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
  int? _selAlarmHour; // 추가
  int? _selAlarmMinute; // 추가

  final Map<String, dynamic> _answers = {};
  Map<String, dynamic>? loginPayload;

  // 백엔드가 기대하는 키 이름으로 수정
  final List<String> _questionKeys = [
    'gender',
    'birthDate',
    'height',
    'weight',
    'bloodType',
    'daySmokeCigarettes',
    'weekAlcoholDrinks',
    'weekExerciseFrequency',
    'alarmTime',
  ];

  // 페이지별 임시 선택값
  String? _selGender;
  String? _selYear;
  String? _selMonth;
  String? _selDay;
  int? _selHeight;
  int? _selWeight;
  String? _selBloodType;
  int? _selSmoke;
  int? _selAlcohol;
  int? _selExercise;

  List<Widget> get _pages => [
        _buildGenderQuestion(),
        _buildBirthDateQuestion(),
        _buildHeightQuestion(),
        _buildWeightQuestion(),
        _buildBloodTypeQuestion(),
        _buildSmokingQuestion(),
        _buildAlcoholQuestion(),
        _buildExerciseQuestion(),
        _buildAlarmTimeQuestion(),
      ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 로그인 페이로드는 라우팅 시 전달받은 arguments 에 담겨 있다고 가정
    loginPayload =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
  }

  void _goNext() {
    final key = _questionKeys[_currentPage];
    if (_answers[key] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('값을 선택하고 확인을 눌러주세요.')),
      );
      return;
    }
    if (_currentPage < _pages.length - 1) {
      setState(() => _currentPage++);
    } else {
      _submitSurvey();
    }
  }

  Future<void> _submitSurvey() async {
    final signUpRequest = {
      'loginRequest': loginPayload,
      'memberCheckUp': _answers,
    };

    debugPrint('📤 payload: ${jsonEncode(signUpRequest)}');

    final res = await http.post(
      Uri.parse('http://localhost:8080/signup/oauth2/kakao'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(signUpRequest),
    );

    debugPrint('📡 status: ${res.statusCode}');
    debugPrint('📦 body: ${res.body}');

    if (res.statusCode == 201) {
      final decoded = jsonDecode(res.body);
      final serverToken =
          decoded['accessToken'] ?? decoded['tokenResponse']?['accessToken'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      if (serverToken != null) {
        await prefs.setString('accessToken', serverToken);
      }
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('회원가입 실패'),
          content: Text('에러 ${res.statusCode}\n${res.body}'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('확인')),
          ],
        ),
      );
    }
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

  Widget _buildGenderQuestion() {
    return _buildPage(
      title: '성별을 선택하세요',
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ChoiceChip(
                label: const Text('남성'),
                selected: _selGender == Gender.MALE.name,
                onSelected: (_) {
                  setState(() {
                    _selGender = Gender.MALE.name;
                    _answers['gender'] = _selGender;
                  });
                },
                backgroundColor: Colors.grey,
                selectedColor: Colors.deepPurple,
                labelStyle: TextStyle(
                  color: _selGender == Gender.MALE.name
                      ? Colors.white
                      : Colors.black,
                ),
              ),
              const SizedBox(width: 16),
              ChoiceChip(
                label: const Text('여성'),
                selected: _selGender == Gender.FEMALE.name,
                onSelected: (_) {
                  setState(() {
                    _selGender = Gender.FEMALE.name;
                    _answers['gender'] = _selGender;
                  });
                },
                backgroundColor: Colors.grey,
                selectedColor: Colors.deepPurple,
                labelStyle: TextStyle(
                  color: _selGender == Gender.FEMALE.name
                      ? Colors.white
                      : Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _selGender == null ? null : _goNext,
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  Widget _buildBirthDateQuestion() {
    // 연도, 월, 일 리스트
    final years = List.generate(40, (i) => (1980 + i).toString());
    final months = List.generate(12, (i) => (i + 1).toString().padLeft(2, '0'));
    final days = List.generate(31, (i) => (i + 1).toString().padLeft(2, '0'));

    return _buildPage(
      title: '생년월일을 선택하세요',
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DropdownButton<String>(
                hint: const Text('년'),
                value: _selYear,
                onChanged: (v) => setState(() => _selYear = v),
                items: years
                    .map((y) => DropdownMenuItem(value: y, child: Text('$y년')))
                    .toList(),
              ),
              const SizedBox(width: 8),
              DropdownButton<String>(
                hint: const Text('월'),
                value: _selMonth,
                onChanged: (v) => setState(() => _selMonth = v),
                items: months
                    .map((m) => DropdownMenuItem(value: m, child: Text('$m월')))
                    .toList(),
              ),
              const SizedBox(width: 8),
              DropdownButton<String>(
                hint: const Text('일'),
                value: _selDay,
                onChanged: (v) => setState(() => _selDay = v),
                items: days
                    .map((d) => DropdownMenuItem(value: d, child: Text('$d일')))
                    .toList(),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              if (_selYear == null || _selMonth == null || _selDay == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('년·월·일을 모두 선택해주세요.')),
                );
                return;
              }
              final dateStr = '${_selYear!}-${_selMonth!}-${_selDay!}';
              _answers['birthDate'] = dateStr;
              _goNext();
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeightQuestion() {
    final options = List.generate(101, (i) => 120 + i);
    return _buildPage(
      title: '키를 선택하세요 (cm)',
      child: Column(
        children: [
          DropdownButton<int>(
            hint: const Text('예: 170'),
            value: _selHeight,
            onChanged: (v) => setState(() => _selHeight = v),
            items: options
                .map((h) => DropdownMenuItem(value: h, child: Text('$h cm')))
                .toList(),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              if (_selHeight == null) return;
              _answers['height'] = _selHeight;
              _goNext();
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightQuestion() {
    final options = List.generate(81, (i) => 40 + i);
    return _buildPage(
      title: '몸무게를 선택하세요 (kg)',
      child: Column(
        children: [
          DropdownButton<int>(
            hint: const Text('예: 65'),
            value: _selWeight,
            onChanged: (v) => setState(() => _selWeight = v),
            items: options
                .map((w) => DropdownMenuItem(value: w, child: Text('$w kg')))
                .toList(),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              if (_selWeight == null) return;
              _answers['weight'] = _selWeight;
              _goNext();
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  Widget _buildBloodTypeQuestion() {
    const types = ['A', 'B', 'AB', 'O'];
    return _buildPage(
      title: '혈액형을 선택하세요',
      child: Column(
        children: [
          DropdownButton<String>(
            hint: const Text('혈액형'),
            value: _selBloodType,
            onChanged: (v) => setState(() => _selBloodType = v),
            items: types
                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                .toList(),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              if (_selBloodType == null) return;
              _answers['bloodType'] = _selBloodType;
              _goNext();
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  Widget _buildSmokingQuestion() {
    return _buildPage(
      title: '하루 평균 흡연량 (개비)',
      child: Column(
        children: [
          DropdownButton<int>(
            hint: const Text('0~100'),
            value: _selSmoke,
            onChanged: (v) => setState(() => _selSmoke = v),
            items: List.generate(
                101, (i) => DropdownMenuItem(value: i, child: Text('$i'))),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              if (_selSmoke == null) return;
              _answers['daySmokeCigarettes'] = _selSmoke;
              _goNext();
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  Widget _buildAlcoholQuestion() {
    return _buildPage(
      title: '주간 평균 음주 횟수 (회)',
      child: Column(
        children: [
          DropdownButton<int>(
            hint: const Text('0~7'),
            value: _selAlcohol,
            onChanged: (v) => setState(() => _selAlcohol = v),
            items: List.generate(
                8, (i) => DropdownMenuItem(value: i, child: Text('$i'))),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              if (_selAlcohol == null) return;
              _answers['weekAlcoholDrinks'] = _selAlcohol;
              _goNext();
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseQuestion() {
    return _buildPage(
      title: '주간 운동 빈도 (회)',
      child: Column(
        children: [
          DropdownButton<int>(
            hint: const Text('0~7'),
            value: _selExercise,
            onChanged: (v) => setState(() => _selExercise = v),
            items: List.generate(
                8, (i) => DropdownMenuItem(value: i, child: Text('$i'))),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              if (_selExercise == null) return;
              _answers['weekExerciseFrequency'] = _selExercise;
              _goNext();
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  /// 9. 알림 받을 시간 선택 페이지
  Widget _buildAlarmTimeQuestion() {
    final hours = List.generate(24, (i) => i);
    final minutes = List.generate(60, (i) => i);

    return _buildPage(
      title: '알림 받을 시간을 선택하세요',
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DropdownButton<int>(
                hint: const Text('시'),
                value: _selAlarmHour,
                items: hours
                    .map((h) => DropdownMenuItem(value: h, child: Text('$h 시')))
                    .toList(),
                onChanged: (v) => setState(() => _selAlarmHour = v),
              ),
              const SizedBox(width: 16),
              DropdownButton<int>(
                hint: const Text('분'),
                value: _selAlarmMinute,
                items: minutes
                    .map((m) => DropdownMenuItem(value: m, child: Text('$m 분')))
                    .toList(),
                onChanged: (v) => setState(() => _selAlarmMinute = v),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              if (_selAlarmHour == null || _selAlarmMinute == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('시와 분을 모두 선택해주세요.')),
                );
                return;
              }
              // 1) SharedPreferences에 저장
              final prefs = await SharedPreferences.getInstance();
              final timeStr = '${_selAlarmHour!.toString().padLeft(2, '0')}:'
                  '${_selAlarmMinute!.toString().padLeft(2, '0')}';
              await prefs.setString('alarm_time', timeStr);

              // 2) _answers에도 기록(필요없으면 백엔드 전송 제외 가능)
              _answers['alarmTime'] = timeStr;

              // 3) 다음 페이지 또는 _submitSurvey 호출
              _goNext();
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('설문조사')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _pages[_currentPage],
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
      final decoded = jsonDecode(res.body);
      final serverAccessToken = decoded['tokenResponse']['accessToken'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString(
          'accessToken', serverAccessToken); // ✅ accessToken 저장

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