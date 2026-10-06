import 'package:flutter/material.dart';
import 'page3.dart';

class Page2 extends StatelessWidget {
  const Page2({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Page 2'),
        automaticallyImplyLeading: false, // ซ่อนปุ่มย้อนกลับบน AppBar
      ),
      body: Center(
        child: Text(
          'Hello, this is Page 2',
          style: TextStyle(fontSize: 24),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // ปุ่มลูกศรล่างซ้าย -> กลับไป Page 1
            FloatingActionButton(
              heroTag: 'page2_back',
              onPressed: () {
                Navigator.pop(context);
              },
              child: Icon(Icons.arrow_back),
            ),
            // ปุ่มลูกศรล่างขวา -> ไป Page 3
            FloatingActionButton(
              heroTag: 'page2_next',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Page3()),
                );
              },
              child: Icon(Icons.arrow_forward),
            ),
          ],
        ),
      ),
    );
  }
}