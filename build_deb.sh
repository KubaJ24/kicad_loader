#!/bin/bash

# Zmienna na nazwę i wersję
PKG_NAME="kicad loader"
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
rm -R ${PKG_NAME}-${PREV_VERSION} ${PKG_NAME}-${PREV_VERSION}.deb

# Struktura katalogów
mkdir -p ${PKG_NAME}-${VERSION}/usr/bin
mkdir -p ${PKG_NAME}-${VERSION}/UBUNTU

# Kopiowanie pliku i ustawienie wykonywalności
cp modbus_rtu_master.py ${PKG_NAME}-${VERSION}/usr/bin/modbus-rtu-master
chmod +x ${PKG_NAME}-${VERSION}/usr/bin/modbus-rtu-master
mkdir -p ${PKG_NAME}-${VERSION}/usr/share/doc/${PKG_NAME}
cp README.txt ${PKG_NAME}-${VERSION}/usr/share/doc/${PKG_NAME}/
chmod 644 ${PKG_NAME}-${VERSION}/usr/share/doc/${PKG_NAME}/README.txt

# Plik kontrolny
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

# Skrypt postinst - instalacja minimalmodbus przez pip3
cat <<'EOF' > ${PKG_NAME}-${VERSION}/UBUNTU/postinst
#!/bin/bash
set -e

exit 0
EOF

chmod +x ${PKG_NAME}-${VERSION}/UBUNTU/postinst

# Budowanie paczki
dpkg-deb --build ${PKG_NAME}-${VERSION}

echo "Paczka zbudowana: ${PKG_NAME}-${VERSION}.deb"