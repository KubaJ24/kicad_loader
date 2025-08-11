#!/bin/bash

set -e

PKG_NAME="kicad-loader"
VERSION=$1
PREV_VERSION=$2
ARCH="all"

if [[ "$VERSION" == "--help" ]]; then
    echo "Użycie: ./build_deb.sh <nowa_wersja> <stara_wersja>"
    exit
fi

echo "Deb builder for ${PKG_NAME}"

# Czyszczenie
rm -rf ${PKG_NAME}-${VERSION} ${PKG_NAME}-${VERSION}.deb
rm -rf ${PKG_NAME}-${PREV_VERSION} ${PKG_NAME}-${PREV_VERSION}.deb

# Struktura katalogów
mkdir -p ${PKG_NAME}-${VERSION}/usr/bin/kicad_loader
mkdir -p ${PKG_NAME}-${VERSION}/DEBIAN
mkdir -p /tmp/kicad-loader-tmp
mkdir -p ${PKG_NAME}-${VERSION}/etc/kicad_loader
mkdir -p ${PKG_NAME}-${VERSION}/etc/systemd/system

# Pliki aplikacji
cp kicad_loader.py ${PKG_NAME}-${VERSION}/usr/bin/kicad_loader/
chmod +x ${PKG_NAME}-${VERSION}/usr/bin/kicad_loader/kicad_loader.py
cp config.json ${PKG_NAME}-${VERSION}/etc/kicad_loader
chmod +rw ${PKG_NAME}-${VERSION}/etc/kicad_loader
cp kicad-loader.service ${PKG_NAME}-${VERSION}/etc/systemd/system

# Wrapper w usr/bin
cat <<EOF > ${PKG_NAME}-${VERSION}/usr/bin/kicad-loader
#!/bin/bash
python3 /usr/bin/kicad_loader/kicad_loader.py "\$@"
EOF
chmod +x ${PKG_NAME}-${VERSION}/usr/bin/kicad-loader

# Plik control
cat <<EOF > ${PKG_NAME}-${VERSION}/DEBIAN/control
Package: ${PKG_NAME}
Version: ${VERSION}
Section: utils
Priority: optional
Architecture: ${ARCH}
Depends: python3
Maintainer: KubaJ24
Description: kicad loader for Linux
EOF

# postinst
cat <<'EOF' > ${PKG_NAME}-${VERSION}/DEBIAN/postinst
#!/bin/bash
set -e
exit 0
EOF
chmod +x ${PKG_NAME}-${VERSION}/DEBIAN/postinst

# Budowanie paczki
dpkg-deb --build ${PKG_NAME}-${VERSION}
echo "Paczka zbudowana: ${PKG_NAME}-${VERSION}.deb"

