# Sabit Kıymet Ek Fonksiyonları Test Senaryoları

Bu doküman, Fixed Asset Additional Functionalities extension'ının test senaryolarını içeren yaşayan bir test dökümanıdır.

## İçindekiler
1. [Genel Gereksinimler](#genel-gereksinimler)
2. [Implementasyon Durumu](#implementasyon-durumu)
3. [Test Senaryoları](#test-senaryoları)
   - [Senaryo 1: Transfer Emri Sabit Kıymet Dönüşümü](#senaryo-1-transfer-emri-sabit-kıymet-dönüşümü-konum-testi)
   - [Senaryo 2: Konum Değişikliği (Amortisman Sonrası)](#senaryo-2-sabit-kıymet-konum-değişikliği-testi-amortisman-sonrası)
   - [Senaryo 4: Toplu FA Transfer Maddesi Oluşturma](#senaryo-4-toplu-fa-transfer-maddesi-oluşturma)
   - [Senaryo 5: FA Dönüşüm Sayısı Görüntüleme](#senaryo-5-fa-dönüşüm-sayısı-görüntüleme)

---

## Genel Gereksinimler

### Müşteri Talepleri (Teams Mesajından - 25.09.2025)
1. **✅ Transfer Receipt Location Mapping**: Transfer Receipt'ten FA dönüşümde konum bilgileri Current Location'a gelmeli
2. **❌ Field Edit Restrictions**: FA Card'da madde ve konum kodu değiştirme kısıtlaması
3. **✅ Bulk FA Transfer Item Creation**: Fixed Asset List'ten toplu transfer maddesi oluşturma
4. **❌ Location History Tracking**: Konum değişikliklerinin yaşam öyküsü
5. **❌ Item Depreciation Life**: Madde kartında ömür yıl alanı ve otomatik hesaplama
6. **✅ FA Conversion Count**: Varyant bazında dönüşüm sayısı görüntüleme

---

## Implementasyon Durumu

### ✅ Tamamlananlar
- **Toplu FA Transfer Maddesi Oluşturma**: Fixed Asset List'ten çoklu seçim destekleniyor
- **FA Dönüşüm Sayısı**: Sadece Item Variants'ta görüntülebiliyor
- **Posted Transfer Receipt Lines Görünümü**: FA Location Code ve Name alanları eklendi

### ❌ Eksikler
- Transfer Receipt'ten dönüşümde konum Current Location'a DEĞİL, FA Location Code'a yazılıyor
- Field edit restrictions yok - tüm kullanıcılar değiştirebiliyor
- Location history tracking yok
- Item depreciation life alanı ve otomatik hesaplama yok

---

## Test Senaryoları

### Senaryo 1: Transfer Emri Sabit Kıymet Dönüşümü Konum Testi

#### Ön Koşullar
- [ ] En az 2 farklı konum tanımlı (örn: MERKEZ, ŞUBE)
- [ ] Transfer edilebilir item tanımlı (FA No. Series, FA Posting Group dolu)
- [ ] FA Conversion Setup yapılmış

#### Test Adımları

**Adım 1: Transfer Emri Oluşturma**
1. Transfer Orders sayfasını açın
2. Yeni transfer emri oluşturun:
   - Transfer-from Code: MERKEZ
   - Transfer-to Code: ŞUBE
3. Item line ekleyin (qty: 1)
4. Transfer emrini release → ship → receive

**Adım 2: Posted Transfer Receipt Lines Kontrolü**
1. "Posted Transfer ReceiptLns INF" sayfasını açın
2. Transfer receipt line'ını bulun
3. **Kontrol**:
   - FA Location Code = ŞUBE ✓
   - FA Location Name = ŞUBE adı ✓

**Adım 3: Sabit Kıymet Dönüşümü**
1. Line'ı seçin → "Create Fixed Assets For Selected Lines"
2. Oluşan FA Card'ı açın

**Adım 4: Konum Kontrolü**
- **Mevcut Durum**: FA Location Code = ŞUBE ✓
- **Problem**: Current Location ve Current Location Name boş veya farklı ❌
- **Beklenen**: Current Location alanlarında da ŞUBE görünmeli

#### Başarı Kriterleri
- ✅ Posted Transfer Receipt Lines'da konum bilgileri doğru
- ❌ Current Location alanları Transfer-to Code'u göstermiyor (implementasyon eksik)

---

### Senaryo 2: Sabit Kıymet Konum Değişikliği Testi (Amortisman Sonrası)

#### Ön Koşullar
- [ ] Senaryo 1'den oluşturulan FA
- [ ] Depreciation book setup'ı yapılmış

#### Test Adımları

1. **Amortisman Hesaplama**
   - FA Depreciation Books'a depreciation book ekle
   - Calculate Depreciation batch job'ı çalıştır
   - FA Journal'dan post et

2. **Konum Değişikliği**
   - FA Card'da FA Location Code'u değiştir
   - Kaydet

3. **Senkronizasyon Kontrolü**
   - FA Conversion record'unda Location Code güncellenmeli ✓
   - Current Location alanları güncellenmeli (CalcFields sonrası)

#### Başarı Kriterleri
- ✅ Amortisman sonrası konum değiştirilebiliyor
- ✅ FA Conversion senkronize oluyor

---

### Senaryo 4: Toplu FA Transfer Maddesi Oluşturma

#### Ön Koşullar
- [ ] En az 2-3 Fixed Asset kaydı mevcut

#### Test Adımları

1. **Fixed Asset List** açın
2. **Ctrl** ile 2-3 FA seçin
3. **Process → Create FA Transfer Item** tıklayın
4. Items listesinde "SK-" prefixli yeni maddeleri kontrol edin

#### Alternatif: Tekil Oluşturma
1. **Fixed Asset Card** açın
2. **Process → Create FA Transfer Item** tıklayın

#### Başarı Kriterleri
- ✅ Seçili FA sayısı kadar madde oluşuyor
- ✅ Her maddenin Serial No = FA No

---

### Senaryo 5: FA Dönüşüm Sayısı Görüntüleme

#### Ön Koşullar
- [ ] Varyantlı item tanımlı
- [ ] Bu varyanttan FA dönüşümü yapılmış

#### Test: Item Variants'tan Kontrol
1. Item Card'dan **Related → Item → Variants** sayfasını açın
2. **FA Conversion Count** sütununu kontrol edin
3. **Sonuç**: Her varyantın kendi dönüşüm sayısı görünmeli ✓

#### Kısıtlamalar
- Item List'te FA Conversion Count YOK (Business Central veri modeli gereği)
- FA Conversion Count sadece Item Variants üzerinde görüntülenmektedir

#### Başarı Kriterleri
- ✅ Item Variants'ta varyant bazlı sayılar görünüyor

---

## Test Sonuç Değerlendirmesi

### ✅ Çalışan Özellikler
- [ ] Toplu FA Transfer maddesi oluşturma
- [ ] FA dönüşüm sayılarının görüntülenmesi
- [ ] Posted Transfer Receipt Lines'da konum bilgileri

### ❌ Düzeltilmesi Gerekenler
- [ ] Transfer Receipt'ten dönüşümde Current Location mapping
- [ ] Field edit restrictions implementasyonu
- [ ] Location history tracking
- [ ] Item depreciation life integration

### Sorun Durumunda Kontroller
1. **Konum boş geliyorsa**: Location ve FA Location setup kontrolü
2. **Senkronizasyon çalışmıyorsa**: FALocationSyncHandler aktifliği
3. **Current Location güncellenmiyor**: FlowField olduğu için CalcFields gerekli

---

## Notlar
- Test ortamı: ERRA_DEV (tenant: 8beae494-639b-461e-9d2e-ad58f9467cf9)
- Her test sonrası veri temizliği değerlendirilmeli
- Hata durumunda ekran görüntüsü alınmalı
- Bu döküman canlı tutulmalı, yeni özellikler eklendikçe güncellenmeli

---

*Son Güncelleme: 25.09.2025*