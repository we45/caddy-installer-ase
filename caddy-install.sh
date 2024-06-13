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
wget https://theia-config-files.s3.amazonaws.com/caddy_templater.py
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

# Remove caddy_templater.py after use
echo "Removing caddy_templater.py"
/usr/bin/caddy run -config /root/.config/caddy.json & rm ./caddy_templater.py
