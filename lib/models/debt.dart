class Debt {
  final String id;
  final String namaHutang;
  final double jumlahHutang;
  final DateTime tanggalHutang;
  final String? deskripsi;

  Debt({
    required this.id,
    required this.namaHutang,
    required this.jumlahHutang,
    required this.tanggalHutang,
    this.deskripsi,
  });

  factory Debt.fromJson(Map<String, dynamic> json) {
    return Debt(
      id: json['id'],
      namaHutang: json['nama_hutang'],
      jumlahHutang: json['jumlah_hutang'].toDouble(),
      tanggalHutang: DateTime.parse(json['tanggal_hutang']),
      deskripsi: json['deskripsi'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nama_hutang': namaHutang,
      'jumlah_hutang': jumlahHutang,
      'tanggal_hutang': tanggalHutang.toIso8601String().split('T').first,
      'deskripsi': deskripsi,
    };
  }
}