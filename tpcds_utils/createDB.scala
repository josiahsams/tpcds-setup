import com.databricks.spark.sql.perf.tpcds.Tables

val HDFS_PATH = "hdfs://n001/TPCDS-1TB-test"

val SIZE_IN_MB = 1024

val DBNAME = "tpcds10tb"

val KIT_PATH = "/home/baidu/tpcds-kit/tools"

// For spark 2.0, uncomment the following line.
// val sqlContext = new org.apache.spark.sql.SQLContext(sc)

val tables = new Tables(sqlContext, KIT_PATH, SIZE_IN_MB)

sqlContext.sql(s"DROP DATABASE IF EXISTS $DBNAME CASCADE")

tables.createExternalTables(HDFS_PATH, "parquet", DBNAME, true)

System.exit(0)
