#! /bin/bash
TAR=/tmp/text_butler.tmp.tgz
ARCH=$(uname -m)
SOURCE=build/linux/x64/release/bundle
TARGET_DIR=/tmp/text_butler.install.tmp
TARGET=tools/$ARCH/Install.sh
INSTALL_SKELETON=tools/skeleton
LABEL="===SEPARATOR-BETWEEN-SCRIPT-AND_TAR==="
END_LABEL="===END-SCRIPT-AND_TAR==="
BASE=$(pwd)
DATE=$(date -u +%Y-%m-%d)
test "$1" = "all" && flutter build linux
mkdir -p $(dirname $TARGET)
test -d $TARGET_DIR && rm -Rf $TARGET_DIR
mkdir -p $TARGET_DIR
cd $TARGET_DIR
pwd
cp -a $BASE/$SOURCE .
mv bundle $ARCH
cp -a $BASE/$INSTALL_SKELETON/* .
tar czf $TAR --mtime=$DATE .
cd $BASE
cp -a tools/Install.template $TARGET
echo $LABEL >>$TARGET
cat $TAR >>$TARGET
echo "" >>$TARGET
echo $END_LABEL >> $TARGET
ls -l $TARGET
