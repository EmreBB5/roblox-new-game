# Aetheria · Ufuklar

Roblox için fantastik açık dünya MMORPG prototipi. Güvenli köyden yollarla bağlı üç bölgeye çık, seviye kazan, saatlik world bosslara katıl ve nadir pet koleksiyonunu oluştur. Dünya sunucu açılışında parçalarla üretilir; dış model, ses, API anahtarı veya varlık yüklemesi gerekmez.

## Oyna

[Hazır Aetheria.rbxl dosyasını doğrudan indir](https://github.com/EmreBB5/roblox-new-game/raw/refs/heads/codex/roblox-studio-setup/downloads/Aetheria.rbxl). Roblox Studio'da **Ctrl+O** ile açıp **F5** ile başlatabilirsin; Git veya Rojo kurulumu gerekmez.

1. Bulutta `bash scripts/build.sh` ile `build/Aetheria.rbxlx` oluştur.
2. Bu dosyayı bilgisayarına indir ve **Roblox Studio → File → Open from File** ile aç.
3. **Play** düğmesine bas. Köy ve canavarlar oyun başladığında oluşturulur; düzenleme görünümü başlangıçta boştur.
4. Köydeki **Eldrin**'e yaklaş ve **E** ile görev al. **M** ile haritayı aç; batı yolundan Fısıltı Ormanı'na ilerle.
5. Bir yaratığa yaklaş; **sol tık / F** ile saldır. Üç orman yaratığını yendikten sonra Eldrin'e dön ve aynı etkileşimle ödülünü al.
6. Boss takvimini izle, haritadaki ◆ işaretine git ve diğer oyuncularla bossu yen. **P** ile pet koleksiyonunu açıp kazandığın peti tak.
7. **C** ile karakterini aç: köyde sınıf seç, sefer ödüllerini al ve Borin'in yanında donanımını yükselt. **Q/R** aktif yeteneklerindir.

GitHub üzerinde **Actions → Validate and build Roblox place** iş akışı, her push için kontrolleri ve oyun derlemesini çalıştırır. Başarılı çalışmanın **Aetheria-place** çıktısını indirip ZIP içindeki `Aetheria.rbxlx` dosyasını Studio'da açabilirsin. Bu iş akışı oyunu Roblox'a yayımlamaz.

Mobilde varsayılan Roblox hareket/atlama kontrolleri, **SALDIR**, iki yetenek, **PET**, **HARİTA**, **KARAKTER** düğmeleri ve NPC/kaynak etkileşim simgesi kullanılır. Gamepad'de saldırı **R2**, yetenekler **L1/R1**, NPC etkileşimi **X**, petler **Y**, harita **L3**, karakter **D-pad yukarı**'dır. Panel **Escape/B** ile kapanır. En yakın menzil içi hedef seçilir; hasar ve ödülleri sunucu belirler.

Orman yaratıkları 10 XP, bataklık yaratıkları 30 XP, köz yaratıkları 50 XP verir. Başlangıç görevi yalnız orman yaratıklarıyla ilerler; ödülü 75 XP, 25 altın ve çantada gösterilen tek orman kristalidir. Kristal petlerden ayrı bir görev ödülüdür. Eldrin'le tekrar konuşarak görev yenilenebilir. Güvenli köy bölgesinde saldırı yapılmaz; normal canavarlar yeniden doğar.

## Dünya bossları ve petler

| Bölge | Önerilen seviye | World boss | Her saat çıkış | Nadir pet |
|---|---:|---|---|---|
| Fısıltı Ormanı | 1 | Diken Muhafızı | :00 | Yosun Perisi |
| Sisli Bataklık | 3 | Sis Bekçisi | :20 | Sis Kanadı |
| Köz Yaylası | 5 | Köz Ejderi | :40 | Köz Yavrusu |

Yayınlanmış oyunda bosslar gerçek UTC saatine göre çıkar, 10 dakika kalır. Arayüz İstanbul saatini (UTC+3) ve geri sayımı gösterir. Örneğin bir saat içindeki İstanbul 18:00, 18:20 ve 18:40 çıkışları üç farklı bossa aittir. Sunucu etkinlik sürerken açılırsa kalan süreyle mevcut karşılaşmayı oluşturur; yenilmiş bir boss aynı sunucuda aynı zaman diliminde tekrar çıkmaz.

Her oyuncu en az **3 kabul edilmiş vuruş** ve bossun toplam canının **%1'i kadar hasar** ile kişisel ödüle hak kazanır. Son vuruşu yapan oyuncu bütün ganimeti almaz. Her uygun zaferde ilgili petin düşme şansı **%3**; aynı boss için art arda 29 başarısız düşüşün ardından **30. uygun zafer garantidir**. Başarılı pet düşüşü o bossun sayacını sıfırlar. Kopya pet 10 yıldız tozuna dönüşür. Takvime, hasara, rastgeleliğe ve ödüle sunucu karar verir.

Tek pet kuşanılır. Üç pet de eşit **+4 saldırı hasarı** verir; yaprak, yüzgeç ve boynuz görselleriyle oyuncuyu takip eder. Petler yalnız boss ödülünden açılır; para veya API anahtarıyla satın alma yoktur. Aynı global boss zaman diliminden yeniden ödül alınmasını önleyen kayıt, pet koleksiyonu ve garanti sayaçlarıyla birlikte saklanır.

**Studio demo takvimi:** İlk boss Play'den yaklaşık 20 saniye sonra çıkar; sonraki bosslar 200 ve 380. saniyelerdedir. Döngü 180 saniyelik aralıklarla sürer. Bosslar 120 saniye kalır, canları normalin %30'udur. Bu hızlandırma yalnız Studio'da geçerlidir; pet şansı yine %3'tür. Demo olduğu HUD'da açıkça gösterilir. İlk petin her denemede düşmesi beklenmemelidir.

MMO örnekleri, kaynakların sınırları ve tasarım kararları: [docs/MMO_DESIGN.md](docs/MMO_DESIGN.md).

## Sınıflar, yetenekler ve donanım

Yeni karakter **Savaşçı** olarak başlar. **C → Karakter** panelinden güvenli köyde ve en az 10 saniye savaş dışında kalarak sınıf değiştirilebilir. Değişim can doldurmaz, enerji veya yetenek bekleme sürelerini sıfırlamaz. Ekipman sınıfa göre kılıç ya da asa olarak görünür.

| Sınıf | Başlangıç canı / temel saldırı menzili | Q | R |
|---|---|---|---|
| Savaşçı | 140 / 11 stud | Geniş Darbe: yakındaki en fazla 3 hedef, 25 enerji, 6 sn | İkinci Nefes: 35 can iyileştirme, 30 enerji, 14 sn |
| Büyücü | 100 / 32 stud | Aether Oku: 48 stud içindeki hedef, 25 enerji, 4 sn | Yıldız Halkası: 17 stud içinde en fazla 3 hedef, 40 enerji, 9 sn |

Enerji en fazla **100**, yenilenme saniyede **8**'dir. Temel saldırı enerji harcamaz. Geçerli hedef yoksa, hedef duvar arkasındaysa veya iyileştirmede can zaten doluysa yetenek enerji/bekleme süresi tüketmez. Hasar, enerji, hedef görüş hattı ve zamanlar sunucuda doğrulanır. Kılıç darbesi, büyü ışını, alan halkası ve iyileştirme görselleri yalnız sunucunun kabul ettiği eylemlerde gösterilir.

**Sefer günlüğü**, Eldrin'in tekrarlanan 3 yaratık görevinden ayrıdır. Sırayla **5 orman yaratığı → 5 bataklık yaratığı → 5 köz yaratığı → 1 uygun katılımlı world boss** ister. Her aşamanın ödülünü C panelinden alarak bir sonraki aşamayı açarsın; daha erken yapılan sonraki bölge öldürmeleri geriye dönük sayılmaz. Her aşama bir kez ödül verir. İlk üç seferin altın/malzeme ödülleri, ilgili sıradaki donanım tarifini karşılar.

Haritada her bölgede beş toplama noktası vardır. Odun, demir ve köz cevherine yaklaş, **E** tutarak topla. Bir nokta aynı oyuncu için 30 saniyede yenilenir; diğer oyuncunun hakkını tüketmez. Normal yaratıklar da kendi bölgelerinin malzemesinden bir adet verir.

Köyde **Borin**'e yaklaş ve E kullan veya C panelinden **Yükselt** seç. Yalnız sıradaki kademe üretilir; malzeme veya altın eksikse hiçbir ödeme alınmaz.

| Kademe | Tarif | Toplam donanım bonusu |
|---|---|---|
| 1 · Gezgin | 5 odun, 25 altın | +4 hasar, +10 maksimum can |
| 2 · Muhafız | 8 odun, 5 demir, 75 altın | +9 hasar, +20 maksimum can |
| 3 · Aether | 10 odun, 8 demir, 6 köz, 150 altın | +15 hasar, +35 maksimum can |

Bonuslar kademeler arasında üst üste eklenmez. Seviye ve kuşanılan petin hasar katkısı ayrıca uygulanır. Tarife ve sınıfa göre görünüm güncellenir.

## Bulut araçları ve kontroller

Gereksinimler: Linux x86_64, Python 3, Bash ve HTTPS erişimi. Kaynak kod mevcut checkout içinde geliştirilir; ayrıca worktree gerekmez.

```bash
cd /workspace/roblox-new-game
python3 scripts/setup-tools.py
bash scripts/check.sh
```

Kurulum, resmi GitHub sürümlerinden **Rojo 7.7.1** ve **Luau 0.743** indirir; yayınlanan SHA-256 değerlerini doğruladıktan sonra `/workspace/.tools/aetheria/bin` altına kurar. Tekrar çalıştırma doğrulanmış indirme önbelleğini kullanır. Farklı araç konumu için `AETHERIA_TOOLS_DIR` değişkeni desteklenir. Python'un TLS doğrulaması açık kalır; checksum uyuşmazlığı kurulumu durdurur.

`scripts/check.sh`, tüm Luau kaynaklarını sözdizimi açısından derler, Roblox'a bağlı olmayan ortak mantıkta tür analizini ve üç test paketini çalıştırır, ardından Studio oyun dosyasını üretir. İlerleme paketinde 34, boss/pet paketinde 166, savaş/sefer/üretim paketinde 133 doğrulama vardır (toplam 333). Server/client dosyalarının Roblox API türleri bu bağımsız analiz kapsamına girmez. `build/` üretilmiş çıktıdır ve Git tarafından yok sayılır.

### Windows: GitHub deposunu Roblox Studio'ya bağla

Bu adımları **Roblox Studio'nun kurulu olduğu Windows bilgisayarında** uygula. İlk yöntem Git gerektirmez.

**En kolay yol: ZIP indir**

1. [Güncel kaynak ZIP'ini indir](https://github.com/EmreBB5/roblox-new-game/archive/refs/heads/codex/roblox-studio-setup.zip). Bu bağlantı kurulum dalının güncel sürümünü indirir. Daha önce gönderilen sabit `e486f00` ZIP'i eski prototiptir; yeni boss ve pet kodlarını içermez.
2. Dosya Gezgini'nde ZIP'e sağ tıkla → **Tümünü Ayıkla**. Kullanıcı klasörünün altında yeni bir klasör seç; mevcut proje dosyalarının üzerine ayıklama.
3. Çıkarılan `roblox-new-game-…` proje klasörünü aç. **`scripts`, `src` ve `default.project.json` görünmeli.** ZIP'in içinden çalıştırma.
4. Bu klasörde Dosya Gezgini'nin adres çubuğuna `powershell` yaz ve Enter'a bas. Aşağıdaki kurulum komutlarını bu pencerede çalıştır.

`C:\Windows\System32` proje klasörü değildir; orada `scripts\studio.ps1` bulunmaz. Git kurulu değilse `git` komutlarını kullanma. Güncel dal ZIP'i sürümler arasında değişir; eski prototipin ZIP checksum'u yeni sürüm için kullanılmaz. Rojo CLI ve eklentisi kendi sabit SHA-256 değerleriyle doğrulanmaya devam eder.

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

**GitHub'daki yeni kodu almak için** önce Studio'da Play'i durdur ve PowerShell'deki Rojo sunucusunu `Ctrl+C` ile kapat. ZIP yöntemiyle başladıysan yukarıdaki güncel ZIP'i yeniden indirip **ayrı bir klasöre** çıkar; eski klasörünü ve yerel değişikliklerini koru. Yeni klasördeki script ile yeniden başlat. Eski klasörde Rojo'yu yeniden açmak yeni kodları indirmez.

Git yöntemiyle başladıysan yerel dosya değişikliklerini commit ederek veya stash ile koru. Ardından depo klasöründe:

```powershell
git pull --ff-only
powershell -NoProfile -File .\scripts\studio.ps1
```

Studio'daki Rojo bağlantısını gerekirse yeniden kur ve eşitleme değişikliklerini incele. Akış **GitHub → ZIP indirme veya git pull → bilgisayarındaki dosyalar → Rojo → Studio** şeklindedir. Bilgisayardaki kaynak dosyalarını kaydettiğinde Rojo bağlı Studio'ya bunları aktarır; oyun davranışındaki değişiklikleri temiz bir Play oturumunda dene. **Studio içinde yaptığın düzenlemeler otomatik olarak Git dosyalarına veya GitHub'a dönmez.** Kaynak kod değişikliklerini yerel dosyalarda yap; GitHub'a göndermek için ayrıca Git ile commit/push veya GitHub'ın dosya yükleme arayüzünü kullan.

Bulutta çalışan Rojo sunucusuna bilgisayarındaki Studio'nun doğrudan erişebildiği varsayılmaz; bu depo için bulut önizleme bağlantısı yoktur. İndirilmiş `.rbxlx` dosyasını açmak ise eşitleme sunucusu gerektirmez.

## Kaynaklar

- `src/server/World.luau`: bağlı bölgeler, köy, arenalar, boss modelleri ve saldırı uyarıları.
- `src/server/Main.server.luau`: düşman AI, görev etkileşimi ve oyuncu yaşam döngüsü.
- `src/server/PlayerActions.luau`: sınıf, yetenek, menzil/enerji doğrulaması, üretim ve toplama etkileşimleri.
- `src/server/BossService.luau`: gerçek saatli boss yaşam döngüsü, katılım ve kişisel ödül entegrasyonu.
- `src/server/ProfileStore.luau`: Studio oturum verisi ve yayınlanmış deneyimde DataStore kayıtları.
- `src/shared/`: ayarlar, saf takvim, pet/ödül/savaş/üretim/sefer kuralları ve v3 profil geçişi.
- `src/client/`: Türkçe HUD, karakter paneli, yetenek çubuğu, savaş efektleri, pet koleksiyonu, boss takvimi ve harita.
- `tests/`: otomatik ilerleme testleri ve Studio kontrol planı.

## Kayıt ve çok oyunculu test

Studio'da kayıtlar bilinçli olarak **geçicidir**; API Services ayarını açmak bunu değiştirmez. Play oturumu yeniden başladığında yeni profil oluşturulur. Yayınlanmış deneyimde Roblox `DataStoreService` kullanılır; harici sunucu veya sohbetten paylaşılacak bir anahtar gerekmez. Kayıt yüklenemiyorsa oyuncu kabul edilmez; boş profil ile mevcut kayıt ezilmez. Kayıt sırasında oturum kilidi ve periyodik kaydetme kullanılır.

Eski v1/v2 kayıtlarının seviye, XP, altın, görev, kristal, petler ve garanti sayaçları korunur. **Profil v3** sınıf, donanım kademesi, malzemeler ve sefer ilerlemesini ekler. Aynı `AetheriaProfiles_v1` DataStore adı kullanılır; geçiş için eski kayıtlar silinmez. İç içe koleksiyonlar kaydetme sırasında bağımsız kopyalanır. Enerji ve yetenek bekleme süreleri yalnız çalışan sunucunun oturum durumudur; aynı oturumda yeniden doğma/sınıf değişimiyle sıfırlanmaz.

Studio'nun çoklu istemci testinden iki oyuncu başlatıp görev, ölüm/yeniden doğma, boss katılımı ve pet kuşanmayı kontrol et. Kalıcılığı ayrı, yayınlanmış özel bir test deneyiminde çıkıp tekrar girerek doğrula. Ayrıntılı kontrol listesi: [tests/MANUAL.md](tests/MANUAL.md).

Bu sürüm tek Roblox sunucusunda yollarla bağlı üç bölge sunar; streaming açıktır. Yayınlanmış sunucular aynı UTC takvimini kullanır, fakat boss canı ve karşılaşma durumu sunucular arasında ortak değildir. İki sınıfın sabit yetenekleri vardır; dallanan yetenek ağacı, lonca, oyuncu pazarı ve çok sunuculu kesintisiz bir dünya henüz yoktur. Yıldız tozu şu an yalnız koleksiyon sayacıdır; harcama sistemi yoktur. Hız/mesafe kontrolleri temel kötüye kullanım kontrolleridir; kapsamlı bir anti-cheat sistemi değildir.

Bulutta Luau mantığı, proje derlemesi ve Rojo eşitleme protokolü kontrol edilebilir. Roblox Studio/Linux desteği bulunmadığından gerçek oynanış, fizik, mobil arayüz ve canlı DataStore bu ortamda doğrulanmış sayılmaz.
