#!/bin/bash

rm -rf build
rm -rf /usr/local/include/fues3
mkdir build
cd build
meson
ninja
sudo ninja install
cd ../
