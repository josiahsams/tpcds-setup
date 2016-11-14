#!/bin/bash

${WORKDIR?"Need to set WORKDIR env"} 2>/dev/null

if [ $# -ne 2 ]; then
     echo "Usage: $0 <db_name> <timeout_secs>"
     exit
fi

RUNCONF=${WORKDIR}/tpcds-setup/tpcds_conf/run.config

if [ ! -f ${RUNCONF} ]; then
    echo "File : ${RUNCONF} not found!"
fi

. ${RUNCONF}

DBNAME=$1
TIMEOUT=$2
# HOST=pcloud1.austin.ibm.com
# USER=testuser
# PASSWD=passw0rd
${HOST?"Need to set HOST, USER, PASSWD in this script"} 2>/dev/null
${USER?"Need to set HOST, USER, PASSWD in this script"} 2>/dev/null
${PASSWD?"Need to set HOST, USER, PASSWD in this script"} 2>/dev/null

PREFIX=throughput_${ARCH}_jmeter

SEQ=$$

cat ${HADOOP_HOME}/etc/hadoop/slaves | grep -v ^# | xargs -i ssh {} "sync && echo 3 | sudo tee /proc/sys/vm/drop_caches"

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

JMX=${WORKDIR}/tpcds-setup/tpcds_conf/baidu-tpcds-yarn-throughput-allcores.jmx
JMX_IN_USE=${WORKDIR}/tpcds-setup/tpcds_conf/baidu-tpcds-yarn-throughput-allcores.jmx.$$

sed "s~SRCPATH~${DIR}~g; s~HOST~${HOST}~g; s~USER~${USER}~g; s~PASSWD~${PASSWD}~g; s~DBNAME~${DBNAME}~g; s~TIMEOUT~${TIMEOUT}~g;" $JMX > $JMX_IN_USE

# CUR_NMON_DIR=${NMON_DIR}/${PREFIX}_${SEQ}_nmon_logs
# startnmon.sh $CUR_NMON_DIR

/usr/bin/time  ${JMETER_BIN} -n -t ${JMX_IN_USE} -l ${LOG_DIR}/run1.jtl -j ${LOG_DIR}/run1.log

# stopnmon.sh $CUR_NMON_DIR

rm $JMX_IN_USE

cd ${SPARK_EVENT_LOG_PATH}
ls -lart application* | tail -n 1 | awk '{print $9}' | xargs -i tar czf ${LOG_DIR}/{}.tgz {}
cd -


