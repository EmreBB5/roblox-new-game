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

## Birlikte keşif sürümü: grup ve türbeler

Dört kişilik grup, birlikte normal yaratık kesmeyi ödüllendirir. Davet karşı tarafın kabulünü gerektirir; 30 saniyede düşer. Bir oyuncu aynı anda tek grupta olur. Lider ayrıldığında kalan ilk üye liderliği alır. Grup sunucu oturumunda tutulur; lonca veya sunucular arası arkadaşlık sistemi değildir.

Son vuruş tam XP verir. Aynı gruptaki canlı ve ölüm noktasından en fazla 100 stud uzaktaki üyeler %70 XP, bölge malzemesi ve uygun aktif görev/sefer ilerlemesi alır. Ödül oyuncu başına bir kez uygulanır. Boss katkısı bu paylaşıma dahil edilmez: pet şansı için kişisel üç kabul edilmiş vuruş ve %1 hasar hâlâ zorunludur. Bu sayede birlikte normal gelişim kolaylaşırken nadir koleksiyonun katılım şartı korunur.

Altı seyahat türbesi, keşif ve sonradan geri dönme döngüsünü destekler. Köy başlangıçta açıktır; diğer noktalar fiziksel etkileşimle keşfedilir. Seyahat yalnız türbe yakınından keşfedilmiş bir başka noktaya, 10 saniye savaş dışındayken başlar. Üç saniyelik hazırlıkta hareket, hasar, ölüm veya karakter değişimi işlemi iptal eder. Sunucu hedef CFrame'ini seçer; meşru seyahatten sonra hareket doğrulama örneği yenilenir. Sınıf kaynakları ve cooldown'lar korunur.

Profil v4 yalnız kalıcı keşif tablosunu ekler; v1/v2/v3 ilerlemesi aynı DataStore adında taşınır. Grup, davet ve devam eden seyahat kayda yazılmaz. Bu sürüm için ek oyun incelemesi yapılmadı; kurallar Aetheria'nın mevcut döngüsüne göre seçildi. Çoklu istemcide lider değişimi, paylaşım sınırları, seyahatin iptali ve streaming ile varış Studio test planına eklendi.

## Genişleme: buzul ve çöl

Dünya alanı 2,5 katına, 3.000×2.400 stud'a çıkarıldı. Tek dev zemin yerine dokuz zemin parçası Roblox'un 2.048 stud parça sınırını aşmadan yüzeyi kaplar. Beş biyomun her birinde dört normal yaratık ve beş toplama düğümü vardır. Batıdaki Buzul Çamlığı seviye 8, doğudaki Güneş Kırığı Çölü seviye 11 için önerilir; seviye bir giriş kilidi değildir.

Karlı çamlar, buz sütunları ve donmuş göl; kaktüsler, kumtaşı sütunları ve vaha ile görsel fark oluşturur. Bölge adı ve önerilen seviye HUD'a yansır, yerel renk geçişi sadece bakan oyuncuyu etkiler. Rastgele dekorlar yol koridorlarından ve türbelerden uzak tutulur. Küçük seyahat platformları Persistent streaming modeli kullanır; uzak zeminin yüklenmesi sırasında varış noktasında bir taban bırakır.

Seferin beşinci ve altıncı aşaması sekizer yeni bölge yaratığı ister. Önceki sürümün tamamlanmış işareti olan aşama 5, artık yeni seferin başlangıcıdır; eski ödüller tekrar alınmaz. Yeni düğümler mevcut demir ve köz stoklarını kullanır. Pet düşüren bosslar üç mevcut karşılaşmada kalır; yeni boss veya pet eklenmiş gibi gösterilmez. Canlı sunucu performansı ve fizik doğrulaması Studio/yayınlanmış test gerektirir.

## Pet eğitimi ve bölgesel elitler

Petler, kazanıldıktan sonra da savaş döngüsünde gelişir. Kuşanılmış ve sahip olunan pet normal öldürmeden 4, kişisel elit ödülünden 12, kişisel boss ödülünden 30 XP alır. Grup elit desteği 4 pet XP verir. Birikimli XP, kayda yazılan tek eğitim değeridir; seviye ve hasar aynı eğriden türetilir. Tüm petler toplam 1.080 XP ile 10. seviyeye, 3/5/7/9. seviyelerde artan bonusla +8 hasara ulaşır. Görsel büyüme ve rünler kozmetiktir. Profil v5 yalnız sahip olunan petlerin XP alanlarını saklar; eski kayıtların eğitim XP'si sıfırdır.

Yeni bölgeler Buzul Devriyesi ve Kum Mızrağı elitlerini barındırır. Buzul saldırısı elitin çevresinde, çöl saldırısı seçilen oyuncunun başlangıç konumunda hazırlanır. Her iki alan da önceden işaretlenir. Gerçek konum, görüş hattı, güvenli bölge ve hareket güveni sunucu tarafından kontrol edilir. Saldırı başındaki merkez daha sonra oyuncuyu izlemez; kaçmak mümkündür.

Elit ödülleri iki kabul edilmiş isabet ve %1 hasar veren, canlı ve ölüm noktasından 120 stud içindeki oyunculara verilir. Sonra bu kişilerin uygun yakın grup üyeleri destek kümesine eklenir. Bir oyuncu hem kişisel hem destek adayıysa kişisel ödül üstün gelir; ortak küme aynı oyuncuya iki kez ödül vermez. Elitler pet düşürmez, boss garanti sayacını değiştirmez. Bu yaklaşım, bossların kişisel nadir koleksiyon döngüsünü korur.

Ölüm, geri çekilme, yeni karşılaşma ve kapanış saldırı neslini geçersiz kılar. Her gecikmiş saldırı karşılaşma kimliği/nesil/tek kullanım kontrolünden geçer. Yeniden doğuş 90 saniyedir. Birlikte testte bu servis akışı taklit ortamında denetlenebilir; Roblox fizik ve streaming sonucu olarak sunulmaz. Studio kontrol planı bu ayrımı korur.

Sunucunun kabul ettiği gerçek can azalması ve iyileştirme, eylemi yapan oyuncuya kısa süreli sayılarla gösterilir. Bu sayılar hasar isteği üretmez. Örneğin 2 canı kalmış hedefe 40 hasarlık vuruş 2 olarak görünür. Derleme sonrasında XML'deki tüm kaynaklar ve Script/LocalScript/ModuleScript türleri dosyalarla karşılaştırılır; eksik veya eski kaynak içeren çıktı hata verir.
