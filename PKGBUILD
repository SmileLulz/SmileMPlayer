# Maintainer: SmileLulz <SmileLulz@users.noreply.github.com>
# Contributor: SmileLulz

pkgname=smilemplayer
pkgver=0.7.6
pkgrel=1
pkgdesc="A simple and modern-looking playlist-based local music player for Linux"
arch=('any')
url="https://github.com/SmileLulz/SmileMPlayer"
license=('GPL-3.0-only')

depends=(
    'python>=3.10'
    'pyside6>=6.8'
    'python-mutagen>=1.47'
    'qt6-multimedia-gstreamer'
    'gst-plugins-base'
    'gst-plugins-good'
    'gst-plugins-bad'
)

optdepends=('gst-libav')

makedepends=(
    'python-hatchling'
    'python-build'
    'python-installer'
    'python-wheel'
)

source=()
sha256sums=()

build() {
    cd "$startdir"
    python -m build --wheel --no-isolation
}

package() {
    cd "$startdir"

    python -m installer --destdir="$pkgdir" dist/*.whl

    install -Dm644 data/icons/smilemplayer.png \
        "$pkgdir/usr/share/icons/hicolor/256x256/apps/smilemplayer.png"

    install -Dm644 data/smilemplayer.desktop \
        "$pkgdir/usr/share/applications/smilemplayer.desktop"

    install -Dm644 LICENSE \
        "$pkgdir/usr/share/licenses/$pkgname/LICENSE"
}

# cat > smilemplayer.desktop << EOF
# [Desktop Entry]
# Name=SmileMPlayer
# Comment=Simple local music player
# Exec=smilemplayer
# Icon=smilemplayer
# Terminal=false
# Type=Application
# Categories=AudioVideo;Player;
# MimeType=audio/mpeg;audio/flac;audio/ogg;audio/opus;audio/x-m4a;audio/aac;audio/wav;
# EOF
