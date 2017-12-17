#!/bin/bash

VERSION="2.0"
# Usage: ./portsmack.sh 

## Changelog

# 2.0 - Bugfixes and added "status" to show recent stats and log data
#       Usage: ./portsmack.sh status 
# 1.4 - Added better port reporting
# 1.3 - Added check for netcat dependancy
# 1.2 - Added comments
# 1.1 - Updated logging
# 1.0 - Private release

# Identify which ports you want to listen on.
PORTS="21
23
1433
445
"

# Identify which hosts you want to whitelist. NOTE: you can duplicate entries if you do not have 4 to whitelist.
# If you want to add more whitelisted IPs, make sure to add them to the SUSPECT variable.
WHITELIST1="127.0.0"
WHITELIST2="117.121.10.46"
WHITELIST3="72.36.166.162"
WHITELIST4="188.104.216"

SUSPECT="`sudo grep PortSmack /var/log/syslog | awk -F[ '{ print $3 }' | awk -F] '{ print $1 }' |sort | uniq | grep -v $WHITELIST1 | grep -v $WHITELIST2 | grep -v $WHITELIST3 | grep -v $WHITELIST4`"

##### YOU SHOULD NOT HAVE TO EDIT BELOW THIS POINT #####

log_and_print ()
{
  echo "       " $1
  logger PortSmack - $1
}

if [ "$UID" != "0" ];then
echo "I am not root, lets try again with sudo..."
if [ $1 ];then
sudo $0 $1
else sudo $0
fi
exit 0
fi

if [ ! "`which netcat`" ];then
echo "I can not find netcat, exiting."
exit 0
fi

if [ "$1" == "status" ]; then
clear
SEPERATOR="++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo $SEPERATOR
echo "++ /etc/hosts.deny: `grep ALL /etc/hosts.deny | wc -l` blocked IP addresses."
echo "++ syslog shows `grep -i portsmack /var/log/syslog | grep connect\ to | wc -l` blocked IP addresses in the last 24 hours."
echo $SEPERATOR
echo "++ Top Port hits (last 24 hours):"

PORTS="`grep PortSmack /var/log/syslog | grep connect | grep Port\: | awk -FPort\: '{ print $2 }' | awk -F\  '{ print $1 }' | sort | uniq`"
for each in $PORTS
do
echo "++ Port $each: `grep PortSmack /var/log/syslog | grep connect | grep Port\: | awk -FPort\: '{ print $2 }' | awk -F\  '{ print $1 }' | sort | grep $each | wc -l` hits"
done
echo $SEPERATOR
echo "Recent syslog activity:"
tail -n45 /var/log/syslog | grep PortSmack
exit 0
fi


echo '#!/bin/bash' > /tmp/.response.sh
echo 'echo -e "I thought I smelled something phishy about you. Tisk Tisk...";' >> /tmp/.response.sh
chmod +x /tmp/.response.sh

while :
do
for each in $PORTS
do
if [ ! "`/usr/bin/lsof -i :$each`" ]; then
log_and_print "Port $each available, starting listener..."
netcat -v -l -p $each -e /tmp/.response.sh 2>&1 | sed -s "s/^/PortSmack\ -\ Port\:$each\ /g" | logger  &
log_and_print "Done."
else sleep 20
fi

for TARGET in $SUSPECT; do
if [ ! "`cat /etc/hosts.deny | grep $TARGET`" ]; then
    log_and_print "$TARGET: This guy is not in the hosts.deny list, adding..."
    echo "ALL: $TARGET" >> /etc/hosts.deny
 fi
 if [ ! "`iptables -L -n | grep $TARGET`" ];then
        log_and_print "$TARGET: This guy is not in iptables, adding..."
        iptables -A INPUT -s $TARGET -j DROP
 fi
done
done
done

exit 0
