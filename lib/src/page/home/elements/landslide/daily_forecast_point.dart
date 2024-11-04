class DailyForecastPoint {
  final String maDiem;
  final String viTri;
  final Map<String, dynamic> toaDo;
  final Map<String, dynamic> diaGioi;
  final List<Map<String, dynamic>> duBao;

  DailyForecastPoint({
    required this.maDiem,
    required this.viTri,
    required this.toaDo,
    required this.diaGioi,
    required this.duBao,
  });

  factory DailyForecastPoint.fromJson(Map<String, dynamic> json) {
    return DailyForecastPoint(
      maDiem: json['ma_diem'] ?? '',
      viTri: json['vi_tri'] ?? '',
      toaDo: json['toa_do'] ?? {},
      diaGioi: json['dia_gioi'] ?? {},
      duBao: List<Map<String, dynamic>>.from(json['du_bao'] ?? []),
    );
  }
}