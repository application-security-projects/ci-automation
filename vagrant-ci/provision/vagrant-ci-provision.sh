#!/bin/bash
#
# Automated Security Scanning in CI with Jenkins + TestNG + WebDriver + Arachni Scanner 
# Author: Anton Abashkin
#

#Installing as vagrant user, uncomment if needed
su vagrant


#Config jenkins & tools
export ASDIR="arachni-1.1-0.5.7"
ASVERSION="$ASDIR-linux-x86_64" 
ASHOME=/usr/share/arachni/$ASDIR
ASURL="http://downloads.arachni-scanner.com/$ASVERSION.tar.gz"

JENKINS_HOST="http://localhost:8181"
JENKINS_HOME="/var/lib/jenkins"


#Install Jenkins
wget -q -O - https://jenkins-ci.org/debian/jenkins-ci.org.key | sudo apt-key add -
sudo sh -c 'echo deb http://pkg.jenkins-ci.org/debian binary/ > /etc/apt/sources.list.d/jenkins.list'
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password password temppass'
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password temppass'
sudo apt-get update
sudo apt-get install -y git jenkins mysql-server tomcat7 maven firefox xvfb openjdk-7-jdk

sudo cat /etc/default/jenkins | sed -e "s/HTTP_PORT=8080/HTTP_PORT=8181/" > ~/jenkins_tmp_config
sudo mv ~/jenkins_tmp_config /etc/default/jenkins


#Download setup scripts
cd ~
mkdir -p git
cd git
git clone https://github.com/application-security-projects/wavsep-tests
git clone https://github.com/application-security-projects/ci-automation
chmod u+x ~/git/ci-automation/*.sh


#Install WAVSEP
sudo cp ~/git/ci-automation/wavsep15.war /var/lib/tomcat7/webapps/wavsep.war


#Tomcat performance hack and remote debugging. Recommendation: Comment out if running on less than 4 GB RAM.
echo "JAVA_OPTS=\"-Djava.awt.headless=true -Xms1024m -Xmx2048m -XX:NewSize=256m -XX:MaxNewSize=256m -XX:PermSize=256m -XX:MaxPermSize=256m -XX:+UseConcMarkSweepGC -Xdebug -Xrunjdwp:transport=dt_socket,address=8000,server=y,suspend=n\"" | sudo tee --append /etc/default/tomcat7

sudo service tomcat7 restart
echo '127.0.0.1     wavsep.test' | sudo tee --append /etc/hosts
sudo mkdir -p /var/lib/tomcat7/db
sudo chown tomcat7:tomcat7 /var/lib/tomcat7/db/
curl --data "username=root&password=temppass&host=localhost&port=3306&wavsep_username=&wavsep_passwd=" http://wavsep.test:8080/wavsep/wavsep-install/install.jsp


#NETWORKING FIX: Host only interface overwrites the proper gateway for Internet access. REMOVE IF NEEDED
sudo cp ci-automation/vm-networking-fix.sh /etc/init.d/
sudo chmod +x /etc/init.d/vm-networking-fix.sh
sudo update-rc.d vm-networking-fix.sh defaults


#Install Arachni Scanner
sudo mkdir -p /usr/share/arachni
GROUP=`groups | cut -d" " -f1`
sudo chown -R $USER:users /usr/share/arachni/
cd /usr/share/arachni

#cp ~/*.tar.gz .
curl --output $ASVERSION.tar.gz $ASURL
tar -zxvf $ASVERSION.tar.gz
cp -R ~/git/ci-automation/custom $ASDIR/
chmod +x $ASDIR/custom/*.sh
sudo chown -R jenkins:users $ASDIR

export PATH=$ASHOME/bin:$PATH
export PATH=$ASHOME/custom:$PATH
 
sudo touch /etc/profile.d/env_setup.sh
echo "export ASHOME="$ASHOME | sudo tee --append /etc/profile.d/env_setup.sh
echo "export PATH=\$ASHOME/custom:"$PATH | sudo tee --append /etc/profile.d/env_setup.sh
echo "export PATH=\$ASHOME/bin:\$PATH" | sudo tee --append /etc/profile.d/env_setup.sh
echo "export ASVERSION="$ASVERSION | sudo tee --append /etc/profile.d/env_setup.sh
echo "export JENKINS_HOME="$JENKINS_HOME | sudo tee --append /etc/profile.d/env_setup.sh

sudo service jenkins restart

#Test arachni executable
arachni --version


#Configuration Jenkins jobs
cd ~
curl --silent http://localhost:8181/
sleep 30
curl http://localhost:8181/jnlpJars/jenkins-cli.jar > jenkins-cli.jar
curl -L https://updates.jenkins-ci.org/latest/git.hpi > git.hpi
curl -L http://updates.jenkins-ci.org/update-center.json | sed '1d;$d' | curl -X POST -H 'Accept: application/json' -d @- http://localhost:8181/updateCenter/byId/default/postBack
java -jar jenkins-cli.jar -s $JENKINS_HOST install-plugin git-client htmlpublisher scm-api -deploy -restart
java -jar jenkins-cli.jar -s $JENKINS_HOST install-plugin git.hpi -deploy -restart
sleep 30
java -jar jenkins-cli.jar -s $JENKINS_HOST create-job Arachni_Test < ~/git/wavsep-tests/jobs/Arachni_Test.xml
java -jar jenkins-cli.jar -s $JENKINS_HOST create-job Arachni_WAVSEP_WebUI_ReportUpload_Test < ~/git/wavsep-tests/jobs/Arachni_WAVSEP_WebUI_ReportUpload_Test.xml
java -jar jenkins-cli.jar -s $JENKINS_HOST create-job Arachni_WAVSEP_ALL_proxied < ~/git/wavsep-tests/jobs/Arachni_WAVSEP_ALL_proxied.xml
java -jar jenkins-cli.jar -s $JENKINS_HOST create-job Arachni_WAVSEP_XSS_proxied < ~/git/wavsep-tests/jobs/Arachni_WAVSEP_XSS_proxied.xml
java -jar jenkins-cli.jar -s $JENKINS_HOST create-job Arachni_WAVSEP_SQLi_proxied < ~/git/wavsep-tests/jobs/Arachni_WAVSEP_SQLi_proxied.xml
java -jar jenkins-cli.jar -s $JENKINS_HOST create-job Arachni_WAVSEP_RFI_proxied < ~/git/wavsep-tests/jobs/Arachni_WAVSEP_RFI_proxied.xml
java -jar jenkins-cli.jar -s $JENKINS_HOST create-job Arachni_WAVSEP_LFI_proxied < ~/git/wavsep-tests/jobs/Arachni_WAVSEP_LFI_proxied.xml
java -jar jenkins-cli.jar -s $JENKINS_HOST create-job Arachni_WAVSEP_UnvalidatedRedirect_proxied < ~/git/wavsep-tests/jobs/Arachni_WAVSEP_UnvalidatedRedirect_proxied.xml
java -jar jenkins-cli.jar -s $JENKINS_HOST create-job Arachni_WAVSEP_XSS_crawled < ~/git/wavsep-tests/jobs/Arachni_WAVSEP_XSS_crawled.xml
java -jar jenkins-cli.jar -s $JENKINS_HOST create-job Arachni_WAVSEP_SQLi_crawled < ~/git/wavsep-tests/jobs/Arachni_WAVSEP_SQLi_crawled.xml
java -jar jenkins-cli.jar -s $JENKINS_HOST create-job Arachni_WAVSEP_RFI_crawled < ~/git/wavsep-tests/jobs/Arachni_WAVSEP_RFI_crawled.xml
java -jar jenkins-cli.jar -s $JENKINS_HOST create-job Arachni_WAVSEP_LFI_crawled < ~/git/wavsep-tests/jobs/Arachni_WAVSEP_LFI_crawled.xml
java -jar jenkins-cli.jar -s $JENKINS_HOST create-job Arachni_WAVSEP_UnvalidatedRedirect_crawled < ~/git/wavsep-tests/jobs/Arachni_WAVSEP_UnvalidatedRedirect_crawled.xml
java -jar jenkins-cli.jar -s $JENKINS_HOST create-job Arachni_WAVSEP_DOMXSS_crawled < ~/git/wavsep-tests/jobs/Arachni_WAVSEP_DOMXSS_crawled.xml
java -jar jenkins-cli.jar -s $JENKINS_HOST create-job Arachni_WAVSEP_FalsePositives_crawled < ~/git/wavsep-tests/jobs/Arachni_WAVSEP_FalsePositives_crawled.xml
curl -vvv -X POST -d @/home/$USER/git/wavsep-tests/jobs/wavsep_crawl_view.xml -H "Content-Type: text/xml" http://localhost:8181/createView?name=WAVSEP+%28Crawled%29
curl -vvv -X POST -d @/home/$USER/git/wavsep-tests/jobs/wavsep_proxy_view.xml -H "Content-Type: text/xml" http://localhost:8181/createView?name=WAVSEP+%28Proxied%29
curl -vvv -X POST -d @/home/$USER/git/wavsep-tests/jobs/wavsep_tests_view.xml -H "Content-Type: text/xml" http://localhost:8181/createView?name=Tests

java -jar jenkins-cli.jar -s http://localhost:8181 build 'Arachni_Test'

sudo mkdir -p $JENKINS_HOME/reports/arachni/unzipped
sudo mkdir -p $JENKINS_HOME/reports/arachni/tmpupload
sudo chown -R jenkins:jenkins $JENKINS_HOME/reports/

#Redsocks proxy setup
~/git/ci-automation/setup-redsocks.sh