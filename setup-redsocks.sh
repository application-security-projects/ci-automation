#!/bin/bash

sudo apt-get install -y redsocks

sudo groupadd proxied
sudo usermod -a -G proxied jenkins

# Create new chain
sudo iptables -t nat -N REDSOCKS

# Ignore LANs and some other reserved addresses.
# See http://en.wikipedia.org/wiki/Reserved_IP_addresses#Reserved_IPv4_addresses
# and http://tools.ietf.org/html/rfc5735 for full list of reserved networks.
sudo iptables -t nat -A REDSOCKS -d 0.0.0.0/8 -j RETURN
#sudo iptables -t nat -A REDSOCKS -d 10.0.0.0/8 -j RETURN
#sudo iptables -t nat -A REDSOCKS -d 127.0.0.0/8 -j RETURN
sudo iptables -t nat -A REDSOCKS -d 169.254.0.0/16 -j RETURN
sudo iptables -t nat -A REDSOCKS -d 172.16.0.0/12 -j RETURN
#sudo iptables -t nat -A REDSOCKS -d 192.168.0.0/16 -j RETURN
sudo iptables -t nat -A REDSOCKS -d 224.0.0.0/4 -j RETURN
sudo iptables -t nat -A REDSOCKS -d 240.0.0.0/4 -j RETURN

# Anything else should be redirected to port 12345
sudo iptables -t nat -A REDSOCKS -p tcp -j REDIRECT --to-ports 12345

# Any tcp connection made by user in group newman should be redirected.
sudo iptables -t nat -A OUTPUT -p tcp -m owner --gid-owner proxied -j REDSOCKS

sudo cp ~/git/ci-automation/redsocks.conf /etc/redsocks.conf
sudo service redsocks restart &