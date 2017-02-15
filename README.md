# tpcds-setup

###Requirements:

1. Spark 1.6.1 should be installed and SPARK_HOME should be set in the environment variable.
2. HADOOP YARN Setup should be completed and HADOOP_HOME should be set in the environment variable.
3. Make sure the nodes are set for password-less SSH both ways(master->slaves & slaves->master).
4. Since we use the environment variables a lot in our scripts, make sure to comment out the portion following this statement in your ~/.bashrc ,
  `If not running interactively, don't do anything`
5. Kindly refer to the setups & scripts provided in https://github.com/kmadhugit/hadoop-cluster-utils before proceeding further as the utility scripts provided in the repository are needed here.
6. In order to make the scripts run w/o prompting for password, make sure you run `sudo visudo` and edit the line as follows ,

```
%sudo   ALL=(ALL:ALL) NOPASSWD:ALL
```
	
###Steps to run TPC-DS Benchmark:

1. Clone this repository and follow the steps before proceeding.
    Note: `WORKDIR` is where you will be running the scripts and all the log files and configuration files will be placed. All the provided scripts expect WORKDIR to be made part of ~/.bashrc. 

  ```bash
  git clone https://github.com/josiahsams/tpcds-setup
  
  cd tpcds-setup
  
  # Install the TPC-DS Dependencies
  ./setup.sh
  source ~/.bashrc  
  ```
  
  Note: install_tpcdep.sh will take care of the following
  
  - Download spark-sql-perf
  - Download and install tpcds-kit
  - Download and config apache-jmeter-2.13
  - Download, install and config mysql
  - Config spark hivecontext to use mysql as DB to store metastore
  
2. Check the following variables in `${WORKDIR}/tpcds-setup/conf/run.config` file before running tpcds benchmark scripts,

```
# Runtime config paramters
DRIVER_MEM=30g
DRIVER_CORES=10
NUM_EXECUTORS=27
EXEC_CORES=15
EXEC_MEM=20g

EXEC_MEM_OVERHEAD=1536
SHUFFLE_PARTITIONS=64
GC_THREADS=9
```
   Note: 
   - The above configuration is used in 4 node cluster(1 Master + 3 Slaves) with 200GB+160Cores from each slave nodes.
   - Make sure you don't allocate more than 30G per executor and size of the other parameters accordingly.
   
3. Generate the TPC-DS raw data and create the TPC-DS database as well as the table objects. Use the scripts provided in the utils directory.

  ```
    genData.sh hdfs://localhost[:port]/tpcds-xxx <size_in_gb>
    createDB.sh hdfs://localhost[:port]/tpcds-xxx <size_in_gb> <db_name>
    
    eg:-
    
    # genData.sh hdfs://n001:9000/tpcds-5GB 5
    # createDB.sh hdfs://n001:9000/tpcds-5GB 5 tpcds5G
  ```
  
    Note: Don't leave any hyphen/special characters for db_name.

6. There are 2 types of tpcds benchmark script provided,
   
    a. To run individual sql queries and to get the execution time invoke `run_single.sh` script as follows,
    
  ``` 
  run_single.sh q1,q19 2 8 18 23g tpcds1g1
  (or)
  run_single.sh queries.run 2 8 18 23g tpcds1g1
  
  cat queries.run
  q19
  q73
  q93
  ```

      Note: 
      - Multiple queries can be provided in a comma separated format or in a file. 
      - Queries can be made to run in an iterative mode
   
    b. run throughput test by invoking jmeter inside the script,
    
    Before running it, make sure to set `HOST`, `USER`  & `PASSWD` so that jmeter uses it to spawn multiple workloads.
    
  ```   
  run_throughput.sh 1 15 18g tpcds100g 200
  ```

      Note: 
      - Running this script will invoke all the 9 sql queries found under `${WORKDIR}/queries/*.scala` in parallel using `jmeter` for the specified timeout period. 
      - input parameters like cores, memory & executor instances are applied to individual threads and not for the whole application.

    c. To collect performance data along with TPC runs, kindly go through the initial setup after cloning this repo: https://github.com/josiahsams/perftools-setup and then execute the above scripts with additional options as follows,
    
    ```
    # To collect nmon data with a run
    run_single.sh q1 2 8 18 23g tpcds1g1 -n
    
    # To collect operf data with a run
    run_single.sh q1,q19 2 8 18 23g tpcds1g1 -o
    
    # To collect PID monitor data for a run
    pmon run_single.sh q1,q19 2 8 18 23g tpcds1g1
    ```


