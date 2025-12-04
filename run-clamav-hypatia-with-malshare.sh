#!/bin/sh

createCommand(){
printf "sudo clamscan -ior"

find "${PWD}/out/other" -type f \( -name "*.hsb" -o -name "*.hdb" \) | while read line; do
printf " %s %s" "-d" "$line"
done

find "${PWD}/out/malsharebulk" -type f \( -name "*.hsb" -o -name "*.hdb" \) | while read line; do
printf " %s %s" "-d" "$line"
done

#append the dir to scan
printf " %s" "${1}"
}

cd "$(realpath $(dirname ${0}))"

if [ ! -d "${PWD}/out" ]; then
echo "You need to process using get.sh first before running run-clamav-hypatia"
exit
fi

if [ ! -d "$(dirname "${1}")" ] || [ "${1}" = "" ]; then
echo "Argv1: Clamav output txt file"
exit
fi

if [ ! -d "${2}" ] && [ ! -f "${2}" ]; then
echo "Argv2: The directory or file to scan"
exit
fi

echo "Command:" | tee "${1}"
echo | tee "${1}"
createCommand | tee "${1}"
echo | tee "${1}"
echo | tee "${1}"
echo | tee "${1}"
$(createCommand "${2}") | tee "${1}"

#####PLAY COMPLETION SOUND#######

if [ "$(which paplay)" != "" ]; then
	if [ -f "/usr/share/sounds/freedesktop/stereo/complete.oga" ]; then
		paplay "/usr/share/sounds/freedesktop/stereo/complete.oga"
	fi
fi