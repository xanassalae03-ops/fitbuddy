import 'package:flutter/material.dart'; 
 
void main() { 
  runApp(MyApp()); 
} 
 
class MyApp extends StatelessWidget {
  const MyApp({super.key});
 
  @override 
  Widget build(BuildContext context) { 
    return MaterialApp( 
      title: 'Flutter Home Example', 
      home: HomePage(), // set the home screen 
    ); 
  } 
} 
 
class HomePage extends StatelessWidget {
  const HomePage({super.key});
 
  @override 
  Widget build(BuildContext context) { 
    return Scaffold( 
      appBar: AppBar( 
        title: Text('Home'), 
      ), 
      body: Center( 
        child: Text('Welcome to the Home Page!123'), 
      ),
       ); 
  } 
} 