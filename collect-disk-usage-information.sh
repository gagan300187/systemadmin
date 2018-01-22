#DATE=date format in mmdd
#MP=mount point
#MPTD=mount point total disk
#MPDU=mount point disk usage
#DATFILE=data file
#PDATFILE=previous data file
#CONF=configuration file
#MPFD= mount point free disk
#FT=first time running
#REPORTFILE= report file, in which all the data is accumulated, rotated according to week
#DATEW= date according to weeknumber

MAINDIR=/tmp/capmgmt
OS=`uname`
FT=0
DATEW=`date +%U`
DATEW=`expr $DATEW + 1`
DATFILE=$MAINDIR/`uname -n`-diskusage
TMPFILE=$MAINDIR/`uname -n`-diskusage.tmp
PDATFILE=$MAINDIR/pd-`uname -n`-diskusage
CONF=$MAINDIR/cm.conf
REPORTFILE=$MAINDIR/`uname -n`-report-$DATEW
DATE=`date +%m%d`


##########################Coding for Linux#############################################################3

if [ $OS = "Linux" ]; then


if [[ -e $DATFILE ]]; then
rm $DATFILE
fi

if [[ ! -e $CONF ]]; then
echo "configuration file missing, generating file...."
grep check_disk /etc/nagios/nrpe.cfg | grep  -v "^#" | grep  -v "/dev/hda1" |  tr " " "\n" | grep "^/" | sort | uniq | grep -v "check_disk.pl" > $CONF
fi

if [[ ! -e $PDATFILE ]]; then
echo "no previous data file found...... this script is being executed first time"
FT=1
fi


for mp in `cat $CONF`
do
t=`df -k $mp | grep -w $mp | awk '{print $(NF-4)}'`
MPTD=`echo "$t / 1024" | bc`
t=`df -k $mp | grep -w $mp | awk '{print $(NF-3)}'`
MPDU=`echo  "$t / 1024" | bc`
echo "$mp:$MPTD:$MPDU" >> $TMPFILE
echo "$mp is using $MPDU MB space"
done

if [ $FT -eq 0 ]; then
for mp in `cat $CONF`
do

d=`grep -w $mp $TMPFILE | wc -l`
if [ $d -gt 1 ]; then
cvalue=`grep -w $mp $TMPFILE | head -1 | cut -f 3 -d ":"`
MPTD=`grep -w $mp $TMPFILE | head -1 | cut -f 2 -d ":"`

else
cvalue=`grep -w $mp $TMPFILE | cut -f 3 -d ":"`
MPTD=`grep -w $mp $TMPFILE | cut -f 2 -d ":"`
fi

d=`grep -w $mp $PDATFILE | wc -l`
if [ $d -gt 1 ]; then
pvalue=`grep -w $mp $PDATFILE | head -1 | cut -f 3 -d ":"`

else
pvalue=`grep -w $mp $PDATFILE | cut -f 3 -d ":"`
fi


usage=`echo "$cvalue - $pvalue" | bc`
echo "$mp:$MPTD:$usage" >> $DATFILE
done

rm $PDATFILE
mv $TMPFILE $PDATFILE
fi

if [ $FT -eq 1 ]; then
rm $PDATFILE
mv $TMPFILE $PDATFILE
fi




#################Generating report Linux#################################################

if [ -e $DATFILE ]; then

if [[ ! -e $REPORTFILE ]]; then
touch $REPORTFILE
echo "Date" > $REPORTFILE
cat $CONF | tr -d " " >> $REPORTFILE
fi


mv $REPORTFILE $REPORTFILE-bak
grep "Date" $REPORTFILE-bak | sed "s/$/:$DATE/g" >  $REPORTFILE

for mp in `cat $CONF | tr -d " "`
do

d=`grep -w "$mp" $DATFILE | wc -l`
if [ $d -gt 1 ]; then
tt=`grep -w "$mp" $DATFILE | head -1 | awk 'BEGIN {FS=":"}  END {print $(NF)}'`
grep -w "$mp" $REPORTFILE-bak | head -1 | sed "s/$/:${tt}/g" >> $REPORTFILE
else
tt=`grep -w "$mp" $DATFILE | awk 'BEGIN {FS=":"}  END {print $(NF)}'`
grep -w "$mp" $REPORTFILE-bak | sed "s/$/:${tt}/g" >> $REPORTFILE
fi

done


fi
fi


################################Linux Code ends##################################################################







#########################AIX CODE Here########################################################################


if [ $OS = "AIX" ]; then

if [[ -e $DATFILE ]]; then
rm $DATFILE
fi

if [[ ! -e $CONF ]]; then
echo "configuration file missing, generating file...."
grep check_disk /etc/nagios/nrpe.cfg | grep  -v "^#" | grep  -v "/dev/hda1" |  tr " " "\n" | grep "^/" | sort | uniq | grep -v "check_disk.pl" > $CONF
fi

if [[ ! -e $PDATFILE ]]; then
echo "no previous data file found...... this script is being executed first time"
FT=1
fi

for mp in `cat $CONF`
do
t=`df -k $mp | grep -w $mp | awk '{print $2}'`
MPTD=`echo "$t / 1024" | bc`
t=`df -k $mp | grep -w $mp | awk '{print $3}'`
MPFD=`echo "$t / 1024" | bc`
MPDU=`echo "$MPTD - $MPFD" | bc`

echo "$mp:$MPTD:$MPDU" >> $TMPFILE
echo "$mp is using $MPDU MB space"
done

if [ $FT -eq 0 ]; then
for mp in `cat $CONF`
do

d=`grep -w $mp $TMPFILE | wc -l`
if [ $d -gt 1 ]; then
cvalue=`grep -w $mp $TMPFILE | head -1 | cut -f 3 -d ":"`
MPTD=`grep -w $mp $TMPFILE | head -1 | cut -f 2 -d ":"`

else
cvalue=`grep -w $mp $TMPFILE | cut -f 3 -d ":"`
MPTD=`grep -w $mp $TMPFILE | cut -f 2 -d ":"`
fi

d=`grep -w $mp $PDATFILE | wc -l`
if [ $d -gt 1 ]; then
pvalue=`grep -w $mp $PDATFILE | head -1 | cut -f 3 -d ":"`

else
pvalue=`grep -w $mp $PDATFILE | cut -f 3 -d ":"`
fi


usage=`echo "$cvalue - $pvalue" | bc`
echo "$mp:$MPTD:$usage" >> $DATFILE
done

rm $PDATFILE
mv $TMPFILE $PDATFILE
fi

if [ $FT -eq 1 ]; then
#rm $PDATFILE
mv $TMPFILE $PDATFILE
fi




#################Generating report AIX########################################################################

if [ -e $DATFILE ]; then

if [[ ! -e $REPORTFILE ]]; then
touch $REPORTFILE
echo "Date" > $REPORTFILE
cat $CONF | tr -d " " >> $REPORTFILE
fi


mv $REPORTFILE $REPORTFILE-bak
grep "Date" $REPORTFILE-bak | sed "s/$/:$DATE/g" >  $REPORTFILE

for mp in `cat $CONF | tr -d " "`
do

d=`grep -w "$mp" $DATFILE | wc -l`
if [ $d -gt 1 ]; then
tt=`grep -w "$mp" $DATFILE | head -1 | awk -F : '{print $(NF)}'`
grep -w "$mp" $REPORTFILE-bak | head -1 | sed "s/$/:${tt}/g" >> $REPORTFILE
else
tt=`grep -w "$mp" $DATFILE | awk -F : '{print $(NF)}'`
grep -w "$mp" $REPORTFILE-bak | sed "s/$/:${tt}/g" >> $REPORTFILE
fi

done



fi

fi



######################################AIX CODE ENDS######################################################################################








#######################################SUNOS code here ##################################################################################

if [ $OS = "SunOS" ]; then

if [[ -e $DATFILE ]]; then
rm $DATFILE
fi

if [[ ! -e $CONF ]]; then
echo "configuration file missing, generating file...."
grep check_disk /etc/nagios/nrpe.cfg | grep  -v "^#" | grep  -v "/dev/hda1" |  tr " " "\n" | grep "^/" | sort | uniq | grep -v "check_disk.pl" > $CONF
fi

if [[ ! -e $PDATFILE ]]; then
echo "no previous data file found...... this script is being executed first time"
FT=1
fi


for mp in `cat $CONF`
do
t=`df -k $mp | grep  $mp | awk '{print $2}'`
MPTD=`echo "$t / 1024" | bc`
t=`df -k $mp | grep  $mp | awk '{print $3}'`
MPDU=`echo  "$t / 1024" | bc`
echo "$mp:$MPTD:$MPDU" >> $TMPFILE
echo "$mp is using $MPDU MB space"
done

if [ $FT -eq 0 ]; then
for mp in `cat $CONF`
do

d=`grep -w $mp $TMPFILE | wc -l`
if [ $d -gt 1 ]; then
cvalue=`grep -w $mp $TMPFILE | head -1 | cut -f 3 -d ":"`
MPTD=`grep -w $mp $TMPFILE | head -1 | cut -f 2 -d ":"`

else
cvalue=`grep -w $mp $TMPFILE | cut -f 3 -d ":"`
MPTD=`grep -w $mp $TMPFILE | cut -f 2 -d ":"`
fi

d=`grep -w $mp $PDATFILE | wc -l`
if [ $d -gt 1 ]; then
pvalue=`grep -w $mp $PDATFILE | head -1 | cut -f 3 -d ":"`

else
pvalue=`grep -w $mp $PDATFILE | cut -f 3 -d ":"`
fi


usage=`echo "$cvalue - $pvalue" | bc`
echo "$mp:$MPTD:$usage" >> $DATFILE
done

rm $PDATFILE
mv $TMPFILE $PDATFILE
fi

if [ $FT -eq 1 ]; then
#rm $PDATFILE
mv $TMPFILE $PDATFILE
fi

###############Generating Reports SUNOS ###################################################3

if [ -e $DATFILE ]; then

if [[ ! -e $REPORTFILE ]]; then
touch $REPORTFILE
echo "Date" > $REPORTFILE
cat $CONF | tr -d " " >> $REPORTFILE
fi


mv $REPORTFILE $REPORTFILE-bak
grep "Date" $REPORTFILE-bak | sed "s/$/:$DATE/g" >  $REPORTFILE

for mp in `cat $CONF | tr -d " "`
do

d=`grep -w "$mp" $DATFILE | wc -l`
if [ $d -gt 1 ]; then
tt=`grep -w "$mp" $DATFILE | head -1 | awk 'BEGIN {FS=":"}  END {print NF}'`
grep -w "$mp" $REPORTFILE-bak | head -1 | sed "s/$/:${tt}/g" >> $REPORTFILE
else
tt=`grep -w "$mp" $DATFILE | awk 'BEGIN {FS=":"}  END {print NF}'`
grep -w "$mp" $REPORTFILE-bak | sed "s/$/:${tt}/g" >> $REPORTFILE
fi

done


fi





fi


######################################SunOS code ends here########################################################






################################Coding for HP-UX ##########################################################################


if [ $OS = "HP-UX" ]; then

if [[ -e $DATFILE ]]; then
rm $DATFILE
fi

if [[ ! -e $CONF ]]; then
echo "configuration file missing, generating file...."
grep check_disk /etc/nagios/nrpe.cfg | grep  -v "^#" | grep  -v "/dev/hda1" |  tr " " "\n" | grep "^/" | sort | uniq | grep -v "check_disk.pl" > $CONF
fi

if [[ ! -e $PDATFILE ]]; then
echo "no previous data file found...... this script is being executed first time"
FT=1
fi

for mp in `cat $CONF`
do
t=`df -k $mp | grep -w total | cut -f 2 -d ":" | awk '{print $1}'`
MPTD=`echo "$t / 1024" | bc`
t=`df -k $mp | grep "used allocated Kb" | awk '{print $1}'`
MPDU=`echo  "$t / 1024" | bc`
echo "$mp:$MPTD:$MPDU" >> $TMPFILE
echo "$mp is using $MPDU MB space"
done

if [ $FT -eq 0 ]; then
for mp in `cat $CONF`
do

d=`grep -w $mp $TMPFILE | wc -l`
if [ $d -gt 1 ]; then
cvalue=`grep -w $mp $TMPFILE | head -1 | cut -f 3 -d ":"`
MPTD=`grep -w $mp $TMPFILE | head -1 | cut -f 2 -d ":"`

else
cvalue=`grep -w $mp $TMPFILE | cut -f 3 -d ":"`
MPTD=`grep -w $mp $TMPFILE | cut -f 2 -d ":"`
fi

d=`grep -w $mp $PDATFILE | wc -l`
if [ $d -gt 1 ]; then
pvalue=`grep -w $mp $PDATFILE | head -1 | cut -f 3 -d ":"`

else
pvalue=`grep -w $mp $PDATFILE | cut -f 3 -d ":"`
fi


usage=`echo "$cvalue - $pvalue" | bc`
echo "$mp:$MPTD:$usage" >> $DATFILE
done

rm $PDATFILE
mv $TMPFILE $PDATFILE
fi

if [ $FT -eq 1 ]; then
#rm $PDATFILE
mv $TMPFILE $PDATFILE
fi



#################Generating report HP-UX#####################################3#######################

if [ -e $DATFILE ]; then

if [[ ! -e $REPORTFILE ]]; then
touch $REPORTFILE
echo "Date" > $REPORTFILE
cat $CONF | tr -d " " >> $REPORTFILE
fi


mv $REPORTFILE $REPORTFILE-bak
grep "Date" $REPORTFILE-bak | sed "s/$/:$DATE/g" >  $REPORTFILE

for mp in `cat $CONF | tr -d " "`
do

d=`grep -w "$mp" $DATFILE | wc -l`
if [ $d -gt 1 ]; then
tt=`grep -w "$mp" $DATFILE | head -1 | awk 'BEGIN {FS=":"}  END {print $(NF)}'`
grep -w "$mp" $REPORTFILE-bak | head -1 | sed "s/$/:${tt}/g" >> $REPORTFILE
else
tt=`grep -w "$mp" $DATFILE | awk 'BEGIN {FS=":"}  END {print $(NF)}'`
grep -w "$mp" $REPORTFILE-bak | sed "s/$/:${tt}/g" >> $REPORTFILE
fi

done

fi

fi

###########################################Script and HP-UX code ends###############################################
