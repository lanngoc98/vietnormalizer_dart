/// English to Vietnamese transliterator.
///
/// Ported from nghitts/src/utils/transliterator.js via the Python port.
/// Converts English words to Vietnamese phonetic transliteration using a rule-based approach.
library;

import 'detector.dart';

// Each rule is a (pattern, replacement) record.
typedef _Rule = (RegExp, String);

// High priority rules: special endings and consonant clusters.
final List<_Rule> _highPriorityRules = [
  (RegExp(r'tion$'), 'ân'),
  (RegExp(r'sion$'), 'ân'),
  (RegExp(r'age$'), 'ây'),
  (RegExp(r'ing$'), 'ing'),
  (RegExp(r'ture$'), 'chờ'),
  (RegExp(r'cial$'), 'xô'),
  (RegExp(r'tial$'), 'xô'),
  (RegExp(r'aught'), 'ót'),
  (RegExp(r'ought'), 'ót'),
  (RegExp(r'ound'), 'ao'),
  (RegExp(r'ight'), 'ai'),
  (RegExp(r'eigh'), 'ây'),
  (RegExp(r'ough'), 'ao'),
  (RegExp(r'\bst(?!r)'), 't'),
  (RegExp(r'\bstr'), 'tr'),
  (RegExp(r'\bsch'), 'c'),
  (RegExp(r'\bsc(?=h)'), 'c'),
  (RegExp(r'\bsc|\bsk'), 'c'),
  (RegExp(r'\bsp'), 'p'),
  (RegExp(r'\btr'), 'tr'),
  (RegExp(r'\bbr'), 'r'),
  (RegExp(r'\bcr|\bpr|\bgr|\bdr|\bfr'), 'r'),
  (RegExp(r'\bbl|\bcl|\bsl|\bpl'), 'l'),
  (RegExp(r'\bfl'), 'ph'),
  (RegExp(r'ck'), 'c'),
  (RegExp(r'sh'), 's'),
  (RegExp(r'ch'), 'ch'),
  (RegExp(r'th'), 'th'),
  (RegExp(r'ph'), 'ph'),
  (RegExp(r'wh'), 'q'),
  (RegExp(r'qu'), 'q'),
  (RegExp(r'kn'), 'n'),
  (RegExp(r'wr'), 'r'),
];

// Ending rules: only apply at end of word.
final List<_Rule> _endingRules = [
  (RegExp(r'le$'), 'ồ'),
  (RegExp(r'ook$'), 'úc'),
  (RegExp(r'ood$'), 'út'),
  (RegExp(r'ool$'), 'un'),
  (RegExp(r'oom$'), 'um'),
  (RegExp(r'oon$'), 'un'),
  (RegExp(r'oot$'), 'út'),
  (RegExp(r'iend$'), 'en'),
  (RegExp(r'end$'), 'en'),
  (RegExp(r'eau$'), 'iu'),
  (RegExp(r'ail$'), 'ain'),
  (RegExp(r'ain$'), 'ain'),
  (RegExp(r'ait$'), 'ât'),
  (RegExp(r'oat$'), 'ốt'),
  (RegExp(r'oad$'), 'ốt'),
  (RegExp(r'oal$'), 'ôn'),
  (RegExp(r'eep$'), 'íp'),
  (RegExp(r'eet$'), 'ít'),
  (RegExp(r'eel$'), 'in'),
  (RegExp(r'atch$'), 'át'),
  (RegExp(r'etch$'), 'éch'),
  (RegExp(r'itch$'), 'ích'),
  (RegExp(r'otch$'), 'ốt'),
  (RegExp(r'utch$'), 'út'),
  (RegExp(r'edge$'), 'ét'),
  (RegExp(r'idge$'), 'ít'),
  (RegExp(r'odge$'), 'ót'),
  (RegExp(r'udge$'), 'út'),
  (RegExp(r'ack$'), 'ác'),
  (RegExp(r'eck$'), 'éc'),
  (RegExp(r'ick$'), 'ích'),
  (RegExp(r'ock$'), 'óc'),
  (RegExp(r'uck$'), 'úc'),
  (RegExp(r'ash$'), 'át'),
  (RegExp(r'esh$'), 'ét'),
  (RegExp(r'ish$'), 'ít'),
  (RegExp(r'osh$'), 'ốt'),
  (RegExp(r'ush$'), 'út'),
  (RegExp(r'ath$'), 'át'),
  (RegExp(r'eth$'), 'ét'),
  (RegExp(r'ith$'), 'ít'),
  (RegExp(r'oth$'), 'ót'),
  (RegExp(r'uth$'), 'út'),
  (RegExp(r'ate$'), 'ây'),
  (RegExp(r'ete$'), 'ét'),
  (RegExp(r'ite$'), 'ai'),
  (RegExp(r'ote$'), 'ốt'),
  (RegExp(r'ute$'), 'út'),
  (RegExp(r'ade$'), 'ây'),
  (RegExp(r'ede$'), 'ét'),
  (RegExp(r'ide$'), 'ai'),
  (RegExp(r'ode$'), 'ốt'),
  (RegExp(r'ude$'), 'út'),
  (RegExp(r'ake$'), 'ây'),
  (RegExp(r'ame$'), 'am'),
  (RegExp(r'ane$'), 'an'),
  (RegExp(r'ape$'), 'ếp'),
  (RegExp(r'eke$'), 'ét'),
  (RegExp(r'eme$'), 'êm'),
  (RegExp(r'ene$'), 'en'),
  (RegExp(r'ike$'), 'íc'),
  (RegExp(r'ime$'), 'am'),
  (RegExp(r'ine$'), 'ai'),
  (RegExp(r'oke$'), 'ốc'),
  (RegExp(r'ome$'), 'om'),
  (RegExp(r'one$'), 'oăn'),
  (RegExp(r'uke$'), 'ấc'),
  (RegExp(r'ume$'), 'uym'),
  (RegExp(r'une$'), 'uyn'),
  (RegExp(r'ase$'), 'ây'),
  (RegExp(r'ise$'), 'ai'),
  (RegExp(r'ose$'), 'âu'),
  (RegExp(r'all$'), 'âu'),
  (RegExp(r'ell$'), 'eo'),
  (RegExp(r'ill$'), 'iu'),
  (RegExp(r'oll$'), 'ôn'),
  (RegExp(r'ull$'), 'un'),
  (RegExp(r'ang$'), 'ang'),
  (RegExp(r'eng$'), 'ing'),
  (RegExp(r'ong$'), 'ong'),
  (RegExp(r'ung$'), 'âng'),
  (RegExp(r'air$'), 'e'),
  (RegExp(r'ear$'), 'ia'),
  (RegExp(r'ire$'), 'ai'),
  (RegExp(r'ure$'), 'iu'),
  (RegExp(r'our$'), 'ao'),
  (RegExp(r'ore$'), 'o'),
  (RegExp(r'ound$'), 'ao'),
  (RegExp(r'ight$'), 'ai'),
  (RegExp(r'aught$'), 'ót'),
  (RegExp(r'ought$'), 'ót'),
  (RegExp(r'eigh$'), 'ây'),
  (RegExp(r'ork$'), 'ót'),
  (RegExp(r'ee$'), 'i'),
  (RegExp(r'ea$'), 'i'),
  (RegExp(r'oo$'), 'u'),
  (RegExp(r'oa$'), 'oa'),
  (RegExp(r'oe$'), 'oe'),
  (RegExp(r'ai$'), 'ai'),
  (RegExp(r'ay$'), 'ay'),
  (RegExp(r'au$'), 'au'),
  (RegExp(r'aw$'), 'â'),
  (RegExp(r'ei$'), 'ây'),
  (RegExp(r'ey$'), 'ây'),
  (RegExp(r'oi$'), 'oi'),
  (RegExp(r'oy$'), 'oi'),
  (RegExp(r'ou$'), 'u'),
  (RegExp(r'ow$'), 'ô'),
  (RegExp(r'ue$'), 'ue'),
  (RegExp(r'ui$'), 'ui'),
  (RegExp(r'ie$'), 'ai'),
  (RegExp(r'eu$'), 'iu'),
  (RegExp(r'ar$'), 'a'),
  (RegExp(r'er$'), 'ơ'),
  (RegExp(r'ir$'), 'ơ'),
  (RegExp(r'or$'), 'o'),
  (RegExp(r'ur$'), 'ơ'),
  (RegExp(r'al$'), 'an'),
  (RegExp(r'el$'), 'eo'),
  (RegExp(r'il$'), 'iu'),
  (RegExp(r'ol$'), 'ôn'),
  (RegExp(r'ul$'), 'un'),
  (RegExp(r'ab$'), 'áp'),
  (RegExp(r'ad$'), 'át'),
  (RegExp(r'ag$'), 'ác'),
  (RegExp(r'ak$'), 'át'),
  (RegExp(r'ap$'), 'áp'),
  (RegExp(r'at$'), 'át'),
  (RegExp(r'eb$'), 'ép'),
  (RegExp(r'ed$'), 'ét'),
  (RegExp(r'eg$'), 'ét'),
  (RegExp(r'ek$'), 'éc'),
  (RegExp(r'ep$'), 'ép'),
  (RegExp(r'et$'), 'ét'),
  (RegExp(r'ib$'), 'íp'),
  (RegExp(r'id$'), 'ít'),
  (RegExp(r'ig$'), 'íc'),
  (RegExp(r'ik$'), 'íc'),
  (RegExp(r'ip$'), 'íp'),
  (RegExp(r'it$'), 'ít'),
  (RegExp(r'ob$'), 'óp'),
  (RegExp(r'od$'), 'ót'),
  (RegExp(r'og$'), 'óc'),
  (RegExp(r'ok$'), 'óc'),
  (RegExp(r'op$'), 'óp'),
  (RegExp(r'ot$'), 'ót'),
  (RegExp(r'ub$'), 'úp'),
  (RegExp(r'ud$'), 'út'),
  (RegExp(r'ug$'), 'úc'),
  (RegExp(r'uk$'), 'úc'),
  (RegExp(r'up$'), 'úp'),
  (RegExp(r'ut$'), 'út'),
  (RegExp(r'am$'), 'am'),
  (RegExp(r'an$'), 'an'),
  (RegExp(r'em$'), 'em'),
  (RegExp(r'en$'), 'en'),
  (RegExp(r'im$'), 'im'),
  (RegExp(r'in$'), 'in'),
  (RegExp(r'om$'), 'om'),
  (RegExp(r'on$'), 'on'),
  (RegExp(r'um$'), 'âm'),
  (RegExp(r'un$'), 'ân'),
  (RegExp(r'as$'), 'ẹt'),
  (RegExp(r'es$'), 'ẹt'),
  (RegExp(r'is$'), 'ít'),
  (RegExp(r'os$'), 'ọt'),
  (RegExp(r'us$'), 'ợt'),
  (RegExp(r'aa$'), 'a'),
  (RegExp(r'ii$'), 'i'),
  (RegExp(r'uu$'), 'u'),
];

// General single-character rules.
final List<_Rule> _generalRules = [
  (RegExp(r'j'), 'd'),
  (RegExp(r'z'), 'd'),
  (RegExp(r'w'), 'u'),
  (RegExp(r'x'), 'x'),
  (RegExp(r'v'), 'v'),
  (RegExp(r'f'), 'ph'),
  (RegExp(r's'), 'x'),
  (RegExp(r'c'), 'k'),
  (RegExp(r'q'), 'ku'),
  (RegExp(r'a'), 'a'),
  (RegExp(r'e'), 'e'),
  (RegExp(r'i'), 'i'),
  (RegExp(r'o'), 'o'),
  (RegExp(r'u'), 'u'),
];

const _vowels =
    'aeiouăâêôơưáàảãạắằẳẵặấầẩẫậéèẻẽẹếềểễệíìỉĩịóòỏõọốồổỗộớờởỡợúùủũụứừửữựýỳỷỹỵ';
final RegExp _syllablePattern = RegExp(
  '([^$_vowels]*[$_vowels]+[ptcmngs]?(?![$_vowels]))',
);
final RegExp _consonantYPattern = RegExp(r'([bcdfghjklmnpqrstvwxz])y');
final RegExp _yEndPattern = RegExp(r'y$');
final RegExp _doubleConsonantPattern = RegExp(r'([brlptdgmnckxsvfzjwqh])\1+');
const Set<String> _validConsonantPairs = {
  'ch',
  'th',
  'ph',
  'sh',
  'ng',
  'tr',
  'nh',
  'gh',
  'kh',
};
const Set<String> _consonants = {
  'b',
  'c',
  'd',
  'f',
  'g',
  'h',
  'j',
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
  'w',
  'x',
  'z',
};
const Set<String> _validEndings = {'p', 't', 'c', 'm', 'n', 'g', 's'};

String _applyRules(String w, List<_Rule> rules) {
  for (final (pattern, replacement) in rules) {
    w = w.replaceAll(pattern, replacement);
  }
  return w;
}

String _cleanConsonantClusters(String p) {
  p = p.replaceAllMapped(_doubleConsonantPattern, (m) => m.group(1)!);

  final result = StringBuffer();
  int i = 0;
  while (i < p.length) {
    if (i < p.length - 1 &&
        _consonants.contains(p[i]) &&
        _consonants.contains(p[i + 1])) {
      final pair = p[i] + p[i + 1];
      if (_validConsonantPairs.contains(pair)) {
        result.write(pair);
        i += 2;
      } else {
        result.write(p[i + 1]);
        i += 2;
      }
    } else {
      result.write(p[i]);
      i++;
    }
  }
  return result.toString();
}

String _applyCkRule(String p) {
  if (p.startsWith('ch') ||
      p.startsWith('th') ||
      p.startsWith('ph') ||
      p.startsWith('sh')) {
    return p;
  }
  if (p.startsWith('k') || p.startsWith('c')) {
    final nextChar = p.length > 1 ? p[1] : '';
    final useK = nextChar == 'i' || nextChar == 'e' || nextChar == 'y';
    return '${useK ? 'k' : 'c'}${p.substring(1)}';
  }
  return p;
}

String _filterEnding(String p) {
  if (p.length > 1 && !_vowels.contains(p[p.length - 1])) {
    final last = p[p.length - 1];
    if (!_validEndings.contains(last)) {
      if (last == 'l') return '${p.substring(0, p.length - 1)}n';
      return p.substring(0, p.length - 1);
    }
  }
  return p;
}

String _processSyllable(String s) {
  s = s.trim();
  if (s.isEmpty) return '';

  if (s.startsWith('y')) s = 'd${s.substring(1)}';

  s = _applyRules(s, _highPriorityRules);
  s = _applyRules(s, _endingRules);
  s = _applyRules(s, _generalRules);

  s = s.replaceAllMapped(_consonantYPattern, (m) => '${m.group(1)}i');
  s = s.replaceAll(_yEndPattern, 'i');

  s = _cleanConsonantClusters(s);
  s = _applyCkRule(s);
  s = _filterEnding(s);

  return s;
}

/// Converts an English word to Vietnamese phonetic transliteration.
String englishToVietnamese(String word) {
  if (word.isEmpty) return '';

  var w = word.toLowerCase().trim();

  if (w.startsWith('y')) w = 'd${w.substring(1)}';
  if (w.startsWith('d')) w = 'đ${w.substring(1)}';

  w = _applyRules(w, _highPriorityRules);
  w = _applyRules(w, _endingRules);
  w = _applyRules(w, _generalRules);

  w = w.replaceAllMapped(_consonantYPattern, (m) => '${m.group(1)}i');
  w = w.replaceAll(_yEndPattern, 'i');

  final parts = _syllablePattern.allMatches(w).map((m) => m.group(0)!).toList();
  if (parts.isEmpty) return w;

  final finalParts = parts
      .map(_processSyllable)
      .where((p) => p.isNotEmpty)
      .toList();
  return finalParts.join('-');
}

/// Transliterates a word from English to Vietnamese.
/// If the word is already Vietnamese, returns it unchanged.
String transliterateWord(String word) {
  if (word.isEmpty) return word;
  if (isVietnameseWord(word)) return word;
  return englishToVietnamese(word);
}
