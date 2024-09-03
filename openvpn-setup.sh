#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Update the system
sudo apt update
sudo apt upgrade -y

# Install OpenVPN and Easy-RSA
sudo apt install -y openvpn easy-rsa

# Set up the Certificate Authority (CA)
mkdir ~/openvpn-ca
cd ~/openvpn-ca

# Initialize the Public Key Infrastructure (PKI)
./easyrsa init-pki

# Build the CA (you will be prompted for a passphrase)
./easyrsa build-ca nopass

# Generate the server certificate and key
./easyrsa gen-req server nopass
./easyrsa sign-req server server

# Generate Diffie-Hellman parameters
./easyrsa gen-dh

# Generate the HMAC key to defend against DoS attacks
openvpn --genkey --secret ta.key

# Create the server configuration directory if it doesn't exist
sudo mkdir -p /etc/openvpn/server

# Copy server certificates and keys to the OpenVPN directory
sudo cp pki/ca.crt pki/issued/server.crt pki/private/server.key pki/dh.pem ta.key /etc/openvpn/server/

# Copy the server configuration template and decompress it
sudo cp /usr/share/doc/openvpn/examples/sample-config-files/server.conf.gz /etc/openvpn/
sudo gzip -d /etc/openvpn/server.conf.gz

# Modify the server configuration file
sudo sed -i 's|ca ca.crt|ca /etc/openvpn/server/ca.crt|' /etc/openvpn/server.conf
sudo sed -i 's|cert server.crt|cert /etc/openvpn/server/server.crt|' /etc/openvpn/server.conf
sudo sed -i 's|key server.key|key /etc/openvpn/server/server.key|' /etc/openvpn/server.conf
sudo sed -i 's|dh dh2048.pem|dh /etc/openvpn/server/dh.pem|' /etc/openvpn/server.conf
sudo sed -i 's|;tls-auth ta.key 0 # This file is secret|tls-auth /etc/openvpn/server/ta.key 0|' /etc/openvpn/server.conf
sudo sed -i 's|;user nobody|user nobody|' /etc/openvpn/server.conf
sudo sed -i 's|;group nogroup|group nogroup|' /etc/openvpn/server.conf
sudo sed -i 's|;push "redirect-gateway def1 bypass-dhcp"|push "redirect-gateway def1 bypass-dhcp"|' /etc/openvpn/server.conf
sudo sed -i 's|;push "dhcp-option DNS 208.67.222.222"|push "dhcp-option DNS 8.8.8.8"|' /etc/openvpn/server.conf
sudo sed -i 's|;push "dhcp-option DNS 208.67.220.220"|push "dhcp-option DNS 8.8.4.4"|' /etc/openvpn/server.conf

# Enable IP forwarding in the system
sudo sed -i 's|#net.ipv4.ip_forward=1|net.ipv4.ip_forward=1|' /etc/sysctl.conf
sudo sysctl -p

# Configure UFW to allow OpenVPN traffic
sudo ufw allow 1194/udp
sudo ufw allow OpenSSH
sudo ufw allow 22/tcp

# Before enabling UFW, add a rule to allow forwarding
sudo bash -c 'cat <<EOF >> /etc/ufw/before.rules
# START OPENVPN RULES
*nat
:POSTROUTING ACCEPT [0:0]
-A POSTROUTING -s 10.8.0.0/8 -o eth0 -j MASQUERADE
COMMIT
# END OPENVPN RULES
EOF'

# Enable UFW
sudo ufw enable

# Start and enable the OpenVPN service
sudo systemctl start openvpn@server
sudo systemctl enable openvpn@server

# Generate a client certificate and key
cd ~/openvpn-ca
./easyrsa gen-req client1 nopass
./easyrsa sign-req client client1

# Copy the client configuration template
mkdir -p ~/client-configs/files
cp /usr/share/doc/openvpn/examples/sample-config-files/client.conf ~/client-configs/base.conf

# Modify the client configuration file
sed -i 's|remote my-server-1 1194|remote your-server-ip 1194|' ~/client-configs/base.conf
sed -i 's|ca ca.crt|ca [inline]|' ~/client-configs/base.conf
sed -i 's|cert client.crt|cert [inline]|' ~/client-configs/base.conf
sed -i 's|key client.key|key [inline]|' ~/client-configs/base.conf
sed -i 's|tls-auth ta.key 1|<tls-auth>\n\n</tls-auth>|' ~/client-configs/base.conf
echo "<ca>" >> ~/client-configs/base.conf
cat ~/openvpn-ca/pki/ca.crt >> ~/client-configs/base.conf
echo "</ca>" >> ~/client-configs/base.conf
echo "<cert>" >> ~/client-configs/base.conf
cat ~/openvpn-ca/pki/issued/client1.crt >> ~/client-configs/base.conf
echo "</cert>" >> ~/client-configs/base.conf
echo "<key>" >> ~/client-configs/base.conf
cat ~/openvpn-ca/pki/private/client1.key >> ~/client-configs/base.conf
echo "</key>" >> ~/client-configs/base.conf
echo "<tls-auth>" >> ~/client-configs/base.conf
cat /etc/openvpn/server/ta.key >> ~/client-configs/base.conf
echo "</tls-auth>" >> ~/client-configs/base.conf

# Output the client configuration
echo "Client configuration file created at: ~/client-configs/base.conf"
