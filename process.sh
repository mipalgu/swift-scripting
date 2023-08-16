#! /bin/sh

function sigint_handler() {
    exit 0
}

trap 'sigint_handler' SIGINT
echo "start"
counter=0
while [ $counter -le 60 ]
do
    sleep 1
    ((counter++))
done
exit 1
