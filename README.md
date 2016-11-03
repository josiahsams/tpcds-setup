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
  #Add PATH and WORKDIR in .bashrc
  export WORKDIR=${HOME}
  export PATH=$PATH:${WORKDIR}/tpcds-setup:${WORKDIR}/tpcds-setup/tpcds_utils
  . ~/.bashrc  
  
  # Install the TPC-DS Dependencies
  install_tpcdep.sh
  ```
  
  Note: install_tpcdep.sh will take care of the following
  
  - Download spark-sql-perf
  - Download and install tpcds-kit
  - Download and config apache-jmeter-2.13
  

2. Install `mysql` and make `mysql` to manage the HIVE metastore instead the default `derby` so that multiple connections can be made access the HIVE Database parallelly.
  
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

    c. Confirm `mysql` services are up and runnning. If not restart the service.

  ```
    sudo netstat -tap | grep mysql
    sudo systemctl restart mysql.service
  ```

    d. Create a new user in mysql for Hive.Hive will create a database and store external table definitions in this database.
    
      Check for user name conflits - list all users.
    
      ```mysql
      select user from mysql.user;
      ```
      To list all the database, run the below command.
    
      ```mysql
      show databases;
      ```
   
      login via mysql root(not unix root) to create new user.
 
  ```mysql
  mysql -u root -p
  mysql> CREATE USER 'hive'@'%' IDENTIFIED BY 'hivepassword';
  mysql> GRANT all on *.* to 'hive'@localhost identified by 'hivepassword';
  mysql>  flush privileges;
  ```

    e. Confirm new user created sucessfully.
    
    ```mysql
    mysql -u hive -p 
    ```
    
    f. Add the mysql connector to the `${SPARK_HOME}/conf/spark-env.sh` file
    
    ```
    export SPARK_CLASSPATH=/usr/share/java/mysql-connector-java.jar
    ```

3. Create a file `hive-site.xml` under ${SPARK_HOME}/conf/, if not found. Make similar changes as follows so that spark uses the mysql DB for HIVE metastore information for SQLContext based queries,

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
   
4. Check the ${WORKDIR}/tpcds-setup/tpcds_conf/run.config file before running tpcds benchmark scripts,
   
5. Generate the TPC-DS raw data and create the TPC-DS database as well as the table objects. Use the scripts provided in the utils directory.

  ```
    genData.sh hdfs://localhost[:port]/tpcds-xxx <size_in_gb>
    createDB.sh hdfs://localhost[:port]/tpcds-xxx <size_in_gb> <db_name>
    
    eg:-
    # genData.sh hdfs://n001/tpcds-5GB 5
    # createDB.sh hdfs://n001/tpcds-5GB 5 tpcds5G
  ```
  
    Note: Don't leave any hyphen/special characters for db_name.

6. There are 2 types of tpcds benchmark script provided,
   
    a. To run one sql query at a time and to get the execution time invoke `run_single.sh` script as follows,
    
  ```
  run_single.sh q19 15 30 30g 2048 200 9 tpcds5G
  ```

      Note: Here we run the sql query found under `${WORKDIR}/tpcds_queries/q19_baidu_tuned_2.sql` with other parameters.
   
    b. run throughput test by invoking jmeter inside the script,
    
  ```   
  run_throughput_with_jmeter_nm.sh tpcds5G 200
  ```

      Note: Running this script will invoke all the 9 sql queries found under `${WORKDIR}/tpcds_queries/*.scala` in parallel using `jmeter` for the specified timeout period. 



