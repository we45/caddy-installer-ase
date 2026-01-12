# Lab Tracker CI Scripts

Scripts for integrating the ASE Lab Command Tracker into the lab image CI pipeline.

## Overview

These scripts automate the setup of the lab command tracker during CI image builds:

1. **`lab-image-setup.sh`** - Runs lab setup + configures tracker
2. **`lab-image-cleanup.sh`** - Prepares VM for image capture
3. **`lab-spec-template.json`** - Template for lab authors

## How It Works

```bash
┌─────────────────────────────────────────────────────────────┐
│                     CI Pipeline Flow                        │
├─────────────────────────────────────────────────────────────┤
│ 1. Create VM from base image (ase-deb-images)               │
│                         ↓                                   │
│ 2. Clone lab repo containing:                               │
│    - setup.sh (required)                                    │
│    - lab-spec.json (optional, enables tracking)             │
│                         ↓                                   │
│ 3. Run lab-image-setup.sh                                   │
│    ├── Executes lab's setup.sh                              │
│    ├── Installs lab-spec.json (if present)                  │
│    ├── Generates lab-specific JWT                           │
│    └── Verifies tracker starts                              │
│                         ↓                                   │
│ 4. Run lab-image-cleanup.sh                                 │
│                         ↓                                   │
│ 5. Create GCP image                                         │
└─────────────────────────────────────────────────────────────┘
```

## For Lab Authors

### Required Files in Lab Repo

Every lab repo **must** contain:

| File | Purpose |
|------|---------|
| `setup.sh` | Lab-specific environment setup script |
| `README.md` | Lab documentation |
| `.gitignore` | Git ignore rules |
| `.gitlab-ci.yml` | CI configuration (usually includes shared template) |
| `lab-spec.json` | **Optional** - enables command tracking |

> **Note:** `README.md`, `.gitignore`, `.gitlab-ci.yml`, and `.git/` are automatically removed from the final image.

### Adding Tracking to Your Lab

1. **Create `lab-spec.json`** in your lab repo root (copy from `lab-spec-template.json`)

2. **Define steps** that users should complete:

    ```json
    {
    "lab_id": "sql-injection-101",
    "lab_version": "1.0.0", 
    "title": "SQL Injection Fundamentals",
    "steps": [
        {
        "id": "start_app",
        "description": "Start the vulnerable application",
        "match_type": "argv_prefix",
        "match_pattern": "python3 app.py",
        "requires_success": true,
        "min_times": 1
        }
    ],
    "completion": {
        "policy": "all_steps"
    }
    }
    ```

3. **Commit both `setup.sh` and `lab-spec.json`** to your repo

### Match Types

| Type | Description | Example Pattern |
|------|-------------|-----------------|
| `argv_prefix` | Command starts with these words | `python3 app.py` |
| `regex` | Regular expression match | `curl.*--data.*login` |
| `exact` | Exact string match | `cat /etc/passwd` |
| `contains_tokens` | All words present (exact match) | `nmap,-sV,-p` |

### Step Options

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | yes | Unique step identifier |
| `description` | string | no | Human-readable description |
| `match_type` | string | yes | One of: exact, argv_prefix, contains_tokens, regex |
| `match_pattern` | string | yes | Pattern to match |
| `requires_success` | bool | no | Only match if exit code is 0 (default: true) |
| `min_times` | int | no | Minimum times to complete (default: 1) |
| `cwd` | string | no | Required working directory prefix |

### Tips

- Use `regex` for flexible matching (e.g., `curl.*http` matches any curl to http)
- Use `argv_prefix` for exact command starts (e.g., `python3 app.py`)
- Set `requires_success: false` for commands that may fail (e.g., exploit attempts)
- Test your patterns locally before committing

## CI Variables Required

| Variable | Description |
|----------|-------------|
| `JWT_SECRET` | HS256 signing secret for generating lab JWTs |
| `SCRIPTS_REPO` | Raw URL to this scripts repo |

## Script URLs

When hosted on GitHub, use raw URLs:

```
https://raw.githubusercontent.com/we45/caddy-installer-ase/main/lab-tracker/lab-image-setup.sh
https://raw.githubusercontent.com/we45/caddy-installer-ase/main/lab-tracker/lab-image-cleanup.sh
```

## Testing Locally

```bash
# Validate your lab-spec.json
cat lab-spec.json | python3 -m json.tool

# Check step count
python3 -c "import json; s=json.load(open('lab-spec.json')); print(f'Lab: {s[\"lab_id\"]}, Steps: {len(s[\"steps\"])}')"
```
