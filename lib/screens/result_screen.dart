import 'package:flutter/material.dart';
import 'package:mrz_parser/mrz_parser.dart';
import 'face_scan_screen.dart';

class ResultScreen extends StatelessWidget {
  final MRZResult result;

  const ResultScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Result'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCard('Personal Info', [
              _buildRow('Surnames', result.surnames),
              _buildRow('Given Names', result.givenNames),
              _buildRow('Sex', _sexLabel(result.sex)),
              _buildRow('Nationality', result.nationalityCountryCode),
              _buildRow('Date of Birth', _formatDate(result.birthDate)),
            ]),
            const SizedBox(height: 16),
            _buildCard('Document Info', [
              _buildRow('Document Type', result.documentType),
              _buildRow('Document Number', result.documentNumber),
              _buildRow('Country Code', result.countryCode),
              _buildRow('Expiry Date', _formatDate(result.expiryDate)),
              _buildRow('Personal Number', result.personalNumber),
              if (result.personalNumber2 != null)
                _buildRow('Personal Number 2', result.personalNumber2!),
            ]),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FaceScanScreen(
                      docNumber: result.documentNumber,
                      birthDate:
                          '${result.birthDate.day.toString().padLeft(2, '0')}.${result.birthDate.month.toString().padLeft(2, '0')}.${result.birthDate.year}',
                    ),
                  ),
                ),
                icon: const Icon(Icons.face),
                label: const Text('Continue to Face Scan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
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

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : '—',
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
