#!/bin/bash

#********************************************************************************
# Copyright 2014 IBM
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#********************************************************************************

#############
# Colors    #
#############
export green='\e[0;32m'
export red='\e[0;31m'
export label_color='\e[0;33m'
export no_color='\e[0m' # No Color


##################################################
# Simple function to only run command if DEBUG=1 # 
##################################################
debugme() {
  [[ $DEBUG = 1 ]] && "$@" || :
}

sudo apt-get update &> /dev/null
sudo apt-get -y install curl golang &> /dev/null



set +e
set +x 

###############################
# Configure extension PATH    #
###############################
if [ -n $EXT_DIR ]; then 
    export PATH=$EXT_DIR:$PATH
else
    export EXT_DIR=`pwd`
fi 

#################################
# Source git_util file          #
#################################
source ${EXT_DIR}/git_util.sh

################################
# git the go source code       #
################################
pushd . >/dev/null
export GOPATH=`pwd`
mkdir -p src/github.com/Osthanes
cd src/github.com/Osthanes
git_retry clone https://github.com/Osthanes/goUcdDeployer.git goUcdDeployer
popd >/dev/null


################################
# build the go  code           #
################################
go install github.com/Osthanes/goUcdDeployer

#################################################################
# Identify the COMPONENT_ID and VERSION to use from IMAGE built #
#################################################################
# If the COMPONENT_ID is set in the environment then use that.  
# Else assume the input is coming from the build.properties created and archived by the Docker builder job
debugme echo "finding build.properties"
debugme pwd 
debugme ls

if [ -f build.properties ]; then
    . build.properties 
    debugme cat build.properties
fi
SHORT_NAME=`echo ${IMAGE_NAME#*/}`
if [ -z $COMPONENT_ID ]; then
    export COMPONENT_ID=`echo ${SHORT_NAME} | awk -F ':' '{print $1}'`
fi
if [ -z $VERSION ]; then
    export VERSION=`echo ${SHORT_NAME} | awk -F ':' '{print $2}'`
fi

if [ -z $COMPONENT_ID ]; then
    echo -e "${red}Set the COMPONENT_ID in the environment or provide a Docker build job as input to this deploy job.${no_color}"
    echo -e "${red}If there was a recent change to the pipeline, such as deleting or moving a job or stage, check that the input to this and other later stages is still set to the correct build stage and job.${no_color}"
    exit 1
fi
echo "COMPONENT_ID: $COMPONENT_ID"
if [ -z $VERSION ]; then
    export VERSION="latest"
fi
echo "VERSION: $VERSION"

