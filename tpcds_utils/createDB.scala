import com.databricks.spark.sql.perf.tpcds.Tables

val HDFS_PATH = "hdfs://n001/TPCDS-1TB-test"

val SIZE_IN_MB = 1024

val DBNAME = "tpcds10tb"

val tables = new Tables(sqlContext, "/home/baidu/tpcds-kit/tools", SIZE_IN_MB)

sqlContext.sql(s"DROP DATABASE IF EXISTS $DBNAME CASCADE")

tables.createExternalTables(HDFS_PATH, "parquet", DBNAME, true)

System.exit(0)
