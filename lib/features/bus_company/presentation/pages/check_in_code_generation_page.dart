import 'package:flutter/material.dart';

class CheckInCodeGenerationPage extends StatelessWidget {
  const CheckInCodeGenerationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trip Check-in Codes')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text(
              'Select Trip to Generate Check-in Codes',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: 5,
                itemBuilder: (context, index) => Card(
                  child: ListTile(
                    title: Text('Trip #$index'),
                    subtitle: const Text('Destination: City Center'),
                    trailing: ElevatedButton(
                      onPressed: () {},
                      child: const Text('Generate'),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
