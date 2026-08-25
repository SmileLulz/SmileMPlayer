Name:           smilemplayer
Version:        1.8.b9
Release:        1%{?dist}
Summary:        Modern playlist-based local music player

License:        GPL-3.0-only
URL:            https://github.com/SmileLulz/SmileMPlayer
Source0:        https://github.com/SmileLulz/SmileMPlayer/archive/refs/tags/v%{version}.tar.gz

BuildArch:      noarch

BuildRequires:  python3-devel
BuildRequires:  python3-hatchling
BuildRequires:  python3-pip
BuildRequires:  desktop-file-utils
BuildRequires:  appstream

%generate_buildrequires
%pyproject_buildrequires -r

%description
SmileMPlayer is a simple and modern playlist-based local music player for Linux
with ReplayGain support, MPRIS integration, fully customizable UI,
Material You theme by default, and more.

%prep
%autosetup -n SmileMPlayer-%{version}

%build
%pyproject_wheel

%install
%pyproject_install

rm -rf %{buildroot}%{python3_sitelib}/smilemplayer/__pycache__/
rm -rf %{buildroot}%{python3_sitelib}/smilemplayer/core/__pycache__/

desktop-file-install \
    --dir=%{buildroot}%{_datadir}/applications \
    data/smilemplayer.desktop

install -Dm644 data/icons/smilemplayer.png \
    %{buildroot}%{_datadir}/icons/hicolor/256x256/apps/smilemplayer.png

install -Dm644 data/metainfo/com.smilelulz.SmileMPlayer.metainfo.xml \
    %{buildroot}%{_metainfodir}/com.smilelulz.SmileMPlayer.metainfo.xml

%check
desktop-file-validate \
    %{buildroot}%{_datadir}/applications/smilemplayer.desktop

appstreamcli validate \
    --no-net \
    %{buildroot}%{_metainfodir}/com.smilelulz.SmileMPlayer.metainfo.xml

%files
%doc WIKI.md
%license LICENSE

%{_bindir}/smilemplayer
%{python3_sitelib}/smilemplayer/
%{python3_sitelib}/smilemplayer-*.dist-info/

%{_datadir}/applications/smilemplayer.desktop
%{_datadir}/icons/hicolor/256x256/apps/smilemplayer.png
%{_metainfodir}/com.smilelulz.SmileMPlayer.metainfo.xml

%changelog
* Tue Aug 25 2026 SmileLulz - 1.8.b9-1
- Version bump to 1.8.b9

