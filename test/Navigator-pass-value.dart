import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Navigator Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
        ),
        useMaterial3: true,
      ),
      home: const FirstPage(),
    );
  }
}

// ==================== FIRST PAGE ====================

class FirstPage extends StatefulWidget {
  const FirstPage({super.key});

  @override
  State<FirstPage> createState() => _FirstPageState();
}

class _FirstPageState extends State<FirstPage> {
  String? returnedData;

  // เพิ่ม Controller สำหรับรับชื่อ
  final TextEditingController nameController = TextEditingController();

  Future<void> goToSecondPage() async {
    // เพิ่มการรับชื่อจากช่องกรอก
    String name = nameController.text;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SecondPage(
          // เปลี่ยนจากข้อความเดิมเป็นชื่อที่กรอก
          message: 'สวัสดี $name 👋',
        ),
      ),
    );

    if (result != null) {
      setState(() {
        returnedData = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'First Page',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),

      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            // Icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.home_rounded,
                size: 60,
                color: Colors.blue.shade700,
              ),
            ),

            const SizedBox(height: 20),

            // Title
            const Text(
              'Welcome to First Page',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'กดปุ่มเพื่อไปยังหน้าที่สอง',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 30),

            // เพิ่มช่องกรอกชื่อ
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'ชื่อ',
                hintText: 'กรอกชื่อของคุณ',
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Go to Second Page Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: goToSecondPage,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text(
                  'Go to Second Page',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 3,
                ),
              ),
            ),

            const SizedBox(height: 25),

            // Returned Data Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: returnedData == null
                    ? Colors.grey.shade100
                    : Colors.green.shade50,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: returnedData == null
                      ? Colors.grey.shade300
                      : Colors.green.shade200,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    returnedData == null
                        ? Icons.info_outline_rounded
                        : Icons.check_circle_rounded,
                    size: 35,
                    color: returnedData == null
                        ? Colors.grey
                        : Colors.green,
                  ),

                  const SizedBox(height: 10),

                  Text(
                    returnedData == null
                        ? 'No data returned yet'
                        : 'Data received successfully!',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: returnedData == null
                          ? Colors.grey.shade700
                          : Colors.green.shade700,
                    ),
                  ),

                  if (returnedData != null) ...[
                    const SizedBox(height: 8),

                    Text(
                      returnedData!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== SECOND PAGE ====================

class SecondPage extends StatelessWidget {
  final String message;

  const SecondPage({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Second Page',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),

      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            // Icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.message_rounded,
                size: 60,
                color: Colors.orange.shade700,
              ),
            ),

            const SizedBox(height: 20),

            // Title
            const Text(
              'Second Page',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 25),

            // Received Message
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.orange.shade200,
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    'Message received',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Return Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(
                    context,
                    'Data from Second Page',
                  );
                },
                icon: const Icon(
                  Icons.arrow_back_rounded,
                ),
                label: const Text(
                  'Return Data to First Page',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

