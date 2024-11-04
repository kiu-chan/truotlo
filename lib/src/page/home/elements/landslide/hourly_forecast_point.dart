class HourlyForecastPoint {
  final int id;
  final int recordId; 
  final String tenDiem;
  final String viTri;
  final String kinhDo;
  final String viDo;
  final String tinh;
  final String huyen;
  final String xa;
  final String nguyCoLuQuet;
  final String nguyCoTruotNong;
  final String nguyCoTruotLon;
  final int nam;
  final int thang;
  final int ngay;
  final int gio;
  final String createdAt;

  HourlyForecastPoint({
    required this.id,
    required this.recordId,
    required this.tenDiem, 
    required this.viTri,
    required this.kinhDo,
    required this.viDo,
    required this.tinh,
    required this.huyen,
    required this.xa,
    required this.nguyCoLuQuet,
    required this.nguyCoTruotNong,
    required this.nguyCoTruotLon,
    required this.nam,
    required this.thang,
    required this.ngay,
    required this.gio,
    required this.createdAt,
  });

  factory HourlyForecastPoint.fromJson(Map<String, dynamic> json) {
    return HourlyForecastPoint(
      id: json['id'] ?? 0,
      recordId: json['record_id'] ?? 0,
      tenDiem: json['ten_diem'] ?? '',
      viTri: json['vi_tri'] ?? '',
      kinhDo: json['kinh_do'] ?? '',
      viDo: json['vi_do'] ?? '',
      tinh: json['tinh'] ?? '',
      huyen: json['huyen'] ?? '',
      xa: json['xa'] ?? '',
      nguyCoLuQuet: json['nguy_co_lu_quet']?.toString() ?? '0',
      nguyCoTruotNong: json['nguy_co_truot_nong']?.toString() ?? '0', 
      nguyCoTruotLon: json['nguy_co_truot_lon']?.toString() ?? '0',
      nam: json['nam'] ?? 0,
      thang: json['thang'] ?? 0,
      ngay: json['ngay'] ?? 0,
      gio: json['gio'] ?? 0,
      createdAt: json['created_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'record_id': recordId,
      'ten_diem': tenDiem,
      'vi_tri': viTri,
      'kinh_do': kinhDo,
      'vi_do': viDo,
      'tinh': tinh,
      'huyen': huyen,
      'xa': xa,
      'nguy_co_lu_quet': nguyCoLuQuet,
      'nguy_co_truot_nong': nguyCoTruotNong,
      'nguy_co_truot_lon': nguyCoTruotLon,
      'nam': nam,
      'thang': thang,
      'ngay': ngay,
      'gio': gio,
      'created_at': createdAt,
    };
  }
}