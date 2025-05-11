import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

enum Gender { MALE, FEMALE }

class SurveyScreen extends StatefulWidget {
  const SurveyScreen({super.key});

  @override
  State<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> {
  int _currentPage = 0;
  final Map<String, dynamic> _answers = {};
  Map<String, dynamic>? loginPayload;

  final List<Widget> _questions = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    loginPayload =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    if (_questions.isEmpty) {
      _questions.addAll([
        _buildGenderQuestion(),
        _buildBirthDateQuestion(),
        _buildHeightQuestion(),
        _buildWeightQuestion(),
        _buildBloodTypeQuestion(),
        _buildSmokingQuestion(),
        _buildAlcoholQuestion(),
        _buildExerciseQuestion(),
      ]);
    }
  }

  void _nextPage() {
    if (_currentPage < _questions.length - 1) {
      setState(() => _currentPage++);
    } else {
      debugPrint('📤 설문 전송 시도!');
      _submitSurvey();
    }
  }

  Future<void> _submitSurvey() async {
    final signupPayload = {
      'loginRequest': loginPayload,
      'memberCheckUp': _answers,
    };

    debugPrint('📝 payload: ${jsonEncode(signupPayload)}');

    final res = await http.post(
      Uri.parse('http://localhost:8080/signup/oauth2/kakao'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(signupPayload),
    );

    debugPrint('📡 signup status: ${res.statusCode}');
    debugPrint('📦 signup body: ${res.body}');

    if (res.statusCode == 201) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('회원가입 실패'),
          content: Text('에러 상태: ${res.statusCode}\n${res.body}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('확인'),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildGenderQuestion() {
    Gender? selectedGender;

    return _buildPage(
      title: '성별을 선택하세요',
      child: Column(
        children: [
          DropdownButton<Gender>(
            value: selectedGender,
            hint: const Text('성별'),
            onChanged: (val) => setState(() => selectedGender = val),
            items: Gender.values
                .map((g) => DropdownMenuItem(value: g, child: Text(g.name)))
                .toList(),
          ),
          ElevatedButton(
            onPressed: () {
              if (selectedGender != null) {
                _answers['gender'] = selectedGender!.name;
                _nextPage();
              }
            },
            child: const Text('다음'),
          ),
        ],
      ),
    );
  }

  Widget _buildBirthDateQuestion() {
    int? selectedYear;
    int? selectedMonth;
    int? selectedDay;

    return _buildPage(
      title: '생년월일을 선택하세요',
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DropdownButton<int>(
                value: selectedYear,
                hint: const Text('년도'),
                onChanged: (val) => setState(() => selectedYear = val),
                items: List.generate(40, (i) {
                  final year = 1980 + i;
                  return DropdownMenuItem(value: year, child: Text('$year년'));
                }),
              ),
              DropdownButton<int>(
                value: selectedMonth,
                hint: const Text('월'),
                onChanged: (val) => setState(() => selectedMonth = val),
                items: List.generate(
                    12,
                    (i) => DropdownMenuItem(
                        value: i + 1, child: Text('${i + 1}월'))),
              ),
              DropdownButton<int>(
                value: selectedDay,
                hint: const Text('일'),
                onChanged: (val) => setState(() => selectedDay = val),
                items: List.generate(
                    31,
                    (i) => DropdownMenuItem(
                        value: i + 1, child: Text('${i + 1}일'))),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () {
              if (selectedYear != null &&
                  selectedMonth != null &&
                  selectedDay != null) {
                final mm = selectedMonth!.toString().padLeft(2, '0');
                final dd = selectedDay!.toString().padLeft(2, '0');
                _answers['birthDate'] = '${selectedYear!}-$mm-$dd';
                _nextPage();
              }
            },
            child: const Text('다음'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeightQuestion() {
    int? selectedHeight;

    return _buildPage(
      title: '키를 선택하세요 (cm)',
      child: Column(
        children: [
          DropdownButton<int>(
            value: selectedHeight,
            hint: const Text('예: 170'),
            onChanged: (val) => setState(() => selectedHeight = val),
            items: List.generate(
                101,
                (i) => DropdownMenuItem(
                    value: 120 + i, child: Text('${120 + i} cm'))),
          ),
          ElevatedButton(
            onPressed: () {
              if (selectedHeight != null) {
                _answers['height'] = selectedHeight;
                _nextPage();
              }
            },
            child: const Text('다음'),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightQuestion() {
    int? selectedWeight;

    return _buildPage(
      title: '몸무게를 선택하세요 (kg)',
      child: Column(
        children: [
          DropdownButton<int>(
            value: selectedWeight,
            hint: const Text('예: 65'),
            onChanged: (val) => setState(() => selectedWeight = val),
            items: List.generate(
                81,
                (i) => DropdownMenuItem(
                    value: 40 + i, child: Text('${40 + i} kg'))),
          ),
          ElevatedButton(
            onPressed: () {
              if (selectedWeight != null) {
                _answers['weight'] = selectedWeight;
                _nextPage();
              }
            },
            child: const Text('다음'),
          ),
        ],
      ),
    );
  }

  Widget _buildBloodTypeQuestion() {
    String? selectedType;

    return _buildPage(
      title: '혈액형을 선택하세요',
      child: Column(
        children: [
          DropdownButton<String>(
            value: selectedType,
            hint: const Text('혈액형'),
            onChanged: (val) => setState(() => selectedType = val),
            items: ['A', 'B', 'AB', 'O']
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
          ),
          ElevatedButton(
            onPressed: () {
              if (selectedType != null) {
                _answers['bloodType'] = selectedType;
                _nextPage();
              }
            },
            child: const Text('다음'),
          ),
        ],
      ),
    );
  }

  Widget _buildSmokingQuestion() {
    int? selected;

    return _buildPage(
      title: '하루 평균 흡연량 (개비)',
      child: Column(
        children: [
          DropdownButton<int>(
            value: selected,
            hint: const Text('0 ~ 100개비'),
            onChanged: (val) => setState(() => selected = val),
            items: List.generate(
                101, (i) => DropdownMenuItem(value: i, child: Text('$i 개비'))),
          ),
          ElevatedButton(
            onPressed: () {
              if (selected != null) {
                _answers['daySmokingAvg'] = selected;
                _nextPage();
              }
            },
            child: const Text('다음'),
          ),
        ],
      ),
    );
  }

  Widget _buildAlcoholQuestion() {
    int? selected;

    return _buildPage(
      title: '주간 평균 음주 횟수 (회)',
      child: Column(
        children: [
          DropdownButton<int>(
            value: selected,
            hint: const Text('0 ~ 7회'),
            onChanged: (val) => setState(() => selected = val),
            items: List.generate(
                8, (i) => DropdownMenuItem(value: i, child: Text('$i 회'))),
          ),
          ElevatedButton(
            onPressed: () {
              if (selected != null) {
                _answers['weekAlcoholAvg'] = selected;
                _nextPage();
              }
            },
            child: const Text('다음'),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseQuestion() {
    int? selected;

    return _buildPage(
      title: '주간 운동 빈도 (회)',
      child: Column(
        children: [
          DropdownButton<int>(
            value: selected,
            hint: const Text('0 ~ 7회'),
            onChanged: (val) => setState(() => selected = val),
            items: List.generate(
                8, (i) => DropdownMenuItem(value: i, child: Text('$i 회'))),
          ),
          ElevatedButton(
            onPressed: () {
              if (selected != null) {
                _answers['weekExerciseFreq'] = selected;
                _nextPage();
              }
            },
            child: const Text('제출'),
          ),
        ],
      ),
    );
  }

  Widget _buildPage({required String title, required Widget child}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('설문조사')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _questions[_currentPage],
      ),
    );
  }
}

/*
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

enum Gender { MALE, FEMALE }

class SurveyScreen extends StatefulWidget {
  const SurveyScreen({super.key});

  @override
  State<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> {
  int _currentPage = 0;
  final Map<String, dynamic> _answers = {};
  Map<String, dynamic>? loginPayload;

  final List<String> _questionKeys = [
    'gender',
    'birthDate',
    'height',
    'weight',
    'bloodType',
    'daySmokingAvg',
    'weekAlcoholAvg',
    'weekExerciseFreq',
  ];

  final List<Widget> _questions = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    loginPayload =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    if (_questions.isEmpty) {
      // ✅ 중복 방지 조건 추가
      _questions.addAll([
        _buildGenderQuestion(),
        _buildBirthDateQuestion(),
        _buildHeightQuestion(),
        _buildWeightQuestion(),
        _buildBloodTypeQuestion(),
        _buildSmokingQuestion(),
        _buildAlcoholQuestion(),
        _buildExerciseQuestion(),
      ]);
    }
  }

  void _nextPage() {
    final currentKey = _questionKeys[_currentPage];
    if (_answers[currentKey] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('값을 선택해주세요!')),
      );
      return;
    }

    if (_currentPage < _questions.length - 1) {
      setState(() => _currentPage++);
    } else {
      debugPrint('📤 설문 전송 시도!');
      _submitSurvey();
    }
  }

  Future<void> _submitSurvey() async {
    final signupPayload = {
      'loginRequest': loginPayload,
      'memberCheckUp': _answers,
    };

    debugPrint('📝 payload: ${jsonEncode(signupPayload)}');

    final res = await http.post(
      Uri.parse('http://localhost:8080/signup/oauth2/kakao'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(signupPayload),
    );

    debugPrint('📡 signup status: ${res.statusCode}');
    debugPrint('📦 signup body: ${res.body}');

    if (res.statusCode == 201) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('회원가입 실패'),
          content: Text('에러 상태: ${res.statusCode}\n${res.body}'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('확인')),
          ],
        ),
      );
    }
  }

  Widget _buildGenderQuestion() {
    return _buildPage(
      title: '성별을 선택하세요',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: () {
              _answers['gender'] = Gender.MALE.name;
              _nextPage();
            },
            child: const Text('남성'),
          ),
          const SizedBox(width: 20),
          ElevatedButton(
            onPressed: () {
              _answers['gender'] = Gender.FEMALE.name;
              _nextPage();
            },
            child: const Text('여성'),
          ),
        ],
      ),
    );
  }

  Widget _buildBirthDateQuestion() {
    return _buildPage(
      title: '생년월일을 선택하세요',
      child: DropdownButton<String>(
        value: _answers['birthDate'] as String?,
        hint: const Text('예: 2000-04-18'),
        onChanged: (val) {
          setState(() => _answers['birthDate'] = val);
          _nextPage();
        },
        items: List.generate(40, (i) {
          final year = 1980 + i;
          return DropdownMenuItem(
            value: '$year-01-01',
            child: Text('$year-01-01'),
          );
        }),
      ),
    );
  }

  Widget _buildHeightQuestion() {
    return _buildPage(
      title: '키를 선택하세요 (cm)',
      child: DropdownButton<int>(
        value: _answers['height'] as int?,
        hint: const Text('예: 170'),
        onChanged: (val) {
          setState(() => _answers['height'] = val);
          _nextPage();
        },
        items: List.generate(
            101,
            (i) =>
                DropdownMenuItem(value: 120 + i, child: Text('${120 + i} cm'))),
      ),
    );
  }

  Widget _buildWeightQuestion() {
    return _buildPage(
      title: '몸무게를 선택하세요 (kg)',
      child: DropdownButton<int>(
        value: _answers['weight'] as int?,
        hint: const Text('예: 65'),
        onChanged: (val) {
          setState(() => _answers['weight'] = val);
          _nextPage();
        },
        items: List.generate(
            81,
            (i) =>
                DropdownMenuItem(value: 40 + i, child: Text('${40 + i} kg'))),
      ),
    );
  }

  Widget _buildBloodTypeQuestion() {
    return _buildPage(
      title: '혈액형을 선택하세요',
      child: DropdownButton<String>(
        value: _answers['bloodType'] as String?,
        hint: const Text('혈액형'),
        onChanged: (val) {
          setState(() => _answers['bloodType'] = val);
          _nextPage();
        },
        items: ['A', 'B', 'AB', 'O']
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
      ),
    );
  }

  Widget _buildSmokingQuestion() {
    return _buildPage(
      title: '하루 평균 흡연량 (개비)',
      child: DropdownButton<int>(
        value: _answers['daySmokingAvg'] as int?,
        hint: const Text('0 ~ 100개비'),
        onChanged: (val) {
          setState(() => _answers['daySmokingAvg'] = val);
          _nextPage();
        },
        items: List.generate(
            101, (i) => DropdownMenuItem(value: i, child: Text('$i 개비'))),
      ),
    );
  }

  Widget _buildAlcoholQuestion() {
    return _buildPage(
      title: '주간 평균 음주 횟수 (회)',
      child: DropdownButton<int>(
        value: _answers['weekAlcoholAvg'] as int?,
        hint: const Text('0 ~ 7회'),
        onChanged: (val) {
          setState(() => _answers['weekAlcoholAvg'] = val);
          _nextPage();
        },
        items: List.generate(
            8, (i) => DropdownMenuItem(value: i, child: Text('$i 회'))),
      ),
    );
  }

  Widget _buildExerciseQuestion() {
    return _buildPage(
      title: '주간 운동 빈도 (회)',
      child: DropdownButton<int>(
        value: _answers['weekExerciseFreq'] as int?,
        hint: const Text('0 ~ 7회'),
        onChanged: (val) {
          setState(() => _answers['weekExerciseFreq'] = val);
          _nextPage();
        },
        items: List.generate(
            8, (i) => DropdownMenuItem(value: i, child: Text('$i 회'))),
      ),
    );
  }

  Widget _buildPage({required String title, required Widget child}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('설문조사')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _questions[_currentPage],
      ),
    );
  }
}
*/
