import 'package:flutter/material.dart';

class DrinkEntryScreen extends StatefulWidget {
  final String drinkType; // '맥주' or '소주'

  const DrinkEntryScreen({super.key, required this.drinkType});

  @override
  State<DrinkEntryScreen> createState() => _DrinkEntryScreenState();
}

class _DrinkEntryScreenState extends State<DrinkEntryScreen> {
  int _count = 0;
  late final int cupSize;

  @override
  void initState() {
    super.initState();
    cupSize = widget.drinkType == '맥주' ? 250 : 50;
  }

  void _increment() {
    if (_count < 30) {
      setState(() => _count++);
    }
  }

  void _decrement() {
    if (_count > 0) {
      setState(() => _count--);
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
          Text(
            '${_count * cupSize}ml',
            style: const TextStyle(fontSize: 40, color: Colors.deepPurple),
          ),
          const SizedBox(height: 40),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5, // 한 줄에 5개
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
              ),
              itemCount: 30, // 총 30개 (5 x 6)
              itemBuilder: (context, index) {
                final isFilled = index < _count;
                return GestureDetector(
                  onTap: () {
                    if (isFilled) {
                      _decrement();
                    } else {
                      _increment();
                    }
                  },
                  child: _buildDrinkIcon(isFilled),
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

  Widget _buildDrinkIcon(bool filled) {
    if (widget.drinkType == '맥주') {
      return Image.asset(
        filled ? 'assets/images/beer.png' : 'assets/images/empty_beer.png',
        width: 40,
        height: 40,
      );
    } else {
      return Image.asset(
        filled ? 'assets/images/soju.png' : 'assets/images/empty_soju.png',
        width: 40,
        height: 40,
      );
    }
  }
}
