import 'package:flutter/material.dart';

class DrinkEntryScreen extends StatefulWidget {
  final String drinkType; // 맥주 or 소주

  const DrinkEntryScreen({super.key, required this.drinkType});

  @override
  State<DrinkEntryScreen> createState() => _DrinkEntryScreenState();
}

class _DrinkEntryScreenState extends State<DrinkEntryScreen> {
  int _count = 0;
  static const int cupSize = 250; // ml

  void _increment() {
    setState(() {
      _count++;
    });
  }

  void _decrement() {
    if (_count > 0) {
      setState(() {
        _count--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('오늘 ${widget.drinkType} 얼마나 드셨나요?'),
      ),
      body: Column(
        children: [
          const SizedBox(height: 40),
          Text('${_count * cupSize}ml',
              style: const TextStyle(fontSize: 40, color: Colors.deepPurple)),
          const SizedBox(height: 40),
          // 잔 그림 그리기
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
              ),
              itemCount: 20,
              itemBuilder: (context, index) {
                bool filled = index < _count;
                return GestureDetector(
                  onTap: () {
                    if (filled) {
                      _decrement();
                    } else {
                      _increment();
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      color: filled ? Colors.deepPurple[100] : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(child: Icon(Icons.add)),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: 저장 로직
                  Navigator.pop(context);
                },
                child: const Text('확인'),
              ),
            ),
          )
        ],
      ),
    );
  }
}
