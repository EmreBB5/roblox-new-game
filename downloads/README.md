# Studio oyun dosyası

`Aetheria.rbxl`, `f6cfc9da98b4b1ceb5678343286dfcfe060d307b` kaynak sürümünden Rojo 7.7.1 ile üretilmiş bağımsız Studio dosyasıdır. Doğrudan indirme için depoda tutulur.

**v8 görsel yenilemesi:** eğimli çatılar, ahşap kirişler, sıcak pencereler, çiçeklikler, kristal çeşme, pazar tezgâhları, fenerler ve beş biyoma özgü simgesel yapılar. Yaratıklara bölgesel zırh/siluet ayrıntıları ve sınırlı yerel yürüyüş hareketi; petlere yüzler ve tür ayrıntıları eklendi. Arayüz lacivert/turkuaz/altın temasına geçti; pet koleksiyonunda üç yerel 3B önizleme var. Biyoma göre renk/sis ve tek parçacık alanı kullanılır. Yakındaki en fazla 12 dünya ışığı, 24 hareketli yaratık ve 12 kristal parçası yerelde işlenir; gerçek cihaz FPS testi ayrıca gerekir.

Beş biyom, 3.000×2.400 stud dünya, dört kişilik grup, altı seyahat türbesi, altı sefer aşaması, pet eğitimi, iki elit, beş bölge görevi, Tab/R3/HEDEF seçimi, beş keşif kampı ve kişisel sandıklar bulunur. Kayıt şeması v7 eski ilerlemeyi korur.

Yedi saf Luau paketinde 1.318 ve gerçek servis/modül kaynaklarını kullanan beş sınırlı akış taklidinde 274 doğrulama geçti (toplam **1.592**). Bütün Luau dosyaları derlendi, saf mantık analizi ve **42 kaynak/tür** için XML dışa aktarımı ve yerel Rojo API eşitliği doğrulandı. Sınırlı dünya yapım denetimi **1.576 statik parça**, 9 zemin, 30 düşman doğum noktası, 5 kamp, 6 türbe, 282 landmark parçası ve beş bölge yaratığının kozmetik parçalarını kontrol etti. Bu kontroller gerçek Studio görünüm/fizik/çoklu istemci/kalıcılık/FPS testi değildir; Linux ortamında Studio çalıştırılmamıştır.

Dosya: 116,803 bayt. SHA-256: `183b97f3550523c596ef8e61187231db6552d3a644583f63cba011c9485a1145`.

Studio'da **Ctrl+O** ile bu dosyayı aç, **F5** ile başlat. Dünya Play sırasında oluşturulur. Yeni köyden açık dünyaya çık; **P** ile pet portrelerini, **M** ile biyom ve kamp haritasını aç. Muhafızları yendikten sonra sandıkları karakter başına bir kez alabilirsin. Önceki indirdiğin oyun dosyasının ayrı bir kopyasını koru.

Yeni bir oyun sürümü yayımlanırken önce `bash scripts/check.sh` çalıştır, ardından `rojo build default.project.json --output build/Aetheria.rbxl` ile üret ve doğrulanmış çıktıyı buradaki dosyaya kopyala. Kurulum veya başlangıç scriptleri bu takip edilen dosyayı otomatik değiştirmez.
