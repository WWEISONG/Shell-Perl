#!/bin/dash

# Test shell script for subset-3
num=1
if test $num -gt 0
then
    num=$((num + 3))
    echo $num
fi

if [ -d /2041/assign ]
then
    echo "directory exist"
else
    echo "directory NOT exist"
fi

if test -d /assign
then
    echo "directory exist"
fi

if test -d "sheepl.pl"
then
    echo "file sheepl.pl exist"
else 
    echo "file not exist"
fi

ls -las "$@"
exit 0
