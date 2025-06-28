# rpi-ci-runner-setup

Automated setup script for installing and configuring a GitLab CI Runner on Raspberry Pi OS (64-bit), using Docker as the executor.

## 📌 Overview

This project provides a Bash script (`setup-runner.sh`) that installs:

- Docker Engine (official Debian-based repo)
- GitLab Runner (ARM64 .deb packages)
- Registers and configures the runner to work with Docker
- Enables and starts the systemd GitLab Runner service

Perfect for self-hosted CI/CD on Raspberry Pi boards using GitLab.

## ✅ Features

- Compatible with Raspberry Pi OS 64-bit (Debian-based)
- Installs Docker and GitLab Runner
- Adds proper permissions and group access
- Starts and enables runner via systemd
- Docker executor-ready
- Interactive `gitlab-runner register` step included

## 🧰 Requirements

- Raspberry Pi running a 64-bit OS (e.g., Raspberry Pi OS Lite 64-bit)
- Root access (`sudo`)
- GitLab project with CI/CD enabled

## 🚀 Installation

Clone the repo and run the script:

```bash
git clone https://github.com/YOUR_USERNAME/rpi-ci-runner-setup.git
cd rpi-ci-runner-setup
chmod +x setup-runner.sh
./setup-runner.sh
```

You'll be prompted to:

- Enter your GitLab instance URL (e.g., `https://gitlab.com`)
- Provide the GitLab registration token (from your repo settings)
- Name your runner and optionally add tags
- Select `docker` as the executor

## 🔍 Verification

After setup, run the following checks:

```bash
sudo gitlab-runner list               # Shows registered runners
sudo systemctl status gitlab-runner  # Verifies service is active
id gitlab-runner                     # Confirms user and docker group
sudo -u gitlab-runner docker info    # Tests Docker access
```

Or verify from GitLab UI:

> Go to **Settings → CI/CD → Runners** and confirm that the runner is **Online**.

## 🛠️ Troubleshooting

- Use `sudo gitlab-runner run` to run the runner manually for debugging
- If Docker fails, ensure the user is added to the `docker` group and reboot
- If the runner isn't online, check token correctness and file permissions:

```bash
sudo chown gitlab-runner:gitlab-runner /etc/gitlab-runner/config.toml
sudo chmod 600 /etc/gitlab-runner/config.toml
```

## 📂 Files

| File             | Description                              |
|------------------|------------------------------------------|
| `setup-runner.sh`| Full setup for Docker + GitLab Runner    |
| `README.md`      | This documentation file                  |
| `LICENSE`        | MIT License © 2025 Nikolaos Tsafas       |
