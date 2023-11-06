#!/usr/bin/env bash

DIFF_LIMIT=100 #might need to be adjusted
OUTPUT_DIR="" #if empty output dir is current dir
CAPTURE_INTERVAL="1" # in seconds

#ntfy topic, make sure to make it random/difficult as it is basicly a password.
#at the moment it will spam ntfy every second if there is motion. needs to be fixed.
NTFY=false
NTFY_TOPIC=""

MOTION_MSG="Motion detected at \$(date +"%H:%M:%S") \(Diff = \$DIFF\)"
SKIP_MSG="Same as previous image: delete \(Diff = \$DIFF\)"
NTFY_MSG=$MOTION_MSG

FFMPEG=ffmpeg

#bool stuff
DISPLAY_SKIPPED=true

##END EDIT
DEPENDENCIES=(
	"ffmpeg"
	"curl"
	"convert"
)

echo -n "Checking dependencies... "
for name in ${DEPENDENCIES[@]}; do
  type $name >/dev/null 2>&1 || { echo -en >&2 "\nI require $name but it's not installed."; deps=1; }
done
[[ $deps -ne 1 ]] && echo "OK" || { echo -en "\nInstall the above and rerun this script. Aborting\n"; exit 1; }

#if ntfy_topic not set make a random one, and save it for the future
if [[ $NTFY == true && -n $NTFY_TOPIC && -s NTFY_TOPIC ]]; then
	NTFY_TOPIC=$(<NTFY_TOPIC)
elif [[ $NTFY == true && -z $NTFY_TOPIC ]]; then 
	NTFY_TOPIC=$(echo $RANDOM | md5sum | head -c 20)
	echo $NTFY_TOPIC > NTFY_TOPIC
fi


if [[ -z $OUTPUT_DIR ]]; then
	SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
	OUTPUT_DIR="$SCRIPT_DIR/images"
fi

command -v $FFMPEG >/dev/null 2>&1 || { FFMPEG=avconv ; }
DIFF_RESULT_FILE=$OUTPUT_DIR/diff_results.txt

fn_cleanup() {
	rm -f diff.png $DIFF_RESULT_FILE
}

fn_terminate_script() {
	fn_cleanup
	echo "SIGINT caught."
	exit 0
}
trap 'fn_terminate_script' SIGINT

mkdir -p $OUTPUT_DIR
PREVIOUS_FILENAME=""
while true ; do
	FILENAME="$OUTPUT_DIR/$(date +"%Y%m%dT%H%M%S").jpg"
	echo "-----------------------------------------"
	echo "Capturing $FILENAME"
	if [[ "$OSTYPE" == "linux-gnu" ]]; then
		$FFMPEG -loglevel fatal -f video4linux2 -i /dev/video0 -r 1 -t 0.0001 $FILENAME
	elif [[ "$OSTYPE" == "darwin"* ]]; then
		# Mac OSX
		$FFMPEG -loglevel fatal -f avfoundation -i "default" -r 1 -t 0.0001 $FILENAME
	fi
	
	if [[ "$PREVIOUS_FILENAME" != "" ]]; then
		# For some reason, `compare` outputs the result to stderr so
		# it's not possibly to directly get the result. It needs to be
		# redirected to a temp file first.
		compare -fuzz 20% -metric ae $PREVIOUS_FILENAME $FILENAME diff.png 2> $DIFF_RESULT_FILE
		DIFF="$(cat $DIFF_RESULT_FILE)"
		fn_cleanup
		if [ "$DIFF" -lt 20 ]; then
			if [ $DISPLAY_SKIPPED == true ]; then
                   eval "echo $SKIP_MSG"
            fi
			rm -f $FILENAME
		else
			eval "echo $MOTION_MSG"

			if [[ $NTFY == true && -n $NTFY_TOPIC ]]; then
				echo "ntfy"
				curl -d "$(eval "echo $NTFY_MSG")" ntfy.sh/$NTFY_TOPIC
			fi

			PREVIOUS_FILENAME="$FILENAME"
		fi
	else
		PREVIOUS_FILENAME="$FILENAME"
	fi
	
	sleep $CAPTURE_INTERVAL
done
