#!/bin/bash

DIRLIST="ocr-testdata  ocr-testdata.0  ocr-testdata.1"

basedir="/mnt/alluxio-fuse/train-data/"  # alluxio cluster memory storage
# basedir="./train-data/"  # local storage
total=0
succ=0
fail=0

dir=
list="${DIRLIST}"
if [ -z  "$list" ]; then
	dir=$basedir
fi
for d in `echo ${list[*]}`
do
	tmp="$basedir/$d"
	dir="$dir $tmp"
done


for f  in `find $dir -type f`; do
	((total++))
	if cat $f >/dev/null 2>&1; then
		((succ++))
	else
		((fail++))
	fi
done

echo total:$total succ:$succ fail:$fail
