#!/usr/bin/env bash

set -o xtrace -o nounset -o pipefail -o errexit

export JAVA_OPTS="-XX:ReservedCodeCacheSize=64m"

# Use node installed in the current environment in PATH
sed -i 's/download = true/download = false/' gradle/node.gradle

# Build Solr without the dependency license.
./gradlew --no-daemon --no-parallel --max-workers=1 \
  -Dorg.gradle.internal.http.socketTimeout=180000 \
  -Dorg.gradle.internal.http.connectionTimeout=180000 \
  -Dorg.gradle.internal.repository.max.retries=5 \
  dev

# Copy all files from build snapshot to ${PREFIX}/libexec/solr
# and symlink wrapper scripts to ${PREFIX}/bin
mkdir -p ${PREFIX}/bin
mkdir -p ${PREFIX}/libexec/apache-solr
cp -r ${SRC_DIR}/solr/packaging/build/solr-${PKG_VERSION}-SNAPSHOT/* ${PREFIX}/libexec/apache-solr
ln -sf ${PREFIX}/libexec/apache-solr/bin/solr ${PREFIX}/bin
ln -sf ${PREFIX}/libexec/apache-solr/bin/solr.cmd ${PREFIX}/bin
