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
