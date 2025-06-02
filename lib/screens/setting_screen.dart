import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:f5_health/services/notification_service.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:http/http.dart' as http;

import 'package:hive_flutter/hive_flutter.dart';
import '../models/daily_record.dart';
import '../models/eaten_food.dart';
import '../config.dart';
import 'package:intl/intl.dart';


class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // --- 프로필 데이터 ---
  String nickname = '사용자';
  int height = 170; // 정수(130~220)
  int weight = 65; // 정수(30~280)
  int daySmokeCigarettes = 0; // 정수(0~40)
  double _sojuBottles = 0.0; // SharedPreferences에서 가져올 소주 병 수
  double _beerBottles = 0.0; // SharedPreferences에서 가져올 맥주 병 수
  int weekExerciseFrequency = 0; // 정수(0~7)

  // --- 기록 알림 시간 ---
  TimeOfDay? selectedTime;

  // 약관·방침 텍스트
  final String _termsOfServiceText = '''
[서비스 이용약관]

**제1장 총칙**

**제1조(목적)**  
본 약관은 F5_Health(이하 “회사”)가 운영하는 모바일 건강관리 애플리케이션 및 웹서비스(이하 “서비스”)의 이용조건 및 절차, 서비스 제공자와 이용자 간의 권리·의무·책임사항과 기타 필요한 사항을 규정함을 목적으로 합니다.

**제2조(용어의 정의)**  
1. “회사”라 함은 F5_Health 서비스를 이용자에게 제공하는 사업자를 말합니다.  
2. “이용자”라 함은 본 약관에 따라 회사가 제공하는 서비스를 받는 회원 및 비회원을 말합니다.  
3. “회원”이라 함은 회사와 서비스 이용계약을 체결하고 일정한 계정(ID, 비밀번호)을 부여받아 서비스를 지속적으로 이용할 수 있는 자를 말합니다.  
4. “비회원”이라 함은 회원 가입 절차를 거치지 않고 회사가 제공하는 서비스를 이용하는 자를 말합니다.  
5. “계정(ID)”이라 함은 회원 식별 및 서비스 이용을 위하여 회원이 설정하고 회사가 승인한 문자 및 숫자의 조합을 의미합니다.  
6. “비밀번호”라 함은 회원이 부여받은 계정이 자신이 등록한 회원임을 확인하고, 모든 개인정보를 보호하기 위하여 회원이 설정한 문자 및 숫자 등의 조합을 의미합니다.  
7. “게시물”이라 함은 서비스 내에 회원이 게시 또는 등록한 텍스트, 이미지, 동영상, 파일, 링크 등의 정보를 말합니다.  

**제2장 약관의 게시 및 개정**

**제3조(약관의 게시 및 개정)**  
1. 회사는 본 약관의 내용을 회원이 쉽게 알 수 있도록 서비스 초기 화면 또는 로그인 화면에 게시합니다.  
2. 회사는 「전자문서 및 전자거래기본법」, 「약관의 규제에 관한 법률」, 「전자서명법」, 「정보통신망 이용촉진 및 정보보호 등에 관한 법률(이하 “정보통신망법”)」 등 관련 법을 위배하지 않는 범위에서 본 약관을 개정할 수 있습니다.  
3. 회사가 약관을 개정할 경우에는 그 개정 약관의 적용일자 및 개정 사유를 명시하여 현행 약관과 함께 서비스 내 공지사항에 게시합니다.  
4. 회사가 개정 약관을 공지·게시하거나 회원에게 이메일 또는 서비스 내 알림을 통해 통지한 날로부터 **7일 전**부터 적용일 전일까지 회원이 거부 의사를 표시하지 아니하면 개정 약관에 동의한 것으로 봅니다. 회원이 개정 약관에 동의하지 않을 경우, 회사는 이용계약을 해지하거나 회원으로서의 자격을 제한할 수 있습니다.  

**제4조(약관 외 준칙)**  
본 약관에 명시되지 않은 사항은 정보통신망법, 전자상거래 등에서의 소비자 보호에 관한 법률, 콘텐츠산업진흥법, 전자금융거래법, GDPR(유럽 개인정보 보호법) 혹은 해당 서비스와 관련한 개별 법령 및 회사가 정한 정책(운영정책, 개인정보처리방침 등)에 따릅니다.

**제3장 서비스 이용 계약**

**제5조(이용 계약의 성립)**  
1. 이용 계약은 이용자가 본 약관의 내용에 동의하고, 회원가입을 신청한 후 회사가 이를 승낙함으로써 성립합니다.  
2. 회원가입은 회원이 회원가입 양식에 ID, 비밀번호, 이메일 주소, 휴대전화번호 등 필수정보를 기입하여 신청하고, 회사가 이를 확인한 뒤 승낙함으로써 완료됩니다.  
3. 회사는 다음 각 호의 어느 하나에 해당하는 경우 가입 승낙을 하지 않을 수 있습니다.  
   1. 가입신청자가 이 약관에 의하여 이전에 회원 자격을 상실한 적이 있는 경우(단, 회사가 일정 기간이 경과한 후 재가입을 승낙하는 등의 지침을 정한 경우에는 해당 지침에 따름)  
   2. 실명이 아니거나 타인의 명의를 이용하여 신청한 경우  
   3. 허위의 정보를 기재하거나, 회사가 제시하는 내용을 기재하지 않은 경우  
   4. 만 14세 미만 아동이 법정대리인의 동의 없이 신청한 경우  
   5. 기타 회사가 정한 이용 신청 요건을 충족하지 못한 경우  

**제6조(이용 계약의 종료)**  
1. 회원이 이용계약을 해지하고자 하는 때에는 회원 본인이 서비스 내 ‘회원 탈퇴’ 메뉴를 선택하여 탈퇴 절차를 완료함으로써 해지할 수 있습니다.  
2. 회사는 회원이 다음 각 호의 어느 하나에 해당하는 사유가 발생한 경우, 이용계약을 해지하거나 또는 회원 자격을 일시 정지할 수 있습니다.  
   1. 가입 신청 시에 허위 내용을 등록한 경우  
   2. 타인의 서비스 이용을 방해하거나 정보를 도용하는 등 부정사용한 경우  
   3. 서비스 운영을 고의로 방해하는 등 서비스의 정상적 운영을 방해한 경우  
   4. 범죄행위와 결부된다고 객관적으로 인정되는 경우  
   5. 부정한 목적 또는 영리를 추구하기 위해 본 서비스를 이용하는 경우  
   6. 정보통신망법 또는 저작권법 등 관련 법령을 위반한 경우  
   7. 회사로부터 서비스 이용에 관련하여 2회 이상 경고를 받은 경우  
   8. 기타 회원이 이 약관 또는 법령에서 금지하는 행위를 한 경우  

**제7조(이용 제한 및 회원 자격 상실)**  
1. 회사는 회원이 아래 각 호의 어느 하나에 해당하는 행위를 하였을 경우 사전 통지 없이 회원 자격을 정지 또는 박탈하고 서비스 이용을 제한할 수 있습니다.  
   1. 타인의 명예를 훼손하거나 불이익을 주는 행위  
   2. 공공질서 및 미풍양속에 위반되는 행위  
   3. 타인의 지적 재산권을 침해하는 행위  
   4. 불법·음란·사행성 정보를 유포하거나 게시하는 행위  
   5. 기타 범죄적 행위와 결부된다고 인정되는 행위  
2. 회사는 전항에 따라 회원 자격을 상실시키는 경우, 해당 회원 자격을 박탈하는 즉시 서비스를 이용할 수 없도록 조치하며, 회원 자격 상실 시 회원에게 통지합니다. 또한, 해당 회원이 작성, 등록한 게시물 등은 삭제될 수 있습니다.

**제4장 서비스 이용**

**제8조(서비스의 제공 및 변경)**  
1. 회사는 다음과 같은 서비스를 제공합니다.  
   1. 건강 정보(심박수, 수면, 운동량 등) 수집 및 통합·분석 서비스  
   2. 일일/주간/월간 건강 데이터 시각화 리포트  
   3. 식단 관리, 섭취 칼로리 및 영양소 계산 서비스  
   4. 이용자 맞춤형 건강 권고사항 및 AI 피드백  
   5. 기타 회사가 정하는 서비스  
2. 회사는 서비스 제공일자를 별도로 정하는 경우 서비스 초기 화면에 게시하거나 개별 통지합니다.  
3. 회사는 서비스를 일정 범위로 분할하여 각 범위별로 이용 가능 시간을 별도로 지정할 수 있으며, 이 경우 그 내용을 서비스 초기 화면에 공지합니다.  
4. 회사는 컴퓨터 등 정보통신설비의 보수·교체·정기점검·고장·통신의 두절 등의 사유가 발생한 경우 일시적으로 서비스의 제공을 중단할 수 있으며, 이를 사전에 공지합니다. 다만, 긴급한 시스템 점검, 서비스 개선, 기술적 문제 해결 등의 사유로 사전 공지가 어려운 경우 사후에 공지할 수 있습니다.

**제9조(서비스 이용 요금)**  
1. 회사가 제공하는 대부분의 서비스는 무료로 이용할 수 있습니다. 다만, 일부 유료 콘텐츠 또는 유료 구독형 서비스(프리미엄 멤버십 등)는 별도로 요금을 부과할 수 있으며, 해당 경우 이용 요금, 결제 방법, 환불 정책 등을 서비스 화면에 명시합니다.  
2. 유료 서비스를 이용하는 경우, 해당 결제와 관련한 제반 절차 및 비용은 회원이 부담합니다. 환불 정책은 서비스 화면에 별도 명시된 바에 따릅니다.

**제10조(정보의 제공 및 광고의 게재)**  
1. 회사는 서비스 운영에 필요한 각종 정보(공지사항, 이용 안내 등)를 서비스 초기 화면 또는 회원이 등록한 이메일, 문자메시지, 앱 푸시알림 등을 통해 회원에게 제공할 수 있습니다.  
2. 회사는 서비스 화면, 이메일, 문자메시지 등에 광고를 게재할 수 있습니다. 다만, 회원이 원하지 않을 경우 언제든지 광고 수신 거부를 신청할 수 있으며, 회사는 관련 법령에 따라 광고를 중단 또는 제한 조치합니다.

**제11조(회원의 의무)**  
1. 회원은 다음 각 호의 행위를 하여서는 안 됩니다.  
   1. 가입 신청 또는 정보 변경 시 허위 내용의 등록  
   2. 타인의 정보 도용  
   3. 회사가 게시한 정보의 변경  
   4. 회사가 정한 정보 이외의 정보(컴퓨터 프로그램 등)의 송신 또는 게시  
   5. 회사 및 기타 제3자의 저작권 등 지적 재산권에 대한 침해  
   6. 회사 및 기타 제3자의 명예를 손상하거나 업무를 방해하는 행위  
   7. 외설 또는 폭력적인 메시지, 화상, 음성 기타 공서양속에 반하는 정보를 서비스에 공개 또는 게시하는 행위  
   8. 정보통신망법, 저작권법 등 관련 법령이나 회사가 정한 정책을 위반하는 행위  
   9. 기타 불법적이거나 부당한 행위  
2. 회원이 관련 법령 또는 본 약관을 위반하여 회사 또는 제3자에게 손해를 끼치는 경우, 회원은 모든 책임을 부담하며, 회사는 그 손해를 배상받을 권리를 가집니다.

**제12조(게시물의 관리 및 권리 귀속)**  
1. 서비스에 게시된 게시물(텍스트, 이미지, 동영상 등)의 저작권은 회사 또는 게시자에게 귀속됩니다. 이용자는 서비스 이용 시 저작권법에 따라 정당한 범위 내에서 이를 이용할 수 있습니다.  
2. 게시자가 게시한 게시물(이하 “회원 게시물”)이 정보통신망법, 저작권법 등 관련 법령 또는 본 약관에 위반되는 내용을 포함하는 경우, 해당 게시물의 권리자는 회사에 삭제 또는 접근 차단을 요청할 수 있으며, 회사는 관련 법령에 따라 이를 즉시 처리합니다.

**제13조(게시물의 이용 및 책임)**  
1. 회사는 서비스 운영과 관련해 게시물에 대해 모니터링을 수행할 수 있으며, 아래 사유가 발생할 경우 해당 게시물을 사전 통지 없이 삭제 또는 임시 접근 차단할 수 있습니다.  
   1. 타인의 명예를 훼손하거나 초상권, 개인정보 보호권 등을 침해하는 게시물  
   2. 공공질서 및 미풍양속을 해치는 게시물  
   3. 영리를 목적으로 광고, 판촉 내용을 포함한 정보(스팸 등)  
   4. 범죄적 행위에 결부된다고 인정되는 게시물  
   5. 정보통신망법 또는 저작권법 등에 위반되는 게시물  
   6. 기타 회사가 부적절하다고 판단되는 게시물  
2. 회사는 전항에 따라 게시물을 삭제하거나 차단한 경우, 지체 없이 해당 회원에게 통지합니다. 다만, 긴급히 삭제가 필요한 경우 사후 통지할 수 있습니다.  
3. 회원이 게시한 게시물의 내용에 대한 모든 책임은 게시자 본인에게 있으며, 회사는 회원 게시물로 인해 발생한 법적 분쟁에 대해 일체의 책임을 지지 않습니다.

**제5장 계약 당사자의 의무**

**제14조(회사의 의무)**  
1. 회사는 관련 법령과 본 약관이 금지하거나 미풍양속에 반하는 행위를 하지 않으며, 지속적이고 안정적으로 서비스를 제공하기 위하여 노력합니다.  
2. 회사는 서비스 제공과 관련하여 취득한 회원의 개인정보를 개인정보처리방침에 따른 용도 이외의 용도로 사용하지 않으며, 회원의 명시적인 동의 없이는 제3자에게 제공하지 않습니다.  
3. 회사는 회원이 원하지 않는 광고성 전자우편 등을 발송하지 않습니다.

**제15조(회원의 의무)**  
1. 회원은 본 약관 및 관계 법령, 회사가 서비스 화면에 게시하거나 공지한 주의사항을 준수해야 합니다.  
2. 회원은 서비스 이용을 위해 필요한 인터넷 회선 및 단말 장치(스마트폰, 태블릿, PC 등)를 자신의 비용과 책임으로 준비해야 합니다.  
3. 회원은 자신의 계정 및 비밀번호에 대한 관리 책임이 있으며, 이를 타인에게 양도, 대여할 수 없습니다. 비밀번호를 도난당하거나 제3자가 사용하고 있음을 인지한 경우 즉시 회사에 통지하고 회사의 안내에 따라야 합니다.

**제6장 서비스 이용의 제한 및 중단**

**제16조(서비스 이용 제한 등)**  
1. 회사는 회원이 아래 각 호의 어느 하나에 해당하는 경우 사전 통지 없이 서비스 이용을 제한하거나 계약을 해지할 수 있습니다.  
   1. 가입 신청 시 허위 내용을 등록한 경우  
   2. 타인의 서비스 이용을 방해하거나 정보를 도용하는 등 부정한 행위를 한 경우  
   3. 서비스 운영을 고의로 방해하는 등 서비스의 정상적 운영을 방해한 경우  
   4. 범죄와 결부된다고 객관적으로 인정되는 경우  
   5. 부정한 목적 또는 영리를 위해 서비스를 이용하는 경우  
   6. 정보통신망법, 저작권법 등 관련 법령을 위반한 경우  
   7. 다른 사람의 명예를 훼손하거나 불이익을 주는 경우  
   8. 공공질서를 문란하게 하거나 미풍양속을 저해하는 정보 및 내용을 등록한 경우  
   9. 서비스에 타인의 개인정보(전화번호, 이메일, 주소 등)를 무단으로 침해하는 경우  
   10. 기타 회사가 정한 정책을 위반한 경우  
2. 회사는 전항에 따른 이용 제한이나 해지 시, 회원에게 통지합니다.

**제17조(서비스 제공의 중단)**  
1. 회사는 컴퓨터 등 정보통신설비의 보수·교체·정기 점검·고장·통신 장애, 또는 기타 부득이한 사유가 발생한 경우에는 서비스 제공을 일시적으로 중단할 수 있습니다.  
2. 회사는 제1항의 사유로 서비스 중단이 발생할 경우, 사전에 서비스 초기 화면 또는 공지사항을 통해 중단 일시, 사유, 예정 일정을 안내합니다. 다만, 긴급점검, 긴급 장애 복구 등의 사유가 있을 경우 사후에 공지할 수 있습니다.  
3. 회사는 서비스 제공 중단으로 인해 회원 또는 제3자가 입은 손해에 대해 배상합니다. 다만, 회사의 고의 또는 중과실이 없는 경우에는 배상 책임이 면제됩니다.

**제7장 손해배상 및 면책조항**

**제18조(손해배상)**  
1. 회사는 서비스 이용과 관련하여 회사의 고의 또는 중과실이 입증된 경우를 제외하고는 회원에게 발생한 손해를 배상할 책임이 없습니다.  
2. 회원이 서비스 이용과 관련하여 회사에 손해를 끼쳤을 경우, 회사는 회원에 대해 손해배상을 청구할 수 있습니다.

**제19조(면책조항)**  
1. 회사는 천재지변, 국가 비상사태, 정전, 통신 두절, 서비스 서버의 장애, 해킹, 바이러스, 회원의 부주의 등으로 인한 서비스 장애 및 정보 유출에 대하여 책임을 지지 않습니다.  
2. 회사는 회원이 서비스에 게재하거나 제3자가 게재한 게시물, 링크, 자료의 신뢰도, 정확성 등에 대해서는 보증하지 않으며, 이로 인한 손해(법률적 분쟁, 명예훼손, 저작권 침해 등)는 모두 게시자 본인이 책임을 집니다.  
3. 회사는 회원 상호 간 또는 회원과 제3자 상호 간에 서비스를 매개로 발생한 분쟁에 대해 개입하지 않으며, 이로 인한 손해에 대해서도 책임을 지지 않습니다.  
4. 회사는 회원이 휴대폰 기기, 통신 요금, 기타 장치 등을 이용하여 서비스에 접속하는 과정에서 발생하는 비용(데이터 요금, SMS 요금 등)에 대해 책임을 지지 않습니다.

**제8장 기타**

**제20조(약관의 해석)**  
본 약관 및 회사가 제공하는 개별 이용조건(유료 서비스 이용약관 등)이 상충할 경우, 개별 이용조건이 우선 적용됩니다.

**제21조(분쟁 해결)**  
1. 회사와 회원 간에 발생한 분쟁에 대해 소송이 제기될 경우, 해당 소송의 관할 법원은 회사 본사 소재지를 관할하는 법원으로 합니다.  
2. 회사와 회원은 서비스 이용과 관련하여 발생하는 분쟁을 원만하게 해결하기 위하여 필요한 모든 노력(콘텐츠 조정, 중재, 협의 등)을 합니다.

**제22조(준거법)**  
본 약관은 대한민국 법령에 따라 해석되고 적용됩니다.

**부칙**  
본 약관은 2025년 6월 1일부터 시행합니다.
''';

  final String _privacyPolicyText = '''
[개인정보처리방침]

F5_Health(이하 “회사”)는 “정보통신망 이용촉진 및 정보보호 등에 관한 법률”(약칭 “정보통신망법”) 및 “개인정보 보호법”(약칭 “PIPA”) 등 관련 법령을 준수하며, 이용자의 개인정보보호를 최우선으로 고려하여 아래와 같이 개인정보처리방침을 수립·공개합니다.

**제1조(개인정보의 처리 목적)**  
회사는 다음과 같은 목적으로 개인정보를 처리합니다. 처리된 개인정보는 다음의 목적 이외에는 사용되지 않으며, 목적이 변경되는 경우 사전에 별도 동의를 받습니다.

1. **회원 관리**  
   - 회원 가입 의사 확인, 이용자 식별·인증, 회원 자격 유지·관리, 분쟁 조정을 위한 기록 보존  
   - 불만처리, 서비스 이행 및 고지사항 전달

2. **서비스 제공 및 운영**  
   - 개인 맞춤형 건강 정보(심박수, 수면, 운동량 등)를 수집·분석하여 대시보드 및 리포트를 제공  
   - AI 기반 건강 피드백 및 맞춤 알림  
   - 서비스 이용 통계 및 품질 개선을 위한 데이터 분석

3. **마케팅 및 광고 활용**  
   - 신규 서비스(프리미엄 등) 개발, 이벤트 및 광고성 정보 제공 및 참여기회 제공  
   - 접속 빈도 파악 또는 회원의 서비스 이용에 대한 통계

4. **기기, 네트워크 관리 및 보안**  
   - 서비스 이용 기록, 접속 빈도 및 오·남용 방지  
   - 부정이용 방지, 분쟁 해결, 서비스 최적화

**제2조(수집하는 개인정보 항목 및 수집 방법)**  
1. **수집 항목**  
   1. **회원가입 및 서비스 이용 시**(필수):  
      - 이메일 주소, 비밀번호, 휴대전화번호, 닉네임, 생년월일, 성별(선택)  
   2. **건강 데이터 수집**(회원 동의 후 선택적 수집):  
      - 심박수, 활동량(걸음 수, 운동 종류·시간·칼로리), 수면 데이터, 수면 단계  
      - 체중, 활동 거리, 소모된 칼로리 등 (Apple HealthKit, Google Fit 연동 시 해당 플랫폼으로부터 제공받은 데이터)  
   3. **Daily Record 저장(Hive 로컬 DB)**:  
      - 물 섭취량(잔 수), 흡연량(개비 수), 음주량(ml 단위), 식단 정보(음식 코드, 섭취량 등)  
   4. **자동 생성 정보**:  
      - 서비스 이용 기록(로그인 시간, 서비스 이용 로그 등), 접속 IP, 기기 정보(OS, 기기 모델, 버전), 쿠키, 위치정보(선택적 권한 시)  
   5. **마케팅 목적 수집**(선택):  
      - 푸시 알림, 이메일, SMS 수신 여부

2. **수집 방법**  
   1. 회원가입, 로그인, 서비스 이용 과정에서 이용자가 직접 제공  
   2. 건강 데이터 연동 시 Apple HealthKit, Google Fit API 등 외부 헬스케어 플랫폼으로부터 자동 수집  
   3. 서비스 이용 과정에서 자동으로 생성·수집 (접속 로그, 쿠키, IP 주소 등)

3. **개인정보 수집 최소화 원칙**  
회사는 개인정보를 처리할 때 목적 달성에 필요한 최소한의 정보만을 수집하며, 불필요한 개인정보는 즉시 파기합니다.

**제3조(개인정보의 처리 및 보유 기간)**  
1. 회사는 개인정보 처리 목적이 달성된 후에는 관련 법령에 따라 해당 정보를 지체 없이 파기합니다.  
2. 보유 기간 예시:  
   1. **회원관리**: 회원 탈퇴 또는 이용계약 종료 시까지  
   2. **부정 이용 기록**: 부정 이용 방지를 위한 기록(부정 행위, 제재 이력 등) – 1년  
   3. **서비스 이용 기록**: 통계 및 접속 기록 – 6개월(정보통신망법)  
   4. **건강 데이터**: 회원 탈퇴 시까지(탈퇴 후 복원 불가)  
   5. **개인정보 관련 분쟁 해결**: 분쟁 발생 시 완전 해결 시까지

**제4조(개인정보 파기 절차 및 방법)**  
1. **파기 절차**  
   - 회원 탈퇴, 법정 보유 기간 경과, 처리 목적 달성 등 개인정보가 불필요하게 된 경우 내부 방침에 따라 파기합니다.  
   - 파기 사유 발생 시 지체 없이 파기하며, 별도 DB로 옮겨져 내부 방침에 따라 일정 기간 저장된 후 파기됩니다.

2. **파기 방법**  
   1. **전자적 파일 형태**: 복원이 불가능한 방법(기록을 덮어쓰기, 물리적 디스크 파기 등)  
   2. **종이 문서 형태**: 분쇄기로 분쇄하거나 소각

**제5조(개인정보 제3자 제공)**  
회사는 원칙적으로 이용자의 개인정보를 제3자에게 제공하지 않습니다. 다만, 아래 경우에는 예외적으로 개인정보를 제공할 수 있습니다.  
1. 이용자들이 사전에 동의한 경우  
2. 법령의 규정에 의거하거나, 수사 목적으로 법령에 정해진 절차와 방법에 따라 수사기관의 요구가 있는 경우  
3. 통계 작성, 학술연구 또는 시장조사를 위하여 필요한 경우로서 특정 개인을 식별할 수 없는 형태로 제공하는 경우  
4. 서비스 제공을 위해 외부 업체(데이터 분석, 서버 호스팅, 메시징 서비스 업체 등)와 업무제휴 또는 위탁계약을 체결한 경우(위탁업체 현황은 아래 “위탁업체” 항목 참조)

**제6조(정보주체 및 법정대리인의 권리·의무와 그 행사 방법)**  
1. 정보주체(회원)는 언제든지 다음 각 호의 개인정보 보호 관련 권리를 행사할 수 있습니다.  
   1. 개인정보 열람 요구  
   2. 오류 등이 있는 경우 정정 요구  
   3. 삭제 요구  
   4. 처리 정지 요구  
2. 제1항에 따른 권리 행사는 회사에 대해 서면, 전화, 이메일 등을 통해 요청할 수 있으며, 회사는 지체 없이 조치합니다.  
3. 정보주체가 정정·삭제·처리정지 등을 요구한 경우, 회사는 정정·삭제·정지 사유가 정당한 경우 지체 없이 조치하며, 처리 결과를 정보주체에게 통지합니다.  
4. 정보주체가 개인정보 오류 등에 대한 정정 또는 삭제를 요청한 경우, 회사는 그 요청을 받은 날로부터 30일 이내에 완료합니다.  
5. 이용자는 개인정보 열람 또는 오류 정정, 삭제, 처리정지 등을 위해 고객센터(connect@f5health.co.kr)로 문의하거나, 서비스 내 ‘개인정보 변경’ 메뉴를 통해 직접 변경할 수 있습니다.

**제7조(개인정보 보호를 위한 기술적·관리적 대책)**  
회사는 개인정보 보호법 제29조에 따라 다음과 같은 기술적·관리적 보호 대책을 적용하여 개인정보를 안전하게 관리합니다.

1. **관리적 대책**  
   1. 개인정보처리 담당자 지정 및 정기적인 교육을 시행합니다.  
   2. 개인정보 처리방침 및 내부 운영 방침 마련·공유하여 임직원과 파견·위탁 직원이 이를 준수하도록 합니다.  
   3. 개인정보 접근 권한 최소화(업무 수행에 필요한 최소 인원에게만 부여)  
   4. 임직원 비밀번호 관리, 보안서약서 체결, 물리적 보안(출입통제 등)

2. **기술적 대책**  
   1. 개인정보는 암호화하여 저장 및 관리합니다.  
   2. 해킹 등에 대비한 침입 차단 시스템(IPS), 악성코드 차단 솔루션을 설치·운영합니다.  
   3. 중요한 데이터(비밀번호 등)는 암호화하여 저장하며, 파일 및 전송데이터는 암호화 통신(SSL/TLS 등)을 적용합니다.  
   4. 개인정보 취급 시스템(서버)에 대한 접근 통제 시스템 구축  
   5. 네트워크 접속 기록 보관 및 보안로그 정기 모니터링  
   6. 백신 프로그램을 설치하여 주기적으로 악성 프로그램 점검 및 차단

**제8조(개인정보 자동 수집 장치의 설치·운영 및 거부에 관한 사항)**  
1. 회사는 이용자 편의를 위해 쿠키(Cookie), 로그파일 등을 사용하여 이용자가 서비스를 방문할 때마다 접속 IP, 브라우저 종류, 모바일 기기 정보, 방문일시, 서비스 이용 기록 등을 자동으로 수집할 수 있습니다.  
2. 쿠키란 웹사이트 서버가 이용자의 브라우저에 보내는 소량의 정보로, 이용자 PC 혹은 모바일 기기의 웹 브라우저에 저장됩니다. 쿠키를 통해 이용자 식별, 로그인 상태 유지, 개인화된 환경 제공 등이 가능합니다.  
3. 이용자는 쿠키 설치에 대해 브라우저 옵션을 통해 허용 여부를 선택할 수 있습니다. 다만, 쿠키 허용 거부 시 서비스 이용에 불편이 있을 수 있습니다.  
   - Chrome: 설정 → 개인 정보 및 보안 → 쿠키 및 기타 사이트 데이터 → 쿠키 허용/거부  
   - Safari: 환경설정 → 개인정보 보호 → 쿠키 및 웹사이트 데이터 관리  
   - 기타 브라우저 메뉴얼 참조

**제9조(개인정보의 제3자 제공 및 위탁)**  
1. 회사는 개인정보 처리 목적 달성을 위해 제3자 제공이 필요한 경우, 정보주체의 동의를 받거나, 법령에 따른 절차를 준수합니다.  
2. 회사는 개인정보 처리를 위탁할 경우 위탁 계약 체결 시 개인정보 보호 관련 사항을 명확히 규정하며, 수탁자가 개인정보를 안전하게 관리하도록 감독합니다.  
3. 현재 회사의 개인정보 처리 위탁 현황은 다음과 같습니다.  

| 위탁업체       | 위탁 업무 내용                   | 개인정보 보유 및 이용 기간    |
|--------------|------------------------------|--------------------------|
| AWS(Amazon Web Services) | 서비스 호스팅 및 데이터베이스 관리 | 위탁계약 종료 시까지 또는 회원 탈퇴 시 즉시 파기 |
| Firebase(구글) | 푸시 알림 서비스               | 위탁계약 종료 시까지 또는 회원 탈퇴 시 즉시 파기 |
| Mixpanel     | 서비스 이용 통계 분석            | 위탁계약 종료 시까지 또는 통계 목적으로 익명 처리 후 보관 |
| SendGrid     | 이메일 발송(회원가입, 알림 등)     | 위탁계약 종료 시까지 또는 회원탈퇴 시 즉시 파기 |

(※ 위탁업체 정보는 사정에 의해 변경될 수 있으며, 변경 시 이 개인정보처리방침을 통해 공지합니다.)

**제10조(정보주체의 권익침해 구제방법)**  
1. 정보주체는 개인정보 침해를 신고하거나 상담을 원할 경우 아래 기관에 문의할 수 있습니다.  
   1. 개인정보분쟁조정위원회 (www.kopico.go.kr / 1833-6972)  
   2. 개인정보침해신고센터 (privacy.kisa.or.kr / 국번 없이 118)  
   3. 대검찰청 사이버수사과 (www.spo.go.kr / 02-3480-3573)  
   4. 경찰청 사이버안전국 (cyberbureau.police.go.kr / 국번 없이 182)  
2. 회사는 정보주체의 개인정보 관련 민원을 신속하게 처리하며, 그 외 개인정보 보호 관련 문의에 대해 성실히 답변합니다.

**제11조(개인정보 보호책임자 및 담당부서)**  
1. 회사는 개인정보 처리에 관한 업무를 총괄하여 책임지고, 개인정보 처리와 관련한 정보주체의 불만 처리, 피해구제 등을 위하여 아래와 같이 개인정보 보호 책임자 및 담당자를 지정합니다.

- 개인정보 보호 책임자(Chief Privacy Officer, CPO)  
  이름: 홍길동  
  직책: 최고정보보호책임자(CISO)  
  연락처: privacy@f5health.co.kr  

- 개인정보 보호 담당부서(Data Protection Officer, DPO)  
  부서명: 개인정보관리팀  
  담당자: 김철수  
  연락처: dpo@f5health.co.kr, 02-1234-5678  

2. 정보주체는 회사의 서비스(또는 사업)를 이용하면서 발생한 모든 개인정보 보호 관련 문의, 불만처리, 피해구제 등에 관한 사항을 개인정보 보호 책임자 및 담당부서로 문의할 수 있습니다. 회사는 정보주체의 문의에 대해 지체 없이 답변 및 처리합니다.

**제12조(국내·외 서비스 제공 및 개인정보 처리 위탁)**  
1. 회사는 일부 서비스를 국외에 서버를 두고 제공하거나, 해외 법인 및 외부 위탁업체에 일부 업무를 위탁하여 제공할 수 있습니다. 이 경우 회사는 해외 이전되는 개인정보가 안전하게 보호되도록 필요한 절차와 안전장치를 마련합니다.  
2. 회사는 개인 건강 정보를 포함한 민감 정보를 국외로 이전하는 경우, 정보주체로부터 별도의 동의를 받으며, 이전 국가의 개인정보 보호 수준 등을 고려하여 적절한 보호 조치를 취합니다.

**제13조(개인정보 보호 정책 변경)**  
1. 이 개인정보처리방침은 법령, 지침, 회사 내부 방침 변경 및 서비스 변경 사항 등에 따라 변경될 수 있습니다.  
2. 방침 변경 시 변경된 내용을 시행일 7일 전부터 홈페이지 또는 서비스 내 공지사항을 통하여 공지합니다. 다만, 개인정보보호에 중대한 영향을 미치는 변경의 경우 정보주체에게 별도 통지하거나 동의를 받을 수 있습니다.  
3. 본 방침은 2025년 6월 1일부터 적용되며, 종전 방침은 동일한 방법으로 공지된 이후 7일이 경과한 시점부터 효력을 상실합니다.

**부칙**  
본 방침은 2025년 6월 1일부터 시행합니다.
''';

  @override
  void initState() {
    super.initState();
    _loadAlarmTime();
    _loadSavedAlcohol(); // SharedPreferences에서 소주/맥주 값 불러오기
    _loadProfile(); // 나머지 프로필 정보(API) 불러오기
  }

  /// SharedPreferences에서 저장된 소주/맥주 병 수 불러오기
  Future<void> _loadSavedAlcohol() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _sojuBottles = prefs.getDouble('sojuBottles') ?? 0.0;
      _beerBottles = prefs.getDouble('beerBottles') ?? 0.0;
    });
  }

  /// 1) GET /v1/members/me 로 현재 프로필 불러오기 (음주량은 Shared에서 가져옴)
  Future<void> _loadProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken');
      final res = await http.get(
        Uri.parse('${Config.baseUrl}/v1/members/me'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        setState(() {
          nickname = data['nickname'] ?? nickname;
          height = data['height'] ?? height;
          weight = data['weight'] ?? weight;
          daySmokeCigarettes = data['daySmokeCigarettes'] ?? daySmokeCigarettes;
          weekExerciseFrequency =
              data['weekExerciseFrequency'] ?? weekExerciseFrequency;
          // **음주량(weekAlcoholDrinks)은 API에서 무시**하고 Shared에서 가져온 값을 그대로 사용
        });
      } else {
        debugPrint('❌ 프로필 로드 실패: ${res.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ 프로필 로드 오류: $e');
    }
  }

  /// 2) PATCH /v1/members/me/edit 로 프로필 업데이트
  Future<void> _updateProfile({
    required String nickname,
    required int height,
    required int weight,
    required int daySmokeCigarettes,
    required int weekAlcoholMl, // ml 단위
    required int weekExerciseFrequency,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken');
      final body = json.encode({
        'nickname': nickname,
        'height': height,
        'weight': weight,
        'daySmokeCigarettes': daySmokeCigarettes,
        'weekAlcoholDrinks': weekAlcoholMl,
        'weekExerciseFrequency': weekExerciseFrequency,
      });
      final res = await http.patch(
        Uri.parse('${Config.baseUrl}/v1/members/me/edit'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: body,
      );
      if (res.statusCode == 200) {
        setState(() {
          this.nickname = nickname;
          this.height = height;
          this.weight = weight;
          this.daySmokeCigarettes = daySmokeCigarettes;
          this.weekExerciseFrequency = weekExerciseFrequency;
          // UI에 보여줄 알코올 병 단위는 Shared에서 이미 업데이트된 값 사용
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('프로필이 업데이트되었습니다.')));
      } else {
        debugPrint('❌ 프로필 업데이트 실패: ${res.statusCode}');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('프로필 업데이트에 실패했습니다.')));
      }
    } catch (e) {
      debugPrint('❌ 프로필 업데이트 오류: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('프로필 업데이트 중 오류가 발생했습니다.')));
    }
  }

  /// SharedPreferences에서 저장된 알림 시간 읽어오기
  Future<void> _loadAlarmTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timeStr = prefs.getString('alarm_time');
    if (timeStr != null) {
      final parts = timeStr.split(':');
      if (parts.length == 2) {
        final h = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        if (h != null && m != null) {
          setState(() => selectedTime = TimeOfDay(hour: h, minute: m));
        }
      }
    }
  }

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
            padding: EdgeInsets.all(16),
            child: Text(
              '설정 메뉴',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),

          // ────────────────────────────────────────────────────
          // 내 정보 변경
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('내 정보 변경'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _showEditProfileDialog,
          ),

          // 알림 시간 설정 (AM/PM 모드로 강제 변경)
          ListTile(
            leading: const Icon(Icons.notifications),
            title: Text(
              selectedTime != null
                  ? '기록 알림 시간: ${selectedTime!.format(context)}'
                  : '기록 알림 시간 설정',
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _showTimePickerDialog,
          ),

          // 서비스 이용약관
          ListTile(
            leading: const Icon(Icons.article),
            title: const Text('서비스 이용약관'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showTextDialog("서비스 이용약관", _termsOfServiceText),
          ),

          // 개인정보 처리방침
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('개인정보 처리방침'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showTextDialog("개인정보 처리방침", _privacyPolicyText),
          ),

          const SizedBox(height: 24),

          // 로그아웃 버튼
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
              onPressed: _handleLogout,
              child: const Text('Log out'),
            ),
          ),
        ],
      ),
    );
  }

  /// 내 정보 변경 다이얼로그
  void _showEditProfileDialog() {
    final nickCtrl = TextEditingController(text: nickname);
    // 주간 운동 빈도용 컨트롤러는 Dropdown으로 바뀌어 사용하지 않음

    // 드롭다운 옵션 리스트 생성
    final heightOptions = List<int>.generate(220 - 130 + 1, (i) => 130 + i);
    final weightOptions = List<int>.generate(280 - 30 + 1, (i) => 30 + i);
    final smokeOptions = List<int>.generate(41, (i) => i); // 0~40
    final bottleOptions = List<double>.generate(21, (i) => i * 0.5); // 0.0~10.0
    final exerciseOptions = List<int>.generate(8, (i) => i); // 0~7

    // 다이얼로그 내에서 사용할 임시 선택 변수
    int selectedHeight = height;
    int selectedWeight = weight;
    int selectedSmoke = daySmokeCigarettes;
    double selectedSoju = _sojuBottles;
    double selectedBeer = _beerBottles;
    int selectedExercise = weekExerciseFrequency;

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('내 정보 변경'),
            content: StatefulBuilder(
              builder:
                  (context, setDialogState) => SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 닉네임 입력
                        TextField(
                          controller: nickCtrl,
                          decoration: const InputDecoration(labelText: '닉네임'),
                        ),
                        const SizedBox(height: 8),

                        // 키 선택
                        Row(
                          children: [
                            const Expanded(
                              flex: 2,
                              child: Text(
                                '키(cm)',
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: DropdownButton<int>(
                                value: selectedHeight,
                                isExpanded: true,
                                items:
                                    heightOptions.map((h) {
                                      return DropdownMenuItem<int>(
                                        value: h,
                                        child: Text(h.toString()),
                                      );
                                    }).toList(),
                                onChanged: (val) {
                                  if (val == null) return;
                                  setDialogState(() {
                                    selectedHeight = val;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // 몸무게 선택
                        Row(
                          children: [
                            const Expanded(
                              flex: 2,
                              child: Text(
                                '몸무게(kg)',
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: DropdownButton<int>(
                                value: selectedWeight,
                                isExpanded: true,
                                items:
                                    weightOptions.map((w) {
                                      return DropdownMenuItem<int>(
                                        value: w,
                                        child: Text(w.toString()),
                                      );
                                    }).toList(),
                                onChanged: (val) {
                                  if (val == null) return;
                                  setDialogState(() {
                                    selectedWeight = val;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // 하루 흡연량 선택
                        Row(
                          children: [
                            const Expanded(
                              flex: 2,
                              child: Text(
                                '하루 흡연량(개비)',
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: DropdownButton<int>(
                                value: selectedSmoke,
                                isExpanded: true,
                                items:
                                    smokeOptions.map((s) {
                                      return DropdownMenuItem<int>(
                                        value: s,
                                        child: Text(s.toString()),
                                      );
                                    }).toList(),
                                onChanged: (val) {
                                  if (val == null) return;
                                  setDialogState(() {
                                    selectedSmoke = val;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // ─────────────────────────────────────────────────
                        // “주간 음주량” 레이블 추가
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '주간 음주량',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // 소주 병 수
                        Row(
                          children: [
                            const Expanded(
                              flex: 2,
                              child: Text(
                                '소주 (360ml/병)',
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: DropdownButton<double>(
                                value: selectedSoju,
                                isExpanded: true,
                                items:
                                    bottleOptions.map((b) {
                                      return DropdownMenuItem<double>(
                                        value: b,
                                        child: Text(b.toStringAsFixed(1)),
                                      );
                                    }).toList(),
                                onChanged: (val) {
                                  if (val == null) return;
                                  setDialogState(() {
                                    selectedSoju = val;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // 맥주 병 수
                        Row(
                          children: [
                            const Expanded(
                              flex: 2,
                              child: Text(
                                '맥주 (500ml/병)',
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: DropdownButton<double>(
                                value: selectedBeer,
                                isExpanded: true,
                                items:
                                    bottleOptions.map((b) {
                                      return DropdownMenuItem<double>(
                                        value: b,
                                        child: Text(b.toStringAsFixed(1)),
                                      );
                                    }).toList(),
                                onChanged: (val) {
                                  if (val == null) return;
                                  setDialogState(() {
                                    selectedBeer = val;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // 주간 운동 빈도 (0~7 선택)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '주간 운동 빈도',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Expanded(flex: 2, child: SizedBox()), // 빈 공간
                            Expanded(
                              flex: 3,
                              child: DropdownButton<int>(
                                value: selectedExercise,
                                isExpanded: true,
                                items:
                                    exerciseOptions.map((e) {
                                      return DropdownMenuItem<int>(
                                        value: e,
                                        child: Text(e.toString()),
                                      );
                                    }).toList(),
                                onChanged: (val) {
                                  if (val == null) return;
                                  setDialogState(() {
                                    selectedExercise = val;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () async {
                  final newNick = nickCtrl.text;
                  final newH = selectedHeight;
                  final newW = selectedWeight;
                  final newS = selectedSmoke;
                  final newE = selectedExercise;

                  // 병 단위 → ml 단위로 환산
                  final int totalAlcoholMl =
                      (selectedSoju * 360 + selectedBeer * 500).round();

                  // SharedPreferences에 소주/맥주 병 수 저장
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setDouble('sojuBottles', selectedSoju);
                  await prefs.setDouble('beerBottles', selectedBeer);

                  // 화면에 즉시 반영해 주기
                  setState(() {
                    _sojuBottles = selectedSoju;
                    _beerBottles = selectedBeer;
                    weekExerciseFrequency = newE;
                  });

                  Navigator.pop(context);

                  _updateProfile(
                    nickname: newNick,
                    height: newH,
                    weight: newW,
                    daySmokeCigarettes: newS,
                    weekAlcoholMl: totalAlcoholMl,
                    weekExerciseFrequency: newE,
                  );
                },
                child: const Text('저장'),
              ),
            ],
          ),
    );
  }

  /// 시간 선택 다이얼로그 (AM/PM 모드)
  void _showTimePickerDialog() async {
    final now = TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? now,
      builder: (context, child) {
        // 12시간(AM/PM) 모드로 강제 변경하기
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => selectedTime = picked);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('alarm_time', _timeOfDayToString(picked));
      await cancelAlarm();
      await scheduleDailyAlarm(picked);
    }
  }

  String _timeOfDayToString(TimeOfDay t) =>
      t.hour.toString().padLeft(2, '0') +
      ':' +
      t.minute.toString().padLeft(2, '0');

  void _showTextDialog(String title, String content) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text(title),
            content: SingleChildScrollView(child: Text(content)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('닫기'),
              ),
            ],
          ),
    );
  }

  Future<void> _handleLogout() async {
    try {
      await Hive.box<DailyRecord>('dailyData').clear();
      await Hive.box<List<EatenFood>>('mealFoodsBox').clear();
      final prefs = await SharedPreferences.getInstance();
      final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
      await prefs.remove('submitted_$todayKey');

      final refresh = prefs.getString('refresh_token');
      if (refresh != null) {
        final res = await http.post(
          Uri.parse('${Config.baseUrl}/logout'),
          headers: {
            'Content-Type': 'application/json',
            'Refresh-Token': refresh,
          },
        );
        debugPrint('🔌 서버 로그아웃 응답: ${res.statusCode}');
      }

      await UserApi.instance.logout();
      debugPrint('✅ 카카오 로그아웃 완료');
      // await prefs.clear(); // 주석 처리하여 알람 시간, 소주/맥주 값은 유지
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);
    } catch (e) {
      debugPrint('❌ 로그아웃 실패: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('로그아웃에 실패했습니다.')));
    }
  }
}

/*
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:f5_health/services/notification_service.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:http/http.dart' as http;

import 'package:hive_flutter/hive_flutter.dart';
import '../models/daily_record.dart';
import '../models/eaten_food.dart';
import '../config.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // --- 프로필 데이터 ---
  String nickname = '사용자';
  int height = 0;
  int weight = 0;
  int daySmokeCigarettes = 0;
  int weekAlcoholDrinks = 0;
  int weekExerciseFrequency = 0;

  // --- 기록 알림 시간 ---
  TimeOfDay? selectedTime;

  // 약관·방침 텍스트 (생략) …
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
  void initState() {
    super.initState();
    _loadAlarmTime();
    _loadProfile();
  }

  /// 1) GET /v1/members/me 로 현재 프로필 불러오기
  Future<void> _loadProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken');
      final res = await http.get(
        Uri.parse('${Config.baseUrl}/v1/members/me'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        setState(() {
          nickname = data['nickname'] ?? nickname;
          height = data['height'] ?? height;
          weight = data['weight'] ?? weight;
          daySmokeCigarettes = data['daySmokeCigarettes'] ?? daySmokeCigarettes;
          weekAlcoholDrinks = data['weekAlcoholDrinks'] ?? weekAlcoholDrinks;
          weekExerciseFrequency =
              data['weekExerciseFrequency'] ?? weekExerciseFrequency;
        });
      } else {
        debugPrint('❌ 프로필 로드 실패: ${res.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ 프로필 로드 오류: $e');
    }
  }

  /// 2) PATCH /v1/members/me/edit 로 프로필 업데이트
  Future<void> _updateProfile({
    required String nickname,
    required int height,
    required int weight,
    required int daySmokeCigarettes,
    required int weekAlcoholDrinks,
    required int weekExerciseFrequency,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken');
      final body = json.encode({
        'nickname': nickname,
        'height': height,
        'weight': weight,
        'daySmokeCigarettes': daySmokeCigarettes,
        'weekAlcoholDrinks': weekAlcoholDrinks,
        'weekExerciseFrequency': weekExerciseFrequency,
      });
      final res = await http.patch(
        Uri.parse('${Config.baseUrl}/v1/members/me/edit'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: body,
      );
      if (res.statusCode == 200) {
        setState(() {
          this.nickname = nickname;
          this.height = height;
          this.weight = weight;
          this.daySmokeCigarettes = daySmokeCigarettes;
          this.weekAlcoholDrinks = weekAlcoholDrinks;
          this.weekExerciseFrequency = weekExerciseFrequency;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('프로필이 업데이트되었습니다.')));
      } else {
        debugPrint('❌ 프로필 업데이트 실패: ${res.statusCode}');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('프로필 업데이트에 실패했습니다.')));
      }
    } catch (e) {
      debugPrint('❌ 프로필 업데이트 오류: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('프로필 업데이트 중 오류가 발생했습니다.')));
    }
  }

  /// SharedPreferences에서 저장된 알림 시간 읽어오기
  Future<void> _loadAlarmTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timeStr = prefs.getString('alarm_time');
    if (timeStr != null) {
      final parts = timeStr.split(':');
      if (parts.length == 2) {
        final h = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        if (h != null && m != null) {
          setState(() => selectedTime = TimeOfDay(hour: h, minute: m));
        }
      }
    }
  }

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
            padding: EdgeInsets.all(16),
            child: Text(
              '설정 메뉴',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),

          // ───────────────────────────────────
          // 내 정보 변경
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('내 정보 변경'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _showEditProfileDialog,
          ),

          // 알림 시간 설정
          ListTile(
            leading: const Icon(Icons.notifications),
            title: Text(
              selectedTime != null
                  ? '기록 알림 시간: ${selectedTime!.format(context)}'
                  : '기록 알림 시간 설정',
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _showTimePickerDialog,
          ),

          // 서비스 이용약관
          ListTile(
            leading: const Icon(Icons.article),
            title: const Text('서비스 이용약관'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showTextDialog("서비스 이용약관", _termsOfServiceText),
          ),

          // 개인정보 처리방침
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('개인정보 처리방침'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showTextDialog("개인정보 처리방침", _privacyPolicyText),
          ),

          const SizedBox(height: 24),

          // 로그아웃 버튼
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
              onPressed: _handleLogout,
              child: const Text('Log out'),
            ),
          ),
        ],
      ),
    );
  }

  /// 내 정보 변경 다이얼로그
  void _showEditProfileDialog() {
    final nickCtrl = TextEditingController(text: nickname);
    final hCtrl = TextEditingController(text: height.toString());
    final wCtrl = TextEditingController(text: weight.toString());
    final sCtrl = TextEditingController(text: daySmokeCigarettes.toString());
    final aCtrl = TextEditingController(text: weekAlcoholDrinks.toString());
    final eCtrl = TextEditingController(text: weekExerciseFrequency.toString());

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('내 정보 변경'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nickCtrl,
                    decoration: const InputDecoration(labelText: '닉네임'),
                  ),
                  TextField(
                    controller: hCtrl,
                    decoration: const InputDecoration(labelText: '키(cm)'),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: wCtrl,
                    decoration: const InputDecoration(labelText: '몸무게(kg)'),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: sCtrl,
                    decoration: const InputDecoration(labelText: '하루 흡연량(개비)'),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: aCtrl,
                    decoration: const InputDecoration(labelText: '주간 음주 횟수'),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: eCtrl,
                    decoration: const InputDecoration(labelText: '주간 운동 빈도'),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () {
                  final newNick = nickCtrl.text;
                  final newH = int.tryParse(hCtrl.text) ?? height;
                  final newW = int.tryParse(wCtrl.text) ?? weight;
                  final newS = int.tryParse(sCtrl.text) ?? daySmokeCigarettes;
                  final newA = int.tryParse(aCtrl.text) ?? weekAlcoholDrinks;
                  final newE =
                      int.tryParse(eCtrl.text) ?? weekExerciseFrequency;

                  Navigator.pop(context);
                  _updateProfile(
                    nickname: newNick,
                    height: newH,
                    weight: newW,
                    daySmokeCigarettes: newS,
                    weekAlcoholDrinks: newA,
                    weekExerciseFrequency: newE,
                  );
                },
                child: const Text('저장'),
              ),
            ],
          ),
    );
  }

  /// 시간 선택 다이얼로그
  void _showTimePickerDialog() async {
    final now = TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? now,
    );
    if (picked != null) {
      setState(() => selectedTime = picked);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('alarm_time', _timeOfDayToString(picked));
      await cancelAlarm();
      await scheduleDailyAlarm(picked);
    }
  }

  String _timeOfDayToString(TimeOfDay t) =>
      t.hour.toString().padLeft(2, '0') +
      ':' +
      t.minute.toString().padLeft(2, '0');

  void _showTextDialog(String title, String content) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text(title),
            content: SingleChildScrollView(child: Text(content)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('닫기'),
              ),
            ],
          ),
    );
  }

  Future<void> _handleLogout() async {
    try {
      await Hive.box<DailyRecord>('dailyData').clear();
      await Hive.box<List<EatenFood>>('mealFoodsBox').clear();
      final prefs = await SharedPreferences.getInstance();
      final refresh = prefs.getString('refresh_token');
      if (refresh != null) {
        final res = await http.post(
          Uri.parse('${Config.baseUrl}/logout'),
          headers: {
            'Content-Type': 'application/json',
            'Refresh-Token': refresh,
          },
        );
        debugPrint('🔌 서버 로그아웃 응답: ${res.statusCode}');
      }

      await UserApi.instance.logout();
      debugPrint('✅ 카카오 로그아웃 완료');
      await prefs.clear();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);
    } catch (e) {
      debugPrint('❌ 로그아웃 실패: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('로그아웃에 실패했습니다.')));
    }
  }
}
*/
