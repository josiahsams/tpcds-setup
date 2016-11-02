# tpcds-setup

###Requirements:

1. Spark 1.6.1 should be installed and SPARK_HOME should be set in the environment variable.
2. HADOOP YARN Setup should be completed and HADOOP_HOME should be set in the environment variable.
3. Make sure the nodes are set for password-less SSH both ways(master->slaves & slaves->master).
4. Since we use the environment variables a lot in our scripts, make sure to comment out the portion following this statement in your ~/.bashrc ,
  `If not running interactively, don't do anything`
5. Kindly refer to the setups & scripts provided in https://github.com/kmadhugit/hadoop-cluster-utils before proceeding further as the utility scripts provided in the repository are needed here.
 
###Steps to run TPC-DS Benchmark:

1. Clone this repository and follow the steps before proceeding.
    Note: `WORKDIR` is where you will be running the scripts and all the log files and configuration files will be placed. All the provided scripts expect WORKDIR to be made part of ~/.bashrc. 

  ```bash
  git clone https://github.com/josiahsams/tpcds-setup
  #Update PATH and WORKDIR in .bashrc
  vi ~/.bashrc
  G
  export WORKDIR=${HOME}
  export PATH=$PATH:${WORKDIR}/tpcds-setup
  . ~/.bashrc  
  ```

    
2. Download and build the Databricks TPC-DS benchmark package

  The version to be used is 0.3.2, which is good for Spark 1.6.1. First the github repository from https://github.com/databricks/spark-sql-perf and checkout the 0.3.2 version and proceed to build.
  
  ```
  git clone https://github.com/databricks/spark-sql-perf.git
  cd ./spark-sql-perf-0.3.2
  git checkout -b v0.3.2 v0.3.2
  export DBC_USERNAME=`whoami`
  ./build/sbt clean package
  ls ./target/scala-2.10/*.jar
  ```
  If the build succeeds you will see a jar (in ./target/scala-2.10/ directory) created. You need this jar's absolute path (SQLPERF_JAR) later to run the benchmark. Refer step 8.
  
3. Download and build the TPC-DS datagen kit. You need this to generate the TPC-DS raw data. 

  ```
    cd ${WORKDIR}
    git clone https://github.com/davies/tpcds-kit.git
    cd ./tpcds-kit/tools
    cp Makefile.suite Makefile
    make
  ```
  
  Then copy the tpcds-kit to all the nodes and place it in the same directory, and grand read and write permissions to all users (chmod –R a+rx <tpcds-kit dir>)
  
  ```
    cd ${WORKDIR}
    tar cf tpcds-kit.tar ./tpcds-kit
    CP ${WORKDIR}/tpcds-kit.tar ${WORKDIR}/tpcds-kit.tar 
    DN "tar xvf ${WORKDIR}/tpcds-kit.tar"
    AN "chmod -R a+rx ${WORKDIR}/tpcds-kit"
  ```

4. Install `mysql` and make `mysql` to manage the HIVE metastore instead the default `derby` so that multiple connections can be made access the HIVE Database parallelly.
  
    a. Install the following packages in Ubuntu. 
    
    Note: During the installation of mysql-server, you'll be prompted to create a root password. We need this password to create database later in this process.
  
  ```
    sudo apt-get update
    sudo apt-get dist-upgrade
    sudo apt-get install mysql-server mysql-client
    sudo apt-get install libmysql-java
  ```

    b. Confirm the connector jar file is found under:
  
  ```
     ls -lt /usr/share/java/mysql-connector-java.jar
  ```

    c. Create metastore_db to store all the HIVE Catalogs & Schema definitions if not already exists.
    
      To list all the database, run the command and check metatstore_db exists,
    
  ```mysql
  mysql> show databases;
  ```
      
      To list all users, run the command and check for `hive` user
    
  ```mysql
  mysql> select user from mysql.user;
  ```
 
  ```mysql
  mysql -u root -p
  mysql> CREATE DATABASE metastore_db;
  mysql> CREATE USER 'hive'@'%' IDENTIFIED BY 'hivepassword';
  mysql> GRANT all on *.* to 'hive'@localhost identified by 'hivepassword';
  mysql>  flush privileges;
  ```

    d. Confirm `mysql` services are up and runnning. If not restart the service.

  ```
    sudo netstat -tap | grep mysql
    sudo systemctl restart mysql.service
  ```

5. Create a file `hive-site.xml` under ${SPARK_HOME}/conf/, if not found. Make similar changes as follows so that spark uses the mysql DB for HIVE metastore information for SQLContext based queries,

  ```bash
    vi ${SPARK_HOME}/conf/hive-site.xml
  ```
  
    Copy the below content into the file.

  ```xml
    <configuration>
          <property>
                <name>javax.jdo.option.ConnectionURL</name>
                <value>jdbc:mysql://localhost/metastore_db?createDatabaseIfNotExist=true</value>
                <description>metadata is stored in a MySQL server</description>
          </property>
          <property>
                <name>javax.jdo.option.ConnectionDriverName</name>
                <value>com.mysql.jdbc.Driver</value>
                <description>MySQL JDBC driver class</description>
          </property>
          <property>
                <name>javax.jdo.option.ConnectionUserName</name>
                <value>hive</value>
                <description>user name for connecting to mysql server </description>
          </property>
          <property>
                <name>javax.jdo.option.ConnectionPassword</name>
                <value>hivepassword</value>
                <description>password for connecting to mysql server </description>
          </property>
    </configuration>
  ```

6. Take copy of the `tpcds_conf/`, `tpcds_queries/` and `tpcds_utils` directory and place it under `WORKDIR` directory.

  ```
  cp -r tpcds_conf/ ${WORKDIR}/
  cp -r tpcds_queries/ ${WORKDIR}/
  cp -r tpcds_utils/ ${WORKDIR}/
  
  ```
   
7. Download jmeter version 2.13 from the below link,
   
   ```
      cd ${WORKDIR}
      wget https://archive.apache.org/dist/jmeter/binaries/apache-jmeter-2.13.tgz
      tar zxf apache-jmeter-2.13.tgz
   ```

   Set JMETER_PATH to the downloaded absolute path. Refer Step 8.
   
8. Config the ${WORKDIR}/tpcds_conf/run.config file before running tpcds benchmark scripts,

   ```
   export LOG_DIR=${WORKDIR}/tpcds_logs
   export QUERIES_DIR=${WORKDIR}/tpcds_queries
   export JMETER_PATH=${WORKDIR}/apache-jmeter-2.13/bin/jmeter
   export SQLPERF_JAR=${WORKDIR}/spark-sql-perf/target/scala-2.10/spark-sql-perf_2.10-0.3.2.jar
   ```
   
9. Generate the TPC-DS raw data and create the TPC-DS database as well as the table objects. Use the scripts provided in the utils directory.

  ```
    genData.sh <hdfs_name> <size_in_mb>
    createDB.sh <hdfs_name> <size_in_mb> <db_name>
  ```

10. There are 2 types of tpcds benchmark script provided,
   
    a. To run one sql query at a time and to get the execution time invoke `run_single.sh` script as follows,
    
  ```
  run_single.sh q19 15 30 30g 2048 200 9
  ```

      Note: Here we run the sql query found under `${WORKDIR}/tpcds_queries/q19_baidu_tuned_2.sql` with other parameters.
   
    b. run throughput test by invoking jmeter inside the script,
    
  ```   
  run_throughput_with_jmeter_nm.sh
  ```

      Note: Running this script will invoke all the 9 sql queries found under `${WORKDIR}/tpcds_queries/*.scala` in parallel using `jmeter` for the specified timeout period. 



