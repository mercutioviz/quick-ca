# quick-ca
Quick and easy Cert Auth setup

The purpose of this script is to create a very simple CA for non-prod environments.
Sometimes you just need a server or client cert signed by a CA and it can be challenging
to set that up. This script will make life a lot easier for you!

## Requirements
There are only two requirements but they are critical:
#1 - Powershell v7 or higher. Script will not run on the old ISE with PS 5.1
#2 - An up-to-date OpenSSL installation, such as FireDaemon

## Running the script
After you clone the repo or download the script, put it into a temp folder on your computer
While there are many parameters you can specify on the command line, ultimately just one piece 
of information is absolutely required and that is the domain name that clients and servers 
will be using. If you run the script with no parameters it will ask for you to enter the domain
name to use. Press <enter> to accept the default of my.vpn.local.

After running the script you will have several files:
* ca-ssl.cnf, server-ssl.cnf, and client-ssl.cnf - OpenSSL config files
* ca-key.pem, server-key.pem, client-0001-key.pem - Private keys for each type of cert
* client-0001-csr.pem and server-csr.pem - Certificate Signing Request (CSR) files
* ca-root.pem - CA root certificate used to sign the CSR's
* server-crt.pem and client-0001-crt.pem - Server and client signed certificates
* server.pfx and client-0001.pfx - Server and client cert bundles in PKCS12 (aka .pfx) format
