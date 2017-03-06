ffmpeg -i render-02-02-2017-edit-ffmpeg.mp4 -b:a 192k -vn january.mp3

#!/bin/bash
if [ "$#" -ne 3 ]; then
	echo "Requires 2 arguments:"
	echo "1) Movie file"
	echo "2) Bitrate"
	echo "3) Output filename"
	exit
fi

fn=$1
bitrate=$2
output=$3

echo "Extracing audio from $fn"
exec ffmpeg -i "${fn}" -b:a ${bitrate} -vn "${output}" &
echo "Done"
