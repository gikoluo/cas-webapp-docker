FROM centos:centos7

MAINTAINER Apereo Foundation

ENV PATH=$PATH:$JRE_HOME/bin

RUN yum -y install wget tar unzip git \
    && yum -y clean all

# Download Azul Java, verify the hash, and install \
# RUN set -x; \
#     java_version=8.0.131; \
#     zulu_version=8.21.0.1; \
#     java_hash=1931ed3beedee0b16fb7fd37e069b162; \

#     cd / \
#     && wget http://cdn.azul.com/zulu/bin/zulu$zulu_version-jdk$java_version-linux_x64.tar.gz \
#     && echo "$java_hash  zulu$zulu_version-jdk$java_version-linux_x64.tar.gz" | md5sum -c - \
#     && tar -zxvf zulu$zulu_version-jdk$java_version-linux_x64.tar.gz -C /opt \
#     && rm zulu$zulu_version-jdk$java_version-linux_x64.tar.gz \
#     && ln -s /opt/zulu$zulu_version-jdk$java_version-linux_x64/jre/ /opt/jre-home;

# RUN cd / \
# 	&& wget http://cdn.azul.com/zcek/bin/ZuluJCEPolicies.zip \
#     && unzip ZuluJCEPolicies.zip \
#     && mv -f ZuluJCEPolicies/*.jar /opt/jre-home/lib/security \
#     && rm ZuluJCEPolicies.zip; 


# Set up Oracle Java properties
RUN set -x; \
    java_version=8u191; \
    java_bnumber=12; \
    java_semver=1.8.0_191; \
    java_url_hash=2787e4a523244c269598db4e85c51e0c; \
    java_hash=8d6ead9209fd2590f3a8778abbbea6a6b68e02b8a96500e2e77eabdbcaaebcae; \

# Download Oracle Java, verify the hash, and install \
    cd / \
#    && wget --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" \
#    http://download.oracle.com/otn-pub/java/jdk/${java_version}-b${java_bnumber}/${java_url_hash}/server-jre-${java_version}-linux-x64.tar.gz \
    && wget http://www.luochunhui.com/server-jre-8u191-linux-x64.tar.gz \
    && echo "${java_hash}  server-jre-${java_version}-linux-x64.tar.gz" | sha256sum -c - \
    && tar -zxvf server-jre-${java_version}-linux-x64.tar.gz -C /opt \
    && rm server-jre-${java_version}-linux-x64.tar.gz \
    && ln -s /opt/jdk${java_semver}/ /opt/jre-home;

# Download the CAS overlay project \
RUN cd / \
    && git clone --depth 1 --branch 5.3 --single-branch https://github.com/apereo/cas-overlay-template.git cas-overlay \
    && mkdir -p /etc/cas \
    && mkdir -p cas-overlay/bin;


COPY thekeystore /etc/cas/
COPY bin/*.* cas-overlay/bin/
COPY etc/cas/config/*.* /cas-overlay/etc/cas/config/
COPY etc/cas/services/*.* /cas-overlay/etc/cas/services/

RUN chmod -R 750 cas-overlay/bin \
    && chmod 750 cas-overlay/mvnw \
    && chmod 750 cas-overlay/build.sh \
    && chmod 750 /opt/jre-home/bin/java \
# Accelarate in China \
    && mkdir -p $HOME/.m2/ \
    && touch $HOME/.m2/settings.xml \
    && chmod 750 $HOME/.m2/ \
    && sed -i 's/^distributionUrl=https.*/distributionUrl=http\\:\/\/mirrors.shu.edu.cn\/apache\/maven\/maven-3\/3.5.4\/binaries\/apache-maven-3.5.4-bin.zip/g' cas-overlay/maven/maven-wrapper.properties \
    && echo '<?xml version="1.0" encoding="UTF-8"?>' \
            '<settings xmlns="http://maven.apache.org/SETTINGS/1.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.0.0 http://maven.apache.org/xsd/settings-1.0.0.xsd">' \
            '<mirrors> <mirror><id>alimaven</id><name>aliyun maven</name><url>http://maven.aliyun.com/nexus/content/groups/public/</url><mirrorOf>central</mirrorOf></mirror>' \
            '</mirrors></settings>' > $HOME/.m2/settings.xml;

EXPOSE 8080 8443

WORKDIR /cas-overlay

ENV JAVA_HOME /opt/jre-home
ENV PATH $PATH:$JAVA_HOME/bin:.


RUN ./mvnw clean package -T 10

CMD ["/cas-overlay/bin/run-cas.sh"]
