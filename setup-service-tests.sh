#!/bin/bash
#
# Automated Security Scanning in CI with Jenkins + TestNG + WebDriver + Arachni Scanner 
# Author: Anton Abashkin
#
JENKINS_HOST="http://localhost:8181"

sudo apt-get update
sudo apt-get install -y build-essential libssl-dev


cd ~
mkdir -p git
cd git

git clone https://github.com/application-security-projects/wavsep-service  

sudo cp wavsep-service/wavsep-service.war /var/lib/tomcat7/webapps/wavsep-service.war

sudo -H -u jenkins bash -c $HOME'/git/setup-scripts/setup-newman.sh' 

cd ~
java -jar jenkins-cli.jar -s $JENKINS_HOST create-job Arachni_WAVSEP_RFI_service < ~/git/wavsep-service/jobs/Arachni_WAVSEP_RFI_service.xml
java -jar jenkins-cli.jar -s $JENKINS_HOST create-job Newman_Test < ~/git/wavsep-service/jobs/Newman_Test.xml
curl -vvv -X POST -d @/home/$USER/git/wavsep-service/jobs/wavsep_services_view.xml -H "Content-Type: text/xml" http://localhost:8181/createView?name=WAVSEP+Services

