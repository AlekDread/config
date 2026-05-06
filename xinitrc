#!/bin/sh

setxkbmap -layout us,ru -option grp:alt_shift_toggle

xrandr --output DisplayPort-0 --mode 1920x1080 --rate 144 &

pipewire &

exec dwm
