#!/bin/bash
#
# Automated Security Scanning in CI with Jenkins + TestNG + WebDriver + Arachni Scanner 
# Author: Anton Abashkin
#

sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password password temppass'
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password temppass'
sudo apt-get update
sudo apt-get install -y git mysql-server tomcat7 maven openjdk-7-jdk

sudo cat /etc/default/jenkins | sed -e "s/HTTP_PORT=8080/HTTP_PORT=8181/" > ~/jenkins_tmp_config
sudo mv ~/jenkins_tmp_config /etc/default/jenkins

cd ~
mkdir -p git
cd git
git clone https://github.com/application-security-projects/wavsep-tests
git clone https://github.com/application-security-projects/ci-automation
chmod u+x ~/git/ci-automation/*.sh

sudo cp ~/git/ci-automation/wavsep15.war /var/lib/tomcat7/webapps/wavsep.war

#Tomcat performance hack and remote debugging. Recommendation: Comment out if running on less than 4 GB RAM.
echo "JAVA_OPTS=\"-Djava.awt.headless=true -Xms1024m -Xmx2048m -XX:NewSize=256m -XX:MaxNewSize=256m -XX:PermSize=256m -XX:MaxPermSize=256m -XX:+UseConcMarkSweepGC -Xdebug -Xrunjdwp:transport=dt_socket,address=8000,server=y,suspend=n\"" | sudo tee --append /etc/default/tomcat7

sudo service tomcat7 restart
echo '127.0.0.1     wavsep.test' | sudo tee --append /etc/hosts
sudo mkdir -p /var/lib/tomcat7/db
sudo chown tomcat7:tomcat7 /var/lib/tomcat7/db/
curl --data "username=root&password=temppass&host=localhost&port=3306&wavsep_username=&wavsep_passwd=" http://wavsep.test:8080/wavsep/wavsep-install/install.jsp
