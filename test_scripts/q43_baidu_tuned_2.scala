import com.databricks.spark.sql.perf.Throughput

sqlContext.sql(s"USE tpcds10tb")

val throughput = new Throughput()

throughput.run("q43_baidu_tuned_2", 7200)

System.exit(0)

