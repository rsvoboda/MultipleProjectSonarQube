# MultipleProjectSonarQube
Running SonarQube on Multiple Project (Not Multiple Module)

## Experiment plan
1) run SonarQube analysis on source from big project like https://github.com/wildfly/wildfly
2) run SonarQube analysis on jbossws-* dependencies of jbossws-cxf-client
   - as separate SonarQube projects
   - as one big SonarQube project
3) run SonarQube analysis (one big SonarQube project) on all the dependencies of jbossws-cxf-client
   - using Sonar Maven Plugin
   - using Sonar Runner
4) run SonarQube analysis (one big SonarQube project) on all the dependencies of WildFly

### Step 1 - Analysis on WildFly sources
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