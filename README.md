# pmcam - poor man's video capture with motion detection in Bash

This simple Bash script captures images from a webcam with motion detection support. I wanted to change some settings from the original, [laurent22/pmcam](https://github.com/jaclu/pmcam), and also add some new features such as video capture and the ability send notifications with [NTFY](https://ntfy.sh). Also borrowed some things from [jaclu/pmcam](https://github.com/jaclu/pmcam)

Frames are captured at regular intervals using `ffmpeg`. Then ImageMagick's `compare` tool is used to check if this frame is similar to the previous one.

There are now two modes, 
Image mode: If the frames are different enough, they are kept, otherwise they are deleted. This provide very simple motion detection and avoids filling up the hard drive with duplicate frames.

Video mode: If the frames are different enough, video capture will be started. It will then stop a defined amount of seconds later if no further motion is detected.

Curl is then used to send a notification to [ntfy.sh](https://ntfy.sh)

## Installation

### OS X

Not tested, unsupported as of now since v4l2loopback is needed to capture motion and record from the same device

### Linux (Debian)

	sudo apt-get install ffmpeg imagemagick curl v4l2loopback-dkms
	curl -O https://raw.github.com/brazier/pmcam/master/pmcam.sh

### Windows

Not tested, unsupported. See OS X


## Configuration

The primary config options are:

    DIFF_LIMIT          Cut-off for what changes should be saved
    OUTPUT_DIR          Where to save matching imgs
    CAPTURE_MODE	Images only [1] or video capture [2]
    VIDEO_FRAMERATE     Framerate of recording
    VIDEO_SIZE          Resolution of recording
    REC_WAIT            How many seconds to wait before stopping recording. Prevents many short recordings. (approximately)
    CAPTURE_INTERVALS	How often to capture/check for motion. (approximately)
    NTFY                Activate NTFY [true/false]
    NTFY_TOPIC          Topic to use with ntfy
    NTFY_TIMEOUT        Minimum seconds between each notification
    DISPLAY_SKIPPED	Output messages when there is no motion [true/false]
    DISPLAY_CAPTURE     Output messages when a picture is taken [true/false]
    DISPLAY_MOTION      Output messages when there is motion [true/false]

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

MIT License

Copyright (c) 2023 brazier 
Copyright (c) 2020-2021 jaclu 
Copyright (c) 2014-2019 laurent22 

See [LICENCE](LICENCE.md) for full licence.
