#!/bin/bash
#
# Automated Security Scanning in CI with Jenkins + TestNG + WebDriver + Arachni Scanner 
# Author: Anton Abashkin
#

curl https://raw.githubusercontent.com/creationix/nvm/v0.23.3/install.sh | bash
. ~/.nvm/nvm.sh
echo ". ~/.nvm/nvm.sh" >> ~/.profile
nvm ls-remote
nvm install 0.12
nvm alias default 0.12
nvm use default
npm install -g newman