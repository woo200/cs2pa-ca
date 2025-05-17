read -p 'What slot is this certificate intended for? (9a, 9c, 9d, 9e): ' pivslot
echo "Paste your CSR (Or a path to a CSR), then press Ctrl-D (on a new line) to finish:"
csr_data=$(cat)
if [[ $csr_data != *"-----BEGIN CERTIFICATE REQUEST-----"* ]]; then
    $csr_data=$(<"$csr_data")
fi

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

echo "To import into PIV card, run:"
echo "  yubico-piv-tool -r HID -a import-certificate -s $pivslot < \"$(pwd)/current_cer.pem\""