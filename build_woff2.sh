#!/bin/bash
# this repo contains a prebuilt version of woff2.
# this rebuilds the version.
# woff2 revision 4721483ad780ee2b63cb787bfee4aa64b61a0446.
set -e
rm -rf woff2/build || true
mkdir woff2/build
cd woff2/build
cmake .. -G Ninja \
	-DCMAKE_SYSTEM_NAME=iOS \
	-DCMAKE_OSX_DEPLOYMENT_TARGET=14.0 \
	-DCMAKE_OSX_ARCHITECTURES=arm64 \
	-DBROTLIDEC_INCLUDE_DIRS=../brotli/c/include \
	-DBROTLIDEC_LIBRARIES="FAKEFAKEFAKE" \
	-DBROTLIENC_INCLUDE_DIRS=../brotli/c/include \
	-DBROTLIENC_LIBRARIES="FAKEFAKEFAKE" \
	-DBUILD_SHARED_LIBS=NO \
	-DCMAKE_MACOSX_BUNDLE=OFF
ninja woff2enc
cp woff2/build/libwoff2common.a woff2/build/libwoff2enc.a WDBFontOverwrite/
