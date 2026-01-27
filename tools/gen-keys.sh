#!/bin/bash
# Copyright (c) 2015 by Roderick W. Smith
# Licensed under the terms of the GPL v3

set -e

NAME="chipsec-sec secureboot test"

if ! type uuid &> /dev/null;
then
	echo "uuid binary not found in PATH. Please install the uuid binary (apt install uuid on Debian and derivatives)" >&2
	exit 1
fi

SRCDIR="$(dirname "$0")"
DSTDIR="$SRCDIR/ca"
mkdir -p "$DSTDIR"
cd "$DSTDIR"
rm -f -- *.cer *.crt *.key *.esl *.auth myGUID.txt

GUID=$(uuid)
echo "$GUID" > myGUID.txt

for key in PK KEK DB DBX;
do
	openssl req -new -x509 -newkey rsa:2048 -subj "/CN=$NAME ${key}/" -keyout ${key}.key \
        -out ${key}.crt -days 3650 -nodes -sha256

	openssl x509 -in ${key}.crt -out ${key}.cer -outform DER

	cert-to-efi-sig-list -g "$GUID" ${key}.crt ${key}.esl
done

rm -f noPK.esl
touch noPK.esl

for key in PK noPK KEK DB DBX;
do
	case $key in
		"noPK")
			var="PK";;
		"DB")
			var="db";;
		"DBX")
			var="dbx";;
		*)
			var="${key}";;
	esac

	sign-efi-sig-list -t "$(date --date='1 second' +'%Y-%m-%d %H:%M:%S')" \
  	-k PK.key -c PK.crt ${var} ${key}.esl ${key}.auth
done

chmod 0600 -- *.key

echo ""
echo ""
echo "For use with KeyTool, copy the *.auth and *.esl files to a FAT USB"
echo "flash drive or to your EFI System Partition (ESP)."
echo "For use with most UEFIs' built-in key managers, copy the *.cer files."
echo ""
