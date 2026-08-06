#!/bin/bash
set -e

rm -rf deb_dist plezy_1.0.0_amd64.deb

mkdir -p deb_dist/DEBIAN
mkdir -p deb_dist/usr/lib/plezy
mkdir -p deb_dist/usr/bin
mkdir -p deb_dist/usr/share/applications
mkdir -p deb_dist/usr/share/icons/hicolor/256x256/apps

cp -r build/linux/x64/release/bundle/* deb_dist/usr/lib/plezy/
ln -sf /usr/lib/plezy/plezy deb_dist/usr/bin/plezy

if [ -f assets/icon/icon.png ]; then
  cp assets/icon/icon.png deb_dist/usr/share/icons/hicolor/256x256/apps/plezy.png
fi

cat <<DESKTOP > deb_dist/usr/share/applications/plezy.desktop
[Desktop Entry]
Name=Plezy
Comment=Jellyfin and Emby Media Client
Exec=/usr/bin/plezy
Icon=plezy
Terminal=false
Type=Application
Categories=AudioVideo;Player;
DESKTOP

cat <<CONTROL > deb_dist/DEBIAN/control
Package: plezy
Version: 1.0.0
Architecture: amd64
Maintainer: Oguz <oguz@localhost>
Description: Plezy Media Player for Linux (Jellyfin/Emby client)
Section: utils
Priority: optional
CONTROL

dpkg-deb --build deb_dist plezy_1.0.0_amd64.deb
rm -rf deb_dist
echo "🎉 DEB paketi başarıyla oluşturuldu: plezy_1.0.0_amd64.deb"
