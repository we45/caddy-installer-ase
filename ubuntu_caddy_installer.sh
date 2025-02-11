#!/usr/bin/env bash

# Assume dns and other variables are set
# dns="codeserver.ase.sh"
# auth=true
# temp_password="appsec"

# Check if Caddy is installed
echo "Checking if Caddy is installed"
command -v caddy >/dev/null 2>&1 || { echo >&2 "Caddy not installed."; exit 1; }
echo "Caddy installed successfully."

# Ensure Caddy is stopped and disabled
sudo systemctl stop caddy
sudo systemctl disable caddy

# Fetch variables from caddy_templater.py
echo "Fetching caddy_templater.py"
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
        caddy_hash=$(/usr/bin/caddy hash-password --plaintext "$temp_password")
        echo "caddy_hash: $caddy_hash"
        python3 caddy_templater.py --dns "$dns" --auth "$auth" --password "$caddy_hash"
else
        echo "AUTH is false."
        python3 caddy_templater.py --dns "$dns"
fi

# Remove caddy_templater.py after use
rm caddy_templater.py