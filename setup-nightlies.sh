#!/bin/bash
#
# Automated Security Scanning in CI with Jenkins + TestNG + WebDriver + Arachni Scanner 
# Author: Anton Abashkin
#

#Nightly builds
export ASDIR="arachni-2.0dev-1.0dev"
export ASVERSION="$ASDIR-linux-x86_64" 
export ASHOME=/usr/share/arachni/$ASDIR
ASURL="http://downloads.arachni-scanner.com/nightlies/$ASVERSION.tar.gz"

sudo mkdir -p /usr/share/arachni
sudo chown -R $USER:users /usr/share/arachni/
cd /usr/share/arachni

#cp ~/*.tar.gz .
curl --output $ASVERSION.tar.gz $ASURL
tar -zxvf $ASVERSION.tar.gz
cp -R ~/git/setup-scripts/custom $ASDIR/
chmod +x $ASDIR/custom/*.sh
sudo chown -R jenkins:users $ASDIR

export PATH=$ASHOME/bin:$PATH
export PATH=$ASHOME/custom:$PATH
 
sudo touch /etc/profile.d/env_setup.sh
echo "export ASHOME="$ASHOME | sudo tee --append /etc/profile.d/env_setup.sh
echo "export PATH=\$ASHOME/custom:"$PATH | sudo tee --append /etc/profile.d/env_setup.sh
echo "export PATH=\$ASHOME/bin:\$PATH" | sudo tee --append /etc/profile.d/env_setup.sh

#Logout, login for PATH changes