# tpcds-setup

1.	Download and build the Databricks TPC-DS benchmark package

  The version to be used is 0.3.2, which is good for Spark 1.6.1. First the github repository from https://github.com/databricks/spark-sql-perf and checkout the 0.3.2 version and proceed to build.
  
  export DBC_USERNAME=root
  
  cd ./spark-sql-perf-0.3.2
  
  ./build/sbt clean package
  
  If the build succeeds you will see a jar (in green below) created. You need this jar later to run the benchmark.
  
  2.	Download and build the TPC-DS datagen kit

    git clone https://github.com/davies/tpcds-kit.git

    cd ./tpcds-kit/tools
    cp Makefile.suite Makefile
    make

You need this to generate the TPC-DS raw data. Then copy the tpcds-kit to all the nodes and place it in the same directory, and grand read and write permissions to all users (chmod –R a+rx <tpcde-kit dir>

   3. Take copy of the conf/ and test_scripts/ directory and place it under WORKDIR directory. WORKDIR is where
   you want all the log files and configuration files to be placed. All the provided scripts expect WORKDIR to be
   made part of ~/.bashrc
   
  4.	Generate the TPC-DS raw data and create the TPC-DS database as well as the table objects

  Use the scripts provided in the utils directory.
    
      genData.sh
      
      createDB.sh
   
   4. Download jmeter
   

   
   6. Config the run.config file ,
   
   SET LOG_DIR
   SET TEST_SCRIPTS_DIR
   SET JMETER_PATH
   SET SQLPERF_JAR
   
   
   
  5. There are 2 types of script provided,
   
   a) run one query at a time to calculate the execution time.
   
   run_single.sh
   
   b) run throughput test by invoking jmeter inside the script,
   
   run_throughput_with_jmeter_nm.sh
  



