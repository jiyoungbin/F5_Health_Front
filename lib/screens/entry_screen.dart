// lib/screens/entry_screen.dart


import 'package:flutter/material.dart';
import '../app_data.dart';

// 추가됨 (DrinkEntryScreen import)
import 'drink_entry_screen.dart';

class EntryScreen extends StatefulWidget {
  const EntryScreen({Key? key}) : super(key: key);
  @override
  State<EntryScreen> createState() => _EntryScreenState();
}

class _EntryScreenState extends State<EntryScreen> {
  int _initialWater = AppData.waterCount;
  int _initialSmoke = AppData.smokeCount;
  int _extraWater = 0;
  int _extraSmoke = 0;
  final _waterController = TextEditingController();
  final _smokeController = TextEditingController();

  @override
  void dispose() {
    _waterController.dispose();
    _smokeController.dispose();
    super.dispose();
  }

  Future<void> _showAddDialog({
    required String title,
    required TextEditingController ctrl,
    required ValueSetter<int> onConfirm,
  }) {
    ctrl.clear();
    return showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('$title 추가 입력'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: '숫자를 입력하세요'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
          TextButton(
            onPressed: () {
              final v = int.tryParse(ctrl.text) ?? 0;
              onConfirm(v);
              Navigator.pop(context);
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _onSave() {
    AppData.waterCount = _initialWater + _extraWater;
    AppData.smokeCount = _initialSmoke + _extraSmoke;
    // TODO: 서버 전송 로직 추가 예정
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('오늘 하루 건강 기록 정리하기')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // 흡연 기록
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('흡연 기록', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('총 흡연 개비수: ${_initialSmoke + _extraSmoke}개비'),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => _showAddDialog(
                    title: '흡연량',
                    ctrl: _smokeController,
                    onConfirm: (v) => setState(() => _extraSmoke += v),
                  ),
                  child: const Text('개비 수 추가 입력'),
                ),
              ]),
            ),
          ),

          const SizedBox(height: 16),

          // 음수량 기록
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('음수량 기록', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('총 음수량: ${_initialWater + _extraWater}잔'),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => _showAddDialog(
                    title: '음수량',
                    ctrl: _waterController,
                    onConfirm: (v) => setState(() => _extraWater += v),
                  ),
                  child: const Text('잔 수 추가 입력'),
                ),
              ]),
            ),
          ),

          const SizedBox(height: 16),

          // 음주량 버튼 (맥주/소주)
          const Text('음주량 기록', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  // 추가됨 (맥주 입력 화면으로 이동)
                  print("맥주 버튼 눌림"); // ← 이거 추가
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DrinkEntryScreen(drinkType: '맥주'),
                    ),
                  );
                },
                child: const Text('맥주'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  // 추가됨 (소주 입력 화면으로 이동)
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DrinkEntryScreen(drinkType: '소주'),
                    ),
                  );
                },
                child: const Text('소주'),
              ),
            ),
          ]),

          const SizedBox(height: 16),

          // 식단 입력
          const Text('식단 입력', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...AppData.meals.keys.map((meal) {
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(meal),
              subtitle: Text(
                AppData.meals[meal]!.isEmpty
                  ? '아직 입력된 식단이 없습니다.'
                  : AppData.meals[meal]!,
              ),
              onTap: () {
                final ctrl = TextEditingController(text: AppData.meals[meal]);
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text('$meal 입력'),
                    content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: '내용을 입력하세요')),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
                      TextButton(onPressed: () {
                        setState(() => AppData.meals[meal] = ctrl.text);
                        Navigator.pop(context);
                      }, child: const Text('저장')),
                    ],
                  ),
                );
              },
            );
          }).toList(),

          const SizedBox(height: 24),
          Center(
            child: ElevatedButton(
              onPressed: _onSave,
              child: const Text('기록 완료하기'),
            ),
          ),
        ]),
      ),

      // 공통 BottomNav
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0, // 일괄 입력(Entry)이 0번
         onTap: (i) {
          if (i == 0) return;
          switch (i) {
            case 1: Navigator.pushReplacementNamed(context, '/savings'); break;
            case 2: Navigator.pushReplacementNamed(context, '/home'); break;
            case 3: Navigator.pushReplacementNamed(context, '/report'); break;
            case 4: Navigator.pushReplacementNamed(context, '/badge'); break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.edit),       label: '일괄 입력'),
          BottomNavigationBarItem(icon: Icon(Icons.savings),    label: '절약 금액'),
          BottomNavigationBarItem(icon: Icon(Icons.home),       label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart),  label: '리포트'),
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events),label: '배지'),
        ],
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}





/*
import 'package:flutter/material.dart';
import '../app_data.dart';

class EntryScreen extends StatefulWidget {
  const EntryScreen({Key? key}) : super(key: key);
  @override
  State<EntryScreen> createState() => _EntryScreenState();
}

class _EntryScreenState extends State<EntryScreen> {
  int _initialWater = AppData.waterCount;
  int _initialSmoke = AppData.smokeCount;
  int _extraWater = 0;
  int _extraSmoke = 0;
  final _waterController = TextEditingController();
  final _smokeController = TextEditingController();

  @override
  void dispose() {
    _waterController.dispose();
    _smokeController.dispose();
    super.dispose();
  }

  Future<void> _showAddDialog({
    required String title,
    required TextEditingController ctrl,
    required ValueSetter<int> onConfirm,
  }) {
    ctrl.clear();
    return showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('$title 추가 입력'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: '숫자를 입력하세요'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
          TextButton(
            onPressed: () {
              final v = int.tryParse(ctrl.text) ?? 0;
              onConfirm(v);
              Navigator.pop(context);
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _onSave() {
    AppData.waterCount = _initialWater + _extraWater;
    AppData.smokeCount = _initialSmoke + _extraSmoke;
    // TODO: 서버 전송 로직 추가 예정
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('오늘 하루 건강 기록 정리하기')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // 흡연 기록
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('흡연 기록', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('총 흡연 개비수: ${_initialSmoke + _extraSmoke}개비'),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => _showAddDialog(
                    title: '흡연량',
                    ctrl: _smokeController,
                    onConfirm: (v) => setState(() => _extraSmoke += v),
                  ),
                  child: const Text('개비 수 추가 입력'),
                ),
              ]),
            ),
          ),

          const SizedBox(height: 16),

          // 음수량 기록
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('음수량 기록', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('총 음수량: ${_initialWater + _extraWater}잔'),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => _showAddDialog(
                    title: '음수량',
                    ctrl: _waterController,
                    onConfirm: (v) => setState(() => _extraWater += v),
                  ),
                  child: const Text('잔 수 추가 입력'),
                ),
              ]),
            ),
          ),

          const SizedBox(height: 16),

          // 음주량 버튼 (맥주/소주)
          const Text('음주량 기록', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: OutlinedButton(onPressed: () {
              // TODO: 맥주 입력 화면으로 이동
            }, child: const Text('맥주'))),
            const SizedBox(width: 8),
            Expanded(child: OutlinedButton(onPressed: () {
              // TODO: 소주 입력 화면으로 이동
            }, child: const Text('소주'))),
          ]),

          const SizedBox(height: 16),

          // 식단 입력
          const Text('식단 입력', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...AppData.meals.keys.map((meal) {
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(meal),
              subtitle: Text(
                AppData.meals[meal]!.isEmpty
                  ? '아직 입력된 식단이 없습니다.'
                  : AppData.meals[meal]!,
              ),
              onTap: () {
                final ctrl = TextEditingController(text: AppData.meals[meal]);
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text('$meal 입력'),
                    content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: '내용을 입력하세요')),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
                      TextButton(onPressed: () {
                        setState(() => AppData.meals[meal] = ctrl.text);
                        Navigator.pop(context);
                      }, child: const Text('저장')),
                    ],
                  ),
                );
              },
            );
          }).toList(),

          const SizedBox(height: 24),
          Center(
            child: ElevatedButton(
              onPressed: _onSave,
              child: const Text('기록 완료하기'),
            ),
          ),
        ]),
      ),

      // 공통 BottomNav
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0, // 일괄 입력(Entry)이 0번
         onTap: (i) {
          if (i == 0) return;
          switch (i) {
            case 1: Navigator.pushReplacementNamed(context, '/savings'); break;
            case 2: Navigator.pushReplacementNamed(context, '/home'); break;
            case 3: Navigator.pushReplacementNamed(context, '/report'); break;
            case 4: Navigator.pushReplacementNamed(context, '/badge'); break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.edit),       label: '일괄 입력'),
          BottomNavigationBarItem(icon: Icon(Icons.savings),    label: '절약 금액'),
          BottomNavigationBarItem(icon: Icon(Icons.home),       label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart),  label: '리포트'),
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events),label: '배지'),
        ],
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}
*/