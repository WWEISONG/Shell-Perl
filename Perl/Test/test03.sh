#!/bin/dash

# test 'test' expression and backticks
i=1
j=10

if [ $i < 5 ]  && [ $j > 3 ]  
then
    i=$((i + 1))
    # expression with backticks  
    i=`expr $i + 1`
    echo $i 
fi
