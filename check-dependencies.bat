@echo off
echo Checking Maven dependency tree for Tomcat versions...
echo.
mvn dependency:tree -Dincludes=org.apache.tomcat.embed:*
echo.
echo Checking for any HIGH/CRITICAL vulnerabilities in dependencies...
echo.
mvn org.owasp:dependency-check-maven:check -DfailBuildOnCVSS=7
