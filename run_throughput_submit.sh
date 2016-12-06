#!/bin/bash

if [[ $# -le 4 ||  $# -ge 7 ]]; then
    echo "Usage: $0 <num-executors> <executor-cores> <executor-memory> <db_name> <timeout> -o|-n|-no"
    exit
fi

${WORKDIR?"Need to set WORKDIR env"} 2>/dev/null

RUNCONF=${WORKDIR}/tpcds-setup/tpcds_conf/run.config

if [ ! -f ${RUNCONF} ]; then
    echo "File : ${RUNCONF} not found!"
fi

. ${RUNCONF}

num_executors=$1
executor_cores=$2
executor_memory=$3
databaseName=$4
timeout=$5
enableOperf=$6

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
HOST=`hostname`
USER=`whoami`
PASSWD="passw0rd"

PREFIX=throughput_${ARCH}_${num_executors}e_${executor_cores}c_${executor_memory}
SEQ=0
CNT=`ls -lrt ${LOG_DIR}/${PREFIX}_nmon_logs 2>/dev/null | wc | awk '{print \$1}'`
SEQ=$CNT

CUR_NMON_DIR=${LOG_DIR}/${PREFIX}_${SEQ}_nmon_logs

cat ${HADOOP_HOME}/etc/hadoop/slaves | grep -v ^# | xargs -i ssh {} "sync && echo 3 | sudo tee /proc/sys/vm/drop_caches"

if [[ ! -f ${JMETER_BIN} ]]; then
    echo "Jmeter binary is not found"
    exit 22
fi

if [[ $enableOperf == *"n"* ]]; then
	echo "Starting nmon and logs will be placed under ${CUR_NMON_DIR}"
	startnmon.sh $CUR_NMON_DIR
fi

if [[ $enableOperf == *"o"* ]]; then
	type operf >/dev/null 2>&1
	if [ $? -ne 0 ]; then
		echo "operf is not installed. Exiting."
		exit 255
	fi

	export OPERFLIB=${WORKDIR}/oprofile/oprofile_install/lib

	if [ ! -d ${OPERFLIB} ]; then
	    echo "OPERFLIB is not set properly"
	    echo "check OPERFLIB value in this script and continue."
	    exit 255
	fi

	oprofile_start.sh
fi


JMX=${WORKDIR}/tpcds-setup/tpcds_conf/baidu-tpcds-yarn-throughput-allcores.jmx
JMX_IN_USE=${WORKDIR}/tpcds-setup/tpcds_conf/baidu-tpcds-yarn-throughput-allcores.jmx.$$

sed "s~SRCPATH~${DIR}~g; s~HOST~${HOST}~g; s~USER~${USER}~g; s~PASSWD~${PASSWD}~g; s~DBNAME~${databaseName}~g; s~TIMEOUT~${timeout}~g; s~EXEC~${num_executors}~g; s~CORES~${executor_cores}~g; s~MEMORY~${executor_memory}~g; s~EXTRA~${enableOperf}~g; " $JMX > $JMX_IN_USE

/usr/bin/time  ${JMETER_BIN} -n -t ${JMX_IN_USE} -l ${LOG_DIR}/run1.jtl -j ${LOG_DIR}/run1.log

# rm $JMX_IN_USE
echo $JMX_IN_USE

if [[ $enableOperf == *"n"* ]]; then
   stopnmon.sh $CUR_NMON_DIR
fi

if [[ $enableOperf == *"o"* ]]; then
  oprofile_stop.sh
fi


