# onyx-greeter

[English](README.md) · **Türkçe**

Wayland üzerinde KDE Plasma 6 için tam siyah bir SDDM giriş ekranı ve ona uyan
bir kilit ekranı arka planı.

![Yüz taraması sürerken giriş ekranı](screenshots/login-scanning.png)

> **Başlamadan önce küçük bir not:** onyx-greeter en başta kendi kullanımım için tasarlandı; başkalarının da işine yarayabilir diye paylaşıyorum. Kendi ihtiyaçlarım ve tercihlerim doğrultusunda şekillendiği için herkese hitap etmeyebilir. Öneri ve geri bildirimlerinizi memnuniyetle karşılarım.

![Yüz taraması başarısız](screenshots/login-failed.png)

Giriş ekranı, Plasma'nın kendi kilit ekranının da kullandığı
`org.kde.breeze.components` QML modülü üzerine kuruludur; profil resmi, saat,
eylem düğmeleri ve reddedilen parola animasyonu iki ekranda da aynı
bileşenlerdir ve etkin renk şemasını izler. İki ekran tek bir arka plan
dosyasını paylaşır (`shared/Backdrop.qml`): siyah zemin, ince bir çerçeve, dört
köşe işareti ve küçük bir başlık.

| Parça | Ne olduğu | Kurulduğu yer |
|---|---|---|
| giriş ekranı | SDDM teması | `/usr/share/sddm/themes/onyx` |
| kilit ekranı | duvar kağıdı eklentisi | `~/.local/share/plasma/wallpapers/org.lckt0.onyx` |

Kilit ekranındaki parola kutusu ve düğmeler Plasma'nın kendi bileşenleri olarak
kalır: onları değiştirmek ayrı bir Plasma kabuk paketi gerektirir ve onyx bunu
yapmaz.

> **Uyumluluk:** Plasma 6.7 için yazıldı. Plasma 6.8,
> `org.kde.breeze.components` içinde `sddm/Main.qml` dosyasının hâlâ kullandığı
> `VirtualKeyboardLoader` bileşenini artık içermiyor; bu yüzden giriş ekranı
> 6.8'de henüz yüklenmiyor (SDDM bu durumda kendi yerleşik temasına döner).

## Kurulum

### Gereksinimler

- KDE Plasma 6 ve Qt 6 karşılayıcısıyla SDDM
- Tam etki için koyu bir renk şeması (tema renklerini etkin şemadan alır)
- İsteğe bağlı: yüzle giriş için [howdy](https://github.com/boltgolt/howdy)

### Arch Linux

Henüz bir AUR paketi yok. Depoyu klonlayıp kurulum betiğini çalıştırın:

```sh
git clone https://github.com/lckt0/onyx-greeter.git
cd onyx-greeter
./install.sh
```

### Kurulum betiği

```sh
./install.sh                  # iki parçayı da kurar ve seçer
./install.sh --sddm           # yalnızca giriş ekranı
./install.sh --lock           # yalnızca kilit ekranı
./install.sh --no-select      # dosyaları kurar, mevcut seçimi korur
./install.sh --no-appearance  # karşılayıcının profiline dokunmaz
```

Giriş ekranı bir sonraki giriş ekranında, kilit ekranı bir sonraki kilitlemede
değişir; oturumu kapatmak gerekmez. Köşedeki başlık varsayılan olarak makine
adıdır; `ONYX_CAPTION="..." ./install.sh` ile değiştirebilirsiniz.

Betiğin yazdığı her şey:

```
/usr/share/sddm/themes/onyx/                     tema
/etc/sddm.conf.d/kde_settings.conf               [Theme] Current=onyx
~/.local/share/plasma/wallpapers/org.lckt0.onyx/ arka plan
~/.config/kscreenlockerrc                        [Greeter] WallpaperPlugin=org.lckt0.onyx
/var/lib/sddm/.config/{kdeglobals,plasmarc}      renkler, vurgu, simgeler, stil
/var/lib/sddm/.local/share/...                   bu paketlerin kopyaları
```

Son iki satır `--no-appearance` ile atlanır. SDDM karşılayıcıyı `0700` izinli
ev dizinini okuyamayan `sddm` kullanıcısıyla çalıştırır; bu adımlar olmadan
giriş ekranı stok Breeze renklerine ve simgelerine döner. İki yapılandırma
dosyası da ilk yazmadan önce `*.onyx-backup` olarak yedeklenir.

### Elle kurulum

```sh
sudo install -d /usr/share/sddm/themes/onyx
sudo install -m644 sddm/*.qml sddm/metadata.desktop sddm/theme.conf sddm/preview.png /usr/share/sddm/themes/onyx/

mkdir -p ~/.local/share/plasma/wallpapers/org.lckt0.onyx
cp -rL wallpaper/. ~/.local/share/plasma/wallpapers/org.lckt0.onyx/
```

Ardından seçin:

- **Giriş ekranı:** Sistem Ayarları → Renkler ve Temalar → Giriş Ekranı (SDDM) → **Onyx**
  (orada *Plasma Ayarlarını Uygula* renklerinizi ve simgelerinizi karşılayıcıya
  kopyalar) ya da
  `sudo kwriteconfig6 --file /etc/sddm.conf.d/kde_settings.conf --group Theme --key Current onyx`.
- **Kilit ekranı:** Sistem Ayarları → Ekran Kilitleme → Görünüm → duvar kağıdı türü **Onyx**.

### Yapılandırma

Kurulan tema dizinindeki `theme.conf`:

| Anahtar | Varsayılan | |
|---|---|---|
| `caption` | makine adı | sol üst köşe işaretinin içindeki yazı |
| `showCaption` | `true` | |
| `showClock` | `true` | |
| `showFaceUnlock` | `true` | Face Unlock düğmesini gösterir |

Kilit ekranı başlık ayarlarını kendi duvar kağıdı yapılandırmasından okur
(Sistem Ayarları → Ekran Kilitleme).

## Kaldırma

```sh
./uninstall.sh [geri-dönülecek-sddm-teması]   # varsayılan: breeze
```

Betik verilen SDDM temasını seçer, kilit ekranını stok resim duvar kağıdına
döndürür, `/var/lib/sddm/.config` içindeki `*.onyx-backup` dosyalarını geri
yükler, `/var/lib/sddm/.local/share` altındaki renk şeması, Plasma stili ve
simge kopyalarını siler, kurulan temayı ve duvar kağıdı eklentisini kaldırır.

Elle:

```sh
sudo kwriteconfig6 --file /etc/sddm.conf.d/kde_settings.conf --group Theme --key Current breeze
kwriteconfig6 --file kscreenlockerrc --group Greeter --key WallpaperPlugin org.kde.image
sudo rm -rf /usr/share/sddm/themes/onyx
rm -rf ~/.local/share/plasma/wallpapers/org.lckt0.onyx
```

İsteğe bağlı olarak, varsa karşılayıcının görünüm dosyalarını yedeklerden geri
yükleyin:

```sh
sudo mv /var/lib/sddm/.config/kdeglobals.onyx-backup /var/lib/sddm/.config/kdeglobals
sudo mv /var/lib/sddm/.config/plasmarc.onyx-backup /var/lib/sddm/.config/plasmarc
```

## Yüzle giriş (howdy)

`pam_howdy`, `/etc/pam.d/sddm` ve `/etc/pam.d/kde` dosyalarında `pam_unix`'ten
önce `sufficient` olarak yer aldığında:

- **Kilit ekranı:** tarama kendiliğinden başlar; howdy'nin iletileri parola
  alanının üstünde görünür.
- **Giriş ekranı:** SDDM parolayı PAM'e en başta verdiği için tarama yalnızca
  istendiğinde başlar. Boş alanda Enter'a basın ya da **Face Unlock**
  düğmesini kullanın.

İki ekranda da ilerleme iletilerini görmek için howdy'de açın:

```ini
# /etc/howdy/config.ini
[core]
detection_notice = true
```

Giriş ekranında başarısız bir tarama boş parolayla `pam_unix`'e düşer;
`pam_faillock` bunu başarısız deneme sayar ve başarılı bir tarama bu sayacı
sıfırlamaz. Varsayılan `deny=3` ile art arda üç başarısız tarama hesabı on
dakika kilitler. Face Unlock'ın karşılayıcı açılınca kendiliğinden çalışmayıp
bir düğme olmasının nedeni budur.

## Oturumu kapatmadan önizleme

```sh
QT_QPA_PLATFORM=offscreen qml6 tools/preview.qml -- --grab /tmp/onyx.png
```

`tools/preview.qml`, SDDM'in sağladığı nesnelerin (`sddm`, `userModel`,
`sessionModel`, `screenModel`, `keyboard`, `config`) yerini tutar ve bir howdy
konuşmasını canlandırır. `QT_QPA_PLATFORM=offscreen` ve `--grab` olmadan normal
bir pencere açar. Aksi halde günlüğe giden QML hatalarını görmek için
`QT_FORCE_STDERR_LOGGING=1` ayarlayın.

## Lisans

LGPL-2.0-or-later. `sddm/KeyboardButton.qml` ve `sddm/SessionButton.qml`,
KDE'nin Breeze SDDM temasından gelir ve özgün telif başlıklarını korur. Bkz.
[LICENSE](LICENSE).
