import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:f5_health/app_data.dart'; // 전역 상태 접근
import 'package:f5_health/services/notification_service.dart'; // 알림 예약/취소

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String nickname = '사용자';
  TimeOfDay? selectedTime;

  @override
  void initState() {
    super.initState();
    selectedTime = AppData.alarmTime;
  }

  final String _termsOfServiceText = '''
[서비스 이용약관]

제1조 (목적)
본 약관은 F5_Health가 제공하는 모바일 건강관리 서비스의 이용조건 및 절차, 사용자와 F5_Health 간의 권리·의무 및 책임사항을 규정함을 목적으로 합니다.

제2조 (정의)
1. "서비스"라 함은 사용자의 건강 관련 습관을 기록하고 이를 분석하여 점수 및 피드백을 제공하는 F5_Health 앱의 모든 기능을 말합니다.
2. "회원"이라 함은 본 약관에 동의하고 서비스를 이용하는 자를 말합니다.

제3조 (약관의 효력 및 변경)
1. 본 약관은 앱에 게시하거나 알림 등을 통해 사용자에게 고지함으로써 효력이 발생합니다.
2. 회사는 관련 법령을 준수하며, 약관 내용을 변경할 수 있고, 변경 시 사전 공지합니다.

제4조 (회원가입 및 탈퇴)
1. 회원가입은 카카오 로그인으로 이루어지며, 회원은 언제든지 탈퇴할 수 있습니다.
2. 회원 탈퇴 시 모든 데이터는 즉시 삭제됩니다. 단, 법령상 의무에 따라 보관이 필요한 데이터는 예외로 합니다.

제5조 (서비스 제공 및 변경)
1. 서비스는 연중무휴 24시간 제공됩니다. 단, 점검 또는 기술적 문제 발생 시 일시적으로 중단될 수 있습니다.
2. F5_Health는 서비스 내용을 개선하거나 변경할 수 있으며, 이 경우 사전 공지합니다.

제6조 (회원의 의무)
1. 회원은 타인의 정보를 도용하거나, 허위 정보를 입력해서는 안 됩니다.
2. 회원은 F5_Health를 통해 제공되는 정보를 상업적 목적으로 무단 이용할 수 없습니다.

제7조 (운영자의 의무)
F5_Health는 개인정보 보호와 서비스 안정성 확보를 위해 지속적으로 보안 및 관리 체계를 개선합니다.

제8조 (저작권 및 게시물)
회원이 작성한 기록, 피드백 등은 회원 본인의 책임 하에 게시되며, 타인의 권리를 침해하는 경우 삭제될 수 있습니다.

제9조 (면책조항)
1. F5_Health는 사용자에게 의료적 진단 또는 처방을 제공하지 않으며, 앱에서 제공하는 정보는 참고용입니다.
2. 시스템 장애, 천재지변, 불가항력 등으로 인해 발생한 서비스 중단에 대해 책임을 지지 않습니다.

제10조 (분쟁 해결)
이 약관은 대한민국 법률에 따라 해석되며, 분쟁 발생 시 관할 법원은 서울중앙지방법원으로 합니다.

부칙
이 약관은 2025년 5월 5일부터 시행됩니다.
''';

  final String _privacyPolicyText = '''
[개인정보처리방침]

F5_Health는 개인정보 보호법 제30조에 따라 정보주체의 개인정보를 보호하고 이와 관련한 고충을 신속하고 원활하게 처리할 수 있도록 하기 위하여 다음과 같이 개인정보처리방침을 수립·공개합니다.

1. 수집하는 개인정보 항목 및 수집 방법
F5_Health는 다음과 같은 개인정보를 수집합니다.

- 필수 항목: 카카오 계정 정보(이메일, 닉네임, 사용자 고유 ID)
- 선택 항목: 프로필 이미지
- 건강 기록 데이터: 음수량, 흡연량, 식사 기록, 걸음 수 등 사용자 입력 데이터
- 수집 방법: 카카오 로그인 API, 사용자 직접 입력, 기기 센서 연동

2. 개인정보의 수집 및 이용 목적
- 사용자 인증 및 식별
- 건강 습관 점수 제공 및 피드백 제공
- 절약 금액 분석 및 건강 아이템 추천
- 알림 및 리마인드 기능 제공
- 통계 기반 리포트 작성

3. 개인정보의 보유 및 이용 기간
- 회원 탈퇴 시 또는 수집 목적 달성 시 지체 없이 삭제
- 법령에 의해 일정 기간 보관이 필요한 경우 예외 처리

4. 개인정보 제3자 제공 및 위탁
- 원칙적으로 제3자에게 제공하지 않으며, 필요한 경우 사전 동의를 받음
- 일부 서비스의 안정적 운영을 위해 외부 전문 업체에 위탁할 수 있음

5. 이용자의 권리
- 개인정보 열람, 정정, 삭제 요청 가능
- 요청 방법: 앱 설정 또는 이메일(f5health@app.com)

6. 개인정보 파기 절차 및 방법
- 전자 파일은 복구 불가능한 방식으로 영구 삭제
- 출력물은 분쇄 또는 소각

7. 개인정보 보호를 위한 기술적·관리적 조치
- SSL 등 암호화 기술 적용
- 접근 제한 및 인증 시스템 운영
- 보안 점검 및 로그 관리

8. 개인정보 보호책임자
- 이름: 김광렬
- 이메일: f5health@app.com

본 방침은 2025년 5월 5일부터 시행됩니다.
''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              '설정 메뉴',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          _buildSettingItem(
            icon: Icons.person,
            title: '내 정보 변경',
            onTap: () => _showEditNicknameDialog(),
          ),
          _buildSettingItem(
            icon: Icons.notifications,
            title: selectedTime != null
                ? '기록 알림 시간: ${selectedTime!.format(context)}'
                : '기록 알림 시간 설정',
            onTap: () => _showTimePickerDialog(),
          ),
          _buildSettingItem(
            icon: Icons.article,
            title: '서비스 이용약관',
            onTap: () => _showTextDialog("서비스 이용약관", _termsOfServiceText),
          ),
          _buildSettingItem(
            icon: Icons.lock,
            title: '개인정보 처리방침',
            onTap: () => _showTextDialog("개인정보 처리방침", _privacyPolicyText),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                // TODO: Kakao 로그아웃 처리
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: const Text('Log out'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  void _showEditNicknameDialog() {
    final controller = TextEditingController(text: nickname);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('닉네임 변경'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: '새 닉네임 입력'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('취소')),
          TextButton(
            onPressed: () {
              setState(() => nickname = controller.text);
              Navigator.pop(context);
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  void _showTimePickerDialog() async {
    final now = TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? AppData.alarmTime ?? now,
    );

    if (picked != null) {
      setState(() => selectedTime = picked);
      AppData.alarmTime = picked;

      final prefs = await SharedPreferences.getInstance();
      final timeStr = timeOfDayToString(picked);
      await prefs.setString('alarm_time', timeStr);

      debugPrint("알림 시간 저장됨: $timeStr");

      await cancelAlarm();
      await scheduleDailyAlarm(picked);
    }
  }

  void _showTextDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(content)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('닫기')),
        ],
      ),
    );
  }

  String timeOfDayToString(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}


/*
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';


class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String nickname = '사용자';
  TimeOfDay? selectedTime;

  final String _termsOfServiceText = '''
[서비스 이용약관]

제1조 (목적)
본 약관은 F5_Health가 제공하는 모바일 건강관리 서비스의 이용조건 및 절차, 사용자와 F5_Health 간의 권리·의무 및 책임사항을 규정함을 목적으로 합니다.

제2조 (정의)
1. "서비스"라 함은 사용자의 건강 관련 습관을 기록하고 이를 분석하여 점수 및 피드백을 제공하는 F5_Health 앱의 모든 기능을 말합니다.
2. "회원"이라 함은 본 약관에 동의하고 서비스를 이용하는 자를 말합니다.

제3조 (약관의 효력 및 변경)
1. 본 약관은 앱에 게시하거나 알림 등을 통해 사용자에게 고지함으로써 효력이 발생합니다.
2. 회사는 관련 법령을 준수하며, 약관 내용을 변경할 수 있고, 변경 시 사전 공지합니다.

제4조 (회원가입 및 탈퇴)
1. 회원가입은 카카오 로그인으로 이루어지며, 회원은 언제든지 탈퇴할 수 있습니다.
2. 회원 탈퇴 시 모든 데이터는 즉시 삭제됩니다. 단, 법령상 의무에 따라 보관이 필요한 데이터는 예외로 합니다.

제5조 (서비스 제공 및 변경)
1. 서비스는 연중무휴 24시간 제공됩니다. 단, 점검 또는 기술적 문제 발생 시 일시적으로 중단될 수 있습니다.
2. F5_Health는 서비스 내용을 개선하거나 변경할 수 있으며, 이 경우 사전 공지합니다.

제6조 (회원의 의무)
1. 회원은 타인의 정보를 도용하거나, 허위 정보를 입력해서는 안 됩니다.
2. 회원은 F5_Health를 통해 제공되는 정보를 상업적 목적으로 무단 이용할 수 없습니다.

제7조 (운영자의 의무)
F5_Health는 개인정보 보호와 서비스 안정성 확보를 위해 지속적으로 보안 및 관리 체계를 개선합니다.

제8조 (저작권 및 게시물)
회원이 작성한 기록, 피드백 등은 회원 본인의 책임 하에 게시되며, 타인의 권리를 침해하는 경우 삭제될 수 있습니다.

제9조 (면책조항)
1. F5_Health는 사용자에게 의료적 진단 또는 처방을 제공하지 않으며, 앱에서 제공하는 정보는 참고용입니다.
2. 시스템 장애, 천재지변, 불가항력 등으로 인해 발생한 서비스 중단에 대해 책임을 지지 않습니다.

제10조 (분쟁 해결)
이 약관은 대한민국 법률에 따라 해석되며, 분쟁 발생 시 관할 법원은 서울중앙지방법원으로 합니다.

부칙
이 약관은 2025년 5월 5일부터 시행됩니다.
''';

  final String _privacyPolicyText = '''
[개인정보처리방침]

F5_Health는 개인정보 보호법 제30조에 따라 정보주체의 개인정보를 보호하고 이와 관련한 고충을 신속하고 원활하게 처리할 수 있도록 하기 위하여 다음과 같이 개인정보처리방침을 수립·공개합니다.

1. 수집하는 개인정보 항목 및 수집 방법
F5_Health는 다음과 같은 개인정보를 수집합니다.

- 필수 항목: 카카오 계정 정보(이메일, 닉네임, 사용자 고유 ID)
- 선택 항목: 프로필 이미지
- 건강 기록 데이터: 음수량, 흡연량, 식사 기록, 걸음 수 등 사용자 입력 데이터
- 수집 방법: 카카오 로그인 API, 사용자 직접 입력, 기기 센서 연동

2. 개인정보의 수집 및 이용 목적
- 사용자 인증 및 식별
- 건강 습관 점수 제공 및 피드백 제공
- 절약 금액 분석 및 건강 아이템 추천
- 알림 및 리마인드 기능 제공
- 통계 기반 리포트 작성

3. 개인정보의 보유 및 이용 기간
- 회원 탈퇴 시 또는 수집 목적 달성 시 지체 없이 삭제
- 법령에 의해 일정 기간 보관이 필요한 경우 예외 처리

4. 개인정보 제3자 제공 및 위탁
- 원칙적으로 제3자에게 제공하지 않으며, 필요한 경우 사전 동의를 받음
- 일부 서비스의 안정적 운영을 위해 외부 전문 업체에 위탁할 수 있음

5. 이용자의 권리
- 개인정보 열람, 정정, 삭제 요청 가능
- 요청 방법: 앱 설정 또는 이메일(f5health@app.com)

6. 개인정보 파기 절차 및 방법
- 전자 파일은 복구 불가능한 방식으로 영구 삭제
- 출력물은 분쇄 또는 소각

7. 개인정보 보호를 위한 기술적·관리적 조치
- SSL 등 암호화 기술 적용
- 접근 제한 및 인증 시스템 운영
- 보안 점검 및 로그 관리

8. 개인정보 보호책임자
- 이름: 김광렬
- 이메일: f5health@app.com

본 방침은 2025년 5월 5일부터 시행됩니다.
''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              '설정 메뉴',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          _buildSettingItem(
            icon: Icons.person,
            title: '내 정보 변경',
            onTap: () => _showEditNicknameDialog(),
          ),
          _buildSettingItem(
            icon: Icons.notifications,
            title: '기록 알림 시간 설정',
            onTap: () => _showTimePickerDialog(),
          ),
          _buildSettingItem(
            icon: Icons.article,
            title: '서비스 이용약관',
            onTap: () => _showTextDialog("서비스 이용약관", _termsOfServiceText),
          ),
          _buildSettingItem(
            icon: Icons.lock,
            title: '개인정보 처리방침',
            onTap: () => _showTextDialog("개인정보 처리방침", _privacyPolicyText),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                // TODO: Kakao 로그아웃 처리
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: const Text('Log out'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  void _showEditNicknameDialog() {
    final controller = TextEditingController(text: nickname);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('닉네임 변경'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: '새 닉네임 입력'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('취소')),
          TextButton(
            onPressed: () {
              setState(() => nickname = controller.text);
              Navigator.pop(context);
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  void _showTimePickerDialog() async {
    final now = TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? now,
    );

    if (picked != null) {
      setState(() => selectedTime = picked);

      final prefs = await SharedPreferences.getInstance();
      final timeStr = timeOfDayToString(picked);
      await prefs.setString('alarm_time', timeStr);

      debugPrint("알림 시간 저장됨: $timeStr");
    }
  }

  void _showTextDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(content)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('닫기')),
        ],
      ),
    );
  }

  String timeOfDayToString(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
*/