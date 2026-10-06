import 'package:flutter/material.dart';

void main() => runApp(MaterialApp(home: RadioExample()));

class RadioExample extends StatefulWidget {
  const RadioExample({super.key});

  @override
  _RadioExampleState createState() => _RadioExampleState();
}

class _RadioExampleState extends State<RadioExample> {
  String selectedGender = 'male'; // Default selected

  void _showSelected() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Selected Gender'),
        content: Text('You selected: $selectedGender'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Radio Button Example')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Choose your gender:', style: TextStyle(fontSize: 16)),

            // Male radio
            Row(
              children: [
                Radio<String>(
                  value: 'male',
                  groupValue: selectedGender,
                  onChanged: (value) {
                    setState(() {
                      selectedGender = value!;
                    });
                  },
                ),
                Text('Male'),
              ],
            ),

            // Female radio
            Row(
              children: [
                Radio<String>(
                  value: 'female',
                  groupValue: selectedGender,
                  onChanged: (value) {
                    setState(() {
                      selectedGender = value!;
                    });
                  },
                ),
                Text('Female'),
              ],
            ),

            // Other radio
            Row(
              children: [
                Radio<String>(
                  value: 'other',
                  groupValue: selectedGender,
                  onChanged: (value) {
                    setState(() {
                      selectedGender = value!;
                    });
                  },
                ),
                Text('Other'),
              ],
            ),

            SizedBox(height: 16),

            ElevatedButton(
              onPressed: _showSelected,
              child: Text('Show Selected'),
            ),
          ],
        ),
      ),
    );
  }
}
