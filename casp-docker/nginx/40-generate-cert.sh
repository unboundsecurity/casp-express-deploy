#!/bin/sh

set -x

openssl req -x509 -newkey rsa:4096 -nodes -keyout /etc/ssl/private/privkey.pem -out /etc/ssl/private/fullchain.pem -days 365 -subj "/C=US/ST=Oregon/L=Portland/O=Company Name/OU=Org/CN=localhost"
