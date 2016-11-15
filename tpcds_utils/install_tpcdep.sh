#!/bin/bash

${WORKDIR?"Need to set WORKDIR env"} 2>/dev/null
type AN >/dev/null 2>&1 || { echo >&2 "Require AN script to be in path. Aborting."; exit 1; }
type DN >/dev/null 2>&1 || { echo >&2 "Require DN script to be in path. Aborting."; exit 1; }
type CP >/dev/null 2>&1 || { echo >&2 "Require CP script to be in path. Aborting."; exit 1; }

REPO_DIR=${WORKDIR}/tpcds-setup
DEPSDIR=${REPO_DIR}/tpcdeps
UTILS_DIR=${REPO_DIR}/tpcds_utils/

mkdir -p ${DEPSDIR}

DEPSLOGS=${DEPSDIR}/install_tpcdep.log.$$
echo "Logs will be placed under ${DEPSLOGS} "

echo -n "Setting up spark-sql-perf ... "
cd ${DEPSDIR}
if [ ! -d ${DEPSDIR}/spark-sql-perf ]; then
   git clone https://github.com/josiahsams/spark-sql-perf-spark2.0.0 spark-sql-perf
   cd ./spark-sql-perf
#  Not required for this git repo
#  git checkout -b v0.3.2 v0.3.2
fi

# As the install steps involve accessing multiple Secure Sites, lets ensure the CA certificates are in place.
AN "sudo update-ca-certificates -f >/dev/null 2>&1"

SQLPERF_JAR=${DEPSDIR}/spark-sql-perf/target/scala-2.10/spark-sql-perf*.jar
if ! ls ${SQLPERF_JAR} 1> /dev/null 2>&1; then
   cd ${DEPSDIR}/spark-sql-perf
   export DBC_USERNAME=`whoami`
   ./build/sbt clean package >> ${DEPSLOGS}  2>&1
   if [[ $? -ne 0 ]]; then
   	echo "spark-sql-perf compilation failed"
   	exit
   fi
fi
echo "done"

echo "Check for compiler and its dependencies"
if [ ! -f /usr/bin/python ]; then
	if [ -f /usr/bin/apt-get ]; then
		# install python in ubuntu
		sudo apt-get -y install python-minimal
	else
		# install python in RHEL
		sudo yum -y install python2
	fi
fi

python -mplatform  |grep -i redhat >/dev/null 2>&1
if [ $? -ne 0 ]; then
	# Ubuntu
	dpkg -l | grep gcc  >/dev/null 2>&1
	if [ $? -ne 0 ]; then
		sudo apt-get -y install gcc
	fi
	dpkg -l | grep make  >/dev/null 2>&1
	if [ $? -ne 0 ]; then
		sudo apt-get -y install make
	fi
	dpkg -l | grep bison  >/dev/null 2>&1
	if [ $? -ne 0 ]; then
		sudo apt-get -y install bison
	fi
	dpkg -l | grep flex  >/dev/null 2>&1
	if [ $? -ne 0 ]; then
		sudo apt-get -y install flex
	fi
else
	# RHEL
	rpm -qa |grep gcc >/dev/null 2>&1
  	if [ $? -ne 0 ]; then
		sudo yum -y install gcc
	fi
	rpm -qa |grep make >/dev/null 2>&1
  	if [ $? -ne 0 ]; then
		sudo yum -y install make
	fi
	rpm -qa |grep flex >/dev/null 2>&1
  	if [ $? -ne 0 ]; then
		sudo yum -y install flex
	fi
	rpm -qa |grep bison >/dev/null 2>&1
  	if [ $? -ne 0 ]; then
		sudo yum -y install bison
	fi
fi

echo -n "Setting up tpcds-kit ... "
cd ${DEPSDIR}
KIT_PATH=${DEPSDIR}/tpcds-kit/tools
if [ ! -d ${KIT_PATH} ]; then
   git clone https://github.com/davies/tpcds-kit.git
   cd ./tpcds-kit/tools
   cp Makefile.suite Makefile
   make >> ${DEPSLOGS} 2>&1
   if [[ $? -ne 0 ]]; then
        echo "tpcds-kit compilation failed"
        exit
   fi
fi
echo "done"

echo "Copy tpcds-kit to all the slave nodes"
cd ${DEPSDIR}
tar cf tpcds-kit.tar ./tpcds-kit
DN "mkdir -p ${DEPSDIR}"
CP ${DEPSDIR}/tpcds-kit.tar ${DEPSDIR}/tpcds-kit.tar
DN "tar xf ${DEPSDIR}/tpcds-kit.tar -C ${DEPSDIR} "
AN "chmod -R a+rx ${DEPSDIR}/tpcds-kit"


echo "Setting up Jmeter"
cd ${DEPSDIR}
JMETER_BIN=${DEPSDIR}/apache-jmeter-2.13/bin/jmeter
if [ ! -f ${JMETER_BIN} ]; then
    wget https://archive.apache.org/dist/jmeter/binaries/apache-jmeter-2.13.tgz
    tar zxf apache-jmeter-2.13.tgz
    # install jmeter-ssh-sampler. Refer https://code.google.com/archive/p/jmeter-ssh-sampler/downloads
    cp ${UTILS_DIR}/jmeter-ssh-sampler-0.1.0.jar ${DEPSDIR}/apache-jmeter-2.13/lib/ext
    # Refer http://www.jcraft.com/jsch/index.html
    cp ${UTILS_DIR}/jsch-0.1.54.jar ${DEPSDIR}/apache-jmeter-2.13/lib

    sed -i '/^#jmeterengine.force.system.exit/s/^#jmeterengine.force.system.exit.*/jmeterengine.force.system.exit=true/g' ${DEPSDIR}/apache-jmeter-2.13/bin/jmeter.properties
fi

# Check mysql is already installed
echo "Setting up mysql"

python -mplatform  |grep -i redhat >/dev/null 2>&1

# Ubuntu
if [ $? -ne 0 ]; then

  dpkg -l | grep mysql >/dev/null 2>&1

  if [ $? -ne 0 ]; then
    sudo apt-key update
    sudo apt-get -y update
    sudo apt-get -y dist-upgrade

    dpkg -S /usr/bin/mysq
    if [ $? -ne 0 ]; then
       sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password password passw0rd'
       sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password passw0rd'
       sudo apt-get -y install mysql-server --force-yes
       sudo apt-get -y install mysql-client --force-yes
    fi
  else
    echo "mysql is already installed"
  fi

  if [ ! -f /usr/share/java/mysql-connector-java.jar ]; then
    sudo apt-get -y install libmysql-java --force-yes
  else
    echo "mysql connector is installed already"
  fi

  sudo netstat -tap | grep mysql >/dev/null 2>&1
  if [ $? -ne 0 ]; then
    sudo systemctl restart mysql.service
    sudo netstat -tap | grep mysql
    if [ $? -ne 0 ]; then
        echo "Failed to start mysql"
        exit 255
    fi
  fi
else
  # RedHat
  rpm -qa |grep maria >/dev/null 2>&1
  if [ $? -ne 0 ]; then
	sudo yum -y install mariadb mariadb-server mariadb-libs >/dev/null 2>&1
	sudo systemctl start mariadb.service
	sudo systemctl enable mariadb.service

	rpm -qa | grep expect >/dev/null 2>&1
	if [ $? -ne 0 ] ; then
	  sudo yum -y install expect >/dev/null 2>&1
	fi

	MYSQL=passw0rd

	echo "Setting mysql root password to ${MYSQL}"
	SECURE_MYSQL=$(expect -c "
	set timeout 10
	spawn mysql_secure_installation
	expect \"Enter current password for root (enter for none):\"
	send \"\r\"
	expect \"Set root password?\"
	send \"y\r\"
	expect \"New password:\"
	send \"$MYSQL\r\"
	expect \"Re-enter new password:\"
	send \"$MYSQL\r\"
	expect \"Remove anonymous users?\"
	send \"y\r\"
	expect \"Disallow root login remotely?\"
	send \"y\r\"
	expect \"Remove test database and access to it?\"
	send \"y\r\"
	expect \"Reload privilege tables now?\"
	send \"y\r\"
	expect eof
	")

	echo "$SECURE_MYSQL"
  else
    echo "mysql is already installed"
  fi

  if [ ! -f /usr/share/java/mysql-connector-java.jar ]; then
    sudo sudo yum -y install mysql-connector-java
  else
    echo "mysql connector is installed already"
 fi
fi

# Check for hive user
mysql -u root -ppassw0rd -e 'select user from mysql.user where user="hive" and host="localhost";' 2>&1 | grep -w hive >/dev/null
if [ $? -ne 0 ]; then
    mysql -u root -ppassw0rd -e "CREATE USER 'hive'@'%' IDENTIFIED BY 'hivepassword';GRANT all on *.* to 'hive'@localhost identified by 'hivepassword';flush privileges;"
    if [ $? -ne 0 ]; then
        echo "Failed to create hive user"
        exit 255
    fi
    echo "User hive added to mysql"
else
    mysql -u hive -phivepassword -e "show databases;" >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "Note: Error accessing hive user with the password: hivepassword;"
        echo "      Ensure that the ConnectionUserName/ConnectionPassword in hive-site.xml"
        echo "      in Spark conf directory matches with the mysql's hive user"
    fi
    echo "Existing user hive in mysql is sufficient."
fi

# Place hive-site.xml into ${SPARK_HOME}/conf/

if [ ! -f ${SPARK_HOME}/conf/hive-site.xml ]; then
    cp ${UTILS_DIR}/hive-site.xml.template ${SPARK_HOME}/conf/hive-site.xml
    if [ $? -eq 0 ]; then
       echo "Sucessfully placed ${SPARK_HOME}/conf/hive-site.xml"
    fi
else
    echo "${SPARK_HOME}/conf/hive-site.xml exist already."
    echo "Note: Check it out javax.jdo.option.ConnectionUserName"
    echo "      and javax.jdo.option.ConnectionPassword attributes"
    echo "      it should match with the mysql's hive user"
fi

echo "Adding mysql connector to Spark Classpath"
grep spark.executor.extraClassPath ${SPARK_HOME}/conf/spark-defaults.conf | grep -v "^#" | grep mysql-connector-java.jar >/dev/null 2>&1
if [ $? -ne 0 ]; then
	grep spark.executor.extraClassPath ${SPARK_HOME}/conf/spark-defaults.conf | grep -v "^#" >/dev/null 2>&1
	if [ $? -ne 0 ]; then
	# Fresh entry
		echo "spark.executor.extraClassPath /usr/share/java/mysql-connector-java.jar" >> ${SPARK_HOME}/conf/spark-defaults.conf
	else
	# append to the existing CLASSPATH
		sed -i '/^spark.executor.extraClassPath/ s~$~:/usr/share/java/mysql-connector-java.jar~' ${SPARK_HOME}/conf/spark-defaults.conf
	fi
	echo "Added mysql-connector-java.jar to spark classpath"
fi

grep spark.driver.extraClassPath ${SPARK_HOME}/conf/spark-defaults.conf | grep -v "^#" | grep mysql-connector-java.jar >/dev/null 2>&1
if [ $? -ne 0 ]; then
	grep spark.driver.extraClassPath ${SPARK_HOME}/conf/spark-defaults.conf | grep -v "^#" >/dev/null 2>&1
	if [ $? -ne 0 ]; then
	# Fresh entry
		echo "spark.driver.extraClassPath /usr/share/java/mysql-connector-java.jar" >> ${SPARK_HOME}/conf/spark-defaults.conf
	else
	# append to the existing CLASSPATH
		sed -i '/^spark.driver.extraClassPath/ s~$~:/usr/share/java/mysql-connector-java.jar~' ${SPARK_HOME}/conf/spark-defaults.conf
	fi
	echo "Added mysql-connector-java.jar to spark classpath"
fi

exit 0
