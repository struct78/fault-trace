 ﻿#!/bin/bash
 # Usage
 # > ./edit-render.sh ../../renders/march/render.mov 00:00:07 00:11:30 688 2.0 4K

if [ "$#" -ne 6 ]; then
	echo "Requires 3 arguments:"
	echo "1) Movie file"
	echo "2) Start time"
	echo "3) End time"
	echo "4) Fade out time (in seconds)"
	echo "5) Fade out duration (Fade out time - this number)"
	echo "6) Type: 4K (Default), HD, Square"
	exit
fi

fn=$1
start=$2
end=$3
fadeout=$4
fadeduration=$5
type=$6

echo "Converting $fn"
echo $type

if [ "$type" == "HD" ]; then
	exec ffmpeg -i "${fn}" -vf "fade=t=out:st=${fadeout}:d=${fadeduration}:color=#020C14,crop=3840:2160:0:120,scale=1920:1080" -codec:v libx264 -crf 18 -pix_fmt yuv420p -c:a aac -strict -2 -ss $start -to $end -async 1 -y "${fn%.*}-hd.mp4" &
elif [ "$type" == "Square" ]; then
	exec ffmpeg -i "${fn}" -vf "fade=t=out:st=${fadeout}:d=${fadeduration}:color=#020C14,crop=1890:1890:975:255,scale=1080:1080" -codec:v libx264 -crf 18 -pix_fmt yuv420p -c:a aac -strict -2 -ss $start -to $end -async 1 -y "${fn%.*}-square.mp4" &
else
	exec ffmpeg -i "${fn}" -vf "fade=t=out:st=${fadeout}:d=${fadeduration}:color=#020C14,crop=3840:2160:0:120" -codec:v libx264 -crf 18 -pix_fmt yuv420p -c:a aac -strict -2 -ss $start -to $end -async 1 -y "${fn%.*}-4k.mp4" &
fi

echo "Done"
