Name:       veradesk
Version:    1.1.9
Release:    0
Summary:    RPM package
License:    GPL-3.0
Requires:   gtk3 libxcb1 libXfixes3 alsa-utils libXtst6 libva2 gstreamer-plugins-base gstreamer-plugin-pipewire
Recommends: libayatana-appindicator3-1 xdotool

# https://docs.fedoraproject.org/en-US/packaging-guidelines/Scriptlets/

%description
The best open-source remote desktop client software, written in Rust.

%prep
# we have no source, so nothing here

%build
# we have no source, so nothing here

%global __python %{__python3}

%install
mkdir -p %{buildroot}/usr/bin/
mkdir -p %{buildroot}/usr/share/veradesk/
mkdir -p %{buildroot}/usr/share/veradesk/files/
mkdir -p %{buildroot}/usr/share/icons/hicolor/256x256/apps/
mkdir -p %{buildroot}/usr/share/icons/hicolor/scalable/apps/
install -m 755 $HBB/target/release/veradesk %{buildroot}/usr/bin/veradesk
install $HBB/libsciter-gtk.so %{buildroot}/usr/share/veradesk/libsciter-gtk.so
install $HBB/res/veradesk.service %{buildroot}/usr/share/veradesk/files/
install $HBB/res/128x128@2x.png %{buildroot}/usr/share/icons/hicolor/256x256/apps/veradesk.png
install $HBB/res/scalable.svg %{buildroot}/usr/share/icons/hicolor/scalable/apps/veradesk.svg
install $HBB/res/veradesk.desktop %{buildroot}/usr/share/veradesk/files/
install $HBB/res/veradesk-link.desktop %{buildroot}/usr/share/veradesk/files/

%files
/usr/bin/veradesk
/usr/share/veradesk/libsciter-gtk.so
/usr/share/veradesk/files/veradesk.service
/usr/share/icons/hicolor/256x256/apps/veradesk.png
/usr/share/icons/hicolor/scalable/apps/veradesk.svg
/usr/share/veradesk/files/veradesk.desktop
/usr/share/veradesk/files/veradesk-link.desktop

%changelog
# let's skip this for now

%pre
# can do something for centos7
case "$1" in
  1)
    # for install
  ;;
  2)
    # for upgrade
    systemctl stop veradesk || true
  ;;
esac

%post
cp /usr/share/veradesk/files/veradesk.service /etc/systemd/system/veradesk.service
cp /usr/share/veradesk/files/veradesk.desktop /usr/share/applications/
cp /usr/share/veradesk/files/veradesk-link.desktop /usr/share/applications/
systemctl daemon-reload
systemctl enable veradesk
systemctl start veradesk
update-desktop-database

%preun
case "$1" in
  0)
    # for uninstall
    systemctl stop veradesk || true
    systemctl disable veradesk || true
    rm /etc/systemd/system/veradesk.service || true
  ;;
  1)
    # for upgrade
  ;;
esac

%postun
case "$1" in
  0)
    # for uninstall
    rm /usr/share/applications/veradesk.desktop || true
    rm /usr/share/applications/veradesk-link.desktop || true
    update-desktop-database
  ;;
  1)
    # for upgrade
  ;;
esac
