import 'package:flutter/material.dart';

import '../../utils/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const List<_PrivacySection> _sections = [
    _PrivacySection(
      title: '1. المشتريات والمعاملات المالية',
      body: 'في حال توفر عمليات دفع داخل التطبيق، تتم المعاملات '
          'بشكل آمن تماماً عبر بوابات الدفع الرسمية المعتمدة '
          '(مثل متاجر التطبيقات)، دون أن نقوم نحن بتخزين أي '
          'بيانات حساسة لبطاقات الدفع أو الحسابات المالية الخاصة بك.',
    ),
    _PrivacySection(
      title: '2. حقوق الملكية الفكرية',
      body: 'يلتزم مستخدمو تطبيق "رسمنا" بكونهم أصحاب الحقوق أو '
          'يملكون التراخيص القانونية للصور التي يقومون بعرضها، '
          'ويتحمل المستخدم وحده مسؤولية المحتوى الذي يقدمه '
          'داخل المنصة.',
    ),
    _PrivacySection(
      title: '3. أمان الجهاز',
      body: 'نظراً لعدم جمعنا لأي معلومات أو بيانات شخصية، فإنك '
          'لست عرضة لخطر تسريب البيانات أو فقدان الخصوصية من '
          'قِبل خوادمنا. بياناتك تظل معك وعلى جهازك الخاص.',
    ),
    _PrivacySection(
      title: '4. خصوصية الأطفال',
      body: 'نظراً لأن التطبيق لا يجمع أي معلومات شخصية، فهو آمن '
          'للاستخدام العام، ولا نقوم عن قصد أو غير قصد بجمع أي '
          'بيانات من أي فئة عمرية.',
    ),
    _PrivacySection(
      title: '5. الروابط الخارجية',
      body: 'قد يحتوي التطبيق على روابط لمواقع أو خدمات خارجية '
          'تابعة لأطراف ثالثة. نحن لسنا مسؤوليين عن سياسات '
          'الخصوصية أو محتوى تلك الجهات الخارجية.',
    ),
    _PrivacySection(
      title: '6. التغييرات على هذه السياسة',
      body: 'قد نقوم بتحديث سياسة الخصوصية هذه من وقت لآخر إذا '
          'استجدت ميزات جديدة في التطبيق. سيتم نشر أي تحديث '
          'هنا مباشرة، ويعتبر استمرارك في استخدام التطبيق '
          'موافقة ضمنية على البنود المحدثة.',
    ),
    _PrivacySection(
      title: '7. الأمان المبدئي',
      body: 'نحن حريصون على تقديم تجربة تقنية خفيفة وسريعة لا '
          'تستهلك موارد جهازك ولا تشكل أي تهديد لخصوصيتك '
          'الرقمية بأي شكل من الأشكال.',
    ),
    _PrivacySection(
      title: '8. المسؤولية القانونية',
      body: 'التطبيق يُقدم كما هو ("As Is") لغرض بيع وشراء الصور '
          'الرقمية، ولا يتحمل مطورو التطبيق المسؤولية عن سوء '
          'الاستخدام الفردي للمحتوى المرئي من قِبل المستخدمين.',
    ),
    _PrivacySection(
      title: '9. التواصل والدعم الفني',
      body: 'لكوننا لا نجمع بريديات إلكترونية أو معلومات اتصال، '
          'فإن أي دعم فني أو استفسار يتم حصرياً عبر قنوات '
          'التواصل المباشرة المتاحة للمطورين داخل صفحة المتجر '
          'الرسمية، ودون حفظ أي سجلات بيانات دائمة للمراسلة.',
    ),
    _PrivacySection(
      title: '10. الموافقة والقبول',
      body: 'استخدامك المستمر لتطبيق "رسمنا" يعني ضمنياً موافقتك '
          'الكاملة على هذه البنود البسيطة والمصممة خصيصاً '
          'لضمان حريتك وراحتك المطلقة.',
    ),
    _PrivacySection(
      title: '11. إخلاء المسؤولية العامة',
      body: 'نضمن لك أن تطبيق "رسمنا" لن يقوم نهائياً ببيع، أو '
          'تأجير، أو مشاركة أي بيانات تخصك لأننا ببساطة لا '
          'نقوم بجمعها أساساً، لتطفر وتستمتع بتطبيقك وأنت '
          'مطمئن تماماً!',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سياسة الخصوصية'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildIntro(),
          const SizedBox(height: 20),
          ..._sections.map(_buildSection),
          const SizedBox(height: 20),
          _buildFooter(),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, AppTheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.privacy_tip,
            color: Colors.white,
            size: 48,
          ),
          const SizedBox(height: 12),
          const Text(
            'سياسة الخصوصية',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'تاريخ السريان: أكتوبر 2026',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntro() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: const Text(
        'نحن في تطبيق "رسمنا" نؤمن بأن الخصوصية هي حق أساسي '
        'من حقوق المستخدمين. لقد صُمم هذا التطبيق ليكون بيئة '
        'آمنة وحرة لبيع وشراء الصور الرقمية، ودون أي تعقيدات '
        'تتعلق بجمع البيانات أو تتبع النشاط الشخصي.\n\n'
        'باستخدامك لتطبيق "رسمنا"، فإنك توافق على الالتزام '
        'بالبنود الموضحة في هذه السياسة:',
        style: TextStyle(
          fontSize: 13,
          height: 1.7,
        ),
      ),
    );
  }

  Widget _buildSection(_PrivacySection section) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primary.withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 22,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  section.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Text(
              section.body,
              style: const TextStyle(
                fontSize: 13,
                height: 1.7,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.success.withValues(alpha: 0.3),
        ),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.verified_user,
            color: AppTheme.success,
            size: 24,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'خصوصيتك محمية بالكامل — نحن لا نجمع أي بيانات',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.success,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacySection {
  final String title;
  final String body;
  const _PrivacySection({required this.title, required this.body});
}
