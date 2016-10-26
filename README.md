# tpcds-setup

1. Download and build the Databricks TPC-DS benchmark package

  The version to be used is 0.3.2, which is good for Spark 1.6.1. First the github repository from https://github.com/databricks/spark-sql-perf and checkout the 0.3.2 version and proceed to build.
  
  export DBC_USERNAME=root
  
  cd ./spark-sql-perf-0.3.2
  
  ./build/sbt clean package
  
  If the build succeeds you will see a jar (in green below) created. You need this jar later to run the benchmark.
  
2. Download and build the TPC-DS datagen kit

    git clone https://github.com/davies/tpcds-kit.git

    cd ./tpcds-kit/tools
    cp Makefile.suite Makefile
    make

  You need this to generate the TPC-DS raw data. Then copy the tpcds-kit to all the nodes and place it in the same directory, and grand read and write permissions to all users (chmod –R a+rx <tpcde-kit dir>

3. Install `mysql` and make `mysql` to manage the HIVE metastore instead the default `derby` so that multiple connections can be made access the HIVE Database parallelly.
  
    a. sudo apt-get update
    b. sudo apt-get dist-upgrade

      sudo apt-get install mysql-server mysql-client
  
    c. set root password (mysql root)
  
    d. sudo apt-get install libmysql-java

      ls -lt /usr/share/java/mysql-connector-java.jar

    e. Create metastore_db
 
```
  mysql -u root -p
  mysql> CREATE DATABASE metastore_db;
  mysql> CREATE USER 'hiveuser'@'%' IDENTIFIED BY 'hivepassword';

  mysql> GRANT all on *.* to 'hiveuser'@localhost identified by 'hivepassword';
  mysql>  flush privileges;
```
    f. sudo netstat -tap | grep mysql
  
    g. sudo systemctl restart mysql.service

4. Create a file `hive-site.xml` if not found under ${SPARK_HOME}/conf/ and make similar changes as follows so that spark uses the mysql DB for HIVE metastore information for SQLContext based queries,

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

5. Take copy of the `tpcds_conf/` and `tpcds_queries/` directory and place it under `WORKDIR` directory. `WORKDIR` is where you want all the log files and configuration files to be placed. All the provided scripts expect WORKDIR to be
   made part of ~/.bashrc
   
6.	Generate the TPC-DS raw data and create the TPC-DS database as well as the table objects

  Use the scripts provided in the utils directory.
    
      genData.sh <hdfs_name> <size_in_mb>
      
      createDB.sh <hdfs_name> <size_in_mb> <db_name>
   
7. Download jmeter version 2.13 from the below link,
   
      wget https://archive.apache.org/dist/jmeter/binaries/apache-jmeter-2.13.tgz

   
8. Config the ${WORKDIR}/tpcds_conf/run.config file before running tpcds benchmark scripts,
   
   SET LOG_DIR
   SET TEST_SCRIPTS_DIR
   SET JMETER_PATH
   SET SQLPERF_JAR
   
   
9. There are 2 types of tpcds benchmark script provided,
   
    a) To run one sql query at a time and to get the execution time invoke `run_single.sh` script as follows,
   
      run_single.sh q19[^1] 15 30 30g 2048 200 9
   
      [^1]: Note: Here we run the sql query found under `${WORKDIR}/tpcds_queries/q19_baidu_tuned_2.sql` with other parameters.
   
    b) run throughput test by invoking jmeter inside the script,
   
      run_throughput_with_jmeter_nm.sh
  
      Note: Running this script will invoke all the 9 sql queries found under `${WORKDIR}/tpcds_queries/*.scala" in parallel using `jmeter` for the specified timeout period. 



