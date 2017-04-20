#!/bin/bash

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
	com_date=$(echo "$line" | cut -d$'\t' -f2)
	author=$(echo "$line" | cut -d$'\t' -f3)
	license=$(echo "$line" | cut -d$'\t' -f4)
	extra=$(echo "$line" | cut -d$'\t' -f5)

	date=
	FILE=
	
	echo "Downloading $url"
	getFile #Try download file	
	getDate #Try get las update

	echo "$FILE" >>$TMP #save

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

cat $TMP |grep -Ev "(^[#]|^$|^[\t])" | sed 's/0\.0\.0\.0/127\.0\.0\.1/g' | awk '{print $1 "\t" $2}' | grep "127\.0\.0\.1" | sed 's/\r$//'| sort | uniq | grep -vP "\tlocalhost$" >>hosts

echo "OK"

exit 0
