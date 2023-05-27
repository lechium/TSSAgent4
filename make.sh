#!/bin/bash

set -e

xcrun -sdk appletvos clang++ -arch arm64 -L. -lkbtask -Iinclude -F. -framework Foundation -framework IOKit -mappletvos-version-min=9.0 -o TSSAgent TSSSaver.mm NSURLRequest+cURL.m NSURLRequest+IgnoreSSL.m
xcrun -sdk appletvos clang++ -arch arm64 -Iinclude -F. -framework Foundation -framework IOKit -mappletvos-version-min=9.0 -o ecid ecid.mm
ldid -Sent.plist TSSAgent
ldid -Sent.plist ecid
#jtool --sign platform --ent ent.plist --inplace TSSAgent
#jtool --sign platform --ent ent.plist --inplace ecid
cp ecid TSSAgent layout/fs/jb/usr/bin/
find layout -name .DS_Store | xargs rm -f
dpkg-deb -b layout com.nito.tssagent_1.1-1-appletvos-arm64.deb

