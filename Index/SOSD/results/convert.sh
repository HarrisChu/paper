#!/bin/bash
for element in `ls $1`
    do  
	echo $element
	filename=$(echo $element | cut -d . -f1)
	extension=$(echo $element | cut -d . -f2)
	grep RESULT: $filename.txt | awk -F ":" '{print $2}' | awk -F "," '{print $1 "_" $2 "," $3 "," $4 "," $5}' > $filename.csv
    done
