#!/bin/bash

USE_DB=$1
USE_ARCH=$2
USE_SECURITY=$3

# # set default values
USE_DB=${USE_DB:--redis}
USE_ARCH=${USE_ARCH:--x86_64}
USE_SECURITY=${USE_SECURITY:--}

# # x86_64 or arm64
[ "$USE_ARCH" = "arm64" ] && USE_ARM64="-arm64"

# # security or no security
[ "$USE_SECURITY" != '-security-' ] && USE_NO_SECURITY="-no-secty"

# nightly or other release
USE_RELEASE=${RELEASE:-nightly-build}
if [ "$USE_RELEASE" = "nightly-build" ]; then
     COMPOSE_FILE="docker-compose-nexus${USE_DB}${USE_NO_SECURITY}${USE_ARM64}.yml"
else
     COMPOSE_FILE="docker-compose${USE_DB}${USE_RELEASE}${USE_NO_SECURITY}${USE_ARM64}.yml"
fi

wget -O ${COMPOSE_FILE} "https://raw.githubusercontent.com/edgexfoundry/developer-scripts/master/releases/${USE_RELEASE}/compose-files/${COMPOSE_FILE}"

# Use Centos base image instead of Alpine base image for Kong for x86_64 CI
# due to compatibility issues with Alpine image in CI
# sed command of MacOS is in different syntax
if [ "$(uname -m)" = "x86_64" ] && [ "$(uname)" = "Darwin" ]; then
     sed -i '' 's/kong:1.3.0$/kong:1.3.0-centos/' ${COMPOSE_FILE}
elif [ "$(uname -m)" = "x86_64" ]; then
     sed -i 's/kong:1.3.0$/kong:1.3.0-centos/' ${COMPOSE_FILE}
fi

# Delete device-virtual service from the compose file
sed -i -r '/device-virtual:/,/- command/ {/ / d;}' ${COMPOSE_FILE}

# Insert device services into the compose file
sed -e '/# device-random:/r docker-compose-device-service.yaml' -e //N ${COMPOSE_FILE} > docker-compose-temp.yaml

# Insert required services for end to end tests
sed -e '/portainer:/r docker-compose-end-to-end.yaml' -e //N docker-compose-temp.yaml > docker-compose.yaml
