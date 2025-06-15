openssl ca -config openssl.cnf -gencrl > ca/crl/rootca.crl 
rsync ca/crl/rootca.crl cs2pa:/var/www/html/CRL/rootca.crl
echo "Updated root CRL and uploaded to PKI server"