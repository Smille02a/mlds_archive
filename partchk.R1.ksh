#!/bin/ksh
#set -o xtrace
##################################################################
#
#       Archive Store and Arrival Script
#       /usr/local/bin/partchk.R1.ksh
#
#       Created:   09/13/95
#       Modified:  09/13/95
#
#       Merrill Lynch
#       Stephen Miller, SA
#               Phone:  (212)
#               Beeper: (800) 225-0256 pin 95684
#               email:  smiller@ml.com
#
#       This script is designed to be run by root, and will
#	collect disk information wrt both SunOs and Solaris machines
#
#       It will email one report to sysdoc, and will also create
#	a log file in hostname:/tmp/ called 
#	`uname -n`_disk_info_`date +%m%d%y`.log
#	
#	i.e. sparc10:/tmp/sparc10_disk_info_091395.log
#
##################################################################
#
df_info()
{
print "\n`date`\n\tChecking $HOST mounted partitions...\n\n"
if [[ "$ARCH" = "SunOS" ]]; then
	df -t 4.2
	print "\n\nFormat Expect Script...\n\n"
	if [ -x /usr/local/admin/scr/formatlist.ex ]; then
		/usr/local/admin/scr/formatlist.ex
	else
		 print "\t /usr/local/admin/formatlist.ex not found\n"
	fi
else
	df -k
fi
}
dk_info()
{
print "\n`date`\n\tChecking $HOST dkinfo of attached disks...\n\n"
if [[ "$ARCH" = "SunOS" ]]; then
	cd /dev
	dkinfo sd* 
	sleep 1
else
	cd /dev/dsk
	ls
	echo ""
	prtvtoc *
	sleep 1
fi
}
syb_info()
{
print "\n`date`\n\tChecking $HOST SYBASE owned partitions...\n\n"
if [[ "$ARCH" = "SunOS" ]]; then
	cd /dev
	ls -alF |grep sybase
	sleep 1
else
	cd /dev/dsk
	ls -alF |grep sybase
	sleep 1
fi
}
export_info()
{
print "\n`date`\n\tChecking $HOST exported filesystem info...\n\n"
if [[ "$ARCH" = "SunOS" ]]; then
	exportfs
else
	share
fi
}
close()
{
if [ "$status" = "success" ]; then
	print "\n`date`\n\t$VERSION completed successfully on $HOST"
	print "\t\tLogfile can be found on $HOST:$LOGFILE"
	print "\n`date`\n\t******** DONE *********\n\n"
	cat $LOGFILE | /usr/ucb/mail \
	   -s "$HOST: System disk information on $DATE" sysdoc
else
	print "\n`date`\n\t$VERSION errored on $HOST"
	print "\t\tLogfile can be found on $HOST:$LOGFILE"
	cat $LOGFILE | /usr/ucb/mail \
	  -s "$HOST: ERROR System disk information on $DATE" sysdoc
	exit 1
fi
}
#
##################################################################
## MAIN
##################################################################
#
VERSION="/usr/local/admin/scr/partchk.R1.ksh"
DATE=`date +%m%d%y`
ARCH=`uname -r` # Changed 10 lines later 
HOST=`uname -n`
MAIL_LIST="sysdoc"
LOGFILE="/tmp/`uname -n`_disk_info_$DATE.log"
TMPFILE="/tmp/$HOST_disk_info_$DATE.tmp"
ERRLOG="/tmp/$HOST_disk_info_$DATE.err"
BEEP="/usr/local/bin/beep"
#
WHO=`/usr/ucb/whoami`
if [[ "$WHO" != "root" ]]; then
    echo ""
    echo "You are not root.  Please su to root and run again"
    echo ""
    exit 1
fi
#
# if [[ "$ARCH" = "5.4" ]] ||  [[ "$ARCH" = "5.3" ]]; then
if [[ "$ARCH" = "5.4" || "$ARCH" = "5.3" ]]; then
	ARCH="Solaris"
else
	ARCH="SunOS"
fi
#
>$LOGFILE
#
print "\nThis logfile file has been created  on `date` "  >> $LOGFILE
print "\n\tHostname:    $HOST" >> $LOGFILE
print "\tScript name: $VERSION"  >> $LOGFILE
print "\tLog file:    $LOGFILE\n"  >> $LOGFILE
print "It depicts the current state of disk resources\n\n" >> $LOGFILE
print "This machine is a $ARCH machine  --SWM\n\n" >> $LOGFILE
#
#
if `df_info >> $LOGFILE 2>&1`; then
	if `dk_info >> $LOGFILE 2>&1`; then
		if `syb_info >> $LOGFILE 2>&1`; then
			if `export_info >> $LOGFILE 2>&1`; then
				status="success"
			else
				status="failure"
				print "\t\tCommand failed on export_info"
			fi
		else
			status="failure"
			print "\t\tCommand failed on syb_info"
		fi
	else
		status="failure"
		print "\t\tCommand failed on dk_info"
	fi
else
	status="failure"
	print "\t\tCommand failed on df_info"
	exit 1
fi
#close >> $LOGFILE 2>&1
##################################################################
## DONE
##################################################################
