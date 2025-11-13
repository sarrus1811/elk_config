#!/usr/bin/env bash

cd ~
mkdir -p ~/tls/{configs,keys,csr,caroot,caintermediate,certs}

# Generate root certicates
echo "Generating the root certifcate..."
sleep 1
cp openssl-rootca.cnf ~/tls/configs/openssl-rootca.cnf
openssl req -x509 -config tls/configs/openssl-rootca.cnf -days 3650 -new -extensions ca_root -keyout tls/caroot/ca.key.pem -out tls/caroot/ca.cert.pem -passout pass:abcd1234
echo "Displaying the root certificate..."
sleep 1
openssl x509 -text -noout -in ~/tls/caroot/ca.cert.pem
touch ~/tls/caroot/index-root.txt
echo "00" > ~/tls/caroot/serial-root.txt

# Generate intermediate certificates
cp openssl-intermediateca.cnf ~/tls/configs/openssl-intermediateca.cnf

openssl req -config ~/tls/configs/openssl-intermediateca.cnf -new -keyout ~/tls/caintermediate/ca-int.key.pem -out ~/tls/caintermediate/ca-int.csr -outform PEM -passout pass:abcd1234
openssl ca -batch -notext -config ~/tls/configs/openssl-rootca.cnf -passin pass:abcd1234 -policy signing_policy -days 3650 -extensions ca_intermediate -out ~/tls/caintermediate/ca-int.cert.pem -infiles ~/tls/caintermediate/ca-int.csr
echo "Displaying the intermediate certificate..."
sleep 1
openssl x509 -text -noout -in ~/tls/caintermediate/ca-int.cert.pem
touch ~/tls/caintermediate/index-intermediate.txt
echo "00" > ~/tls/caintermediate/serial-intermediate.txt
echo "Verifying..."
sleep 1
openssl verify -CAfile ~/tls/caroot/ca.cert.pem ~/tls/caintermediate/ca-int.cert.pem
sleep 1

echo "Creating chain file..."
cat ~/tls/caroot/ca.cert.pem ~/tls/caintermediate/ca-int.cert.pem >> ~/tls/certs/ca-chain.cert.pem

# Generate certifcates for logstash
echo "Generating keys for logstash..."
cp openssl-flex-logstash.local.cnf ~/tls/configs/openssl-flex-logstash.local.cnf
openssl req -config ~/tls/configs/openssl-flex-logstash.local.cnf -new -out ~/tls/csr/logstash.local.flex.csr -outform PEM -passout pass:abcd1234
openssl ca -batch -notext -config ~/tls/configs/openssl-intermediateca.cnf -passin pass:abcd1234 -policy signing_policy -extensions flex_cert -out ~/tls/certs/logstash.local.flex.cert.pem -infiles ~/tls/csr/logstash.local.flex.csr

echo "Displaying the certificate..."
sleep 1
openssl x509 -text -noout -in ~/tls/certs/logstash.local.flex.cert.pem

echo "Verifying..."
sleep 1
openssl verify -CAfile ~/tls/certs/ca-chain.cert.pem ~/tls/certs/logstash.local.flex.cert.pem
