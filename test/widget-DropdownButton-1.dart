import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(
    home: DropdownWithButton(),
  ));
}

class DropdownWithButton extends StatefulWidget {
  const DropdownWithButton({super.key});

  @override
  _DropdownWithButtonState createState() => _DropdownWithButtonState();
}

class _DropdownWithButtonState extends State<DropdownWithButton> {
  String selectedFruit = 'Apple';
  String resultText = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("DropdownButton + Button")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DropdownButton<String>(
              value: selectedFruit,
              onChanged: (String? newValue) {
                setState(() {
                  selectedFruit = newValue!;
                });
              },
              items: <String>['Apple', 'Banana', 'Cherry', 'Date']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  resultText = 'You selected: $selectedFruit';
                });
              },
              child: Text("Confirm"),
            ),
            SizedBox(height: 20),
            Text(
              resultText,
              style: TextStyle(fontSize: 18, color: Colors.blue),
            ),
          ],
        ),
      ),
    );
  }
}
