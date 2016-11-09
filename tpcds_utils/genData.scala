import com.databricks.spark.sql.perf.tpcds.Tables

val HDFS_PATH = "hdfs://n001/TPCDS-1TB-test"

val SIZE_IN_MB = 1024

val KIT_PATH = "/home/baidu/tpcds-kit/tools"

// For spark 2.0, uncomment the following line.
// val sqlContext = new org.apache.spark.sql.SQLContext(sc)
val tables = new Tables(sqlContext, KIT_PATH, SIZE_IN_MB)

tables.genData(HDFS_PATH, "parquet", true, true, true, true, true)

System.exit(0)

