#!/bin/bash

${WORKDIR?"Need to set WORKDIR env"} 2>/dev/null

RUNCONF=${WORKDIR}/tpcds_conf/run.config

if [ ! -f ${RUNCONF} ]; then
    echo "File : ${RUNCONF} not found!"
fi

. ${RUNCONF}

echo "Looking for latest 9 log output from ${LOG_DIR} "

for i in `ls -lt ${LOG_DIR}/*.nohup | head -9 | awk '{ print \$9}' `
do
	getTime=`ls -lt $i | awk '{ print \$8}'`
	echo -e  "Parsing file : $i : ($getTime) : \c"
	awk 'c&&!--c;/minTimeMs/{c=2}' $i | awk -F'|' '{print $6}'
done


