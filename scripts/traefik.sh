#!/bin/bash
#
# I live in /usr/local/bin/traefik.sh
# Don't forget to `chmod +x` this file!
#
# My counterpart lives in /etc/supervisor/conf.d/traefik.conf

cd /home/trey/
docker start -a traefik
