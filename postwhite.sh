#! /bin/bash
#
# Postwhite Automatic Postcreen Whitelist Generator
#
# Version 1.3
# By Steve Jenkins (http://stevejenkins.com/)
#
# Usage: ./postwhite.sh
#
# Requires spf-tools (https://github.com/jsarenik/spf-tools)
# Thanks to Mike Miller (mmiller@mgm51.com) for gwhitelist.sh script

# USER-DEFINABLE OPTIONS

# spf-tools location (REQUIRED)
spftoolspath=/usr/local/bin/spf-tools
# ipcalc location (REQUIRED)
ipcalc=/usr/local/bin/ipcalc

# Postfix location and whitelist filename
postfixpath=/etc/postfix
postfixbinarypath=/usr/sbin
whitelist=postscreen_spf_whitelist.cidr

# Toggle senders you want to include
google=yes
microsoft=yes
facebook=yes
twitter=yes

# Reload Postfix Automatically when done?
reloadpostfix=yes 

# NO NEED TO EDIT PAST THIS LINE

# Create temporary files
tmpBase=`basename $0`
tmp1=`mktemp -q /tmp/${tmpBase}.XXXXXX`
tmp2=`mktemp -q /tmp/${tmpBase}.XXXXXX`
	if [ $? -ne 0 ]; then
		echo "$0: Can't create temp file, exiting..."
		exit 1
	fi

# abort on any error
set -e

function normalize_cidr() {
	# split by ":"
	local array=(${ip/:/ });
	if [ "x${array[0]}" = "xip4" ] ; then
		# check if is a CIDR
		if [[ ${array[1]} == *"/"* ]]
		then
			IP=$($ipcalc -b ${array[1]} | awk '/^Network/ {print $2}');
		else
			IP=${array[1]}
		fi
	else
		IP=${array[1]}
	fi
	echo $IP
}


if [ "$google" == "yes" ]; then

	${spftoolspath}/despf.sh google.com >> ${tmp1}

fi

if [ "$microsoft" == "yes" ]; then

	${spftoolspath}/despf.sh outlook.com >> ${tmp1}

	${spftoolspath}/despf.sh hotmail.com >> ${tmp1}

fi

if [ "$facebook" == "yes" ]; then

	${spftoolspath}/despf.sh facebookmail.com >> ${tmp1}

fi

if [ "$twitter" == "yes" ]; then

	${spftoolspath}/despf.sh twitter.com >> ${tmp1}

fi

# Format the whitelist
for ip in `cat  ${tmp1}` ; do
	ip=$(normalize_cidr  $ip);
	echo -ne "$ip\tpermit\n"
done >> ${tmp2}

# Sort and unique the final list and write to Postfix directory
sort -n -u ${tmp2} > ${postfixpath}/${whitelist}

# Remove temp files
test -e ${tmp1} && rm ${tmp1}
test -e ${tmp2} && rm ${tmp2}

# Reload Postfix to pick up any changes
if [ "$reloadpostfix" == "yes" ]; then
	${postfixbinarypath}/postfix reload
fi
