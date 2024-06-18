#!/usr/bin/env bash
command -v code-server >/dev/null 2>&1 || { echo >&2 "code-server not installed."; exit 1; }
echo "code-server already installed"
echo "wait for confirmation of service running"
sudo systemctl is-active --quiet code-server@root && echo "code-server is running"

# # Install code server
# echo "Installing code-server"
# VERSION=4.89.1
# curl -fOL https://github.com/coder/code-server/releases/download/v$VERSION/code-server_${VERSION}_amd64.deb #TO-DO move this file to our s3 bucket
# sudo dpkg -i code-server_${VERSION}_amd64.deb
# sudo systemctl enable --now code-server@root
# command -v code-server >/dev/null 2>&1 || { echo >&2 "code-server not installed."; exit 1; }

# # Start code server
# sudo systemctl start code-server@root.service
# # sleep 5

# # Set custom theme
# echo "Setting dark theme for code server"
# sudo mkdir -p /root/.local/share/code-server/User
# sudo tee /root/.local/share/code-server/User/settings.json <<EOF1
# {
#     "workbench.colorTheme": "Default Dark Modern",
#     "workbench.startupEditor": "none",
#     "terminal.integrated.defaultProfile.linux": "bash"
# }
# EOF1

# # Set path to open to
# echo "Setting path to open code server to"
# sudo mkdir -p /root/.local/share/code-server
# sudo tee /root/.local/share/code-server/coder.json  <<EOF2
# {
#   "query": {
#     "folder": "/root"
#   }
# }
# EOF2

# # Configure code-server
# echo "Configuring code-server"
# sudo mkdir -p /root/.config/code-server
# sudo tee /root/.config/code-server/config.yaml <<EOF3
# bind-addr: 127.0.0.1:2059
# auth: none
# cert: false
# disable-update-check: true
# disable-getting-started-override: true
# disable-workspace-trust: true
# force: true
# EOF3

# # Run code-server
# echo "Running code-server with the new configuration"
# sudo systemctl restart code-server@root
# echo "Setup complete"
