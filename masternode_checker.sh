#!/bin/bash
#set -x


# Edit the below variable to set the time in seconds between sending another email.
# To avoid spam, suggested interval is at 5 mins (300), but 15 min (900) is probably
# more reasonable.
FREQUENCY=900

EMAIL="YOUR.EMAIL@exmaple.com"

# Update this list with your list of masternodes, leave a space between each one, they must
# all be on a single unbroken line.
MASTERNODES=(XiVTs3xjtX2MuDHz5uifcxT8RFTjomsH6r XgLpmZ5yavN4rRmubeSNZmAXLbT8AXeT4G Xp1qX8LFL8cpyYGXcH8UHBV15ztQ18vjcT)


PROG="$0"

# This variable gets updated after an incident occurs.
LAST_SENT_TIME=0
MN_FILTERED=$(dash-cli masternode list full|grep $(echo "${MASTERNODES[@]}"|sed 's/ /\\|/g'))
test -x `which dash-cli` || body="dash-cli failed to execute..."

for ((i=0; i < ${#MASTERNODES[*]}; i++ ))
do
	if echo "$MN_FILTERED"|grep -q "${MASTERNODES[$i]}";then
		if echo "$MN_FILTERED"|grep "${MASTERNODES[$i]}"|grep -vq "ENABLED 70210";then
			BODY=$(echo "$BODY";echo "Found MN ${MASTERNODES[$i]}, but it is not in the ENABLED status...")
		else
			# The mastenode has been found in the mn list and is ENABLED 70210.
			# One final check, verify it responds to a TCP 3-way H/S.
			ip_port=$(echo "$MN_FILTERED"|grep "${MASTERNODES[$i]}"|sed 's/[",]//g;s/:/ /g'|awk '{print $9" "$10}')
			echo | nc -w10 $ip_port || BODY=$(echo "$BODY";echo "MN ${MASTERNODES[$i]} does not respond to ping.")
		fi
	else
		BODY=$(echo "$BODY";echo "Missing MN ${MASTERNODES[$i]}.")
	fi
done

if [ ! -z "$BODY" ];then
	# Only send an email if $FREQUENCY time has passed.
	if (( $(date +%s) - $LAST_SENT_TIME > $FREQUENCY ));then
		BODY=$(echo "Report from $(hostname)";echo "$BODY")
		echo "$BODY"|mailx -s "*** CRITICAL MN FAULT ***" "$EMAIL"
		sed -i "s/\(^LAST_SENT_TIME=\).*/\1$(date +%s)/" "$PROG"
	fi
fi

