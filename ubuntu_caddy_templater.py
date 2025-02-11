import json
import argparse
from sys import exit

caddy_dict = {'apps': {'http': {'servers': {'srv0': {'listen': [':80'],
     'routes': [{'match': [],
       'handle': [{'handler': 'subroute',
         'routes': [{'handle': [{'handler': 'reverse_proxy',
             'upstreams': [{'dial': '127.0.0.1:2059'}]}]}]}],
        'terminal': True}]}}}}}

parser = argparse.ArgumentParser(description = "Set caddy template variables for provisioner")
parser.add_argument('--dns', type=str, help="add a FQDN to be set for web server DNS host")
parser.add_argument('--auth', type=bool, default = False, help="Authentication to be enabled or not")
parser.add_argument('--password', type=str, help = "Password to add for authentication param")

def main():
    args = parser.parse_args()
    if not args.dns:
        print("[!] There's no DNS information. Exiting...")
        exit(1)
    
    if args.auth and not args.password:
        print("[!] you need to enter a password when you have enabled auth")
        exit(1)
    
    caddy_dict['apps']['http']['servers']['srv0']['routes'][0]['match'].append({"host": [args.dns]})

    if args.auth:
        password_dict = {
            "handler": "authentication",
            "providers": {
                "http_basic": {
                    "accounts": [{
                        "password": args.password,
                        "username": "appsecengineer"
                    }],
                    "hash": {
                        "algorithm": "bcrypt"
                    },
                    "hash_cache": {}
                }
            }
        }

        caddy_dict['apps']['http']['servers']['srv0']["routes"][0]["handle"].insert(0,password_dict)

    
    with open('/root/.config/caddy.json', 'w') as caddyfile:
        caddyfile.write(json.dumps(caddy_dict))
    



if __name__ == '__main__':
    main()