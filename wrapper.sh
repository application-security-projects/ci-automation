#!/bin/bash
#
# Automated Security Scanning in CI with Jenkins + TestNG + WebDriver + Arachni Scanner
# Author: Anton Abashkin
#

#Read remote SSH environment variables

COMMAND=$SSH_ORIGINAL_COMMAND

source /etc/profile.d/env_setup.sh

#export ARGS="$2"
#ARGS=$LC_ARGS
#ARGS=`echo $ARGS | sed -e 's/[|]/ /g' -e 's/[&&]/ /g'`
#TODO: Secure arguments parameter. Use OWASP encoding library or similar


case "$COMMAND" in

         "scp")
                scp -v -t ~/tmpupload
                ;;

        "arachni_web_scan_import")
                REPORT=`echo ~`"/tmpupload/"`ls ~/tmpupload`
                USERNAME=`echo ~/email`
                USERID=`cat ~/userid`
				arachni_web_script 'ScanGroup.find_or_create_by( name: "'$LC_TEAM'", description: "Created by Import", owner: User.find( '$USERID' ) )'
				arachni_web_script 'ScanGroup.find_or_create_by( name: "'$LC_DOMAIN'", description: "Created by Import", owner: User.find( '$USERID' ) )'
                TEAM=`arachni_web_script -c 'p ScanGroup.where( name: "'$LC_TEAM'" ).first.id'`
                DOMAIN=`arachni_web_script -c 'p ScanGroup.where( name: "'$LC_DOMAIN'" ).first.id'`
				
                arachni_web_scan_import "$REPORT" "$USERID" --groups "$DOMAIN","$TEAM"
                rm ~/tmpupload/*
                ;;

        "test")
                echo "$USER"
				echo "$LC_TEAM"
                echo "$LC_DOMAIN"
                ;;

        *)
                echo "Unsupported command"
                ;;

		
esac
	
	
#TODO: SSH tunnel port forwarding and Arachni proxy binding on localhost only for added security