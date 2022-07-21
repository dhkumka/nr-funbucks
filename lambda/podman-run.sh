#!/bin/bash

cd "${0%/*}"

# Host Metadata - OS
#
export HOST_OS_KERNEL="$(uname -r)"
export HOST_OS_TYPE="$(uname)"

# Host Metadata - General
#
export HOST_ARCH="$(uname -m)"
export HOST_HOSTNAME="$(hostname -s)"
export HOST_ID="$(hostname -f)"
export HOST_NAME="${HOST_HOSTNAME}"
export HOST_DOMAIN="$(echo ${HOST_HOSTNAME#[[:alpha:]]*.})"
export FLUENT_VERSION="1.9.6"
export FLUENT_CONF_HOME="/config"
export FUNBUCKS_HOME="${PWD}/.."

# Run in foreground, passing vars
podman run --rm \
    -v "${FUNBUCKS_HOME}/output:/config" \
    -v "${PWD}/data:/data" \
    -v "/proc/stat:/proc/stat:ro" \
    -e FLUENT_VERSION=${FLUENT_VERSION} \
    -e HOST_* \
    -e FLUENT_CONF_HOME=${FLUENT_CONF_HOME} \
    --network=host \
	--security-opt label=disable \
    fluent/fluent-bit:${FLUENT_VERSION}-debug /fluent-bit/bin/fluent-bit -c /config/fluent-bit.conf
