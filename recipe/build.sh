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
