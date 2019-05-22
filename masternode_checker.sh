#!/bin/bash
#set -x

# Dependencies: Install netcat and jq
# sudo apt install netcat jq

# Edit the below variable to set the time in seconds between sending another email.
# To avoid spam, suggested interval is at 5 mins (300), but 15 min (900) is probably
# more reasonable.
FREQUENCY=900

EMAIL="YOUR.EMAIL@exmaple.com"

# Update this list with your list of masternodes protx submit hash, leave a space
# between each one, they must all be on a single unbroken line.
MASTERNODES=(d36f26a754b07c6d7c7f6abbe0ea740c9770bd7dfff9f25ef4e71764b999aef1 0e98fdf7488a6929b2b45640973453d74698d943eb1cf1b5664fe05111b73c00)


PROG="$0"

# This variable gets updated after an incident occurs.
LAST_SENT_TIME=1551864535
MN_FILTERED=$(dash-cli protx list|grep -v ^[][]|sed 's/.*"\(.*\)".*/\1/g'|grep $(echo "${MASTERNODES[@]}"|sed 's/ /\\|/g'))
test -x `which dash-cli` || body="dash-cli failed to execute..."

for (( i=0; i < ${#MASTERNODES[*]}; i++ ))
do
	if echo "$MN_FILTERED"|grep -q "${MASTERNODES[$i]}";then
		# Protx provided is in the protx list, so extract some facts about this masternode.
		protx_info="$(dash-cli protx info ${MASTERNODES[$i]})"
		collateral=$(echo "$protx_info"| jq -r '"\(.collateralHash)-\(.collateralIndex)"')
		ip_port=$(echo "$protx_info"| jq -r '.state.service'|sed 's/:/ /g')
		posepenalty=$(echo "$protx_info"| jq -r '.state.PoSePenalty')

		#  Check the PoSe Score and ping the masternode
		echo | nc -w10 $ip_port || BODY=$(echo "$BODY";echo "MN ${MASTERNODES[$i]} does not respond to ping.")
		if [ $posepenalty -ne 0 ];then
			BODY=$(echo "$BODY";echo "MN ${MASTERNODES[$i]} has PoSe Score of $posepenalty.")
		fi

		# Now check the masternode status, first make sure it is unique
		nodes=$(dash-cli masternode list full|grep "$collateral"|grep -v ^[{}]|wc -l)
		case $nodes in
			0)
				BODY=$(echo "$BODY";echo "MN ${MASTERNODES[$i]} is MISSING from masternode list...")
				;;
			1)
				# Found a single MN payout address, so can check on the status.
				if dash-cli masternode list full $collateral|grep -v ^[{}]|grep -vq "ENABLED";then
					BODY=$(echo "$BODY";echo "MN ${MASTERNODES[$i]} is not in the ENABLED status...")
				fi
				;;
			*)
				BODY=$(echo "$BODY";echo "MN ${MASTERNODES[$i]} the collateral hash and index is not unique and hence cannot determine the status of this node.")
				;;
		esac
	else
		BODY=$(echo "$BODY";echo "Missing MN ${MASTERNODES[$i]}. Check protx hash is correct.")
	fi
done

if [ ! -z "$BODY" ];then
	# Only send an email if $FREQUENCY time has passed.
	if (( $(date +%s) - $LAST_SENT_TIME > $FREQUENCY ));then
		BODY=$(echo "Report from $(hostname)";echo "$BODY")
		echo "$BODY"|mailx -s "*** CRITICAL MN FAULT ***" "$EMAIL"
		#echo "$BODY"
		sed -i "s/\(^LAST_SENT_TIME=\).*/\1$(date +%s)/" "$PROG"
	fi
fi

