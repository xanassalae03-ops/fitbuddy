import 'package:flutter/material.dart';
import 'page2.dart';

class Page1 extends StatelessWidget {
  const Page1({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Page 1'),
      ),
      body: Center(
        child: Text(
          'Hello, this is Page 1',
          style: TextStyle(fontSize: 24),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton(
        heroTag: 'page1_next',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => Page2()),
          );
        },
        child: Icon(Icons.arrow_forward),
      ),
    );
  }
}