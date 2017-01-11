##Automated Dynamic Security Scanning in CI with Jenkins + TestNG + WebDriver + WAVSEP demo + Arachni Scanner 

http://jenkins-ci.org/  

http://testng.org/doc/index.html  

http://docs.seleniumhq.org/projects/webdriver/  

https://code.google.com/p/wavsep/  

http://www.arachni-scanner.com/  


##Project Overview

* Problem: How do we help web application security keep up in a world of high velocity software development?
* Solution: Take existing tests for web applications/services and proxy them into a dynamic security analysis tool (Arachni) as part of a Continuous Integration (CI) process.
* The main benefit: Creates a new level of security automation by leveraging well-maintained tests in suites familiar to engineers in order to automatically update the scan configuration of the security tool whenever the test changes.
 * Security teams spend less time on the maintaining the tool
 * Allows the utilization of complex data providers through test suites which cannot be easily programmed into a security tool directly.

TestNG + WebDriver is the testsuite used in this example, but anything that produces an HTTP request can be used.

Other examples of clients:
* Postman and other API clients
* Web testing frameworks such as PhantomJS & Waitr
* Mobile App emulators


##The Magic

One of the biggest goals for this project was to be able to proxy anything, even if proxy capabilities were not implemented on that particular client. The linux client for newman is an example of a widely used client with no proxy capabilities for version 1.x and 2.x . The Android emulator is another good example, because adding `-http-proxy http://<local-ip-address>:<port>` only proxies browser traffic, it will not pick up any requests sent by apps. These types of usecases are addressed by this project.

But wait, you say, what about popular frameworks like Selenium? These have well established proxy capabilities built in. Why not use those?

The answer is all about scalability. A large organization with thousands of tests could save itself a good deal of time by not having to change the code at all. This also allows DevOps to step in and start running tests without needing write access to the git. The original test, say `"mvn clean test -e -Dtestng.suite="testng_wavsep_quick.xml"` gets executed by our system as the 'proxied' group, like so: `sg proxied -c "mvn clean test -e -Dtestng.suite=\"testng_wavsep_quick.xml\"`

Why are we using `sg` to run the test as a different linux group? Because in the script `setup-redocks.sh` there is a series of iptables rules which get applied to all processes running under the 'proxied' group. This traffic is sent to port 12345, where our redsocks server is listening. Redsocks takes any client connecting to it and proxies it transparently.

Now that we have full control over our network flow, all that needs to be done is run our web security scanner (Arachni) in proxy mode so that our test suite can "teach it" our application as it runs. Here is a visual idea:

![alt text](https://github.com/application-security-projects/ci-automation/raw/master/screenshots/diagram_overview.png)

This is what a typical test will look like. Keep in mind, we did not have to alter our original test code at all, we simply had to clone an existing CI job and add our wrapper script:

```
##########Pre Test##########

#Configuration
TARGET="http://wavsep.test:8080"
#CHECKS="xss"
CHECKS="xss,xss_path,xss_event,xss_tag,xss_script_context,sql*,rfi,path_traversal,file_inclusion,unvalidated_redirect"


### Run Arachni with specified checks in proxy mode
arachni $TARGET --daemon-friendly --scope-page-limit=0 --plugin=proxy:ignore_responses=true --checks=$CHECKS --audit-forms --report-save-path=$JENKINS_HOME/reports/arachni/$BUILD_TAG.afr &


##########Maven Test##########


sg proxied -c "mvn clean test -e -Dtestng.suite=\"testng_wavsep_quick.xml\""


##########Post Test##########

echo "Test finished, shutting down the proxy..."
curl --proxy localhost:8282 http://arachni.proxy/shutdown || true

while [ ! -f $JENKINS_HOME/reports/arachni/$BUILD_TAG.afr  ] ;
do
        echo "Waiting for audit to finish and generate report"
        sleep 15
done

#Generate report
arachni_reporter --reporter html:outfile=$JENKINS_HOME/reports/arachni/${BUILD_TAG}-report.zip $JENKINS_HOME/reports/arachni/${BUILD_TAG}.afr
```


##Setup Guide - Standalone demo

* The install scripts can be run on any Linux system (Ubuntu 14.04 recommended)
* For demo purposes, the Vagrant scripts come preconfigured with Virtualbox VM networking settings. By default, this creates a Host-Only adapter assigned to IP `192.168.56.102`. Please edit the `/vagrant-ci/Vagrantfile` to meet your networking requirements if necessary.
* The demo is self-contained and may be run on its own. It runs an instance of the vulnerable test app **WAVSEP** in a local Tomcat instance. If you would like to test performance, you may move the web server off to a remote instance and point the CI tests there.

### Part 1 - Setting up VM's

* Download and install vagrant [LINK](http://www.vagrantup.com/downloads.html)
* Clone the git
```
git clone https://github.com/application-security-projects/ci-automation.git
```
* (Windows) Navigate to the 'vagrant_ci' directory. Right click --> Open command window here
```
vagrant up
```

* Download and install PuTTY [LINK](http://www.chiark.greenend.org.uk/~sgtatham/putty/download.html)
* Configure PuTTY to use vagrant's private key.
 * Connection --> SSH --> Auth --> "Private key file for authentication:"
 * Default location: C:\Users\%USER%\.vagrant.d\insecure_private_key

### Part 2 - Usage
* Navigate to http://localhost:8181/ to access the Jenkins instance
* Choose any job and click Build Now
* Wait for the build and the scan to finish. You can watch the Console Output section to see what is happening under the hood
* View the HTML report from the sidebar in the finished job

### Part 3 - Screenshots
Jenkins Dashboard:
![alt text](https://github.com/application-security-projects/ci-automation/raw/master/screenshots/ss_jenkins.png)
Job running -- proxy opened, TestNG suite started:
![alt text](https://github.com/application-security-projects/ci-automation/raw/master/screenshots/ss_jenkins_log1.png)
Job running -- proxy closed, auditing begins:
![alt text](https://github.com/application-security-projects/ci-automation/raw/master/screenshots/ss_jenkins_log2.png)
Job running -- auditing complete, report generated
![alt text](https://github.com/application-security-projects/ci-automation/raw/master/screenshots/ss_jenkins_log3.png)

##Setup Guide - Remote CI scan, Remote WebUI (SaaS model)
TODO

Author: Anton Abashkin  
