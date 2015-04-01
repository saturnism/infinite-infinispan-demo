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

FROM java:7

ADD *.jar /app/
ADD *.json /app/

WORKDIR /app/

CMD ["java", "-Djava.net.preferIPv4Stack=true", "-cp", "jboss-client.jar:jmxtrans-247-SNAPSHOT-all.jar", "-Djava.awt.headless=true", "-Djava.net.preferIPv4Stack=true", "-Dinfinispan.host=`hostname -I`", "-Dinfinispan.port=9990", "-Djmxtrans.log.dir=/app/", "com.googlecode.jmxtrans.JmxTransformer", "-f", "/app/infinispan.json"]
