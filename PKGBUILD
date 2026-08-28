# Maintainer: SmileLulz <SmileLulz@users.noreply.github.com>

pkgname=smilemplayer
pkgver=2.6.b1
pkgrel=1
pkgdesc="A simple and modern-looking playlist-based local music player for Linux"
arch=('any')
url="https://github.com/SmileLulz/SmileMPlayer"
license=('GPL-3.0-only')

depends=(
    'python>=3.10'
    'pyside6>=6.8'
    'python-mutagen>=1.47'
    'python-dbus-next>=0.2.3'
    'qt6-multimedia-ffmpeg'
    'ttf-jetbrains-mono-nerd'
)

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
