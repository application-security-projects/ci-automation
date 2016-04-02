#!/bin/bash
#
# Automated Security Scanning in CI with Jenkins + TestNG + WebDriver + Arachni Scanner
# Author: Anton Abashkin
#
# Based on: https://github.com/aabashkin/spring-android-samples/blob/master/ci.sh

sudo dpkg --add-architecture i386
sudo apt-get install -y expect

expect -c '
set timeout -1;
spawn sudo add-apt-repository ppa:cwchien/gradle;
   expect {
                "to continue or ctrl-c to cancel adding it" { exp_send "\r" ; exp_continue }
                eof
   }
   '

sudo apt-get update
sudo apt-get install -y --force-yes openjdk-7-jdk libc6:i386 libncurses5:i386 libstdc++6:i386 lib32z1 gradle-1.11

#export PATH=/usr/sbin:/sbin:/usr/X11/bin:${PATH}
export ANDROID_HOME=/var/lib/jenkins/android-sdk-linux
export PATH=${ANDROID_HOME}/tools:${ANDROID_HOME}/platform-tools:${PATH}
echo "export ANDROID_HOME=/var/lib/jenkins/android-sdk-linux" | sudo tee --append /etc/profile.d/env_setup.sh
echo "export PATH=${ANDROID_HOME}/tools:${ANDROID_HOME}/platform-tools:${PATH}" | sudo tee --append /etc/profile.d/env_setup.sh

echo $PATH
echo $ANDROID_HOME

cd /var/lib/jenkins
sudo curl http://dl.google.com/android/android-sdk_r22.6.2-linux.tgz
sudo tar xzf android-sdk_r22.6.2-linux.tgz
sudo chown $USER android-sdk-linux -R
expect -c '
           set timeout -1   ;
           spawn android update sdk -f -u -a -t tools,platform-tools,build-tools-19.1,android-19,extra-android-m2repository,extra-android-support;
           expect {
                        "Do you accept the license" { exp_send "y\r" ; exp_continue }
                        eof
           }
           '

sudo chown jenkins:jenkins android-sdk-linux -R

emulator -help
