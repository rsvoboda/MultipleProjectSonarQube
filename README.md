# MultipleProjectSonarQube
Running SonarQube on Multiple Project (Not Multiple Module)

Experiment plan
-------------------
1) run SonarQube analysis on source from big project like https://github.com/wildfly/wildfly
2) run SonarQube analysis on jbossws-* dependencies of jbossws-cxf-client
   - as separate SonarQube projects
   - as one big SonarQube project
3) run SonarQube analysis (one big SonarQube project) on all the dependencies of jbossws-cxf-client
   - using Sonar Maven Plugin
   - using Sonar Runner
4) run SonarQube analysis (one big SonarQube project) on all the dependencies of WildFly