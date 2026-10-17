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
