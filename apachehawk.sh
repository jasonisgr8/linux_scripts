#!/bin/bash

# block all ips that 404, except mine.

SAFE1="173.226.216.162"
SAFE2="EXAMPLE-117.91.10.141"
SAFE3="EXAMPLE-some-cool-path-to-ignore"
SAFE4="EXAMPLE-special-user-agent"
SAFE5="93.94.121"

if [ "$UID" != "0" ];then
echo "I am not root, lets try again with sudo..."
sudo $0
exit 0
fi

log_and_print ()
{
  echo "       " $1
  logger apache-hawk - $1
}

while :
do
SUSPECT="`cat /var/log/apache2/access.log | grep 404 | grep -v $SAFE1 | grep -v $SAFE2 | grep -v $SAFE3 | grep -v $SAFE4 | grep -v $SAFE5 | awk '{ print $1 }' | sort | uniq`"

for EACH in $SUSPECT; do
if [ ! "`cat /etc/hosts.deny | grep $EACH`" ]; then
    log_and_print "$EACH: This guy is not in the hosts.deny list, adding..."
    echo "ALL: $EACH" >> /etc/hosts.deny
 fi
 if [ ! "`iptables -L -n | grep $EACH`" ];then
        log_and_print "$EACH: This guy is not in iptables, adding..."
        iptables -A INPUT -s $EACH -j DROP
 fi

done
sleep 2m
done

exit 0
