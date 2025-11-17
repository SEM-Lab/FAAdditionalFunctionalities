# FA Conversion Count - Test Scenarios

## Test Adımları

### 1. Item Card'dan Kontrol
1. Item Card aç (herhangi bir item)
2. **FA Conversion** grubuna git
3. **FA Conversion Count** alanını gör
4. Sayı doğru mu kontrol et

### 2. Item List'ten Kontrol
1. Item List sayfasını aç
2. Listede **FA Conversion Count** kolonunu gör
3. Her item için sayılar görünüyor mu kontrol et

### 3. Item Variants'tan Kontrol (Item Card'dan)
1. Item Card aç
2. Navigate → Variants'a git
3. Variant listesinde **FA Conversion Count** kolonunu gör
4. Her variant için sayılar görünüyor mu kontrol et

### 4. Item Variants'tan Kontrol (Direkt)
1. Item Variants sayfasını direkt aç
2. Listede **FA Conversion Count** kolonunu gör
3. Her variant için sayılar görünüyor mu kontrol et

### 5. Gerçek Zamanlı Güncelleme Testi
1. Bir item'ın FA Conversion Count'unu not et
2. O item için yeni FA Conversion oluştur
3. Sayfayı yenile
4. Count'un 1 arttığını kontrol et

## Başarı Kriterleri
- ✅ Tüm sayfalarda FA Conversion Count görünür
- ✅ Sayılar doğru
- ✅ Yeni conversion sonrası otomatik güncellenir
