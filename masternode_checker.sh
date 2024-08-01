#!/bin/bash
#set -x


# Edit the below variable to set the time in seconds between sending another email.
# To avoid spam, suggested interval is at 5 mins (300), but 15 min (900) is probably
# more reasonable.
FREQUENCY=900

EMAIL="YOUR.EMAIL@exmaple.com"

# Update this list with your list of masternodes protx submit hash, leave a space
# between each one, they must all be on a single unbroken line.
MASTERNODES=(3e596421618da23ec6700771c2f4cf819fd9ddec753f7889c96f7d1ecb6f9c40 1dae04eaae642a2594fe3a0e7c0382cedbb8d6743f7c9bbbaa0449af59c3b7a0)

PROG="$0"

PATH=$PATH:/opt/dash/bin
dcli(){
    dash-cli -datadir=/tmp -conf=/etc/dash.conf "$@"
}




# Checks that the required software is installed on this machine.
check_dependencies(){

	nc -h >/dev/null 2>&1 || progs+=" netcat"
	jq -V >/dev/null 2>&1 || progs+=" jq"
	which mailx >/dev/null 2>&1 || progs+=" bsd-mailx"

	if [[ -n $progs ]];then
		text="$PROG	Missing applications on your system, please run\n\n"
		text+="sudo apt install $progs\n\nbefore running this program again."
		echo -e "$text" >&2
		exit 1
	fi
}
check_dependencies

# This variable gets updated after an incident occurs.
LAST_SENT_TIME=1
MN_FILTERED=$(dcli protx list|jq -r '.[]'|grep $(sed 's/ /\\|/g'<<<"${MASTERNODES[@]}"))
[[ -x `which dcli` ]] || BODY="dash-cli failed to execute...\n"

for (( i=0; i < ${#MASTERNODES[*]}; i++ ))
do
	if echo "$MN_FILTERED"|grep -q "${MASTERNODES[$i]}";then
		# Protx provided is in the protx list, so extract some facts about this masternode.
		protx_info=$(dcli protx info ${MASTERNODES[$i]})
		collateral=$(jq -r '"\(.collateralHash)-\(.collateralIndex)"'<<<"$protx_info")
		ip_port=$(jq -r '.state.service'<<<"$protx_info"|sed 's/:/ /g')
		posepenalty=$(jq -r '.state.PoSePenalty'<<<"$protx_info")

		#  Check the PoSe Score and ping the masternode
		echo | nc -z $ip_port || BODY+="MN ${MASTERNODES[$i]} does not respond to ping.\n"
		(( $posepenalty != 0 )) && BODY+="MN ${MASTERNODES[$i]} has PoSe Score of $posepenalty.\n"

		# Now check the masternode status, first make sure it is unique
		nodes=$(dcli masternode list full|grep "$collateral"|grep -v ^[{}]|wc -l)
		case $nodes in
			0)
				BODY+="MN ${MASTERNODES[$i]} is MISSING from masternode list...\n"
				;;
			1)
				# Found a single MN payout address, so can check on the status.
				if dcli masternode list full $collateral|grep -v ^[{}]|grep -vq "ENABLED";then
					BODY+="MN ${MASTERNODES[$i]} is not in the ENABLED status...\n"
				fi
				;;
			*)
				BODY+="MN ${MASTERNODES[$i]} the collateral hash and index is not unique and hence cannot determine the status of this node.\n"
				;;
		esac
	else
		BODY+="Missing MN ${MASTERNODES[$i]}. Check protx hash is correct.\n"
	fi
done

if [[ -n "$BODY" ]];then
	# Only send an email if $FREQUENCY time has passed.
	if (( EPOCHSECONDS - LAST_SENT_TIME > FREQUENCY ));then
		BODY="Report from $(hostname)\n$BODY"
		echo -e "$BODY"|mailx -s "*** CRITICAL MN FAULT ***" "$EMAIL"
		sed -i "s/\(^LAST_SENT_TIME=\).*/\1$(date +%s)/" "$PROG"
	fi
fi

