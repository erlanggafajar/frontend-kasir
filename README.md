# Aplikasi Kasir Flutter

Aplikasi kasir modern dengan Flutter untuk mengelola transaksi penjualan toko dengan sistem manajemen user yang lengkap.

## 🌟 Fitur Utama

### 🔐 **Autentikasi & Manajemen User**

- Login dan registrasi pengguna dengan role-based access
- **ADMIN (OWNER)**: Akses penuh ke semua fitur
- **KASIR (KARYAWAN)**: Akses terbatas sesuai toko
- Edit profile pengguna (tanpa ubah password untuk KASIR)
- Manajemen user oleh ADMIN

### 🛍️ **Manajemen Produk**

- CRUD produk dengan validasi stok otomatis
- Kategori produk dengan kode unik
- Monitoring stok real-time
- Update harga dan stok bulk

### 💳 **Sistem Transaksi**

- Transaksi penjualan
- Validasi stok otomatis saat checkout
- Riwayat transaksi per toko dengan filtering
- **KASIR**: Hanya lihat transaksi miliknya sendiri
- **ADMIN**: Lihat semua transaksi toko dengan detail pembuat
- Enrichment data transaksi dengan info user

### 📊 **Laporan & Export**

- Export transaksi ke Excel (.xlsx)
- Generate PDF laporan harian
- Token-based secure export system
- Filter laporan berdasarkan tanggal

### 🔒 **Keamanan & Data Isolation**

- Toko dengan data isolation sempurna
- Toko-based filtering untuk semua API endpoints
- Role-based permissions (ADMIN/KASIR)
- Token authentication dengan JWT
- CORS configuration untuk keamanan API

### 🎨 **User Interface**

- Modern UI dengan gradient design
- Responsive layout untuk mobile
- Real-time loading states
- User-friendly error messages
- Dark/Light theme support

## 🛠️ Teknologi

### **Frontend (Flutter)**

- **Flutter SDK** (Latest stable)
- **Provider** untuk state management
- **HTTP/Dio** untuk komunikasi API
- **Shared Preferences** untuk penyimpanan lokal
- **Go Router** untuk navigation management
- **Excel Export** dengan file generation
- **PDF Generation** untuk laporan

### **Backend (Laravel)**

- **Laravel 9+** untuk RESTful API
- **JWT Authentication** untuk security
- **MySQL/PostgreSQL** untuk database
- **Eloquent ORM** untuk data modeling
- **API Resource** untuk response formatting
- **CORS Middleware** untuk cross-origin

## 🚀 Cara Menjalankan

### **Prerequisites**

- Flutter SDK >= 3.0.0
- Dart SDK >= 2.17.0
- Laravel 9+ (Backend)
- MySQL/PostgreSQL
- Composer

### **Setup Backend**

```bash
# Clone backend repository
git clone <backend-repo-url>
cd backend

# Install dependencies
composer install

# Environment setup
cp .env.example .env
php artisan key:generate

# Database migration
php artisan migrate

# Start server
php artisan serve
```
