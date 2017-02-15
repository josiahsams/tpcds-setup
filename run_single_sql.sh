#!/bin/bash

if [[ $# -ne 5 && $# -ne 6 ]]; then
    echo "Usage: $0 <query name> <num-executors> <executor-cores> <executor-memory> <db_name> -o|-n|-no"
    exit
fi

${WORKDIR?"Need to set WORKDIR env"} 2>/dev/null

RUNCONF=${WORKDIR}/tpcds-setup/conf/run.config

if [ ! -f ${RUNCONF} ]; then
    echo "File : ${RUNCONF} not found!"
fi

. ${RUNCONF}

query_name=$1
num_executors=$2
executor_cores=$3
executor_memory=$4
databaseName=$5
enableOperf=$6

executor_memoryOverhead=$EXEC_MEM_OVERHEAD
sql_shuffle_partitions=$SHUFFLE_PARTITIONS
gcThreads=$GC_THREADS


PREFIX=${query_name}_single_${ARCH}_${num_executors}e_${executor_cores}c_${executor_memory}

SEQ=0
CNT=`ls -lrt ${LOG_DIR}/${PREFIX}_*.nohup 2>/dev/null | wc | awk '{print \$1}'`
SEQ=$CNT

cat ${HADOOP_HOME}/etc/hadoop/slaves | grep -v ^# | xargs -i ssh {} "sync && echo 3 | sudo tee /proc/sys/vm/drop_caches"

if [[ $enableOperf == *"n"* ]]; then
    CUR_NMON_DIR=${LOG_DIR}/${PREFIX}_${SEQ}_nmon_logs
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
    executor_extraJavaOptions="-agentpath:${OPERFLIB}/oprofile/libjvmti_oprofile.so"
    extraOptions="--conf spark.executor.extraLibraryPath=${OPERFLIB} --driver-library-path ${OPERFLIB} --driver-java-options -agentpath:${OPERFLIB}/oprofile/libjvmti_oprofile.so" 
else
    executor_extraJavaOptions=""
    extraOptions=""
fi

echo "Execution logs will be placed under : ${LOG_DIR}${PREFIX}_${SEQ}.nohup " 

${SPARK_HOME}/bin/spark-sql                                                                                \
    --conf  spark.kryo.referenceTracking=true                                                                               \
    --conf  spark.kryoserializer.buffer.max=256m                                                                            \
    --conf spark.shuffle.io.numConnectionsPerPeer=4                                                                         \
    --conf spark.reducer.maxSizeInFlight=128m                                                                               \
    --conf spark.executor.extraJavaOptions="-Diop.version=4.1.0.0 -XX:ParallelGCThreads=${gcThreads} -XX:+AlwaysTenure ${executor_extraJavaOptions}"     \
    ${extraOptions}                                                                                                         \
    --conf spark.sql.shuffle.partitions=${sql_shuffle_partitions}                                                           \
    --conf spark.yarn.driver.memoryOverhead=400                                                                             \
    --conf spark.yarn.executor.memoryOverhead=${executor_memoryOverhead}                                                    \
    --conf spark.shuffle.consolidateFiles=true                                                                              \
    --conf spark.reducer.maxSizeInFlight=128m                                                                               \
    --conf spark.sql.autoBroadcastJoinThreshold=67108864                                                                    \
    --conf spark.serializer=org.apache.spark.serializer.KryoSerializer                                                      \
    --master yarn                                                                                                           \
    --deploy-mode client                                                                                                    \
    --name ${query_name}                                                                                                    \
    --database ${databaseName}                                                                                              \
    --driver-memory 22g                                                                                                     \
    --driver-cores 10                                                                                                       \
    --num-executors ${num_executors}                                                                                        \
    --executor-cores ${executor_cores}                                                                                      \
    --executor-memory ${executor_memory}                                                                                    \
    --verbose                                                                                                               \
    -f ${QUERIES_DIR}/${query_name}.sql 2>&1 | tee ${LOG_DIR}/${PREFIX}_${SEQ}.nohup
            
echo "Execution logs are placed under : ${LOG_DIR}${PREFIX}_${SEQ}.nohup " 

if [[ $enableOperf == *"n"* ]]; then
   stopnmon.sh $CUR_NMON_DIR
fi

if [[ $enableOperf == *"o"* ]]; then
  oprofile_stop.sh
fi

cd ${SPARK_EVENT_LOG_PATH}
ls -lart application* | tail -n 1 | awk '{print $9}' | xargs -i tar czf ${LOG_DIR}/{}.tgz {}
cd -

