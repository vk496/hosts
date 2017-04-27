#!/bin/bash
set -e #exit if some part fails

TMP=$(mktemp)

errorExit(){
	rm $TMP
	exit 1
}

getDate(){

	if [ "$com_date" == "now" ]; then
		date=$(date +%d-%m-%Y)
	else
		date=$(eval "echo \"\$FILE\" | head -30 |$com_date")
		if [ $? -ne 0 ]; then
			>&2 echo "ERROR Get last file update"
			errorExit
		elif [ -z "$date" ]; then
			>&2 echo "ERROR Last file update blank"
			errorExit
		fi
	fi

}


getFile(){

	FILE="$(curl -skL "$url")"

	if [ $? -ne 0 ]; then
		>&2 echo "ERROR Download file"
		errorExit
	fi


}

echo -e "# @vk496 Project. GPLv3">hosts
echo -e "# Updated: $(date +%d-%m-%Y)\n#####">>hosts


cat webs | grep -Ev "(^[#]|^$)" | \
while read line; do

	url=$(echo "$line" | cut -d$'\t' -f1)
	preparse=$(echo "$line" | cut -d$'\t' -f2)
	com_date=$(echo "$line" | cut -d$'\t' -f3)
	author=$(echo "$line" | cut -d$'\t' -f4)
	license=$(echo "$line" | cut -d$'\t' -f5)
	extra=$(echo "$line" | cut -d$'\t' -f6)

	date=
	FILE=
	
	echo "Downloading $url"
	getFile #Try download file	
	getDate #Try get las update

	eval "echo \"\$FILE\"" $preparse >>$TMP #save

	echo -e "### URL: $url" >>hosts
	echo -e "# Date: $date" >>hosts
	echo -e "# Cred: $author" >>hosts
	echo -e "# Lic.: $license" >>hosts
	echo -e "# INFO: $extra" >>hosts
	echo -e "###" >>hosts
done

echo "Generate hosts file"

echo -e "\n127.0.0.1\tlocalhost" >> hosts
echo -e "::1\tlocalhost\n" >>hosts

cat $TMP 				| \
grep -Ev "(^[#]|^$|^[\t])" 		| # quit comments and blank lines
sed 's/0\.0\.0\.0/127\.0\.0\.1/g' 	| # replace all IPs to 127.0.0.1
awk '{print $1 "\t" $2}' 		| # Get ONLY the IP and DOMAINs, avoiding inline comments
grep "127\.0\.0\.1" 			| # Again, get only IPs. Avoid some natural text of HTML websites
sed 's/\r$//'				| # Delete \r char
sort -u 				| # Sort and delete duplicates
grep -vP "\tlocalhost$" >>hosts		  # Delete all localhost entrys

sed -i "/@vk496/a # Unique hosts: $(grep -Ev '(^[#]|^$)' hosts | wc -l)" hosts

echo "OK"

exit 0
