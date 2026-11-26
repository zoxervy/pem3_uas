-- Data demo. Password: admin123 (admin), waitress123 (rina, budi), kasir123 (sari). GANTI sebelum dipakai sungguhan.
SET NAMES utf8mb4;

INSERT INTO users (nama, username, password, role, no_hp, aktif, created_at, updated_at) VALUES
  ('Administrator', 'admin', '$2y$10$c0N85l4eoe2yWf4GMr0X6OSDxosQ2u4p4xU3am6RtV7nRupyk7Ylu', 'admin', NULL, 1, NOW(), NOW()),
  ('Rina', 'rina', '$2y$10$P2A2CFD0UGSQbuAYAZtNru1Wq9SGI4Cvn7HYmRzXOF0d9jAPyqMre', 'waitress', '081200000001', 1, NOW(), NOW()),
  ('Budi', 'budi', '$2y$10$pUfG1NqM/nAKPPUuHH4PX.s5d8bcmq2kaqiVXUHepFCEA.eW5W0G.', 'waitress', '081200000002', 1, NOW(), NOW()),
  ('Sari', 'sari', '$2y$10$u4ieI3ro0a0cghqIuEXMKe9ZV9K3nzhmtp.QwSIwlf48U4ckwA9X.', 'kasir', '081200000003', 1, NOW(), NOW());

INSERT INTO kategori (id, nama_kategori) VALUES (1, 'Makanan'), (2, 'Minuman'), (3, 'Snack');

INSERT INTO menu (kategori_id, nama_menu, harga, deskripsi) VALUES
  (1, 'Nasi Goreng Spesial', 25000, 'Nasi goreng dengan telur dan ayam suwir'),
  (1, 'Mie Goreng', 22000, 'Mie goreng sayur dan telur'),
  (1, 'Ayam Bakar', 30000, 'Ayam bakar bumbu kecap + nasi'),
  (1, 'Soto Ayam', 20000, 'Soto ayam kuah bening'),
  (2, 'Es Teh Manis', 5000, NULL),
  (2, 'Es Jeruk', 8000, NULL),
  (2, 'Kopi Hitam', 10000, NULL),
  (2, 'Air Mineral', 4000, NULL),
  (3, 'Kentang Goreng', 15000, NULL),
  (3, 'Pisang Goreng', 12000, NULL);

-- 3 meja; kode_qr = isi QR yang ditempel di meja
INSERT INTO meja (nomor_meja, kapasitas, kode_qr) VALUES
  ('1', 4, 'j1M7I0WKsQAISxDobmsGOHmiHhQ83YBl'),
  ('2', 4, 'f1mWyLdVbhaiO22jKg6pJj3Wn1kQa436'),
  ('3', 6, 'gFpri79QRaMRhPbeuTCAki9m4ap7KIQ6');
