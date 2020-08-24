#!/bin/dash

# Test shell script for subset-4
i=0
j=1
if [ $i -lt 3 ] || [ $j -gt 5 ]
then
    i=`expr $i + 1`
    j=$((j + 1))
    echo $i $j
fi

check_number() {
    num=$1
    i=0
    while test $i -le $num 
    do
        if [ $((i % 2)) -eq 0 ]
        then
            echo $i is even
        else
            echo $i is odd
        fi
        i=$((i + 1))
    done
}

check_number 10

echo 'Input a number between 1 to 4'
echo 'Your number is:'
read aNum
case $aNum in
    1)  echo 'You select 1'
    ;;
    2)  echo 'You select 2'
    ;;
    3)  echo 'You select 3'
    ;;
    4)  echo 'You select 4'
    ;;
    *)  echo 'You do not select a number between 1 to 4'
    ;;
esac
