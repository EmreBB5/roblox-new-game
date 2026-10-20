# Studio oyun dosyası

`Aetheria.rbxl`, `8f1b29c8b2edf9a49617898dc9f15c9baf1f10a8` kaynak sürümünden Rojo 7.7.1 ile üretilmiş bağımsız Studio dosyasıdır. Doğrudan indirme için depoda tutulur.

**v10 yolculuk rehberi:** mevcut görev kutusunda sıradaki hedef, mesafe ve pusula yönü; M haritasının altındaki altı öneriden kişisel hedef sabitleme. Geçerli hedef uzaklaşınca, sıralama değişince veya yeniden doğunca korunur; tamamlanan ve süresi dolan hedefler kaldırılır. Bölgelere girişte kısa başlıklar ve yakın native etkileşimlerde hafif zemin halkaları vardır. Kişisel keşfedilmiş kamp taşları ve alınmış sandıkların E istemleri yalnız ilgili oyuncuda gizlenir.

Önceki beş biyomlu 3.000×2.400 stud dünya, grup, altı seyahat türbesi, sefer/bölge görevleri, pet eğitimi, iki elit, beş keşif kampı ve kişisel sandıklar dahildir. V8 görsel kimliği ve 3B pet portreleri, V9 savaş efektleri/düşman göstergeleri/kazanım kartları da bulunur. Kayıt şeması v7 eski ilerlemeyi korur.

Dokuz saf Luau paketinde 1.491 ve gerçek servis/modül kaynaklarını kullanan beş sınırlı akış taklidinde 274 doğrulama geçti (toplam **1.765**). Bütün Luau dosyaları derlendi, saf mantık analizi, statik Enum denetimi ve **49 kaynak/tür** için XML dışa aktarımı ve yerel Rojo API eşitliği doğrulandı. Bunlar gerçek Studio görünüm/fizik/çoklu istemci/kalıcılık/FPS testi değildir; Linux ortamında Studio çalıştırılmamıştır.

Yeni görsel sınırlar: tek kısa giriş kartı, iki sekiz parçalı etkileşim halkası ve iki parçalı tek hedef işareti. Gösterilen yön düz hedef yönüdür; pathfinding veya otomatik seyahat değildir. Rehber, ödül veya hasar isteği üretmez. Küçük ekran, native istem, gerçek yüzeye işaret yerleştirme ve iki istemci senaryoları tests/MANUAL.md içindedir.

Dosya: 141,868 bayt. SHA-256: `e5cfb51365f18a605f24766c66ce81418535279b96e97caede4463ff06ddd254`.

Studio'da **Ctrl+O** ile bu dosyayı aç, **F5** ile başlat. Dünya Play sırasında oluşturulur. **M → en alta kaydır → Sıradaki Adımın → HEDEFİ TAKİP ET** ile hedef seç; aynı düğmeyle otomatiğe dön. **C** panelinde orman kristalini, **P** panelinde petleri görebilirsin. Önceki indirdiğin oyun dosyasının ayrı bir kopyasını koru.

Yeni bir oyun sürümü yayımlanırken önce `bash scripts/check.sh` çalıştır, ardından `rojo build default.project.json --output build/Aetheria.rbxl` ile üret ve doğrulanmış çıktıyı buradaki dosyaya kopyala. Kurulum veya başlangıç scriptleri bu takip edilen dosyayı otomatik değiştirmez.
