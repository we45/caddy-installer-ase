#!/bin/bash
# =============================================================================
# Lab Image Setup Script
# =============================================================================
# This script is called during CI to:
#   1. Run the lab's own setup.sh (lab-specific environment setup)
#   2. Install the lab-spec.json for command tracking
#   3. Install a placeholder JWT (real JWT injected by orchestrator at runtime)
#   4. Verify the tracker agent starts correctly
#   5. Prepare for image capture
#
# Usage: lab-image-setup.sh <project_name>
#
# Expects:
#   - Lab repo cloned at /root/<project_name>
#   - Lab repo contains:
#       - setup.sh (required)
#       - README.md (required)
#       - .gitignore (required)
#       - .gitlab-ci.yml (required)
#       - lab-spec.json (optional, enables command tracking)
#
# =============================================================================
set -e

PROJECT_NAME="$1"
REPO_DIR="/root/${PROJECT_NAME}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Validate arguments
if [[ -z "$PROJECT_NAME" ]]; then
    log_error "Usage: $0 <project_name>"
    exit 1
fi

echo ""
echo "=============================================="
echo "  Lab Image Setup: ${PROJECT_NAME}"
echo "=============================================="
echo ""

cd "$REPO_DIR" || { log_error "Repo directory not found: $REPO_DIR"; exit 1; }

# ============================================
# STEP 1: Validate required files
# ============================================
echo "[1/7] Validating required repo files..."

REQUIRED_FILES=("setup.sh" "README.md" ".gitignore" ".gitlab-ci.yml")
MISSING_FILES=()

for file in "${REQUIRED_FILES[@]}"; do
    if [[ -f "$file" ]]; then
        echo "  ✓ $file"
    else
        echo "  ✗ $file (MISSING)"
        MISSING_FILES+=("$file")
    fi
done

if [[ ${#MISSING_FILES[@]} -gt 0 ]]; then
    echo ""
    log_error "CI FAILED: Missing required files in repo!"
    log_error "Please add the following files to your repository:"
    for file in "${MISSING_FILES[@]}"; do
        echo "    - $file"
    done
    echo ""
    exit 1
fi

echo ""
log_info "All required files present"

# ============================================
# STEP 2: Run lab-specific setup.sh
# ============================================
echo ""
echo "[2/7] Running lab-specific setup..."
chmod +x setup.sh
if ./setup.sh; then
    log_info "Lab setup completed successfully"
else
    log_error "Lab setup.sh failed!"
    exit 1
fi

# ============================================
# STEP 3: Remove repo metadata files from image
# ============================================
echo ""
echo "[3/7] Removing repo metadata files..."

# These files should not be in the final image
rm -f README.md .gitignore .gitlab-ci.yml
rm -rf .git
rm -f .cursorrules .cursorignore 2>/dev/null || true

log_info "Repo metadata files removed"

# ============================================
# STEP 4: Check for lab-spec.json (optional)
# ============================================
echo ""
echo "[4/7] Checking for lab tracker configuration..."

if [[ ! -f lab-spec.json ]]; then
    log_warn "lab-spec.json not found - skipping tracker setup"
    log_warn "Lab will be created WITHOUT command tracking"
    echo ""
    echo "=============================================="
    echo "  Setup Complete (No Tracker)"
    echo "=============================================="
    echo ""
    echo "Summary:"
    echo "  - Lab setup.sh: executed"
    echo "  - Repo files: removed"
    echo "  - Tracker: NOT configured (no lab-spec.json)"
    echo ""
    exit 0
fi

# Validate JSON syntax
if ! python3 -m json.tool lab-spec.json > /dev/null 2>&1; then
    log_error "lab-spec.json is not valid JSON!"
    exit 1
fi

# Extract lab metadata
LAB_ID=$(python3 -c "import json; print(json.load(open('lab-spec.json'))['lab_id'])")
STEP_COUNT=$(python3 -c "import json; print(len(json.load(open('lab-spec.json'))['steps']))")
LAB_TITLE=$(python3 -c "import json; print(json.load(open('lab-spec.json')).get('title', 'Untitled'))")

log_info "Lab ID: ${LAB_ID}"
log_info "Title: ${LAB_TITLE}"
log_info "Steps: ${STEP_COUNT}"

# Install lab spec
cp lab-spec.json /opt/appsecengineer/labs/current.json
log_info "Lab spec installed"

# ============================================
# STEP 5: Install placeholder JWT token
# ============================================
echo ""
echo "[5/7] Installing placeholder JWT token..."

# Create a dummy JWT for CI verification
# The orchestrator will replace this with a real token at VM startup
DUMMY_JWT="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJjaS10ZXN0IiwibGFiX2lkIjoiJHtMQUJfSUR9IiwiaWF0IjowLCJleHAiOjk5OTk5OTk5OTl9.placeholder"

echo "$DUMMY_JWT" > /etc/ase-lab-agent/lab_token.jwt
chmod 600 /etc/ase-lab-agent/lab_token.jwt

log_info "Placeholder JWT installed"

# ============================================
# STEP 6: Start and verify tracker
# ============================================
echo ""
echo "[6/7] Starting and verifying lab tracker..."

systemctl restart ase-lab-agent
sleep 3

# Check agent is responding
if ! ase-labctl ping > /dev/null 2>&1; then
    log_error "Agent failed to start!"
    echo "--- Agent Logs ---"
    journalctl -u ase-lab-agent --no-pager -n 15 || cat /var/log/ase-lab-agent.log 2>/dev/null || true
    exit 1
fi
log_info "Agent responding"

# Verify spec loaded correctly
LOADED_LAB_ID=$(ase-labctl spec --json 2>/dev/null | python3 -c "import sys,json; print(json.load(sys.stdin)['lab_id'])" 2>/dev/null || echo "")
if [[ "$LOADED_LAB_ID" != "$LAB_ID" ]]; then
    log_error "Lab ID mismatch: expected '${LAB_ID}', got '${LOADED_LAB_ID}'"
    exit 1
fi
log_info "Lab spec loaded and verified"

# ============================================
# STEP 7: Stop tracker for image capture
# ============================================
echo ""
echo "[7/7] Preparing tracker for image capture..."

systemctl stop ase-lab-agent
rm -f /var/lib/ase-lab-agent/state.db
rm -f /var/log/ase-lab-agent.log
log_info "Tracker state cleared"

# ============================================
# Summary
# ============================================
echo ""
echo "Setup Summary"
echo "----------------------------------------------"
echo "  Lab ID:        ${LAB_ID}"
echo "  Title:         ${LAB_TITLE}"
echo "  Steps:         ${STEP_COUNT}"
echo "  Lab Spec:      /opt/appsecengineer/labs/current.json"
echo "  JWT Token:     Placeholder"
echo "  Agent:         Will auto-start on VM boot"
echo "----------------------------------------------"
echo ""
echo "=============================================="
echo "  Setup Complete"
echo "=============================================="

