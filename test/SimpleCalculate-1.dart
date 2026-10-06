import 'package:flutter/material.dart'; 
 
void main() { 
  runApp(MyApp()); 
} 
 
// Main application widget 
class MyApp extends StatelessWidget {
  const MyApp({super.key});
 
  @override 
  Widget build(BuildContext context) { 
    return MaterialApp( 
      title: 'Simple Calculator', 
      theme: ThemeData( 
        primarySwatch: Colors.blue, 
      ), 
      home: CalculatorApp(), 
    ); 
  } 
} 
 
class CalculatorApp extends StatefulWidget {
  const CalculatorApp({super.key});
 
  @override 
  _CalculatorAppState createState() => _CalculatorAppState(); 
} 
 
class _CalculatorAppState extends State<CalculatorApp> { 
  double num1 = 0; 
  double num2 = 0; 
  double result = 0; 
 
  final TextEditingController controller1 = TextEditingController(); 
  final TextEditingController controller2 = TextEditingController(); 
 
  void calculate(String operation) { 
    setState(() {
       num1 = double.tryParse(controller1.text) ?? 0; 
      num2 = double.tryParse(controller2.text) ?? 0; 
 
      switch (operation) { 
        case '+': 
          result = num1 + num2; 
          break; 
        case '-': 
          result = num1 - num2; 
          break; 
        case '*': 
          result = num1 * num2; 
          break; 
        case '/': 
          result = num2 != 0 ? num1 / num2 : double.nan; 
          break; 
      } 
    }); 
  } 
 
  void clear() { 
    setState(() { 
      controller1.clear(); 
      controller2.clear(); 
      result = 0; 
    }); 
  } 
 
  @override 
  Widget build(BuildContext context) { 
    return Scaffold( 
      appBar: AppBar( 
        title: Text('Simple Calculator'), 
        centerTitle: true, 
      ), 
      body: Padding(
         padding: const EdgeInsets.all(16.0), 
        child: Column( 
          children: [ 
            TextField( 
              controller: controller1, 
              keyboardType: TextInputType.number, 
              decoration: InputDecoration(labelText: 'Enter first number'), 
            ), 
            TextField( 
              controller: controller2, 
              keyboardType: TextInputType.number, 
              decoration: InputDecoration(labelText: 'Enter second number'), 
            ), 
            SizedBox(height: 20), 
            Text( 
              'Result: $result', 
              style: TextStyle(fontSize: 28, fontWeight: 
FontWeight.bold), 
            ), 
            SizedBox(height: 20), 
            Wrap( 
              spacing: 10, 
              children: [ 
                ElevatedButton( 
                  onPressed: () => calculate('+'), 
                  child: Text('+'), 
                ), 
                ElevatedButton( 
                  onPressed: () => calculate('-'), 
                  child: Text('-'), 
                ), 
                ElevatedButton( 
                  onPressed: () => calculate('*'), 
                  child: Text('*'),
                    ), 
                ElevatedButton( 
                  onPressed: () => calculate('/'), 
                  child: Text('/'), 
                ), 
                ElevatedButton( 
                  style: ElevatedButton.styleFrom( 
                    backgroundColor: Colors.red, 
                  ), 
                  onPressed: clear, 
                  child: Text('Clear'), 
                ), 
              ], 
            ), 
          ], 
        ), 
      ), 
    ); 
  } 
} 