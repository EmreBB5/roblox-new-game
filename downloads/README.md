# Studio oyun dosyası

`Aetheria.rbxl`, `d20da2c4dc826c96dd5db11a9419579280486d3f` kaynak sürümünden Rojo 7.7.1 ile üretilmiş bağımsız Studio dosyasıdır. Doğrudan indirme için depoda tutulur.

Bu sürüm beş biyom, 3.000×2.400 stud dünya, dört kişilik grup, altı keşif türbesi, altı sefer aşaması, pet eğitimi, iki elit, beş bağımsız bölge görevi ve Tab/R3/HEDEF seçimini içerir. Normal yaratık saldırıları bölgelere göre farklıdır. Profil v6 eski ilerlemeyi korur.

Altı saf Luau paketinde 1.000 ve gerçek servis/modül kaynaklarını kullanan dört sınırlı akış taklidinde 215 doğrulama geçti (toplam 1.215). Bütün Luau dosyaları derlendi, saf mantık analizi ve 34 kaynak/tür dışa aktarım eşitliği doğrulandı. Bu kontroller gerçek Studio oynanış/fizik/çoklu istemci/kalıcılık testi değildir; Linux ortamında Studio çalıştırılmamıştır.

Dosya: 88,748 bayt. SHA-256: `7d1f1733cbddbcbe6bd121ae32e86000df2a2b69fca8a795c11b40c3c398df23`.

Studio'da **Ctrl+O** ile bu dosyayı aç, **F5** ile başlat. Dünya Play sırasında oluşturulur. Önceki indirdiğin oyun dosyasının ayrı bir kopyasını koru.

Yeni bir oyun sürümü yayımlanırken önce `bash scripts/check.sh` çalıştır, ardından `rojo build default.project.json --output build/Aetheria.rbxl` ile üret ve doğrulanmış çıktıyı buradaki dosyaya kopyala. Kurulum veya başlangıç scriptleri bu takip edilen dosyayı otomatik değiştirmez.
