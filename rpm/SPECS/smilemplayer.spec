Name:           smilemplayer
Version:        1.5
Release:        1%{?dist}
Summary:        A simple and modern-looking playlist-based local music player

License:        GPL-3.0-only
URL:            https://github.com/SmileLulz/SmileMPlayer
Source0:        %{name}-%{version}.tar.gz

BuildArch:      noarch

BuildRequires:  python3-devel
BuildRequires:  python3-hatchling
BuildRequires:  python3-pip
BuildRequires:  python3-pyside6
BuildRequires:  python3-dbus-next
BuildRequires:  python3-mutagen
BuildRequires:  desktop-file-utils

%generate_buildrequires
%pyproject_buildrequires -r

%description
SmileMPlayer is a simple and modern-looking playlist-based local music
player for Linux, built with PySide6 and Qt6.

%prep
%autosetup

%build
%pyproject_wheel

%install
%pyproject_install

install -Dm644 data/smilemplayer.desktop \
    %{buildroot}%{_datadir}/applications/smilemplayer.desktop

install -Dm644 data/icons/smilemplayer.png \
    %{buildroot}%{_datadir}/icons/hicolor/256x256/apps/smilemplayer.png

%if 0%{?_licensedir:1}
mkdir -p %{buildroot}%{_licensedir}/%{name}
cp -a LICENSES/. %{buildroot}%{_licensedir}/%{name}/
%endif

%check
desktop-file-validate \
    %{buildroot}%{_datadir}/applications/smilemplayer.desktop

%files
%license LICENSE
%license LICENSES/*

%{_bindir}/smilemplayer
%{python3_sitelib}/smilemplayer/
%{python3_sitelib}/smilemplayer-*.dist-info/

%{_datadir}/applications/smilemplayer.desktop
%{_datadir}/icons/hicolor/256x256/apps/smilemplayer.png

%changelog
* Mon Aug 24 2026 SmileLulz <SmileLulz@users.noreply.github.com> - 1.5-1
- Initial Fedora package
