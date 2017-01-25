#!/bin/bash
if [ "$#" -ne 3 ]; then
	echo "Requires 3 arguments:"
	echo "1) Movie file"
	echo "2) Start time"
	echo "3) End time"
	exit
fi

fn=$1

echo "Converting $fn"
exec ffmpeg -i "$fn" -vcodec libx264 -acodec aac -strict experimental -y "${fn/.mov/}.mp4" &
wait
echo "Cutting movie..."
exec ffmpeg -i "${fn/.mov/}.mp4" -acodec aac -strict experimental -ss $2 -to $3 -async 1 -y "${fn/.mov/}-ffmpeg.mp4" &
wait
echo "Done"
