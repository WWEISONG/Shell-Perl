#!/bin/dash

# Test shell script for subset-2
if [ name = Sam ]
then
    echo hello Sam
elif test name = Sherman
then
    echo hello Sherman
elif test name = Will
then 
    echo hello Will
fi

if [ name = name ] && [ family = family ]
then
    echo not possible
fi

if test Andrew = great
then
    echo correct
elif test Andrew = fantastic
then
    echo yes
else
    echo error
fi

i=0
j=10
if test $i -lt 30 && test $j -le 10
then
    echo success
fi  