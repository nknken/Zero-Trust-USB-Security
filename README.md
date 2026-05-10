<div align="center">

# 🔒 Zero Trust USB Security
Alat keamanan USB real-time yang mendeteksi, menganalisis, dan otomatis memblokir perangkat HID tidak sah (serangan BadUSB / Rubber Ducky) menggunakan analisis perilaku dan model Zero Trust berbasis whitelist.

</div>

---

## 📋 Daftar Isi
- [Fitur](#-fitur)
- [Cara Kerja](#-cara-kerja)
- [Persyaratan](#-persyaratan)
- [Instalasi](#-instalasi)
- [Cara Penggunaan](#-cara-penggunaan)
- [Struktur File](#-struktur-file)
- [FAQ](#-faq)
- [Kontribusi](#-kontribusi)

---

## ✨ Fitur

| Fitur | Keterangan |
|---|---|
| 🛡️ **Model Zero Trust** | Setiap USB baru dianggap tidak aman sampai didaftarkan ke whitelist |
| 🔍 **Analisis Perilaku Real-time** | Memantau interval ketikan, CV, dan burst rate untuk mendeteksi input otomatis |
| ⚡ **Auto Emergency Block** | Langsung menonaktifkan dan menghapus perangkat mencurigakan dari sistem |
| 💥 **Gangguan Payload** | Menyuntikkan karakter acak untuk merusak payload serangan yang sedang berjalan |
| 🖥️ **Dashboard GUI** | Tampilan dashboard gelap yang bersih untuk memantau status, log, dan mengelola perangkat |
| 📋 **Whitelist / Blacklist** | Daftar perangkat tepercaya dan terblokir yang tersimpan permanen |
| 📁 **Arsip Log Otomatis** | Log keyboard harian dan log USB mingguan diarsipkan ke ZIP secara otomatis |
| 🔄 **Setup First Run** | Wizard interaktif untuk mendaftarkan perangkat tepercaya sebelum monitoring dimulai |

---

## 🔬 Cara Kerja

```
USB Dicolokkan
      │
      ▼
┌─────────────────────┐
│  Cek Zero Trust     │  ── Ada di Whitelist? ──► TRUSTED (diizinkan)
└─────────────────────┘
      │ Tidak
      ▼
┌─────────────────────┐
│  PENDING / DIPANTAU │  ◄── Analisis perilaku berjalan
└─────────────────────┘
      │ Score ≥ 4
      ▼
┌────────────────────────────────────────────┐
│  RESPONS DARURAT                           │
│  1. Suntik karakter acak (rusak payload)   │   │
│  2. Disable & hapus perangkat (PnP)        │
│  3. Tulis ke blacklist                     │
└────────────────────────────────────────────┘
```

**Sistem Penilaian Perilaku:**

| Metrik | Ambang Batas | Skor |
|---|---|---|
| Rata-rata interval ketikan | < 50ms | +1 |
| Rata-rata interval ketikan | < 30ms | +2 |
| Koefisien Variasi (CV) | < 0.5 | +1 |
| Koefisien Variasi (CV) | < 0.2 | +2 |
| Jumlah burst (< 25ms) | ≥ 5 | +1 |
| Jumlah burst (< 25ms) | ≥ 15 | +2 |

> **Score ≥ 4 → Emergency Block diaktifkan**

---

## 📦 Persyaratan

- Windows 10 / 11
- PowerShell 5.1 atau lebih baru
- .NET Framework 4.5+ (sudah terinstal di Win 10/11)

> ℹ️ Hak akses Administrator dibutuhkan oleh aplikasi, namun **sudah diminta otomatis** saat program dijalankan.

---

## 🚀 Instalasi

### Opsi 1 — Download Release (Direkomendasikan)

1. Buka halaman [Releases](https://github.com/nknken/Zero-Trust-USB-Security/releases)
2. Download `.zip` versi terbaru
3. Ekstrak ke folder (contoh: `C:\ZeroTrustUSB\`)
4. Jalankan `Run-GUI.bat` — UAC akan muncul otomatis, klik **Yes**

### Opsi 2 — Clone Repository

```bash
git clone https://github.com/nknken/Zero-Trust-USB-Security.git
cd Zero-Trust-USB-Security
```

Lalu jalankan `Run-GUI.bat` — UAC akan muncul otomatis, klik **Yes**.

> ⚠️ **Jangan memindahkan file secara terpisah.** Struktur folder harus tetap utuh agar aplikasi berjalan dengan benar.

---

## 📖 Cara Penggunaan

### Langkah 1 — First Run (Daftarkan Perangkat)

Sebelum monitoring aktif, daftarkan keyboard/mouse USB Anda terlebih dahulu:

1. Jalankan `Run-GUI.bat`
2. Klik tombol **"Setup Awal"** di dashboard
3. Colokkan keyboard dan/atau mouse Anda
4. Tekan `Y` untuk mendaftarkan setiap perangkat
5. Tekan `S` untuk selesai

> ✅ Whitelist tersimpan permanen dan tidak hilang setelah restart.

### Langkah 2 — Monitoring Normal

Setelah setup selesai, cukup jalankan `Run-GUI.bat` — monitoring dimulai secara otomatis.

| Indikator | Arti |
|---|---|
| 🟢 `● MONITORING AKTIF` | Monitor berjalan normal |
| 🔴 `○ MONITOR TIDAK AKTIF` | Monitor tidak berjalan |

### Mengelola Perangkat via GUI

- **Unblock perangkat** → Klik dua kali perangkat di panel Blacklist → Klik `Unblock`
- **Hapus dari whitelist** → Klik dua kali perangkat di panel Whitelist → Klik `Remove Whitelist`
- Bisa juga ketik `VID:PID` secara manual di kolom input

### Mode CLI

Jalankan `Run-CLI.bat` — akan muncul menu pilihan:

```
===========================================
   PILIH FUNGSI ZERO TRUST USB (CLI)
===========================================
1. Jalankan Monitoring Utama (FirstRun)
2. Buka Menu Utama (Main)
3. Unblock Perangkat
4. Remove dari Whitelist
===========================================
```

| Pilihan | Fungsi |
|---|---|
| `1` | Setup awal + daftarkan perangkat tepercaya |
| `2` | Langsung mulai monitoring tanpa setup |
| `3` | Unblock perangkat yang masuk blacklist (input `VID:PID`) |
| `4` | Hapus perangkat dari whitelist (input `VID:PID`) |

Setelah menu selesai dijalankan, terminal PowerShell tetap terbuka. Kamu bisa langsung menjalankan perintah lanjutan tanpa perlu membuka ulang:

```powershell
# Jalankan monitoring utama
.\main.ps1

# Setup first run
.\main.ps1 -FirstRun

# Unblock perangkat
.\main.ps1 -UnblockDevice "VID:PID"

# Hapus dari whitelist
.\main.ps1 -RemoveWhitelist "VID:PID"
```
> [!IMPORTANT]
> **Apa itu VID:PID?**
> - **VID (Vendor ID):** 4 digit kode unik pabrikan perangkat (contoh: `1234`).
> - **PID (Product ID):** 4 digit kode unik produk perangkat (contoh: `5678`).
> 
> Anda bisa menemukan kombinasi ini pada kolom **"Hardware ID"** di Dashboard GUI atau melalui Log di folder `logs/usb_security.log`. Format penulisannya harus dipisahkan dengan tanda titik dua (`:`).
---

## 📁 Struktur File

```
Zero-Trust-USB-Security/
│
├── main.ps1                  # Engine monitoring utama
├── gui.ps1                   # Dashboard GUI
├── Run-GUI.bat               # Jalankan GUI (sebagai Admin)
├── Run-CLI.bat               # Jalankan monitor CLI (sebagai Admin)
│
├── modules/
│   ├── usb_detector.ps1      # Deteksi USB HID & logging
│   └── behavior_monitor.ps1  # Analisis perilaku ketikan
│
├── whitelist.txt             # Perangkat tepercaya (dibuat otomatis)
├── blacklist.txt             # Perangkat terblokir (dibuat otomatis)
│
└── logs/
    ├── usb_security.log      # Log event USB
    ├── keyboard_input.log    # Log waktu ketikan (aktif)
    └── archive/
        ├── keyboard/         # Log keyboard harian (ZIP)
        └── usb/              # Log USB mingguan (ZIP)
```

---

## ❓ FAQ

**T: Apakah ini akan memblokir keyboard/mouse saya sendiri?**
> Tidak — selama Anda mendaftarkannya saat First Run Setup. Whitelist tersimpan permanen dan tidak hilang setelah restart.

**T: Apa itu serangan BadUSB / Rubber Ducky?**
> Perangkat yang menyamar sebagai keyboard untuk mengetik perintah berbahaya secara otomatis (misalnya membuka PowerShell dan menjalankan script) begitu dicolokkan ke komputer.

**T: Kenapa muncul UAC (User Account Control) saat membuka aplikasi?**
> Aplikasi membutuhkan hak Administrator untuk menonaktifkan perangkat PnP dan menghentikan proses sistem. UAC diminta otomatis — cukup klik **Yes**.

**T: Saya tidak sengaja memblokir keyboard saya. Apa yang harus dilakukan?**
> Gunakan keyboard lain atau on-screen keyboard (`Win + Ctrl + O`), lalu jalankan `Run-CLI.bat` dan pilih menu **3. Unblock Perangkat**, masukkan `VID:PID` perangkat tersebut. Atau buka GUI dan gunakan tombol **Unblock**.

**T: Di mana log disimpan?**
> Di folder `logs\` di dalam direktori aplikasi. Klik tombol **"Buka Folder"** di GUI untuk membukanya langsung.

**T: Monitor menampilkan "TIDAK AKTIF" setelah dibuka.**
> Pastikan klik **Yes** saat UAC muncul. Jika UAC tidak muncul sama sekali, coba klik kanan `Run-GUI.bat` → *Run as administrator*.

---

## 🤝 Kontribusi

Kontribusi sangat disambut! Caranya:

1. Fork repository ini
2. Buat branch baru: `git checkout -b fitur/nama-fitur`
3. Commit perubahan: `git commit -m "Tambah: nama fitur"`
4. Push ke branch: `git push origin fitur/nama-fitur`
5. Buka Pull Request

Untuk perubahan besar, harap buka **Issue** terlebih dahulu untuk mendiskusikan apa yang ingin diubah.

---

<div align="center">

Dibuat dengan ❤️ oleh [nknken](https://github.com/nknken)

⭐ **Beri bintang jika bermanfaat!** ⭐

</div>