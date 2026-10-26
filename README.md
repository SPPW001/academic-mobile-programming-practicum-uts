# TaniAir - UTS Mobile Programming Practicum

**Nama:** Setyo Pratama Putra Wibowo  
**NIM:** 240605110090  
**Kelas:** Mobile Programming Practicum H

## Deskripsi

TaniAir adalah aplikasi mobile berbasis **Flutter dan Dart** yang dikembangkan untuk membantu pengguna, khususnya petani atau pengelola lahan, dalam memahami kondisi lingkungan lahan dan mempertimbangkan kebutuhan penyiraman tanaman.

Aplikasi memanfaatkan data dinamis dari **Open-Meteo API**. Pengguna cukup mencari nama lokasi lahan, kemudian aplikasi akan memperoleh koordinat secara otomatis melalui Geocoding API dan mengambil data cuaca melalui Forecast API.

Data seperti estimasi kelembapan tanah, suhu, peluang hujan, curah hujan, dan ET₀ kemudian diolah menjadi informasi yang lebih mudah dipahami dalam bentuk rekomendasi seperti **Siram, Pantau, atau Tunda Penyiraman**.

## Fitur Utama

- Pencarian lokasi lahan berdasarkan nama daerah.
- Pengambilan data dinamis dari Open-Meteo API.
- Informasi estimasi kelembapan tanah.
- Informasi suhu dan kelembapan udara.
- Informasi peluang dan prakiraan hujan.
- Pengolahan data menjadi rekomendasi penyiraman.
- Prakiraan kondisi beberapa jam ke depan.
- Tampilan rincian data teknis.
- Penanganan kondisi loading, success, dan error.
- Fitur refresh untuk memperbarui data.

## Teknologi

- Flutter
- Dart
- HTTP Package
- Open-Meteo Geocoding API
- Open-Meteo Forecast API

## Menjalankan Aplikasi

Pastikan Flutter sudah terpasang pada perangkat.

```bash
flutter pub get
flutter run
```

## Catatan

Rekomendasi yang diberikan oleh TaniAir merupakan indikator sederhana berdasarkan data model dan prakiraan cuaca dari Open-Meteo. Data kelembapan tanah bukan berasal dari sensor fisik yang dipasang langsung pada lahan, sehingga hasil aplikasi digunakan sebagai informasi pendukung dan tidak menggantikan pengamatan kondisi lahan secara langsung.

## Sumber Data

Data cuaca dan lokasi diperoleh dari:

Open-Meteo  
https://open-meteo.com/
