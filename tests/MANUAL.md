# Roblox Studio doğrulama planı

Bu senaryolar otomatik test sonucu değildir. Studio ve yayınlanmış özel test deneyiminde uygulanmalıdır.

1. **İlk giriş:** Oyunu başlat; Türkçe HUD, güvenli başlangıç alanı, NPC ve düşmanlar görünmeli. Görev henüz alınmadan öldürülen düşman görev ilerlemesi vermemeli.
2. **Görev döngüsü:** NPC'ye yaklaş, görevi al, üç düşmanı yen ve NPC'ye dön. Sayaç doğru ilerlemeli; teslimde XP, altın ve ödül tam bir kez verilmeli. Tekrarlanan etkileşim aynı ödülü çoğaltmamalı.
3. **İki oyuncu:** Studio `Start Server` ile iki istemci aç. Grup kurmadan bir oyuncunun normal yaratık ödülü diğerine aktarılmamalı; düşman ölümü ve yeniden doğması iki istemcide tutarlı görünmeli. Grup ödülleri aşağıdaki ayrı senaryoya göre paylaşılır.
4. **Saldırı sınırları:** Düşmandan uzakta, ölüyken ve saldırı düğmesine hızla basarak dene. Mesafe ve bekleme süresi dışındaki girişler hasar vermemeli. İstemci tarafından gönderilen sahte hedef veya hasar değeri ödül sağlamamalı.
5. **NPC güvenliği:** NPC'den uzakta görev etkileşimi göndermeyi ve görev tamamlanmadan teslimi dene. Sunucu isteği reddetmeli.
6. **Düşman davranışı:** Düşmanı başlangıç noktasından uzaklaştır, güvenli alana çek ve oyuncuyu öldürt. Düşman belirlenen sınırda geri dönmeli; güvenli alanda hasar vermemeli; öldüğünde yalnızca bir kez yeniden doğmalı.
7. **Ölüm ve yeniden doğma:** Öl, yeniden doğ ve tekrar saldır. HUD tek kopya kalmalı; sağlık yeni karakteri izlemeli; eski karakter bağlantıları yeni sağlığı bozmamalı.
8. **Mobil:** Studio cihaz emülatöründe küçük yatay ve dikey ekranları kontrol et. HUD kırpılmamalı; saldırı düğmesi hareket/atlama kontrollerini engellememeli; görev metni okunmalı.
9. **Kalıcılık:** Kalıcılık etkinse ayrı yayınlanmış test deneyiminde ilerle, çık ve yeniden gir. XP, altın ve ödül geri gelmeli. Yükleme hatası veya kapalı API erişimi mevcut profili boş verilerle ezmemeli; kullanıcıya açık durum bildirilmeli.

Sonuçları tarih, Studio sürümü, oyuncu sayısı ve görülen hatalarla birlikte kaydet.

## Windows GitHub / Rojo bağlantısı

Bu kontroller Windows bilgisayarında yapılmalıdır; Linux üzerinde başarılı PowerShell sözdizimi kontrolü bunların geçtiği anlamına gelmez.

1. Kurulum dalını temiz bir klasöre klonla. Studio kapalıyken `powershell -NoProfile -File .\scripts\studio.ps1 -SetupOnly` çalıştır; CLI ve eklenti sürümü 7.7.1 olmalı. İkinci çalıştırma aynı doğrulanmış dosyaları kullanmalı.
2. Farklı bir Rojo eklentisi bulunan ayrı test klasörünü `-PluginDirectory` ile seç; yardımcı mevcut dosyayı değiştirmeden durmalı. Gerçek eklentilerini silmeden test et.
3. Yardımcıyı normal çalıştır, Studio'da boş Baseplate aç ve Rojo ile `localhost:34872` adresine bağlan. Değişiklikleri inceleyip kabul et; Play ile görev döngüsünü dene.
4. Yerel bir kaynak dosyasındaki geçici değişikliğin Studio'ya ulaştığını kontrol edip değişikliği geri al. Studio'daki değişikliğin otomatik Git commit veya Roblox yayını oluşturmadığını doğrula.

## Açık dünya, boss ve pet doğrulaması

Bu kontroller de henüz Studio'da uygulanmış sayılmaz.

1. **Üç bölge:** Köyden orman, bataklık ve köz bölgesine yürü. Harita işareti konuma uymalı, harita adları bölge tabelalarıyla eşleşmeli; bağlantı yolları geçilebilir olmalı. Düşmanlar ilgili bölgenin sağlık/hasar değerlerini kullanmalı, güvenli köyde oyuncuya hasar verilmemeli. Bölge dışına gidip geri dönerek streaming sonrasında modellerin yeniden göründüğünü kontrol et.
2. **Demo ve gerçek saat:** Studio'da ilk boss yaklaşık 20. saniyede, sonrakiler başlangıçtan 200 ve 380. saniyelerde çıkmalı. Bunlar test takvimidir. Yayınlanmış özel testte UTC saat başı/:20/:40 kontrol edilmeli; İstanbul ekranı UTC+3 göstermeli. Saniyelerce geciken bir sunucu güncellemesi aynı bossu iki kez çıkarmamalı.
3. **Karşılaşma ömrü:** Boss yenildiğinde aynı zaman diliminde yeniden çıkmamalı. Süresi dolduğunda kaybolmalı ve ödül vermemeli. Studio boss sağlığı normalin %30'u olmalı; %1 katılım eşiği de bu gerçek sağlığa dayanmalı.
4. **Kişisel katılım:** İki oyuncu da aynı bossun en az %1 canı kadar, en az üç kabul edilmiş vuruş yapsın. Son vuruşu yalnız biri yapsa da iki oyuncu kişisel ödül almalı. Bir veya iki vuruş yapan, yalnız yakınında bekleyen veya yalnız normal düşman kesen oyuncu boss ödülü almamalı.
5. **Savaş güvenliği:** İstemciden hedef, hasar, rastgele sayı, pet kimliği veya ödül isteyen sahte Attack argümanları gönder. Sunucu bunları kabul etmemeli. Bossun işaretli alan saldırısından çıkınca hasar alınmamalı; süresi dolmuş/yenilmiş bossun gecikmiş saldırısı işlememeli.
6. **Geri çekilme:** Bossu başlangıcından yeterince uzaklaştır. Geri dönüp sağlığını yenilediğinde eski katılım sıfırlanmalı; farklı denemeler biriktirilerek ödül alınmamalı.
7. **Pet koleksiyonu:** Yalnız sahip olunan pet kuşanılabilmeli. Bilinmeyen pet veya başkasının pet kimliği reddedilmeli. Tek pet kuşanılmalı; üç pet de aynı +4 saldırı katkısı sağlamalı. Kozmetik takipçi ölüm/yeniden doğma, kuşanma değiştirme ve iki oyuncuda çoğalmamalı.
8. **Düşüş ve garanti:** Otomatik saf testler %3 sınırını, 30. uygun zafer garantisini ve kopya petin 10 yıldız tozuna dönüşmesini kapsar. Studio'da ödül/garanti sayacının ekrana doğru taşındığını ayrıca doğrula; test kolaylığı için üretim düşüş oranını değiştirme.
9. **Kayıt geçişi ve tekrar giriş:** Ayrı yayınlanmış testte eski v1 profilin XP/altın/görevini koruduğunu, petler/kuşanılan pet/garanti sayaçlarının geri geldiğini kontrol et. Aynı global boss karşılaşmasına başka sunucuda tekrar katılmak ikinci ödül vermemeli. DataStore hatası durumunda boş veya kısmi profil kaydedilmemeli.

## Sınıf, yetenek, sefer ve demirci

1. Köyde savaşçı/büyücü arasında geçiş yap. Maksimum can, temel saldırı menzili ve silah görünümü doğru değişmeli. Yetenek kaynağı ve Q/R bekleme zamanları korunmalı; hasar aldıktan veya verdikten sonraki 10 saniyede sınıf değiştirilememeli.
2. Q/R yeteneklerini klavye, mobil düğme ve gamepad'de kullan. Geçersiz/duvar arkasındaki/menzil dışındaki hedefe saldırı ve tam candaki iyileştirme kaynak veya bekleme süresi tüketmemeli. Hızlı tekrar kullanım, sahte slot ve ek RemoteEvent argümanları sunucuda reddedilmeli.
3. Kaynak 100'ü aşmamalı, saniyede 8 yenilenmeli; yeniden doğma veya sınıf değiştirme bekleme süresini sıfırlamamalı. İstemci HUD sayacı GetServerTimeNow zamanıyla sunucuya uymalı.
4. Eski Eldrin görevi (3 orman düşmanı) ve sefer günlüğü (5 orman → 5 bataklık → 5 köz → 1 uygun boss) ayrı izlenmeli. Yanlış bölge ve yetersiz boss katılımı seferi ilerletmemeli. Her aşama yalnız oyuncunun teslimiyle ilerlemeli; tekrarlanan teslim ödülü çoğaltmamalı.
5. Demirciden uzakta geliştirme isteği reddedilmeli. Eksik altın veya son kontrol edilen eksik malzemede hiçbir ödeme alınmamalı; yalnız sıradaki kademe yapılmalı. Üç kademeden sonra tekrar istek kaynak tüketmemeli. Stat ve silah görseli kademeyle güncellenmeli.
6. Bir kaynak düğümünü topla; 30 saniye dolmadan aynı oyuncu yeniden alamamalı, başka oyuncu kendi hakkını kullanabilmeli. Uzaktan sahte ProximityPrompt tetikleme işe yaramamalı.
7. Ayrı yayınlanmış testte sınıf, kademe, malzemeler ve sefer ilerlemesinin yeniden girişte korunduğunu doğrula. Eski v1/v2 kayıtların altını, XP'si, görevi, peti ve boss garanti sayacı korunmalı.

## Grup, seyahat ve genişleyen biyomlar

Bu senaryolar henüz gerçek Studio test sonucu değildir.

1. **Grup daveti:** Beş istemci başlat. G ile davet gönder; kabul edilmeden katılım olmamalı. Yanlış davet kimliği, süresi dolmuş davet, tekrarlanan kabul, dört kişiden sonra beşinci katılım ve lider olmayanın davet/çıkarma isteği reddedilmeli. Davet alan mobil oyuncuda GRUP ! görünmeli; kabul/ret paneli kaydırılabilmeli.
2. **Liderlik ve ayrılma:** Lider normal ayrılma ve bağlantı kopmasıyla ayrılsın; kalan ilk üye lider olsun. Çıkarılan oyuncunun üyeliği temizlensin. Son üye ayrılınca grup silinsin. Eski solo davetini gönderen başka gruba katılınca bu davet artık kabul edilememeli.
3. **Normal ödül:** Aynı gruptaki üç oyuncudan biri son vuruş yapsın. Tam XP son vuruşa, canlı ve 100 stud içindeki üyelere %70 XP gitmeli; her alıcı tam bir malzeme ve uygun görev/sefer ilerlemesi almalı. Orman dışındaki öldürme Eldrin görevini ilerletmemeli. Ölü, uzaktaki, grupta olmayan ve güvenilmeyen konumdaki oyuncu paylaşım almamalı.
4. **Boss istisnası:** Dört kişilik grupta yalnız iki oyuncu en az 3 isabet ve %1 hasar yapsın. Diğer iki üye yakında dursa bile boss XP/altın, sefer boss ilerlemesi ve pet şansı alamamalı.
5. **Keşif:** Yeni profil yalnız köy türbesini açmalı. Beş biyomun türbelerine yürüyüp E kullan; her biri kişisel haritada açılsın. Uzaktan sahte prompt/RemoteEvent keşif açmamalı. Başka oyuncunun keşfi senin haritanı açmamalı.
6. **Seyahat:** Türbe yakınında keşfedilmiş farklı hedef seç; 3 saniye sonunda platforma varılmalı. Aynı hedef, kilitli hedef, türbeden uzaklık, ölüm ve son 10 saniyede savaş reddedilmeli. Hazırlıkta 3 stud'dan fazla hareket, zıplama, hasar, saldırı, karakter değişimi ve çıkış işlemi iptal etmeli. Spam tek kanaldan fazla oluşturamamalı; eski gecikmiş hazırlık yeni karakteri taşımamalı.
7. **Varış ve hareket:** Önceden görüntülenmemiş uzak türbeye git. Platform/zemin yüklenirken düşme, anti-teleport tarafından geri çekilme veya duvar içine doğma olmamalı. Enerji, yetenek cooldown'ları ve grup korunmalı. Varış koruması 3 saniyede kalkmalı.
8. **Yeni biyomlar:** Kuzey kavşağından buzula ve çöle yürü; yollar dekorla kapanmamalı. Buzulda kar, çam, donmuş göl; çölde kaktüs, harabe, vaha görünmeli. HUD isim/seviye ve yerel renk geçişi doğru değişmeli; farklı biyomdaki ikinci oyuncunun renkleri etkilenmemeli. Dokuz zemin parçasının sınırlarında düşme veya boşluk olmamalı.
9. **Yeni gelişim:** Buzul yaratığı 80 XP/demir, çöl yaratığı 110 XP/köz vermeli. Beşinci/altıncı sefer sekiz doğru bölge yaratığı ile tamamlanmalı; erken kesimler ve boss bu aşamaları ilerletmemeli. Önceden dört aşamayı tamamlamış v3 profil beşinciden başlamalı; eski ödüller tekrar verilmemeli.
10. **Arayüz ve kayıt:** 320×568 dikey ve 568×320 yatay cihazları safe-area ile dene. Grup/harita/pet/karakter panelleri kaymalı; ana menü, seyahat, davet kabul/ret ve kapat düğmeleri kullanılabilir kalmalı. Gamepad D-pad sol/yukarı, L3, Y, B ile menüleri dene. Ayrı özel deneyimde keşifler yeniden girişte korunmalı; grup ve devam eden seyahat korunmamalı.

## Pet eğitimi ve bölgesel elitler

1. Sahip olduğun peti kuşan, normal yaratık yen: yalnız kuşanılmış pet 4 XP almalı. İkinci petin XP'si değişmemeli. Bossun uygun kişisel ödülü 30 XP, kişisel elit ödülü 12 XP, grup elit desteği 4 XP vermeli. Pet kuşanılmamışsa pet XP artmamalı.
2. Pet XP'si 40 olduğunda seviye 2, 100 olduğunda seviye 3 olmalı. Seviye 3/5/7/9'da hasar katkısı sırasıyla +5/+6/+7/+8; seviye 10'da toplam 1080 XP sınırı olmalı. HUD, karakter hasarı ve kozmetik pet seviyesi aynı kalmalı. Yeniden kuşanma, ölüm ve tekrar giriş XP'yi çoğaltmamalı veya sıfırlamamalı.
3. Buzul Devriyesi kendi bulunduğu noktada 1,5 saniye önceden işaretlenen 14 stud yarıçaplı patlama hazırlamalı. Kum Mızrağı oyuncunun saldırı hazırlığı başındaki konumunu 1,2 saniye önceden işaretlemeli; oyuncu hareket edince işaret onu takip etmemeli. İşaretten kaçmak, duvar arkasında kalmak ve güvenli alana girmek hasarı önlemeli.
4. Eliti saldırı hazırlanırken öldür, 130 stud dışına çekerek geri döndür veya sunucuyu kapat. Eski işaret kaldırılmalı; gecikmiş saldırı hasar vermemeli. Geri dönen elitin canı ve katılım sayacı sıfırlanmalı. Öldükten yaklaşık 90 saniye sonra tek kopya yeniden doğmalı.
5. İki oyuncu elitin en az %1 canına ve iki kabul edilmiş isabete ulaşsın. İkisi de tek kişisel ödül almalı; aynı grubun yakın, canlı ve güvenilir diğer üyesi yalnız tek destek ödülü almalı. Kişisel katılımı olan üyeye ayrıca destek ödülü verilmemeli. Ölü, uzaktaki ve katkısız solo oyuncu ödül almamalı.
6. Elitlerden pet düşmemeli; boss düşüş oranı ve garanti sayacı değişmemeli. Yüksek altın bakiyesinde elit ödülü bakiyeyi azaltmamalı. Eski v1-v4 kayıtlarda sınıf, donanım, keşif, sefer, pet ve boss sayaçları korunmalı; eski petler eğitim XP'sine sıfırdan başlamalı.
7. Hasar sayıları yalnız saldırıyı yapan oyuncuda görünmeli. Hedefin 2 canı varken daha güçlü bir vuruş 2 göstermeli. 95/100 cana iyileştirme +5 göstermeli; tam candaki iyileştirme ve korumalı hedefte hiç sayı çıkmamalı. Alan saldırısında her hedef ayrı sayı almalı. Yeniden doğunca eski sayılar temizlenmeli; hızlı savaşta aynı anda 30 sayı sınırı aşılmamalı.
8. Harita açıkken bir elitin saldırı hazırlığına girmesini izle. 1,2/1,5 saniyelik uyarı, 3 saniyelik olağan güncellemeyi beklemeden görünmeli. Elit ölünce ya da geri çekilince eski uyarı kapanmalı; canı sıfır olmuş fakat Died olayı henüz işlenmemiş elitin gecikmiş saldırısı hasar vermemeli.

Bu yeni senaryoların gerçek Studio ve yayınlanmış özel test uygulaması ayrıca yapılmalıdır.

## Bölgesel sözleşmeler, yaratık davranışları ve hedef seçimi

1. Beş bölgenin görev panosunda sözleşmeyi al. Kabul öncesindeki yaratık öldürme ve toplama sayılmamalı; daha önce keşfedilmiş ilgili türbe geçerli olmalı. Kabul sonrasında 5 bölge yaratığı ve 3 başarılı kaynak toplama etkileşimi gerekli. Başka bölgedeki ilerleme bu sözleşmeye yazılmamalı.
2. Panodan 14 stud'dan uzakta, ölüyken veya güvenilmez konumda kabul/teslim isteği reddedilmeli. Hazır sözleşme panoda tek ödül vermeli; hızlı çift tıklama, tekrar giriş ve tekrar teslim ikinci ödül vermemeli. Sözleşme pet XP'si vermemeli. Tüm eski kayıt alanları yeni şema yüklemesinden sonra korunmalı.
3. Orman düşmanı yakın menzilde doğrudan saldırmalı. Bataklık ve çöl yaratıkları oyuncunun hazırlık başındaki konumuna sabit işaret bırakmalı; işaret hareket eden oyuncuyu izlememeli. Köz yaratığı kendi konumunda patlama, buzul yaratığı kısa hazırlıklı yakın saldırı yapmalı. İşaretten çıkmak ve duvar arkasına geçmek saldırıyı önlemeli.
4. Yaratığı hazırlık sırasında öldür, başlangıcından 100 stud dışına çek veya yeni karşılaşmayla değiştir. Eski saldırı hasar vermemeli. Geri dönüşte can ve son saldıran bilgisi sıfırlanmalı; eski oyuncuya sonradan ödül yazılmamalı. Normal düşman tek kopya olarak 8 saniye sonra yeniden doğmalı.
5. Tab, gamepad R3 ve mobil hedef düğmesiyle yakındaki görünür hedefler arasında geç. Seçili hedefin adı, türü, canı ve uzaklığı güncellenmeli. Ölüm, duvar, mesafe veya streaming nedeniyle kaybolan hedef temizlenmeli. Hedef seçmek saldırının sunucu menzilini artırmamalı; sahte oyuncu/NPC/model hedefi hasar almamalı.
6. Küçük yatay/dikey ekranlarda hedef paneli, görev listesi ve yetenek düğmeleri üst üste binmemeli. Günlükte hedefler açık görünmeli; teslim için ilgili panoya dönülmesi gerektiği anlaşılmalı.

Saf kurallar ve taklit ortamındaki servis akışları otomatik test edilmiştir; bu liste gerçek Studio oynanış uygulamasının yerini tutmaz.

## Keşif kampları ve kişisel sandıklar

1. Beş kampta giriş keşif işaretiyle etkileş. Keşif savaş sırasında da kaydedilebilmeli; hareket/savaş kontrollerini kapatan günlük kendiliğinden açılmamalı. Harita işareti ve keşif günlüğü kişisel ilerlemeyi göstermeli.
2. Bir muhafız hayattayken sandık açılmamalı. Tam iki kayıtlı muhafız yenildikten sonra sandık her oyuncuya ayrı, tek seferlik ödül vermeli. Eksik/başarısız muhafız oluşturma, fazladan kayıt veya kapanan servis alanı temiz saymamalı.
3. Sandıktan 14 stud'dan uzakta, ölüyken veya son hasar verme/alma üzerinden 5 saniye geçmeden istek reddedilmeli. Tam 5 saniye sınırında, canlı ve güvenilir konumdaki oyuncu açabilmeli. UI'da temiz görünen alanın muhafızı arada doğarsa sunucu sandığı kilitlemeli.
4. Muhafızlar 45 saniye dolmadan yeniden doğmamalı; sonra tek kopya doğmalı ve alan tekrar kilitlenmeli. Oyuncunun önceden aldığı kişisel sandık ödülü tekrar açılmamalı. İkinci oyuncu aynı ortak temizlikten kendi tek ödülünü alabilmeli.
5. Hızlı tekrar istek, tekrar giriş veya keşif işaretine yeniden basma ödülü çoğaltmamalı. Ödül yalnız oyuncu XP'si, altın ve üç bölge malzemesi vermeli; pet veya pet XP'si vermemeli. Altın/malzeme sınırında kayıt bozulmamalı.
6. Yayınlanmış özel testte v1-v6 profillerin sınıf, donanım, pet eğitimi, boss sayaçları, görevleri ve türbe keşfi korunmalı. Yeni kamp keşifleri ve kişisel sandıklar yeniden girişte kalmalı. Mobilde beş kart kaydırılabilir, 44 px düğmeler kullanılabilir olmalı.

7. İki oyuncudan yalnız biri sandık ödülünü alsın: yalnız onda kapak açık ve altınlar gizli olmalı; diğerinde kapalı kalmalı. Kampı streaming dışına çıkarıp geri gelince ve karakter yeniden doğunca kişisel görünüm korunmalı. İkinci oyuncu da ödül alınca onun kapağı açılmalı.
8. Beş yol kolunda ve 10 stud genişliğindeki köprülerin iki girişinde yürüyüp zıpla. Korkuluklar, keşif taşı, kamp binaları ve sandık ortadaki geçişi engellememeli. Düşme, takılma ve zemin yüklenme boşluğu olmamalı.

Otomatik testler saf ödül kurallarını ve gerçek servis metotlarının taklit edilmiş oyuncu/konum/guard akışlarını kapsar; Studio fiziği, görünüm ve gerçek DataStore ayrı doğrulanmalıdır.

## v8 görsel yenileme ve performans

1. Köyden beş bölgeye, türbelere ve keşif kamplarına yürü. Yeni bina, köprü ve çevre süsleri yolu, NPC/pano/keşif/sandık promptlarını veya iki muhafızın hareketini kapatmamalı. Işık ve renkler değişirken saldırı uyarıları, hedef canı ve güvenli bölge sınırı okunmalı.
2. Normal yaratık, elit ve boss modellerinde vuruş/LOS denetimini karşılaştır. Dekoratif boynuz, kanat, parçacık ve yerel petler saldırıyı engellememeli; duvar gibi gerçek engellerden hasar geçmemeli. Tüm hasar, pet sahipliği ve ödül kararları sunucuda kalmalı.
3. Düşük grafik ayarında ve mobil cihazda köy, yoğun orman, üç boss alanı ve iki elit alanını dolaş. Kare süresi, bellek, parça sayısı ve parçacık yoğunluğunu Studio istatistikleriyle gözle. Streaming sırasında boşlukta kalma, yarım kamp veya kaybolan prompt oluşmamalı. Otomatik kaynak kontrolü gerçek cihaz performansı ölçümü değildir.
4. 320×568 ve 568×320 gibi küçük ekranlarda yeni tema, başlıklar, hedef paneli, enerji/yetenek düğmeleri ve kaydırılan günlükleri kontrol et. Dokunma hedefleri en az 44 px olmalı; hareket/atlama kontrolleri kapanmamalı. Menü veya sohbet açıkken savaş tuşları işlememeli.
5. Pet önizlemeleri ve dünyadaki pet görünümü için sahip olunan/sahip olunmayan, farklı seviye ve kuşanma durumlarını dene. Önizleme yeni ödül veya sahiplik üretmemeli. Menü tekrar açıldığında kamera, model, bağlantı veya animasyon sayısı birikmemeli; ölüm/yeniden doğma sonrasında tek görünüm kalmalı.
6. Aynı anda dört oyuncuyla savaş, büyü, pet ve ortam efektlerini çalıştır. Ekrandaki çizim ve parçacık bütçesi kabul edilebilir kalmalı; kozmetik parçalar karaktere çarpmamalı, raycast hedefi olmamalı veya sunucu savaş hesabını değiştirmemeli.

Yapı taklit denetimi ve kaynak incelemesi yalnız kurulum/API/ölçü tutarlılığını sınar. Işık, model görünümü, fizik, gerçek streaming ve cihaz performansı Studio veya gerçek istemcide ayrıca değerlendirilmelidir.

Ek v8 kontrolleri:

- İki istemciyi farklı bölgelere götür. Her istemcide 110 stud içindeki en yakın en fazla 12 dünya ışığı yaklaşık 0,7 saniyede seçilmeli; bir istemcinin ışık/atmosfer ayarı diğerini değiştirmemeli. Arayüz kapanınca önceki yerel ışık durumu geri gelmeli.
- Yaklaşan, duran, ölen ve yeniden doğan yaratıkları izle. Yerel yürüyüş hareketi kök konumu, hasar menzili veya sunucu hareketini değiştirmemeli. Uzaklaşınca/streaming çıkışında hareket temizlenmeli; yakın kristalin iç ve dış parçaları birlikte hareket etmeli. Kamera ve petler yürürken titreme veya biriken görünüm oluşmamalı.
- İki oyuncuda pet koleksiyonunu tekrar açıp kapat. Üç boyutlu önizleme kameraları doğru peti göstermeli; sahiplik ve seviye yalnız ilgili oyuncunun kayıtlarına uymalı. Yeni görünüm pet düşürme, kuşanma veya ödül kararı vermemeli. Gerçek render döngüsü, kamera görüntüsü ve fizik bu otomatik kaynak denetiminde çalıştırılmamıştır.

## v9 savaş ve ödül sunumu

1. İlk girişte mevcut seviye, altın, donanım, pet ve sandık kayıtları yüklenirken kutlama çıkmamalı. Yeni kazanımlarda tek özet kart gösterilmeli; aynı State tekrarı veya daha eski feedbackRevision kutlamayı yenilememeli. Sözleşme/sandık toplu ödülünde XP ve altın toplamları gerçek sunucu artışına uymalı.
2. Seviye sınırını aşan XP ödülünü ve aynı anda pet/seviye/donanım kazanımını dene. Birikmiş XP doğru hesaplanmalı; öncelikli kart diğer kazanımları sonraki aynı State'te tekrar kutlamamalı. Altın harcama kayıp veya sahte kazanç olarak gösterilmemeli; harcama sonrasındaki gerçek ödül doğru görünmeli.
3. Normal yaratık, elit ve boss ad/can çubuklarını farklı uzaklıklarda incele. Aynı anda en fazla 12 özel etiket olmalı; ölüm, yeniden doğma, streaming çıkışı ve arayüz kapanışında eski yerleşik etiketler doğru geri gelmeli. Çubuklar duvarın arkasından görünmemeli, dokunma veya hedef seçimini engellememeli.
4. Savaşçı alan darbesi ile büyücü alan büyüsünün renk/şekil farkını, mermi ve iyileştirme sunumlarını karşılaştır. İsabet kıvılcımları ve sayılar yalnız sunucunun kabul ettiği gerçek can değişiminde görünmeli; tam candaki iyileştirme, boşa veya engellenmiş vuruş sahte sayı üretmemeli.
5. Dört istemciyle yoğun saldırıda yerel efekt parçası sınırı 100, isabet sayısı görünümü sınırı 30 ve ödül kuyruğu sınırı korunmalı. Ölüm/yeniden doğma ve GUI kaldırma sonrasında efekt, bağlantı, kart veya sayı kalmamalı. Görsel efektler fizik/raycast ve sunucu hasarını değiştirmemeli.
6. Küçük mobil ekran ve gamepad'de ödül kartının hareket/atlama/yetenek kontrollerini veya hedef canını kapatmadığını kontrol et. Kartlar sohbet/modal açıkken etkileşimi ele geçirmemeli. Kamera sarsıntısı veya istemciden yeni ödül/hasar isteği üretilmemeli.

Saf feedback testleri hesap ve tekrar korumasını sınar. Gerçek çizim, BillboardGui görünümü, efekt zamanlaması ve düşük cihaz performansı Studio/istemciyle ayrıca kontrol edilmelidir.

## v10 yolculuk önerileri ve etkileşim sunumu

1. Yeni profilde Eldrin'e gitme, görev etkin olduğunda ormana gitme ve hedef tamamlandığında Eldrin'e dönme önerilerini izle. Eski görev tamamlanmışsa günlük oyuncuyu sürekli aynı görevi yeniden almaya zorlamamalı. Sefer ve bölge sözleşmesi teslimi hazır olduğunda doğru günlük/pano önerilmeli.
2. Canlı ve seviyeye uygun dünya bossu önerisini, süresi dolmuş/ölmüş/henüz çıkmamış boss bilgileriyle karşılaştır. Eski State veya WorldState, oyuncuyu ölü ya da süresi dolmuş hedefe göndermemeli. Öneri ödül veya boss katılım koşulunu değiştirmemeli.
3. Keşfedilmemiş türbe, kamp ve açılmamış kişisel sandık önerilerini dene. Yakınlık sırası ve eşit uzaklıkta sıralama kararlı olmalı; keşif veya sandık tamamlanınca eski öneri listeden kalkmalı. Yanlış/eksik konum bilgisi dünya işareti oluşturmamalı.
4. Haritadaki önerilerden birini sabitle, tamamla veya geçersiz hale getir. Sabitleme yalnız bu istemcide kalmalı; yeni hedef eski işareti temizlemeli. İşaret sınırı, mesafe gizleme, modal açıkken gizlenme, ölüm/yeniden doğma ve GUI kapanışında temizleme kontrol edilmeli.
5. Küçük dikey/yatay ekran ve gamepad'de görev kutusunun yeni başlık/açıklama/mesafe satırları kayıt durumunu veya hareket/yetenek düğmelerini kapatmamalı. İsteğe bağlı harita öneri kartları en az 44 px düğme ve kaydırma alanıyla kullanılmalı.
6. Bölgeye giriş ve etkileşim efektlerini iki oyuncuyla dene. İstemci efektleri yeni ödül/hasar isteği üretmemeli; keşif, toplama, üretim ve sandık ödülleri yalnız sunucu onayından sonra görünmeli. Tekrar etkileşim, profil yükleme veya eski snapshot sahte başarı gösterimi üretmemeli.

Saf öneri testleri karar mantığını ve girdi güvenilirliğini kontrol eder. Gerçek yönlendirme görünümü, render zamanlaması, fizik ve mobil kullanım Studio/istemcide ayrıca doğrulanmalıdır.

Sabitleme regresyonu: Otomatik öneri sayısı altıdan fazla olduğunda daha düşük öncelikli bir hedefi sabitle ve 350 stud dışına yürü. Hedef tamamlanmadıkça sabitleme korunmalı; ölüm/yeniden doğma sırasında kök parçasının geçici yokluğu sabitlemeyi silmemeli. Tamamlanan keşif/sandık veya süresi dolan boss sabitlemesi ise bırakılmalı; altı kart sınırı korunmalı.
