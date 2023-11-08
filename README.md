# pmcam - poor man's video capture with motion detection in Bash

This simple Bash script captures images from a webcam with motion detection support. I wanted to change some settings from the original, [laurent22/pmcam](https://github.com/jaclu/pmcam), and also add some new features such as the ability send notifications with [NTFY](https://ntfy.sh). Also borrowed some things from [jaclu/pmcam](https://github.com/jaclu/pmcam)

Frames are captured at regular intervals using `ffmpeg`. Then ImageMagick's `compare` tool is used to check if this frame is similar to the previous one If the frames are different enough, they are kept, otherwise they are deleted. A notification will be sent, if motion is detected. This provide very simple motion detection and avoids filling up the hard drive with duplicate frames.

## Installation

### OS X

Not tested

### Linux (Debian)

	sudo apt-get install ffmpeg imagemagick curl
	curl -O https://raw.github.com/brazier/pmcam/master/pmcam.sh

### Windows

(Not tested)

* Install [Cygwin](https://www.cygwin.com/) or [MinGW](http://www.mingw.org/)
* Install [ffmpeg](http://ffmpeg.zeranoe.com/builds/)
* Install [ImageMagick](http://www.imagemagick.org/script/binary-releases.php)


## Configuration

The primary config options are:

    DIFF_LIMIT          cut-off for what changes should be saved
    OUTPUT_DIR          where to save matching imgs
    CAPTURE_INTERVALS	how often to capture/check for motion.
    NTFY_TOPIC          Topic to use with ntfy, if NTFY set to true and NTFY_TOPIC is not set, a random 20 char wil be made.
    
    Booleans, true/false
    NTFY                send notifications to ntfy
    DISPLAY_SKIPPED     display info about ignored images

Set them as you see fit.

## Usage

	./pmcam.sh

The script will use the default webcam to capture frames. To capture using a different camera, the ffmpeg command `-i` parameter can be changed - see the [ffmpeg documentation](https://trac.ffmpeg.org/wiki/Capture/Webcam) for more information.

A frame will then be saved approximately every 1 second to the "images" folder next to the Bash script. Both delay and target folder can be changed in the script.

To stop the script, press Ctrl + C.

## TODO

* Allow specifying the video capture source and format (curently hardcoded)
* Add option to start video capture on motion instead of just images

## License

MIT
