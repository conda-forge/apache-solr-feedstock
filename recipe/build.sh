#!/usr/bin/env bash

set -o xtrace -o nounset -o pipefail -o errexit

export JAVA_OPTS="-XX:ReservedCodeCacheSize=64m"

# Build Solr without the dependency license report step.
# The package does not need to generate third-party license reports during conda packaging.
./gradlew --no-daemon --no-parallel --max-workers=1 dev

# Copy all files from build snapshot to ${PREFIX}/libexec/solr
# and symlink wrapper scripts to ${PREFIX}/bin
mkdir -p ${PREFIX}/bin
mkdir -p ${PREFIX}/libexec/apache-solr
cp -r ${SRC_DIR}/solr/packaging/build/solr-${PKG_VERSION}-SNAPSHOT/* ${PREFIX}/libexec/apache-solr
ln -sf ${PREFIX}/libexec/apache-solr/bin/solr ${PREFIX}/bin
ln -sf ${PREFIX}/libexec/apache-solr/bin/solr.cmd ${PREFIX}/bin
