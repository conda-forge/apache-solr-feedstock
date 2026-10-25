#!/usr/bin/env bash

set -o xtrace -o nounset -o pipefail -o errexit

# Patch build.gradle to add dependency-license-report plugin
sed -i "s/id 'base'/id 'base'\nid 'com.github.jk1.dependency-license-report' version 'latest.release'/" build.gradle

# Build from source with gradle and download third-party licenses
export JAVA_OPTS="-XX:ReservedCodeCacheSize=64m"
./gradlew dev
./gradlew generateLicenseReport

# Copy all files from build snapshot to ${PREFIX}/libexec/solr
# and symlink wrapper scripts to ${PREFIX}/bin
mkdir -p ${PREFIX}/bin
mkdir -p ${PREFIX}/libexec/apache-solr
cp -r ${SRC_DIR}/solr/packaging/build/solr-${PKG_VERSION}-SNAPSHOT/* ${PREFIX}/libexec/apache-solr
ln -sf ${PREFIX}/libexec/apache-solr/bin/solr ${PREFIX}/bin
ln -sf ${PREFIX}/libexec/apache-solr/bin/solr.cmd ${PREFIX}/bin

# google-api-client bundles its own CA trust store, but
# Solr's HTTP code paths never load it. They use the JVM's trust store instead.
# Strip the dead copy so it can't go stale.
gcs_jar_count=0
while IFS= read -r -d '' jar; do
  zip -d "${jar}" \
    "com/google/api/client/googleapis/google.p12" \
    "com/google/api/client/googleapis/google.jks"
  gcs_jar_count=$((gcs_jar_count + 1))
done < <(find "${PREFIX}/libexec/apache-solr" -name 'google-api-client-*.jar' -print0)
if [ "${gcs_jar_count}" -eq 0 ]; then
  echo "ERROR: expected to find a google-api-client-*.jar to strip the vendored CA trust store from, found none." >&2
  exit 1
fi
