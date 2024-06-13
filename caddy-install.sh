#!/usr/bin/env bash

# Assume dns and other variables are set
# dns="codeserver.ase.sh"
# auth=true
# temp_password="123123123"

# Install Caddy
# echo "Installing Caddy"
# sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https
# curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
# curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
# sudo apt update
# sudo apt install caddy
echo "Checking if Caddy is installed"
command -v caddy >/dev/null 2>&1 || { echo >&2 "Caddy not installed."; exit 1; }
echo "Caddy installed successfully."

# Ensure Caddy is stopped and disabled
systemctl stop caddy\nsystemctl disable caddy

# Fetch variables from caddy_templater.py
echo "Fetching caddy_templater.py"
wget -O caddy_templater.py https://raw.githubusercontent.com/we45/caddy-installer-ase/main/caddy_templater_2.0.py
chmod +x ./caddy_templater.py
echo "Fetching variables from caddy_templater.py"
while test $# -gt 0; do
        case "$1" in
                -dns)
                        shift
                        dns=$1
                        shift
                        ;;
                -temp_password)
                        shift
                        temp_password=$1
                        shift
                        ;;
                -auth)
                        shift
                        auth=$1
                        shift
                        ;;
                *)
                        echo "$1 is not a recognized flag!"
                        exit 1
                        ;;
        esac
done

# Check if DNS is empty
if [ -z "$dns" ]; then
    echo "DNS is empty. Exiting."
    exit 1
fi

echo "Variables fetched:"
echo "DNS : $dns"

# Generate Caddy hash if auth is true
if [ "$auth" = true ]; then
        echo "PASSWORD : $temp_password"
        echo "AUTHENTICATION : $auth"
        echo "AUTH is true. Generating Caddy hash"
        caddy_hash=$(/usr/bin/caddy hash-password -plaintext "$temp_password")
        echo "caddy_hash: $caddy_hash"
        ./caddy_templater.py --dns "$dns" --auth "$auth" --password "$caddy_hash"
else
        echo "AUTH is false."
        ./caddy_templater.py --dns "$dns"
fi

## Temp Code Server
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
sleep 12
sudo systemctl stop code-server@root

# Set custom theme
echo "Setting dark theme for code server"
sudo mkdir -p /root/.local/share/code-server/User
sudo tee /root/.local/share/code-server/User/settings.json <<EOF
{
    "workbench.colorTheme": "Default Dark Modern"
}
EOF

# Configure code-server
echo "Configuring code-server"
sudo mkdir -p /root/.config/code-server
sudo tee /root/.config/code-server/config.yaml <<EOF
bind-addr: 127.0.0.1:2059
auth: none
cert: false
disable-update-check: true
disable-getting-started-override: true
disable-workspace-trust: true
force: true
EOF

# Run code-server
echo "Running code-server with the new configuration"
sudo systemctl reload code-server@root
sudo code-server /root/
echo "Setup complete"

# Remove caddy_templater.py after use
echo "Removing caddy_templater.py"
/usr/bin/caddy run -config /root/.config/caddy.json & rm ./caddy_templater.py
