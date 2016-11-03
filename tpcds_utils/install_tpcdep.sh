#!/bin/bash

${WORKDIR?"Need to set WORKDIR env"} 2>/dev/null
type AN >/dev/null 2>&1 || { echo >&2 "Require AN script to be in path. Aborting."; exit 1; }
type DN >/dev/null 2>&1 || { echo >&2 "Require DN script to be in path. Aborting."; exit 1; }
type CP >/dev/null 2>&1 || { echo >&2 "Require CP script to be in path. Aborting."; exit 1; }

REPO_DIR=${WORKDIR}/tpcds-setup
DEPSDIR=${REPO_DIR}/tpcdeps

mkdir -p ${DEPSDIR}

DEPSLOGS=${DEPSDIR}/install_tpcdep.log.$$
echo "Logs will be placed under ${DEPSLOGS} "

echo "Setting up spark-sql-perf"
cd ${DEPSDIR}
if [ ! -d ${DEPSDIR}/spark-sql-perf ]; then
   git clone https://github.com/josiahsams/spark-sql-perf 
   cd ./spark-sql-perf
#  Not required for this git repo
#  git checkout -b v0.3.2 v0.3.2
fi

SQLPERF_JAR=${DEPSDIR}/spark-sql-perf/target/scala-2.10/spark-sql-perf_2.10-0.3.2.jar
if [ ! -f ${SQLPERF_JAR} ]; then
   cd ${DEPSDIR}/spark-sql-perf
   export DBC_USERNAME=`whoami`
   ./build/sbt clean package >> ${DEPSLOGS}  2>&1
   if [[ $? -ne 0 ]]; then
   	echo "spark-sql-perf compilation failed"
   	exit
   fi
fi


echo "Setting up tpcds-kit"
cd ${DEPSDIR}
KIT_PATH=${DEPSDIR}/tpcds-kit/tools
if [ ! -d ${KIT_PATH} ]; then
   git clone https://github.com/davies/tpcds-kit.git
   cd ./tpcds-kit/tools
   cp Makefile.suite Makefile
   make >> ${DEPSLOGS} 2>&1
   if [[ $? -ne 0 ]]; then
        echo "tpcds-kit compilation failed"
        exit
   fi
fi

echo "Copy tpcds-kit to all the slave nodes"
cd ${DEPSDIR}
tar cf tpcds-kit.tar ./tpcds-kit
DN "mkdir -p ${DEPSDIR}"
CP ${DEPSDIR}/tpcds-kit.tar ${DEPSDIR}/tpcds-kit.tar 
DN "tar xf ${DEPSDIR}/tpcds-kit.tar -C ${DEPSDIR} "
AN "chmod -R a+rx ${DEPSDIR}/tpcds-kit"


echo "Setting up Jmeter"
cd ${DEPSDIR}
JMETER_BIN=${DEPSDIR}/apache-jmeter-2.13/bin/jmeter
if [ ! -f ${JMETER_BIN} ]; then
    wget https://archive.apache.org/dist/jmeter/binaries/apache-jmeter-2.13.tgz
    tar zxf apache-jmeter-2.13.tgz
    # install jmeter-ssh-sampler. Refer https://code.google.com/archive/p/jmeter-ssh-sampler/downloads
    cp ${REPO_DIR}/tpcds_utils/jmeter-ssh-sampler-0.1.0.jar ${DEPSDIR}/apache-jmeter-2.13/lib/ext
    # Refer http://www.jcraft.com/jsch/index.html
    cp ${REPO_DIR}/tpcds_utils/jsch-0.1.54.jar ${DEPSDIR}/apache-jmeter-2.13/lib
fi


