#!/bin/bash
#
# Common functions
#
# Rostislav Svoboda 

function show_settings() {
  echo "PROJECT = $PROJECT"
  echo "ALL_IN_PROJECT = $ALL_IN_PROJECT"
  echo "ALL_IN_PROJECT_VERSION = $ALL_IN_PROJECT_VERSION"
  echo "PROJECT_NAME = $PROJECT_NAME"
  echo "MODULE_PREFIX = $MODULE_PREFIX"
  echo ""
  echo "TEST_RESULTS = $TEST_RESULTS"
  echo "JACOCO_EXEC = $JACOCO_EXEC"
  echo ""
  echo "WS = $WS"
  echo "WS_INFRA = $WS_INFRA"
}

function enable_debug() {
  set -x
}

function disable_debug() {
  set +x
}

#
# Generates all_in_one maven project based on 
#  - details defined in env variables (see show_settings function) 
#  - dependencies listed in ${WS_INFRA}/${PROJECT}-dependencies.txt
#
function generate_all_in_one() {

mvn -f ${WS_INFRA}/${PROJECT}-pom.xml dependency:sources > /dev/null ## to have nicer dependencies file
mvn -f ${WS_INFRA}/${PROJECT}-pom.xml dependency:sources > ${WS_INFRA}/${PROJECT}-dependencies.txt


rm -rf ${WS}/${ALL_IN_PROJECT} && mkdir ${WS}/${ALL_IN_PROJECT}
rm -rf \$\{project.basedir\}/target/dependency-maven-plugin-markers/

cat <<EOF > ${WS}/${ALL_IN_PROJECT}/pom.xml
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/maven-v4_0_0.xsd">
        <modelVersion>4.0.0</modelVersion>

        <name>${PROJECT_NAME} - All-In-One</name>
        <groupId>org.experiments.rsvoboda</groupId>
        <artifactId>${ALL_IN_PROJECT}</artifactId>
        <version>${ALL_IN_PROJECT_VERSION}</version>
        <packaging>pom</packaging>

        <modules>
EOF

for GAV in `grep ".*:.*:.*:.*:.*:.*" ${WS_INFRA}/${PROJECT}-dependencies.txt| sed "s/\[INFO\]    //g" | grep ':jar:' | cut -d: -f1-2,5`; do
  MODULE=`echo "${MODULE_PREFIX}$GAV" | tr ":" "-"`
  mvn org.apache.maven.plugins:maven-dependency-plugin:2.8:unpack -Dartifact=$GAV:jar:sources -DoutputDirectory=${WS}/${ALL_IN_PROJECT}/$MODULE/src/main/java
  if [ $? -gt 0 ]
  then
    mvn dependency:copy -Dartifact=$GAV:jar -DoutputDirectory=${WS_INFRA}
    java -jar ${WS}/cfr.jar ${WS_INFRA}/`echo $GAV | cut -d: -f2- | tr ":" "-"`.jar \
       --outputdir ${WS}/${ALL_IN_PROJECT}/$MODULE/src/main/java
  fi
  mvn org.apache.maven.plugins:maven-dependency-plugin:2.8:unpack -Dartifact=$GAV:jar -DoutputDirectory=${WS}/${ALL_IN_PROJECT}/$MODULE/target/classes/
  cat <<EOF >> ${WS}/${ALL_IN_PROJECT}/pom.xml
                <module>$MODULE</module>
EOF

  cat <<EOF > ${WS}/${ALL_IN_PROJECT}/$MODULE/pom.xml
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/maven-v4_0_0.xsd">
        <modelVersion>4.0.0</modelVersion>
        <parent>
                <groupId>org.experiments.rsvoboda</groupId>
                <artifactId>${ALL_IN_PROJECT}</artifactId>
                <version>${ALL_IN_PROJECT_VERSION}</version>
        </parent>
        <artifactId>$MODULE</artifactId>
</project>
EOF
done

## Generate test mocks
MODULE="${MODULE_PREFIX}testsuite"
mkdir -p ${WS}/${ALL_IN_PROJECT}/$MODULE/src/test/java/

for i in `ls ${TEST_RESULTS} | grep "TEST-"`; do
  TEST_PATH=`basename $i | tr "." "/" | sed "s/\/xml/\.java/g" | sed "s,TEST-,${WS}/${ALL_IN_PROJECT}/$MODULE/src/test/java/,g"`
  FQCN=`basename $i | sed "s/.xml//g" | sed "s,TEST-,,g"`
  TEST_NAME=`echo "$FQCN" | rev | cut -d. -f1 | rev`
  PACKAGE_NAME=`echo "$FQCN" | rev | cut -d. -f2- | rev`

  mkdir -p `dirname $TEST_PATH`
  echo "package $PACKAGE_NAME;"           > $TEST_PATH
  echo "public final class $TEST_NAME {}" >> $TEST_PATH

done
cat <<EOF > ${WS}/${ALL_IN_PROJECT}/$MODULE/pom.xml
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/maven-v4_0_0.xsd">
        <modelVersion>4.0.0</modelVersion>
        <parent>
                <groupId>org.experiments.rsvoboda</groupId>
                <artifactId>${ALL_IN_PROJECT}</artifactId>
                <version>${ALL_IN_PROJECT_VERSION}</version>
        </parent>
        <artifactId>$MODULE</artifactId>
</project>
EOF

cat <<EOF >> ${WS}/${ALL_IN_PROJECT}/pom.xml
                <module>$MODULE</module>
        </modules>
</project>
EOF

rm -rf \$\{project.basedir\}/target/dependency-maven-plugin-markers/
}

