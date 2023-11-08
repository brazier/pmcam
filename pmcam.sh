#!/usr/bin/env bash

##
## Settings
##

DIFF_LIMIT=100 #might need to be adjusted depending on quality of your camera. eg. low light produces a lot of noise.
OUTPUT_DIR="" #if empty, output dir is current dir

CAPTURE_MODE="1" # 1: images only, every x seconds. 2: start video capture on motion

# The following is only needed if CAPTURE_MODE is set to 2.
VIDEO_FRAMERATE="15.0"
VIDEO_SIZE="640x480"
REC_WAIT="10" # seconds to wait before stopping recording.

CAPTURE_INTERVAL="1" # in seconds

# ntfy topic, make sure to make it random/difficult as it is basicly a password.
# see ntfy.sh for more information
NTFY=true
NTFY_TOPIC=""
NTFY_TIMEOUT="900" #minimum seconds between each notification. 900s = 15m

MOTION_MSG="Motion detected"
SKIP_MSG="Same as previous image: delete"
NTFY_MSG="Motion detected"

DISPLAY_SKIPPED=true
DISPLAY_CAPTURE=true
DISPLAY_MOTION=true


##END EDIT

DEVICE_IN="/dev/video0"
DEVICE_OUT="/dev/video1"

FFMPEG=ffmpeg
FFMPEG_LOGLEVEL="fatal"

##
## Check for dependencies
##
DEPENDENCIES=(
	"ffmpeg"
	"curl"
	"convert" #imagemagic
)

echo -n "Checking dependencies... "
for name in ${DEPENDENCIES[@]}; do
  type $name >/dev/null 2>&1 || { echo -en >&2 "\nI require $name but it's not installed."; deps=1; }
done
[[ $deps -ne 1 ]] && echo "OK" || { echo -en "\nInstall the above and rerun this script. Aborting\n"; exit 1; }


# if ntfy_topic not set make a random one, and save it for the future
if [[ $NTFY == true && -n $NTFY_TOPIC && -s NTFY_TOPIC ]]; then
	NTFY_TOPIC=$(<NTFY_TOPIC)
elif [[ $NTFY == true && -z $NTFY_TOPIC ]]; then 
	NTFY_TOPIC=$(echo $RANDOM | md5sum | head -c 20)
	echo $NTFY_TOPIC > NTFY_TOPIC
fi

# set output dir to current if not defined in settings
if [[ -z $OUTPUT_DIR ]]; then
	SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
	OUTPUT_DIR="$SCRIPT_DIR/output"
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

fn_message() {
	echo -n "[$(date "+%d/%m/%y %T")] "
	echo -n $1

	if [[ -n $2 ]]; then
		echo -n " (Diff = $2)"
	fi
	echo -en "\n"
}
fn_loopback() {
	$FFMPEG -loglevel "$FFMPEG_LOGLEVEL" -f v4l2 -i "$DEVICE_IN" -f v4l2 "$DEVICE_OUT" &
	sleep 1
}
fn_record() {
	if [[ "$1" == "start" ]]; then
		declare -gA REC=(
			[START]="$(date +%s)"
			[FILENAME]="$OUTPUT_DIR/$(date +"%Y%m%dT%H%M%S").mkv"
		)
		$FFMPEG -loglevel "$FFMPEG_LOGLEVEL" -f v4l2 -i "$DEVICE_OUT" -framerate "$VIDEO_FRAMERATE" -video_size "$VIDEO_SIZE" "${REC[FILENAME]}" &
		REC[PID]=$!
		fn_message "Recording Started: ${REC[FILENAME]}"
	elif [[ "$1" == "stop" ]]; then
		kill ${REC[PID]} >/dev/null 2>&1
		fn_message "Recording Stoppped: ${REC[FILENAME]}"
		unset REC
	else
		echo "Missing arg"
		fn_terminate_script
	fi
}

fn_ntfy() {
	if [[ $NTFY == true && -n $NTFY_TOPIC && $NTFIED = 0 && $NTFY_LAST_RUN -lt $(($(date +%s)-$NTFY_TIMEOUT)) ]]; then
		curl -d "$(fn_message "$NTFY_MSG" "$DIFF")" ntfy.sh/$NTFY_TOPIC > /dev/null 2>&1
		fn_message "Sent NTFY ntfy.sh/$NTFY_TOPIC"

		NTFY_LAST_RUN=$(date +%s)
		NTFIED=1
	fi
}

trap 'fn_terminate_script' SIGINT

mkdir -p $OUTPUT_DIR
PREVIOUS_FILENAME=""
NTFY_LAST_RUN=$(date +%s)-$NTFY_TIMEOUT

if [[ $NTFY == true ]]; then
	echo "Visit ntfy.sh/$NTFY_TOPIC for notifications"
fi
fn_loopback
##
## Main loop
##
while true ; do
	FILENAME="$OUTPUT_DIR/$(date +"%Y%m%dT%H%M%S").jpg"

	if [[ $DISPLAY_CAPTURE == true ]]; then
		fn_message "Capturing $FILENAME"
	fi

	if [[ "$OSTYPE" == "linux-gnu" ]]; then
		$FFMPEG -loglevel "$FFMPEG_LOGLEVEL" -f v4l2 -i "$DEVICE_OUT" -r 1 -t 0.0001 $FILENAME
	elif [[ "$OSTYPE" == "darwin"* ]]; then
		# Mac OSX
		$FFMPEG -loglevel "$FFMPEG_LOGLEVEL" -f avfoundation -i "default" -r 1 -t 0.0001 $FILENAME
	fi
	
	if [[ "$PREVIOUS_FILENAME" != "" ]]; then
		# For some reason, `compare` outputs the result to stderr so
		# it's not possibly to directly get the result. It needs to be
		# redirected to a temp file first.
		compare -fuzz 20% -metric ae $PREVIOUS_FILENAME $FILENAME diff.png 2> $DIFF_RESULT_FILE
		DIFF="$(cat $DIFF_RESULT_FILE)"
		fn_cleanup
		if [ "$DIFF" -lt "$DIFF_LIMIT" ]; then
			if [ $DISPLAY_SKIPPED == true ]; then
                   fn_message "$SKIP_MSG" "$DIFF"
            fi
			rm -f $FILENAME

			if [[ "$CAPTURE_MODE" == "2" && ${REC[*]} && $REC_LAST_MOTION -lt $(($(date +%s)-$REC_WAIT)) ]]; then
				fn_record "stop"
			fi

			NTFIED=0
		else
			if [ $DISPLAY_MOTION == true ]; then
				fn_message "$MOTION_MSG" "$DIFF"
			fi
			fn_ntfy

			if [[ "$CAPTURE_MODE" == "1" ]]; then
				PREVIOUS_FILENAME="$FILENAME"
			elif [[ "$CAPTURE_MODE" == "2" ]]; then
				rm -f $PREVIOUS_FILENAME
				PREVIOUS_FILENAME="$FILENAME"
				REC_LAST_MOTION=$(date +%s)


				if [ ${#REC[@]} -eq 0 ]; then
					fn_record "start" #start recording
				fi

			fi
			
		fi
	else
		PREVIOUS_FILENAME="$FILENAME"
	fi
	
	sleep $CAPTURE_INTERVAL
done
