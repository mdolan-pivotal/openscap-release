#!/bin/bash


# Location of log file
LOG_FILE="/var/vcap/sys/log/openscap/openscap-scan.log"
HTML_FILE="/var/vcap/sys/log/openscap/results.html"
XML_RESULTS="/var/vcap/sys/log/openscap/report.xml"
SSG_FILE="/var/vcap/packages/scap/ssg/ssg-ubuntu1404-xccdf.xml"
CPE_FILE="/var/vcap/packages/scap/ssg/ssg-ubuntu1404-cpe-dictionary.xml"
PROFILE="common"


# Value of 0 will not remove files
# Value of 1 will remove files
AGGRESSIVE=0

# Value of 0 will not send an email upon discovery
# Value of 1 will send a summary email upon discovery
SEND_EMAIL=0

# Email Subject
SUBJECT="OpenSCAP scan results on `hostname`"
# Email To
EMAIL="your.email@your.domain.com"
# Email From
EMAIL_FROM="openscap@server.hostname.com"

check_scan () {
    # If there were infected files detected, send email alert
 
    # Count number of infections
        SCAN_RESULTS=$( grep 'score-val' | head -1)
        #INFECTIONS=${SCAN_RESULTS##* }
 
        EMAILMESSAGE=`mktemp /tmp/openscap-alert.XXXXX`
        echo "To: ${EMAIL}" >>  ${EMAILMESSAGE}
        echo "From: ${EMAIL_FROM}" >>  ${EMAILMESSAGE}
        echo "Subject: ${SUBJECT}" >>  ${EMAILMESSAGE}
        echo "Importance: High" >> ${EMAILMESSAGE}
        echo "X-Priority: 1" >> ${EMAILMESSAGE}

        #if [[ $AGGRESSIVE -eq 1 ]]
        #then
            #echo -e "\n`tail -n $((10 + ($INFECTIONS*2))) $LOG_FILE`" >> ${EMAILMESSAGE}
        #else
            #echo -e "\n`tail -n $((10 + $INFECTIONS)) $LOG_FILE`" >> ${EMAILMESSAGE}
        #fi
           cat $HTML_FILE >> ${EMAILMESSAGE} 

        sendmail -t < ${EMAILMESSAGE}
    fi
}

# Ensure a previous scan is not still running
running=`pgrep oscap`
if [[ $? -eq 0 ]]
then
    echo "don't run because process already running - pid $running" 1>&2
    exit 1
fi

if [[ $AGGRESSIVE -eq 1 ]]
then
    #/var/vcap/packages/openscap/bin/clamscan -ri --exclude-dir=^/sys\|^/proc\|^/dev --remove --stdout $SCAN_DIR
    /var/vcap/packages/openscap/bin/oscap xccdf eval --remediate --profile ${PROFILE} --report ${HTML_FILE} --cpe ${CPE_FILE} --results ${XML_RESULTS} ${SSG_FILE}
else
    #/var/vcap/packages/openscap/bin/clamscan -ri --exclude-dir=^/sys\|^/proc\|^/dev --stdout $SCAN_DIR
    /var/vcap/packages/openscap/bin/oscap xccdf eval --profile ${PROFILE} --report ${HTML_FILE} --cpe ${CPE_FILE} --results ${XML_RESULTS} ${SSG_FILE}
fi

if [[ $SEND_EMAIL -eq 1 ]]
then
    check_scan
fi

exit 0
