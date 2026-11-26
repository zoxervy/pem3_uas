-- Struktur database aplikasi restoran (MariaDB / MySQL). Impor sekali ke database kosong.
SET NAMES utf8mb4;

CREATE TABLE `users` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `nama` varchar(100) NOT NULL,
  `username` varchar(50) NOT NULL,
  `password` varchar(255) NOT NULL,
  `role` enum('admin','waitress','kasir') NOT NULL,
  `no_hp` varchar(20) DEFAULT NULL,
  `aktif` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `users_username_unique` (`username`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
;

CREATE TABLE `kategori` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `nama_kategori` varchar(50) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
;

CREATE TABLE `menu` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `kategori_id` bigint(20) unsigned NOT NULL,
  `nama_menu` varchar(100) NOT NULL,
  `harga` int(10) unsigned NOT NULL,
  `deskripsi` text DEFAULT NULL,
  `foto` varchar(255) DEFAULT NULL,
  `tersedia` tinyint(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`),
  KEY `menu_kategori_id_foreign` (`kategori_id`),
  CONSTRAINT `menu_kategori_id_foreign` FOREIGN KEY (`kategori_id`) REFERENCES `kategori` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
;

CREATE TABLE `meja` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `nomor_meja` varchar(10) NOT NULL,
  `kapasitas` int(10) unsigned DEFAULT NULL,
  `status` enum('kosong','terisi') NOT NULL DEFAULT 'kosong',
  `kode_qr` varchar(40) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `meja_nomor_meja_unique` (`nomor_meja`),
  UNIQUE KEY `meja_kode_qr_unique` (`kode_qr`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
;

CREATE TABLE `pesanan` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `kode_pesanan` varchar(30) NOT NULL,
  `token` varchar(40) DEFAULT NULL,
  `kode_bayar` varchar(40) DEFAULT NULL,
  `meja_id` bigint(20) unsigned NOT NULL,
  `waiter_id` bigint(20) unsigned DEFAULT NULL,
  `kasir_id` bigint(20) unsigned DEFAULT NULL,
  `nama_pelanggan` varchar(100) DEFAULT NULL,
  `tanggal` datetime NOT NULL,
  `waktu_konfirmasi` datetime DEFAULT NULL,
  `status` enum('menunggu_konfirmasi','menunggu_pembayaran','lunas','disajikan','batal') NOT NULL DEFAULT 'menunggu_konfirmasi',
  `total` int(10) unsigned NOT NULL DEFAULT 0,
  `bayar` int(10) unsigned DEFAULT NULL,
  `kembalian` int(10) unsigned DEFAULT NULL,
  `metode_bayar` enum('qris','tunai') DEFAULT NULL,
  `waktu_bayar` datetime DEFAULT NULL,
  `waktu_antar` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `pesanan_kode_pesanan_unique` (`kode_pesanan`),
  UNIQUE KEY `pesanan_token_unique` (`token`),
  UNIQUE KEY `pesanan_kode_bayar_unique` (`kode_bayar`),
  KEY `pesanan_meja_id_foreign` (`meja_id`),
  KEY `pesanan_waiter_id_foreign` (`waiter_id`),
  KEY `pesanan_kasir_id_foreign` (`kasir_id`),
  KEY `pesanan_status_index` (`status`),
  KEY `pesanan_waktu_bayar_index` (`waktu_bayar`),
  CONSTRAINT `pesanan_kasir_id_foreign` FOREIGN KEY (`kasir_id`) REFERENCES `users` (`id`),
  CONSTRAINT `pesanan_meja_id_foreign` FOREIGN KEY (`meja_id`) REFERENCES `meja` (`id`),
  CONSTRAINT `pesanan_waiter_id_foreign` FOREIGN KEY (`waiter_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
;

CREATE TABLE `detail_pesanan` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `pesanan_id` bigint(20) unsigned NOT NULL,
  `menu_id` bigint(20) unsigned NOT NULL,
  `jumlah` int(10) unsigned NOT NULL,
  `harga_satuan` int(10) unsigned NOT NULL,
  `subtotal` int(10) unsigned NOT NULL,
  `catatan` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `detail_pesanan_pesanan_id_foreign` (`pesanan_id`),
  KEY `detail_pesanan_menu_id_foreign` (`menu_id`),
  CONSTRAINT `detail_pesanan_menu_id_foreign` FOREIGN KEY (`menu_id`) REFERENCES `menu` (`id`),
  CONSTRAINT `detail_pesanan_pesanan_id_foreign` FOREIGN KEY (`pesanan_id`) REFERENCES `pesanan` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
;

CREATE TABLE `log_aktivitas` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` bigint(20) unsigned DEFAULT NULL,
  `pesanan_id` bigint(20) unsigned DEFAULT NULL,
  `aksi` varchar(50) NOT NULL,
  `keterangan` varchar(255) DEFAULT NULL,
  `waktu` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `log_aktivitas_user_id_foreign` (`user_id`),
  KEY `log_aktivitas_pesanan_id_foreign` (`pesanan_id`),
  KEY `log_aktivitas_waktu_index` (`waktu`),
  CONSTRAINT `log_aktivitas_pesanan_id_foreign` FOREIGN KEY (`pesanan_id`) REFERENCES `pesanan` (`id`) ON DELETE SET NULL,
  CONSTRAINT `log_aktivitas_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
;

CREATE TABLE `personal_access_tokens` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `tokenable_type` varchar(255) NOT NULL,
  `tokenable_id` bigint(20) unsigned NOT NULL,
  `name` text NOT NULL,
  `token` varchar(64) NOT NULL,
  `abilities` text DEFAULT NULL,
  `last_used_at` timestamp NULL DEFAULT NULL,
  `expires_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `personal_access_tokens_token_unique` (`token`),
  KEY `personal_access_tokens_tokenable_type_tokenable_id_index` (`tokenable_type`,`tokenable_id`),
  KEY `personal_access_tokens_expires_at_index` (`expires_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
;

