#!/bin/bash
#
# I live in /usr/local/bin/example_site.sh
# Don't forget to `chmod +x` this file!
#
# My counterpart lives in /etc/supervisor/conf.d/example_site.conf

cd /home/trey/apps/example_site
docker-compose up
