# 🐦 CennetKuşEvi - Pet Shop Yönetim Sistemi

ASP.NET Core MVC tabanlı, kapsamlı bir pet shop yönetim sistemidir. Sistem, mağaza operasyonları, stok yönetimi, üretim tesisleri, lojistik ve müşteri yönetimi gibi tüm iş süreçlerini tek bir platformda birleştirir.

## 📋 İçindekiler

- [Özellikler](#-özellikler)
- [Teknoloji Stack](#-teknoloji-stack)
- [Kurulum](#-kurulum)
- [Veritabanı Yapısı](#-veritabanı-yapısı)
- [Kullanım](#-kullanım)
- [Proje Yapısı](#-proje-yapısı)
- [Modüller](#-modüller)
- [İş Kuralları](#-iş-kuralları)

## ✨ Özellikler

### 🏪 Mağaza Yönetimi
- Çoklu mağaza desteği
- Gerçek zamanlı stok takibi
- Mağaza bazlı satış raporları
- Ürün kataloğu ve filtreleme

### 📦 Stok ve Lojistik
- Depo yönetimi (Warehouse)
- Üretim tesisi yönetimi (BreedingUnit)
- Lokasyonlar arası transfer işlemleri
- Otomatik envanter güncellemeleri
- Tedarikçi yönetimi ve mal kabul

### 🐾 Hayvan ve Ürün Yönetimi
- Hayvan kayıt ve takip sistemi
- Sağlık durumu yönetimi
- Üretim yuvaları (Nest) yönetimi
- Ürün kataloğu (Hayvan ve Mal)
- Son kullanma tarihi takibi

### 👥 Müşteri ve Satış
- Müşteri kayıt sistemi
- Sipariş oluşturma ve yönetimi
- Ödeme ve borç takibi
- Müşteri satın alma geçmişi
- Müşteri portalı (alışveriş için)

### 💼 İnsan Kaynakları
- Çalışan yönetimi
- Maaş güncelleme sistemi
- Lokasyon atama işlemleri
- Çalışan rolleri (Breeder, Carrier, Staff)

### 📊 Raporlama ve Dashboard
- Mağaza bazlı satış performansı
- Müşteri borç durumu
- Transfer logları
- Hasta hayvan takibi
- Son kullanma tarihi yaklaşan ürünler
- Envanter durumu

## 🛠 Teknoloji Stack

- **Framework**: ASP.NET Core MVC (.NET 10.0)
- **Veritabanı**: Microsoft SQL Server
- **ORM/Data Access**: ADO.NET (System.Data.SqlClient)
- **Frontend**: 
  - Bootstrap 5
  - jQuery
  - Razor Views
- **Session Management**: ASP.NET Core Session
- **Authentication**: Session-based (Admin ve Customer rolleri)

## 📦 Kurulum

### Gereksinimler

- .NET 10.0 SDK veya üzeri
- Microsoft SQL Server (2019 veya üzeri)
- Visual Studio 2022 veya Visual Studio Code
- SQL Server Management Studio (SSMS) - Veritabanı kurulumu için

### Adım 1: Projeyi Klonlayın

```bash
git clone <repository-url>
cd petshop-web
```

### Adım 2: Veritabanını Oluşturun

1. SQL Server Management Studio'yu açın
2. `sql/petshop-management-sql-query.sql` dosyasını açın
3. SQL scriptini çalıştırarak veritabanını oluşturun
   - Script otomatik olarak `CennetKusEvi1` veritabanını oluşturur
   - Tüm tablolar, view'lar, trigger'lar ve stored procedure'ler kurulur
   - Seed data (örnek veriler) otomatik olarak eklenir

### Adım 3: Bağlantı Stringini Yapılandırın

`WebApplication1/appsettings.json` dosyasını açın ve bağlantı stringini düzenleyin:

```json
{
  "ConnectionStrings": {
    "PetShopDB": "Server=localhost;Database=CennetKusEvi1;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True"
  },
  "AdminAuth": {
    "Username": "admin",
    "Password": "1234"
  }
}
```

**Not**: SQL Server adınız farklıysa veya SQL Server Authentication kullanıyorsanız bağlantı stringini buna göre güncelleyin.

### Adım 4: Projeyi Çalıştırın

#### Visual Studio ile:
1. `WebApplication1.slnx` dosyasını açın
2. `F5` tuşuna basarak projeyi çalıştırın

#### Komut satırı ile:
```bash
cd WebApplication1
dotnet build
dotnet watch run
```

Proje seçtiğiniz adreste çalışacaktır.

##  Veritabanı Yapısı

### Ana Tablolar

- **Location** (Supertype): Tüm lokasyonların temel tablosu
  - **Warehouse**: Depo lokasyonları
  - **Store**: Mağaza lokasyonları
  - **BreedingUnit**: Üretim tesisi lokasyonları

- **Employee** (Supertype): Tüm çalışanların temel tablosu
  - **Breeder**: Üretim sorumluları
  - **Carrier**: Kurye/taşıyıcı çalışanlar
  - **Staff**: Mağaza personeli

- **Product** (Supertype): Tüm ürünlerin temel tablosu
  - **Animal**: Canlı hayvan ürünleri
  - **Goods**: Mal/aksesuar ürünleri

- **Orders**: Sipariş başlıkları
- **OrderLine**: Sipariş satırları
- **Supply**: Tedarik kayıtları
- **SupplyLine**: Tedarik satırları
- **Transfer**: Transfer işlemleri
- **TransferLine**: Transfer satırları
- **LocationInventory**: Lokasyon bazlı envanter takibi
- **Nest**: Üretim yuvaları
- **Customer**: Müşteriler
- **Vendor**: Tedarikçiler

### View'lar

- `vw_ProductDetails`: Detaylı ürün listesi
- `vw_StoreSales`: Mağaza bazlı satış performansı
- `vw_CustomerDebtInfo`: Müşteri borç durumu
- `vw_TransferLog`: Transfer logları
- `vw_AllEmployees`: Tüm çalışan detayları
- `vw_SickAnimals`: Hasta hayvanlar
- `vw_ExpiringGoods`: Son kullanma tarihi yaklaşan ürünler
- `vw_LocationInventory`: Lokasyon envanter durumu

### Stored Procedure'ler

- `sp_AddOrderWithValidation`: Sipariş oluşturma
- `sp_AddOrderLine`: Sipariş satırı ekleme
- `sp_MakePayment`: Ödeme işlemi
- `sp_CreateTransferWithLine`: Transfer oluşturma
- `sp_CreateSupplyWithLine`: Mal kabul işlemi
- `sp_RegisterNewAnimal`: Yeni hayvan kaydı
- `sp_IncreaseSalary`: Maaş artırma
- `sp_AssignEmployeeToLocation`: Personel atama
- `sp_AddNewBreedingNest`: Yeni yuva oluşturma
- `sp_UpdateAnimalHealth`: Hayvan sağlık durumu güncelleme

### Trigger'lar

Sistem, veri bütünlüğünü ve iş kurallarını korumak için çok sayıda trigger içerir:

- Son kullanma tarihi geçmiş ürün satışını engelleme
- Maaş düşüşünü engelleme
- Transfer lokasyon kurallarını doğrulama
- Aşırı ödemeyi engelleme
- Transfer işlemlerinde kurye kontrolü
- Satış lokasyon kontrolü
- Envanter otomatik güncelleme
- Yuva minimum hayvan sayısı kontrolü

## 🚀 Kullanım

### Admin Girişi

1. Ana sayfada "Admin" rolünü seçin
2. Kullanıcı adı: `admin`
3. Şifre: `1234` (varsayılan, `appsettings.json`'dan değiştirilebilir)

### Admin Paneli Özellikleri

#### Dashboard (Ana Sayfa)
- Mağaza satış performansı
- Hasta hayvan listesi
- En yüksek borçlu müşteriler
- Son transfer işlemleri
- Çalışan listesi
- Son kullanma tarihi yaklaşan ürünler
- Ürün kataloğu istatistikleri

#### Satış İşlemleri
- **Sipariş Oluştur**: Müşteri, mağaza ve ürün seçerek sipariş oluşturma
- **Tahsilat**: Müşteri borçlarını ödeme alma
- **Müşteri Satın Alımları**: Müşteri bazlı satın alma geçmişi raporu

#### Ürün Kataloğu
- Tüm ürünleri görüntüleme
- Tip bazlı filtreleme (Animal/Goods)
- Arama özelliği
- Sağlık durumu filtreleme
- Fiyat sıralama

#### Transfer İşlemleri
- Depo → Mağaza transferi (Goods)
- Üretim Tesisi → Mağaza transferi (Animal)
- Kurye atama
- Transfer geçmişi görüntüleme

#### Mal Kabul
- Tedarikçiden mal kabul
- Depo seçimi
- Ürün ve miktar girişi

#### İnsan Kaynakları
- Çalışan listesi
- Maaş güncelleme (yüzde bazlı artış)
- Lokasyon atama

#### Üretim ve Sağlık
- Üretim tesislerini görüntüleme
- Yuva (Nest) yönetimi
- Yeni hayvan kaydı
- Hayvan sağlık durumu güncelleme

### Müşteri Girişi

1. Ana sayfada "Müşteri" rolünü seçin
2. Müşteri ID'nizi girin (veritabanındaki CustomerID)
3. Müşteri portalına yönlendirilirsiniz

### Müşteri Portalı Özellikleri

- **Alışveriş**: Mağaza seçerek ürün görüntüleme ve satın alma
- Stok durumu görüntüleme
- Ürün fiyat bilgisi

## 📁 Proje Yapısı

```
petshop-web/
├── WebApplication1/
│   ├── Controllers/
│   │   ├── AccountController.cs      # Giriş/Çıkış işlemleri
│   │   ├── HomeController.cs         # Admin paneli işlemleri
│   │   └── CustomerController.cs     # Müşteri portalı işlemleri
│   ├── Models/
│   │   └── ErrorViewModel.cs
│   ├── Views/
│   │   ├── Account/
│   │   │   └── Login.cshtml
│   │   ├── Customer/
│   │   │   └── Shop.cshtml
│   │   ├── Home/
│   │   │   ├── Index.cshtml          # Dashboard
│   │   │   ├── CreateOrder.cshtml
│   │   │   ├── MakePayment.cshtml
│   │   │   ├── CustomerPurchases.cshtml
│   │   │   ├── ProductCatalog.cshtml
│   │   │   ├── Transfer.cshtml
│   │   │   ├── ReceiveSupply.cshtml
│   │   │   ├── HR.cshtml
│   │   │   ├── Breeding.cshtml
│   │   │   └── UpdateSalary.cshtml
│   │   └── Shared/
│   │       ├── _Layout.cshtml
│   │       └── Error.cshtml
│   ├── wwwroot/
│   │   ├── css/
│   │   ├── js/
│   │   └── lib/                       # Bootstrap, jQuery
│   ├── Program.cs                     # Uygulama başlangıç noktası
│   ├── appsettings.json               # Yapılandırma
│   └── WebApplication1.csproj        # Proje dosyası
├── sql/
│   └── petshop-management-sql-query.sql  # Veritabanı scripti
├── docs/
│   └── petshop-management-report.pdf     # Proje dokümantasyonu
└── README.md
```

## 🔧 Modüller

### 1. Kimlik Doğrulama Modülü
- Session tabanlı authentication
- Admin ve Customer rolleri
- Giriş/Çıkış işlemleri

### 2. Dashboard Modülü
- Gerçek zamanlı raporlar
- İstatistiksel veriler
- Hızlı erişim linkleri

### 3. Satış ve Ödeme Modülü
- Sipariş oluşturma
- Ödeme alma
- Borç takibi
- Satış raporları

### 4. Ürün Yönetimi Modülü
- Ürün kataloğu
- Filtreleme ve arama
- Stok durumu

### 5. Lojistik Modülü
- Transfer işlemleri
- Mal kabul
- Envanter yönetimi

### 6. İnsan Kaynakları Modülü
- Çalışan yönetimi
- Maaş güncellemeleri
- Lokasyon atamaları

### 7. Üretim Modülü
- Yuva yönetimi
- Hayvan kayıt
- Sağlık takibi

## ⚖️ İş Kuralları

Sistem aşağıdaki iş kurallarını otomatik olarak uygular:

1. **Satış Kuralları**
   - Satışlar sadece Store lokasyonlarından yapılabilir
   - Canlı hayvan satışlarında miktar 1 olmalıdır
   - Son kullanma tarihi geçmiş ürünler satılamaz
   - Stok yetersizse satış yapılamaz

2. **Transfer Kuralları**
   - Hayvanlar sadece BreedingUnit → Store transfer edilebilir
   - Mallar sadece Warehouse → Store transfer edilebilir
   - Transfer işlemleri sadece Carrier çalışanlar tarafından yapılabilir
   - Canlı hayvan transferlerinde miktar 1 olmalıdır

3. **Envanter Kuralları**
   - Her transfer ve satış işleminde envanter otomatik güncellenir
   - Stok kontrolü otomatik yapılır

4. **Ödeme Kuralları**
   - Müşteri, sipariş toplamından fazla ödeme yapamaz
   - Ödemeler en eski borçtan başlayarak tahsil edilir

5. **Üretim Kuralları**
   - Her yuva (Nest) en az 2 hayvan içermelidir
   - Hayvanlar mutlaka bir yuvaya atanmalıdır

6. **Personel Kuralları**
   - Çalışan maaşı düşürülemez, sadece artırılabilir

## 🔐 Güvenlik Notları

- Admin şifresi `appsettings.json` dosyasında saklanmaktadır
- SQL Injection koruması için parametreli sorgular kullanılmıştır
- Session timeout ayarlarını production için yapılandırın

## 📝 Lisans

Bu proje eğitim amaçlı geliştirilmiştir.

---

**Not**: Bu sistem, veritabanı trigger'ları ve stored procedure'ler kullanarak güçlü bir iş kuralı kontrolü sağlar. Tüm kritik işlemler veritabanı seviyesinde doğrulanır.

