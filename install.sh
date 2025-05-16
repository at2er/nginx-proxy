#!/bin/bash

echo -e "Your email: \c"

read email

SUBJ="/C=CN/ST=ST$RANDOM/O=O$RANDOM/OU=OU$RANDOM/CN=CN$RANDOM/emailAddress=$email"

echo "Gen CA..."

openssl genrsa 2048 > proxy-ca.key
openssl req -new -x509 -days 730 -key proxy-ca.key -out proxy-ca.pem -subj $SUBJ -extensions v3_ca
openssl genrsa 2048 > nginx.key
openssl req -new -nodes -key nginx.key -out nginx.csr -subj $SUBJ
openssl x509 -req -days 730 \
    -in nginx.csr -out nginx.pem \
    -CA proxy-ca.pem -CAkey proxy-ca.key -set_serial 0 -extensions CUSTOM_STRING_LIKE_SAN_KU\
    -extfile extfile.conf

echo "Install CA..."

sudo cp ./nginx.key /etc/nginx/proxy/nginx.key
sudo cp ./nginx.pem /etc/nginx/proxy/nginx.pem
sudo cp ./nginx.pem /etc/ca-certificates/trust-source/anchors/nginx.pem
sudo cp ./proxy-ca.pem /etc/ca-certificates/trust-source/anchors/ca.pem
sudo update-ca-trust

echo "Install nginx config..."

path="/etc/nginx/proxy"

sudo mkdir -p "$path"
sudo cp ./cert.conf\
	./github.conf\
	./github-upstreams.conf\
	./shared-proxy-params.conf\
	./proxy.conf\
	"$path"

echo "Edit hosts file..."
sudo cat hosts >> /etc/hosts

echo "Put 'include proxy/proxy.conf;' to your nginx config in 'http' section"
echo "Please restart your nginx!"
