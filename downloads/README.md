# Studio oyun dosyası

`Aetheria.rbxl`, `48109b30483875a1386c9c9e1aa079c2371903af` kaynak sürümünden Rojo 7.7.1 ile üretilmiş bağımsız Studio dosyasıdır. Doğrudan indirme için depoda tutulur.

Bu sürüm beş biyom, 3.000×2.400 stud dünya, dört kişilik grup, altı keşif türbesi, altı sefer aşaması, pet eğitimi, iki elit, beş bağımsız bölge görevi, Tab/R3/HEDEF seçimi ve **beş yeni keşif kampını** içerir. Kamp yolları ve köprüleri, on muhafız, kişisel tek seferlik sandıklar ve M keşif günlüğü eklenmiştir. Alınan sandık yalnız ilgili oyuncuda açık/boş görünür. Profil v7 eski ilerlemeyi korur.

Yedi saf Luau paketinde 1.318 ve gerçek servis/modül kaynaklarını kullanan beş sınırlı akış taklidinde 274 doğrulama geçti (toplam **1.592**). Bütün Luau dosyaları derlendi, saf mantık analizi ve **37 kaynak/tür** için XML dışa aktarımı ve yerel Rojo API eşitliği doğrulandı. Sınırlı dünya yapım denetimi 1.108 statik parça, 9 zemin, 30 düşman doğum noktası, 5 kamp ve 50 köprü tahtasını oluşturdu; kritik etkileşim konumları ve parça boyutlarını kontrol etti. Bu kontroller gerçek Studio oynanış/fizik/çoklu istemci/kalıcılık testi değildir; Linux ortamında Studio çalıştırılmamıştır.

Dosya: 97,970 bayt. SHA-256: `b4123cbffa853d4d5c9d62f48ea9ca602e272a22724ab89cec0a892d3b9007bf`.

Studio'da **Ctrl+O** ile bu dosyayı aç, **F5** ile başlat. Dünya Play sırasında oluşturulur. **M** haritasındaki **?** işaretine yürü, taşta **E** ile keşfet, iki muhafızı yen ve 5 saniye savaş dışında kaldıktan sonra sandıkta **E** tut. Önceki indirdiğin oyun dosyasının ayrı bir kopyasını koru.

Yeni bir oyun sürümü yayımlanırken önce `bash scripts/check.sh` çalıştır, ardından `rojo build default.project.json --output build/Aetheria.rbxl` ile üret ve doğrulanmış çıktıyı buradaki dosyaya kopyala. Kurulum veya başlangıç scriptleri bu takip edilen dosyayı otomatik değiştirmez.
