#!/bin/bash
if [[ $# -le 4 || $# -ge 7 ]]; then
    echo "Usage: $0 <num-executors> <executor-cores> <executor-memory> <driver-memory> <iterations> <filter>"
    echo "Filter is optional, for example DF will run all queries that contain the name DF"
    echo "List of queries is "
    echo "+-------------------------+
|name                     |
+-------------------------+
|DF: average              |
|DF: back-to-back filters |
|DF: back-to-back maps    |
|DF: range                |
|DS: average              |
|DS: back-to-back filters |
|DS: back-to-back maps    |
|DS: range                |
|RDD: average             |
|RDD: back-to-back filters|
|RDD: back-to-back maps   |
|RDD: range               |
+-------------------------+
Some examples: ./run_ds_perf.sh 12 1 2g 2g 10
Some examples: ./run_ds_perf.sh 12 1 2g 2g 10 DF - runs all queries in DF (Dataframe benchmarks)
Some examples: ./run_ds_perf.sh 12 1 2g 2g 10 filters - runs all filters 
" 
    exit
fi

${WORKDIR?"Need to set WORKDIR env"} 2>/dev/null

RUNCONF=${WORKDIR}/tpcds-setup/conf/run.config

if [ ! -f ${RUNCONF} ]; then
    echo "File : ${RUNCONF} not found!"
fi

. ${RUNCONF}


num_executors=$1
executor_cores=$2
executor_memory=$3
driver_memory=$4
iterations=$5
filter=$6

if  [ $# -eq 6 ] && [ $filter != "" ] 
then
   filter=" --filter ${filter}" 
fi

executor_memoryOverhead=$EXEC_MEM_OVERHEAD
sql_shuffle_partitions=${SHPART:-$SHUFFLE_PARTITIONS}
echo "sql_shuffle_partitions is set to ${sql_shuffle_partitions}"
gcThreads=$GC_THREADS


PREFIX=run_ds_${ARCH}_${num_executors}e_${executor_cores}c_${executor_memory}

SEQ=0
CNT=`ls -lrt ${LOG_DIR}/run_ds_*.nohup 2>/dev/null | wc | awk '{print \$1}'`
SEQ=$CNT

cat ${HADOOP_HOME}/etc/hadoop/slaves | grep -v ^# | xargs -i ssh {} "sync && echo 3 | sudo tee /proc/sys/vm/drop_caches"



echo "Execution logs will be placed under : ${LOG_DIR}${PREFIX}_${SEQ}.nohup " 

${SPARK_HOME}/bin/spark-submit                                                                                              \
    --class  com.databricks.spark.sql.perf.RunBenchmark                                                                  \
    --conf  spark.kryo.referenceTracking=true                                                                               \
    --conf  spark.kryoserializer.buffer.max=256m                                                                            \
    --conf spark.shuffle.io.numConnectionsPerPeer=4                                                                         \
    --conf spark.reducer.maxSizeInFlight=128m                                                                               \
    --conf spark.executor.extraJavaOptions="-Diop.version=4.1.0.0 -XX:ParallelGCThreads=${gcThreads} -XX:+AlwaysTenure ${executor_extraJavaOptions}"      \
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
    --driver-memory ${driver_memory}                                                                                                     \
    --driver-cores 10                                                                                                       \
    --num-executors ${num_executors}                                                                                        \
    --executor-cores ${executor_cores}                                                                                      \
    --executor-memory ${executor_memory}                                                                                    \
    --verbose                                                                                                               \
    ${SQLPERF_JAR} ${filter}                                                                                                \
    -i ${iterations}                                                                                                        \
    -b com.databricks.spark.sql.perf.DatasetPerformance                                                                     \
    | tee ${LOG_DIR}/${PREFIX}_${SEQ}.nohup
            
echo "Execution logs are placed under : ${LOG_DIR}${PREFIX}_${SEQ}.nohup " 

cd ${SPARK_EVENT_LOG_PATH}
ls -lart application* | tail -n 1 | awk '{print $9}' | xargs -i tar czf ${LOG_DIR}/{}.tgz {}
cd -
