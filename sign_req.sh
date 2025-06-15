function print_usage() {
    echo "Usage: $0 [request.csr] [output_certificate.pem]"
    printf "%${#0}s"
    echo "        -h (Help on generating certs and requests)"
    
}

if [[ $1 == "-h" ]]
then
    echo "openssl req -addext \"subjectAltName=DNS.1:domain.com,DNS.2:domain.com,IP:127.0.0.1\" \\"
    echo "            -newkey rsa:2048 -keyout PRIVATEKEY.key -nodes -out MYCSR.csr"
    exit
fi

if [ $# -lt 2 ]
then
    print_usage
    exit
fi

openssl req -in $1 -text -noout
openssl ca -config openssl.cnf \
    -out $2 \
    -in $1 \
    -extensions CRLonly