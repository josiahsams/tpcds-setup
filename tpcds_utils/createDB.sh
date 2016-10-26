#!/bin/bash

${WORKDIR?"Need to set WORKDIR env"} 2>/dev/null

RUNCONF=${WORKDIR}/tpcds_conf/run.config

if [ ! -f ${RUNCONF} ]; then
    echo "File : ${RUNCONF} not found!"
fi

. ${RUNCONF}

if [ $# -ne 3 ]; then
    echo "Usage: $0 <hdfs_path> <size_in_mb> <db_name>"
    echo "Eg: $0 hdfs://n001/TPCDS-1TB-test 1024 tpcds10tb"
    exit
fi

hdfs_path=$1
size_in_mb=$2
db_name=$3

SCRIPT=${WORKDIR}/tpcds_utils/genData.scala
SCRIPT_TO_EXECUTE=${WORKDIR}/tpcds_utils/genData.scala.$$

sed "s~KIT_PATH =.*~KIT_PATH = ${KIT_PATH}~g; s~DBNAME = .*~DBNAME = \"${db_name}\"~g ; s~HDFS_PATH =.*~HDFS_PATH = \"${hdfs_path}\"~g; s~SIZE_IN_MB =.*~SIZE_IN_MB = ${size_in_mb}~g" ${SCRIPT} > ${SCRIPT_TO_EXECUTE}

# Below parameters will be initialized from run.config and can be overriden here
DRIVER_MEM=30g
DRIVER_CORES=10
EXEC_MEM_OVERHEAD=1536
SHUFFLE_PARTITIONS=64
NUM_EXECUTORS=27
EXEC_CORES=15
EXEC_MEM=20g

$SPARK_HOME/bin/spark-shell --master yarn-client --name dsdgen --driver-memory ${DRIVER_MEM} --driver-cores ${DRIVER_CORES} --conf spark.shuffle.io.numConnectionsPerPeer=4 --conf spark.reducer.maxSizeInFlight=200m --conf spark.executor.extraJavaOptions="-XX:ParallelGCThreads=9 -XX:+AlwaysTenure" --conf spark.sql.shuffle.partitions=${SHUFFLE_PARTTIONS} --conf spark.yarn.executor.memoryOverhead=${EXEC_MEM_OVERHEAD} --conf spark.shuffle.consolidateFiles=true --conf spark.sql.autoBroadcastJoinThreshold=67108864 --conf spark.serializer=org.apache.spark.serializer.KryoSerializer --num-executors ${NUM_EXECUTORS} --executor-cores ${EXEC_CORES} --executor-memory ${EXEC_MEM} -i ${SCRIPT_TO_EXECUTE} --jars ${SQLPERF_JAR} 2>&1 | tee ${size_in_mb}_gendata_$$.out

rm $SCRIPT_TO_EXECUTE


