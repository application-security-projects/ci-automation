#!/bin/bash
#
# Automated Security Scanning in CI with Jenkins + TestNG + WebDriver + Arachni Scanner 
# Author: Anton Abashkin
#

#Host only interface overwrites the proper gateway for Internet access, remove if needed
sudo route del default
sudo route add default gw 10.0.2.2
sudo ifdown eth0 && sudo ifup eth0