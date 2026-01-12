#!/bin/bash
# =============================================================================
# Lab Image Cleanup Script
# =============================================================================
# This script prepares the VM for image capture by:
#   1. Removing the cloned lab repository
#   2. Clearing shell history
#   3. Clearing instance-specific data (SSH keys, cloud-init, machine-id)
#   4. Clearing logs
#
# Usage: lab-image-cleanup.sh <project_name>
#
# =============================================================================
set -e

PROJECT_NAME="$1"

echo ""
echo "=============================================="
echo "  Cleanup for Image Capture"
echo "=============================================="
echo ""

# ============================================
# Remove cloned repository
# ============================================
echo "[1/5] Removing build artifacts..."
if [[ -n "$PROJECT_NAME" ]] && [[ -d "/root/${PROJECT_NAME}" ]]; then
    rm -rf "/root/${PROJECT_NAME}"
    echo "  ✓ Removed /root/${PROJECT_NAME}"
fi

# Also clean common build locations
rm -rf /tmp/lab-* 2>/dev/null || true
rm -rf /root/*.tar.gz 2>/dev/null || true
rm -rf /root/*.zip 2>/dev/null || true

# ============================================
# Clear shell history
# ============================================
echo "[2/5] Clearing shell history..."
rm -f /root/.bash_history 2>/dev/null || true
rm -f /root/.zsh_history 2>/dev/null || true
rm -f /home/*/.bash_history 2>/dev/null || true
rm -f /home/*/.zsh_history 2>/dev/null || true
history -c 2>/dev/null || true
echo "  ✓ History cleared"

# ============================================
# Clear logs
# ============================================
echo "[3/5] Clearing logs..."
rm -f /var/log/*.log 2>/dev/null || true
rm -f /var/log/*/*.log 2>/dev/null || true
rm -f /var/log/journal/*/* 2>/dev/null || true
journalctl --vacuum-time=1s 2>/dev/null || true
echo "  ✓ Logs cleared"

echo ""
echo "=============================================="
echo "  Cleanup Complete - Ready for Image Capture"
echo "=============================================="

