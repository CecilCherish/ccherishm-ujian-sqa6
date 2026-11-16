# Walkthrough: Perbaikan Alur Kerja RobotCoreBank (Core Banking Audit, Fraud Detection & SE Auto-Retry)

Dokumen ini mencatat seluruh implementasi dan penyempurnaan alur kerja [Main.xaml](file:///c:/Users/pendi/OneDrive/Documents/UiPath/RobotCoreBank/Main.xaml) untuk proses audit transaksi perbankan, deteksi *fraud*, simulasi *System Error* & *Auto-Retry*, serta pelaporan Excel multi-sheet.

---

## 1. Fitur Utama yang Telah Diimplementasikan

### A. Inisialisasi Pasti 11 Kolom untuk 3 DataTable
* **Masalah Sebelumnya**: Aktivitas `<ui:BuildDataTable>` gagal mempertahankan skema 11 kolom saat runtime pada proyek C#, menyebabkan error `Input array is longer than the number of columns in this table`.
* **Solusi Diterapkan**: Menggunakan aktivitas `Assign` dengan ekspresi C# (*collection initializer*) yang dievaluasi langsung oleh CLR tanpa error expression tree (`CS0834`/`CS8198`):
  * `dtAuditResult`: Menampung seluruh 25 transaksi hasil audit.
  * `dtAuditClean`: Khusus menampung transaksi berstatus `MATCH` dan `MATCH (HIGH_VALUE_REVIEW)`.
  * `dtAuditExceptions`: Khusus menampung transaksi berkategori exception (`SUSPECT_FRAUD` / `BRE` atau `SYSTEM_ERROR` / `SE`).
* Seluruh tabel dijamin memiliki 11 kolom:
  `ID_Transaksi`, `Waktu_Transaksi`, `No_Rekening`, `Channel_Core`, `Nominal_Core`, `Status_Core`, `Web_Channel`, `Web_Nominal`, `Web_Status`, `Audit_Status`, `Keterangan_Audit`.

---

### B. Eksperimen Simulasi System Error & Auto-Retry (Transaksi ke-7)
* **Kebutuhan**: Mensimulasikan browser freeze/crash pada transaksi ke-7 (`TRX-2026-0007`), memicu prosedur *Re-Init*, membuka kembali browser, dan mengulang kembali transaksi ke-7 hingga berhasil.
* **Mekanisme yang Dibangun**:
  1. Variabel kontrol:
     * `simulatedCrashDone` (*Boolean*, default `false`): Memastikan crash hanya disimulasikan satu kali saat percobaan pertama transaksi ke-7.
     * `retryCount` (*Int32*, default `0`): Menghitung jumlah percobaan per transaksi.
     * `maxRetry` (*Int32*, default `3`): Batas maksimal percobaan ulang.
     * `transactionSuccess` (*Boolean*, default `false`): Menandai status akhir pemrosesan per transaksi.
  2. Perulangan `While` (`retryCount < maxRetry && !transactionSuccess`) membungkus blok `TryCatch`.
  3. Pada transaksi ke-7 di percobaan pertama (`searchTransactionID == "TRX-2026-0007" && !simulatedCrashDone`):
     * Set `simulatedCrashDone = true`.
     * Eksekusi `<ui:KillProcess>` pada `msedge` dan `chrome` (`ContinueOnError="True"`).
     * Lempar `Throw new System.Exception("[SE Simulasi] Browser freeze / crash secara paksa pada transaksi ke-7!")`.
  4. Blok `Catch (System.Exception se)`:
     * Menangkap error simulasi SE atau gangguan teknis lainnya.
     * Melakukan increment `retryCount++`.
     * Jika `retryCount < maxRetry`:
       * Menjalankan prosedur **Re-Init**: Kill sisa browser $\rightarrow$ Delay 1s $\rightarrow$ `<ui:StartProcess>` membuka kembali portal Edge/Chrome $\rightarrow$ Delay 2s hingga portal siap.
       * Loop `While` mengulang kembali transaksi ke-7 dari awal.
     * Jika `retryCount >= maxRetry`:
       * Mencatat status sebagai `SYSTEM_ERROR` dan keluar dari loop.
  5. Catatan penting: Blok `Catch (BusinessRuleException bre)` **tidak pernah di-retry** karena merupakan validasi data bisnis (langsung dicatat `SUSPECT_FRAUD` dan lanjut ke transaksi berikutnya).

---

### C. Pemisahan Sheet pada File Output Excel
* **File Utama 1**: [Data\Audit_CleanAndException.xlsx](file:///c:/Users/pendi/OneDrive/Documents/UiPath/RobotCoreBank/Data/Audit_CleanAndException.xlsx)
  * **Sheet 1 (`Audit_Clean`)**: Berisi seluruh baris dari `dtAuditClean` (khusus status `MATCH` dan `MATCH (HIGH_VALUE_REVIEW)`).
  * **Sheet 2 (`Audit_Exceptions`)**: Berisi seluruh baris dari `dtAuditExceptions` (khusus status `SUSPECT_FRAUD` / `BRE` dan `SYSTEM_ERROR` / `SE`).
* **File Utama 2**: [Data\Audit_Core_Banking_Result.xlsx](file:///c:/Users/pendi/OneDrive/Documents/UiPath/RobotCoreBank/Data/Audit_Core_Banking_Result.xlsx)
  * **Sheet (`Audit_Result`)**: Berisi seluruh 25 transaksi gabungan dari `dtAuditResult`.

---

### D. Optimasi Selektor Target Web Portal
* Target NApplicationCard menggunakan wildcard fleksibel `app='*.exe'` sehingga kompatibel baik di **Microsoft Edge** (`msedge.exe`) maupun **Google Chrome** (`chrome.exe`).
* Selektor NGetText menggunakan tag spesifik HTML `SPAN` dengan ID pasti:
  * `<webctrl id='web-trx-id' tag='SPAN' />`
  * `<webctrl id='web-trx-channel' tag='SPAN' />`
  * `<webctrl id='web-trx-amount' tag='SPAN' />`
  * `<webctrl id='web-trx-status' tag='SPAN' />`

---

## 2. Pengaturan Wajib Sebelum Eksekusi

> [!CAUTION]
> **Aktifkan Opsi "Allow access to file URLs" pada Browser:**
> Karena portal bank dijalankan dari berkas lokal (`file:///C:/TUGASKKu/sqa-batch-31/banking-monitoring-portal.html`), ekstensi browser UiPath **wajib** diberi izin akses file lokal:
> 
> * **Jika menggunakan Microsoft Edge**:
>   1. Buka Edge $\rightarrow$ buka URL: `edge://extensions`
>   2. Temukan ekstensi **UiPath Browser Automation** $\rightarrow$ klik **Details** (*Rincian*).
>   3. Aktifkan toggle **"Allow access to file URLs"** (*Izinkan akses ke URL file*).
> * **Jika menggunakan Google Chrome**:
>   1. Buka Chrome $\rightarrow$ buka URL: `chrome://extensions`
>   2. Temukan ekstensi **UiPath Web Automation** $\rightarrow$ klik **Details**.
>   3. Aktifkan toggle **"Allow access to file URLs"**.

---

## 3. Panduan Menjalankan Alur Kerja

> [!TIP]
> **Rekomendasi: Jalankan dengan Run File (`Ctrl + F5`):**
> * **Jika menggunakan Debug (`F5`)**: Setiap kali robot menemui `Throw` (baik simulasi SE pada transaksi ke-7 maupun BRE saat fraud terdeteksi), Studio akan jeda sementara (*Pause / Highlight Kuning*). Anda harus menekan tombol **Continue (`F5`)** pada toolbar Studio agar proses berlanjut.
> * **Jika menggunakan Run File (`Ctrl + F5`)**: Robot akan berjalan lancar secara otomatis dari awal hingga akhir, melakukan auto-retry pada transaksi ke-7, memisahkan transaksi ke dua sheet, dan menghasilkan file Excel lengkap.

---

## 4. Hasil Verifikasi Sistem
- **Struktur XML [Main.xaml](file:///c:/Users/pendi/OneDrive/Documents/UiPath/RobotCoreBank/Main.xaml)**: Valid (100% Clean Parse).
- **Inisialisasi DataTable**: Ketiga tabel (`dtAuditResult`, `dtAuditClean`, `dtAuditExceptions`) terinisialisasi tepat 11 kolom.
- **Folder Output**: Folder [Data](file:///c:/Users/pendi/OneDrive/Documents/UiPath/RobotCoreBank/Data) siap menerima file hasil pemeriksaan.
