#!/bin/sh
set -e

query_component() {
    curl -fsSL 'https://ci.openharmony.cn/api/daily_build/build/list/component' \
        -H 'Accept: application/json, text/plain, */*' \
        -H 'Content-Type: application/json' \
        --data-raw '{"projectName":"openharmony","branch":"OpenHarmony-5.1.0-Release","pageNum":1,"pageSize":10,"deviceLevel":"","component":"dayu200-arm64_5.1.0-Release","type":1,"startTime":"2025070100000000","endTime":"20990101235959","sortType":"","sortField":"","hardwareBoard":"","buildStatus":"","buildFailReason":"","withDomain":1}'
}
curl $(query_component | jq -r '.data.list.dataList[0].imgObsPath') -o dayu200-arm64.tar.gz

tar -zxf dayu200-arm64.tar.gz
7z x system.img -osystem
mkdir ramdisk
cp ramdisk.img ramdisk/ramdisk.img.gz
cd ramdisk
gunzip ramdisk.img.gz
cpio -i -F ramdisk.img
rm ramdisk.img
cd ..

cp system/lib64/libc++.so ramdisk/lib64/
cp system/lib64/libc++_shared.so ramdisk/lib64/
cp system/etc/passwd ramdisk/etc/
cp -r system/etc/security ramdisk/etc/
#cp -r --dereference /etc/ssl ramdisk/etc/
ln -s ../bin ramdisk/usr/bin
ln -s ../lib ramdisk/usr/lib
ln -s ../lib64 ramdisk/usr/lib64
rm ramdisk/init
rm ramdisk/bin/init_early

# for toybox and curl
cp system/lib64/chipset-pub-sdk/libcrypto_openssl.z.so ramdisk/lib64/chipset-pub-sdk/

# for curl
cp system/lib64/chipset-pub-sdk/libcurl_shared.z.so ramdisk/lib64/chipset-pub-sdk/
cp system/lib64/chipset-pub-sdk/libssl_openssl.z.so ramdisk/lib64/chipset-pub-sdk/
cp system/lib64/platformsdk/libnghttp2_shared.z.so ramdisk/lib64/platformsdk/
cp system/lib64/chipset-pub-sdk/libshared_libz.z.so ramdisk/lib64/chipset-pub-sdk/
cp system/lib64/chipset-sdk/libbrotli_shared.z.so ramdisk/lib64/
cp system/lib64/libc_ares.z.so ramdisk/lib64/
ln -s ./chipset-pub-sdk/libcurl_shared.z.so ramdisk/lib64/libcurl.so.4

cp -r ramdisk /opt/ramdisk
