class VerificationResponse {
  final String status;
  final String requestId;
  final VerificationData? data;

  const VerificationResponse({
    required this.status,
    required this.requestId,
    this.data,
  });

  factory VerificationResponse.fromJson(Map<String, dynamic> json) {
    return VerificationResponse(
      status: json['status'] ?? '',
      requestId: json['requestId'] ?? '',
      data: json['data'] != null
          ? VerificationData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }
}

class VerificationData {
  final String namelat;
  final String surnamelat;
  final String patronymlat;
  final String namecyr;
  final String surnamecyr;
  final String patronymcyr;
  final String birthDate;
  final String birthplace;
  final String citizenship;
  final String docPinfl;
  final String currentDocument;
  final String livestatus;
  final String sex;

  const VerificationData({
    required this.namelat,
    required this.surnamelat,
    required this.patronymlat,
    required this.namecyr,
    required this.surnamecyr,
    required this.patronymcyr,
    required this.birthDate,
    required this.birthplace,
    required this.citizenship,
    required this.docPinfl,
    required this.currentDocument,
    required this.livestatus,
    required this.sex,
  });

  factory VerificationData.fromJson(Map<String, dynamic> json) {
    return VerificationData(
      namelat: json['namelat'] ?? '',
      surnamelat: json['surnamelat'] ?? '',
      patronymlat: json['patronymlat'] ?? '',
      namecyr: json['namecyr'] ?? '',
      surnamecyr: json['surnamecyr'] ?? '',
      patronymcyr: json['patronymcyr'] ?? '',
      birthDate: json['birth_date'] ?? '',
      birthplace: json['birthplace'] ?? '',
      citizenship: json['citizenship'] ?? '',
      docPinfl: json['doc_pinfl'] ?? '',
      currentDocument: json['current_document'] ?? '',
      livestatus: json['livestatus'] ?? '',
      sex: json['sex'] ?? '',
    );
  }
}
