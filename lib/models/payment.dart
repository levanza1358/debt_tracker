class Payment {
  final String id;
  final String debtId;
  final double jumlahBayar;
  final DateTime tanggalBayar;
  final String? fotoUrl;

  Payment({
    required this.id,
    required this.debtId,
    required this.jumlahBayar,
    required this.tanggalBayar,
    this.fotoUrl,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'],
      debtId: json['debt_id'],
      jumlahBayar: json['jumlah_bayar'].toDouble(),
      tanggalBayar: DateTime.parse(json['tanggal_bayar']),
      fotoUrl: json['foto_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'debt_id': debtId,
      'jumlah_bayar': jumlahBayar,
      'tanggal_bayar': tanggalBayar.toIso8601String().split('T').first,
      'foto_url': fotoUrl,
    };
  }
}