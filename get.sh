#!/bin/sh

OLD_UMASK="$(umask)"
umask 0022

######FUNCTIONS######

csvToHSB(){
	if [ -f "$3" ]; then
		rm "$3"
	fi


	if [ ! -f "$1" ]; then
		echo "Argv 1: The csv of the malware dataset"
		exit
	fi

	if [ "$2" = "" ]; then
		echo "Arg2: Malware csv dataset name"
		exit
	fi

	if [ ! -d "$(dirname "$3")" ] || [ "$3" = "" ]; then
		echo "Arg3: The output hsb file"
		exit
	fi

	while read line; do
		linelength="$(printf "%s" "$line" | wc -c)"
		#check line length is that of base64 sha256,sha1,md5 sum
		if [ "$linelength" = "64" ] || [ "$linelength" = "40" ] || [ "$linelength" = "32" ] ; then
			echo "$line:*:Unidentified $2 potential malware:73" >> "$3"
		fi
	done < "$1"

}

#####MAIN#######

thepwd="$(realpath $(dirname "$0"))"

git clone "https://github.com/MaintainTeam/Hypatia"

cp -a Hypatia/scripts build

cd build

builddir="$PWD"

#0avast-covid19.sh
git clone "https://github.com/avast/covid-19-ioc"
cd "${builddir}"
cp -a "${thepwd}/0avast-covid19.sh" "${builddir}/0avast-covid19.sh"
cd covid-19-ioc
chmod +x "${builddir}/0avast-covid19.sh"
sh "${builddir}/0avast-covid19.sh"
find . -mindepth 1 -maxdepth 1 -name "*.sha256" | while read shafile; do
	shafilename="$(basename "${shafile}")"
	echo "Processing ${shafilename} ..."
	csvToHSB "$shafile" "${shafilename%???????}" "${shafilename%???????}.hsb"
done
cd "${builddir}"

#0clamav.sh
mkdir -p clamav
cd clamav
mkdir -p raw
mkdir -p exclusions
chmod +x "${builddir}/0clamav.sh"
sh "${builddir}/0clamav.sh"
cd "${builddir}"

###0cybercure.sh is broken
##mkdir -p cybercure
##cd cybercure
##chmod +x ../0cybercure.sh
##../0cybercure.sh
##cd ..

#0eset.sh
git clone https://github.com/eset/malware-ioc
cd malware-ioc
chmod +x "${builddir}/0eset.sh"
bash "${builddir}/0eset.sh"
echo "Processing eset.md5 ..."
csvToHSB "eset.md5" "eset.md5" "eset.md5.hsb"
echo "Processing eset.sha1 ..."
csvToHSB "eset.sha1" "eset.sha1" "eset.sha1.hsb"
echo "Processing eset.sha256 ..."
csvToHSB "eset.sha256" "eset.sha256" "eset.sha256.hsb"
cd "${builddir}"

#0genbloom.sh
#???

#0malshare-bulk.sh and 0malshare-combine.sh
mkdir -p malsharebulk
cd malsharebulk
chmod +x "${builddir}/0malshare-bulk.sh"
sh "${builddir}/0malshare-bulk.sh" | tee urls.txt

if [ -f "urls.txt" ]; then
	while read line; do
		echo "Getting $line ..."
		wget "$line"
	done < urls.txt

	mkdir -p raw-extended

	#0malshare-combine
	if [ -f "${builddir}/0malshare-combine.sh" ]; then
		rm "${builddir}/0malshare-combine.sh"
	fi
	cp -a "${thepwd}/0malshare-combine.sh" "${builddir}/0malshare-combine.sh"
	chmod +x "${builddir}/0malshare-combine.sh"
	sh "${builddir}/0malshare-combine.sh"
fi

find . -type f -empty -exec rm {} \;

cd "${builddir}/malsharebulk/raw-extended"
find . -maxdepth 1 -mindepth 1 -name "*.md5" | while read md5file; do
	md5filename="$(basename "${md5file}")"
	echo "Processing ${md5filename} ..."
	#if statement to eliminate corrupt files
	if [ "$(file "${md5file}" | rev | cut -d ' ' -f 1 | rev)" != "data" ]; then
		csvToHSB "$md5file" "${md5filename%????}" "${md5filename%????}.hsb"
	fi
done

cd "${builddir}"

#0sanesecurity.sh
mkdir -p sanesecurity-real
cd  sanesecurity-real
rsync -av rsync://rsync.sanesecurity.net/sanesecurity .
cd ..
mkdir -p raw
chmod +x "${builddir}/0sanesecurity.sh"
sh "${builddir}/0sanesecurity.sh"
mv raw sanesecurity-real
cd "${builddir}"

#0stalkerware.sh
git clone https://github.com/AssoEchap/stalkerware-indicators
cd stalkerware-indicators
chmod +x "${builddir}/0stalkerware.sh"
sh "${builddir}/0stalkerware.sh"
cd "${builddir}"

#0targetedthreats.sh
git clone https://github.com/botherder/targetedthreats
cd targetedthreats
chmod +x "${builddir}/0targetedthreats.sh"
bash "${builddir}/0targetedthreats.sh"
cd "${builddir}"

#0threatfox.sh
mkdir -p threatfox
cd threatfox
wget -H -e robots=off -U "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Safari/537.36" https://threatfox.abuse.ch/export/csv/sha256/full/ -O out.zip
unzip out.zip
mv *.sha256 full_sha256.csv
chmod +x "${builddir}/0threatfox.sh"
sh "${builddir}/0threatfox.sh"
echo "Processing threatfox ..."
csvToHSB "threatfox.sha256" "threatfox" "threatfox.hsb"
cd "${builddir}"

#0threatview.sh
mkdir -p threatview/raw
cd threatview
chmod +x ../0threatview.sh
../0threatview.sh
cd raw
echo "Processing threatview.md5 ..."
csvToHSB "threatview.md5" "threatview.md5" "threatview.md5.hsb"
echo "Processing threatview.sha1 ..."
csvToHSB "threatview.sha1" "threatview.sha1" "threatview.sha1.hsb"
cd "${builddir}"

######FINALISE#########

buildoutdir="${thepwd}/out"

if [ -d "${buildoutdir}" ] && [ "${thepwd}" != "" ]; then
	rm -rf "${buildoutdir}"
fi

mkdir -p "${buildoutdir}/other"
mkdir -p "${buildoutdir}/malsharebulk"

find "${builddir}/clamav/raw" -type f \( -name "*.hsb" -o -name "*.hdb" \) | while read clamavdef; do
cp -a "${clamavdef}" "${buildoutdir}/other/clamav-$(basename "$clamavdef")"
done

find "${builddir}/covid-19-ioc" -maxdepth 1 -mindepth 1 -type f \( -name "*.hsb" -o -name "*.hdb" \) -exec cp -a "{}" "${buildoutdir}/other" \;

find "${builddir}/malsharebulk/raw-extended" -type f \( -name "*.hsb" -o -name "*.hdb" \) -exec cp -a "{}" "${buildoutdir}/malsharebulk" \;

find "${builddir}/malware-ioc" -maxdepth 1 -mindepth 1 -type f \( -name "*.hsb" -o -name "*.hdb" \) -exec cp -a "{}" "${buildoutdir}/other" \;

find "${builddir}/sanesecurity-real/raw" -type f \( -name "*.hsb" -o -name "*.hdb" \) | while read sanesecuritydef; do
grep -v "^$" "$sanesecuritydef" > "${buildoutdir}/other/$(basename ${sanesecuritydef})"
done

find "${builddir}/stalkerware-indicators" -maxdepth 1 -mindepth 1 -type f \( -name "*.hsb" -o -name "*.hdb" \) | while read stalkerwaredef; do
	while read swline; do
		swnum="$(echo "${swline}" | cut -d ':' -f 2)"
		if [ "$swnum" = "0" ]; then
			printf "%s:*:%s:73\n" "$(printf "${swline}" | cut -d ':' -f 1)" "$(printf "${swline}" | cut -d ':' -f 3)" >> "${buildoutdir}/other/$(basename ${stalkerwaredef})"
		else
			printf "%s:*:%s:%s\n" "$(printf "${swline}" | cut -d ':' -f 1)" "$(printf "${swline}" | cut -d ':' -f 3)" "${swnum}" >> "${buildoutdir}/other/$(basename ${stalkerwaredef})"
		fi
	done < "${stalkerwaredef}"
done

find "${builddir}/targetedthreats" -maxdepth 1 -mindepth 1 -type f \( -name "*.hsb" -o -name "*.hdb" \) | while read targetedthreatsdef; do
	while read ttline; do
		ttnum="$(echo "${ttline}" | cut -d ':' -f 2)"
		if [ "$ttnum" = "0" ]; then
			printf "%s:*:%s:73\n" "$(printf "${ttline}" | cut -d ':' -f 1)" "$(printf "${ttline}" | cut -d ':' -f 3)" >> "${buildoutdir}/other/$(basename ${targetedthreatsdef})"
		else
			printf "%s:*:%s:%s\n" "$(printf "${ttline}" | cut -d ':' -f 1)" "$(printf "${ttline}" | cut -d ':' -f 3)" "${ttnum}" >> "${buildoutdir}/other/$(basename ${targetedthreatsdef})"
		fi
	done < "${targetedthreatsdef}"
done

find "${builddir}/threatfox" -maxdepth 1 -mindepth 1 -type f \( -name "*.hsb" -o -name "*.hdb" \) | while read threatfoxdef; do
	cat "${threatfoxdef}" | grep -v "^87083882cc6015984eb0411a99d3981817f5dc5c90ba24f0940420c5548d82de.*" | grep -v "^186c92b5b0fe414c285181ea1529361a30291480f7d5f1cc47e98bedcbb9f6c2.*" > "${buildoutdir}/other/$(basename "${threatfoxdef}")"
done

find "${builddir}/threatview/raw" -type f \( -name "*.hsb" -o -name "*.hdb" \) -exec cp -a "{}" "${buildoutdir}/other" \;

#####PLAY COMPLETION SOUND#######

if [ "$(which paplay)" != "" ]; then
	if [ -f "/usr/share/sounds/freedesktop/stereo/complete.oga" ]; then
		paplay "/usr/share/sounds/freedesktop/stereo/complete.oga"
	fi
fi

umask "${OLD_UMASK}"