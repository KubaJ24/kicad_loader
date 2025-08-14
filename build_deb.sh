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
mkdir -p ${PKG_NAME}-${VERSION}/usr/share/kicad_loader
mkdir -p ${PKG_NAME}-${VERSION}/etc/systemd/system

chmod 755 ${PKG_NAME}-${VERSION}/DEBIAN

# Pliki aplikacji
cp kicad_loader.py ${PKG_NAME}-${VERSION}/usr/bin/kicad_loader/
chmod +x ${PKG_NAME}-${VERSION}/usr/bin/kicad_loader/kicad_loader.py
cp config.json ${PKG_NAME}-${VERSION}/usr/share/kicad_loader
chmod +rw ${PKG_NAME}-${VERSION}/usr/share/kicad_loader/config.json
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

if [ -n "$SUDO_USER" ] && [ "$SUDO_USER" != "root" ]; then
    USER_HOME=$(eval echo "~$SUDO_USER")
    if [ ! -f "$USER_HOME/.config/kicad_loader/config.json" ]; then
        mkdir -p "$USER_HOME/.config/kicad_loader"
        cp /usr/share/kicad_loader/config.json "$USER_HOME/.config/kicad_loader/"
        chown -R "$SUDO_USER":"$SUDO_USER" "$USER_HOME/.config/kicad_loader"
        echo "Konfiguracja została skopiowana do $USER_HOME/.config/kicad_loader/"
    else
        echo "Znaleziono plik 'config.json' w $USER_HOME/.config/kicad_loader/"
fi
fi

read -p "Czy chcesz zainstalować i uruchomić usługę kicad-loader w systemd? (y/N): " choice
case "$choice" in
    y|Y )
        systemctl daemon-reload
        systemctl enable kicad-loader.service
        echo "Usługa kicad-loader enabled"
        echo "Do oglądania logów: sudo journalctl -u kicad-loader.service -f"
        ;;
    * )
        echo "Pominięto instalację usługi systemd."
        ;;
esac

exit 0
EOF
chmod +x ${PKG_NAME}-${VERSION}/DEBIAN/postinst

sudo chmod 755 ${PKG_NAME}-${VERSION}/DEBIAN
# Budowanie paczki
dpkg-deb --build ${PKG_NAME}-${VERSION}
echo "Paczka zbudowana: ${PKG_NAME}-${VERSION}.deb"

