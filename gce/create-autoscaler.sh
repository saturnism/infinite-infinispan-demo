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

gcloud preview autoscaler --zone us-central1-c \
  create $1 \
  --cool-down-period 30 \
  --custom-metric custom.cloudmonitoring.googleapis.com/infinispan/namedCache/numberOfEntries \
  --custom-metric-utilization-target-type GAUGE \
  --min-num-replicas 1 \
  --max-num-replicas 10 \
  --target-custom-metric-utilization 1000 \
  --target $2
