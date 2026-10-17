# Studio oyun dosyası

`Aetheria.rbxl`, `da8988bc14963268c1d8fa841cbfd43a40caa486` kaynak sürümünden Rojo 7.7.1 ile üretilmiş bağımsız Studio dosyasıdır. Doğrudan indirme için depoda tutulur.

Bu sürüm beş biyom, 3.000×2.400 stud dünya, dört kişilik grup, altı keşif türbesi, altı sefer aşaması, seviye 10'a kadar pet eğitimi, iki bölgesel elit ve doğrulanmış hasar/iyileştirme sayıları içerir. Profil şeması v5 eski ilerlemeyi korur.

Beş saf Luau paketinde 707, gerçek EliteService kodunu kullanan sınırlı sunucu akışı taklitlerinde 68 doğrulama geçti (toplam 775). Bütün Luau dosyaları derlendi, saf mantık analizi ve 28 kaynak/tür dışa aktarım eşitliği doğrulandı. Bu kontroller gerçek Studio oynanış/fizik/çoklu istemci/kalıcılık testi değildir; Linux ortamında Studio çalıştırılmamıştır.

Dosya: 77,861 bayt. SHA-256: `78eab8341c954ba57ac3c9ef564d303be3fdc18e02f0382521966fccac9fc79b`.

Studio'da **Ctrl+O** ile bu dosyayı aç, **F5** ile başlat. Dünya Play sırasında oluşturulur. Önceki indirdiğin oyun dosyasının ayrı bir kopyasını koru.

Yeni bir oyun sürümü yayımlanırken önce `bash scripts/check.sh` çalıştır, ardından `rojo build default.project.json --output build/Aetheria.rbxl` ile üret ve doğrulanmış çıktıyı buradaki dosyaya kopyala. Kurulum veya başlangıç scriptleri bu takip edilen dosyayı otomatik değiştirmez.
