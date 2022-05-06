$rootsubj="/C=US/ST=California/L=Clovis/O=None/OU=None/CN=collins.local"
openssl genrsa 2048 > ca-key.pem
## Need syntax to set the extensions and key usage!
openssl req -new -x509 -noenc -days 3650 -key .\ca-key.pem -subj "$rootsubj" > ca-cert.pem
$subj="/C=US/ST=California/L=Clovis/O=None/OU=None/CN=vpn.collins.local"
openssl genrsa 2048 > server-key.pem
openssl req -new -noenc -key .\server-key.pem -out server-csr.pem -subj "$subj"
openssl genrsa 2048 > client-key.pem
openssl req -new -noenc -key .\client-key.pem -out client-csr.pem -subj "$subj"
