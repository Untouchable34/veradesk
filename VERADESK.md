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
export VCPKG_ROOT=$HOME/vcpkg
python3 build.py --flutter
```
