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
      title: 'setState Example', 
      theme: ThemeData( 
        primarySwatch: Colors.blue, 
      ), 
      home: CounterApp(), // The home screen 
    ); 
  } 
} 
 
// A StatefulWidget that maintains a counter value 
class CounterApp extends StatefulWidget {
  const CounterApp({super.key});
 
  @override 
  _CounterAppState createState() => _CounterAppState(); 
} 
 
class _CounterAppState extends State<CounterApp> { 
  int counter = 0; // State variable to store the counter value 
 
  // Function to increment counter 
  void increment() { 
    setState(() {
       counter++; 
    }); 
  } 
 
  // Function to decrement counter 
  void decrement() { 
    setState(() { 
      counter--; 
    }); 
  } 
 
  // Function to reset counter 
  void reset() { 
    setState(() { 
      counter = 0; 
    }); 
  } 

  // Function to square counter
void square() {
  setState(() {
    counter = counter * counter;
  });
}
 
  @override 
  Widget build(BuildContext context) { 
    return Scaffold( 
      appBar: AppBar( 
        title: Text('setState Example'), 
        centerTitle: true, 
      ), 
      body: Center( 
        child: Text( 
          'Count: $counter', // Display the counter value 
          style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold), 
        ), 
      ), 
      floatingActionButton: Row( 
        mainAxisAlignment: MainAxisAlignment.end, 
        children: [ 
          // Decrease button 
          FloatingActionButton(
              heroTag: 'decrement', 
            onPressed: decrement, 
            child: Icon(Icons.remove), 
          ), 
          SizedBox(width: 10), 
          // Reset button 
          FloatingActionButton( 
            heroTag: 'reset', 
            onPressed: reset, 
            child: Icon(Icons.refresh), 
          ), 
          SizedBox(width: 10), 
          // Increase button 
          FloatingActionButton( 
            heroTag: 'increment', 
            onPressed: increment, 
            child: Icon(Icons.add),
          ),
          SizedBox(width: 10),

          // Square button
          FloatingActionButton(
            heroTag: 'square',
            onPressed: square,
            child: Icon(Icons.exposure_plus_2),
          ),

          SizedBox(width: 10),  
           
        ], 
      ), 
    ); 
  } 
}