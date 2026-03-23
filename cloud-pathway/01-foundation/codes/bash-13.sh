#!/bin/bash

file="/etc/passwd"

if [ -f "$file" ]; then
    echo "File exists"
    if [ -r "$file" ]; then
        echo "File is readable"
    fi
else
    echo "File does not exist"
fi