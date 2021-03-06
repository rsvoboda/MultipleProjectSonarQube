# MultipleProjectSonarQube
Running SonarQube on Multiple Project (Not Multiple Module)
SonarQube download page is https://www.sonarqube.org/downloads/
Project code is on GitHub https://github.com/SonarSource/sonarqube/
All versions are accessible on https://sonarsource.bintray.com/Distribution/sonarqube/

## Table of Contents

  * [Experiment plan](#experiment-plan)
  * [Step 1 Analysis on WildFly sources](#step-1-analysis-on-wildfly-sources)
  * SonarQube analysis on jbossws-* dependencies of jbossws-cxf-client
      * [Step 2a) jbossws-* dependencies of jbossws-cxf-client in separate projects](#step-2a-jbossws--dependencies-of-jbossws-cxf-client-in-separate-projects)
      * [Step 2b) jbossws-* dependencies for jbossws-cxf-client in one big project](#step-2b-jbossws--dependencies-for-jbossws-cxf-client-in-one-big-project)
  * SonarQube analysis (one big project) on all the dependencies of jbossws-cxf-client
      * [Step 3a) jbossws-cxf-client   dependencies using SonarQube Scanner for Maven](#step-3a-jbossws-cxf-client--dependencies-using-sonarqube-scanner-for-maven)
      * [Step 3b) jbossws-cxf-client   dependencies using SonarQube Runner](#step-3b-jbossws-cxf-client--dependencies-using-sonarqube-runner)
      * [Step 3c) jbossws-cxf-client   dependencies using SonarQube Scanner CLI](#step-3c-jbossws-cxf-client--dependencies-using-sonarqube-scanner-cli)
      * [Step 3d) jbossws-cxf-client   dependencies using SonarLint](#step-3d-jbossws-cxf-client--dependencies-using-sonarlint)
  * [Step 4) WildFly and all dependencies in one big project](#step-4-wildfly-and-all-dependencies-in-one-big-project)
  * [Step 5) SonarQube and PostgreSQL in Docker](#step-5-sonarqube-and-postgresql-in-docker)
  * [Step 6) JaCoCo code coverage details for project](#step-6-jacoco-code-coverage-details-for-project)
  * [Step 7) Several JaCoCo code coverage files   one big project](#step-7-several-jacoco-code-coverage-files--one-big-project)
      * [Merge several JaCoCo .exec files](#merge-several-jacoco-exec-files)
      * [Several JaCoCo code coverage files and jbossws-cxf](#several-jacoco-code-coverage-files-and-jbossws-cxf)
      * [Pushing JaCoCo code coverage details to older or LTS SonarQube server](#pushing-jacoco-code-coverage-details-to-older-or-lts-sonarqube-server)
  * [Step 8) SonarQube   get maven dependencies   decompile jars](#step-8-sonarqube--get-maven-dependencies--decompile-jars)
  * [Step 9) SonarQube analysis of tests](#step-9-sonarqube-analysis-of-tests)
      * [Tests results inside current project](#tests-results-inside-current-project)
      * [External tests results](#external-tests-results)
      * [Analyze only tests](#analyze-only-tests)
  * [Step 10) jbossws-cxf-client all-in-one project with code coverage and test results](#step-10-jbossws-cxf-client-all-in-one-project-with-code-coverage-and-test-results)
  * [Step 11) jbossws-cxf server side all-in-one with code coverage and test results](#step-11-jbossws-cxf-server-side-all-in-one-with-code-coverage-and-test-results)
  * [Step 12) WildFly all-in-one with code coverage and test results](#step-12-wildfly-all-in-one-with-code-coverage-and-test-results)
  * [Step 13) Failsafe plugin, TestNG](#step-13-failsafe-plugin-testng)
  * [Step 14) Project Configuration Parameters](#step-14-project-configuration-parameters)
  * [Step 15) SonarQube and https](#step-15-sonarqube-and-https)

Created with [gh-md-toc](https://github.com/ekalinin/github-markdown-toc) help.

## Experiment plan
1) run SonarQube analysis on source from big project like https://github.com/wildfly/wildfly
2) run SonarQube analysis on jbossws-* dependencies of jbossws-cxf-client
   - as separate SonarQube projects
   - as one big SonarQube project
3) run SonarQube analysis (one big SonarQube project) on all the dependencies of jbossws-cxf-client
   - using SonarQube Scanner for Maven
   - using SonarQube Runner
   - using SonarQube Scanner CLI
   - using SonarLint
4) run SonarQube analysis (one big SonarQube project) on all the dependencies of WildFly
5) SonarQube and PostgreSQL in Docker for quick production-like setup in different environments
6) SonarQube + JaCoCo code coverage details for one project
7) SonarQube + several JaCoCo code coverage files + one big SonarQube project
8) SonarQube + get maven dependencies + decompile jars (some artifacts do not have sources available - e.g. asm)
9) SonarQube analysis of tests

## Step 1 Analysis on WildFly sources
```bash
rm -rf workspace && mkdir workspace

git clone https://github.com/wildfly/wildfly.git workspace/wildfly
mvn -f workspace/wildfly/pom.xml clean install -DskipTests -Denforcer.skip=true -Dcheckstyle.skip=true


wget -O workspace/sonarqube-6.3.1.zip https://sonarsource.bintray.com/Distribution/sonarqube/sonarqube-6.3.1.zip
unzip -q -d workspace/ workspace/sonarqube-6.3.1.zip

workspace/sonarqube-6.3.1/bin/linux-x86-64/sonar.sh start
sleep 10

mvn -f workspace/wildfly/pom.xml org.sonarsource.scanner.maven:sonar-maven-plugin:3.2:sonar -Dsonar.host.url=http://localhost:9000/

firefox http://localhost:9000/

```

## Step 2a) jbossws-* dependencies of jbossws-cxf-client in separate projects
```bash
rm -rf workspace && mkdir workspace

wget -O workspace/sonarqube-6.3.1.zip https://sonarsource.bintray.com/Distribution/sonarqube/sonarqube-6.3.1.zip
unzip -q -d workspace/ workspace/sonarqube-6.3.1.zip

workspace/sonarqube-6.3.1/bin/linux-x86-64/sonar.sh start
sleep 10

mkdir workspace/jbossws-cxf-client
cat <<EOF > workspace/jbossws-cxf-client/cxf-client-pom.xml
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/maven-v4_0_0.xsd">
  <modelVersion>4.0.0</modelVersion>

  <name>JBoss Web Services - Client test</name>

  <groupId>org.jboss.ws.cxf</groupId>
  <artifactId>jbossws-cxf-client-test</artifactId>
  <version>1.0.0.Final</version>

  <properties>
      <jbossws-cxf-client-version>5.1.8.Final</jbossws-cxf-client-version>
  </properties>

  <dependencies>
    <dependency>
      <groupId>org.jboss.ws.cxf</groupId>
      <artifactId>jbossws-cxf-client</artifactId>
      <version>\${jbossws-cxf-client-version}</version>
    </dependency>
  </dependencies>

</project>
EOF
mvn -f workspace/jbossws-cxf-client/cxf-client-pom.xml dependency:sources > workspace/jbossws-cxf-client/dependencies.txt

wsprojects=(jbossws-api jbossws-spi jbossws-common jbossws-common-tools jbossws-cxf-client)
rm -rf workspace/jbossws-cxf-client/jbossws-projects && mkdir workspace/jbossws-cxf-client/jbossws-projects
for PP in ${wsprojects[@]}; do
  VERSION=`grep ":jbossws" workspace/jbossws-cxf-client/dependencies.txt| sed "s/\[INFO\]    //g" | grep "$PP:" | cut -d: -f 5 `
  PROJECT=`echo "$PP" | sed "s/jbossws-cxf-client/jbossws-cxf/g"`
  echo "https://github.com/jbossws/$PROJECT/tree/$PROJECT-$VERSION" | sed "s/jbossws-cxf-client/jbossws-cxf/g"
  git clone --branch $PROJECT-$VERSION https://github.com/jbossws/$PROJECT.git workspace/jbossws-cxf-client/jbossws-projects/$PROJECT
  mvn -f workspace/jbossws-cxf-client/jbossws-projects/$PROJECT/pom.xml org.sonarsource.scanner.maven:sonar-maven-plugin:3.2:sonar -Dsonar.host.url=http://localhost:9000/
done


firefox http://localhost:9000/
```

## Step 2b) jbossws-* dependencies for jbossws-cxf-client in one big project
Skipped in favor of Step 3a) which is superset of this step.

## Step 3a) jbossws-cxf-client + dependencies using SonarQube Scanner for Maven
```bash
rm -rf workspace && mkdir workspace

wget -O workspace/sonarqube-6.3.1.zip https://sonarsource.bintray.com/Distribution/sonarqube/sonarqube-6.3.1.zip
unzip -q -d workspace/ workspace/sonarqube-6.3.1.zip

workspace/sonarqube-6.3.1/bin/linux-x86-64/sonar.sh start
sleep 10

mkdir workspace/jbossws-cxf-client
cat <<EOF > workspace/jbossws-cxf-client/cxf-client-pom.xml
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/maven-v4_0_0.xsd">
  <modelVersion>4.0.0</modelVersion>

  <name>JBoss Web Services - Client test</name>

  <groupId>org.jboss.ws.cxf</groupId>
  <artifactId>jbossws-cxf-client-test</artifactId>
  <version>1.0.0.Final</version>

  <properties>
      <jbossws-cxf-client-version>5.1.8.Final</jbossws-cxf-client-version>
  </properties>

  <dependencies>
    <dependency>
      <groupId>org.jboss.ws.cxf</groupId>
      <artifactId>jbossws-cxf-client</artifactId>
      <version>\${jbossws-cxf-client-version}</version>
    </dependency>
  </dependencies>

</project>
EOF
mvn -f workspace/jbossws-cxf-client/cxf-client-pom.xml dependency:sources > workspace/jbossws-cxf-client/dependencies.txt

rm -rf workspace/jbossws-cxf-client/jbossws-all-in-one && mkdir workspace/jbossws-cxf-client/jbossws-all-in-one

cat <<EOF > workspace/jbossws-cxf-client/jbossws-all-in-one/pom.xml
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/maven-v4_0_0.xsd">
        <modelVersion>4.0.0</modelVersion>

        <name>JBoss Web Services CXF Client - All-In-One</name>
        <groupId>org.experiments.rsvoboda</groupId>
        <artifactId>jbossws-all-in-one</artifactId>
        <version>1.0.0</version>
        <packaging>pom</packaging>

        <modules>
EOF

for GAV in `grep ".*:.*:.*:.*:.*:.*" workspace/jbossws-cxf-client/dependencies.txt| sed "s/\[INFO\]    //g" | grep -v system | cut -d: -f1-2,5`; do
  MODULE=`echo $GAV | tr ":" "-"`
  mvn org.apache.maven.plugins:maven-dependency-plugin:2.8:unpack -Dartifact=$GAV:jar:sources -DoutputDirectory=workspace/jbossws-cxf-client/jbossws-all-in-one/$MODULE/src/main/java || true
  cat <<EOF >> workspace/jbossws-cxf-client/jbossws-all-in-one/pom.xml
                <module>$MODULE</module>
EOF

  cat <<EOF > workspace/jbossws-cxf-client/jbossws-all-in-one/$MODULE/pom.xml
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/maven-v4_0_0.xsd">
        <modelVersion>4.0.0</modelVersion>

        <parent>
                <groupId>org.experiments.rsvoboda</groupId>
                <artifactId>jbossws-all-in-one</artifactId>
                <version>1.0.0</version>
        </parent>

        <artifactId>$MODULE</artifactId>
</project>
EOF

done

cat <<EOF >> workspace/jbossws-cxf-client/jbossws-all-in-one/pom.xml
        </modules>
</project>
EOF

mvn -f workspace/jbossws-cxf-client/jbossws-all-in-one/pom.xml  org.sonarsource.scanner.maven:sonar-maven-plugin:3.2:sonar -Dsonar.host.url=http://localhost:9000/ -Dsonar.exclusions=**/com/google/common/util/concurrent/Monitor.java


firefox http://localhost:9000/
```
Note: exclude because of http://stackoverflow.com/questions/43962471/sonarqube-analysis-of-guava-v18-internalprefixunaryexpression-cannot-be-cast-t
Follow-up: https://jira.sonarsource.com/browse/SONARJAVA-2140 has been fixed in version 4.6 of SonarJava analyzer. Bundled version with SonarQube 6.3.1 is 4.5, upgrading it via http://127.0.0.1:9000/updatecenter/updates to latest version (4.9 at time of writing) helps.

## Step 3b) jbossws-cxf-client + dependencies using SonarQube Runner
According to https://docs.sonarqube.org/display/SONARQUBE45/Installing+and+Configuring+SonarQube+Runner
SonarQube Runner is deprecated, latest release April 2014 targeted for SonarQube version 4.5.x.

## Step 3c) jbossws-cxf-client + dependencies using SonarQube Scanner CLI
```bash
wget -O workspace/sonar-scanner-cli-3.0.3.778-linux.zip https://sonarsource.bintray.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-3.0.3.778-linux.zip
unzip -q -d workspace workspace/sonar-scanner-cli-3.0.3.778-linux.zip && rm workspace/sonar-scanner-cli-3.0.3.778-linux.zip

git clone --branch jbossws-cxf-5.1.8.Final https://github.com/jbossws/jbossws-cxf.git workspace/jbossws-cxf

workspace/sonar-scanner-3.0.3.778-linux/bin/sonar-scanner

cd workspace/jbossws-cxf
../sonar-scanner-3.0.3.778-linux/bin/sonar-scanner -Dsonar.projectKey="my:project" -Dsonar.projectName="My project" -Dsonar.projectVersion="1.0" -Dsonar.sources=. -Dsonar.sourceEncoding="UTF-8"

cd -
```

## Step 3d) jbossws-cxf-client + dependencies using SonarLint
SonarLint is has 2 flavors - an extension to your favorite IDE and Command Line tool. For details see
http://www.sonarlint.org/ and http://www.sonarlint.org/commandline/index.html. SonarLint provides on-the-fly
feedback on new bugs and quality issues injected into the code, no server instance is needed.

```bash
wget -O workspace/sonarlint-cli-2.1.0.566.zip https://bintray.com/sonarsource/Distribution/download_file?file_path=sonarlint-cli%2Fsonarlint-cli-2.1.0.566.zip
unzip -q -d workspace workspace/sonarlint-cli-2.1.0.566.zip && rm workspace/sonarlint-cli-2.1.0.566.zip

git clone --branch jbossws-cxf-5.1.8.Final https://github.com/jbossws/jbossws-cxf.git workspace/jbossws-cxf

cd workspace/jbossws-cxf
../sonarlint-cli-2.1.0.566/bin/sonarlint
du -h .sonarlint/sonarlint-report.html
links .sonarlint/sonarlint-report.html ## firefox, chrome

cd -
```

## Step 4) WildFly and all dependencies in one big project
This step expects running SonarQube running in configuration with high Heap Space usage.
Run on machine which has 6GB of available memory.
Just upload of data takes 45 minutes on my Lenovo T440s, postprocessing on SonarQube takes 20-30 minutes.

There are some limitations I noticed with this big experiment:
 * High memory usage for Web Server and Compute Engine parts of SonarQube, had to monitor JVM to get the right setting
 * all-in-one module and sub-modules must have unique identifier / GAV otherwise you will get error like this:
    * Module "org.experiments.rsvoboda:commons-lang-commons-lang-2.6" is already part of project "org.experiments.rsvoboda:jbossws-all-in-one"
 * Using Docker way it is not easy to tune JVM for Compute Engine, Web Server can be tuned using SONARQUBE_WEB_JVM_OPTS
    * https://github.com/SonarSource/docker-sonarqube/issues/83
    * You can see `Caused by: org.postgresql.util.PSQLException: Ran out of memory retrieving query results.` in log of background tasks

```bash
wget -O workspace/sonarqube-6.3.1.zip https://sonarsource.bintray.com/Distribution/sonarqube/sonarqube-6.3.1.zip
unzip -q -d workspace/ workspace/sonarqube-6.3.1.zip

echo "" >> workspace/sonarqube-6.3.1/conf/sonar.properties
echo "sonar.web.javaOpts=-Xmx3072m -Xms1024m -XX:+HeapDumpOnOutOfMemoryError" >> workspace/sonarqube-6.3.1/conf/sonar.properties
echo "sonar.ce.javaOpts=-Xmx2048m -Xms512m -XX:+HeapDumpOnOutOfMemoryError" >> workspace/sonarqube-6.3.1/conf/sonar.properties

workspace/sonarqube-6.3.1/bin/linux-x86-64/sonar.sh start
sleep 10

wget -O workspace/cfr_0_121.jar  http://www.benf.org/other/cfr/cfr_0_121.jar

rm -rf workspace/wf && mkdir workspace/wf
git clone https://github.com/wildfly/wildfly.git workspace/wf/wildfly
mvn -f workspace/wf/wildfly/pom.xml -fn clean install -Dmaven.test.failure.ignore=true -Dtest=NONE -DfailIfNoTests=false
WF_VERSION=`mvn -f workspace/wf/wildfly/pom.xml help:evaluate -Dexpression=project.version | grep -v "^\["`
WF_CORE_VERSION=`mvn -f workspace/wf/wildfly/pom.xml help:evaluate -Dexpression=version.org.wildfly.core | grep -v "^\["`
echo "${WF_VERSION} - ${WF_CORE_VERSION}"

cat <<EOF > workspace/wf/wf-all-pom.xml
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/maven-v4_0_0.xsd">
  <modelVersion>4.0.0</modelVersion>

  <groupId>org.wildfly</groupId>
  <artifactId>wildfly-all-deps</artifactId>
  <version>1.0.0.Final</version>

  <properties>
      <wildfly-version>${WF_VERSION}</wildfly-version>
      <wildfly-core-version>${WF_CORE_VERSION}</wildfly-core-version>
  </properties>

  <dependencies>
    <dependency>
      <groupId>org.wildfly</groupId>
      <artifactId>wildfly-feature-pack</artifactId>
      <version>\${wildfly-version}</version>
      <type>pom</type>
    </dependency>
    <dependency>
      <groupId>org.wildfly.core</groupId>
      <artifactId>wildfly-core-feature-pack</artifactId>
      <version>\${wildfly-core-version}</version>
      <type>pom</type>
    </dependency>
  </dependencies>

</project>
EOF
mvn -f workspace/wf/wf-all-pom.xml dependency:sources > /dev/null ## to get all deps and have nicer dependencies.txt
mvn -f workspace/wf/wf-all-pom.xml dependency:sources > workspace/wf/dependencies.txt

rm -rf workspace/wf/wf-all-in-one && mkdir workspace/wf/wf-all-in-one
rm -rf \$\{project.basedir\}/  ##  The dependency plugin uses the existence of some marker files to detect if a given artifact has been unpacked. By default these markers are stored in /target/dependency.

cat <<EOF > workspace/wf/wf-all-in-one/pom.xml
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/maven-v4_0_0.xsd">
        <modelVersion>4.0.0</modelVersion>

        <name>WildFly - All In One</name>
        <groupId>org.experiments.rsvoboda</groupId>
        <artifactId>wf-all-deps</artifactId>
        <version>1.0.0</version>
        <packaging>pom</packaging>

        <modules>
EOF

for GAV in `grep ".*:.*:.*:.*:.*:.*" workspace/wf/dependencies.txt| sed "s/\[INFO\]    //g" | grep ':jar:' | cut -d: -f1-2,5`; do
  MODULE=`echo $GAV | tr ":" "-"`
  mvn org.apache.maven.plugins:maven-dependency-plugin:2.8:unpack -Dartifact=$GAV:jar:sources -DoutputDirectory=workspace/wf/wf-all-in-one/$MODULE/src/main/java

  if [ $? -gt 0 ]
  then
    mvn org.apache.maven.plugins:maven-dependency-plugin:2.8:copy -Dartifact=$GAV:jar -DoutputDirectory=workspace/wf/tmp
    java -jar workspace/cfr_0_121.jar workspace/wf/tmp/`echo $GAV | cut -d: -f2- | tr ":" "-"`.jar --outputdir workspace/wf/wf-all-in-one/$MODULE/src/main/java
  fi

  cat <<EOF >> workspace/wf/wf-all-in-one/pom.xml
                <module>$MODULE</module>
EOF

  cat <<EOF > workspace/wf/wf-all-in-one/$MODULE/pom.xml
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/maven-v4_0_0.xsd">
        <modelVersion>4.0.0</modelVersion>

        <parent>
                <groupId>org.experiments.rsvoboda</groupId>
                <artifactId>wf-all-deps</artifactId>
                <version>1.0.0</version>
        </parent>

        <artifactId>$MODULE</artifactId>
</project>
EOF

done

cat <<EOF >> workspace/wf/wf-all-in-one/pom.xml
        </modules>
</project>
EOF

## find workspace/wf/wf-all-in-one/ | grep java$

mvn -f workspace/wf/wf-all-in-one/pom.xml  org.sonarsource.scanner.maven:sonar-maven-plugin:3.2:sonar -Dsonar.host.url=http://localhost:9000/  -Dsonar.exclusions=**/org/apache/lucene/analysis/standard/UAX29URLEmailTokenizerImpl.java,**/org/jgroups/protocols/Locking.java

firefox http://localhost:9000/

```

## Step 5) SonarQube and PostgreSQL in Docker
Steps for quick production-like setup in different environments, based on official sonarqube image https://hub.docker.com/_/sonarqube/

Run SonarQube on PostgreSQL
```bash
docker-compose -f docker-compose-complex-config.yml up ## add -d to run in detached mode - containers in the background
```
Backup / Restore Sonar data
```bash
## Backup Sonar data using docker exec
docker exec -t downloads_db_1 pg_dumpall -c -U postgres > sonar_dump_`date +%d-%m-%Y"_"%H_%M_%S`.sql

## Backup Sonar data using docker-compose exec
docker-compose exec db pg_dumpall -c -U postgres > sonar_dump_`date +%d-%m-%Y"_"%H_%M_%S`.sql

## Restore Sonar data
cat your_sonar_dump.sql | docker exec -i downloads_db_1 psql -U postgres
```
Analyse your project as usual
```bash
mvn org.sonarsource.scanner.maven:sonar-maven-plugin:3.2:sonar -Dsonar.host.url=http://localhost:9000/
```
Note: many guides recommend to add `-Dsonar.jdbc.url=jdbc:postgresql://<MACHINE-IP>/sonar` but it was not necessary in my case

**Some helper commands for wirk with Docker:**
```bash
# Stop all containers
docker stop $(docker ps -a -q)

# Delete all containers
docker rm $(docker ps -a -q)

# Delete all images
docker rmi $(docker images -q)

# Delete all volumes
docker volume rm $(docker volume ls -q)

# Inspect volume
docker volume inspect downloads_sonarqube_conf
```
## Step 6) JaCoCo code coverage details for project
To get **JaCoCo code coverage details** into SonarQube **you need compiled classes** and specified `sonar.jacoco.reportPaths` property, no need to have test results etc.
```bash
git clone --branch jbossws-cxf-5.1.8.Final https://github.com/jbossws/jbossws-cxf.git workspace/jbossws-cxf

mvn -f workspace/jbossws-cxf/pom.xml -Pwildfly1010 package -DskipTests -Denforcer.skip=true -Dcheckstyle.skip=true
mvn -f workspace/jbossws-cxf/pom.xml -Pwildfly1010 -Dsonar.jacoco.reportPaths=/home/rsvoboda/Downloads/jacoco.exec org.sonarsource.scanner.maven:sonar-maven-plugin:3.2:sonar

firefox http://localhost:9000/
```

## Step 7) Several JaCoCo code coverage files + one big project

### Merge several JaCoCo .exec files
**Steps using Maven 3**
```bash
cd directory/with/jacoco/exec/files
cat <<EOF > pom.xml
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    <groupId>org.experiments.rsvoboda</groupId>
    <artifactId>JaCoCoMerge</artifactId>
    <version>1.0.0</version>

    <build>
        <plugins>
            <plugin>
                <groupId>org.jacoco</groupId>
                <artifactId>jacoco-maven-plugin</artifactId>
                <version>0.7.9</version>
                <configuration>
                    <fileSets>
                        <fileSet>
                            <!--directory>\${project.build.directory}/jacoco-execs/</directory-->
                            <directory>\${project.basedir}</directory>
                            <includes>
                                <include>*.exec</include>
                            </includes>
                        </fileSet>
                    </fileSets>
                    <destFile>\${project.basedir}/jacoco-merged.exec</destFile>
                </configuration>
            </plugin>
        </plugins>
    </build>

</project>
EOF
mvn jacoco:merge
```
Note: Be aware of backslash before $ to avoid shell expansion if you want to do copy&paste.

If you are trying to merge older .exec files with new ones you may see `[ERROR] Failed to execute goal org.jacoco:jacoco-maven-plugin:0.7.9:merge (default-cli) on project JaCoCoMerge: Unable to read /path/to/jacoco.exec.file: Cannot read execution data version 0x1006. This version of JaCoCo uses execution data version 0x1007. -> [Help 1]`. To see relationship between exec file versions and JaCoCo releases please visit https://github.com/jacoco/jacoco/wiki/ExecFileVersions

**Steps using Ant**
```bash
cd directory/with/jacoco/exec/files
wget -O jacoco.zip http://search.maven.org/remotecontent?filepath=org/jacoco/jacoco/0.7.9/jacoco-0.7.9.zip
unzip -q -d jacoco jacoco.zip

cat <<EOF > build.xml
 <project name="JaCoCo merge project" xmlns:jacoco="antlib:org.jacoco.ant">
     <taskdef uri="antlib:org.jacoco.ant" resource="org/jacoco/ant/antlib.xml">
        <classpath path="jacoco/lib/jacocoant.jar"/>
    </taskdef>
    <target name="merge">
        <jacoco:merge destfile="jacoco-merged.exec">
            <fileset dir="." includes="*.exec"/>
        </jacoco:merge>
    </target>
</project>
EOF

ant merge
```

### Several JaCoCo code coverage files and jbossws-cxf
This step expects existing code coverage files, their creation is out of scope of this text.
For jbossws-cxf I have 3 different JaCoCo file, one for unit tests, one for client side from integration testsuite
and one for server side from integration testsuite (jacoco-server.exec, jacoco-ts.exec, jacoco-unit.exec).
These files are merged into one `jacoco-merged.exec` using steps mentioned above.

```bash
git clone --branch jbossws-cxf-5.1.8.Final https://github.com/jbossws/jbossws-cxf.git workspace/jbossws-cxf

## execute tests so we test details with coverage data
mvn -f workspace/jbossws-cxf/pom.xml -Pwildfly1010 integration-test -Dmaven.test.failure.ignore=true -DfailIfNoTests=false

## push aggregated code coverage
mvn -f workspace/jbossws-cxf/pom.xml -Pwildfly1010 -Dsonar.jacoco.reportPaths=/home/rsvoboda/Downloads/jacoco-merged.exec org.sonarsource.scanner.maven:sonar-maven-plugin:3.2:sonar

firefox http://localhost:9000/
```

### Pushing JaCoCo code coverage details to older or LTS SonarQube server
You may be running older or LTS version of SonarQube server and thus `sonar.jacoco.reportPaths` property won't work.
You must specify older properties `sonar.jacoco.reportPath` and `sonar.jacoco.itReportPath`.

```bash
mvn -Pwildfly1010 org.sonarsource.scanner.maven:sonar-maven-plugin:3.2:sonar -Dsonar.host.url=http://sonar_server_address/ -Dsonar.jacoco.reportPath=/home/rsvoboda/Downloads/jacoco-unit.exec -Dsonar.jacoco.itReportPath=/home/rsvoboda/Downloads/jacoco.exec.merged

```

## Step 8) SonarQube + get maven dependencies + decompile jars 
Some artifacts do not have sources available - e.g. asm and thus some workaround needs to be applied.
Maven can easily fetch jar file with compiled classes, thus decompilation seems like the right way.
Getting sources from component repository can be problematic as one would need to maintain list of
source repositories for components. And on top of that one needs logic to get tag name from component version.

There are several options for decompilers, 3 which I evaluated are:
 * https://bitbucket.org/mstrobel/procyon/downloads/
 * http://jd.benow.ca/
 * http://www.benf.org/other/cfr/

Both Procyon and JD-GUI have last release from August 2015.
CFR is still active, last release is 1 month old. Java 8 support, author works on Java 9 improvements.

```bash
wget -O workspace/cfr_0_121.jar  http://www.benf.org/other/cfr/cfr_0_121.jar

mvn dependency:unpack -Dartifact=$GAV:jar:sources -DoutputDirectory=workspace/wf/wf-all-in-one/$MODULE/src/main/java
if [ $? -gt 0 ]
then
  mvn dependency:copy -Dartifact=$GAV:jar -DoutputDirectory=workspace/wf/tmp
  java -jar workspace/cfr_0_121.jar workspace/wf/tmp/`echo $GAV | cut -d: -f2- | tr ":" "-"`.jar \
     --outputdir workspace/wf/wf-all-in-one/$MODULE/src/main/java
fi
```

Instead of `mvn dependency:copy -Dartifact=$GAV` one can use `mvn dependency:copy-dependencies` to fetch all
dependencies of the project into the target directory.

## Step 9) SonarQube analysis of tests
### Tests results inside current project
```bash
git clone --branch jbossws-cxf-5.1.8.Final https://github.com/jbossws/jbossws-cxf.git workspace/jbossws-cxf

mvn -f workspace/jbossws-cxf/pom.xml test
mvn -f workspace/jbossws-cxf/pom.xml org.sonarsource.scanner.maven:sonar-maven-plugin:3.2:sonar
  ## ==> ~20 unit tests details uploaded

mvn -f workspace/jbossws-cxf/pom.xml -Pwildfly1010 integration-test -Dmaven.test.failure.ignore=true

## tests available results in project
mvn -f workspace/jbossws-cxf/pom.xml org.sonarsource.scanner.maven:sonar-maven-plugin:3.2:sonar
  ## ==> ~740 tests details uploaded

## Customize project name and modules names
find . | grep pom.xml | xargs sed -i "s/JBoss Web Services/EAP : JBoss Web Services/"
mvn -Pwildfly1010 org.sonarsource.scanner.maven:sonar-maven-plugin:3.2:sonar -Dsonar.host.url=http://localhost:9000/
```

### External tests results
When you don't want to spend time re-executing tests you can specify location with the results.
Structure of that directory must be flat, sub-directories are ignored.

```bash
cp -r workspace/jbossws-cxf workspace/jbossws-cxf-flat
cd workspace/jbossws-cxf-flat
mkdir test-results
for i in `find . | grep "surefire-reports$"`; do echo $i; mv $i/* test-results/; done
mvn -Pwildfly1010 clean
mvn -Pwildfly1010 org.sonarsource.scanner.maven:sonar-maven-plugin:3.2:sonar -Dsonar.host.url=http://localhost:9000/ -Dsonar.junit.reportsPath=/home/rsvoboda/Downloads/workspace/jbossws-cxf-flat/test-results/
  ## ==> ~740 tests details uploaded
cd -
```

### Analyze only tests
Original plan was to introduce custom profile which will redefine `sonar.projectName` to something like `${project.name}-tests`
and `sonar.projectKey` to something like `${project.groupId}:${project.artifactId}-tests`. When using Maven, `sonar.projectKey`is
automatically set to `<groupId>:<artifactId>`, details in https://docs.sonarqube.org/display/SONAR/Analysis+Parameters
So the new profile just redefines `sonar.sources` and `sonar.tests`, the rest is done via sed.

```bash
git clone --branch jbossws-cxf-5.1.8.Final https://github.com/jbossws/jbossws-cxf.git workspace/jbossws-cxf-test
cd  workspace/jbossws-cxf-test

TEST_PROFILE="<profile><id>analyze-test-classes</id><properties><sonar.sources>src/test/java</sonar.sources><sonar.tests></sonar.tests></properties></profile>"
sed -i "s,</profiles>,$TEST_PROFILE</profiles>,g" pom.xml

## change groupId to avoid errors like Module "org.jboss.ws.cxf:jbossws-cxf-jaspi" is already part of project "org.jboss.ws.cxf:jbossws-cxf"
find . | grep pom.xml | xargs sed -i "s,<groupId>org.jboss.ws.cxf<\/groupId>,<groupId>org.jboss.ws.cxf.test.analysis<\/groupId>,g"
find . | grep pom.xml | xargs sed -i "s/<name>JBoss Web Services\(.*\)<\/name>/<name>EAP : JBoss Web Services\1 - Tests<\/name>/g"

## ensure src/test/java exists
for i in `find modules | grep pom.xml`; do TESTS_PATH="`dirname $i`/src/test/java"; [[ -d $TESTS_PATH ]] || mkdir -p $TESTS_PATH; done

mvn -Panalyze-test-classes,wildfly1010 org.sonarsource.scanner.maven:sonar-maven-plugin:3.2:sonar
```

### Analyze only tests on older or LTS SonarQube server
When you use steps from previous section against older or 5.6.x LTS SonarQube server you will get failure running the sonar command.
Full message is `Findbugs needs sources to be compiled. Please build project before executing sonar or check the location of compiled classes to make it possible for Findbugs to analyse your project.`.
To workaround this limitation of older SonarQube server you need to build the test classes and give hint to analyzer where to look for them.

Replace last command from previous section with following commands:
```
mvn -Pwildfly1010 integration-test -Dmaven.test.failure.ignore=true -Dtest=NONE -DfailIfNoTests=false
mvn -Panalyze-test-classes,wildfly1010 org.sonarsource.scanner.maven:sonar-maven-plugin:3.2:sonar -Dsonar.java.binaries=target/test-classes
```

## Step 10) jbossws-cxf-client all-in-one project with code coverage and test results
This step expects existing code coverage file and tests results from previous tests execution.
Following code creates all-in-one project with sources pushed into `$MODULE/src/main/java`, it also unpacks .class files into `$MODULE/target/classes/` so code coverage can be processed by SonarQube. To upload test results into SonarQube it is needed to generate minimal mocks of tests into `$MODULE/src/test/java/`. Tests are not uploaded into maven repositories so it's not easy to fetch the real tests.

```bash
## configuration phase

PROJECT="jbossws-cxf-client"
ALL_IN_PROJECT="$PROJECT-all-in-one"
ALL_IN_PROJECT_VERSION="1.0.0.Final"
PROJECT_NAME="JBoss Web Services CXF Client dependencies"
MODULE_PREFIX="ws-client-"

TEST_RESULTS="/home/rsvoboda/Downloads/workspace/jbossws-cxf-flat/test-results"
JACOCO_EXEC="/home/rsvoboda/Downloads/jacoco.exec.merged"

WS="workspace"
WS_INFRA="workspace/tmp"

## prepare phase

[[ -d ${WS} ]] || mkdir -p ${WS}
[[ -d ${WS_INFRA} ]] || mkdir -p ${WS_INFRA}
[[ -f ${WS}/cfr.jar ]] || wget -O ${WS}/cfr.jar http://www.benf.org/other/cfr/cfr_0_121.jar

cat <<EOF > ${WS_INFRA}/${PROJECT}-pom.xml
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/maven-v4_0_0.xsd">
  <modelVersion>4.0.0</modelVersion>

  <name>${PROJECT_NAME}</name>
  <groupId>org.jboss.ws.cxf</groupId>
  <artifactId>${PROJECT}-test</artifactId>
  <version>1.0.0.Final</version>

  <properties>
      <jbossws-cxf-client-version>5.1.8.Final</jbossws-cxf-client-version>
  </properties>

  <dependencies>
    <dependency>
      <groupId>org.jboss.ws.cxf</groupId>
      <artifactId>jbossws-cxf-client</artifactId>
      <version>\${jbossws-cxf-client-version}</version>
    </dependency>
  </dependencies>

</project>
EOF

## execution phase

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

for GAV in `grep ".*:.*:.*:.*:.*:.*" ${WS_INFRA}/${PROJECT}-dependencies.txt| sed "s/\[INFO\]    //g" | grep -v system | cut -d: -f1-2,5`; do
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

mvn -f ${WS}/${ALL_IN_PROJECT}/pom.xml  org.sonarsource.scanner.maven:sonar-maven-plugin:3.2:sonar -Dsonar.host.url=http://localhost:9000/ -Dsonar.exclusions=**/com/google/common/util/concurrent/Monitor.java,**/org/apache/tools/ant/launch/*.java  -Dsonar.jacoco.reportPaths=${JACOCO_EXEC} -Dsonar.junit.reportsPath=${TEST_RESULTS}
```

## Step 11) jbossws-cxf server side all-in-one with code coverage and test results
```bash
## configuration phase

PROJECT="jbossws-cxf-server"
ALL_IN_PROJECT="$PROJECT-all-in-one"
ALL_IN_PROJECT_VERSION="1.0.0.Final"
PROJECT_NAME="JBoss Web Services CXF Server dependencies"
MODULE_PREFIX="ws-server-"

TEST_RESULTS="/home/rsvoboda/Downloads/workspace/jbossws-cxf-flat/test-results"
JACOCO_EXEC="/home/rsvoboda/Downloads/jacoco.exec.merged"

WS="/home/rsvoboda/Downloads/workspace"
WS_INFRA="/home/rsvoboda/Downloads/workspace/tmp"

## prepare phase

[[ -d ${WS} ]] || mkdir -p ${WS}
[[ -d ${WS_INFRA} ]] || mkdir -p ${WS_INFRA}
[[ -f ${WS}/cfr.jar ]] || wget -O ${WS}/cfr.jar http://www.benf.org/other/cfr/cfr_0_121.jar

cat <<EOF > ${WS_INFRA}/${PROJECT}-pom.xml
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/maven-v4_0_0.xsd">
  <modelVersion>4.0.0</modelVersion>

  <name>${PROJECT_NAME}</name>
  <groupId>org.jboss.ws.cxf</groupId>
  <artifactId>${PROJECT}-test</artifactId>
  <version>1.0.0.Final</version>

  <properties>
      <jbossws-cxf-version>5.1.8.Final</jbossws-cxf-version>
  </properties>

  <dependencies>
    <dependency>
      <groupId>org.jboss.ws.cxf</groupId>
      <artifactId>jbossws-cxf-server</artifactId>
      <version>\${jbossws-cxf-version}</version>
    </dependency>
    <dependency>
      <groupId>org.wildfly</groupId>
      <artifactId>wildfly-webservices-server-integration</artifactId>
      <version>11.0.0.Alpha1</version>
      <exclusions>
         <exclusion>
            <groupId>*</groupId>
            <artifactId>*</artifactId>
         </exclusion>
      </exclusions>
    </dependency>
  </dependencies>

</project>
EOF

## execution phase
. common.sh
show_settings
generate_all_in_one

mvn -f ${WS}/${ALL_IN_PROJECT}/pom.xml  org.sonarsource.scanner.maven:sonar-maven-plugin:3.2:sonar -Dsonar.host.url=http://localhost:9000/ -Dsonar.exclusions=**/com/google/common/util/concurrent/Monitor.java,**/org/apache/tools/ant/launch/*.java  -Dsonar.jacoco.reportPaths=${JACOCO_EXEC} -Dsonar.junit.reportsPath=${TEST_RESULTS}

```
## Step 12) WildFly all-in-one with code coverage and test results
```bash
## prepare SonarQube and latest WildFly bits

wget -O workspace/sonarqube-6.3.1.zip https://sonarsource.bintray.com/Distribution/sonarqube/sonarqube-6.3.1.zip
unzip -q -d workspace/ workspace/sonarqube-6.3.1.zip

echo "" >> workspace/sonarqube-6.3.1/conf/sonar.properties
echo "sonar.web.javaOpts=-Xmx3072m -Xms1024m -XX:+HeapDumpOnOutOfMemoryError" >> workspace/sonarqube-6.3.1/conf/sonar.properties
echo "sonar.ce.javaOpts=-Xmx2048m -Xms512m -XX:+HeapDumpOnOutOfMemoryError" >> workspace/sonarqube-6.3.1/conf/sonar.properties

workspace/sonarqube-6.3.1/bin/linux-x86-64/sonar.sh start
sleep 10

git clone https://github.com/wildfly/wildfly.git workspace/wf/wildfly
mvn -f workspace/wf/wildfly/pom.xml -fn clean install -Dmaven.test.failure.ignore=true -Dtest=NONE -DfailIfNoTests=false

mvn -f workspace/wf/wildfly/pom.xml help:evaluate -Dexpression=project.version > /dev/null # to avoid noise in next command
WF_VERSION=`mvn -f workspace/wf/wildfly/pom.xml help:evaluate -Dexpression=project.version | grep -v "^\["`
WF_CORE_VERSION=`mvn -f workspace/wf/wildfly/pom.xml help:evaluate -Dexpression=version.org.wildfly.core | grep -v "^\["`
echo "${WF_VERSION} - ${WF_CORE_VERSION}"
```

```bash
## configuration phase

PROJECT="wildfly-server"
ALL_IN_PROJECT="$PROJECT-all-in-one"
ALL_IN_PROJECT_VERSION="1.0.0.Final"
PROJECT_NAME="WildFly Server dependencies"
MODULE_PREFIX="wf-server-"

TEST_RESULTS="/home/rsvoboda/Downloads/as-ts-plus-ws-ts-flat"
JACOCO_EXEC="/home/rsvoboda/Downloads/jacoco-coverage-files/jacoco-merged.exec"

WS="/home/rsvoboda/Downloads/workspace"
WS_INFRA="/home/rsvoboda/Downloads/workspace/tmp"

## prepare phase

[[ -d ${WS} ]] || mkdir -p ${WS}
[[ -d ${WS_INFRA} ]] || mkdir -p ${WS_INFRA}
[[ -f ${WS}/cfr.jar ]] || wget -O ${WS}/cfr.jar http://www.benf.org/other/cfr/cfr_0_121.jar

cat <<EOF > ${WS_INFRA}/${PROJECT}-pom.xml
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/maven-v4_0_0.xsd">
  <modelVersion>4.0.0</modelVersion>

  <groupId>org.wildfly</groupId>
  <artifactId>wildfly-all-deps</artifactId>
  <version>1.0.0.Final</version>
  <properties>
      <wildfly-version>${WF_VERSION}</wildfly-version>
      <wildfly-core-version>${WF_CORE_VERSION}</wildfly-core-version>
  </properties>
  <dependencies>
    <dependency>
      <groupId>org.wildfly</groupId>
      <artifactId>wildfly-feature-pack</artifactId>
      <version>\${wildfly-version}</version>
      <type>pom</type>
    </dependency>
    <dependency>
      <groupId>org.wildfly</groupId>
      <artifactId>wildfly-servlet-feature-pack</artifactId>
      <version>\${wildfly-version}</version>
      <type>pom</type>
    </dependency>
    <dependency>
      <groupId>org.wildfly.core</groupId>
      <artifactId>wildfly-core-feature-pack</artifactId>
      <version>\${wildfly-core-version}</version>
      <type>pom</type>
    </dependency>
  </dependencies>
</project>
EOF

## execution phase
. common.sh
show_settings
generate_all_in_one

mvn -f ${WS_INFRA}/${PROJECT}-pom.xml dependency:tree

mvn -f ${WS}/${ALL_IN_PROJECT}/pom.xml  org.sonarsource.scanner.maven:sonar-maven-plugin:3.2:sonar -Dsonar.host.url=http://localhost:9000/ -Dsonar.exclusions=**/com/google/common/util/concurrent/Monitor.java,**/org/apache/tools/ant/launch/*.java,**/org/jgroups/protocols/Locking.java  -Dsonar.jacoco.reportPaths=${JACOCO_EXEC} -Dsonar.junit.reportsPath=${TEST_RESULTS}
```

## Step 13) Failsafe plugin, TestNG
Failsafe plugin generates reports into `target/failsafe-reports` directory, SonarQube expects `target/surefire-reports` directory.
This can be redefined using `sonar.junit.reportsPath` property, details in https://github.com/SonarSource/sonar-scanner-maven/blob/master/src/main/java/org/sonarsource/scanner/maven/bootstrap/MavenProjectConverter.java#L99

```bash
git clone https://github.com/orsenthil/maven-failsafe-example workspace/maven-failsafe-example
mvn -f workspace/maven-failsafe-example/pom.xml -Dsonar.junit.reportsPath=target/failsafe-reports/ clean integration-test org.sonarsource.scanner.maven:sonar-maven-plugin:3.2:sonar
```

Usage of TestNG is not causing troubles to SonarQube
```bash
git clone git@github.com:allure-examples/allure-testng-example.git workspace/allure-testng-example
mvn -f workspace/allure-testng-example/pom.xml clean test org.sonarsource.scanner.maven:sonar-maven-plugin:3.2:sonar
## there are test failures but we can ignore them as they are not relevant for this example
```

## Step 14) Project Configuration Parameters
Some projects do not contain some information (homepage, scm etc.) or the information is incorrect.
SonarQube allows to redefine key parameters via command line.
Project configuration parameters are tracked on https://docs.sonarqube.org/display/SONAR/Analysis+Parameters

```bash
mvn archetype:generate -DgroupId=com.mycompany.app -DartifactId=my-app -DarchetypeArtifactId=maven-archetype-quickstart -DinteractiveMode=false

cd my-app/
mvn org.sonarsource.scanner.maven:sonar-maven-plugin:3.2:sonar \
  -Dsonar.links.scm=https://github.com/com.mycompany/my-app \
  -Dsonar.links.homepage=https://www.mycompany.com/my-app \
  -Dsonar.projectDescription="My sample application" \
  -Dsonar.links.ci=https://travis-ci.org/com.mycompany/my-app \
  -Dsonar.links.issue=https://issues.mycompany.com/browse/MYAPP \
  -Dsonar.projectName=MY-APP
```

## Step 15) SonarQube and https
Once you have SonarQube in production it will be probably configured to run on https to prevent simple network tapping - e.g. for username / password. If the server has certificate signed by public CA you will only need to change `http://` to `https://`. If the server has self-signed certificate or certificate signed by internal CA you will need to change `http://` to `https://` and instrument java to trust that server. To do so you need to get the certificate and import it to JDK truststore. Another option is to get the certificate, import it to separate truststore and instruct java to use that truststore. Second option is better for use-cases when users can't patch JDK installation.

```bash
echo -n | openssl s_client -connect sonar-server:443 2>/dev/null | sed -ne '/BEGIN CERTIFICATE/,/END CERTIFICATE/p' > sonar-server.crt
echo "yes" | keytool -import -keystore sonar-truststore.jks -alias sonar-server -file sonar-server.crt -storepass fooBar

mvn org.sonarsource.scanner.maven:sonar-maven-plugin:3.2:sonar \
  -Dsonar.host.url=https://sonar-server/ \
  -Dsonar.login=user-name -Dsonar.password=password \
  -Djavax.net.ssl.trustStore=${WORKSPACE}/sonar-truststore.jks -Djavax.net.ssl.trustStorePassword=fooBar \
  -Dsonar.jacoco.reportPath=${WORKSPACE}/target/jacoco.exec \
  -Dsonar.jacoco.itReportPath=${WORKSPACE}/target/jacoco.exec \
  -Dsonar.jacoco.reportPaths=${WORKSPACE}/target/jacoco.exec ## once SonarQube instance is upgraded to 6.x series
```

## Appendix A
SonarQube 6.4-RC3 experiment, version 6.4 is under development.
No problems noticed, experiments done with Wildfly codebase, tests results and coverage files.

```bash
wget -O workspace/sonarqube-6.4-RC3.zip https://sonarsource.bintray.com/Distribution/sonarqube/sonarqube-6.4-RC3.zip
unzip -q -d workspace/ workspace/sonarqube-6.4-RC3.zip && rm workspace/sonarqube-6.4-RC3.zip

workspace/sonarqube-6.4-RC3/bin/linux-x86-64/sonar.sh start
sleep 10

git clone https://github.com/wildfly/wildfly.git workspace/wildfly
mvn -f workspace/wildfly/pom.xml clean install -DskipTests -Denforcer.skip=true -Dcheckstyle.skip=true

mvn -f workspace/wildfly/pom.xml -DallTests org.sonarsource.scanner.maven:sonar-maven-plugin:3.2:sonar \
  -Dsonar.host.url=http://localhost:9000/ \
  -Dsonar.jacoco.reportPaths=/home/rsvoboda/Downloads/jacoco-coverage-files/jacoco-merged.exec \
  -Dsonar.junit.reportsPath=/home/rsvoboda/Downloads/as-ts-plus-ws-ts-flat
```