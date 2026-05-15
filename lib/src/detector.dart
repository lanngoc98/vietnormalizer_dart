/// Vietnamese language detector - detects if a word is Vietnamese.
///
/// Ported from nghitts/src/utils/vietnamese-detector.js via the Python port.
library;

class VnLanguageDetector {
  static final RegExp _vnAccentRegex = RegExp(
    r'[àáảãạăằắẳẵặâầấẩẫậèéẻẽẹêềếểễệìíỉĩịòóỏõọôồốổỗộơờớởỡợùúủũụưừứửữựỳýỷỹỵđ]',
    caseSensitive: false,
  );

  static final Set<String> _vnOnsets = {
    'b',
    'c',
    'd',
    'đ',
    'g',
    'h',
    'k',
    'l',
    'm',
    'n',
    'p',
    'q',
    'r',
    's',
    't',
    'v',
    'x',
    'ch',
    'gh',
    'gi',
    'kh',
    'ng',
    'nh',
    'ph',
    'qu',
    'th',
    'tr',
  };

  static final Set<String> _vnEndings = {
    'p',
    't',
    'c',
    'm',
    'n',
    'ng',
    'ch',
    'nh',
  };

  static final RegExp _enSpecialChars = RegExp(r'[fwzj]', caseSensitive: false);
  static final RegExp _syllableRegex = RegExp(
    r'^([^ueoaiy]*)([ueoaiy]+)([^ueoaiy]*)$',
  );
  static final RegExp _englishVowelClusters = RegExp(r'ee|oo|ea|ae|ie');
  static final Set<String> _allowedVowelClusters = {'oa', 'oe', 'ua', 'uy'};

  bool isVietnameseWord(String word) {
    if (word.isEmpty) return false;
    final w = word.toLowerCase().trim();

    if (_vnAccentRegex.hasMatch(w)) return true;
    if (_enSpecialChars.hasMatch(w)) return false;

    final match = _syllableRegex.firstMatch(w);
    if (match == null) return false;

    final onset = match.group(1)!;
    final vowel = match.group(2)!;
    final ending = match.group(3)!;

    if (onset.isNotEmpty && !_vnOnsets.contains(onset)) return false;
    if (ending.isNotEmpty && !_vnEndings.contains(ending)) return false;

    if (_englishVowelClusters.hasMatch(vowel)) {
      if (!_allowedVowelClusters.contains(vowel)) return false;
    }

    return true;
  }
}

final _detector = VnLanguageDetector();

bool isVietnameseWord(String word) => _detector.isVietnameseWord(word);
