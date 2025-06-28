#!/bin/bash

# === A. Docker Installation Script for Raspberry Pi OS (64-bit) ===

# --- 1. Update APT and install required packages ---
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg lsb-release

# --- 2. Set up Docker's official GPG key and repository securely ---
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# --- 3. Add Docker repository ---
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
$(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# --- 4. Install Docker Engine and related components ---
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# --- 5. Post-installation: test and set permissions ---
# Add current user to docker group (requires logout/login or reboot to take effect)
sudo usermod -aG docker "$USER"

# --- 6. Run test container to verify installation ---
sudo docker run hello-world

# === B. GitLab Runner Setup Script for Raspberry Pi (ARM64) ===
# Usage: Run interactively and follow prompts where needed

# --- 1. Download and install GitLab Runner and helper images (for ARM64) ---
curl -L --output gitlab-runner-helper-arm64.deb https://s3.dualstack.us-east-1.amazonaws.com/gitlab-runner-downloads/latest/deb/gitlab-runner-helper-images.deb
curl -L --output gitlab-runner-arm64.deb https://s3.dualstack.us-east-1.amazonaws.com/gitlab-runner-downloads/latest/deb/gitlab-runner_arm64.deb

# --- 2. Install both packages ---
sudo dpkg -i gitlab-runner-helper-arm64.deb gitlab-runner-arm64.deb

# --- 3. Verify installation ---
gitlab-runner --version

# --- 4. Add gitlab-runner user to docker group (if using Docker executor) ---
sudo usermod -aG docker gitlab-runner

# --- 5. Register the runner (interactive prompt) ---
# NOTE: This must be run with sudo to register as a system-wide runner (to also apply for gitlab-runner user)
sudo gitlab-runner register

# --- 6. Fix config file permissions ---
sudo chown gitlab-runner:gitlab-runner /etc/gitlab-runner/config.toml
sudo chmod 600 /etc/gitlab-runner/config.toml

# --- 7. Enable and start the GitLab Runner service ---
sudo gitlab-runner install --user=gitlab-runner --working-directory=/home/gitlab-runner
sudo systemctl enable gitlab-runner
sudo systemctl start gitlab-runner
sudo gitlab-runner start

# === Verification (manual steps) ===

# ✅ Check if runner is listed (should show name, executor, token, etc.)
# sudo gitlab-runner list

# ✅ Check systemd service status (should be 'active (running)')
# sudo systemctl status gitlab-runner

# ✅ Check gitlab-runner user and group memberships (should include 'docker')
# id gitlab-runner

# ✅ Check if Docker works for the gitlab-runner user
# sudo -u gitlab-runner docker info

# ✅ Check GitLab UI:
#   - Go to your GitLab project → Settings → CI/CD → Runners
#   - Verify the runner shows up and is ONLINE

# ℹ️ About `gitlab-runner run`:
# This command starts the runner in the foreground (manual mode).
# It is useful for debugging or one-off/local testing.
# Not required to run `gitlab-runner run` manually when the systemd service is enabled and running properly.
