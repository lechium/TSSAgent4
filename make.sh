#!/bin/bash

set -e

xcrun -sdk appletvos clang++ -arch arm64 -Iinclude -F. -framework Foundation -framework IOKit -o TSSAgent TSSSaver.mm 
cp TSSAgent layout/usr/bin/
dpkg-deb -b layout com.nito.tssagent_1.0-appletvos-arm64.deb

