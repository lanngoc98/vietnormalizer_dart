/// Vietnamese text processor for TTS.
///
/// Ported from nghitts/src/utils/vietnamese-processor.js via the Python port.
/// Handles numbers, dates, times, currency, percentages, measurement units,
/// ordinals, phone numbers, and text cleaning.
library;

class VietnameseTextProcessor {
  static const Map<String, String> digits = {
    '0': 'không', '1': 'một', '2': 'hai', '3': 'ba', '4': 'bốn',
    '5': 'năm', '6': 'sáu', '7': 'bảy', '8': 'tám', '9': 'chín',
  };

  static const Map<String, String> teens = {
    '10': 'mười', '11': 'mười một', '12': 'mười hai', '13': 'mười ba',
    '14': 'mười bốn', '15': 'mười lăm', '16': 'mười sáu', '17': 'mười bảy',
    '18': 'mười tám', '19': 'mười chín',
  };

  static const Map<String, String> tens = {
    '2': 'hai mươi', '3': 'ba mươi', '4': 'bốn mươi', '5': 'năm mươi',
    '6': 'sáu mươi', '7': 'bảy mươi', '8': 'tám mươi', '9': 'chín mươi',
  };

  static const Map<String, String> unitMap = {
    // Length
    'cm': 'xăng-ti-mét', 'mm': 'mi-li-mét', 'km': 'ki-lô-mét',
    'dm': 'đề-xi-mét', 'hm': 'héc-tô-mét', 'dam': 'đề-ca-mét',
    'm': 'mét', 'inch': 'in',
    // Weight
    'kg': 'ki-lô-gam', 'mg': 'mi-li-gam', 'g': 'gam',
    't': 'tấn', 'tấn': 'tấn', 'yến': 'yến', 'lạng': 'lạng',
    // Volume
    'ml': 'mi-li-lít', 'l': 'lít', 'lít': 'lít',
    // Area
    'm²': 'mét vuông', 'm2': 'mét vuông',
    'km²': 'ki-lô-mét vuông', 'km2': 'ki-lô-mét vuông',
    'ha': 'héc-ta',
    'cm²': 'xăng-ti-mét vuông', 'cm2': 'xăng-ti-mét vuông',
    // Cubic
    'm³': 'mét khối', 'm3': 'mét khối',
    'cm³': 'xăng-ti-mét khối', 'cm3': 'xăng-ti-mét khối',
    'km³': 'ki-lô-mét khối', 'km3': 'ki-lô-mét khối',
    // Time
    's': 'giây', 'sec': 'giây', 'min': 'phút',
    'h': 'giờ', 'hr': 'giờ', 'hrs': 'giờ',
    // Speed
    'km/h': 'ki-lô-mét trên giờ', 'kmh': 'ki-lô-mét trên giờ',
    'm/s': 'mét trên giây', 'ms': 'mét trên giây',
    'mm/h': 'mi-li-mét trên giờ', 'cm/s': 'xăng-ti-mét trên giây',
    // Temperature
    '°C': 'độ C', '°F': 'độ F', '°K': 'độ K',
    '°R': 'độ R', '°Re': 'độ Re', '°Ro': 'độ Ro',
    '°N': 'độ N', '°D': 'độ D',
  };

  static const Map<String, int> _romanValues = {
    'I': 1, 'V': 5, 'X': 10, 'L': 50, 'C': 100,
  };

  static const Map<String, String> _ordinalMap = {
    '1': 'nhất', '2': 'hai', '3': 'ba', '4': 'tư', '5': 'năm',
    '6': 'sáu', '7': 'bảy', '8': 'tám', '9': 'chín', '10': 'mười',
  };

  late final RegExp _emojiPattern;
  late final RegExp _thousandSepPattern;
  late final RegExp _decimalPattern;
  late final RegExp _percentageRangePattern;
  late final RegExp _percentageDecimalPattern;
  late final RegExp _percentagePattern;
  late final RegExp _standaloneNumberPattern;
  late final RegExp _whitespacePattern;
  late final RegExp _timeHmsPattern;
  late final RegExp _timeHhmmPattern;
  late final RegExp _timeHPattern;
  late final RegExp _timeGiophutPattern;
  late final RegExp _timeGioPattern;
  late final RegExp _dateNgayRangePattern;
  late final RegExp _dateRangePattern;
  late final RegExp _monthRangePattern;
  late final RegExp _dateSinhPattern;
  late final RegExp _dateFullPattern;
  late final RegExp _dateMonthYearPattern;
  late final RegExp _dateDayMonthPattern;
  late final RegExp _dateXThangYPattern;
  late final RegExp _dateThangXPattern;
  late final RegExp _dateNgayXPattern;
  late final RegExp _currencyVndPattern1;
  late final RegExp _currencyVndPattern2;
  late final RegExp _currencyUsdPattern1;
  late final RegExp _currencyUsdPattern2;
  late final RegExp _yearRangePattern;
  late final RegExp _ordinalPattern;
  late final RegExp _phoneVnPattern;
  late final RegExp _phoneIntlPattern;
  late final RegExp _romanNumeralPattern;
  late final RegExp _addressKeywordPattern;
  late final RegExp _address3partPattern;
  late final RegExp _addressBignumPattern;
  late final List<(String, RegExp)> _unitPatterns;

  VietnameseTextProcessor() {
    _initPatterns();
  }

  // Escapes special regex characters in [s].
  static String _reEscape(String s) {
    return s.replaceAllMapped(
      RegExp(r'[.*+?^${}()|[\]\\]'),
      (m) => '\\${m.group(0)}',
    );
  }

  void _initPatterns() {
    _emojiPattern = RegExp(
      r'[\u{1F600}-\u{1F64F}]|[\u{1F300}-\u{1F5FF}]|[\u{1F680}-\u{1F6FF}]|'
      r'[\u{1F1E0}-\u{1F1FF}]|[☀-⛿]|[✀-➿]|'
      r'[\u{1F900}-\u{1F9FF}]|[\u{1F018}-\u{1F270}]|[⎌-⑔]|'
      r'[⃐-⃿]|️|‍',
      unicode: true,
    );

    _thousandSepPattern = RegExp(r'(\d{1,3}(?:\.\d{3})+)(?=\s|$|[^\d.,])');
    _decimalPattern = RegExp(r'(\d+),(\d+)(?=\s|$|[^\d,])');
    _percentageRangePattern = RegExp(r'(\d+)\s*[-–—]\s*(\d+)\s*%');
    _percentageDecimalPattern = RegExp(r'(\d+),(\d+)\s*%');
    _percentagePattern = RegExp(r'(\d+)\s*%');
    _standaloneNumberPattern = RegExp(r'\b\d+\b');
    _whitespacePattern = RegExp(r'\s+');

    // Time: \d{1,2}:\d{2} or with seconds
    _timeHmsPattern = RegExp(r'(\d{1,2}):(\d{2})(?::(\d{2}))?');
    // Time: 14h30 — negative lookahead for Vietnamese/Latin chars
    _timeHhmmPattern = RegExp(r'(\d{1,2})h(\d{2})(?![a-zÀ-ỿ])', caseSensitive: false);
    _timeHPattern = RegExp(r'(\d{1,2})h(?![a-zÀ-ỿ\d])', caseSensitive: false);
    _timeGiophutPattern = RegExp(r'(\d+)\s*giờ\s*(\d+)\s*phút');
    _timeGioPattern = RegExp(r'(\d+)\s*giờ(?!\s*\d)');

    // Date ranges and full dates
    _dateNgayRangePattern = RegExp(
      r'ngày\s+(\d{1,2})\s*[-–—]\s*(\d{1,2})\s*[/\-]\s*(\d{1,2})(?:\s*[/\-]\s*(\d{4}))?',
    );
    _dateRangePattern = RegExp(
      r'(\d{1,2})\s*[-–—]\s*(\d{1,2})\s*[/\-]\s*(\d{1,2})(?:\s*[/\-]\s*(\d{4}))?',
    );
    _monthRangePattern = RegExp(r'(\d{1,2})\s*[-–—]\s*(\d{1,2})\s*[/\-]\s*(\d{4})');
    _dateSinhPattern = RegExp(r'(Sinh|sinh)\s+ngày\s+(\d{1,2})[/\-](\d{1,2})[/\-](\d{4})');
    _dateFullPattern = RegExp(r'(\d{1,2})[/\-](\d{1,2})[/\-](\d{4})');
    _dateMonthYearPattern = RegExp(r'(?:tháng\s+)?(\d{1,2})\s*[/\-]\s*(\d{4})(?![/\-]\d)');
    _dateDayMonthPattern = RegExp(r'(\d{1,2})\s*[/\-]\s*(\d{1,2})(?![/\-]\d)(?!\d+\s*%)');
    _dateXThangYPattern = RegExp(r'(\d+)\s*tháng\s*(\d+)');
    _dateThangXPattern = RegExp(r'tháng\s*(\d+)');
    _dateNgayXPattern = RegExp(r'ngày\s*(\d+)');

    // Currency
    _currencyVndPattern1 = RegExp(
      r'(\d+(?:,\d+)?)\s*(?:đồng|VND|vnđ)\b',
      caseSensitive: false,
    );
    _currencyVndPattern2 = RegExp(
      r'(\d+(?:,\d+)?)đ(?![a-zÀ-ỿ])',
      caseSensitive: false,
    );
    _currencyUsdPattern1 = RegExp(r'\$\s*(\d+(?:,\d+)?)');
    _currencyUsdPattern2 = RegExp(r'(\d+(?:,\d+)?)\s*(?:USD|\$)', caseSensitive: false);

    _yearRangePattern = RegExp(r'(\d{4})\s*[-–—]\s*(\d{4})');

    _ordinalPattern = RegExp(
      r'(thứ|lần|bước|phần|chương|tập|số)\s*(\d+)',
      caseSensitive: false,
    );

    _phoneVnPattern = RegExp(r'0\d{9,10}');
    _phoneIntlPattern = RegExp(r'\+84\d{9,10}');

    _romanNumeralPattern = RegExp(r'\b([IVXLC]{2,})\b');

    _addressKeywordPattern = RegExp(
      r'(số|nhà|đường|hẻm|ngõ|ngách|kiệt|phố)\s+(\d+(?:/\d+)+)',
      caseSensitive: false,
    );
    _address3partPattern = RegExp(r'\b(\d+)/(\d+)/(\d{1,3})\b');
    _addressBignumPattern = RegExp(r'\b(\d{3,})/(\d+)\b');

    _compileUnitPatterns();
  }

  void _compileUnitPatterns() {
    final sortedUnits = unitMap.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    _unitPatterns = [];
    for (final unit in sortedUnits) {
      final escaped = _reEscape(unit);
      final RegExp pattern;
      if (unit.length == 1) {
        pattern = RegExp(
          r'(\d+)\s*' +
              escaped +
              r'(?!\s*[a-zA-ZÀ-ỿ])(?=\s*[^a-zA-ZÀ-ỿ]|$)',
          caseSensitive: false,
        );
      } else {
        pattern = RegExp(
          r'(\d+)\s*' + escaped + r'(?=\s|[^\w]|$)',
          caseSensitive: false,
        );
      }
      _unitPatterns.add((unit, pattern));
    }
  }

  // ---------------------------------------------------------------------------
  // Number conversion
  // ---------------------------------------------------------------------------

  /// Converts a number string to Vietnamese words.
  String numberToWords(String numStr) {
    numStr = numStr.replaceAll(RegExp(r'^0+'), '');
    if (numStr.isEmpty) numStr = '0';

    if (numStr.startsWith('-')) {
      return 'âm ${numberToWords(numStr.substring(1))}';
    }

    final num = int.tryParse(numStr);
    if (num == null) return numStr;

    if (num == 0) return 'không';
    if (num < 10) return digits[num.toString()]!;
    if (num < 20) return teens[num.toString()]!;
    if (num < 100) {
      final t = num ~/ 10;
      final u = num % 10;
      if (u == 0) return tens[t.toString()]!;
      if (u == 1) return '${tens[t.toString()]!} mốt';
      if (u == 4) return '${tens[t.toString()]!} tư';
      if (u == 5) return '${tens[t.toString()]!} lăm';
      return '${tens[t.toString()]!} ${digits[u.toString()]!}';
    }
    if (num < 1000) {
      final h = num ~/ 100;
      final remainder = num % 100;
      final result = '${digits[h.toString()]!} trăm';
      if (remainder == 0) return result;
      if (remainder < 10) return '$result lẻ ${digits[remainder.toString()]!}';
      return '$result ${numberToWords(remainder.toString())}';
    }
    if (num < 1000000) {
      final k = num ~/ 1000;
      final remainder = num % 1000;
      final result = '${numberToWords(k.toString())} nghìn';
      if (remainder == 0) return result;
      if (remainder < 100) {
        if (remainder < 10) {
          return '$result không trăm lẻ ${digits[remainder.toString()]!}';
        }
        return '$result không trăm ${numberToWords(remainder.toString())}';
      }
      return '$result ${numberToWords(remainder.toString())}';
    }
    if (num < 1000000000) {
      final m = num ~/ 1000000;
      final remainder = num % 1000000;
      final result = '${numberToWords(m.toString())} triệu';
      if (remainder == 0) return result;
      if (remainder < 100) {
        if (remainder < 10) {
          return '$result không trăm lẻ ${digits[remainder.toString()]!}';
        }
        return '$result không trăm ${numberToWords(remainder.toString())}';
      }
      return '$result ${numberToWords(remainder.toString())}';
    }
    if (num < 1000000000000) {
      final b = num ~/ 1000000000;
      final remainder = num % 1000000000;
      final result = '${numberToWords(b.toString())} tỷ';
      if (remainder == 0) return result;
      if (remainder < 100) {
        if (remainder < 10) {
          return '$result không trăm lẻ ${digits[remainder.toString()]!}';
        }
        return '$result không trăm ${numberToWords(remainder.toString())}';
      }
      return '$result ${numberToWords(remainder.toString())}';
    }

    // Fallback: read digit by digit
    return numStr.split('').map((d) => digits[d] ?? d).join(' ');
  }

  // ---------------------------------------------------------------------------
  // Conversion methods
  // ---------------------------------------------------------------------------

  /// Removes thousand separators (dots) from numbers like 1.000.000.
  String removeThousandSeparators(String text) {
    return text.replaceAllMapped(_thousandSepPattern, (m) => m.group(0)!.replaceAll('.', ''));
  }

  /// Converts decimal numbers: 7,27 → bảy phẩy hai mươi bảy.
  String convertDecimal(String text) {
    return text.replaceAllMapped(_decimalPattern, (m) {
      final integerPart = m.group(1)!;
      final decimalPart = m.group(2)!;
      final intWords = numberToWords(integerPart);
      final stripped = decimalPart.replaceAll(RegExp(r'^0+'), '');
      final decWords = numberToWords(stripped.isEmpty ? '0' : stripped);
      return '$intWords phẩy $decWords';
    });
  }

  /// Converts percentages: 50% → năm mươi phần trăm, 3-5% → ba đến năm phần trăm.
  String convertPercentage(String text) {
    text = text.replaceAllMapped(_percentageRangePattern, (m) {
      return '${numberToWords(m.group(1)!)} đến ${numberToWords(m.group(2)!)} phần trăm';
    });

    text = text.replaceAllMapped(_percentageDecimalPattern, (m) {
      final intWords = numberToWords(m.group(1)!);
      final stripped = m.group(2)!.replaceAll(RegExp(r'^0+'), '');
      final decWords = numberToWords(stripped.isEmpty ? '0' : stripped);
      return '$intWords phẩy $decWords phần trăm';
    });

    return text.replaceAllMapped(
      _percentagePattern,
      (m) => '${numberToWords(m.group(1)!)} phần trăm',
    );
  }

  /// Converts currency amounts (VND and USD).
  String convertCurrency(String text) {
    text = text.replaceAllMapped(_currencyVndPattern1, (m) {
      final num = m.group(1)!.replaceAll(',', '');
      return '${numberToWords(num)} đồng';
    });
    text = text.replaceAllMapped(_currencyVndPattern2, (m) {
      final num = m.group(1)!.replaceAll(',', '');
      return '${numberToWords(num)} đồng';
    });
    text = text.replaceAllMapped(_currencyUsdPattern1, (m) {
      final num = m.group(1)!.replaceAll(',', '');
      return '${numberToWords(num)} đô la';
    });
    text = text.replaceAllMapped(_currencyUsdPattern2, (m) {
      final num = m.group(1)!.replaceAll(',', '');
      return '${numberToWords(num)} đô la';
    });
    return text;
  }

  /// Converts time expressions: 2:20 → hai giờ hai mươi phút.
  String convertTime(String text) {
    text = text.replaceAllMapped(_timeHmsPattern, (m) {
      final hour = m.group(1)!;
      final minute = m.group(2)!;
      final second = m.group(3);
      var result = '${numberToWords(hour)} giờ';
      result += ' ${numberToWords(minute)} phút';
      if (second != null) result += ' ${numberToWords(second)} giây';
      return result;
    });

    text = text.replaceAllMapped(_timeHhmmPattern, (m) {
      final h = int.parse(m.group(1)!);
      final min = int.parse(m.group(2)!);
      if (h >= 0 && h <= 23 && min >= 0 && min <= 59) {
        return '${numberToWords(m.group(1)!)} giờ ${numberToWords(m.group(2)!)}';
      }
      return m.group(0)!;
    });

    text = text.replaceAllMapped(_timeHPattern, (m) {
      final h = int.parse(m.group(1)!);
      if (h >= 0 && h <= 23) {
        return '${numberToWords(m.group(1)!)} giờ';
      }
      return m.group(0)!;
    });

    text = text.replaceAllMapped(_timeGiophutPattern, (m) {
      return '${numberToWords(m.group(1)!)} giờ ${numberToWords(m.group(2)!)} phút';
    });

    text = text.replaceAllMapped(_timeGioPattern, (m) {
      return '${numberToWords(m.group(1)!)} giờ';
    });

    return text;
  }

  /// Converts year ranges: 1873-1907 → một nghìn... đến một nghìn...
  String convertYearRange(String text) {
    return text.replaceAllMapped(_yearRangePattern, (m) {
      return '${numberToWords(m.group(1)!)} đến ${numberToWords(m.group(2)!)}';
    });
  }

  /// Converts date expressions including date ranges.
  String convertDate(String text) {
    bool isValidDate(String day, String month, [String? year]) {
      final d = int.parse(day);
      final mo = int.parse(month);
      if (year != null) {
        final y = int.parse(year);
        return d >= 1 && d <= 31 && mo >= 1 && mo <= 12 && y >= 1000 && y <= 9999;
      }
      return d >= 1 && d <= 31 && mo >= 1 && mo <= 12;
    }

    bool isValidMonth(String month) {
      final m = int.parse(month);
      return m >= 1 && m <= 12;
    }

    // ngày dd-dd/mm or ngày dd-dd/mm/yyyy
    text = text.replaceAllMapped(_dateNgayRangePattern, (m) {
      final day1 = m.group(1)!, day2 = m.group(2)!, month = m.group(3)!;
      final year = m.group(4);
      if (isValidDate(day1, month, year) && isValidDate(day2, month, year)) {
        var result =
            'ngày ${numberToWords(day1)} đến ${numberToWords(day2)} tháng ${numberToWords(month)}';
        if (year != null) result += ' năm ${numberToWords(year)}';
        return result;
      }
      return m.group(0)!;
    });

    // dd-dd/mm or dd-dd/mm/yyyy
    text = text.replaceAllMapped(_dateRangePattern, (m) {
      final day1 = m.group(1)!, day2 = m.group(2)!, month = m.group(3)!;
      final year = m.group(4);
      if (isValidDate(day1, month, year) && isValidDate(day2, month, year)) {
        var result =
            '${numberToWords(day1)} đến ${numberToWords(day2)} tháng ${numberToWords(month)}';
        if (year != null) result += ' năm ${numberToWords(year)}';
        return result;
      }
      return m.group(0)!;
    });

    // mm-mm/yyyy
    text = text.replaceAllMapped(_monthRangePattern, (m) {
      final m1 = m.group(1)!, m2 = m.group(2)!, year = m.group(3)!;
      if (isValidMonth(m1) && isValidMonth(m2)) {
        final y = int.parse(year);
        if (y >= 1000 && y <= 9999) {
          return 'tháng ${numberToWords(m1)} đến tháng ${numberToWords(m2)} năm ${numberToWords(year)}';
        }
      }
      return m.group(0)!;
    });

    // Sinh ngày DD/MM/YYYY
    text = text.replaceAllMapped(_dateSinhPattern, (m) {
      final prefix = m.group(1)!, day = m.group(2)!, month = m.group(3)!, year = m.group(4)!;
      if (isValidDate(day, month, year)) {
        return '$prefix ngày ${numberToWords(day)} tháng ${numberToWords(month)} năm ${numberToWords(year)}';
      }
      return m.group(0)!;
    });

    // DD/MM/YYYY
    text = text.replaceAllMapped(_dateFullPattern, (m) {
      final day = m.group(1)!, month = m.group(2)!, year = m.group(3)!;
      if (isValidDate(day, month, year)) {
        return 'ngày ${numberToWords(day)} tháng ${numberToWords(month)} năm ${numberToWords(year)}';
      }
      return m.group(0)!;
    });

    // MM/YYYY
    text = text.replaceAllMapped(_dateMonthYearPattern, (m) {
      final month = m.group(1)!, year = m.group(2)!;
      final mo = int.parse(month);
      final y = int.parse(year);
      if (mo >= 1 && mo <= 12 && y >= 1000 && y <= 9999) {
        return 'tháng ${numberToWords(month)} năm ${numberToWords(year)}';
      }
      return m.group(0)!;
    });

    // DD/MM
    text = text.replaceAllMapped(_dateDayMonthPattern, (m) {
      final day = m.group(1)!, month = m.group(2)!;
      if (isValidDate(day, month)) {
        return '${numberToWords(day)} tháng ${numberToWords(month)}';
      }
      return m.group(0)!;
    });

    // X tháng Y
    text = text.replaceAllMapped(_dateXThangYPattern, (m) {
      final day = m.group(1)!, month = m.group(2)!;
      if (isValidDate(day, month)) {
        return 'ngày ${numberToWords(day)} tháng ${numberToWords(month)}';
      }
      return m.group(0)!;
    });

    // tháng X
    text = text.replaceAllMapped(_dateThangXPattern, (m) {
      final month = m.group(1)!;
      if (isValidMonth(month)) return 'tháng ${numberToWords(month)}';
      return m.group(0)!;
    });

    // ngày X
    text = text.replaceAllMapped(_dateNgayXPattern, (m) {
      final day = m.group(1)!;
      final d = int.parse(day);
      if (d >= 1 && d <= 31) return 'ngày ${numberToWords(day)}';
      return m.group(0)!;
    });

    return text;
  }

  /// Converts ordinals: thứ 2 → thứ hai.
  String convertOrdinal(String text) {
    return text.replaceAllMapped(_ordinalPattern, (m) {
      final prefix = m.group(1)!;
      final num = m.group(2)!;
      final word = _ordinalMap[num] ?? numberToWords(num);
      return '$prefix $word';
    });
  }

  /// Reads phone numbers digit by digit.
  String convertPhoneNumber(String text) {
    String replacePhone(Match m) {
      return m
          .group(0)!
          .split('')
          .where((c) => RegExp(r'\d').hasMatch(c))
          .map((d) => digits[d] ?? d)
          .join(' ');
    }

    text = text.replaceAllMapped(_phoneVnPattern, replacePhone);
    text = text.replaceAllMapped(_phoneIntlPattern, replacePhone);
    return text;
  }

  /// Converts measurement units to Vietnamese names.
  String convertMeasurementUnits(String text) {
    for (final (unit, pattern) in _unitPatterns) {
      text = text.replaceAllMapped(pattern, (m) => '${m.group(1)!} ${unitMap[unit]!}');
    }
    return text;
  }

  int _romanToInt(String s) {
    if (s.isEmpty || !s.split('').every((c) => _romanValues.containsKey(c))) return -1;
    var total = 0;
    var prev = 0;
    for (final c in s.split('').reversed) {
      final val = _romanValues[c]!;
      if (val < prev) {
        total -= val;
      } else {
        total += val;
      }
      prev = val;
    }
    return total;
  }

  /// Converts uppercase Roman numerals (< 100) to Vietnamese words.
  String convertRomanNumerals(String text) {
    return text.replaceAllMapped(_romanNumeralPattern, (m) {
      final roman = m.group(1)!;
      final value = _romanToInt(roman);
      if (value >= 1 && value < 100) return numberToWords(value.toString());
      return m.group(0)!;
    });
  }

  String _readAddressParts(String partsStr) {
    return partsStr.split('/').map(numberToWords).join(' trên ');
  }

  /// Converts address numbers like 13/2/80, 878/16 with "trên" separator.
  /// Must be called BEFORE date conversion.
  String convertAddressNumber(String text) {
    text = text.replaceAllMapped(_addressKeywordPattern, (m) {
      return '${m.group(1)!} ${_readAddressParts(m.group(2)!)}';
    });
    text = text.replaceAllMapped(_address3partPattern, (m) {
      return _readAddressParts('${m.group(1)!}/${m.group(2)!}/${m.group(3)!}');
    });
    text = text.replaceAllMapped(_addressBignumPattern, (m) {
      return _readAddressParts('${m.group(1)!}/${m.group(2)!}');
    });
    return text;
  }

  /// Converts remaining standalone numbers to words.
  String convertStandaloneNumbers(String text) {
    return text.replaceAllMapped(_standaloneNumberPattern, (m) => numberToWords(m.group(0)!));
  }

  /// Removes or replaces special characters that can't be spoken.
  String removeSpecialChars(String text) {
    text = text
        .replaceAll('&', ' và ')
        .replaceAll('@', ' a còng ')
        .replaceAll('#', ' thăng ')
        .replaceAll('*', '')
        .replaceAll('_', ' ')
        .replaceAll('~', '')
        .replaceAll('`', '')
        .replaceAll('^', '');

    text = text.replaceAll(RegExp(r'https?://\S+'), '');
    text = text.replaceAll(RegExp(r'www\.\S+'), '');
    text = text.replaceAll(RegExp(r'\S+@\S+\.\S+'), '');
    return text;
  }

  /// Normalizes punctuation marks.
  String normalizePunctuation(String text) {
    text = text.replaceAll(RegExp(r'[""„‟]'), '"');
    text = text.replaceAll(RegExp(r"[''‚‛]"), "'");
    text = text.replaceAll(RegExp(r'[–—−]'), '-');
    text = text.replaceAll(RegExp(r'\.{3,}'), '...');
    text = text.replaceAll('…', '...');
    text = text.replaceAllMapped(RegExp(r'([!?.])(\1)+'), (m) => m.group(1)!);
    return text;
  }

  /// Cleans text: removes emojis and non-Latin/Vietnamese characters.
  String cleanTextForTts(String text) {
    text = text.replaceAll(_emojiPattern, '');
    text = text.replaceAll(RegExp(r'[\\()¯"""]'), '');
    text = text.replaceAll(RegExp(r'\s—'), '.');
    text = text.replaceAll(RegExp(r'\b_\b'), ' ');
    // Remove dashes not between digits
    text = text.replaceAllMapped(RegExp(r'(?<!\d)-(?!\d)'), (_) => ' ');
    // Keep only Latin, Vietnamese, numbers, punctuation, whitespace
    text = text.replaceAll(RegExp(r'[^ -ɏḀ-ỿ]'), '');
    return text.trim();
  }

  // ---------------------------------------------------------------------------
  // Main pipeline
  // ---------------------------------------------------------------------------

  /// Processes Vietnamese text through the full 19-step normalization pipeline.
  String processVietnameseText(String text) {
    if (text.isEmpty) return '';

    // Step 1: (Unicode NFC normalization — Dart strings are typically NFC)

    // Step 2: Remove special characters
    text = removeSpecialChars(text);

    // Step 3: Normalize punctuation
    text = normalizePunctuation(text);

    // Step 4: Clean text (emojis, non-Latin)
    text = cleanTextForTts(text);

    // Step 5: Convert address numbers BEFORE dates
    text = convertAddressNumber(text);

    // Step 6: Convert year ranges
    text = convertYearRange(text);

    // Step 7: Convert percentage ranges BEFORE dates (avoids "3-5%" being parsed as date)
    text = text.replaceAllMapped(_percentageRangePattern, (m) {
      return '${numberToWords(m.group(1)!)} đến ${numberToWords(m.group(2)!)} phần trăm';
    });

    // Step 8: Convert dates
    text = convertDate(text);

    // Step 9: Convert times
    text = convertTime(text);

    // Step 10: Convert ordinals
    text = convertOrdinal(text);

    // Step 11: Remove thousand separators
    text = removeThousandSeparators(text);

    // Step 12: Convert currency
    text = convertCurrency(text);

    // Step 13: Convert percentages (ranges already handled)
    text = convertPercentage(text);

    // Step 14: Convert phone numbers
    text = convertPhoneNumber(text);

    // Step 15: Convert decimals
    text = convertDecimal(text);

    // Step 16: Convert measurement units
    text = convertMeasurementUnits(text);

    // Step 17: Convert Roman numerals
    text = convertRomanNumerals(text);

    // Step 18: Convert remaining standalone numbers
    text = convertStandaloneNumbers(text);

    // Step 19: Clean whitespace
    text = text.replaceAll(_whitespacePattern, ' ').trim();

    return text;
  }
}
