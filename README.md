# Aetheria · Ufuklar

Roblox için fantastik açık dünya MMORPG prototipi. Güvenli köyden yollarla bağlı beş biyoma çık, arkadaşlarınla grup kur, seviye kazan, saatlik world bosslara katıl ve nadir pet koleksiyonunu oluştur. Dünya sunucu açılışında parçalarla üretilir; dış model, ses, API anahtarı veya varlık yüklemesi gerekmez.

## Oyna

[Hazır Aetheria.rbxl dosyasını doğrudan indir](https://github.com/EmreBB5/roblox-new-game/raw/refs/heads/codex/roblox-studio-setup/downloads/Aetheria.rbxl). Roblox Studio'da **Ctrl+O** ile açıp **F5** ile başlatabilirsin; Git veya Rojo kurulumu gerekmez.

1. Bulutta `bash scripts/build.sh` ile `build/Aetheria.rbxlx` oluştur.
2. Bu dosyayı bilgisayarına indir ve **Roblox Studio → File → Open from File** ile aç.
3. **Play** düğmesine bas. Köy ve canavarlar oyun başladığında oluşturulur; düzenleme görünümü başlangıçta boştur.
4. Köydeki **Eldrin**'e yaklaş ve **E** ile görev al. **M** ile haritayı aç; batı yolundan Fısıltı Ormanı'na ilerle.
5. Bir yaratığa yaklaş; **sol tık / F** ile saldır. Üç orman yaratığını yendikten sonra Eldrin'e dön ve aynı etkileşimle ödülünü al.
6. Boss takvimini izle, haritadaki ◆ işaretine git ve diğer oyuncularla bossu yen. **P** ile pet koleksiyonunu açıp kazandığın peti tak.
7. **C** ile karakterini aç: köyde sınıf seç, sefer ödüllerini al ve Borin'in yanında donanımını yükselt. **Q/R** aktif yeteneklerindir.
8. **G** ile arkadaşlarını dört kişilik gruba davet et. Bir türbenin yanına gidip **E** ile keşfet; **M** haritasından keşfettiğin başka bir türbeye seyahat et.
9. Kazandığın peti kuşanarak eğit. Buzul ve çöldeki **▲ elit** işaretlerinden ek savaş ödülleri kazan; saldırı öncesi zeminde beliren alandan kaç.
10. Bölge türbesinin yanındaki **görev panosunda E** kullan; bölgesel görevleri **C** günlüğünde izle. **Tab / R3 / HEDEF** ile savaşacağın yaratığı seç.
11. **M → Keşif Günlüğü** bölümündeki **?** işaretlerine yürü. Taşta **E** ile keşfet, iki muhafızı yen ve 5 saniye savaş dışında kaldıktan sonra sandıkta **E** tutarak kişisel ödülünü al.

GitHub üzerinde **Actions → Validate and build Roblox place** iş akışı, her push için kontrolleri ve oyun derlemesini çalıştırır. Başarılı çalışmanın **Aetheria-place** çıktısını indirip ZIP içindeki `Aetheria.rbxlx` dosyasını Studio'da açabilirsin. Bu iş akışı oyunu Roblox'a yayımlamaz.

Mobilde varsayılan Roblox hareket/atlama kontrolleri, **SALDIR**, iki yetenek, **HEDEF**, **PET**, **HARİTA**, **KARAKTER**, **GRUP** düğmeleri ve etkileşim simgesi kullanılır. Gamepad'de saldırı **R2**, yetenekler **L1/R1**, hedef seçimi **R3**, NPC etkileşimi **X**, petler **Y**, harita **L3**, karakter **D-pad yukarı**, grup **D-pad sol**'dur. Panel **Escape/B** ile kapanır. Hedef seçilmemişse en yakın menzil içi yaratığa saldırılır; hasar ve ödülleri sunucu belirler.

Orman yaratıkları 10 XP, bataklık yaratıkları 30 XP, köz yaratıkları 50 XP, buzul yaratıkları 80 XP, çöl yaratıkları 110 XP verir. Başlangıç görevi yalnız orman yaratıklarıyla ilerler; ödülü 75 XP, 25 altın ve çantada gösterilen tek orman kristalidir. Kristal petlerden ayrı bir görev ödülüdür. Eldrin'le tekrar konuşarak görev yenilenebilir. Güvenli köy bölgesinde saldırı yapılmaz; normal canavarlar yeniden doğar.

## Savaş ve kazanım sunumu · v9

Savaşçı kılıcı altın yaylar, alan darbesi çevresel bir halka; büyücü oku hareket eden ışık çekirdeği ve iki iz, alan büyüsü mor/turkuaz halkalar kullanır. İyileştirme yeşil halka ve yükselen ışık noktalarıyla ayrılır. **İsabet parıltıları ve sayılar yalnız sunucunun doğruladığı gerçek hasar/iyileştirmeyi gösterir.** Savaş efektleri ortak bir 100 parça bütçesine, sayılar 30 görünüm sınırına tabidir; sayı animasyonları kısa bir büyüme ve gecikmeli kaybolma kullanır.

Yakındaki düşmanların isim, bölge seviyesi, rol ve canı özel etiketlerde görünür. Bosslar altın, elitler turkuaz çerçeve; düşük can kırmızı ton kullanır. Can çubuğundaki kısa gecikmeli iz, alınan hasarı okumayı kolaylaştırır. Aynı anda en fazla **12 etiket**, 10 Hz güncelleme ve normal/elit/boss için **55/100/150 stud** sınırları vardır. Etiketler duvarın arkasından çizilmez; uzaklaşınca, ölümde veya streaming çıkışında yerleşik göstergeler geri yüklenir.

Seviye, yeni pet, donanım, keşif ve kişisel sandık kazanımları tek bir **kısa özet kartında** gösterilir. Aynı türdeki hızlı kazanımlar birleştirilir; en fazla üç bildirim bekler. İlk profil yüklemesi kutlama üretmez. Sunucunun artan `feedbackRevision` değeri eski/tekrar mesajları eler; seviye atlanırken XP, oyunun gerçek seviye eğrisinden hesaplanır. Altın özeti, gözlenen olumlu bakiye değişimidir. Kart etkileşimsizdir; mobil kontrollerin yanındaki boş alana yerleşir ve fare saldırılarını engellemez. Bildirimler ödül vermez; kayıt şeması v7 kalır.

## Görsel yenileme · v8

Köy artık eğimli arduvaz çatılar, ahşap kirişler, sıcak pencereler, çiçeklikler, çizgili pazar tezgâhları, kehribar fenerler ve kristal çeşmeyle karşılar. Eldrin/Borin'in yüz ve giysi ayrıntıları, silahların sap, kabza, rün ve odak parçaları belirginleşti. Kampların bölgesel flamaları ve sandıkların metal kilit/perçinleri var. Dünya etiketleri başlık ve açıklamayı farklı boyutta gösterir.

| Biyom | Yeni simgesel yapı | Yerel atmosfer |
|---|---|---|
| Orman | Köklerle sarılmış taş kemer ve asılı kristal | Yeşil ton, ateşböceğini andıran ışık noktaları |
| Bataklık | Halkalı söğüt ve parlayan sazlar | Mavi sis, yavaş süzülen parçacıklar |
| Köz | Rünlü bazalt tacı | Sıcak pus, yükselen kıvılcımlar |
| Buzul | Buz kapısı ve kristal yapı | Soğuk ışık ve hafif kar |
| Çöl | Obelisk, palmiye ve vaha ayrıntıları | Altın pus, seyrek toz |

Yaratıklar bölgeye özgü kök zırhı, yüzgeç, lav damarı, buz omuzluğu veya çöl maskesi taşır. Yakındaki canlı yaratıkların omuz/kalçaları yürürken hareket eder; bazı kristaller hafifçe süzülüp döner. Petlerin yüzleri ve türlerine özgü tomurcuk, yüzgeç ucu veya patileri vardır. Lacivert/turkuaz arayüz altın çizgiler, dolgu geçişleri ve durum renkleri kullanır; pet koleksiyonu üç yerel **3B önizleme** gösterir. Pencereler kaydırılabilir; ana kontrol yerleşimi ve 44 px dokunma hedefleri korunur.

Görsel iş yükü sınırlandırılır: yeni simgesel yapılar 282 parça ve 7 ışıktır; istemcide 110 stud içindeki en yakın **12 dünya ışığı**, 160 stud içinde en fazla **24 hareketli yaratık** ve 120 stud içinde **12 kristal parçası** işlenir. Hareket 25 Hz, parçacık alanı tek yayıcı ve en fazla 13 parçacık/sn kullanır. Bunlar FPS garantisi değildir; özellikle düşük donanımlı mobilde sis, Glass/Neon ve çoklu istemci davranışı Studio test planıyla ölçülmelidir. Görsel sürüm v8'dir; kayıt şeması v7'dir.

## Genişleyen dünya

Harita **3.000 × 2.400 stud** boyutunda; ilk 1.800 × 1.600 haritanın 2,5 katı alan sunar. Zemin Roblox parça boyutu sınırına uygun dokuz parçaya bölünür. Bağlantı yolları ve türbe çevreleri dekorlardan arındırılır. Beş biyomda **20 gezici yaratık ve keşif kamplarında 10 muhafız**, **25 toplama noktası**, **5 kişisel keşif sandığı** ve köyle birlikte **6 seyahat türbesi** vardır.

| Biyom | Önerilen seviye | Yaratık | Malzeme | Ayırt edici çevre |
|---|---:|---|---|---|
| Fısıltı Ormanı | 1 | Orman Yaratığı | Odun | Ağaçlar, kök arenaları |
| Sisli Bataklık | 3 | Sis Avcısı | Demir | Sığ büyülü göletler, kristaller |
| Köz Yaylası | 5 | Köz Golemi | Köz | Obsidyen sütunları, kor damarları |
| Buzul Çamlığı | 8 | Buz Muhafızı | Demir | Karlı çamlar, buz çıkıntıları, donmuş göl |
| Güneş Kırığı Çölü | 11 | Kum Bekçisi | Köz | Kaktüsler, kumtaşı kalıntıları, vaha |

Köyün kuzeyindeki kavşaktan batıya giderek buzula, doğuya giderek çöle ulaşılır. Bölgeye girince HUD adı ve önerilen seviyeyi gösterir; hafif ekran renk geçişi o oyuncunun biyomuna uyum sağlar. Yeni bölgeler normal yaratık, toplama, sefer ve keşif içeriği ekler; saatlik pet bossları aşağıdaki üç bölgede kalır.

## Keşif kampları ve korunan sandıklar

Beş biyomun her birinde yollara bağlanan, yürünebilir bir köprüyle girilen bir keşif alanı bulunur. Ormanda köklü harabeler, bataklıkta iskeleler, köz bölgesinde rünlü arşiv, buzulda karakol, çölde çadırlar ve arabalarla kurulmuş kayıp kervan vardır. **M** haritasındaki **?** işaretini yerinde keşfedince alanın adı ve **▣** işareti açılır. Aşağı kaydırılan keşif günlüğü muhafızları ve kişisel sandık durumunu gösterir.

| Keşif alanı | XP | Altın | Malzeme |
|---|---:|---:|---|
| Kök Harabeleri | 60 | 20 | 3 odun |
| Sis İskelesi | 100 | 30 | 3 demir |
| Köz Arşivi | 150 | 45 | 3 köz |
| Buz Nöbeti | 220 | 60 | 3 demir |
| Kayıp Kervan | 280 | 80 | 3 köz |

Önce girişteki keşif taşıyla **E** kullan. Ardından iki kamp muhafızını yen. Muhafızlar bölgenin normal saldırılarını kullanır ve normal yaratık/grup/görev/pet eğitimi ödüllerini verir. Her biri **45 saniyede** geri gelir; sandığı bu aralıkta açabilirsin. Taşla keşif savaş kontrollerini kapatmaz. Sandık isteği sonuçlanırken sunucu iki muhafızın da yenilmiş olduğunu, karakterin hayatta ve sandığın 14 stud yakınında bulunduğunu ve son saldırı/hasarın üzerinden **5 saniye** geçtiğini doğrular.

Her sandık **her karakter için kalıcı olarak bir kez** XP, altın ve malzeme verir. Başka oyuncunun açması senin hakkını tüketmez; muhafızları bir arkadaşın temizlemişse sen de kendi ödülünü alabilirsin. Sandıklar pet veya pet XP vermez. Keşif ve ödül kayıtları eski karakter ilerlemesini koruyan v7 şemasında saklanır; gerçek kalıcılık için yayımlanmış test deneyiminde DataStore doğrulaması gerekir.

## Hedef seçimi ve yaratık davranışları

**Tab**, gamepad **R3** veya yetenek çubuğundaki **HEDEF** düğmesi, 60 stud içindeki görülebilen canlı düşmanlar arasında geçer. Son adaydan sonra seçim temizlenir. Seçili hedefin adı, canı, türü, uzaklığı ve temel saldırı menzilinde olup olmadığı görünür; hedef yerel bir çerçeveyle işaretlenir. Ölüm, görüş kaybı, uzaklaşma ve streaming seçimi temizler. Küçük ekranda hedef bilgisi mevcut yetenek çubuğunun başlığındadır; yeni bir kontrol satırı eklenmez.

Seçim bir tercihtir: sunucu hedefin gerçekten düşman kaydında olduğunu, canlılığını, menzilini ve görüş hattını yeniden doğrular. Geçersiz açık hedefte başka düşmana sessizce geçilmez. Seçili alan hedefi uygunsa ilk sırada, ardından en yakın iki uygun hedef vurulur. Kendini iyileştirme hedef tercihinden bağımsızdır.

| Bölge | Normal yaratığın saldırısı | Kaçış fırsatı |
|---|---|---|
| Orman | 5 stud yakın dövüş | Yaklaşmadan önce mesafeyi koru |
| Bataklık | 32 stud menzil, oyuncunun ilk konumunda 6 stud alan | 1 sn hazırlıkta işaretten çık |
| Köz | Kendi çevresinde 9 stud darbe | 1,2 sn hazırlıkta uzaklaş |
| Buzul | 5 stud yakın darbe | 0,65 sn hazırlıkta geri çekil |
| Çöl | 30 stud menzil, oyuncunun ilk konumunda 7 stud alan | 0,9 sn hazırlıkta işaretten çık |

Normal yaratıklar başlangıçlarından 100 stud uzağa çekilince geri döner, canları ve son saldıran kaydı sıfırlanır. Ölüm, geri çekilme ve kapanışta hazırlanmış saldırı iptal edilir. Gezici yaratıkların yeniden doğma süresi 8 saniye, keşif muhafızlarınınki 45 saniyedir. Saldırının gerçek konumu, görüş hattı ve oyuncunun güvenli bölgede olup olmadığı sunucuda kontrol edilir.

## Bölge görevleri

Her biyomda türbenin yanında bir görev panosu bulunur. Panoda **E** ile görevi al. Kabulden sonra bölgede **5 normal yaratık veya elit yen**, **3 başarılı kaynak toplama** yap ve o bölgenin **türbesini keşfet**. Önceki öldürmeler ve toplamalar sayılmaz; önceden keşfedilmiş türbe geçerlidir. Uygun grup desteği öldürme ilerlemesi verir; bosslar bu sayacı ilerletmez. Aynı kaynak bekleme süresi dolduğunda yeniden toplanabilir.

| Bölgesel görev | XP | Altın | Malzeme |
|---|---:|---:|---|
| Ormanın Emaneti | 75 | 30 | 3 odun |
| Sisin Ardında | 125 | 45 | 3 demir |
| Közün İzleri | 200 | 60 | 3 köz |
| Buzul Nöbeti | 300 | 80 | 3 demir |
| Vahanın Çağrısı | 400 | 100 | 3 köz |

Görevi aynı panonun **14 stud yakınında**, hayattayken teslim et. **C** panelindeki bölge kartları ilerlemeyi gösterir; panoyla etkileşim ilgili karta kaydırır. Her bölge görevi karakter başına bir kez ödül verir ve bağımsız ilerler. Pet XP veya pet düşüşü vermez. Eldrin'in tekrarlanan görevi ve altı aşamalı sefer günlüğü ayrıca devam eder.

## Dünya bossları ve petler

| Bölge | Önerilen seviye | World boss | Her saat çıkış | Nadir pet |
|---|---:|---|---|---|
| Fısıltı Ormanı | 1 | Diken Muhafızı | :00 | Yosun Perisi |
| Sisli Bataklık | 3 | Sis Bekçisi | :20 | Sis Kanadı |
| Köz Yaylası | 5 | Köz Ejderi | :40 | Köz Yavrusu |

Yayınlanmış oyunda bosslar gerçek UTC saatine göre çıkar, 10 dakika kalır. Arayüz İstanbul saatini (UTC+3) ve geri sayımı gösterir. Örneğin bir saat içindeki İstanbul 18:00, 18:20 ve 18:40 çıkışları üç farklı bossa aittir. Sunucu etkinlik sürerken açılırsa kalan süreyle mevcut karşılaşmayı oluşturur; yenilmiş bir boss aynı sunucuda aynı zaman diliminde tekrar çıkmaz.

Her oyuncu en az **3 kabul edilmiş vuruş** ve bossun toplam canının **%1'i kadar hasar** ile kişisel ödüle hak kazanır. Son vuruşu yapan oyuncu bütün ganimeti almaz. Her uygun zaferde ilgili petin düşme şansı **%3**; aynı boss için art arda 29 başarısız düşüşün ardından **30. uygun zafer garantidir**. Başarılı pet düşüşü o bossun sayacını sıfırlar. Kopya pet 10 yıldız tozuna dönüşür. Takvime, hasara, rastgeleliğe ve ödüle sunucu karar verir.

Tek pet kuşanılır. Üç pet de **+4 saldırı hasarıyla** başlar, aynı eğitim eğrisiyle **+8** hasara kadar gelişir; yaprak, yüzgeç ve boynuz görselleriyle oyuncuyu takip eder. Petler yalnız boss ödülünden açılır; para veya API anahtarıyla satın alma yoktur. Aynı global boss zaman diliminden yeniden ödül alınmasını önleyen kayıt, pet koleksiyonu ve garanti sayaçlarıyla birlikte saklanır.

**Studio demo takvimi:** İlk boss Play'den yaklaşık 20 saniye sonra çıkar; sonraki bosslar 200 ve 380. saniyelerdedir. Döngü 180 saniyelik aralıklarla sürer. Bosslar 120 saniye kalır, canları normalin %30'udur. Bu hızlandırma yalnız Studio'da geçerlidir; pet şansı yine %3'tür. Demo olduğu HUD'da açıkça gösterilir. İlk petin her denemede düşmesi beklenmemelidir.

MMO örnekleri, kaynakların sınırları ve tasarım kararları: [docs/MMO_DESIGN.md](docs/MMO_DESIGN.md).

## Pet eğitimi ve elit karşılaşmalar

Yalnız **kuşanılmış ve sahip olunan pet** deneyim kazanır. Normal yaratık ödülü veya normal grup desteği **4 pet XP**, uygun kişisel boss ödülü **30 pet XP** verir. Elitte kişisel katılım **12**, grup desteği **4 pet XP** verir. Görev teslimi, kaynak toplama, peti takıp çıkarma ve aynı boss ödülünü tekrar istemek pet XP kazandırmaz.

Petler en fazla **10. seviyeye**, toplam **1.080 XP** ile ulaşır. Bir sonraki seviye için önce 40, ardından 60, 80…200 XP gerekir. Hasar katkısı 3/5/7/9. seviyelerde +5/+6/+7/+8 olur; 10. seviyede +8 kalır. P paneli seviye, XP çubuğu ve güncel hasar katkısını gösterir. Görsel boyutu kademeli büyür; 3. ve 7. seviyelerde rün halkaları gelişir. Üç petin güç eğrisi aynıdır. Kuşanılmayan petin deneyimi korunur, fakat artmaz.

| Elit | Konum | Can | Kaçınılacak saldırı | Kişisel ödül |
|---|---|---:|---|---|
| Buzul Devriyesi | Buzul Çamlığı, güney arenası | 900 | Kendi çevresinde 14 stud patlama; 1,5 sn uyarı | 160 XP, 15 altın, 3 demir, 12 pet XP |
| Kum Mızrağı | Güneş Kırığı Çölü, güney arenası | 1.100 | Oyuncunun ilk konumunda 12 stud alan; 1,2 sn uyarı | 220 XP, 20 altın, 3 köz, 12 pet XP |

Elitler sunucu başlangıcında bulunur, yenilince **90 saniyede** yeniden doğar. Kişisel ödül için en az **2 kabul edilmiş isabet**, toplam canın **%1'i kadar hasar**, hayatta olmak ve ölüm noktasının **120 stud** yakınında bulunmak gerekir. Uygun oyuncunun aynı gruptaki canlı ve güvenilir **100 stud** yakınındaki üyeleri %70 XP, bir bölge malzemesi ve 4 pet XP destek ödülü alır. Kişisel hak ve birden fazla grup desteği üst üste ödül vermez. Uygun sefer ilerlemesi bir yaratık sayılır.

Elitler **pet düşürmez**; nadir petler mevcut üç world bosstan kazanılır. Elit 130 stud dışına çekilirse canı ve katkıları sıfırlanır; eski saldırısı iptal olur. Haritanın aşağı kaydırılan bölümünde elit canı, saldırı hazırlığı ve yeniden doğma süresi görünür.

## Sınıflar, yetenekler ve donanım

Yeni karakter **Savaşçı** olarak başlar. **C → Karakter** panelinden güvenli köyde ve en az 10 saniye savaş dışında kalarak sınıf değiştirilebilir. Değişim can doldurmaz, enerji veya yetenek bekleme sürelerini sıfırlamaz. Ekipman sınıfa göre kılıç ya da asa olarak görünür.

| Sınıf | Başlangıç canı / temel saldırı menzili | Q | R |
|---|---|---|---|
| Savaşçı | 140 / 11 stud | Geniş Darbe: yakındaki en fazla 3 hedef, 25 enerji, 6 sn | İkinci Nefes: 35 can iyileştirme, 30 enerji, 14 sn |
| Büyücü | 100 / 32 stud | Aether Oku: 48 stud içindeki hedef, 25 enerji, 4 sn | Yıldız Halkası: 17 stud içinde en fazla 3 hedef, 40 enerji, 9 sn |

Enerji en fazla **100**, yenilenme saniyede **8**'dir. Temel saldırı enerji harcamaz. Geçerli hedef yoksa, hedef duvar arkasındaysa veya iyileştirmede can zaten doluysa yetenek enerji/bekleme süresi tüketmez. Hasar, enerji, hedef görüş hattı ve zamanlar sunucuda doğrulanır. Kılıç darbesi, büyü ışını, alan halkası ve iyileştirme görselleri yalnız sunucunun kabul ettiği eylemlerde gösterilir. Vuruş ve iyileştirme sayıları, ilgili oyuncuya sunucunun kabul ettiği miktarı gösterir; kalan canı aşan vuruşlar kalan can kadar gösterilir.

**Sefer günlüğü**, Eldrin'in tekrarlanan 3 yaratık görevinden ayrıdır. Sırayla **5 orman → 5 bataklık → 5 köz yaratığı → 1 uygun katılımlı world boss → 8 buzul → 8 çöl yaratığı** ister. Her aşamanın ödülünü C panelinden alarak bir sonraki aşamayı açarsın; daha erken yapılan sonraki bölge öldürmeleri geriye dönük sayılmaz. Her aşama bir kez ödül verir. İlk üç seferin altın/malzeme ödülleri, ilgili sıradaki donanım tarifini karşılar. Eski dört aşamalı seferi bitiren karakterler beşinci aşamadan devam eder.

Haritada her bölgede beş toplama noktası vardır. Kaynağa yaklaş, **E** tutarak topla. Bir nokta aynı oyuncu için 30 saniyede yenilenir; diğer oyuncunun hakkını tüketmez. Normal yaratıklar da kendi bölgelerinin malzemesinden bir adet verir. Buzul demiri mevcut demir, güneş cevheri mevcut köz stokuna eklenir.

Köyde **Borin**'e yaklaş ve E kullan veya C panelinden **Yükselt** seç. Yalnız sıradaki kademe üretilir; malzeme veya altın eksikse hiçbir ödeme alınmaz.

| Kademe | Tarif | Toplam donanım bonusu |
|---|---|---|
| 1 · Gezgin | 5 odun, 25 altın | +4 hasar, +10 maksimum can |
| 2 · Muhafız | 8 odun, 5 demir, 75 altın | +9 hasar, +20 maksimum can |
| 3 · Aether | 10 odun, 8 demir, 6 köz, 150 altın | +15 hasar, +35 maksimum can |

Bonuslar kademeler arasında üst üste eklenmez. Seviye ve kuşanılan petin hasar katkısı ayrıca uygulanır. Tarife ve sınıfa göre görünüm güncellenir.

## Grup ve keşif seyahati

**G → Grup** panelinde aynı sunucudaki oyunculara davet gönderilir. Davet 30 saniye geçerlidir; oyuncu kabul edince katılır. Bir grupta en fazla dört oyuncu bulunur. Lider üye çıkarabilir; herkes ayrılabilir. Lider ayrıldığında kalan ilk üye lider olur. Grup ve davetler o sunucu oturumuna aittir; tekrar girişte yeniden kurulur.

Normal yaratığın son vuruşunu yapan oyuncu tam XP alır. Aynı grupta, yaratığın ölüm noktasına en fazla **100 stud** uzaklıkta ve hayatta olan üyeler temel XP'nin **%70**'ini alır. Bu oyuncuların uygun bölge görevleri/seferleri ilerler ve her biri bir bölge malzemesi kazanır. Ölü veya uzaktaki üyelere paylaşım yapılmaz. **World boss ve nadir pet ödüllerinde herkesin kişisel 3 vuruş ve %1 hasar şartı sürer.**

Köyde ve beş biyomun her birinde birer seyahat türbesi vardır. Köy başlangıçta açıktır; diğer türbeler yanlarına yürüyüp **E** kullanılarak keşfedilir. Keşifler karakter kaydında saklanır. Bir türbenin **16 stud** yakınından, **M → Harita** panelinde keşfedilmiş başka bir hedef seçilir. Ücret alınmaz. Küçük türbe platformları streaming sırasında da mevcut tutularak varışta zemin sağlar.

Seyahat için hayatta olmak ve en az **10 saniye** savaş dışında kalmak gerekir. **3 saniyelik** hazırlık sırasında 3 stud'dan fazla hareket etmek, hasar almak veya ölmek işlemi iptal eder. Hedef konumu sunucu seçer; seyahat enerji, yetenek bekleme süresi veya grup üyeliğini sıfırlamaz.

## Bulut araçları ve kontroller

Gereksinimler: Linux x86_64, Python 3, Bash ve HTTPS erişimi. Kaynak kod mevcut checkout içinde geliştirilir; ayrıca worktree gerekmez.

```bash
cd /workspace/roblox-new-game
python3 scripts/setup-tools.py
bash scripts/check.sh
```

Kurulum, resmi GitHub sürümlerinden **Rojo 7.7.1** ve **Luau 0.743** indirir; yayınlanan SHA-256 değerlerini doğruladıktan sonra `/workspace/.tools/aetheria/bin` altına kurar. Tekrar çalıştırma doğrulanmış indirme önbelleğini kullanır. Farklı araç konumu için `AETHERIA_TOOLS_DIR` değişkeni desteklenir. Python'un TLS doğrulaması açık kalır; checksum uyuşmazlığı kurulumu durdurur.

`scripts/check.sh`, tüm Luau kaynaklarını sözdizimi açısından derler ve Roblox'a bağlı olmayan ortak mantıkta tür analizi yapar. Sekiz saf Luau paketinde ilerleme 34, boss/pet 166, savaş/sefer/üretim 143, grup/seyahat/dünya 185, pet eğitimi/elit 179, bölge görevi/yaratık kuralları 293, keşif/kayıt geçişi 318 ve kazanım sunumu 58 doğrulama vardır (toplam 1.376).

Ardından `scripts/test-roblox-mocks.py`, **gerçek EliteService, EnemyService, RegionalContractService, PlayerActions ve ExplorationService kaynak kodlarını** sınırlı Roblox taklitleriyle çalıştırır. Toplam 274 ek doğrulama; gecikmiş saldırı iptali, tek ödül, grup paylaşımı, ölüm, yeniden doğma, görev panosu güvenliği, seçili hedefin geçerliliği ve sandıkların son anda muhafız/savaş/mesafe kontrolünü denetler. Toplam **1.650 doğrulama** çalışır. Bu testler Roblox fiziğini, ağını veya streaming'i çalıştırmaz. Son olarak Rojo Studio dosyasını üretir; `scripts/verify-export.py`, bütün kaynakların ve Script/LocalScript/ModuleScript türlerinin dışa aktarımda güncel olduğunu doğrular. Server/client dosyalarının Roblox API türleri bağımsız analiz kapsamına girmez. `build/` üretilmiş çıktıdır ve Git tarafından yok sayılır.

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
- `src/server/PartyService.luau`: oturum grupları, davetler ve yakındaki üyelerin ödül paylaşımı.
- `src/server/TravelService.luau`: türbe keşfi, savaş/hareket kontrolü ve güvenli seyahat.
- `src/server/ProfileStore.luau`: Studio oturum verisi ve yayınlanmış deneyimde DataStore kayıtları.
- `src/server/EliteService.luau`: elit saldırıları, katkı ve grup ödülleri, yeniden doğma ve saldırı iptalleri.
- `src/server/EnemyService.luau`: bölgelere özgü normal yaratık AI, saldırı hazırlığı, ölüm ve yeniden doğma.
- `src/server/RegionalContractService.luau`: görev panosu etkileşimleri, bölgesel ilerleme ve tek teslim.
- `src/shared/`: ayarlar, saf takvim, pet eğitimi/ödül/savaş/üretim/sefer/grup/seyahat/bölge görevi kuralları ve v7 profil geçişi.
- `src/client/`: Türkçe HUD, karakter/grup paneli, yetenek çubuğu, savaş efektleri, biyom renk geçişleri, pet koleksiyonu, boss takvimi ve seyahat haritası.
- `tests/`: otomatik ilerleme testleri ve Studio kontrol planı.

## Kayıt ve çok oyunculu test

Studio'da kayıtlar bilinçli olarak **geçicidir**; API Services ayarını açmak bunu değiştirmez. Play oturumu yeniden başladığında yeni profil oluşturulur. Yayınlanmış deneyimde Roblox `DataStoreService` kullanılır; harici sunucu veya sohbetten paylaşılacak bir anahtar gerekmez. Kayıt yüklenemiyorsa oyuncu kabul edilmez; boş profil ile mevcut kayıt ezilmez. Kayıt sırasında oturum kilidi ve periyodik kaydetme kullanılır.

Eski v1-v6 kayıtlarının seviye, XP, altın, görev, kristal, petler, eğitim XP'si, garanti sayaçları, sınıfı, donanımı, malzemeleri, sefer ilerlemesi ve keşfedilen türbeleri korunur. **Profil v7**, beş keşif alanının kişisel keşif ve sandık kayıtlarını ekler; v6 bölge görevleri korunur. Eski karakterlerin yeni alanları başlangıçta keşfedilmemiştir. Eski v1-v4 petlerin eğitim XP'si sıfırdan başlar. Köy her zaman açıktır. Aynı `AetheriaProfiles_v1` DataStore adı kullanılır; geçiş için eski kayıtlar silinmez. İç içe koleksiyonlar kaydetme sırasında bağımsız kopyalanır. Enerji, yetenek bekleme süreleri, grup, hedef seçimi ve devam eden seyahat yalnız oturum durumudur; aynı oturumda yeniden doğma/sınıf değişimi enerji/bekleme süresini sıfırlamaz.

Studio'nun çoklu istemci testinden dört oyuncu başlatıp grup, görev paylaşımı, ölüm/yeniden doğma, boss katılımı ve türbe seyahatini kontrol et. Kalıcılığı ayrı, yayınlanmış özel bir test deneyiminde çıkıp tekrar girerek doğrula. Ayrıntılı kontrol listesi: [tests/MANUAL.md](tests/MANUAL.md).

Bu sürüm tek Roblox sunucusunda yollarla bağlı beş biyom sunar; streaming açıktır. Yayınlanmış sunucular aynı UTC takvimini kullanır, fakat boss canı ve karşılaşma durumu sunucular arasında ortak değildir. İki sınıfın sabit yetenekleri vardır; dallanan yetenek ağacı, lonca, oyuncu pazarı ve çok sunuculu kesintisiz bir dünya henüz yoktur. Yıldız tozu şu an yalnız koleksiyon sayacıdır; harcama sistemi yoktur. Hız/mesafe kontrolleri temel kötüye kullanım kontrolleridir; kapsamlı bir anti-cheat sistemi değildir.

Bulutta Luau mantığı, proje derlemesi ve Rojo eşitleme protokolü kontrol edilebilir. Roblox Studio/Linux desteği bulunmadığından gerçek oynanış, fizik, mobil arayüz ve canlı DataStore bu ortamda doğrulanmış sayılmaz.
