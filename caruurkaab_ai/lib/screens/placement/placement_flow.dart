import 'dart:math';

import 'package:caruurkaab_ai/screens/learning/student_dashboard.dart';
import 'package:flutter/material.dart';
import '../../services/student_class_service.dart';

class PlacementFlowScreen extends StatefulWidget {
  const PlacementFlowScreen({super.key});

  @override
  State<PlacementFlowScreen> createState() => _PlacementFlowScreenState();
}

class _PlacementFlowScreenState extends State<PlacementFlowScreen> {
  static const int _placementQuestionCount = 50;

  final Random _random = Random();
  int _step = 0;
  int _questionIndex = 0;
  int _score = 0;

  int? _selectedOptionIndex;

  String _assignedClass = "";
  late final List<Map<String, dynamic>> _questions;
  final Map<String, int> _subjectTotals = {};
  final Map<String, int> _subjectScores = {};

  @override
  void initState() {
    super.initState();
    _questions = _buildRandomQuestionSet();
    for (final question in _questions) {
      final subject = (question["subject"] as String?) ?? "Kale";
      _subjectTotals[subject] = (_subjectTotals[subject] ?? 0) + 1;
      _subjectScores.putIfAbsent(subject, () => 0);
    }
  }

  List<Map<String, dynamic>> _buildRandomQuestionSet() {
    final mathQuestions = _buildMathQuestions();
    final generalKnowledgeQuestions = _buildGeneralKnowledgeQuestions();
    final textMatchingQuestions = _buildTextMatchingQuestions();
    final imageQuestions = _buildImageQuestions();

    mathQuestions.shuffle(_random);
    generalKnowledgeQuestions.shuffle(_random);
    textMatchingQuestions.shuffle(_random);
    imageQuestions.shuffle(_random);

    // Su'aalaha guud ha badnaadaan, balse random ha noqdaan mar kasta.
    final selectedGeneral = generalKnowledgeQuestions
        .take(min(34, generalKnowledgeQuestions.length))
        .toList();
    final selectedTextMatching = textMatchingQuestions
        .take(min(8, textMatchingQuestions.length))
        .toList();
    final selectedMath = mathQuestions
        .take(min(4, mathQuestions.length))
        .toList();
    final selectedImages = imageQuestions
        .take(min(4, imageQuestions.length))
        .toList();

    final selected = <Map<String, dynamic>>[
      ...selectedGeneral,
      ...selectedTextMatching,
      ...selectedMath,
      ...selectedImages,
    ];

    final remainingPool = <Map<String, dynamic>>[
      ...generalKnowledgeQuestions.skip(selectedGeneral.length),
      ...textMatchingQuestions.skip(selectedTextMatching.length),
      ...mathQuestions.skip(selectedMath.length),
      ...imageQuestions.skip(selectedImages.length),
    ]..shuffle(_random);

    if (selected.length < _placementQuestionCount) {
      final needed = _placementQuestionCount - selected.length;
      selected.addAll(remainingPool.take(min(needed, remainingPool.length)));
    }

    selected.shuffle(_random);
    return selected
        .take(min(_placementQuestionCount, selected.length))
        .toList();
  }

  List<Map<String, dynamic>> _buildMathQuestions() {
    final raw = <Map<String, dynamic>>[
      {"q": "4 + 4 = ?", "a": 8},
      {"q": "7 + 3 = ?", "a": 10},
      {"q": "6 + 2 = ?", "a": 8},
      {"q": "7 - 1 = ?", "a": 6},
      {"q": "9 - 4 = ?", "a": 5},
      {"q": "8 - 3 = ?", "a": 5},
      {"q": "Immisa tufaax ayaad aragtaa?", "a": 2, "emoji": "🍎 🍎"},
    ];

    return raw.map((item) {
      final answer = (item["a"] as int).toString();
      final options = _buildNumberOptions(answer, 4);
      return {
        "subject": "Xisaab",
        "type": "mcq",
        "question": item["q"],
        "subQuestion": item["emoji"] ?? "Xisaab",
        "options": options,
        "correctIndex": options.indexOf(answer),
      };
    }).toList();
  }

  List<Map<String, dynamic>> _buildGeneralKnowledgeQuestions() {
    final raw = <Map<String, dynamic>>[
      {
        "question": "Soomaaliya waxay xorriyadda qaadatay?",
        "options": ["1912", "1960", "2000", "2020"],
        "answer": "1960",
      },
      {
        "question": "Madaxweynihii ugu horreeyay ee Soomaaliya waa?",
        "options": [
          "Aden Abdullah Osman Daar",
          "Abdirashid Ali Sharmarke",
          "Mohamed Siad Barre",
          "Muhammad Haji Ibrahim Egal",
        ],
        "answer": "Aden Abdullah Osman Daar",
      },
      {
        "question": "Dagaalkii 1aad ee Adduunka wuxuu billowday sanadkee?",
        "options": ["1912", "1914", "1918", "1939"],
        "answer": "1914",
      },
      {
        "question": "Wabiga ugu dheer Soomaaliya waa kee?",
        "options": ["Shabeelle", "Jubba", "Nile", "Tana"],
        "answer": "Shabeelle",
      },
      {
        "question": "Wabiga Shabeelle muxuu kaga duwan yahay Jubba?",
        "options": [
          "Wuu ka gaaban yahay",
          "Mararka qaar ma gaaro badda",
          "Wuxuu ka yimaadaa Kenya",
          "Wuxuu maraa Kismaayo",
        ],
        "answer": "Mararka qaar ma gaaro badda",
      },
      {
        "question": "Yaa gumeysan jiray koonfurta Soomaaliya?",
        "options": ["UK", "France", "Italy", "Portugal"],
        "answer": "Italy",
      },
      {
        "question": "Dagaalkii Ogaden War wuxuu dhacay sanadkee?",
        "options": ["1960", "1977", "1991", "2000"],
        "answer": "1977",
      },
      {
        "question": "Qorraxdu subaxdii halkee ayay ka soo baxdaa?",
        "options": ["Galbeedka", "Bariga", "Koonfur", "Waqooyi"],
        "answer": "Bariga",
      },
      {
        "question": "Qorraxdu fiidkii halkee ayay u dhacdaa?",
        "options": ["Galbeedka", "Bariga", "Koonfur", "Waqooyi"],
        "answer": "Galbeedka",
      },
      {
        "question": "Caasimadda Soomaaliya waa?",
        "options": ["Hargeysa", "Muqdisho", "Baydhabo", "Kismaayo"],
        "answer": "Muqdisho",
      },
      {
        "question": "Lacagta Soomaaliya waa?",
        "options": ["Birr", "Shilin Soomaali", "Dollar", "Dinar"],
        "answer": "Shilin Soomaali",
      },
      {
        "question": "Soomaaliya waxay ku taallaa?",
        "options": [
          "Waqooyiga Afrika",
          "Geeska Afrika",
          "Bartamaha Afrika",
          "Yurub",
        ],
        "answer": "Geeska Afrika",
      },
      {
        "question": "Soomaaliya xeebteeda dheer waxay ku fidsan tahay?",
        "options": [
          "Badweynta Hindiya",
          "Badweynta Atlantic",
          "Badda Cas oo kaliya",
          "Badda Mediterranean",
        ],
        "answer": "Badweynta Hindiya",
      },
      {
        "question": "Magaalada dekedda weyn ee waqooyi waa?",
        "options": ["Berbera", "Marka", "Baraawe", "Kismaayo"],
        "answer": "Berbera",
      },
      {
        "question": "Magaalada Kismaayo waxay ku taallaa gobolka?",
        "options": ["Bari", "Jubbada Hoose", "Nugaal", "Sanaag"],
        "answer": "Jubbada Hoose",
      },
      {
        "question": "Qaaradda Soomaaliya ku taallo waa?",
        "options": ["Aasiya", "Afrika", "Yurub", "Ameerika"],
        "answer": "Afrika",
      },
      {
        "question": "Afka rasmiga ah ee ugu weyn Soomaaliya waa?",
        "options": ["Af-Soomaali", "Sawaaxili", "Amxaari", "Faransiis"],
        "answer": "Af-Soomaali",
      },
      // {
      //   "question": "Diinta ugu badan Soomaaliya waa?",
      //   "options": ["Islaam", "Masiixi", "Hindu", "Budhisam"],
      //   "answer": "Islaam",
      // },
      {
        "question": "Magaalada Hargeysa waxay ku taallaa?",
        "options": ["Waqooyi", "Koonfur", "Galbeed fog", "Xeebta dhexe"],
        "answer": "Waqooyi",
      },
      {
        "question": "Magaalada Baydhabo waxay ku taallaa?",
        "options": [
          "Bari",
          "Koonfur-galbeed",
          "Waqooyi-bari",
          "Soomaali Galbeed",
        ],
        "answer": "Koonfur-galbeed",
      },
      {
        "question": "Webiga Jubba inta badan wuxuu ku shubmaa?",
        "options": [
          "Badweynta Hindiya",
          "Badda Cas",
          "Harada Turkana",
          "Webiga Nile",
        ],
        "answer": "Badweynta Hindiya",
      },
      {
        "question": "Astaanta calanka Soomaaliya waa?",
        "options": ["Xiddig cad", "Bil iyo xiddig", "Libaax", "Qalin"],
        "answer": "Xiddig cad",
      },
      {
        "question": "Midkee ka mid ah waa magaalo Soomaaliyeed?",
        "options": ["Muqdisho", "Nairobi", "Addis Ababa", "Djibouti City"],
        "answer": "Muqdisho",
      },
      {
        "question": "Sannadka calanka Soomaaliya la sameeyay waa?",
        "options": ["1954", "1960", "1977", "1945"],
        "answer": "1954",
      },
      {
        "question": "Qofka hoggaamiya dugsi badanaa waxaa la yiraahdaa?",
        "options": ["Macallin", "Maamule", "Arday", "Dhakhtar"],
        "answer": "Maamule",
      },
      {
        "question": "Bisha Ramadaan ka dib waxaa yimaada?",
        "options": ["Ciidul Fidr", "Ciidul Adxa", "Mowliid", "Ashuura"],
        "answer": "Ciidul Fidr",
      },
      {
        "question": "Soomaaliya waxay leedahay xeebta ugu dheer Afrika.",
        "options": ["Run", "Been"],
        "answer": "Run",
      },
      {
        "question": "Soomaaliya waxay ku taallaa Geeska Afrika.",
        "options": ["Run", "Been"],
        "answer": "Run",
      },
      {
        "question": "Labada webi ee Soomaaliya waxay ka yimaadaan Itoobiya.",
        "options": ["Run", "Been"],
        "answer": "Run",
      },
      {
        "question": "Wabiga Jubba wuxuu ka yimaadaa Kenya.",
        "options": ["Run", "Been"],
        "answer": "Been",
      },
      {
        "question": "Aden Abdullah Osman Daar waa madaxweynihii 2aad.",
        "options": ["Run", "Been"],
        "answer": "Been",
      },
      {
        "question":
            "Inta badan dadka Soomaaliya waxay wadaagaan af Somali iyo diin Islam.",
        "options": ["Run", "Been"],
        "answer": "Run",
      },
      {
        "question": "Soomaaliya xuduud bay la leedahay Itoobiya.",
        "options": ["Run", "Been"],
        "answer": "Run",
      },
      {
        "question": "Badda Cas waxay ku taallaa galbeedka Soomaaliya.",
        "options": ["Run", "Been"],
        "answer": "Been",
      },
      {
        "question": "Muqdisho waa magaalo xeebeed.",
        "options": ["Run", "Been"],
        "answer": "Run",
      },
      {
        "question": "Webiga Shabeelle mar walba badda ayuu gaaraa.",
        "options": ["Run", "Been"],
        "answer": "Been",
      },
      {
        "question": "Kismaayo waxay ku taal Jubbada Hoose.",
        "options": ["Run", "Been"],
        "answer": "Run",
      },
      {
        "question": "Soomaaliya waxay xorowday 1960.",
        "options": ["Run", "Been"],
        "answer": "Run",
      },
      {
        "question": "Magaalada Berbera waxay ku taallaa koonfurta Soomaaliya.",
        "options": ["Run", "Been"],
        "answer": "Been",
      },
      {
        "question": "Calanka Soomaaliya waa buluug leh xiddig cad.",
        "options": ["Run", "Been"],
        "answer": "Run",
      },
      {
        "question": "Luqadda Carabigu waa mid ka mid ah luqadaha rasmiga ah.",
        "options": ["Run", "Been"],
        "answer": "Run",
      },
      {
        "question": "Soomaaliya waxay ku taallaa Yurub.",
        "options": ["Run", "Been"],
        "answer": "Been",
      },
      {
        "question": "Magaalada Baydhabo waxay ku taallaa waqooyi-bari.",
        "options": ["Run", "Been"],
        "answer": "Been",
      },
      {
        "question": "Dalka Soomaaliya waxaa ka jira gobollo badan.",
        "options": ["Run", "Been"],
        "answer": "Run",
      },
      {
        "question":
            "Soomaaliya waxay leedahay xeeb dhererkeedu aad u badan yahay.",
        "options": ["Run", "Been"],
        "answer": "Run",
      },
      {
        "question": "Dagaalkii Ogaden wuxuu dhacay 1977.",
        "options": ["Run", "Been"],
        "answer": "Run",
      },
      {
        "question": "Madaxweynihii ugu horreeyay wuxuu ahaa Aden Cabdulle.",
        "options": ["Run", "Been"],
        "answer": "Run",
      },
    ];

    return raw.map((item) {
      final options = (item["options"] as List).cast<String>().toList()
        ..shuffle(_random);
      final answer = item["answer"] as String;
      return {
        "subject": "Aqoonta Guud",
        "type": "mcq",
        "question": item["question"],
        "subQuestion": "Su'aalo Guud",
        "options": options,
        "correctIndex": options.indexOf(answer),
      };
    }).toList();
  }

  List<Map<String, dynamic>> _buildTextMatchingQuestions() {
    final raw = <Map<String, dynamic>>[
      {
        "question": "Isku-aadi: Caasimadda Soomaaliya waa?",
        "options": ["Muqdisho", "Hargeysa", "Nairobi", "Doha"],
        "answer": "Muqdisho",
      },
      {
        "question": "Isku-aadi: Webiga mara Baladweyne waa?",
        "options": ["Shabeelle", "Jubba", "Nile", "Tana"],
        "answer": "Shabeelle",
      },
      {
        "question": "Isku-aadi: Magaalada dekedda weyn ee waqooyi waa?",
        "options": ["Berbera", "Baydhabo", "Garoowe", "Dhuusamareeb"],
        "answer": "Berbera",
      },
      {
        "question": "Isku-aadi: 2 + 3 = ?",
        "options": ["5", "6", "7", "4"],
        "answer": "5",
      },
      {
        "question": "Isku-aadi: Midabka cirka badanaa waa?",
        "options": ["Buluug", "Casaan", "Cagaar", "Madow"],
        "answer": "Buluug",
      },
      {
        "question": "Isku-aadi: Dugsiga qofka maamula waa?",
        "options": ["Maamule", "Arday", "Kalkaaliye", "Fanaan"],
        "answer": "Maamule",
      },
      {
        "question": "Isku-aadi: 10 - 4 = ?",
        "options": ["6", "5", "7", "4"],
        "answer": "6",
      },
      {
        "question": "Isku-aadi: Bisha Ramadan kadib waxaa yimaada?",
        "options": ["Ciidul Fidr", "Mowliid", "Ashuuro", "Sannad Cusub"],
        "answer": "Ciidul Fidr",
      },
      {
        "question": "Isku-aadi: Dalka deriska la ah Soomaaliya waa?",
        "options": ["Itoobiya", "Masar", "Aljeeriya", "Liibiya"],
        "answer": "Itoobiya",
      },
      {
        "question": "Isku-aadi: 3 + 6 = ?",
        "options": ["9", "8", "10", "7"],
        "answer": "9",
      },
      {
        "question": "Isku-aadi: Waqtiga qorraxdu kasoo baxdo waa?",
        "options": ["Subax", "Galab", "Fiid", "Habeen"],
        "answer": "Subax",
      },
      {
        "question": "Isku-aadi: Xoolaha caanaha bixiya waa?",
        "options": ["Lo'", "Bisad", "Shimbir", "Kalluun"],
        "answer": "Lo'",
      },
      {
        "question": "Isku-aadi: 12 - 5 = ?",
        "options": ["7", "6", "8", "5"],
        "answer": "7",
      },
      {
        "question": "Isku-aadi: Mid ka mid ah gobollada Soomaaliya waa?",
        "options": ["Banaadir", "Kampala", "Dooxada Nile", "Mombasa"],
        "answer": "Banaadir",
      },
      {
        "question": "Isku-aadi: Qalabka wax lagu qoro waa?",
        "options": ["Qalin", "Koob", "Saxan", "Kab"],
        "answer": "Qalin",
      },
      {
        "question": "Isku-aadi: 4 x 2 = ?",
        "options": ["8", "6", "4", "10"],
        "answer": "8",
      },
      {
        "question": "Isku-aadi: Midka ka mid ah xayawaanka biyaha ku nool waa?",
        "options": ["Kalluun", "Geel", "Ri'", "Dameer"],
        "answer": "Kalluun",
      },
      {
        "question": "Isku-aadi: Magaalada Kismaayo waxay ku taal?",
        "options": ["Jubbada Hoose", "Sanaag", "Nugaal", "Awdal"],
        "answer": "Jubbada Hoose",
      },
      {
        "question": "Isku-aadi: 15 + 5 = ?",
        "options": ["20", "18", "25", "19"],
        "answer": "20",
      },
      {
        "question": "Isku-aadi: Midka ka mid ah miraha waa?",
        "options": ["Muus", "Qalin", "Buug", "Miis"],
        "answer": "Muus",
      },
    ];

    return raw.map((item) {
      final options = (item["options"] as List).cast<String>().toList()
        ..shuffle(_random);
      final answer = item["answer"] as String;
      return {
        "subject": "Isbarbardhig Qoraal",
        "type": "mcq",
        "question": item["question"],
        "subQuestion": "Isku-aadi",
        "options": options,
        "correctIndex": options.indexOf(answer),
      };
    }).toList();
  }

  List<Map<String, dynamic>> _buildImageQuestions() {
    final raw = <Map<String, dynamic>>[
      {
        "question": "Xayawaanka kore ilmahiisa ka dooro",
        "prompt": "🐐",
        "options": ["🐐", "🐦", "🐘"],
        "answer": "🐐",
      },
      {
        "question": "Cayayaanka kore midka u eg dooro hoos",
        "prompt": "🐞",
        "options": ["🐞", "🐘", "🐟"],
        "answer": "🐞",
      },
      {
        "question": "Xayawaanka biyaha ku nool dooro",
        "prompt": "🐟",
        "options": ["🦁", "🐟", "🐓"],
        "answer": "🐟",
      },
      {
        "question": "Shimbirta ka dooro saddexdan",
        "prompt": "🐦",
        "options": ["🐢", "🐦", "🐄"],
        "answer": "🐦",
      },
      {
        "question": "Xayawaanka ugaadhsada dooro",
        "prompt": "🦁",
        "options": ["🦁", "🐐", "🐇"],
        "answer": "🦁",
      },
      {
        "question": "Midabka calanka Soomaaliya ka dooro",
        "prompt": "🇸🇴",
        "options": ["🔵", "🟢", "🔴", "🟡"],
        "answer": "🔵",
      },
      {
        "question": "Miraha ka dooro xulashadan",
        "prompt": "🍌",
        "options": ["🍌", "📘", "🚗", "🏠"],
        "answer": "🍌",
      },
      {
        "question": "Qalabka wax lagu qoro ka dooro",
        "prompt": "✏️",
        "options": ["✏️", "🍎", "🐟", "⚽"],
        "answer": "✏️",
      },
      {
        "question": "Xayawaanka duula ka dooro",
        "prompt": "🐦",
        "options": ["🐦", "🐟", "🐄", "🐐"],
        "answer": "🐦",
      },
      {
        "question": "Gaadiidka waddooyinka ka dooro",
        "prompt": "🚗",
        "options": ["🚗", "🌴", "🍞", "📚"],
        "answer": "🚗",
      },
      {
        "question": "Qalabka dijitaalka ah ka dooro",
        "prompt": "💻",
        "options": ["💻", "🐪", "🍉", "🪑"],
        "answer": "💻",
      },
    ];

    return raw.map((item) {
      final options = (item["options"] as List).cast<String>().toList()
        ..shuffle(_random);
      final answer = item["answer"] as String;
      return {
        "subject": "Aqoonsi Sawir",
        "type": "mcq",
        "question": item["question"],
        "subQuestion": "Isbarbardhig sawir",
        "promptEmoji": item["prompt"],
        "options": options,
        "correctIndex": options.indexOf(answer),
      };
    }).toList();
  }

  List<String> _buildNumberOptions(String correct, int length) {
    final set = <String>{correct};
    final correctNumber = int.tryParse(correct) ?? 1;

    while (set.length < length) {
      final candidate = max(
        0,
        correctNumber + _random.nextInt(5) - 2,
      ).toString();
      set.add(candidate);
    }

    final options = set.toList()..shuffle(_random);
    return options;
  }

  Map<String, dynamic> get _currentQuestion => _questions[_questionIndex];

  bool get _canContinue {
    return _selectedOptionIndex != null;
  }

  void _startTest() {
    setState(() {
      _step = 1;
    });
  }

  void _selectMcqOption(int index) {
    setState(() {
      _selectedOptionIndex = index;
    });
  }

  Future<void> _submitQuestion() async {
    if (!_canContinue) return;

    final subject = (_currentQuestion["subject"] as String?) ?? "Kale";
    final correct = _currentQuestion["correctIndex"] as int;
    final isCorrect = _selectedOptionIndex == correct;

    if (isCorrect) {
      _score += 1;
      _subjectScores[subject] = (_subjectScores[subject] ?? 0) + 1;
    }

    if (_questionIndex < _questions.length - 1) {
      setState(() {
        _questionIndex += 1;
        _selectedOptionIndex = null;
      });
      return;
    }

    _assignedClass = _calculateAssignedClass();
    await StudentClassService.saveAssignedClass(_assignedClass);
    setState(() {
      _step = 2;
    });
  }

  String _calculateAssignedClass() {
    final percent = (_score / _questions.length) * 100;
    if (percent < 35) return "Fasalka 1";
    if (percent < 60) return "Fasalka 2";
    if (percent < 80) return "Fasalka 3";
    return "Fasalka 4";
  }

  @override
  Widget build(BuildContext context) {
    if (_step == 0) return _buildPlacementChoice();
    if (_step == 1) return _buildPlacementTest();
    if (_step == 2) return _buildPlacementResult();
    return _buildAssignedClass();
  }

  Widget _buildPlacementChoice() {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 14,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Dooro Meesha Aad Ka Bilaabayso",
                      style: TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Dooro halkii aad ka bilaabi lahayd",
                      style: TextStyle(
                        color: Color(0xFF1D5AFF),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Aan kuu helno heerka kugu habboon.",
                      style: TextStyle(
                        color: Color(0xFF4B5563),
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF4FF),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.quiz_rounded, color: Color(0xFF1D5AFF)),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Imtixaanku waa $_placementQuestionCount su'aal random ah (af-Soomaali), qof walbana way ka duwanaan karaan.",
                              style: TextStyle(
                                color: Color(0xFF1F2937),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _startTest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D5AFF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    "Bilow Imtixaanka",
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlacementTest() {
    final options = (_currentQuestion["options"] as List).cast<String>();
    final isImageQuestion =
        (_currentQuestion["promptEmoji"] as String?) != null;
    final isMathQuestion = (_currentQuestion["subject"] as String?) == "Xisaab";

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    "SU'AAL",
                    style: TextStyle(
                      color: Color(0xFF1D5AFF),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    "${_questionIndex + 1} / ${_questions.length}",
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: (_questionIndex + 1) / _questions.length,
                minHeight: 10,
                borderRadius: BorderRadius.circular(99),
                backgroundColor: const Color(0xFFE5E7EB),
                valueColor: const AlwaysStoppedAnimation(Color(0xFF1D5AFF)),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFD6E0FF)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentQuestion["question"] as String,
                      style: const TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if ((_currentQuestion["promptEmoji"] as String?) != null)
                      Container(
                        margin: const EdgeInsets.only(top: 12),
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F8F3),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF86D59D)),
                        ),
                        child: Center(
                          child: Text(
                            _currentQuestion["promptEmoji"] as String,
                            style: const TextStyle(fontSize: 46),
                          ),
                        ),
                      ),
                    if ((_currentQuestion["image"] as String?) != null) ...[
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          _currentQuestion["image"] as String,
                          height: 170,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (!isImageQuestion && !isMathQuestion)
                ...List.generate(options.length, (index) {
                  final isSelected = _selectedOptionIndex == index;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      onTap: () => _selectMcqOption(index),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFEFF4FF)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF1D5AFF)
                                : const Color(0xFFD1D5DB),
                            width: 1.4,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                options[index],
                                style: TextStyle(
                                  color: isSelected
                                      ? const Color(0xFF1D5AFF)
                                      : const Color(0xFF111827),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle,
                                color: Color(0xFF1D5AFF),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                })
              else if (isMathQuestion)
                LayoutBuilder(
                  builder: (context, constraints) {
                    final boxWidth = (constraints.maxWidth - 24) / 3;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: List.generate(options.length, (index) {
                        final isSelected = _selectedOptionIndex == index;
                        return InkWell(
                          onTap: () => _selectMcqOption(index),
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
                            width: boxWidth,
                            height: 90,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF1D4FFF)
                                  : const Color(0xFF2B8DEB),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Center(
                              child: Text(
                                options[index],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    );
                  },
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final boxWidth = (constraints.maxWidth - 12) / 2;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: List.generate(options.length, (index) {
                        final isSelected = _selectedOptionIndex == index;
                        return InkWell(
                          onTap: () => _selectMcqOption(index),
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            width: boxWidth,
                            height: 140,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFEFF4FF)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF1D5AFF)
                                    : const Color(0xFFD1D5DB),
                                width: 1.4,
                              ),
                            ),
                            child: Stack(
                              children: [
                                Center(
                                  child: Text(
                                    options[index],
                                    style: const TextStyle(fontSize: 50),
                                  ),
                                ),
                                if (isSelected)
                                  const Positioned(
                                    right: 10,
                                    top: 10,
                                    child: Icon(
                                      Icons.check_circle,
                                      color: Color(0xFF1D5AFF),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }),
                    );
                  },
                ),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _canContinue ? _submitQuestion : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D5AFF),
                    disabledBackgroundColor: const Color(0xFFA5B4FC),
                    foregroundColor: Colors.white,
                    disabledForegroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    _questionIndex == _questions.length - 1
                        ? "Xaqiiji / Confirm"
                        : "Sii wad / Next",
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlacementResult() {
    final percent = ((_score / _questions.length) * 100).round();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Column(
            children: [
              const SizedBox(height: 30),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFD6E0FF)),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE8F7EE),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.emoji_events,
                        color: Color(0xFF10B981),
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      "Hambalyo!",
                      style: TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Dhibcahaaga: $percent/100",
                      style: const TextStyle(
                        color: Color(0xFF374151),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Jawaabaha saxda ah: $_score/${_questions.length}",
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF4FF),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        "Fasalka laguu qoondeeyay: $_assignedClass",
                        style: const TextStyle(
                          color: Color(0xFF1D5AFF),
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Column(
                        children: _subjectTotals.keys.map((subject) {
                          final total = _subjectTotals[subject] ?? 0;
                          final got = _subjectScores[subject] ?? 0;
                          final subjectPercent = total == 0
                              ? 0
                              : ((got / total) * 100).round();
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFE5E7EB),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    subject,
                                    style: const TextStyle(
                                      color: Color(0xFF111827),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                Text(
                                  "$got/$total ($subjectPercent%)",
                                  style: const TextStyle(
                                    color: Color(0xFF1D5AFF),
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _step = 3;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D5AFF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    "Sii wad / Next",
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAssignedClass() {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFD6E0FF)),
                ),
                child: Column(
                  children: [
                    const Text(
                      "Heerkaaga waa",
                      style: TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _assignedClass,
                      style: const TextStyle(
                        color: Color(0xFF1D5AFF),
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Ku bilow waxbarashada heerkan.",
                      style: TextStyle(
                        color: Color(0xFF4B5563),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const StudentDashboardScreen(),
                      ),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D5AFF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    "Ku Bilow Waxbarashada",
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
