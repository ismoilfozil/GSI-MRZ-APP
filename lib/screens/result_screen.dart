import 'package:flutter/material.dart';
import 'package:mrz_parser/mrz_parser.dart';
import 'face_scan_screen.dart';

class ResultScreen extends StatefulWidget {
  final MRZResult result;

  const ResultScreen({super.key, required this.result});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late final TextEditingController _surnames;
  late final TextEditingController _givenNames;
  late final TextEditingController _sex;
  late final TextEditingController _nationality;
  late final TextEditingController _birthDate;
  late final TextEditingController _documentType;
  late final TextEditingController _docSeria;
  late final TextEditingController _documentNumber;
  late final TextEditingController _countryCode;
  late final TextEditingController _expiryDate;
  late final TextEditingController _personalNumber;
  late final TextEditingController _personalNumber2;

  @override
  void initState() {
    super.initState();
    final r = widget.result;
    _surnames = TextEditingController(text: r.surnames);
    _givenNames = TextEditingController(text: r.givenNames);
    _sex = TextEditingController(text: _sexLabel(r.sex));
    _nationality = TextEditingController(text: r.nationalityCountryCode);
    _birthDate = TextEditingController(text: _formatDate(r.birthDate));
    _documentType = TextEditingController(text: r.documentType);
    final seriaMatch = RegExp(r'^([A-Za-z]+)(\d+)$').firstMatch(r.documentNumber);
    _docSeria = TextEditingController(text: seriaMatch?.group(1) ?? '');
    _documentNumber = TextEditingController(text: seriaMatch?.group(2) ?? r.documentNumber);
    _countryCode = TextEditingController(text: r.countryCode);
    _expiryDate = TextEditingController(text: _formatDate(r.expiryDate));
    _personalNumber = TextEditingController(text: r.personalNumber);
    _personalNumber2 = TextEditingController(text: r.personalNumber2 ?? '');
  }

  @override
  void dispose() {
    _surnames.dispose();
    _givenNames.dispose();
    _sex.dispose();
    _nationality.dispose();
    _birthDate.dispose();
    _documentType.dispose();
    _docSeria.dispose();
    _documentNumber.dispose();
    _countryCode.dispose();
    _expiryDate.dispose();
    _personalNumber.dispose();
    _personalNumber2.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _sexLabel(Sex sex) {
    switch (sex) {
      case Sex.male:
        return 'Male';
      case Sex.female:
        return 'Female';
      case Sex.none:
        return 'Unspecified';
    }
  }

  int _mrzCheckDigit(String s) {
    const weights = [7, 3, 1];
    int sum = 0;
    for (int i = 0; i < s.length; i++) {
      final c = s[i];
      int val;
      if (c == '<') {
        val = 0;
      } else if (c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57) {
        val = int.parse(c);
      } else {
        val = c.toUpperCase().codeUnitAt(0) - 55;
      }
      sum += val * weights[i % 3];
    }
    return sum % 10;
  }

  String _mrzDate(DateTime d) {
    return '${(d.year % 100).toString().padLeft(2, '0')}'
        '${d.month.toString().padLeft(2, '0')}'
        '${d.day.toString().padLeft(2, '0')}';
  }

  String _reconstructMrz(MRZResult r) {
    final type = r.documentType.padRight(2, '<');
    final country = r.countryCode.padRight(3, '<');
    final docNum = r.documentNumber.toUpperCase().padRight(9, '<');
    final docCheck = _mrzCheckDigit(docNum);
    final nationality = r.nationalityCountryCode.padRight(3, '<');
    final bd = _mrzDate(r.birthDate);
    final bdCheck = _mrzCheckDigit(bd);
    final sex = r.sex == Sex.male ? 'M' : r.sex == Sex.female ? 'F' : '<';
    final ed = _mrzDate(r.expiryDate);
    final edCheck = _mrzCheckDigit(ed);
    final names =
        '${r.surnames.replaceAll(' ', '<')}<<${r.givenNames.replaceAll(' ', '<')}';

    final isTd1 = !r.documentType.startsWith('P');

    if (isTd1) {
      // TD1: 3 lines × 30 chars
      final optional1 = (r.personalNumber).padRight(15, '<');
      final line1 = '$type$country$docNum$docCheck$optional1'.padRight(30, '<').substring(0, 30);

      final optional2 = (r.personalNumber2 ?? '').padRight(11, '<');
      final compositeData = '$docNum$docCheck$bd$bdCheck$ed$edCheck$optional2';
      final overallCheck = _mrzCheckDigit(compositeData);
      final line2 = '$bd$bdCheck$sex$ed$edCheck$nationality$optional2$overallCheck';

      final line3 = names.padRight(30, '<').substring(0, 30);

      return '$line1\n$line2\n$line3';
    } else {
      // TD3: 2 lines × 44 chars
      final line1 = '$type$country${names.padRight(39, '<')}'.substring(0, 44);

      final personal = (r.personalNumber).padRight(14, '<');
      final personalCheck = _mrzCheckDigit(personal);
      final overallCheck = _mrzCheckDigit(
          '$docNum$docCheck$bd$bdCheck$ed$edCheck$personal$personalCheck');
      final line2 = '$docNum$docCheck$nationality$bd$bdCheck$sex$ed$edCheck$personal$personalCheck$overallCheck';

      return '$line1\n$line2';
    }
  }

  void _continueToFaceScan() {
    final docSeria = _docSeria.text.trim();
    final docNumber = _documentNumber.text.trim();
    // Try to parse edited birth date; fall back to original
    DateTime birth;
    try {
      final parts = _birthDate.text.trim().split('-');
      birth = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    } catch (_) {
      birth = widget.result.birthDate;
    }
    final birthFormatted =
        '${birth.day.toString().padLeft(2, '0')}.${birth.month.toString().padLeft(2, '0')}.${birth.year}';

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => FaceScanScreen(
          docSeria: docSeria,
          docNumber: docNumber,
          birthDate: birthFormatted,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Result'),
        backgroundColor: const Color(0xFFE4A216),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                _reconstructMrz(widget.result),
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: Colors.greenAccent,
                  letterSpacing: 1.5,
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildCard('Personal Info', [
              _buildField('Surnames', _surnames),
              _buildField('Given Names', _givenNames),
              _buildField('Sex', _sex),
              _buildField('Nationality', _nationality),
              _buildField('Date of Birth', _birthDate, hint: 'YYYY-MM-DD'),
            ]),
            const SizedBox(height: 16),
            _buildCard('Document Info', [
              _buildField('Document Type', _documentType),
              _buildField('Doc Seria', _docSeria),
              _buildField('Doc Number', _documentNumber),
              _buildField('Country Code', _countryCode),
              _buildField('Expiry Date', _expiryDate, hint: 'YYYY-MM-DD'),
              _buildField('Personal Number', _personalNumber),
              _buildField('Personal Number 2', _personalNumber2),
            ]),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _continueToFaceScan,
                icon: const Icon(Icons.face),
                label: const Text('Continue to Face Scan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE4A216),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Scan Again'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFE4A216),
                  side: const BorderSide(color: Color(0xFFE4A216)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(String title, List<Widget> rows) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            ...rows,
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, {String? hint}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              decoration: InputDecoration(
                hintText: hint ?? '',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: Color(0xFFE4A216)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
