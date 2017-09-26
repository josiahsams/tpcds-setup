#!/bin/bash

CURDIR=`pwd`            # Inside tpcds_setup/utils
WORKDIR=${HOME}         

create_sql_list()
{
echo "use $1;" > $3
for table in `echo $2| tr "," " "`
do
	echo "select '$table',count(*) from $table;" >> $3
done
}

rm_temp_files()
{
	rm ${WORKDIR}/part_query_list &>>/dev/null
	rm ${WORKDIR}/npart_query_list &>>/dev/null
	exit
}

if [ $# -ne 2 ]
then
	echo "USAGE - ./get_tpcds_count.sh dbsize dbname"
	echo "e.g. - ./get_tpcds_count.sh 1tb tpcds1tb"
	exit
fi

dbsize=$1
dbname=$2

part_table_list="catalog_sales,catalog_returns,inventory,store_sales,store_returns,web_sales,web_returns"
npart_table_list="call_center,catalog_page,customer,customer_address,customer_demographics,date_dim,household_demographics,income_band,item,promotion,reason,ship_mode,store,time_dim,warehouse,web_page,web_site"

echo "collecting record counts for partitioned tables"
create_sql_list $dbname $part_table_list ${WORKDIR}/part_query_list
echo "-----------------------------------" > ${WORKDIR}/record_counts
echo "Record count for partitioned tables" >> ${WORKDIR}/record_counts
echo "-----------------------------------" >> ${WORKDIR}/record_counts
$SPARK_HOME/bin/spark-sql -f ${WORKDIR}/part_query_list >> ${WORKDIR}/record_counts

## to check if passed database exist or not
if [[ $? -ne 0 ]]
then
	echo "TPCDS database - $dbname does not exist, please check the DB name"
	rm_temp_files
fi

echo "collecting record counts for non-partitioned tables"
create_sql_list $dbname $npart_table_list ${WORKDIR}/npart_query_list
echo "-----------------------------------" >> ${WORKDIR}/record_counts
echo "Record count for non-partitioned tables" >> ${WORKDIR}/record_counts
echo "-----------------------------------" >> ${WORKDIR}/record_counts
$SPARK_HOME/bin/spark-sql -f ${WORKDIR}/npart_query_list >> ${WORKDIR}/record_counts
echo -e
cat ${WORKDIR}/record_counts
echo -e
## to highlight mismatach count
echo "Comparing actual record count with standard expected counts for $dbname"
echo -e
grep -i ^$dbsize ${CURDIR}/tpcds_std_rec &>>/dev/null
if [ $? -ne 0 ]
then
	echo "Standard record count values for $dbsize are not stored for comparison"
    rm_temp_files
fi

table_list="$part_table_list,$npart_table_list"
flag=0
for i in `echo $table_list | tr "," " "`
do
    std_value=`grep -i ^$dbsize ${CURDIR}/tpcds_std_rec | grep -w $i | awk '{print $3}'`
    act_value=`grep -w $i ${WORKDIR}/record_counts | awk '{print $2}'`
    if [ $std_value != $act_value ]
    then
		echo "Count for $i is $act_value which not as expected. It should be equal to $std_value"
        flag=1
    fi

done

if [ $flag -eq 0 ]
then
	echo "Record counts for $dbname is as expected"
fi

echo -e
echo "You can check file \"${WORKDIR}/record_counts\" for record counts for $dbname."
rm_temp_files
