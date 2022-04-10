#!/bin/bash

set -e

PATH=$PATH:./build/verible/bin

while [ $# -gt 0 ]
do
    echo "Checking format of $1"
    verible-verilog-format "$1" >build/format-check-tmp
    diff build/format-check-tmp "$1"
    shift
done
