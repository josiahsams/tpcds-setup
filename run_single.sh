#!/bin/bash

if [ $# -ne 7 ]; then
    echo "Usage: $0 <query name> <num-executors> <executor-cores> <executor-memory> <executor-memoryOverhead> <sql-shufle-partitions> <# of GC Threads>"
    exit
fi

${WORKDIR?"Need to set WORKDIR env"} 2>/dev/null

RUNCONF=${WORKDIR}/tpcds-setup/tpcds_conf/run.config

if [ ! -f ${RUNCONF} ]; then
    echo "File : ${RUNCONF} not found!"
fi

. ${RUNCONF}

query_name=$1
num_executors=$2
executor_cores=$3
executor_memory=$4
executor_memoryOverhead=$5
sql_shuffle_partitions=$6
gcThreads=$7

PREFIX=${query_name}_single_${ARCH}_${num_executors}e_${executor_cores}c_${executor_memory}

SEQ=0
CNT=`ls -lrt ${LOG_DIR}/${PREFIX}_*.nohup 2>/dev/null | wc | awk '{print \$1}'`
SEQ=$CNT

cat ${HADOOP_HOME}/etc/hadoop/slaves | grep -v ^# | xargs -i ssh {} "sync && echo 3 > /proc/sys/vm/drop_caches"

# CUR_NMON_DIR=${NMON_DIR}/${PREFIX}_${SEQ}_nmon_logs
# startnmon.sh $CUR_NMON_DIR

/usr/bin/time -v ${SPARK_HOME}/bin/spark-sql --master yarn-client --conf spark.kryo.referenceTracking=true --conf spark.shuffle.io.numConnectionsPerPeer=4 --conf spark.reducer.maxSizeInFlight=128m --conf spark.executor.extraJavaOptions="-Diop.version=4.1.0.0 -XX:ParallelGCThreads=${gcThreads} -XX:+AlwaysTenure" --conf spark.sql.shuffle.partitions=${sql_shuffle_partitions} --conf spark.yarn.driver.memoryOverhead=400 --conf spark.yarn.executor.memoryOverhead=${executor_memoryOverhead} --conf spark.shuffle.consolidateFiles=true --conf spark.reducer.maxSizeInFlight=128m --conf spark.sql.autoBroadcastJoinThreshold=67108864 --conf spark.serializer=org.apache.spark.serializer.KryoSerializer --name ${query_name} --database tpcds10tb --driver-memory 12g --driver-cores 16 --num-executors ${num_executors} --executor-cores ${executor_cores} --executor-memory ${executor_memory} -f ${QUERIES_DIR}/${query_name}.sql > ${LOG_DIR}/${PREFIX}_${SEQ}.nohup 2>&1

echo "Execution logs are placed under : ${LOG_DIR}${PREFIX}_${SEQ}.nohup " 

# stopnmon.sh $CUR_NMON_DIR

cd ${SPARK_EVENT_LOG_PATH}
ls -lart application* | tail -n 1 | awk '{print $9}' | xargs -i tar czf ${LOG_DIR}/{}.tgz {}
cd -

