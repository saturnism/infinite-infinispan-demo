#!/bin/bash
#*******************************************************************************
# Copyright 2015 Google Inc. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#*******************************************************************************

export DEBIAN_FRONTEND=noninteractive

# Make sure only one instance of the script can be run at a time
exec 9>/tmp/startup.lock
if ! flock -n 9  ; then
  echo "The startup script is already running. Exiting.";
  exit 1
fi

# Install Java 7
if [ ! -x /usr/bin/java ]; then
  apt-get -q update && \
    apt-get install --no-install-recommends -y -q ca-certificates unzip curl openjdk-7-jdk
fi

if [ ! -d /opt/stackdriver ]; then
  export STACKDRIVER_API_KEY=$(curl http://metadata.google.internal/computeMetadata/v1/project/attributes/STACKDRIVER_API_KEY -H 'Metadata-Flavor: Google')
  echo "stackdriver-agent stackdriver-agent/apikey string $STACKDRIVER_API_KEY" | debconf-set-selections
  curl -o /etc/apt/sources.list.d/stackdriver.list https://repo.stackdriver.com/wheezy.list
  curl --silent https://app.google.stackdriver.com/RPM-GPG-KEY-stackdriver |apt-key add -
  apt-get -q update && \
    apt-get install --no-install-recommends -y -q  stackdriver-agent
fi;

export INFINISPAN_VERSION=7.1.0.Final
export INFINISPAN_HOME=/opt/jboss/infinispan-server
export INFINISPAN_USER=infinispan

export GOOGLE_PING_ACCESS=$(curl http://metadata.google.internal/computeMetadata/v1/project/attributes/GOOGLE_PING_ACCESS -H 'Metadata-Flavor: Google')
export GOOGLE_PING_SECRET=$(curl http://metadata.google.internal/computeMetadata/v1/project/attributes/GOOGLE_PING_SECRET -H 'Metadata-Flavor: Google')
export GOOGLE_PING_BUCKET=$(curl http://metadata.google.internal/computeMetadata/v1/project/attributes/GOOGLE_PING_BUCKET -H 'Metadata-Flavor: Google')

# Create an user
if [ -z "$(getent passwd ${INFINISPAN_USER})" ]; then
  /usr/sbin/addgroup --system ${INFINISPAN_USER}
  /usr/sbin/adduser --system --home ${INFINISPAN_HOME} --shell /bin/bash --disabled-password --ingroup ${INFINISPAN_USER} ${INFINISPAN_USER}
fi

if [ ! -d "${INFINISPAN_HOME}/bin" ]; then
  # Install Infinispan
  http://downloads.jboss.org/infinispan/7.1.0.Final/infinispan-server-7.1.0.Final-bin.zip
  mkdir -p ${INFINISPAN_HOME}
  cd /tmp
  curl -0 -O http://download.jboss.org/infinispan/${INFINISPAN_VERSION}/infinispan-server-${INFINISPAN_VERSION}-bin.zip
  unzip /tmp/infinispan-server-${INFINISPAN_VERSION}-bin.zip
  mv /tmp/infinispan-server-${INFINISPAN_VERSION}/* ${INFINISPAN_HOME}/

  # Insert Cluster Name
  sed -i 's,<transport executor="infinispan-transport",<transport executor="infinispan-transport" cluster="${jboss.cluster.name:default}",' ${INFINISPAN_HOME}/standalone/configuration/clustered.xml

  # Insert JGroups interface
  sed -i '/<\/interfaces>/i <interface name="jgroups"><inet-address value="${jboss.bind.address.jgroups:127.0.0.1}"\/><\/interface>' ${INFINISPAN_HOME}/standalone/configuration/clustered.xml
  sed -i 's,<socket-binding name="jgroups-tcp",<socket-binding name="jgroups-tcp" interface="jgroups",' ${INFINISPAN_HOME}/standalone/configuration/clustered.xml
  sed -i 's,<socket-binding name="jgroups-tcp-fd",<socket-binding name="jgroups-tcp-fd" interface="jgroups",' ${INFINISPAN_HOME}/standalone/configuration/clustered.xml
  sed -i 's,<distributed-cache name="namedCache" mode="SYNC" start="EAGER"/>,<distributed-cache name="namedCache" mode="SYNC" start="EAGER"><state-transfer await-initial-transfer="false"/></distributed-cache>,' ${INFINISPAN_HOME}/standalone/configuration/clustered.xml

  # Update permission
  chown -R ${INFINISPAN_USER}:${INFINISPAN_USER} ${INFINISPAN_HOME}

  export JMX_USERNAME=jmx
  export JMX_PASSWORD=jmx
  ${INFINISPAN_HOME}/bin/add-user.sh -u ${JMX_USERNAME} -p ${JMX_PASSWORD} -s
fi

export JMXTRANS_HOME=/opt/jmxtrans

mkdir -p ${JMXTRANS_HOME}
gsutil -q cp gs://files-intense-pointer-860/*.jar ${JMXTRANS_HOME}
gsutil -q cp gs://files-intense-pointer-860/*.json ${JMXTRANS_HOME}
chown -R ${INFINISPAN_USER}:${INFINISPAN_USER} ${JMXTRANS_HOME}

# Start Infinispan
export JAVA_OPTS="-Xmx2g -Xms2g -XX:PermSize=256m -XX:MaxPermSize=256m -XX:+UseConcMarkSweepGC"
start-stop-daemon --start --quiet --chuid ${INFINISPAN_USER} --group ${INFINISPAN_USER} \
  --background --make-pidfile --pidfile /var/run/infinispan.pid \
  --exec ${INFINISPAN_HOME}/bin/clustered.sh -- \
  -c clustered.xml \
  -b `hostname -I` \
  -bmanagement=0.0.0.0 \
  -Djboss.node.name=`hostname` \
  -Djboss.default.jgroups.stack=google \
  -Djgroups.google.bucket=${GOOGLE_PING_BUCKET} \
  -Djgroups.google.access_key=${GOOGLE_PING_ACCESS} \
  -Djgroups.google.secret_access_key=${GOOGLE_PING_SECRET} \
  -Dcom.sun.management.jmxremote.authenticate=false \
  -Djboss.bind.address.jgroups=`hostname --ip-address` \
  -Djboss.cluster.name=infinispan

start-stop-daemon --start --quiet --chuid ${INFINISPAN_USER} --group ${INFINISPAN_USER} \
    --background --make-pidfile --pidfile /var/run/jmxtrans.pid \
    --exec /usr/bin/java -- \
    -cp ${JMXTRANS_HOME}/jmxtrans-247-SNAPSHOT-all.jar:${JMXTRANS_HOME}/jboss-client.jar \
    -Djava.awt.headless=true \
    -Djmxtrans.log.dir=${JMXTRANS_HOME} \
    -Djava.net.preferIPv4Stack=true \
    -Dinfinispan.host=127.0.0.1 \
    -Dinfinispan.port=9990 \
    com.googlecode.jmxtrans.JmxTransformer \
    -f ${JMXTRANS_HOME}/infinispan.json
