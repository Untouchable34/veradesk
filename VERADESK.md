# VeraDesk

VeraDesk, [VeraDesk](https://github.com/rustdesk/rustdesk) (AGPL-3.0) tabanlı, Veranilsoft
tarafından markalanmış ve kendi ID/relay sunucusuna sabitlenmiş bir uzak masaüstü istemcisidir.
Hedef platformlar: Windows, macOS, Android.

Bu depo AGPL-3.0 lisansı altındadır (bkz. `LICENCE`). Üst projenin adı ve logosu bu projede kullanılmaz; yalnızca lisans gereği kaynak
bağlantısı korunur.

## Upstream'e göre değişenler

| Alan | Dosya | Değişiklik |
|---|---|---|
| Uygulama adı | `libs/hbb_common/src/config.rs` (`VERADESK_APP_NAME`) | Üst projenin adı → `VeraDesk`. Config dizinleri, log yolları, servis adları buradan türer. |
| ID sunucusu | `libs/hbb_common/src/config.rs` (`VERADESK_RENDEZVOUS_SERVER`) | `rd.veranilsoft.com` sabit. Kullanıcı ayarlardan değiştirebilir. |
| Sunucu anahtarı | `libs/hbb_common/src/config.rs` (`RS_PUB_KEY`) | **TODO:** sunucudaki `id_ed25519.pub` içeriği. Boşken anahtarsız bağlanır; sunucu `-k _` ile çalışıyorsa bağlantı reddedilir. |
| Org kimliği | `libs/hbb_common/src/config.rs` (`ORG`) | `com.veranilsoft` → `com.veranilsoft` (macOS Preferences dizini). |
| Gömülü ayarlar | `veradesk.json`, `src/common.rs::load_custom_client` | İmzalı `custom.txt` yerine derleme zamanında gömülen JSON. `default-settings` ilk değer, `override-settings` zorunlu değer. |
| Kalıcı şifre | `veradesk.json` | `verification-method=use-permanent-password`, `approve-mode=password`. |
| Şifreyi hatırla | `src/client.rs`, `veradesk.json` (`default-remember-password`) | Bağlantı diyaloğunda "Şifreyi hatırla" yeni cihazlar için de işaretli gelir. |
| Tek adımda bağlan | `flutter/lib/desktop/pages/connection_page.dart`, `flutter/lib/mobile/pages/connection_page.dart` | ID alanının altında şifre alanı; doluysa `connect(password:)` ile gönderilir, boşsa kayıtlı şifre kullanılır. |
| Onaysız bağlantı | `veradesk.json` (`approve-mode=password`, `allow-hide-cm=Y`) | Şifre doğruysa onay penceresi yok, bağlantı yöneticisi paneli de gizli. Ayarlardan geri açılabilir. |
| Sürüm kontrolü | `src/common.rs::do_check_software_update` | üst projenin sürüm API'si yerine GitHub Releases API (`VERADESK_GITHUB_REPO`). |
| Güncelleme indirme | `src/updater.rs` | GitHub allow-list `VERADESK_GITHUB_REPO` deposuna bakar. |
| API sunucusu | `src/common.rs::get_api_server_` | üst projenin yönetim sunucusu yerine `http://rd.veranilsoft.com:21114` (şu an böyle bir servis yok; giriş/adres defteri senkronu devre dışı sayılır). |
| hbb_common | `libs/hbb_common/` | Git submodule kaldırıldı, kod doğrudan depoya alındı. |
| Platform kimlikleri | macOS/iOS/Android proje dosyaları, `build.py`, `res/msi`, `libs/portable` | Bundle id `com.veranilsoft.veradesk`, URL şeması `veradesk://`, çıktı adları `veradesk-*`. |
| İkonlar | `res/`, `flutter/assets/icon.svg`, Android mipmap, `AppIcon.icns` | Veranilsoft logosu. Kaynak: `../branding/logo-source.svg`. |
| CI | `.github/workflows/veradesk-release.yml` | `v*` etiketi push edilince Windows/macOS/Android derleyip GitHub Release'e yükler. |

İkinci turda tüm iç adlar da değiştirildi: cargo crate `veradesk`, kütüphane `libveradesk`,
Windows ikili adı `veradesk.exe`, Android Kotlin paketi `com.veranilsoft.veradesk`, Dart paketi
`veradesk`, dil dosyalarındaki metinler, Linux paket dosyaları. Üst projeye ait dokümanlar ve CI
iş akışları silindi. Kalan tek üst proje izi: Cargo bağımlılıklarının ve CI'da indirilen üçüncü
taraf bileşenlerin (Flutter engine, yazıcı sürücüsü, TopMostWindow) GitHub adresleri ile kod
yorumlarındaki üst proje issue bağlantıları.

## Sunucu

`../server/docker-compose.yml` ile hbbs + hbbr kurulur. Kurulum sonrası:

```
cat server/data/id_ed25519.pub
```

çıktısını `RS_PUB_KEY` sabitine yaz ve yeniden derle.

## Derleme

Toolchain sürümleri `.github/workflows/veradesk-release.yml` içindeki `env:` bloğunda.
Yerel macOS derlemesi için: Rust 1.81, Flutter 3.24.5 (+ `.github/patches` yaması), vcpkg
(`VCPKG_COMMIT_ID`), `brew install nasm cmake ninja pkg-config llvm create-dmg`.

```
brew install nasm cmake ninja pkg-config llvm create-dmg cocoapods
softwareupdate --install-rosetta --agree-to-license   # Flutter 3.24.5 gen_snapshot x86_64
rustup component add rustfmt
cargo install cargo-expand --version 1.0.95 --locked
cargo install flutter_rust_bridge_codegen --version 1.80.1 --features uuid --locked
export VCPKG_ROOT=$HOME/vcpkg
$VCPKG_ROOT/vcpkg install --triplet arm64-osx --x-install-root=$VCPKG_ROOT/installed
flutter_rust_bridge_codegen --rust-input ./src/flutter_ffi.rs --dart-output ./flutter/lib/generated_bridge.dart --c-output ./flutter/macos/Runner/bridge_generated.h --llvm-path /opt/homebrew/opt/llvm
(cd flutter && flutter pub get && dart run build_runner build --delete-conflicting-outputs)
python3 build.py --flutter --hwcodec --unix-file-copy-paste --screencapturekit
```

Çıktı: `flutter/build/macos/Build/Products/Release/VeraDesk.app`. DMG için `res/osx-dist.sh`
veya CI iş akışındaki `create-dmg` komutu. İlk yerel derleme bu makinede 2026-09-12'de
başarıyla alındı (Apple Silicon, ad-hoc imza).

### Android (yerel, Apple Silicon)

```
rustup target add aarch64-linux-android
cargo install cargo-ndk --version 3.1.2 --locked
export ANDROID_NDK_HOME=$HOME/development/android/ndk/28.2.13676358 VCPKG_ROOT=$HOME/vcpkg
./flutter/build_android_deps.sh arm64-v8a
export LIBCLANG_PATH=/opt/homebrew/opt/llvm/lib
export BINDGEN_EXTRA_CLANG_ARGS_aarch64_linux_android="--sysroot=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/darwin-x86_64/sysroot"
# macOS'un ranlib'i ELF arşivlerini indeksleyemez; verilmezse libsodium sembolleri .so'ya
# girmez ve uygulama açılışta "cannot locate symbol sodium_..." ile çöker
export AR_aarch64_linux_android=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/darwin-x86_64/bin/llvm-ar
export AR=$AR_aarch64_linux_android RANLIB=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/darwin-x86_64/bin/llvm-ranlib
./flutter/ndk_arm64.sh          # bin hedefleri de hatasız linklenmeli; link hatası = eksik sembol
mkdir -p flutter/android/app/src/main/jniLibs/arm64-v8a
cp target/aarch64-linux-android/release/liblibveradesk.so flutter/android/app/src/main/jniLibs/arm64-v8a/libveradesk.so
cp $ANDROID_NDK_HOME/toolchains/llvm/prebuilt/darwin-x86_64/sysroot/usr/lib/aarch64-linux-android/libc++_shared.so flutter/android/app/src/main/jniLibs/arm64-v8a/
export JAVA_HOME=$HOME/development/jdk17/Contents/Home ANDROID_HOME=$HOME/development/android
(cd flutter && flutter build apk --release --target-platform android-arm64 --split-per-abi)
```

**Dikkat:** Android bağımlılıkları aynı vcpkg kök dizinine kurulunca manifest modu macOS'un `ffmpeg:arm64-osx` paketini kaldırıyor. Android sonrası macOS derlemesi için repo kökünde `$VCPKG_ROOT/vcpkg install --triplet arm64-osx --x-install-root=$VCPKG_ROOT/installed` komutunu yeniden çalıştır (binary cache sayesinde saniyeler sürer). `--x-install-root` verilmezse paketler repo içindeki `vcpkg_installed/` klasörüne gider ve `hwcodec` ffmpeg başlıklarını bulamaz.

Gradle `cargo`yu çağırdığı için `~/.cargo/bin` PATH'te olmalı. Release imzası
`flutter/android/key.properties` (git dışı) → `~/Desktop/remote/keys/veradesk-release.jks`.

