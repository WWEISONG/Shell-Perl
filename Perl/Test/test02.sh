#!/bin/dash

# Test if statements with composite conditions
i=1
j=10

if [ $i < 5 ] && [ $j > 3 ]
then
    i=$((i + 1))
    echo $i
fi
