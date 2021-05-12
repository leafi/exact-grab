#!/bin/bash
set -eo pipefail

MOD_NAME=$(jq -r .name info.json)
MOD_VERSION=$(jq -r .version info.json)
OUT_SUBDIR="${MOD_NAME}_${MOD_VERSION}"
OUT_DIR="build/${MOD_NAME}_${MOD_VERSION}"

test -d build && rm -r build
mkdir -p $OUT_DIR

cp -r locale $OUT_DIR/locale
cp *.lua $OUT_DIR/
cp changelog.txt $OUT_DIR/changelog.txt
cp info.json $OUT_DIR/info.json
cp LICENSE $OUT_DIR/LICENSE
cp thumbnail.png $OUT_DIR/thumbnail.png

pushd build 2>&1 >/dev/null
zip -r $OUT_SUBDIR.zip $OUT_SUBDIR
popd 2>&1 >/dev/null
