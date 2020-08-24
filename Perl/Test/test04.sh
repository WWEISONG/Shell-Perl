#!/bin/dash

# Test function declaration and function call
say_hello() {
    local i
    i=$1
    while [ $i < 3 ]
    do 
        echo "hello there!!"
        i=$((i + 1))
    done
}

say_hello 2
