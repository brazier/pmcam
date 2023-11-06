# pmcam - poor man's video capture with motion detection in Bash

This simple Bash script captures images from a webcam with motion detection support. I wanted to find out what my dog was up to when I am not at home, but could not find any free video capture software on OS X. I put together this quick and dirty solution, which does the job surprisingly well.

Frames are captured at regular intervals using `ffmpeg`. Then ImageMagick's `compare` tool is used to check if this frame is similar to the previous one. If the frames are different enough, they are kept, otherwise they are deleted. This provide very simple motion detection and avoids filling up the hard drive with duplicate frames.

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

## Usage

	./pmcam.sh

The script will use the default webcam to capture frames. To capture using a different camera, the ffmpeg command `-i` parameter can be changed - see the [ffmpeg documentation](https://trac.ffmpeg.org/wiki/Capture/Webcam) for more information.

A frame will then be saved approximately every 1 second to the "images" folder next to the Bash script. Both delay and target folder can be changed in the script.

To stop the script, press Ctrl + C.

## TODO

* Allow specifying the video capture source and format (curently hardcoded)
* Command line argument to change frame directory.
* Command line argument to change interval between frame captures.
* Command line argument to specify the threshold for a frame to be kept.

## License

MIT
