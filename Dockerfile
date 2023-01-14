# Name: maven-xvfb-chrome:3.8.7-openjdk-17
FROM docker.io/library/openjdk:17-ea-jdk-buster

# Maintainer
LABEL maintainer "tarosaiba"

# Install Maven
ARG MAVEN_VERSION=3.8.7
ARG USER_HOME_DIR="/root"
ARG SHA=21c2be0a180a326353e8f6d12289f74bc7cd53080305f05358936f3a1b6dd4d91203f4cc799e81761cf5c53c5bbe9dcc13bdb27ec8f57ecf21b2f9ceec3c8d27
ARG BASE_URL=https://downloads.apache.org/maven/maven-3/${MAVEN_VERSION}/binaries
ENV MAVEN_HOME /usr/share/maven
ENV MAVEN_CONFIG "$USER_HOME_DIR/.m2"

RUN set -x \
  && apt-get update \
  && apt-get install -y gnupg dirmngr --no-install-recommends \
  && rm -rf /var/lib/apt/lists/* \
  && curl -fsSLO --compressed ${BASE_URL}/apache-maven-${MAVEN_VERSION}-bin.tar.gz \
  && echo "${SHA}  apache-maven-${MAVEN_VERSION}-bin.tar.gz" | sha512sum -c - \
  && curl -fsSLO --compressed ${BASE_URL}/apache-maven-${MAVEN_VERSION}-bin.tar.gz.asc \
  && export GNUPGHOME="$(mktemp -d)" \
  && for key in \
    6A814B1F869C2BBEAB7CB7271A2A1C94BDE89688 \
  ; do \
    gpg --batch --keyserver hkps://pgp.surf.nl --recv-keys "$key" || \
    gpg --batch --keyserver hkps://keyserver.ubuntu.com --recv-keys "$key" ; \
  done \
  && gpg --batch --verify apache-maven-${MAVEN_VERSION}-bin.tar.gz.asc apache-maven-${MAVEN_VERSION}-bin.tar.gz \
  && mkdir -p ${MAVEN_HOME} ${MAVEN_HOME}/ref \
  && tar -xzf apache-maven-${MAVEN_VERSION}-bin.tar.gz -C ${MAVEN_HOME} --strip-components=1 \
  # GNUPGHOME may fail to delete even with -rf
  && (rm -rf "$GNUPGHOME" apache-maven-${MAVEN_VERSION}-bin.tar.gz.asc apache-maven-${MAVEN_VERSION}-bin.tar.gz || true) \
  && ln -s ${MAVEN_HOME}/bin/mvn /usr/bin/mvn \
  && apt-get remove --purge --autoremove -y gnupg dirmngr \
  # smoke test
  && mvn --version


# Install Google Chrome
RUN apt-get update \
    && apt-get install -y xvfb \
    && wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb \
    && apt install -y ./google-chrome-stable_current_amd64.deb \
    && apt install -y fonts-ipafont fonts-ipaexfont \
    && rm ./google-chrome-stable_current_amd64.deb \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# SAMPLE: xvfb-run mvn clean test -Dselenide.baseUrl=http://frontend -Dat.db.host=mariadb
CMD [xvfb-run mvn --version]
