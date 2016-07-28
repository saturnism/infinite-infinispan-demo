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

NETWORK_NAME=$1
NETWORK_RANGE=$2

gcloud compute networks create $NETWORK_NAME \
  --range $NETWORK_RANGE

gcloud compute firewall-rules create $NETWORK_NAME-allow-ssh \
  --allow tcp:22 \
  --network $NETWORK_NAME

gcloud compute firewall-rules create $NETWORK_NAME-allow-internal\
  --allow tcp:1-65535 udp:1-65535 icmp \
  --source-ranges $NETWORK_RANGE \
  --network $NETWORK_NAME

gcloud compute instances create $NETWORK_NAME-nat-gateway \
  --network $NETWORK_NAME \
  --can-ip-forward \
  --zone us-central1-c \
  --image debian-7 \
  --metadata-from-file startup-script=nat-gateway-startup.sh \
  --tags $NETWORK_NAME-nat \
  --scopes https://www.googleapis.com/auth/cloud-platform

gcloud compute routes create $NETWORK_NAME-internet-route --network $NETWORK_NAME \
  --destination-range 0.0.0.0/0 \
  --next-hop-instance $NETWORK_NAME-nat-gateway \
  --next-hop-instance-zone us-central1-c \
  --tags $NETWORK_NAME-node \
  --priority 800
