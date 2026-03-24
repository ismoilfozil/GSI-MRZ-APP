import 'package:flutter/material.dart';
import '../models/verification_response.dart';
import 'home_screen.dart';

class VerificationResultScreen extends StatelessWidget {
  final VerificationResponse response;

  const VerificationResultScreen({super.key, required this.response});

  @override
  Widget build(BuildContext context) {
    final data = response.data;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verification Result'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(context),
            const SizedBox(height: 16),
            if (data != null) ...[
              _buildCard('Name (Latin)', [
                _buildRow('First Name', data.namelat),
                _buildRow('Last Name', data.surnamelat),
                _buildRow('Patronymic', data.patronymlat),
              ]),
              const SizedBox(height: 16),
              _buildCard('Name (Cyrillic)', [
                _buildRow('First Name', data.namecyr),
                _buildRow('Last Name', data.surnamecyr),
                _buildRow('Patronymic', data.patronymcyr),
              ]),
              const SizedBox(height: 16),
              _buildCard('Personal Info', [
                _buildRow('Date of Birth', data.birthDate),
                _buildRow('Birthplace', data.birthplace),
                _buildRow('Citizenship', data.citizenship),
                _buildRow('Sex', data.sex == '1' ? 'Male' : data.sex == '2' ? 'Female' : data.sex),
                _buildRow('PINFL', data.docPinfl),
                _buildRow('Document', data.currentDocument),
                _buildRow(
                  'Live Status',
                  data.livestatus == '1' ? 'Active' : data.livestatus,
                ),
              ]),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                  (_) => false,
                ),
                icon: const Icon(Icons.home),
                label: const Text('Back to Home'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
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

  Widget _buildStatusCard(BuildContext context) {
    final isOk = response.status.toLowerCase() == 'ok';
    return Card(
      color: isOk ? Colors.green.shade50 : Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              isOk ? Icons.verified_user : Icons.error_outline,
              color: isOk ? Colors.green : Colors.red,
              size: 36,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isOk ? 'Verification Successful' : 'Verification Failed',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isOk ? Colors.green.shade800 : Colors.red.shade800,
                    ),
                  ),
                  Text(
                    'Status: ${response.status}',
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                ],
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
            Text(title,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
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
            width: 130,
            child: Text(label,
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : '—',
              style: const TextStyle(
                  fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
