import com.databricks.spark.sql.perf.tpcds.Tables

val HDFS_PATH = "hdfs://n001/TPCDS-1TB-test"

val SIZE_IN_GB = 1024

val DBNAME = "tpcds10tb"

val KIT_PATH = "/home/baidu/tpcds-kit/tools"

// For spark >= 2.0, comment the following 2 lines.
// import org.apache.spark.sql.hive.HiveContext
// val sqlContext = new HiveContext(sc)

// For spark 1.6, comment the following line.
val sqlContext = new org.apache.spark.sql.SQLContext(sc)

val tables = new Tables(sqlContext, KIT_PATH, SIZE_IN_GB)

sqlContext.sql(s"DROP DATABASE IF EXISTS $DBNAME CASCADE")

tables.createExternalTables(HDFS_PATH, "parquet", DBNAME, true)

System.exit(0)
