#!/bin/bash

CA_LIFE=730
EMAIL=""
PROXY_PATH="/etc/nginx/proxy"

gen_ca() {
	echo "Gen CA..."

	if [ -z "$EMAIL" ]; then
		read -p "Your email: " email
	fi
	local SUBJ="/C=CN/ST=ST$RANDOM/O=O$RANDOM/OU=OU$RANDOM/CN=CN$RANDOM/emailAddress=$email"

	openssl genrsa 2048 > proxy-ca.key
	openssl req -new -x509 \
		-days $CA_LIFE \
		-key proxy-ca.key -out proxy-ca.pem \
		-subj $SUBJ \
		-extensions v3_ca
	openssl genrsa 2048 > nginx.key
	openssl req -new -nodes \
		-key nginx.key -out nginx.csr \
		-subj $SUBJ
	openssl x509 -req -days $CA_LIFE \
			-in nginx.csr -out nginx.pem \
			-CA proxy-ca.pem -CAkey proxy-ca.key \
			-set_serial 0 \
			-extensions CUSTOM_STRING_LIKE_SAN_KU\
			-extfile extfile.conf
}

install_ca() {
	echo "Install CA..."
	sudo mkdir -p "$PROXY_PATH"
	sudo cp ./nginx.key /etc/nginx/proxy/nginx.key
	sudo cp ./nginx.pem /etc/nginx/proxy/nginx.pem
	sudo cp ./nginx.pem /etc/ca-certificates/trust-source/anchors/nginx-proxy-nginx.pem
	sudo cp ./proxy-ca.pem /etc/ca-certificates/trust-source/anchors/nginx-proxy-ca.pem
	sudo update-ca-trust
}

install_conf() {
	echo "Install nginx config..."

	sudo mkdir -p "$PROXY_PATH"
	sudo cp ./cert.conf\
		./github.conf\
		./github-upstreams.conf\
		./shared-proxy-params-1.conf\
		./shared-proxy-params-2.conf\
		./pixiv.conf\
		./proxy.conf\
		"$PROXY_PATH"

	echo "Edit hosts file..."
	cat hosts | sudo tee -a /etc/hosts

	echo "Put 'include proxy/proxy.conf;' to your nginx config in 'http' section"
	echo "Please restart your nginx!"
}

usage() {
	cat << EOF
usage: ./install.sh [<options>]

options: -g, --gen-ca: generate ca-certificates
         -h: usage
         --install-ca: install ca-certificates
         --install-conf: install configuration
EOF
}

until [ $# -eq 0 ]; do
	case "$1" in
		-g|--gen-ca) gen_ca ;;
		-h) usage ;;
		--install-ca) install_ca ;;
		--install-conf) install_conf ;;
		*)
			gen_ca
			install_ca
			install_conf
			;;
	esac
	shift
done
