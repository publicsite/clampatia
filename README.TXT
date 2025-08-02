#### Description ####

Run clamav virus checker using malware signatures processed via hypatia.

#### Get dependencies; for running and/or rebuilding ####

sudo apt-get install -y rsync dos2unix clamav sudo git unzip wget bash
sudo -i freshclam

#### To run ####

./run-clamav-hypatia-withOUT-malshare.sh "clamavout.txt" "/"

#you can also run with malsharebulk defintions, but I got quite a few false positives this way ...

./run-clamav-hypatia-with-malshare.sh "clamavout.txt" "/"

#### Rebuilding ####

To rebuild, run get.sh . Note: Normally you don't actually have to do this, because the output has been included within this repo! It will [also] take a long time.
