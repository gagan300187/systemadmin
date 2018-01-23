#!/bin/bash -x

DT=`/bin/date +%b" "%d`
RDT=`/bin/date +%y%m%d`
pass=unlocksoscall
passchange=unlocksospass

##check if system has filled up all resources
ls -ld /etc
if [ $? -ne 0]; then
reboot
fi

if [ ! -d /gbackup ]; then
/bin/mkdir -p /gbackup/default
fi
if [ ! -f /gbackup/default/sshd_config-orig ]; then
/bin/cp /etc/ssh/sshd_config /gbackup/default/sshd_config-orig
fi
if [ ! -f /gbackup/default/ssh_config-orig ]; then
/bin/cp /etc/ssh/ssh_config /gbackup/default/ssh_config-orig
fi
if [ ! -d /gbackup/data ]; then
mkdir -p /gbackup/data
fi
if [ ! -f /gbackup/data/runinfo-$RDT ]; then
touch /gbackup/data/runinfo-$RDT
fi

echo "Generating the list of all network interfaces"
find /etc -iname ifcfg-* | awk -F "/" '{print $NF}' | cut -f 2 -d "-" | sort | uniq > /gbackup/data/ifdetails 

a=`/bin/ps -ef | /bin/grep /usr/sbin/sshd | /bin/grep -v grep | /bin/awk '{print $1}'`
if [ -z $a ]; then
/etc/init.d/sshd restart
if [ $? -ne 0 ]; then
/bin/mv /etc/ssh/sshd_config /etc/ssh/sshd_config-`date +%m%d`
/bin/cp /gbackup/default/sshd_config-orig /etc/ssh/sshd_config
/bin/chmod 600 /etc/ssh/sshd_config
/bin/chown root:root /etc/ssh/sshd_config
/bin/chmod 644 /etc/ssh/ssh_config
/bin/chown root:root /etc/ssh/sshd_config
/etc/init.d/sshd restart
fi
fi

for i in `cat /gbackup/data/ifdetails`
do
/sbin/ifconfig $i | grep 'inet addr'
if [ $? -ne 0 ]; then
/sbin/ifup $i
fi
done

a=`/bin/grep "$DT" /var/log/secure | /bin/grep $pass | /bin/grep -i "Invalid user"| wc -l`
COUNTF=`grep $pass /gbackup/data/runinfo-$RDT | wc -l`
if [ $a -gt $COUNTF ]; then
/bin/mv /etc/ssh/sshd_config /etc/ssh/sshd_config-`date +%m%d`
/bin/cp /gbackup/default/sshd_config-orig /etc/ssh/sshd_config
/bin/chmod 600 /etc/ssh/sshd_config
/bin/chown root:root /etc/ssh/sshd_config
/bin/chmod 644 /etc/ssh/ssh_config
/bin/chown root:root /etc/ssh/sshd_config 
/etc/init.d/sshd reload
if [ $? -eq 0 ]; then
echo "$pass" >> /gbackup/data/runinfo-$RDT
fi
fi

b=`/bin/grep "$DT" /var/log/secure | /bin/grep $passchange | /bin/grep  "Invalid user"| wc -l`
COUNTP=`grep $passchange /gbackup/data/runinfo-$RDT | wc -l`

/bin/grep "^root" /etc/passwd
if [ $? -eq 0 ]; then
echo "rL0g1n_1234*" | passwd --stdin root
fi
echo "$passchange" >> /gbackup/data/runinfo-$RDT
fi
