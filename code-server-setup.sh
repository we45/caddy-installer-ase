#!/usr/bin/env bash

# Install code server
echo "Installing code-server"
VERSION=4.89.1
curl -fOL https://github.com/coder/code-server/releases/download/v$VERSION/code-server_${VERSION}_amd64.deb
sudo dpkg -i code-server_${VERSION}_amd64.deb
sudo systemctl enable --now code-server@root
command -v code-server >/dev/null 2>&1 || { echo >&2 "code-server not installed."; exit 1; }

# Run code-server
echo "Running code-server to populate defaults"
sudo systemctl start code-server@root
# sleep 12
# sudo systemctl stop code-server@root

# # Set custom theme
# echo "Setting dark theme for code server"
# sudo mkdir -p /root/.local/share/code-server/User
# sudo tee /root/.local/share/code-server/User/settings.json <<EOF
# {
#     "workbench.colorTheme": "Default Dark Modern"
# }
# EOF

# # Configure code-server
# echo "Configuring code-server"
# sudo mkdir -p /root/.config/code-server
# sudo tee /root/.config/code-server/config.yaml <<EOF
# bind-addr: 127.0.0.1:2059
# auth: none
# cert: false
# disable-update-check: true
# disable-getting-started-override: true
# disable-workspace-trust: true
# force: true
# EOF

# # Run code-server
# echo "Running code-server with the new configuration"
# sudo systemctl reload code-server@root
# sudo code-server /root/
echo "Setup complete"
