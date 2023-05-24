#!/bin/bash

set -e

xcrun -sdk appletvos clang++ -arch arm64 -Iinclude -F. -framework Foundation -framework IOKit -mappletvos-version-min=9.0 -o TSSAgent TSSSaver.mm
xcrun -sdk appletvos clang++ -arch arm64 -Iinclude -F. -framework Foundation -framework IOKit -mappletvos-version-min=9.0 -o ecid ecid.mm
ldid -Sent.plist TSSAgent
ldid -Sent.plist ecid
#jtool --sign platform --ent ent.plist --inplace TSSAgent
#jtool --sign platform --ent ent.plist --inplace ecid
sudo cp ecid TSSAgent layout/usr/bin/
dpkg-deb -b layout com.nito.tssagent_1.0-3-appletvos-arm64.deb

