import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/locale_provider.dart';
import '../../utils/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isArabic = context.watch<LocaleProvider>().isArabic;
    final sections = isArabic ? _arabicSections : _englishSections;

    return Scaffold(
      appBar: AppBar(
        title: Text(isArabic ? 'سياسة الخصوصية' : 'Privacy Policy'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(isArabic),
          const SizedBox(height: 20),
          _buildIntro(isArabic),
          const SizedBox(height: 20),
          ...sections.map((s) => _buildSection(s, isArabic)),
          const SizedBox(height: 20),
          _buildFooter(isArabic),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // Header
  // ═══════════════════════════════════════════
  Widget _buildHeader(bool isArabic) {
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
          Text(
            isArabic ? 'سياسة الخصوصية' : 'Privacy Policy',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            isArabic
                ? 'تاريخ السريان: أكتوبر 2026'
                : 'Effective Date: October 2026',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // Intro
  // ═══════════════════════════════════════════
  Widget _buildIntro(bool isArabic) {
    final text = isArabic
        ? 'نحن في تطبيق "رسمنا" نؤمن بأن الخصوصية هي حق أساسي من حقوق '
            'المستخدمين. لقد صُمم هذا التطبيق ليكون بيئة آمنة وحرة لبيع '
            'وشراء الصور الرقمية، ودون أي تعقيدات تتعلق بجمع البيانات أو '
            'تتبع النشاط الشخصي.\n\n'
            'باستخدامك لتطبيق "رسمنا"، فإنك توافق على الالتزام بالبنود '
            'الموضحة في هذه السياسة:'
        : 'At Rasmna, we believe that privacy is a fundamental right of '
            'every user. This app is designed to be a safe and free '
            'environment for buying and selling digital images, without '
            'any complexities related to data collection or personal '
            'activity tracking.\n\n'
            'By using Rasmna, you agree to comply with the terms outlined '
            'in this policy:';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, height: 1.7),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // Section
  // ═══════════════════════════════════════════
  Widget _buildSection(_PrivacySection section, bool isArabic) {
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
            padding: EdgeInsets.only(right: isArabic ? 14 : 0, left: isArabic ? 0 : 14),
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

  // ═══════════════════════════════════════════
  // Footer
  // ═══════════════════════════════════════════
  Widget _buildFooter(bool isArabic) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.success.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.verified_user,
            color: AppTheme.success,
            size: 24,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isArabic
                  ? 'خصوصيتك محمية بالكامل — نحن لا نجمع أي بيانات'
                  : 'Your privacy is fully protected — we collect no data',
              style: const TextStyle(
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

  // ═══════════════════════════════════════════
  // Sections data — Arabic
  // ═══════════════════════════════════════════
  static const List<_PrivacySection> _arabicSections = [
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

  // ═══════════════════════════════════════════
  // Sections data — English
  // ═══════════════════════════════════════════
  static const List<_PrivacySection> _englishSections = [
    _PrivacySection(
      title: '1. Purchases and Financial Transactions',
      body: 'If in-app payments are available, all transactions are '
          'processed securely through official approved payment '
          'gateways (such as app stores). We never store any sensitive '
          'data related to your payment cards or financial accounts.',
    ),
    _PrivacySection(
      title: '2. Intellectual Property Rights',
      body: 'Users of Rasmna agree that they either own the rights or '
          'hold the legal licenses for the images they display. Each '
          'user is solely responsible for the content they upload to '
          'the platform.',
    ),
    _PrivacySection(
      title: '3. Device Security',
      body: 'Since we collect no information or personal data, you are '
          'not at risk of data leakage or loss of privacy from our '
          'servers. Your data stays with you on your own device.',
    ),
    _PrivacySection(
      title: '4. Children\'s Privacy',
      body: 'Because the app collects no personal information, it is '
          'safe for general use. We do not intentionally or '
          'unintentionally collect any data from any age group.',
    ),
    _PrivacySection(
      title: '5. External Links',
      body: 'The app may contain links to external sites or services '
          'owned by third parties. We are not responsible for the '
          'privacy policies or content of those external parties.',
    ),
    _PrivacySection(
      title: '6. Changes to This Policy',
      body: 'We may update this privacy policy from time to time as '
          'new features are added. Any updates will be posted here '
          'directly, and your continued use of the app constitutes '
          'implicit acceptance of the updated terms.',
    ),
    _PrivacySection(
      title: '7. Lightweight Security',
      body: 'We are committed to delivering a lightweight, fast '
          'technical experience that does not consume your device '
          'resources and poses no threat to your digital privacy in '
          'any way.',
    ),
    _PrivacySection(
      title: '8. Legal Responsibility',
      body: 'The app is provided "As Is" for the purpose of buying '
          'and selling digital images. The app developers are not '
          'liable for any individual misuse of visual content by '
          'users.',
    ),
    _PrivacySection(
      title: '9. Contact and Technical Support',
      body: 'Since we do not collect emails or contact information, '
          'any support or inquiry is handled exclusively through '
          'direct communication channels available to developers '
          'on the official store page, without storing any permanent '
          'data logs of the correspondence.',
    ),
    _PrivacySection(
      title: '10. Consent and Acceptance',
      body: 'Your continued use of Rasmna implies your full '
          'acceptance of these simple terms, designed specifically '
          'to ensure your absolute freedom and comfort.',
    ),
    _PrivacySection(
      title: '11. General Disclaimer',
      body: 'We guarantee that Rasmna will never sell, rent, or '
          'share any data related to you, simply because we do not '
          'collect it in the first place. Enjoy your app with '
          'complete peace of mind!',
    ),
  ];
}

class _PrivacySection {
  final String title;
  final String body;
  const _PrivacySection({required this.title, required this.body});
}
