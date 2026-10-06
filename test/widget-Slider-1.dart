import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(
    home: SliderOnlyExample(),
  ));
}

class SliderOnlyExample extends StatefulWidget {
  const SliderOnlyExample({super.key});

  @override
  _SliderOnlyExampleState createState() => _SliderOnlyExampleState();
}

class _SliderOnlyExampleState extends State<SliderOnlyExample> {
  double sliderValue = 50;
  String resultText = '';

  @override
  void dispose() {
    // ����� controller ��� dispose ���ѧ����������ç���ҧ����
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Slider Widget Example")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Slider Value: ${sliderValue.round()}',
                style: TextStyle(fontSize: 18)),
            Slider(
              value: sliderValue,
              min: 0,
              max: 100,
              divisions: 50,
              label: sliderValue.round().toString(),
              onChanged: (double value) {
                setState(() {
                  sliderValue = value;
                });
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  resultText = 'Selected value: ${sliderValue.round()}';
                });
              },
              child: Text("Confirm"),
            ),
            SizedBox(height: 20),
            Text(
              resultText,
              style: TextStyle(fontSize: 16, color: Colors.teal),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
