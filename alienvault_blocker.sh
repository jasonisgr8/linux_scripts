#!/bin/bash
# Pull and block AlienVault bad guys via iptables.

log_and_print ()
{
  echo "       " $1
  logger reputationdb-av - $1
}
# get the hosts.deny tarball from alienvault labs
log_and_print "Preparing to get AlienVault data..."
mkdir -p /tmp/reputationdb-av
cd /tmp/reputationdb-av
wget http://reputation.alienvault.com/reputation.unix.gz
gunzip reputation.unix.gz

SUSPECT="`grep ALL /tmp/reputationdb-av/reputation.unix | awk -F: '{ print $2 }' | sed 's/^\ //g' | awk '{ print $1 }'`"
log_and_print "Processing reputation database..."
for EACH in $SUSPECT; do
 if [ ! "`grep $EACH /etc/hosts.deny`" ]; then
    log_and_print "$EACH: This guy is not in the hosts.deny list, adding..."
    echo "ALL: $EACH" >> /etc/hosts.deny
#    else log_and_print "$EACH: hosts.deny already has this one, :) skipping..."
 fi
 if [ ! "`iptables -L -n | grep $EACH`" ];then
	log_and_print "$EACH: This guy is not in iptables, adding..."
    	iptables -A INPUT -s $EACH -j DROP
#	else log_and_print "$EACH: iptables already has this one, :) skipping..."
 fi
#echo "..."
done
rm -fr /tmp/reputationdb-av
log_and_print "Done."
exit 0
