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
    String pick(List<String> keys) {
      for (final k in keys) {
        final v = json[k];
        if (v is String && v.isNotEmpty) return v;
      }
      return '';
    }

    return VerificationData(
      namelat: pick(['namelat', 'givenname', 'first_name']),
      surnamelat: pick(['surnamelat', 'surname', 'last_name']),
      patronymlat: pick(['patronymlat', 'patronym']),
      namecyr: pick(['namecyr']),
      surnamecyr: pick(['surnamecyr']),
      patronymcyr: pick(['patronymcyr']),
      birthDate: pick(['birth_date']),
      birthplace: pick(['birthplace', 'birth_place']),
      citizenship: pick(['citizenship']),
      docPinfl: pick(['doc_pinfl', 'pin', 'current_pinpp']),
      currentDocument: pick(['current_document', 'document']),
      livestatus: pick(['livestatus']),
      sex: pick(['sex', 'gender']),
    );
  }
}
