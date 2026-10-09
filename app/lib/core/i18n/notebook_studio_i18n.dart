import 'package:family_os/core/i18n/app_localizations.dart';

/// Bilateral (AR/EN) localization accessors for NotebookLM Studio & Grounded
/// Learning capabilities across Parent Studio (n14_studio) and Child Learning
/// World (n17_child_learn).
extension NotebookStudioLocalizations on AppLocalizations {
  bool get _isAr => localeName.toLowerCase().startsWith('ar');

  // --- Multi-Source Grounding Tray (SCR-FAT-041 / SCR-FAT-043) ---
  String get notebookSourcesHeading => _isAr
      ? 'دفتر المصادر الموثّقة (حدد المصادر النشطة للتوليد)'
      : 'Grounded notebook sources (select active sources)';

  String notebookSourcesActiveCount(int active, int total) => _isAr
      ? 'المصادر المفعّلة في التوليد: $active من $total'
      : 'Active grounding sources: $active of $total';

  String get notebookSourceCameraPage47 => _isAr
      ? 'صورة الكتاب: الكسور الاعتيادية (ص 47)'
      : 'Book scan: Common Fractions (p. 47)';

  String get notebookSourceTeacherPdf => _isAr
      ? 'ملزمة المعلم: تدريبات توحيد المقامات.pdf'
      : 'Teacher worksheet: Denominator Practice.pdf';

  String get notebookSourceFatherVoice => _isAr
      ? 'ملاحظة الأب الصوتية: شرح البيتزا لسعد وخالد'
      : 'Father voice note: Pizza analogy for Saad & Khaled';

  String notebookSourcePassagesBadge(int count) =>
      _isAr ? '$count مقاطع موثقة' : '$count grounded passages';

  // --- Flexibility Engine Controls (SCR-FAT-043) ---
  String get notebookFlexibilityTitle => _isAr
      ? 'محرك المرونة والتخصيص الذكي (NotebookLM)'
      : 'Smart flexibility & adaptation engine (NotebookLM)';

  String get notebookDepthLabel => _isAr ? 'عمق المعالجة:' : 'Study depth:';

  String get notebookDepthQuick =>
      _isAr ? 'ملخص سريع (3 د)' : 'Quick briefing (3m)';

  String get notebookDepthStandard =>
      _isAr ? 'درس قياسي متكامل' : 'Standard lesson';

  String get notebookDepthExam =>
      _isAr ? 'مراجعة ليلة الاختبار' : 'Exam crunch';

  String get notebookToneLabel =>
      _isAr ? 'أسلوب الشرح والبودكاست:' : 'Explanation & audio tone:';

  String get notebookToneFusha =>
      _isAr ? 'فصحى مبسطة دافئة' : 'Warm simple Arabic';

  String get notebookToneGulf =>
      _isAr ? 'شرح تربوي قريب للطفل' : 'Child-friendly conversational';

  String get notebookToneBilingual =>
      _isAr ? 'ثنائي اللغة للمصطلحات (AR/EN)' : 'Bilingual STEM terms (AR/EN)';

  String get notebookStrictGroundingLabel => _isAr
      ? 'التزام صارم بمصادر الدفتر فقط (صفر هلوسة من خارج المنهج)'
      : 'Strict notebook-source grounding only (zero external hallucination)';

  // --- New NotebookLM Output Kinds (SCR-FAT-043) ---
  String get generationOutputsStudyGuideFaqTitle => _isAr
      ? 'دليل المراجعة وأهم الأسئلة المتوقعة (FAQ)'
      : 'Study guide & FAQ briefing';

  String get generationOutputsStudyGuideFaqSub => _isAr
      ? 'ملخص تنفيذي + قاموس مصطلحات + أهم 10 أسئلة وإجاباتها بالصفحة'
      : 'Executive briefing + glossary + top 10 grounded Q&As with citations';

  String get generationOutputsAudioOverviewTitle => _isAr
      ? 'بودكاست حواري تفاعلي (مع ميزة ارفع يدك ✋)'
      : 'Interactive Audio Overview (with Raise Hand ✋)';

  String get generationOutputsAudioOverviewSub => _isAr
      ? 'حوار صوتي دافئ بين معلمين يشرحان الدرس مع إمكانية مقاطعة الطفل للسؤال'
      : 'Two-host engaging dialogue explaining the source with child Q&A interruption';

  String get generationOutputsConceptMindMapTitle => _isAr
      ? 'خريطة مفاهيمية تفاعلية (Mind Map)'
      : 'Interactive concept mind map';

  String get generationOutputsConceptMindMapSub => _isAr
      ? 'شجرة علاقات بصرية قابلة للتوسيع تربط كل مفهوم بصفحته وأسئلته'
      : 'Expandable visual concept tree linking every node to its source page';

  String get generationOutputsTimelineTitle => _isAr
      ? 'خط زمني وتسلسل خطوات (Timeline)'
      : 'Interactive step & event timeline';

  String get generationOutputsTimelineSub => _isAr
      ? 'ترتيب زمني ومنطقي للخطوات والأحداث موثق بالمقتطفات'
      : 'Chronological and logical step sequence grounded in source excerpts';

  // --- Preview & Inline Citations (SCR-FAT-044) ---
  String get previewApproveCitationsHeading => _isAr
      ? 'التوثيق المرجعي اللحظي (اضغط على الشارة لمعاينة فقرة المصدر)'
      : 'Inline source citations (tap a badge to inspect source excerpt)';

  String previewApproveCitationChipLabel(String ref) =>
      _isAr ? 'المصدر: $ref' : 'Source: $ref';

  String get previewApproveCitationSelectedTitle =>
      _isAr ? 'مقتطف المصدر الموثق:' : 'Verified source excerpt:';

  String get previewApproveCitationExcerptP47 => _isAr
      ? '«عند جمع كسرين لهما المقام نفسه، نجمع البسطين فقط ويبقى المقام كما هو: 2/7 + 3/7 = 5/7.» (كتاب الرياضيات - ص 47)'
      : '"When adding fractions with the same denominator, add the numerators and keep the denominator: 2/7 + 3/7 = 5/7." (Math Textbook - p. 47)';

  String get previewApproveCitationExcerptWorksheet => _isAr
      ? '«إذا اختلف المقامان، نوجد المضاعف المشترك الأصغر أولاً قبل عملية الجمع.» (ملزمة المعلم - ص 2)'
      : '"If denominators differ, find the least common multiple first before adding." (Teacher Worksheet - p. 2)';

  String get previewApproveAudioOverviewCardTitle => _isAr
      ? 'معاينة البودكاست الحواري ومخطط المفاهيم (تجهيز محلي)'
      : 'Audio Overview & Concept Map preview (local staging)';

  String get previewApproveAudioOverviewCardBody => _isAr
      ? 'حوار ثنائي مبسط (3:20 د) + خريطة مفاهيم الكسور (4 عقد موثقة من ص 47) — جاهز للاعتماد.'
      : 'Two-host dialogue (3m 20s) + Fractions concept map (4 grounded nodes from p. 47) — ready for father approval.';

  // --- Child Lesson Multi-Modal NotebookLM Views (SCR-CHD-013) ---
  String get childLessonModeReader =>
      _isAr ? '📖 القراءة الموثقة' : '📖 Grounded reader';

  String get childLessonModeAudio =>
      _isAr ? '🎙️ البودكاست التفاعلي' : '🎙️ Audio overview';

  String get childLessonModeMindMap =>
      _isAr ? '🧠 الخريطة الذهنية' : '🧠 Concept map';

  String get childLessonCitationBadge =>
      _isAr ? 'موثق من كتابك: ص 47 [1]' : 'Grounded in textbook: p. 47 [1]';

  String get childLessonPinNoteCta => _isAr
      ? '📌 ثبّت هذه الفكرة في لوحة ملاحظاتي'
      : '📌 Pin insight to my noteboard';

  String get childLessonNotePinnedToast => _isAr
      ? 'تم تثبيت الملاحظة في لوحتك لتحويلها إلى بطاقة حفظ!'
      : 'Pinned to your noteboard — ready to convert into a flashcard!';

  String get childLessonAudioHostLine => _isAr
      ? '🎙️ المعلم أ والحاور ب: «تخيل يا بطل أن المقام هو حجم قطعة البيتزا، لذلك لا يتغير عند الجمع!»'
      : '🎙️ Host A & Host B: "Imagine the denominator is the slice size — that is why it stays the same when we add!"';

  String get childLessonAudioHandRaiseCta => _isAr
      ? '✋ ارفع يدك لمقاطعة الحوار والسؤال عن هذه النقطة'
      : '✋ Raise hand to pause & ask the Socratic tutor about this point';

  String get childLessonMindMapRoot => _isAr
      ? 'جمع الكسور الاعتيادية (ص 47)'
      : 'Adding Common Fractions (p. 47)';

  String get childLessonMindMapBranchSame => _isAr
      ? 'مقامات متشابهة ← نجمع البسطين فقط (2/7 + 3/7 = 5/7)'
      : 'Same denominator → add numerators only (2/7 + 3/7 = 5/7)';

  String get childLessonMindMapBranchDiff => _isAr
      ? 'مقامات مختلفة ← نوحّد المقام بالمضاعف المشترك أولاً'
      : 'Different denominators → find common denominator (LCM) first';

  // --- Child Socratic Tutor Source Grounding (SCR-CHD-017) ---
  String get childTutorGroundedSourcesBadge => _isAr
      ? '🔒 مقيّد بـ 3 مصادر معتمدة من أبيك (ص 47 + الملزمة) — لا إجابات جاهزة'
      : '🔒 Grounded in 3 father-approved sources (p. 47 + worksheet) — hints only';

  String get childTutorCitationChipP47 => _isAr
      ? '📄 شاهد المرجع: كتاب الرياضيات ص 47 [1]'
      : '📄 View citation: Math Textbook p. 47 [1]';

  String get childTutorCitationChipWorksheet => _isAr
      ? '📄 شاهد المرجع: ملزمة توحيد المقامات ص 2 [2]'
      : '📄 View citation: Denominator Worksheet p. 2 [2]';

  // --- Child Flashcards Noteboard P1 Conversion (SCR-CHD-014) ---
  String get childFlashcardsNoteboardHeading => _isAr
      ? '📌 لوحة ملاحظاتي المثبتة من الدرس (صناعة بطاقاتي الخاصة P1)'
      : '📌 My pinned lesson notes (create personal flashcards P1)';

  String get childFlashcardsConvertNoteCta => _isAr
      ? '✨ حوّل ملاحظتي المثبتة إلى بطاقة حفظ جديدة'
      : '✨ Convert pinned note into a personal flashcard';

  String get childFlashcardsNoteConvertedToast => _isAr
      ? 'تمت إضافة بطاقتك الشخصية من ملاحظة ص 47 إلى مجموعتك!'
      : 'Added your personal flashcard from p. 47 note to your deck!';
}
