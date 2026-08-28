Name:           smilemplayer
Version:        2.6
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
with LRC sidecar lyrics support, ReplayGain 2.0 support, MPRIS integration, 
fully customizable UI, Material You theme by default, and so on.

%prep
%autosetup -n SmileMPlayer-%{version}

%build
%pyproject_wheel

%install
%pyproject_install

desktop-file-install \
    --dir=%{buildroot}%{_datadir}/applications \
    data/smilemplayer.desktop

install -Dm644 data/icons/smilemplayer.png \
    %{buildroot}%{_datadir}/icons/hicolor/256x256/apps/smilemplayer.png

install -Dm644 data/metainfo/io.github.SmileLulz.SmileMPlayer.metainfo.xml \
    %{buildroot}%{_metainfodir}/io.github.SmileLulz.SmileMPlayer.metainfo.xml

%check
desktop-file-validate \
    %{buildroot}%{_datadir}/applications/smilemplayer.desktop

appstreamcli validate \
    --no-net \
    %{buildroot}%{_metainfodir}/io.github.SmileLulz.SmileMPlayer.metainfo.xml

%files
%doc WIKI.md
%license LICENSE

%{_bindir}/smilemplayer
%{python3_sitelib}/smilemplayer/
%{python3_sitelib}/smilemplayer-*.dist-info/

%{_datadir}/applications/smilemplayer.desktop
%{_datadir}/icons/hicolor/256x256/apps/smilemplayer.png
%{_metainfodir}/io.github.SmileLulz.SmileMPlayer.metainfo.xml

%changelog
* Sat Aug 29 2026 SmileLulz - 2.6-1
- Added Windows build support
- Added a separate `WINDOWS-README.md` for Windows build guide
- Updated `README.md`
- Some useful project changes
