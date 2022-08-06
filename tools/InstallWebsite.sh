#! /bin/bash
DOMAIN=$1
OPT=$2
BASE=$(pwd)
NGINX_BASE=/etc/nginx
NGINX_CONFIG=$NGINX_BASE/sites-available/$DOMAIN

function Usage(){
  echo "Usage: InstallWebsite.sh DOMAIN [OPT]"
  echo "  DOMAIN: the domain name of the website"
  echo "  OPT: force: overwrite nginx file if needed"
  echo "Examples:"
  echo "InstallWebsite.sh www.huber.de"
  echo "InstallWebsite.sh www.huber.de force"
  echo "+++ $*"
}
function InstallNginx(){
  if [ ! -d $NGINX_BASE ]; then
    echo "NGINX is not installed. No configuration is done"
  elif [ -e "$NGINX_CONFIG" -a "$OPT" != force ]; then
    Usage "$NGINX_CONFIG exists. Use force to overwrite"
  else
    sed <<EOS "s/DOMAIN/$DOMAIN/g" >$NGINX_CONFIG
server {
  listen 80;
  server_name DOMAIN;
  root /home/www/DOMAIN;
  location / {
    return 301 https://server_namerequest_uri;  # enforce https
  }
}
server {
  listen 443 ssl http2;
  server_name DOMAIN;
  access_log /var/log/nginx/a_butler.log;
  root /home/www/DOMAIN;
  error_log /var/log/nginx/e_butler.log;
  ssl_certificate /etc/ssl/certs/DOMAIN.pem;
  ssl_certificate_key /etc/ssl/private/DOMAIN.key;
  index index.html;
  location / {
      allow all;
  }
}
EOS
    ln -vs ../sites-available/$DOMAIN $NGINX_BASE/sites-enabled
    echo "= Create a certificate in /etc/ssl/certs/$DOMAIN.pem and /etc/ssl/private/$DOMAIN.key"
    echo "= Reload the webserver: systemctl reload nginx"
  fi
}
if [ "$(id -u)" != 0 ]; then
  echo "Be root!"
elif [ -z "$DOMAIN" ]; then
  Usage "missing DOMAIN"
elif [ -n "$OPT" -a "$OPT" != force ]; then
  Usage "unknown OPT"
else
  InstallNginx
fi

