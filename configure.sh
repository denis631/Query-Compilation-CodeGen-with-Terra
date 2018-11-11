#!/bin/sh

case "$(uname -s)" in
    Linux*)                 link="https://github.com/zdevito/terra/releases/download/release-2016-03-25/terra-Linux-x86_64-332a506.zip";;
    Darwin*)                link="https://github.com/zdevito/terra/releases/download/release-2016-03-25/terra-OSX-x86_64-332a506.zip";;
    CYGWIN*|MINGW32*|MSYS*) link="https://github.com/zdevito/terra/releases/download/release-2016-03-25/terra-Windows-x86_64-332a506.zip";;
    *)                      link="";;
esac

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
DataDIR="$(echo "$DIR/data")"
TerraDIR="$(echo "$DIR/terra")"
DataURL="https://db.in.tum.de/teaching/ws1718/imlab/tpcc_5w.tar.gz"

mkdir -p $DataDIR
mkdir -p $TerraDIR

echo "Downloading Terra sources ..."
curl -sL $link > terra.zip
echo "Unzipping ..."
tar zxf terra.zip -C $TerraDIR --strip-components=1
rm terra.zip

echo "Downloading tpcc data ..."
curl -s $DataURL | tar xz -C $DataDIR

echo "DONE"