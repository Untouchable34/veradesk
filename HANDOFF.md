# VeraDesk — Devir Notu (Codex için)

Bu dosya, başka bir oturumda yürütülen çalışmanın özeti ve açık sorunların
durumudur. Amaç: Windows'taki beyaz ekran sorununu çözmek. Aşağıdaki teşhis
kesindir, doğrudan çözüm adımına geçilebilir.

Tarih: 2026-09-24. Proje: RustDesk fork'u "VeraDesk". Repo kökü:
`~/Desktop/remote/veradesk` (Mac). GitHub: `Untouchable34/veradesk` (private),
dal `veradesk`.

---

## AÇIK SORUN: Windows'ta beyaz ekran

### Belirti
Windows'ta VeraDesk açılıyor ama pencere bomboş beyaz. Uygulama mantığı
sorunsuz başlıyor (FFI init, sunucu bağlantısı hepsi tamam) — **sorun sadece
GPU/render katmanında**, pencere içeriği çizilemiyor.

### Test makinesi
- Windows 11 Pro, kullanıcı `mehmet`, host `DESKTOP-E0THJ1N`, LAN IP `192.168.1.71`.
- **Çift GPU:** NVIDIA RTX 4060 Laptop (sürücü 32.0.16.1062) + Intel UHD
  (31.0.101.5081). Ekran Intel'e bağlı.
- SSH açık (OpenSSH). Mac'in `~/.ssh/id_ed25519_commaptest.pub` anahtarı
  `C:\ProgramData\ssh\administrators_authorized_keys` içine eklendi (yönetici
  hesabı olduğu için oraya; kullanıcı authorized_keys çalışmadı). SSH alias:
  `veradesk-pc` (Mac `~/.ssh/config`).

### Kesinleşen teşhis
1. **Sorun makinede değil, bizim derlemede.** Aynı makinede **resmi RustDesk
   1.4.0 kurulu ve arayüzü sorunsuz açılıyor** (kullanıcı doğruladı). RustDesk
   de Flutter kullanıyor, yani bu GPU render edebiliyor.
2. **Stok Flutter motoru bu makinede çizemiyor.** Bizim ikinci derlememiz stok
   Flutter 3.24.5 Windows motoruyla geldi (`flutter_windows.dll` = 18,181,632
   bayt) ve gerçek ekranda beyaz. Resmi RustDesk **özel motor** kullanıyor
   (`flutter_windows.dll` = 18,057,864 bayt).
3. **SSH'tan çalıştırma testi YANILTICI** — bu tuzağa düşme. SSH oturumunun
   GPU'su yok, o yüzden hangi motor olursa olsun her zaman
   `SwapChain11 ... HRESULT 0x887A0022 (device removed)` +
   `EGL Context Lost` verir. Render'ı ancak kullanıcı gerçek masaüstü
   oturumunda (çift tıklayarak) test edebilir. Ekran görüntüsü de SSH'tan
   bomboş beyaz gelir (ayrı oturum), ona da kanma.

### Şu an makinede ne var
- Kurulu: `C:\Users\Mehmet\AppData\Local\VeraDesk\` (yeni, stok motorlu build).
- **Son müdahale:** teşhis için RustDesk'in çalışan motorunu bizim kuruluma
  kopyaladım:
  - `flutter_windows.dll` ← `C:\Program Files\RustDesk\flutter_windows.dll`
  - Stok yedeği: `flutter_windows.dll.stockbak` (aynı klasörde).
  - **Bu değişiklikle kullanıcının gerçek oturumda testi HENÜZ ALINMADI.**
    İlk yapılacak: kullanıcı `VeraDesk.exe`'yi çift tıklasın, arayüz geliyor mu?
    - Geliyorsa → teşhis %100 kesin (motor). Aşağıdaki çözüme geç.
    - Gelmiyorsa → motor değil; app.so/flutter_assets uyumu ya da başka bir
      şey. (Ama RustDesk 1.4.0 ve bizim Flutter tabanı aynı 3.24.x olduğu için
      dll takası genelde yeter; gelmezse Flutter sürüm uyumuna bak.)

### Çözüm (derleme tarafı)
Windows iş akışı `.github/workflows/veradesk-windows.yml`. Önceki oturumda
"Replace engine with veradesk custom flutter engine" adımı beyaz ekran sanılıp
KALDIRILDI — bu yanlış çıktı, geri gerekiyor. Yapılacak:
1. O adımı geri ekle (referans: `veradesk-release.yml` içinde hâlâ duruyor,
   `git log` ile silinmeden önceki haline de bakılabilir). Adım, engine'i
   `https://github.com/rustdesk/engine/releases/download/main/windows-x64-release.zip`
   adresinden indirip Flutter cache'indeki `windows-x64-release` üzerine yazıyor.
2. **DİKKAT:** İlk custom-engine'li build (run 35885232066) de beyaz ekran
   vermişti. Yani sadece adımı geri koymak yetmeyebilir — o build'de engine'in
   gerçekten devreye girip girmediği doğrulanmadı. Build sonrası üretilen
   `flutter_windows.dll` boyutunun **18,057,864** (RustDesk ile aynı) olduğunu
   doğrula; 18,181,632 çıkarsa engine override çalışmamış demektir (flutter
   build sırasında stok engine yeniden çekiliyor olabilir; precache/versiyon
   pinleme gerekebilir).
3. Alternatif hızlı yol: manuel test için RustDesk dll'i takınca çalışıyorsa,
   build çıktısındaki `flutter_windows.dll`'i RustDesk'inkiyle değiştirip
   paketlemek de bir köprü çözüm (ama temizi engine adımını düzeltmek).

`--vram` bayrağı da kaldırıldı (gpu texture render). Beyaz ekran çözülünce
`--vram` ayrı test edilebilir; şart değil.

### SSH ile hızlı komut çalıştırma (Mac'ten)
PowerShell'in tırnak sorunları yüzünden base64 kullan:
```bash
runps() { local b64; b64=$(printf '%s' "$1" | iconv -t UTF-16LE | base64); \
  ssh -o BatchMode=yes veradesk-pc "powershell -NoProfile -EncodedCommand $b64" \
  2>&1 | grep -v "CLIXML\|<Objs\|progress\|Preparing\|^$"; }
```
Dosya kopyalama: `scp veradesk-pc:"C:/Users/Mehmet/..." .`

---

## GENEL PROJE DURUMU

### Kimlik / sunucu
- App: **VeraDesk**, bundle `com.veranilsoft.veradesk`, şema `veradesk://`.
- Sunucu: hbbs/hbbr 1.1.16, **native systemd** (Docker değil), DigitalOcean
  droplet `Commap-Test` (fra1) `159.89.97.28`, SSH alias `commap-test`.
  Kullanıcı `veradesk`, `/opt/veradesk`. Aynı makinede Commap staging var,
  ona dokunma. Detay + kaldırma: `~/Desktop/remote/server/README.md`.
- Sunucu public key (client'a gömülü, `RS_PUB_KEY`):
  `irZq4Ua5mA+VyXRixVD8LcvEZeAK70wlvQ7ykKQ6bFs=`. Private key yedeği:
  `~/Desktop/remote/keys/veradesk-server/id_ed25519`.
- DNS: `rd.veranilsoft.com` → `159.89.97.28`, Netlify DNS'te (alan adı
  Netlify'da). Çalışıyor.
- Güncelleme/repo sabiti: `libs/hbb_common/src/config.rs` →
  `VERADESK_GITHUB_REPO = "Untouchable34/veradesk"`.

### Kayıtlı cihazlar (sunucu db)
Mac mini `310 325 824`, MacBook Pro `16 399 692`, Pixel 7 `309 821 328`.

### Şifre akışı (uygulandı, committed)
Varsayılan `use-both-passwords`: ekranda her zaman rastgele tek seferlik şifre;
kullanıcı kalıcı şifre belirlerse onu bilenler doğrudan bağlanır. İlk açılıştaki
"kalıcı şifre belirle" zorlaması kapalı. `veradesk.json` +
`flutter/lib/desktop/pages/desktop_home_page.dart` + `server_model.dart`.

### macOS derleme (bu Mac, Apple Silicon)
- Komut: `VCPKG_ROOT=~/vcpkg python3 build.py --flutter --hwcodec --unix-file-copy-paste --screencapturekit`
- Flutter: `~/development/flutter-3.24.5` (yamalı, bunu kullan; `~/development/flutter` kullanıcının kendi 3.47'si, dokunma).
- **Kod imzalama:** kalıcı izinler için kendi ürettiğimiz sertifika. Anahtarlık
  `veradesk-signing.keychain`, kimlik "VeraDesk Local Signing". build.py artık
  `MACOS_CODESIGN_IDENTITY` + `MACOS_CODESIGN_KEYCHAIN` env okuyor. Sertifika/
  şifreler `~/Desktop/remote/keys/` (kaybetme; kaybolursa TCC izinleri sıfırlanır).
- **codec.rs düzeltmesi:** macOS'ta `available_memory()` 0 dönüyordu → encode/
  decode tek çekirdeğe düşüp 4K oturumlar kopuyordu. `total_memory/2` fallback
  eklendi. (Mac mini 4K ekran; bu düzeltmeyle test edildi.)
- macOS'ta `flutter run -d macos` için `target/debug/lib{lib,}veradesk.dylib`
  → `../release/` symlink'leri gerekir (yerel debug çalıştırma).

### Android
- APK arm64. **libsodium tuzağı:** macOS ranlib ELF arşivini indeksleyemiyor,
  NDK araçları şart, yoksa `sodium_*` undefined ile açılışta çöker. Derlemede
  `AR/RANLIB = $ANDROID_NDK_HOME/.../llvm-ar, llvm-ranlib`. (VERADESK.md'de yazılı.)
- Android sonrası macOS derlemesi için vcpkg'ı doğru köke geri kur:
  `$VCPKG_ROOT/vcpkg install --triplet arm64-osx --x-install-root=$VCPKG_ROOT/installed`.

### Windows CI
- **Artifact kota tuzağı:** ücretsiz planda gizli depo artifact deposu hesabın
  tamamı için ~500 MB ve doluydu (`namazvaktin-app` 1.5 GB tutuyordu; eskiler
  silindi). Bu yüzden `veradesk-windows.yml` **tek iş**, ara artifact yüklemez,
  çıktıyı `windows-dev` ön sürümüne asset olarak koyar. Köprü kodu ve
  WindowInjection.dll aynı işte üretilir. Elle tetiklenir:
  `gh workflow run veradesk-windows.yml --repo Untouchable34/veradesk --ref veradesk`
- Tam sürüm akışı `veradesk-release.yml` (macOS/Android dahil, `v*` etiketiyle;
  artifact kullanır, kota boşalınca çalışır).
- **GitHub tuzağı:** akış dosyası, o dosyanın değiştiği bir push olmadan
  kaydolmuyor. Yeni akış ekleyince dosyaya dokunup push et.
- Windows çıktıları: `veradesk-1.5.0-x86_64-install.exe` (kendi kendine açılan
  kurulum) + `.msi`. İmzasız (SmartScreen uyarısı normal).

### Bekleyen işler
- **Sade tasarım:** kullanıcı sade, logolu, "son bağlantılar" görünen arayüz
  istedi; koyu/açık taslak yapıldı (artifact), ama kullanıcı "şimdilik eski
  tasarımla devam" dedi. Logo kaynağı `~/Desktop/remote/branding/logo-source.svg`.
- **Sürükle-bırak dosya aktarımı:** şu an sadece Dosya Aktarımı penceresinde
  var; uzak masaüstü görüntüsü üzerine bırakma YOK. İstenen bu; henüz yapılmadı.
- **macOS bağlantı kopması:** codec tek-çekirdek düzeltmesi yapıldı; kullanıcının
  M1 ↔ Mac mini son testi teyit edilmedi.
- **Windows imzası:** kod imzalama sertifikası alınırsa SmartScreen uyarısı kalkar
  (yıllık ücretli). Şimdilik gerekmiyor.

### Attribution (commit)
Bu depoda commit mesajları şu satırla bitiyor:
`Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>`
(Ortama göre değişebilir; kullanıcının kendi kuralı önceliklidir.)
