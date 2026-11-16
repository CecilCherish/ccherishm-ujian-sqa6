# Walkthrough - Perbaikan Schema Validation Error & Sinkronisasi Selektor UiPath

Dokumen ini mencatat investigasi, akar masalah, dan perbaikan untuk error validasi Studio dan output debug yang dilaporkan.

---

## 1. Analisis Error yang Dilaporkan

### A. Warning: `File path is required` pada `Edge Bank Nusantara - Live Settlement Monitor`
* **Penyebab**: Pada perbaikan sebelumnya, atribut `Selector` di dalam `<uix:TargetApp BrowserType="Edge" ...>` sempat diubah menjadi selektor window desktop (`<wnd app='msedge.exe' ...>`).
* **Dampak**: Karena `BrowserType="Edge"` disetel, UiPath Studio mewajibkan selektor target bertipe web (`<html ...>`). Jika diberikan selektor `<wnd>`, Studio menganggapnya sebagai aplikasi desktop non-browser dan menuntut parameter executable `File path`.
* **Solusi**: Mengembalikan selektor `TargetApp` ke bentuk HTML bawaan Edge:
  ```xml
  <uix:TargetApp ... BrowserType="Edge" Selector="&lt;html app='msedge.exe' title='Bank Nusantara - Live Settlement Monitoring Portal (Day 30 Enterprise REFramework)' /&gt;" ... />
  ```

---

### B. Error: `This activity is missing or could not be loaded.` pada 4 Aktivitas `NGetText`
* **Penyebab**: Atribut `InteractionMode="HardwareEvents"` sempat ditambahkan ke dalam tag `<uix:NGetText>`.
* **Dampak**: Berbeda dengan `NTypeInto` dan `NClick` yang memiliki properti `InteractionMode`, aktivitas `NGetText` di pustaka `UiPath.UIAutomationNext.Activities` **tidak memiliki properti `InteractionMode`**. Akibatnya, XAML reader di UiPath Studio mengalami *schema mismatch* dan menolak memuat aktivitas tersebut.
* **Solusi**: Menghapus atribut `InteractionMode` dari seluruh tag `<uix:NGetText>`. Serta memastikan tiap elemen anchor memiliki `Guid` yang valid.

---

### C. Output Debug Masih Menjalankan Selektor Lama (`<webctrl id='search-trx-id' ...>`)
* **Penyebab**: Karena `Main.xaml` sebelumnya memiliki error validasi *activity missing*, UiPath Studio **menolak mengompilasi file baru**. Saat tombol Debug ditekan, Studio secara otomatis mengeksekusi assembly *cache* lama (versi yang masih menggunakan `<webctrl>`).
* **Solusi**: Setelah error validasi diperbaiki dan bersih, UiPath Studio dapat mengompilasi ulang dan mengeksekusi alur kerja terbaru.

---

## 2. Rangkuman Konfigurasi Final di `Main.xaml`

| Aktivitas | DisplayName | InteractionMode | Target / Selector |
| :--- | :--- | :--- | :--- |
| **`NApplicationCard`** | Edge Bank Nusantara - Live Settlement Monitor | Default (`ScopeGuid`) | `BrowserType="Edge"`, `Selector="<html app='msedge.exe' ...>"` |
| **`NTypeInto`** | Type Into 'Chrome Legacy Window' | `HardwareEvents` | Fuzzy Selector ke `Chrome Legacy Window` (Input Box) + Anchor |
| **`NClick`** | Click 'Cari Transaksi' | `HardwareEvents` | Full Selector ke tombol Cari Transaksi di `Chrome Legacy Window` |
| **`Delay`** | Delay Render Web (500ms) | - | `00:00:00.5000000` |
| **`NGetText` (ID)** | Get Text 'web-trx-id' | *(Bawaan)* | Target `<ctrl role='text' />` + Anchor `<ctrl name='ID Transaksi' />` |
| **`NGetText` (Ch)** | Get Text 'web-trx-channel' | *(Bawaan)* | Target `<ctrl role='text' />` + Anchor `<ctrl name='Channel' />` |
| **`NGetText` (Nom)** | Get Text 'web-trx-amount' | *(Bawaan)* | Target `<ctrl role='text' />` + Anchor `<ctrl name='Nominal Web Portal (IDR)' />` |
| **`NGetText` (Stat)** | Get Text 'web-trx-status' | *(Bawaan)* | Target `<ctrl role='text' />` + Anchor `<ctrl name='Status Portal' />` |

---

## 3. Langkah Menjalankan di UiPath Studio

1. **Reload / Buka Ulang File**:
   - Jika tab `Main.xaml` sedang terbuka di Studio, **tutup tab tersebut lalu buka kembali** (atau klik **Yes / Reload** jika muncul pop-up notifikasi perubahan eksternal dari disk).
2. **Periksa Panel Error List**:
   - Pastikan panel **Error List** di bagian bawah Studio sudah **0 Errors** dan **0 Warnings**.
3. **Pastikan Portal Terbuka**:
   - Pastikan halaman portal `banking-monitoring-portal.html` telah terbuka di Microsoft Edge.
4. **Klik Debug File / Run File**.
