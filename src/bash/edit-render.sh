#!/bin/bash
if [ "$#" -ne 5 ]; then
	echo "Requires 3 arguments:"
	echo "1) Movie file"
	echo "2) Start time"
	echo "3) End time"
	echo "4) Fade out time"
	echo "5) Fade out duration"
	exit
fi

fn=$1
start=$2
end=$3
fadeout=$4
fadeduration=$5

echo "Converting $fn"
exec ffmpeg -i "${fn/.mov/}.mov" -vf "fade=t=out:st=${fadeout}:d=${fadeduration}:color=#E1E1E6,crop=3840:2160:0:120" -codec:v libx264 -crf 18 -pix_fmt yuv420p -c:a aac -strict -2 -ss $start -to $end -async 1 -y "${fn/.mov/}-ffmpeg.mp4" &
echo "Done"
