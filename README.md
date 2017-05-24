# MultipleProjectSonarQube
Running SonarQube on Multiple Project (Not Multiple Module)

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
  * [Step 6) JaCoCo test coverage details for project](#step-6-jacoco-test-coverage-details-for-project)
  * [Step 7) Several JaCoCo test coverage files   one big project](#step-7-several-jacoco-test-coverage-files--one-big-project)
  * [Step 8) SonarQube   get maven dependencies   decompile jars](#step-8-sonarqube--get-maven-dependencies--decompile-jars)
  * [Step 9) SonarQube analysis of tests, detection of dedicated tests modules](#step-9-sonarqube-analysis-of-tests-detection-of-dedicated-tests-modules)

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
6) SonarQube + JaCoCo test coverage details for one project
7) SonarQube + several JaCoCo test coverage files + one big SonarQube project
8) SonarQube + get maven dependencies + decompile jars (some artifacts do not have sources available - e.g. asm)
9) SonarQube analysis of tests, detection of dedicated tests modules

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
## Step 6) JaCoCo test coverage details for project
To get JaCoCo test coverage details into SonarQube you need compiled classes and specified `sonar.jacoco.reportPaths` property, no need to have test results etc.
```bash
git clone --branch jbossws-cxf-5.1.8.Final https://github.com/jbossws/jbossws-cxf.git workspace/jbossws-cxf

mvn -f workspace/jbossws-cxf/pom.xml -Pwildfly1010 package -DskipTests -Denforcer.skip=true -Dcheckstyle.skip=true
mvn -f workspace/jbossws-cxf/pom.xml -Pwildfly1010 -Dsonar.jacoco.reportPaths=/home/rsvoboda/Downloads/jacoco.exec org.sonarsource.scanner.maven:sonar-maven-plugin:3.2:sonar

firefox http://localhost:9000/
```


## Step 7) Several JaCoCo test coverage files + one big project

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

## Step 9) SonarQube analysis of tests, detection of dedicated tests modules
