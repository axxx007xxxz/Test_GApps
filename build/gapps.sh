#!/bin/bash
# (c) Joey Rizzoli, 2015
# (c) Paul Keith, 2017
# (c) axxx007xxxz, 2017
# Released under GPL v2 License

##
# Various
#
DATE=$(date +%F-%H-%M)
TOP=$(realpath .)
ANDROIDV=7.1.2
GARCH=$1
OUT=$TOP/out
BUILD=$TOP/build
METAINF=$BUILD/meta
COMMON=$TOP/common/proprietary
LOG=$OUT/log
ADDOND=$TOP/addond.sh

##
# Functions
#
function clean() {
    echo "Cleaning up..."
    rm -r $OUT/*
    rm /tmp/$BUILDZIP
    return $?
}

function failed() {
    echo "Build failed, check $LOG"
    exit 1
}

function create() {
    echo "Starting GApps compilation" > $LOG
    echo "ARCH= $GARCH" >> $LOG
    echo "OS= $(uname -s -r)" >> $LOG
    echo "NAME= $(whoami) at $(uname -n)" >> $LOG
    PREBUILT=$TOP/$GARCH/proprietary
    test -d $OUT || mkdir $OUT;
    test -d $OUT/$GARCH || mkdir -p $OUT/$GARCH
    test -d $OUT/$GARCH/system || mkdir -p $OUT/$GARCH/system
    echo "Build directories are now ready" >> $LOG
    echo "Getting prebuilts..."
    echo "Copying stuff" >> $LOG
    cp -r $PREBUILT/* $OUT/$GARCH/system >> $LOG
    cp -r $COMMON/* $OUT/$GARCH/system >> $LOG
    echo "Generating addon.d script" >> $LOG
    test -d $OUT/$GARCH/system/addon.d || mkdir -p $OUT/$GARCH/system/addon.d
    test -f $ADDOND && rm -f $ADDOND
    cat $TOP/addond_head > $ADDOND
    for txt_file in proprietary-files-common proprietary-files-$GARCH; do
        cat $TOP/$txt_file.txt | while read l; do
            if [ "$l" != "" ]; then
                line=$(echo "$l" | sed 's/^-//g')
                line=${line%%|*}
                line=${line%%:*}
                echo "$line" >> $ADDOND.tmp
            fi
        done
    done
    cat $ADDOND.tmp | LC_ALL=C sort | uniq >> $ADDOND
    rm $ADDOND.tmp
    cat $TOP/addond_tail >> $ADDOND
    chmod 755 $ADDOND
    mv $ADDOND $OUT/$GARCH/system/addon.d/30-gapps.sh
}

function zipit() {
    BUILDZIP=Test_GApps-$ANDROIDV-$GARCH-$DATE.zip
    echo "Importing installation scripts..."
    test -d $OUT/$GARCH/META-INF || mkdir $OUT/$GARCH/META-INF;
    cp -r $METAINF/* $OUT/$GARCH/META-INF/ && echo "Meta copied" >> $LOG
    echo "Creating package..."
    cd $OUT/$GARCH
    zip -r /tmp/$BUILDZIP . >> $LOG
    rm -rf $OUT/tmp >> $LOG
    cd $TOP
    if [ -f /tmp/$BUILDZIP ]; then
        echo "Signing zip..."
        java -Xmx2048m -jar $TOP/build/sign/signapk.jar -w $TOP/build/sign/testkey.x509.pem $TOP/build/sign/testkey.pk8 /tmp/$BUILDZIP $OUT/$BUILDZIP >> $LOG
    else
        echo "Couldn't zip files!"
        echo "Couldn't find unsigned zip file, aborting" >> $LOG
        return 1
    fi
}

function getmd5() {
    if [ -x $(which md5sum) ]; then
        echo "md5sum is installed, getting md5..." >> $LOG
        echo "Getting md5sum..."
        GMD5=$(md5sum $OUT/$BUILDZIP)
        echo -e "$GMD5" > $OUT/$BUILDZIP.md5sum
        echo "md5 exported at $OUT/$BUILDZIP.md5sum"
        return 0
    else
        echo "md5sum is not installed, aborting" >> $LOG
        return 1
    fi
}

##
# Main
#
if [ -x $(which realpath) ]; then
    echo "Realpath found!" >> $LOG
else
    TOP=$(cd . && pwd) # some darwin love
    echo "No realpath found!" >> $LOG
fi

for func in create zipit getmd5 clean; do
    $func
    ret=$?
    if [ "$ret" == 0 ]; then
        continue
    else
        failed
    fi
done

echo "Done!" >> $LOG
echo "Build completed: $GMD5"
exit 0