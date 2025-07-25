#!/bin/bash

set -euo pipefail

arch="${ARCH:-amd64}"
BASE="eclipse-temurin:11"
if [[ "$arch" = "arm64" ]]; then
  BASE="arm64v8/eclipse-temurin:11"
fi

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

cp "${SCRIPT_DIR}/../../dist/libotelinject_${arch}.so" libotelinject.so
docker buildx build -q --platform linux/${arch} --build-arg BASE=$BASE -o type=image,name=otelinject-test-java,push=false .
OUTPUT=$(docker run --platform linux/${arch} --rm otelinject-test-java)
echo "========== OUTPUT =========="
echo "$OUTPUT"
echo "============================"
echo "Test presence of OTEL_RESOURCE_ATTRIBUTES"
echo "$OUTPUT" | grep "OTEL_RESOURCE_ATTRIBUTES=foo=bar,this=that" > /dev/null && echo "Test passes"  || exit 1
echo "Test presence of OTEL_SERVICE_NAME"
echo "$OUTPUT" | grep "OTEL_SERVICE_NAME=iknowmyownservicename" > /dev/null && echo "Test passes"  || exit 1
echo "Test presence of ANOTHER_VAR"
echo "$OUTPUT" | grep "ANOTHER_VAR=foo" > /dev/null && echo "Test passes"  || exit 1
echo "Test absence of FOO"
[[ ! "$OUTPUT" =~ FOO ]] && echo "Test passes"  || exit 1
echo "Test absence of OTEL_EXPORTER_OTLP_ENDPOINT"
[[ ! "$OUTPUT" =~ OTEL_EXPORTER_OTLP_ENDPOINT ]] && echo "Test passes"  || exit 1

# Check we didn't inject env vars into processes outside of java.
OUTPUT_BASH=$(docker run --platform linux/${arch} --rm otelinject-test-java /usr/bin/env)
echo "======= BASH OUTPUT ========"
echo "$OUTPUT_BASH"
echo "============================"
[[ ! "$OUTPUT_BASH" =~ OTEL_RESOURCE_ATTRIBUTES ]] && echo "Test passes"  || exit 1
