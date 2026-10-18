# Studio oyun dosyası

`Aetheria.rbxl`, `0c5f9ecddd6be209efded947924528676407beb7` kaynak sürümünden Rojo 7.7.1 ile üretilmiş bağımsız Studio dosyasıdır. Doğrudan indirme için depoda tutulur.

**v9 savaş ve kazanım sunumu:** sınıfa özgü kılıç yayları, büyü oku/alan halkaları ve iyileştirme efektleri; sunucunun doğruladığı isabet parıltıları ve pop animasyonlu sayılar. Yakındaki düşmanlarda isim/seviye/rol, boss/elit çerçevesi ve gecikmeli hasar izi var. Seviye, yeni pet, donanım, keşif ve sandık kazanımları tek pasif özet kartında birleştirilir. İlk profil yüklemesi ve eski/tekrar mesajlar kutlanmaz.

Önceki görsel yenileme, beş biyom, 3.000×2.400 stud dünya, dört kişilik grup, altı seyahat türbesi, altı sefer aşaması, pet eğitimi, iki elit, beş bölge görevi, Tab/R3/HEDEF seçimi, beş keşif kampı ve kişisel sandıklar bulunur. Kayıt şeması v7 eski ilerlemeyi korur. V8 köy/pazar/çeşme/landmarkları, 3B pet portreleri, yerel ışık bütçesi ve yaratık hareketi de dahildir.

Sekiz saf Luau paketinde 1.376 ve gerçek servis/modül kaynaklarını kullanan beş sınırlı akış taklidinde 274 doğrulama geçti (toplam **1.650**). Bütün Luau dosyaları derlendi, saf mantık analizi ve **45 kaynak/tür** için XML dışa aktarımı ve yerel Rojo API eşitliği doğrulandı. Bu kontroller gerçek Studio görünüm/fizik/çoklu istemci/kalıcılık/FPS testi değildir; Linux ortamında Studio çalıştırılmamıştır.

Yerel görsel sınırlar: 100 savaş efekti parçası, 30 isabet sayısı, 12 düşman etiketi ve 1 kart + 3 bekleyen kazanım özeti. Etiketler duvarın arkasından çizilmez ve salt görseldir; hasar/ödül kararı sunucudadır. Mobil yerleşim ve gerçek cihaz FPS test planı tests/MANUAL.md içindedir.

Dosya: 128,482 bayt. SHA-256: `39b8847dfa15277ae71bafaeb0d8d7c0d96716060ee3a9d0da35f6f639f192eb`.

Studio'da **Ctrl+O** ile bu dosyayı aç, **F5** ile başlat. Dünya Play sırasında oluşturulur. Savaşçı/büyücü yeteneklerini **Q/R**, pet koleksiyonunu **P**, haritayı **M** ile dene. Önceki indirdiğin oyun dosyasının ayrı bir kopyasını koru.

Yeni bir oyun sürümü yayımlanırken önce `bash scripts/check.sh` çalıştır, ardından `rojo build default.project.json --output build/Aetheria.rbxl` ile üret ve doğrulanmış çıktıyı buradaki dosyaya kopyala. Kurulum veya başlangıç scriptleri bu takip edilen dosyayı otomatik değiştirmez.
