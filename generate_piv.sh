read -p 'What slot is this certificate intended for? (9a, 9c, 9d, 9e): ' pivslot
read -p 'Name: ' full_name
read -p 'UID (65001): ' uid
read -p 'OU (Cybersecurity): ' org_unit
read -p 'emailAddress: ' email_addr

yubico-piv-tool -r HID -a generate -s $pivslot -a verify-pin,request-certificate -S "/CN=$full_name/UID=$uid/OU=$org_unit/emailAddress=$email_addr/" $@
if [ $? -ne 0 ]
then
    echo "FATAL: Yubico piv tool encountered an error, is a managment key enabled? (-k)"
    exit 1
fi

echo "Paste CSR below:"
csr_data=$(cat)
cat > user.csr <<< "$csr_data"

username=$(openssl req -noout -subject -nameopt multiline <<< "$csr_data" | sed -n 's/ *commonName *= \(.*\)/\1/p' )

echo "This is the CSR for '$username'. Is this correct? (Ctrl+C to cancel)"
echo "Default UPN: $username@ad.cs2pa.net"
read -p "Enter UPN (e.g., user1@ad.cs2pa.net) [Press Enter for default]: " upn

if [ -z "${upn}" ]
then
    upn=$username
fi

# Create the temp config file with the new options
cat openssl.cnf - > temp_ext.cnf <<EOF
[ alt_names ]
otherName.1 = 1.3.6.1.4.1.311.20.2.3;UTF8:$upn@ad.cs2pa.net
EOF

openssl ca -config openssl.cnf \
  -extensions "piv_$pivslot" \
  -extfile temp_ext.cnf \
  -out current_cer.pem \
  -in user.csr

rm user.csr temp_ext.cnf
yubico-piv-tool -r HID -a import-certificate -s $pivslot < "$(pwd)/current_cer.pem" $@
rm current_cer.pem