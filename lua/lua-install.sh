#!/bin/sh
# Install lua-sci-lang as recommended via ulua

wget -q https://ulua.io/download/ulua~latest.zip
unzip -q ulua~latest.zip
sed -i 's/noconfirm  = false,/noconfirm  = true,/g' ulua/host/config.lua
ulua/bin/upkg add time
ulua/bin/upkg add sci
ulua/bin/upkg add sci-lang
