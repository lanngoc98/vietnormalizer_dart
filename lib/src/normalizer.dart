/// Vietnamese text normalizer with dictionary support and transliteration.
///
/// Ported from the Python `vietnormalizer` package.
/// Processing pipeline:
/// 1. Clean text and process Vietnamese (numbers, dates, times, etc.)
/// 2. Handle uppercase codes (acronyms/abbreviations)
/// 3. Lowercase normalization
/// 4. Replace acronyms from dictionary
/// 5. Replace non-Vietnamese words from dictionary
/// 6. Transliterate remaining non-Vietnamese words (rule-based)
library;

import 'dart:io';
import 'dart:isolate';

import 'processor.dart';
import 'detector.dart';
import 'transliterator.dart';

/// Maps a letter (A-Z) to its Vietnamese spoken name.
const Map<String, String> letterNames = {
  'A': 'a', 'B': 'bê', 'C': 'xê', 'D': 'đê', 'E': 'ê',
  'F': 'ép', 'G': 'giê', 'H': 'hát', 'I': 'i', 'J': 'giây',
  'K': 'ca', 'L': 'e-lờ', 'M': 'em', 'N': 'en', 'O': 'o',
  'P': 'pê', 'Q': 'cu', 'R': 'e-rờ', 'S': 'ét', 'T': 'tê',
  'U': 'u', 'V': 'vê', 'W': 'vê kép', 'X': 'ích', 'Y': 'i',
  'Z': 'dét',
};

// Matches words including Vietnamese characters (U+00C0..U+1EFF).
final RegExp _wordBoundaryRegex = RegExp(r'[\wÀ-ỿ]+');

// 2+ uppercase letters/digits, starting with a letter.
final RegExp _uppercaseCodePattern = RegExp(r'\b([A-Z][A-Z0-9]+)\b');

class VietnameseNormalizer {
  final VietnameseTextProcessor _processor;
  final bool enableTransliteration;

  /// Acronym map: lowercase acronym → Vietnamese expansion.
  final Map<String, String> acronymMap;

  /// Non-Vietnamese word map: lowercase word → Vietnamese pronunciation.
  final Map<String, String> nonVietnameseMap;

  // Built from nonVietnameseMap — lowercase key lookup.
  late final Map<String, String> _replacements;

  VietnameseNormalizer({
    Map<String, String>? acronymMap,
    Map<String, String>? nonVietnameseMap,
    this.enableTransliteration = true,
  })  : _processor = VietnameseTextProcessor(),
        acronymMap = acronymMap ?? {},
        nonVietnameseMap = nonVietnameseMap ?? {} {
    _buildReplacementDict();
  }

  void _buildReplacementDict() {
    _replacements = {
      for (final e in nonVietnameseMap.entries) e.key.toLowerCase(): e.value,
    };
  }

  // ---------------------------------------------------------------------------
  // Static factories
  // ---------------------------------------------------------------------------

  /// Creates a normalizer by loading CSV data from [acronymsPath] and
  /// [nonVietnameseWordsPath]. If paths are omitted, tries to locate the
  /// bundled data files via the package URI.
  static Future<VietnameseNormalizer> create({
    String? acronymsPath,
    String? nonVietnameseWordsPath,
    bool enableTransliteration = true,
  }) async {
    String? resolvedAcronyms = acronymsPath;
    String? resolvedWords = nonVietnameseWordsPath;

    if (resolvedAcronyms == null || resolvedWords == null) {
      final dataDir = await _findBundledDataDir();
      resolvedAcronyms ??= dataDir != null ? '$dataDir/acronyms.csv' : null;
      resolvedWords ??= dataDir != null ? '$dataDir/non-vietnamese-words.csv' : null;
    }

    final acMap = resolvedAcronyms != null ? await _loadCsvFile(resolvedAcronyms, isAcronym: true) : <String, String>{};
    final wMap = resolvedWords != null ? await _loadCsvFile(resolvedWords, isAcronym: false) : <String, String>{};

    return VietnameseNormalizer(
      acronymMap: acMap,
      nonVietnameseMap: wMap,
      enableTransliteration: enableTransliteration,
    );
  }

  /// Creates a normalizer by loading CSV data from explicit file paths.
  static Future<VietnameseNormalizer> fromFiles({
    required String acronymsPath,
    required String nonVietnameseWordsPath,
    bool enableTransliteration = true,
  }) async {
    final acMap = await _loadCsvFile(acronymsPath, isAcronym: true);
    final wMap = await _loadCsvFile(nonVietnameseWordsPath, isAcronym: false);
    return VietnameseNormalizer(
      acronymMap: acMap,
      nonVietnameseMap: wMap,
      enableTransliteration: enableTransliteration,
    );
  }

  // ---------------------------------------------------------------------------
  // CSV helpers
  // ---------------------------------------------------------------------------

  /// Tries to resolve the bundled `lib/data/` directory via package URI.
  static Future<String?> _findBundledDataDir() async {
    try {
      final uri = await Isolate.resolvePackageUri(
        Uri.parse('package:vietnormalizer_dart/data/'),
      );
      if (uri == null) return null;
      final path = uri.toFilePath();
      if (Directory(path).existsSync()) return path.endsWith('/') ? path.substring(0, path.length - 1) : path;
    } catch (_) {}
    return null;
  }

  static Future<Map<String, String>> _loadCsvFile(String path, {required bool isAcronym}) async {
    try {
      final file = File(path);
      if (!file.existsSync()) return {};
      final content = await file.readAsString();
      return _parseCsv(content, isAcronym: isAcronym);
    } catch (_) {
      return {};
    }
  }

  static Map<String, String> _parseCsv(String content, {required bool isAcronym}) {
    final map = <String, String>{};
    final lines = content.split('\n');
    if (lines.isEmpty) return map;

    final header = _splitCsvLine(lines[0]);
    var wordIdx = -1;
    var pronIdx = -1;

    for (var i = 0; i < header.length; i++) {
      final col = header[i].trim().toLowerCase();
      if (col == 'acronym' || col == 'word' || col == 'original') wordIdx = i;
      if (col == 'transliteration' || col == 'vietnamese_pronunciation') pronIdx = i;
    }

    if (wordIdx == -1 || pronIdx == -1) return map;
    final maxIdx = wordIdx > pronIdx ? wordIdx : pronIdx;

    for (var i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      final parts = _splitCsvLine(line);
      if (parts.length > maxIdx) {
        final word = parts[wordIdx].trim().toLowerCase();
        final pron = parts[pronIdx].trim();
        if (word.isNotEmpty && pron.isNotEmpty) {
          map[word] = pron;
        }
      }
    }

    // Sort by key length descending so longer keys are tried first
    final sortedEntries = map.entries.toList()
      ..sort((a, b) => b.key.length.compareTo(a.key.length));
    return Map.fromEntries(sortedEntries);
  }

  static List<String> _splitCsvLine(String line) {
    final result = <String>[];
    final current = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < line.length; i++) {
      final c = line[i];
      if (c == '"') {
        inQuotes = !inQuotes;
      } else if (c == ',' && !inQuotes) {
        result.add(current.toString());
        current.clear();
      } else {
        current.write(c);
      }
    }
    result.add(current.toString());
    return result;
  }

  // ---------------------------------------------------------------------------
  // Normalization helpers
  // ---------------------------------------------------------------------------

  String _spellOutCode(String code) {
    final parts = <String>[];
    var i = 0;
    while (i < code.length) {
      if (RegExp(r'\d').hasMatch(code[i])) {
        var j = i;
        while (j < code.length && RegExp(r'\d').hasMatch(code[j])) {
          j++;
        }
        parts.add(_processor.numberToWords(code.substring(i, j)));
        i = j;
      } else {
        final letter = code[i].toUpperCase();
        final name = letterNames[letter];
        if (name != null) parts.add(name);
        i++;
      }
    }
    return parts.join(' ');
  }

  /// Handles uppercase codes (acronyms/abbreviations).
  /// Must run BEFORE lowercasing.
  String _handleUppercaseCodes(String text) {
    return text.replaceAllMapped(_uppercaseCodePattern, (m) {
      final code = m.group(1)!;
      final codeLower = code.toLowerCase();
      if (acronymMap.containsKey(codeLower)) return acronymMap[codeLower]!;
      return _spellOutCode(code);
    });
  }

  String _applyTransliteration(String text) {
    if (text.isEmpty) return text;

    final processedWords = <String>{};
    final replacementsToMake = <(String, String)>[];

    for (final match in _wordBoundaryRegex.allMatches(text)) {
      final word = match.group(0)!;
      final wordLower = word.toLowerCase();

      if (processedWords.contains(wordLower)) continue;
      processedWords.add(wordLower);

      if (_replacements.containsKey(wordLower)) continue;
      if (isVietnameseWord(word) || isVietnameseWord(wordLower)) continue;
      if (word.length <= 1) continue;

      final transliterated = transliterateWord(word);
      if (transliterated != word) {
        replacementsToMake.add((word, transliterated));
      }
    }

    for (final (original, transliterated) in replacementsToMake) {
      final escaped = RegExp.escape(original);
      const notWordChar = r'[^\wÀ-ỿ]';
      final pattern = RegExp(
        '(?:^|($notWordChar))($escaped)(?=$notWordChar|\$)',
        caseSensitive: false,
      );

      text = text.replaceAllMapped(pattern, (m) {
        final boundary = m.group(1) ?? '';
        final matchedWord = m.group(2) ?? '';
        final String result;
        if (matchedWord.isNotEmpty &&
            matchedWord[0] != matchedWord[0].toLowerCase()) {
          // First character is uppercase — capitalise transliteration
          result = transliterated[0].toUpperCase() +
              (transliterated.length > 1 ? transliterated.substring(1) : '');
        } else {
          result = transliterated;
        }
        return '$boundary$result';
      });
    }

    return text;
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Normalizes [text] through the full pipeline.
  ///
  /// [enablePreprocessing] — if false, skips the Vietnamese text processor
  /// (numbers/dates/times) and only applies dictionary + transliteration.
  ///
  /// [enableTransliterationOverride] — overrides the instance setting for
  /// this call only.
  String normalize(
    String text, {
    bool enablePreprocessing = true,
    bool? enableTransliterationOverride,
  }) {
    if (text.isEmpty) return '';

    var normalized = enablePreprocessing
        ? _processor.processVietnameseText(text)
        : text.replaceAll(RegExp(r'\s+'), ' ').trim();

    // Step 2: handle uppercase codes before lowercasing
    normalized = _handleUppercaseCodes(normalized);

    // Step 3: lowercase for consistent dictionary lookup
    normalized = normalized.toLowerCase();

    // Steps 4 & 5: replace words from dictionary
    if (_replacements.isNotEmpty) {
      normalized = normalized.replaceAllMapped(RegExp(r'\b\w+\b'), (m) {
        final word = m.group(0)!;
        return _replacements[word] ?? word;
      });
    }

    // Step 6: rule-based transliteration
    final shouldTransliterate =
        enableTransliterationOverride ?? enableTransliteration;
    if (shouldTransliterate) {
      normalized = _applyTransliteration(normalized);
    }

    return normalized.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Reloads dictionaries from the given CSV paths (or re-discovers bundled
  /// files if paths are omitted). Returns a new normalizer instance.
  Future<VietnameseNormalizer> reloadDictionaries({
    String? acronymsPath,
    String? nonVietnameseWordsPath,
  }) {
    return VietnameseNormalizer.create(
      acronymsPath: acronymsPath,
      nonVietnameseWordsPath: nonVietnameseWordsPath,
      enableTransliteration: enableTransliteration,
    );
  }
}
