#!/bin/bash

# Replace the following variables with your actual printer and server details
PRINTER_NAME="CIBIO-Cor"
SERVER_IP="10.221.100.2"
DOMAIN="ICAV"

# Check if login and password are provided as parameters
if [ $# -ne 2 ]; then
  echo "Please provide the login and password as parameters."
  echo "Usage: $0 <login> <password>"
  exit 1
fi

USERNAME="$1"
PASSWORD="$2"

# Install required packages
sudo apt update
sudo apt install -y cups smbclient

# Backup the original smb.conf file
sudo cp /etc/samba/smb.conf /etc/samba/smb.conf.bak

# Append the necessary configuration to enable SMB1 (NT1)
sudo tee -a /etc/samba/smb.conf > /dev/null << EOL
[global]
client min protocol = NT1
EOL

# Restart the Samba service
sudo systemctl restart smbd

echo "SMB1 (NT1) enabled successfully!"
# Configure CUPS

sudo systemctl start cups.service
sudo systemctl enable cups.service

# Add printer to CUPS
lpadmin -p "$PRINTER_NAME" -v "smb://$SERVER_IP/$PRINTER_NAME" -E -m everywhere

# Set authentication credentials for Samba
echo -e "username = $USERNAME\npassword = $PASSWORD\ndomain = $DOMAIN" | sudo tee /etc/samba/auth.conf

# Test Samba authentication
smbclient -L "$SERVER_IP" -U "$USERNAME%$PASSWORD"

# Configure printer options
# Uncomment and modify the following lines as per your requirements
# lpoptions -p "$PRINTER_NAME" -o media=A4
# lpoptions -p "$PRINTER_NAME" -o sides=one-sided

# Set the default printer
lpoptions -d "$PRINTER_NAME"

# Restart CUPS service
sudo systemctl restart cups.service
