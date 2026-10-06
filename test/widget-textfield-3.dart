import 'package:flutter/material.dart';

void main() => runApp(MaterialApp(home: KeyboardTypeExample()));

class KeyboardTypeExample extends StatefulWidget {
  const KeyboardTypeExample({super.key});

  @override
  _KeyboardTypeExampleState createState() => _KeyboardTypeExampleState();
}

class _KeyboardTypeExampleState extends State<KeyboardTypeExample> {
  final emailController = TextEditingController();
  final numberController = TextEditingController();
  final phoneController = TextEditingController();
  final multilineController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    numberController.dispose();
    phoneController.dispose();
    multilineController.dispose();
    super.dispose();
  }

  void _showAllInputs() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Entered Data'),
        content: Text(
          'Email: ${emailController.text}\n'
          'Number: ${numberController.text}\n'
          'Phone: ${phoneController.text}\n'
          'Multiline: ${multilineController.text}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fieldStyle = TextStyle(fontSize: 14);

    return Scaffold(
      appBar: AppBar(title: Text('keyboardType Example')),
      body: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // Email
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

            // Number
            TextField(
              controller: numberController,
              keyboardType: TextInputType.number,
              style: fieldStyle,
              decoration: InputDecoration(
                labelText: 'Number',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            SizedBox(height: 8),

            // Phone
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

            // Multiline
            TextField(
              controller: multilineController,
              keyboardType: TextInputType.multiline,
              maxLines: 2, // Limit to save space
              style: fieldStyle,
              decoration: InputDecoration(
                labelText: 'Multiline',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            SizedBox(height: 10),

            // Button
            ElevatedButton(
              onPressed: _showAllInputs,
              child: Text('Show All Inputs', style: TextStyle(fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }
}
