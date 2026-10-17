# Roblox Studio doğrulama planı

Bu senaryolar otomatik test sonucu değildir. Studio ve yayınlanmış özel test deneyiminde uygulanmalıdır.

1. **İlk giriş:** Oyunu başlat; Türkçe HUD, güvenli başlangıç alanı, NPC ve düşmanlar görünmeli. Görev henüz alınmadan öldürülen düşman görev ilerlemesi vermemeli.
2. **Görev döngüsü:** NPC'ye yaklaş, görevi al, üç düşmanı yen ve NPC'ye dön. Sayaç doğru ilerlemeli; teslimde XP, altın ve ödül tam bir kez verilmeli. Tekrarlanan etkileşim aynı ödülü çoğaltmamalı.
3. **İki oyuncu:** Studio `Start Server` ile iki istemci aç. Bir oyuncunun hasarı, görevi ve ödülü diğerine yanlış aktarılmamalı; düşman ölümü ve yeniden doğması iki istemcide tutarlı görünmeli.
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
