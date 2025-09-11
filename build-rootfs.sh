#!/bin/sh
set -e

# Download operating system image
query_component() {
    curl -fsSL 'https://ci.openharmony.cn/api/daily_build/build/list/component' \
        -H 'Accept: application/json, text/plain, */*' \
        -H 'Content-Type: application/json' \
        --data-raw '{"projectName":"openharmony","branch":"OpenHarmony-5.1.0-Release","pageNum":1,"pageSize":10,"deviceLevel":"","component":"dayu200-arm64_5.1.0-Release","type":1,"startTime":"2025070100000000","endTime":"20990101235959","sortType":"","sortField":"","hardwareBoard":"","buildStatus":"success","buildFailReason":"","withDomain":1}'
}
curl $(query_component | jq -r '.data.list.dataList[0].imgObsPath') -o dayu200-arm64.tar.gz
tar -zxf dayu200-arm64.tar.gz

# Extract necessary files from the operating system image
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
ln -s ../bin ramdisk/usr/bin
ln -s ../lib ramdisk/usr/lib
ln -s ../lib64 ramdisk/usr/lib64

# Replace OpenHarmony toybox with offical toybox
rm ramdisk/bin/toybox
curl https://landley.net/bin/toybox/0.8.10/toybox-aarch64 -o ramdisk/bin/toybox
chmod +x ramdisk/bin/toybox
ln -s toybox ramdisk/bin/wget

# These files are not needed because init is not required in the container
rm ramdisk/init
rm ramdisk/bin/init_early
rm ramdisk/lib64/libinit_stub_empty.so
rm ramdisk/lib64/libinit_module_engine.so
rm ramdisk/lib64/chipset-pub-sdk/libsec_shared.z.so
rm ramdisk/lib64/platformsdk/librestorecon.z.so

# These files are not needed because selinux is not enabled in the root environment
rm ramdisk/lib64/libsepol.z.so
rm ramdisk/lib64/libload_policy.z.so
rm ramdisk/lib64/chipset-pub-sdk/libselinux.z.so
rm ramdisk/lib64/chipset-pub-sdk/libpcre2.z.so

# For curl
cp system/lib64/chipset-pub-sdk/libcrypto_openssl.z.so ramdisk/lib64/chipset-pub-sdk/
cp system/lib64/chipset-pub-sdk/libcurl_shared.z.so ramdisk/lib64/chipset-pub-sdk/
cp system/lib64/chipset-pub-sdk/libssl_openssl.z.so ramdisk/lib64/chipset-pub-sdk/
cp system/lib64/platformsdk/libnghttp2_shared.z.so ramdisk/lib64/platformsdk/
cp system/lib64/chipset-pub-sdk/libshared_libz.z.so ramdisk/lib64/chipset-pub-sdk/
cp system/lib64/chipset-sdk/libbrotli_shared.z.so ramdisk/lib64/
cp system/lib64/libc_ares.z.so ramdisk/lib64/
ln -s ./chipset-pub-sdk/libcurl_shared.z.so ramdisk/lib64/libcurl.so.4
mkdir ramdisk/etc/security
cp -r system/etc/security/certificates ramdisk/etc/security/
cp system/etc/openssl.cnf ramdisk/etc/
if [ -f "/opt/curl-musl/bin/curl" ]; then cp /opt/curl-musl/bin/curl ramdisk/bin/; fi

# Check if NOTICE.txt match actual files.
# This NOTICE.txt file was copied from system.img and is located in system/etc/NOTICE.txt.
# I removed any open source software that was not included in the container image from the this file.
# When the container image changes, the content inside NOTICE.txt needs to be updated.
temp_a=$(mktemp)
temp_b=$(mktemp)
find ramdisk -type f | sed 's/^ramdisk//' | sort > $temp_a
cat NOTICE.txt | awk NF | grep '^/[a-zA-Z]' | sort > $temp_b
if ! cmp -s $temp_a $temp_b; then
    echo "NOTICE.txt does not match the files in the actual image, NOTICE.txt needs to be updated."
    diff -u $temp_a $temp_b
    exit 1
fi

cp NOTICE.txt ramdisk/etc/
cp -r ramdisk /opt/ramdisk
