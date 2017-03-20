#!/bin/sh
export PKG_LOC=/var/vcap/packages/openscap

cp /var/vcap/jobs/openscap/conf/oscap.conf $PKG_LOC/etc/oscap.conf 

LOG_DIR=/var/vcap/sys/log/openscap
RUN_DIR=/var/vcap/sys/run/openscap
if [ ! -d "${LOG_DIR}" ]; then
	mkdir -p ${LOG_DIR}
	touch ${LOG_DIR}/openscap.log
fi
if [ ! -d "${RUN_DIR}" ]; then
	mkdir -p ${RUN_DIR}
fi
if [ ! -d "/var/lib/openscap" ]; then
	mkdir -p /var/lib/openscap
fi


case "$1" in
	'start_oscap')
	  $PKG_LOC/sbin/oscap -c $PKG_LOC/etc/oscap.conf
	  (crontab -l | sed /openscap.*scan/d; cat /var/vcap/jobs/openscap/conf/openscap_dailyscan.cron) | sed /^$/d | crontab
	  (crontab -l | sed /openscap.*logrotate/d; cat /var/vcap/jobs/openscap/conf/openscap_logrotate.cron) | sed /^$/d | crontab
	  sleep 1
	;;
	'stop_oscap')
	  kill `pidof oscap`
	;;
esac
