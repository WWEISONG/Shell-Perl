#!/bin/dash

# demo shell script for subset-1

for name in Sherman Adem Amy Allen 
do
    echo "hello you guys:"
    echo $name
done

for num in 2000 3000 5000
do
    echo guess number, please input a number:
    read number
    echo real number: $num
    echo your number: $number
done

for word in China 2020 Great
do 
    echo "$word $word"
    exit 0
done

for word in Houston 1202 alarm
do
    echo $word
done

for word in Houston 1202 alarm
do
    echo $word
    exit 0
done

for c_file in *.c
do
    echo gcc -c $c_file
done
