Name:       veradesk
Version:    1.5.0
Release:    0
Summary:    RPM package
License:    GPL-3.0
URL:        https://veranilsoft.com
Vendor:     veradesk <info@veranilsoft.com>
Requires:   gtk3 libxcb1 libXfixes3 alsa-utils libXtst6 libva2 gstreamer-plugins-base gstreamer-plugin-pipewire
Recommends: libayatana-appindicator3-1 xdotool
Provides:   libdesktop_drop_plugin.so()(64bit), libdesktop_multi_window_plugin.so()(64bit), libfile_selector_linux_plugin.so()(64bit), libflutter_custom_cursor_plugin.so()(64bit), libflutter_linux_gtk.so()(64bit), libscreen_retriever_plugin.so()(64bit), libtray_manager_plugin.so()(64bit), liburl_launcher_linux_plugin.so()(64bit), libwindow_manager_plugin.so()(64bit), libwindow_size_plugin.so()(64bit), libtexture_rgba_renderer_plugin.so()(64bit)

# https://docs.fedoraproject.org/en-US/packaging-guidelines/Scriptlets/

%description
The best open-source remote desktop client software, written in Rust.

%prep
# we have no source, so nothing here

%build
# we have no source, so nothing here

# %global __python %{__python3}

%install

mkdir -p "%{buildroot}/usr/share/veradesk" && cp -r ${HBB}/flutter/build/linux/x64/release/bundle/* -t "%{buildroot}/usr/share/veradesk"
mkdir -p "%{buildroot}/usr/bin"
install -Dm 644 $HBB/res/veradesk.service -t "%{buildroot}/usr/share/veradesk/files"
install -Dm 644 $HBB/res/veradesk.desktop -t "%{buildroot}/usr/share/veradesk/files"
install -Dm 644 $HBB/res/veradesk-link.desktop -t "%{buildroot}/usr/share/veradesk/files"
install -Dm 644 $HBB/res/128x128@2x.png "%{buildroot}/usr/share/icons/hicolor/256x256/apps/veradesk.png"
install -Dm 644 $HBB/res/scalable.svg "%{buildroot}/usr/share/icons/hicolor/scalable/apps/veradesk.svg"

%files
/usr/share/veradesk/*
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
ln -sf /usr/share/veradesk/veradesk /usr/bin/veradesk
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
    rm /usr/bin/veradesk || true
    rmdir /usr/lib/veradesk || true
    rmdir /usr/local/veradesk || true
    rmdir /usr/share/veradesk || true
    rm /usr/share/applications/veradesk.desktop || true
    rm /usr/share/applications/veradesk-link.desktop || true
    update-desktop-database
  ;;
  1)
    # for upgrade
    rmdir /usr/lib/veradesk || true
    rmdir /usr/local/veradesk || true
  ;;
esac
