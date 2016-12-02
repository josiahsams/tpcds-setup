#!/bin/bash

if [ $# -ne 1 ]; then
    echo "provide cpu count to limit active cores"
    exit 1
fi

cpucount=$1
totalcores=`sudo ppc64_cpu --cores-present | awk '{print $6 }'`

if [[ $cpucount -lt 1 || $cpucount -gt $totalcores ]];then
    echo "Provide cpu count between 1 & $totalcores"
    exit 1
fi

totalvcpus=`lscpu | grep "^CPU(s):" | awk '{print $2 }'`
activevcpus=`lscpu | grep "On-line CPU" | awk '{print $4}'`
echo "OLD Active VCPUS: $activevcpus (out of $totalvcpus)" 

sudo ppc64_cpu --cores-on=$cpucount
if [ $? -eq 0 ]; then
   echo "Activated $cpucount cores successfully"
else
   echo "Error activating $cpucount cores"
   eixt 1
fi

activevcpus=`lscpu | grep "On-line CPU" | awk '{print $4}'`
echo "Active VCPUS: $activevcpus (out of $totalvcpus)" 
