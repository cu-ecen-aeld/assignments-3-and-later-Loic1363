#!/bin/bash

writefile=$1
writestr=$2

if [ -z "$writefile" ] || [ -z "$writestr" ]; then
    echo "Error: Missing arguments"
    exit 1
fi

mkdir -p "$(dirname "$writefile")"

echo "$writestr" > "$writefile"

if [ $? -ne 0 ]; then
    echo "Error: Could not create the file"
    exit 1
fi
