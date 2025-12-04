#!/bin/sh
#License: CC0
#Description: Hypatia conversion script for https://github.com/avast/covid-19-ioc

tail -n +2 datasets/android/*.csv | sed 's/,/ , /' | awk '{ print $1 }' | sort -u  >> avast-covid19-android.sha256
tail -n +2 datasets/windows/*.csv | sed 's/,/ , /' | awk '{ print $1 }' | sort -u  >> avast-covid19-windows.sha256
