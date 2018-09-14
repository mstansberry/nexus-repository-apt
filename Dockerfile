ARG NEXUS_VERSION=3.13.0

FROM maven:3-jdk-8-alpine AS build
ARG NEXUS_VERSION=3.13.0
ARG NEXUS_BUILD=01

COPY . /nexus-repository-apt/
RUN cd /nexus-repository-apt/; sed -i "s/3.11.0-01/${NEXUS_VERSION}-${NEXUS_BUILD}/g" pom.xml; \
    mvn;

FROM sonatype/nexus3:$NEXUS_VERSION
ARG NEXUS_VERSION=3.13.0
ARG NEXUS_BUILD=01
# Will not seem to work in sed without some magick
ARG APT_VERSION=1.0.7
ARG APT_TARGET=/opt/sonatype/nexus/system/net/staticsnow/nexus-repository-apt/${APT_VERSION}/
USER root
RUN mkdir -p ${APT_TARGET}; \
    sed -i 's@nexus-repository-maven</feature>@nexus-repository-maven</feature>\n        <feature prerequisite="false" dependency="false" version="1.0.7">nexus-repository-apt</feature>@g' /opt/sonatype/nexus/system/org/sonatype/nexus/assemblies/nexus-core-feature/${NEXUS_VERSION}-${NEXUS_BUILD}/nexus-core-feature-${NEXUS_VERSION}-${NEXUS_BUILD}-features.xml; \
    sed -i 's@<feature name="nexus-repository-maven"@<feature name="nexus-repository-apt" description="net.staticsnow:nexus-repository-apt" version="1.0.7">\n        <details>net.staticsnow:nexus-repository-apt</details>\n        <bundle>mvn:net.staticsnow/nexus-repository-apt/1.0.7</bundle>\n        <bundle>mvn:org.apache.commons/commons-compress/1.16.1</bundle>\n        <bundle>mvn:org.tukaani/xz/1.8</bundle>\n    </feature>\n    <feature name="nexus-repository-maven"@g' /opt/sonatype/nexus/system/org/sonatype/nexus/assemblies/nexus-core-feature/${NEXUS_VERSION}-${NEXUS_BUILD}/nexus-core-feature-${NEXUS_VERSION}-${NEXUS_BUILD}-features.xml;
COPY --from=build /nexus-repository-apt/target/nexus-repository-apt-${APT_VERSION}.jar ${APT_TARGET}
USER nexus
