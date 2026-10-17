# Aetheria · Orman Muhafızları

Roblox için fantastik, çok oyunculu RPG başlangıç prototipi. Küçük bir köy, Fısıltı Ormanı, ortak canavarlar ve tekrarlanabilen bir görev içerir. Dünya sunucu açılışında parçalarla üretilir; dış model, ses, API anahtarı veya varlık yüklemesi gerekmez.

## Oyna

1. Bulutta `bash scripts/build.sh` ile `build/Aetheria.rbxlx` oluştur.
2. Bu dosyayı bilgisayarına indir ve **Roblox Studio → File → Open from File** ile aç.
3. **Play** düğmesine bas. Köy ve canavarlar oyun başladığında oluşturulur; düzenleme görünümü başlangıçta boştur.
4. Köydeki **Eldrin**'e yaklaş ve **E** ile görev al. Fısıltı Ormanı kapısından kuzeye, taş yol boyunca ilerle.
5. Bir yaratığa yaklaş; **sol tık / F** ile saldır. Üç yaratığı yendikten sonra Eldrin'e dön ve aynı etkileşimle ödülünü al.

GitHub üzerinde **Actions → Validate and build Roblox place** iş akışı, her push için kontrolleri ve oyun derlemesini çalıştırır. Başarılı çalışmanın **Aetheria-place** çıktısını indirip ZIP içindeki `Aetheria.rbxlx` dosyasını Studio'da açabilirsin. Bu iş akışı oyunu Roblox'a yayımlamaz.

Mobilde varsayılan Roblox hareket/atlama kontrolleri, **SALDIR** düğmesi ve NPC'nin etkileşim simgesi kullanılır. Gamepad'de saldırı **R2**, NPC etkileşimi **X**'tir. En yakın menzil içi hedef seçilir; hasar ve ödülleri sunucu belirler.

Her yaratık 10 XP verir. Görev ödülü 75 XP, 25 altın ve çantada gösterilen tek orman kristalidir. Kristal bir koleksiyon bayrağıdır; tekrar görevler yeni bir kristal yığını oluşturmaz. Eldrin'le tekrar konuşarak yeni görev başlatılabilir. Güvenli köy bölgesinde saldırı yapılmaz; canavarlar yeniden doğar.

## Bulut araçları ve kontroller

Gereksinimler: Linux x86_64, Python 3, Bash ve HTTPS erişimi. Kaynak kod mevcut checkout içinde geliştirilir; ayrıca worktree gerekmez.

```bash
cd /workspace/roblox-new-game
python3 scripts/setup-tools.py
bash scripts/check.sh
```

Kurulum, resmi GitHub sürümlerinden **Rojo 7.7.1** ve **Luau 0.743** indirir; yayınlanan SHA-256 değerlerini doğruladıktan sonra `/workspace/.tools/aetheria/bin` altına kurar. Tekrar çalıştırma doğrulanmış indirme önbelleğini kullanır. Farklı araç konumu için `AETHERIA_TOOLS_DIR` değişkeni desteklenir. Python'un TLS doğrulaması açık kalır; checksum uyuşmazlığı kurulumu durdurur.

`scripts/check.sh`, tüm Luau kaynaklarını sözdizimi açısından derler, Roblox'a bağlı olmayan ortak mantıkta tür analizini ve ilerleme testlerini çalıştırır, ardından Studio oyun dosyasını üretir. Server/client dosyalarının Roblox API türleri bu bağımsız analiz kapsamına girmez. `build/` üretilmiş çıktıdır ve Git tarafından yok sayılır.

### Windows: GitHub deposunu Roblox Studio'ya bağla

Bu adımları **Roblox Studio'nun kurulu olduğu Windows bilgisayarında** uygula. İlk yöntem Git gerektirmez.

**En kolay yol: ZIP indir**

1. [Hazır kaynak ZIP'ini indir](https://github.com/EmreBB5/roblox-new-game/archive/e486f004ff73688550b225b669c677f23b91cb2d.zip). Bu bağlantı `e486f004ff73688550b225b669c677f23b91cb2d` sürümüne sabittir.
2. Dosya Gezgini'nde ZIP'e sağ tıkla → **Tümünü Ayıkla**. Kullanıcı klasörünün altında yeni bir klasör seç; mevcut proje dosyalarının üzerine ayıklama.
3. Çıkarılan `roblox-new-game-e486f004ff73688550b225b669c677f23b91cb2d` klasörünü aç. **`scripts`, `src` ve `default.project.json` görünmeli.** ZIP'in içinden çalıştırma.
4. Bu klasörde Dosya Gezgini'nin adres çubuğuna `powershell` yaz ve Enter'a bas. Aşağıdaki kurulum komutlarını bu pencerede çalıştır.

`C:\Windows\System32` proje klasörü değildir; orada `scripts\studio.ps1` bulunmaz. Git kurulu değilse `git` komutlarını kullanma. İndirilen sabit ZIP'in SHA-256 değeri `db0f7bff1eac02218d2c65f3ec4d7a0cfec0067e54f31e8fbe5cc50cd6bacd35` olmalıdır; PowerShell'de `Get-FileHash` ile indirdiğin ZIP'i kontrol edebilirsin.

**Alternatif: Git ile indir**

Git kullanmak istersen [resmi Windows kurulumunu](https://git-scm.com/download/win) tamamla ve yeni bir PowerShell penceresi aç. Kaynakları kullanıcı klasörüne indir:

```powershell
cd $env:USERPROFILE
git clone https://github.com/EmreBB5/roblox-new-game.git
cd roblox-new-game
git switch codex/roblox-studio-setup
```

İlk eklenti kurulumu sırasında **Roblox Studio kapalı olsun**:

```powershell
powershell -NoProfile -File .\scripts\studio.ps1 -SetupOnly
```

Yardımcı script resmi Rojo **7.7.1** Windows dosyasını indirir, SHA-256 değerini doğrular ve aynı sürümün Studio eklentisini kurar. Farklı bir mevcut eklentiyi izinsiz ezmez. Özel bir Studio eklenti klasörü kullanıyorsan scriptin `-PluginDirectory` seçeneğini kullanabilirsin. Windows yürütme politikası scripti engellerse hata metnini paylaş; genel yürütme politikasını değiştirme. İnternetten indirilmiş bir dosyanın engelini kaldırmadan önce kaynağını ve script içeriğini incele.

Ardından yerel eşitleme sunucusunu başlat ve bu PowerShell penceresini açık bırak:

```powershell
powershell -NoProfile -File .\scripts\studio.ps1
```

1. Roblox Studio'yu aç; **yeni, boş bir Baseplate** oluştur. İlk deneme için kaydedilmemiş bir deneyim kullan.
2. **Plugins → Rojo → Connect** bölümünde adresi `localhost`, portu `34872` olarak seç.
3. Rojo'nun gösterdiği değişiklikleri incele ve bu boş projeye uygulanmasını kabul et.
4. **Play** düğmesine bas. Köy ve canavarlar oyun başlayınca oluşturulur; Eldrin'den görev alabilirsin.

Bu yerel bağlantı için script Roblox hesabı, parola veya API anahtarı istemez. GitHub deposunu indirmek ve bilgisayarındaki dosyaları Studio'ya eşitlemek, deneyimi Roblox'a yayınlamaz.

**GitHub'daki yeni kodu almak için** önce Studio'da Play'i durdur ve PowerShell'deki Rojo sunucusunu `Ctrl+C` ile kapat. ZIP yöntemiyle başladıysan yeni sürümün ZIP'ini **ayrı bir klasöre** çıkar; eski klasörünü ve yerel değişikliklerini koru. Yeni klasördeki script ile yeniden başlat. Sabit ZIP bağlantısı her zaman yukarıdaki sürümü indirir; daha sonraki sürüm için yeni bağlantı gerekir.

Git yöntemiyle başladıysan yerel dosya değişikliklerini commit ederek veya stash ile koru. Ardından depo klasöründe:

```powershell
git pull --ff-only
powershell -NoProfile -File .\scripts\studio.ps1
```

Studio'daki Rojo bağlantısını gerekirse yeniden kur ve eşitleme değişikliklerini incele. Akış **GitHub → ZIP indirme veya git pull → bilgisayarındaki dosyalar → Rojo → Studio** şeklindedir. Bilgisayardaki kaynak dosyalarını kaydettiğinde Rojo bağlı Studio'ya bunları aktarır; oyun davranışındaki değişiklikleri temiz bir Play oturumunda dene. **Studio içinde yaptığın düzenlemeler otomatik olarak Git dosyalarına veya GitHub'a dönmez.** Kaynak kod değişikliklerini yerel dosyalarda yap; GitHub'a göndermek için ayrıca Git ile commit/push veya GitHub'ın dosya yükleme arayüzünü kullan.

Bulutta çalışan Rojo sunucusuna bilgisayarındaki Studio'nun doğrudan erişebildiği varsayılmaz; bu depo için bulut önizleme bağlantısı yoktur. İndirilmiş `.rbxlx` dosyasını açmak ise eşitleme sunucusu gerektirmez.

## Kaynaklar

- `src/server/World.luau`: köy, orman, Eldrin, kristaller ve canavar modelleri.
- `src/server/Main.server.luau`: savaş, düşman AI, görev etkileşimi ve oyuncu yaşam döngüsü.
- `src/server/ProfileStore.luau`: Studio oturum verisi ve yayınlanmış deneyimde DataStore kayıtları.
- `src/shared/`: ayarlar ve Roblox'tan bağımsız ilerleme mantığı.
- `src/client/Main.client.luau`: Türkçe HUD, giriş ve bildirimler.
- `tests/`: otomatik ilerleme testleri ve Studio kontrol planı.

## Kayıt ve çok oyunculu test

Studio'da kayıtlar bilinçli olarak **geçicidir**; API Services ayarını açmak bunu değiştirmez. Play oturumu yeniden başladığında yeni profil oluşturulur. Yayınlanmış deneyimde Roblox `DataStoreService` kullanılır; harici sunucu veya sohbetten paylaşılacak bir anahtar gerekmez. Kayıt yüklenemiyorsa oyuncu kabul edilmez; boş profil ile mevcut kayıt ezilmez. Kayıt sırasında oturum kilidi ve periyodik kaydetme kullanılır.

Studio'nun çoklu istemci testinden iki oyuncu başlatıp görev, ölüm/yeniden doğma ve paylaşılan canavarları kontrol et. Kalıcılığı ayrı, yayınlanmış özel bir test deneyiminde çıkıp tekrar girerek doğrula. Ayrıntılı kontrol listesi: [tests/MANUAL.md](tests/MANUAL.md).

Bu ilk sürüm tek Roblox sunucusunda ortak bir bölge sunar. Sınıflar, büyü saldırıları, bosslar, ticaret, geniş envanter ve sunucular arasında kesintisiz bir dünya henüz yoktur. Hız/mesafe kontrolleri temel kötüye kullanım kontrolleridir; kapsamlı bir anti-cheat sistemi değildir.

Bulutta Luau mantığı, proje derlemesi ve Rojo eşitleme protokolü kontrol edilebilir. Roblox Studio/Linux desteği bulunmadığından gerçek oynanış, fizik, mobil arayüz ve canlı DataStore bu ortamda doğrulanmış sayılmaz.
