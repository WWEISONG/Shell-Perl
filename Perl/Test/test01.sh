#!/bin/dash

# Test for while loop with composite conditions
i=0
j=1
while test $i -lt 100 && test $j -le 30
do
    echo $i $j
    i=`expr $i + 1`
done
