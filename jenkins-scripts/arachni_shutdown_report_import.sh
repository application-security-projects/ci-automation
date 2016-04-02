#!/bin/bash

echo "Test finished, shutting down the proxy..."
curl --proxy localhost:8282 http://arachni.proxy/shutdown || true

while [ ! -f $JENKINS_HOME/reports/arachni/$BUILD_TAG.afr  ] ;
do
        echo "Waiting for audit to finish and generate report"
        sleep 15
done

#Generate report
arachni_reporter --reporter html:outfile=$JENKINS_HOME/reports/arachni/${BUILD_TAG}-report.zip $JENKINS_HOME/reports/arachni/${BUILD_TAG}.afr

cp $JENKINS_HOME/reports/arachni/${BUILD_TAG}.afr $JENKINS_HOME/reports/arachni/tmpupload/

#Set remote vars
export LC_DOMAIN=$DOMAIN
export LC_TEAM=$TEAM
export LC_USERNAME=$USERNAME

#Upload and import
echo "Uploading report to WebUI server..."
scp -o StrictHostKeyChecking=no -i $KEY_SCP $JENKINS_HOME/reports/arachni/tmpupload/* $USERNAME@$WEBUIHOST:./tmpupload
echo "Importing report into WebUI"
ssh -o StrictHostKeyChecking=no -i $KEY_WRAPPER $USERNAME@$WEBUIHOST "arachni_web_scan_import"

#Clean temporary dirs
rm -rf $JENKINS_HOME/reports/arachni/unzipped/*
rm -rf $JENKINS_HOME/reports/arachni/tmpupload/*

#Unzip the HTML report
unzip $JENKINS_HOME/reports/arachni/${BUILD_TAG}-report.zip -d $JENKINS_HOME/reports/arachni/unzipped