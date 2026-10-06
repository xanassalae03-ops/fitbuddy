import 'package:flutter/material.dart';

void main() => runApp(MaterialApp(home: CompactFormExample()));

class CompactFormExample extends StatefulWidget {
  const CompactFormExample({super.key});

  @override
  _CompactFormExampleState createState() => _CompactFormExampleState();
}

class _CompactFormExampleState extends State<CompactFormExample> {
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  bool acceptTerms = false; // Checkbox state

  @override
  void dispose() {
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  void _showResult() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Entered Data'),
        content: Text(
          'Email: ${emailController.text}\n'
          'Phone: ${phoneController.text}\n'
          'Accepted Terms: ${acceptTerms ? "Yes" : "No"}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fieldStyle = TextStyle(fontSize: 14);

    return Scaffold(
      appBar: AppBar(title: Text('Form with Checkbox')),
      body: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // Email field
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              style: fieldStyle,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            SizedBox(height: 8),

            // Phone field
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              style: fieldStyle,
              decoration: InputDecoration(
                labelText: 'Phone',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            SizedBox(height: 8),

            // Checkbox
            Row(
              children: [
                Checkbox(
                  value: acceptTerms,
                  onChanged: (bool? value) {
                    setState(() {
                      acceptTerms = value ?? false;
                    });
                  },
                  visualDensity: VisualDensity.compact,
                ),
                Expanded(
                  child: Text(
                    'I accept the terms and conditions',
                    style: TextStyle(fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),

            // Button
            ElevatedButton(
              onPressed: _showResult,
              child: Text('Show All Inputs', style: TextStyle(fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }
}
