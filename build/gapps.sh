#!/bin/bash
# (c) Joey Rizzoli, 2015
# (c) Paul Keith, 2017
# Released under GPL v2 License

##
# var
#
DATE=$(date +%F-%H-%M)
TOP=$(realpath .)
ANDROIDV=7.1.2
GARCH=$1
OUT=$TOP/out
BUILD=$TOP/build
METAINF=$BUILD/meta
COMMON=$TOP/common/proprietary
GLOG=$OUT/gapps_log
ADDOND=$TOP/addond.sh

##
# functions
#
function clean() {
    echo "Cleaning up..."
    rm -r $OUT/$GARCH
    rm /tmp/$BUILDZIP
    return $?
}

function failed() {
    echo "Build failed, check $GLOG"
    exit 1
}

function create() {
    test -f $GLOG && rm -f $GLOG
    echo "Starting GApps compilation" > $GLOG
    echo "ARCH= $GARCH" >> $GLOG
    echo "OS= $(uname -s -r)" >> $GLOG
    echo "NAME= $(whoami) at $(uname -n)" >> $GLOG
    PREBUILT=$TOP/$GARCH/proprietary
    test -d $OUT || mkdir $OUT;
    test -d $OUT/$GARCH || mkdir -p $OUT/$GARCH
    test -d $OUT/$GARCH/system || mkdir -p $OUT/$GARCH/system
    echo "Build directories are now ready" >> $GLOG
    echo "Getting prebuilts..."
    echo "Copying stuff" >> $GLOG
    cp -r $PREBUILT/* $OUT/$GARCH/system >> $GLOG
    cp -r $COMMON/* $OUT/$GARCH/system >> $GLOG
    echo "Generating addon.d script" >> $GLOG
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
    cp -r $METAINF/* $OUT/$GARCH/META-INF/ && echo "Meta copied" >> $GLOG
    echo "Creating package..."
    cd $OUT/$GARCH
    zip -r /tmp/$BUILDZIP . >> $GLOG
    rm -rf $OUT/tmp >> $GLOG
    cd $TOP
    if [ -f /tmp/$BUILDZIP ]; then
        echo "Signing zip..."
        java -Xmx2048m -jar $TOP/build/sign/signapk.jar -w $TOP/build/sign/testkey.x509.pem $TOP/build/sign/testkey.pk8 /tmp/$BUILDZIP $OUT/$BUILDZIP >> $GLOG
    else
        echo "Couldn't zip files!"
        echo "Couldn't find unsigned zip file, aborting" >> $GLOG
        return 1
    fi
}

function getmd5() {
    if [ -x $(which md5sum) ]; then
        echo "md5sum is installed, getting md5..." >> $GLOG
        echo "Getting md5sum..."
        GMD5=$(md5sum $OUT/$BUILDZIP)
        echo -e "$GMD5" > $OUT/$BUILDZIP.md5sum
        echo "md5 exported at $OUT/$BUILDZIP.md5sum"
        return 0
    else
        echo "md5sum is not installed, aborting" >> $GLOG
        return 1
    fi
}

##
# main
#
if [ -x $(which realpath) ]; then
    echo "Realpath found!" >> $GLOG
else
    TOP=$(cd . && pwd) # some darwin love
    echo "No realpath found!" >> $GLOG
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

echo "Done!" >> $GLOG
echo "Build completed: $GMD5"
exit 0
