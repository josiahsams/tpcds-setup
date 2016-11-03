#!/bin/bash

 if [ $# -ne 3 ]; then
     echo "Usage: $0 <query name> <db_name> <timeout_secs>"
     exit
 fi

# WORKDIR=`grep WORKDIR ~/.bashrc | awk -F'=' '{print \$2}'`

${WORKDIR?"Need to set WORKDIR env"} 2>/dev/null


RUNCONF=${WORKDIR}/tpcds-setup/tpcds_conf/run.config

if [ ! -f ${RUNCONF} ]; then
    echo "File : ${RUNCONF} not found!"
fi

. ${RUNCONF}

query_name=$1
DBNAME=$2
# timeout=1800
timeout=$3

# Below parameters are set in run.config and can be overridden
NUM_EXECUTORS=3
EXEC_CORES=15
EXEC_MEM=20g
EXEC_MEM_OVERHEAD=1536
SHUFFLE_PARTITIONS=64
GC_THREADS=9

PREFIX=${query_name}_throughput_${ARCH}_${NUM_EXECUTORS}e_${EXEC_CORES}c_${EXEC_MEM}

SEQ=0
CNT=`ls -lrt $LOG_DIR/.*.nohup 2>/dev/null | wc | awk '{print \$1}'`
SEQ=$CNT

SCRIPTFILE=$LOG_DIR/${query_name}.mod.scala
sed "s/7200/$timeout/g; s/tpcds10tb/${DBNAME}/g;" ${QUERIES_DIR}/${query_name}.scala > $SCRIPTFILE

/usr/bin/time -v ${SPARK_HOME}/bin/spark-shell --master yarn-client --conf spark.shuffle.io.numConnectionsPerPeer=4 --conf spark.reducer.maxSizeInFlight=200m --conf spark.executor.extraJavaOptions="-Diop.version=4.1.0.0 -XX:ParallelGCThreads=${GC_THREADS} -XX:+AlwaysTenure" --conf spark.sql.shuffle.partitions=${SHUFFLE_PARTITIONS} --conf spark.yarn.driver.memoryOverhead=400 --conf spark.yarn.executor.memoryOverhead=${EXEC_MEM_OVERHEAD} --conf spark.shuffle.consolidateFiles=true --conf spark.sql.autoBroadcastJoinThreshold=67108864 --conf spark.serializer=org.apache.spark.serializer.KryoSerializer --name ${query_name} --driver-memory 6g --driver-cores 6 --num-executors ${NUM_EXECUTORS} --executor-cores ${EXEC_CORES} --executor-memory ${EXEC_MEM} --jars ${SQLPERF_JAR} -i $SCRIPTFILE  > $LOG_DIR/${PREFIX}_${SEQ}.nohup 2>&1

echo "Execution logs are placed under : ${LOG_DIR}/${PREFIX}_${SEQ}.nohup"


