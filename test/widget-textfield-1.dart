import 'package:flutter/material.dart';

void main() => runApp(MaterialApp(home: MyForm()));

class MyForm extends StatefulWidget {
  const MyForm({super.key});

  @override
  _MyFormState createState() => _MyFormState();
}

class _MyFormState extends State<MyForm> {
  // Create a TextEditingController to manage and access the value from the TextField
  final nameController = TextEditingController();

  @override
  void dispose() {
    // ?? This method is called when the widget is removed from the widget tree
    // It's important to dispose controllers to free up resources and prevent memory leaks
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('TextField Demo')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: nameController, // Connects the TextField to the controller
              maxLength: 10,
              decoration: InputDecoration(
                labelText: 'Your name :',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              child: Text('Click Button'),
              onPressed: () {
                // Display the entered text in an AlertDialog
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    content: Text('Type : ${nameController.text}'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
