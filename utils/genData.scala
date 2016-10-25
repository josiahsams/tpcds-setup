import com.databricks.spark.sql.perf.tpcds.Tables

val HDFS_PATH = "hdfs://n001/TPCDS-1TB-test"

val SIZE_IN_MB = 1024

val tables = new Tables(sqlContext, "/home/baidu/tpcds-kit/tools", SIZE_IN_MB)

tables.genData(HDFS_PATH, "parquet", true, true, true, true, true)

System.exit(0)

