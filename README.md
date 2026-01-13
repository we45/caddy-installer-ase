# caddy-installer-ase

Infrastructure scripts for ASE lab images: Caddy, Code-Server, and CI/CD pipelines.

---

## CI Pipelines

This repository provides GitLab CI templates that can be included in lab repositories.

### Available Pipelines

| Pipeline | Path | Base Image | Tracking |
| ---------- | ------ | ------------ | ---------- |
| Standard | `debian-bookworm-gitlab-ci.yml` | `ase-deb-12-upgraded` | ❌ |
| With Tracker | `lab-tracker/debian-bookworm-gitlab-ci-with-tracker.yml` | `ase-deb-images` family | ✅ |

### Usage in Lab Repositories

#### Standard Pipeline (Legacy)

```yaml
# .gitlab-ci.yml
include: https://raw.githubusercontent.com/we45/caddy-installer-ase/refs/heads/main/debian-bookworm-gitlab-ci.yml
```

#### Pipeline with Command Tracking (Recommended)

```yaml
# .gitlab-ci.yml
include: https://raw.githubusercontent.com/we45/caddy-installer-ase/main/lab-tracker/debian-bookworm-gitlab-ci-with-tracker.yml
```

---

## Versioning

### Git Refs in GitHub Raw URLs

Pin to a specific version by changing the ref in the URL:

| Ref Type | URL Pattern | Use Case |
| ---------- | --------- | ---------- |
| Branch | `.../main/lab-tracker/...` | Always use latest (development) |
| Tag | `.../v1.0.0/lab-tracker/...` | Pin to stable release (production) |
| Commit | `.../abc1234/lab-tracker/...` | Pin to exact version |

**Examples:**

```yaml
# Development - always latest
include: https://raw.githubusercontent.com/we45/caddy-installer-ase/main/lab-tracker/debian-bookworm-gitlab-ci-with-tracker.yml

# Production - pinned to tag
include: https://raw.githubusercontent.com/we45/caddy-installer-ase/v1.0.0/lab-tracker/debian-bookworm-gitlab-ci-with-tracker.yml
```

**Recommendation**: Use `main` during development, pin to a tag for production labs.

### Image Families

The tracker pipeline uses GCP image families for automatic version management:

| Family | Description |
| -------- | ------------- |
| `ase-deb-images` | Debian 12 with lab tracker pre-installed |

> Note: This image family will be upgraded to Debian 13 in the future.

When you add a new image to a family, VMs created with `--image-family=ase-deb-images` automatically use the latest image.

---

## Lab Tracker Pipeline

### Required Files in Lab Repository

| File | Required | Purpose |
| ------ | ---------- | --------- |
| `setup.sh` | ✅ | Lab-specific setup script |
| `README.md` | ✅ | Lab documentation (removed from image) |
| `.gitignore` | ✅ | Git ignore rules (removed from image) |
| `.gitlab-ci.yml` | ✅ | CI pipeline config (removed from image) |
| `lab-spec.json` | ❌ | Command tracking steps (enables tracking) |

### Required CI Variables

| Variable | Description |
| ---------- | ------------- |
| `SECONDARY_GOOGLE_CREDS` | GCP service account JSON (file) |
| `SECONDARY_GCP_PROJECT_ID` | GCP project for building images |
| `PRIMARY_GCP_PROJECT_ID` | GCP project for production images |
| `ZONE` | GCP zone (e.g., `us-central1-a`) |
| `IMG_CONFIG` | Machine type (e.g., `e2-medium`) |
| `CHIT_TOKEN` | Token for chit tool |
| `SLACK_WEBHOOK_URL` | Slack webhook for notifications |

### Lab Spec Format

Create `lab-spec.json` in your lab repository to enable command tracking:

```json
{
  "lab_id": "my-lab-name",
  "lab_version": "1.0.0",
  "title": "My Lab Title",
  "steps": [
    {
      "id": "step_1",
      "description": "Navigate to lab directory",
      "match_type": "regex",
      "match_pattern": "cd.*/my-lab",
      "requires_success": true,
      "min_times": 1
    }
  ],
  "completion": {
    "policy": "all_steps"
  }
}
```

#### Match Types

| Type | Description | Example Pattern |
| ------ | ------------- | ----------------- |
| `exact` | Exact command match | `ls -la` |
| `argv_prefix` | Command starts with | `docker` |
| `contains_tokens` | Contains all tokens | `curl,localhost` |
| `regex` | Regular expression | `cd.*/cert` |

---

## Directory Structure

```bash
caddy-installer-ase/
├── README.md
├── debian-bookworm-gitlab-ci.yml      # Legacy pipeline (do not move)
├── lab-tracker/
│   ├── README.md                      # Tracker-specific docs
│   ├── debian-bookworm-gitlab-ci-with-tracker.yml
│   ├── lab-image-setup.sh             # Setup script for CI
│   ├── lab-image-cleanup.sh           # Cleanup script for CI
│   └── lab-spec-template.json         # Template for lab authors
└── ... (other installer files)
```

---

## Changelog

### v1.0.0 (2026-01-13)

- Initial release of lab tracker pipeline
- VS Code/Code-Server terminal compatibility
- Placeholder JWT (orchestrator injects real token at runtime)
