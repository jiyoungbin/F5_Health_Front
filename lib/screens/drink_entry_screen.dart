import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class DrinkEntryScreen extends StatefulWidget {
  final String drinkType; // '맥주' or '소주'
  final int initialCount; // 초기 잔 수

  const DrinkEntryScreen({
    super.key,
    required this.drinkType,
    required this.initialCount,
  });

  @override
  State<DrinkEntryScreen> createState() => _DrinkEntryScreenState();
}

class _DrinkEntryScreenState extends State<DrinkEntryScreen> {
  late int _count;
  late final int cupSize;
  final String _resetKey = 'lastDrinkReset';

  @override
  void initState() {
    super.initState();
    // 잔 크기 결정
    cupSize = widget.drinkType == '맥주' ? 250 : 50;
    // 이전에 저장된 값 또는 초기값 세팅
    _count = widget.initialCount;
    // 매일 한 번 0으로 리셋
    _resetCountIfNeeded();
  }

  Future<void> _resetCountIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final lastReset = prefs.getString(_resetKey);
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    if (lastReset != today) {
      // 오늘 날짜와 다르면 _count를 0으로 리셋하고, 날짜 기록
      await prefs.setString(_resetKey, today);
      setState(() => _count = 0);
    }
  }

  void _increment() {
    if (_count < 30) setState(() => _count++);
  }

  void _decrement() {
    if (_count > 0) setState(() => _count--);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('오늘 ${widget.drinkType} 얼마나 드셨나요?')),
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
                crossAxisCount: 5,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
              ),
              itemCount: 30,
              itemBuilder: (context, index) {
                final isFilled = index < _count;
                return GestureDetector(
                  onTap: () {
                    isFilled ? _decrement() : _increment();
                  },
                  child: Image.asset(
                    widget.drinkType == '맥주'
                        ? (isFilled
                            ? 'assets/images/beer.png'
                            : 'assets/images/empty_beer.png')
                        : (isFilled
                            ? 'assets/images/soju.png'
                            : 'assets/images/empty_soju.png'),
                    width: 40,
                    height: 40,
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
                  Navigator.pop(context, _count);
                },
                child: const Text('확인'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/*import 'package:flutter/material.dart';

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
                crossAxisCount: 5,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
              ),
              itemCount: 30,
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
                  // ✅ 카운트 값 반환
                  Navigator.pop(context, _count);
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
*/
