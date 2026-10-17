# Aetheria: açık dünya, world boss ve pet tasarımı

İnceleme tarihi: 17 Ekim 2026. Amaç, ilk tek görevli prototipi keşif → zamanlı ortak etkinlik → kişisel nadir koleksiyon döngüsüne geliştirmek.

## Kaynaklar ve araştırmanın sınırı

Bu ortamdan Guild Wars 2 Wiki, FFXIV resmî oyun rehberi ve Albion Wiki istekleri ağ proxy'si tarafından 403 ile engellendi. Bu oyunların güncel sürümlerini oynayarak veya bütün resmî rehberlerini okuyarak karşılaştırma yapıldığı iddia edilmez. Erişilebilen açık kaynak ve veri tabloları aşağıdadır; topluluk verisi, resmî yayıncı belgesi olarak sunulmaz.

| İncelenen örnek | Kaynaktan doğrulanan gözlem | Aetheria'daki karar |
|---|---|---|
| Guild Wars 2 / topluluk World Events eklentisi | README'de dünya saati, aktif harita işaretleri ve günlük ödül takibi var. `events_basic.cpp` içinde UTC tabanlı tekrarlayan ve belirli saatli boss tabloları var. | Sunucu açıldıktan sonra sürekli kayan sayaç yerine mutlak UTC saat dilimleri; harita ve kalan süre; aynı karşılaşmadan tekrar ödül engeli. |
| FFXIV / XIVAPI topluluk veri çıkarımı | `Fate.csv` adlandırılmış açık dünya etkinlik kayıtlarını, `Companion.csv` ayrı isim/ikon/davranış alanlarına sahip yoldaş koleksiyonunu içeriyor. | Etkinlik katılımı ve kalıcı pet koleksiyonu ayrı sistemler; yeni boss eklemek mevcut profil alanlarını bozmuyor. |
| Roblox resmî Creator Docs | Instance streaming, yakındaki içeriğin yüklenip uzak içeriğin çıkarılmasını destekler. DataStore kalıcı ilerleme sağlar; sunucular arası iletişim ayrı bir MessagingService konusudur. | Tek bağlı haritada streaming; pet görselleri kaybolan karakterleri tolere eder; kalıcı koleksiyon; ortak boss canı varmış gibi davranmayan sunucu başına karşılaşma. |

Kaynak bağlantıları:

- [GW2 World Events README](https://github.com/Xen0phy/World-Events/blob/6c89bd63f1d6f834ab790093a3c84a789e2b0623/README.md) ve [UTC boss tabloları](https://github.com/Xen0phy/World-Events/blob/6c89bd63f1d6f834ab790093a3c84a789e2b0623/src/events/events_basic.cpp). Bunlar topluluk eklentisidir; ArenaNet'in resmî drop oranı kaynağı değildir.
- [XIVAPI veri projesi açıklaması](https://github.com/xivapi/ffxiv-datamining), [Fate.csv](https://github.com/xivapi/ffxiv-datamining/blob/master/csv/en/Fate.csv), [Companion.csv](https://github.com/xivapi/ffxiv-datamining/blob/master/csv/en/Companion.csv). Tablolar topluluk çıkarımıdır; bu incelemede FFXIV'in güncel ödül dengesi veya pet düşüş oranı bunlardan türetilmedi.
- Roblox resmî kaynak deposunda [instance streaming](https://github.com/Roblox/creator-docs/blob/main/content/en-us/workspace/streaming/index.md), [DataStore](https://github.com/Roblox/creator-docs/blob/main/content/en-us/cloud-services/data-stores/index.md), [cross-server messaging](https://github.com/Roblox/creator-docs/blob/main/content/en-us/cloud-services/cross-server-messaging.md).

Başka oyunların karakterleri, isimleri, haritaları, kodları veya görselleri projeye kopyalanmadı. %3 düşüş ve 30 zafer garantisi Aetheria'nın başlangıç denge ayarlarıdır; piyasadaki MMO'ların oranları olduğu iddia edilmez.

## Uygulanan oyun döngüsü

1. Köyde Eldrin'in başlangıç görevini al; Fısıltı Ormanı'nda savaşmayı öğren.
2. Haritadan Sisli Bataklık ve Köz Yaylası'nı keşfet; daha güçlü normal yaratıklardan XP kazan.
3. Saatlik :00, :20 ve :40 boss takvimini takip et. Her boss 10 dakika açık kalır. Arena işaretli alan saldırısından yürüyerek kaç.
4. En az üç kabul edilmiş vuruş ve toplam boss canının en az %1'i kadar hasarla kişisel ödüle hak kazan. Her uygun oyuncu bağımsız pet şansı alır; son vuruş şartı yoktur.
5. %3 pet şansını dene. Aynı bossun 30. ardışık başarısızlık korumalı zaferinde pet garanti olur. Başarılı düşüş o bossun sayacını sıfırlar; kopya pet 10 yıldız tozu verir.
6. P panelinden tek pet kuşan. Üç pet eşit +4 hasar bonusuna sahiptir; farkları görünüm ve koleksiyondur. Sunucu sahipliği doğrular.

## Saat, kayıt ve adil katılım

Prodüksiyonda takvim UTC'ye sabitlenir; oyuncuya İstanbul UTC+3 gösterilir. Sunucu bir etkinliğin ortasında açıldığında aynı başlangıç kimliği ve kalan süre kullanılır. Boss öldükten sonra aynı sunucuda o dilimde tekrar çıkmaz. Her profilde boss başına son ödül alınan dilim saklanır; yeni sunucuya geçiş aynı dilimi tekrar kazandırmaz. Bu kalıcılık, ilgili DataStore kaydının başarılı olmasına bağlıdır.

Boss katkısı sunucunun kabul ettiği gerçek hasardan hesaplanır; fazla öldürme hasarı eklenmez. Leash ile boss sıfırlanırsa katkılar da silinir. Süre aşımı ödül vermez. Yenilmiş, sıfırlanmış veya silinmiş bossun gecikmiş alan saldırısı iptal edilir.

Studio'da beklemeyi azaltmak için başlangıç +20 saniye, sonraki bosslar +200/+380 saniyedir; döngü sürer. Boss 120 saniye yaşar, canı %30'dur; katılım eşiği bu gerçek cana göre hesaplanır. Pet oranı değiştirilmez ve bedava pet verilmez. Demo takvimi yayınlanmış oyunda kullanılmaz.

Eski v1 DataStore adı korunur; XP, altın, görev ve kristal v2 profile taşınır. Petler ve sayaçlar kaydetme sırasında bağımsız kopyalanır. Yükleme hatası boş profil yaratıp eski veriyi ezmez. Bu davranışların gerçek Roblox DataStore üzerinde doğrulanması ayrı yayınlanmış özel test deneyimi gerektirir.

## Doğrulama ve kapsam

Bağımsız Luau testleri takvim sınırları, kaçırılan saatlerden sonra kaymama, kişisel ödül, %3 sınırı, 30. garanti, tekrar ödül engeli, sahiplik, eski kayıt geçişi ve iç içe kayıt kopyasını kapsar. Tam kontrol komutu `bash scripts/check.sh` olur. Gerçek oyun/fizik/mobil/çoklu istemci/kalıcılık planı [MANUAL.md](../tests/MANUAL.md) içindedir; bu plan çalıştırılmış Studio sonucu değildir.

Bu sürüm ortak bir Roblox sunucusunda açık dünya RPG temelidir. Bossların UTC çıkışları sunucular arasında aynı, canları ayrıdır. Sürekli ortak dünya, lonca, pazar ekonomisi ve dallanan yetenek ağaçları için ek sistemler gerekir. Performans yük testi veya üretime hazır MMORPG iddiası yoktur.

## Karakter gelişimi sürümü: sınıf, sefer ve donanım

Savaşçı ve büyücü, aynı seviye/donanım/pet gelişimini farklı saldırı menzilleri ve Q/R yetenekleriyle kullanır. Savaşçı yakın alan darbesi ve kendi canını yenilemeye; büyücü uzak tek hedef ve çevresel alan hasarına sahiptir. Yetenek kaynağı ve bekleme zamanları sunucu tarafından tutulur. Hedef geometrisi doğrulanmadan kaynak tüketilmez. Güvenli köydeki sınıf değişimi mevcut can oranını korur; enerji ve bekleme süreleri aynı oturumda taşınır.

Eldrin'in tekrarlanan öğretici görevine eklenen dört aşamalı sefer, her bölgeyi sırayla tanıtır. Üç bölgedeki beşer yaratık aşaması ve son world boss aşaması ayrı ayrı teslim edilir. Her aşamanın ödülü yalnız bir kez alınır. İlk üç aşama ilgili donanım tarifini karşılayacak malzeme/altın sağlar; oyuncu kaynak toplamaya zorunlu tutulmaz. Böylece keşif ve etkinlik sistemlerinin yanında ölçülebilir karakter gelişimi vardır.

Borin'in üç kademeli tarifleri bütün gereksinimler kontrol edildikten sonra tek işlemde malzeme ve altın tüketir. Malzemeler bölge yaratıklarından ve oyuncu başına 30 saniye beklemeli 15 toplama noktasından gelir. Bunlar serbest oyuncu pazarı veya üretim ekonomisi simülasyonu değildir; malzeme toplama ve geliştirme döngüsünün ilk uygulamasıdır.

Profil v3, v1/v2 ilerlemesini ve petleri korurken sınıf/kademe/malzeme/sefer alanlarını ekler. Bağımsız testler kaynak yenilenmesi, kesin cooldown sınırları, geçersiz hedefte harcama olmaması, bütün malzemeleri karşılamadan üretim yapılmaması, aşamaların tekrar ödül vermemesi ve iç içe profil alanlarının ayrık kopyasını doğrular. Gerçek Studio oynanışı, dokunma kontrolleri ve canlı DataStore kontrolü aynı manuel test planında ayrı durur.
