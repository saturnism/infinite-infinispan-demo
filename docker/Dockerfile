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

FROM jboss/infinispan-server:7.1.0.Final

RUN chmod +x ${INFINISPAN_SERVER_HOME}/bin/*.sh
RUN sed -i '/<dependencies>/a <module name="org.jboss.kubeping"\/>' ${INFINISPAN_SERVER_HOME}/modules/system/layers/base/org/jgroups/main/module.xml
RUN sed -i '/<dependencies>/a <module name="org.jboss.kubeping"\/>' ${INFINISPAN_SERVER_HOME}/modules/system/layers/base/org/jboss/as/clustering/jgroups/main/module.xml
COPY standalone/configuration/* ${INFINISPAN_SERVER_HOME}/standalone/configuration/
COPY modules/ ${INFINISPAN_SERVER_HOME}/modules/

ENV JMX_USERNAME=jmx
ENV JMX_PASSWORD=jmx
RUN ${INFINISPAN_SERVER_HOME}/bin/add-user.sh -u ${JMX_USERNAME} -p ${JMX_PASSWORD} -s

EXPOSE 7600 9990 8888 11222 57600

CMD ["/opt/jboss/infinispan-server/bin/clustered.sh", "-c", "clustered-google.xml", "-b", "0.0.0.0"]
