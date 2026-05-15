import 'package:vietnormalizer_dart/vietnormalizer_dart.dart';
import 'package:test/test.dart';

void main() {
  late VietnameseTextProcessor processor;

  setUpAll(() {
    processor = VietnameseTextProcessor();
  });

  // -------------------------------------------------------------------------
  // VietnameseTextProcessor — mirrors Python test_normalizer.py
  // -------------------------------------------------------------------------

  group('VietnameseTextProcessor', () {
    group('number_to_words', () {
      test('zero', () => expect(processor.numberToWords('0'), 'không'));
      test('single digit', () => expect(processor.numberToWords('7'), 'bảy'));
      test('teens', () => expect(processor.numberToWords('15'), 'mười lăm'));
      test('tens', () => expect(processor.numberToWords('20'), 'hai mươi'));
      test(
        'tens + units',
        () => expect(processor.numberToWords('21'), 'hai mươi mốt'),
      );
      test(
        'tens + 4',
        () => expect(processor.numberToWords('24'), 'hai mươi tư'),
      );
      test(
        'hundreds',
        () => expect(processor.numberToWords('100'), 'một trăm'),
      );
      test(
        'hundreds with remainder < 10',
        () => expect(processor.numberToWords('105'), 'một trăm lẻ năm'),
      );
      test(
        'thousands',
        () => expect(processor.numberToWords('1000'), 'một nghìn'),
      );
      test(
        'millions',
        () => expect(processor.numberToWords('1000000'), 'một triệu'),
      );
      test(
        'billions',
        () => expect(processor.numberToWords('1000000000'), 'một tỷ'),
      );
    });

    group('date normalization', () {
      test('full date DD/MM/YYYY', () {
        final result = processor.processVietnameseText('Hôm nay là 25/12/2023');
        expect(
          result,
          contains(
            'ngày hai mươi lăm tháng mười hai năm hai nghìn không trăm hai mươi ba',
          ),
        );
      });

      test('date with slashes DD/MM/YYYY', () {
        final result = processor.processVietnameseText('ngày 01/01/2024');
        expect(result, contains('ngày một tháng một năm hai nghìn'));
      });

      test('month/year MM/YYYY', () {
        final result = processor.processVietnameseText('tháng 12/2023');
        expect(
          result,
          contains('tháng mười hai năm hai nghìn không trăm hai mươi ba'),
        );
      });
    });

    group('time normalization', () {
      test('HH:MM format', () {
        final result = processor.processVietnameseText('Cuộc họp lúc 14:30');
        expect(result, contains('mười bốn giờ ba mươi phút'));
      });

      test('H giờ MM phút format', () {
        final result = processor.processVietnameseText('2 giờ 20 phút');
        expect(result, contains('hai giờ hai mươi phút'));
      });
    });

    group('currency normalization', () {
      test('VND with thousand separator', () {
        final result = processor.processVietnameseText('Giá là 1.000.000đ');
        expect(result, contains('một triệu đồng'));
      });

      test('USD with dollar sign', () {
        final result = processor.processVietnameseText('Giá \$100');
        expect(result, contains('một trăm đô la'));
      });
    });

    group('percentage normalization', () {
      test('whole percentage', () {
        final result = processor.processVietnameseText('50%');
        expect(result, 'năm mươi phần trăm');
      });

      test('percentage range', () {
        final result = processor.processVietnameseText('3-5%');
        expect(result, 'ba đến năm phần trăm');
      });
    });

    group('standalone numbers', () {
      test('converts bare numbers', () {
        final result = processor.processVietnameseText('có 42 người');
        expect(result, contains('bốn mươi hai'));
      });
    });

    group('measurement units', () {
      test('km', () {
        final result = processor.processVietnameseText('100km');
        expect(result, contains('ki-lô-mét'));
      });

      test('°C', () {
        final result = processor.processVietnameseText('37°C');
        expect(result, contains('độ C'));
      });
    });

    group('Roman numerals', () {
      test('converts II-IX range', () {
        final result = processor.processVietnameseText('chương IV');
        expect(result, contains('bốn'));
      });
    });

    group('ordinals', () {
      test('thứ 2', () {
        final result = processor.processVietnameseText('thứ 2');
        expect(result, 'thứ hai');
      });

      test('thứ 10', () {
        final result = processor.processVietnameseText('thứ 10');
        expect(result, 'thứ mười');
      });
    });

    group('phone numbers', () {
      test('Vietnamese mobile', () {
        final result = processor.processVietnameseText('0912345678');
        expect(result, contains('không chín một hai ba bốn năm sáu bảy tám'));
      });
    });
  });

  // -------------------------------------------------------------------------
  // VnLanguageDetector
  // -------------------------------------------------------------------------

  group('VnLanguageDetector', () {
    final detector = VnLanguageDetector();

    test('Vietnamese word with diacritic is Vietnamese', () {
      expect(detector.isVietnameseWord('tôi'), isTrue);
      expect(detector.isVietnameseWord('Việt'), isTrue);
    });

    test('word with f/w/z/j is not Vietnamese', () {
      expect(detector.isVietnameseWord('wifi'), isFalse);
      expect(detector.isVietnameseWord('zoom'), isFalse);
    });

    test('plain ASCII valid syllable is Vietnamese', () {
      expect(detector.isVietnameseWord('ban'), isTrue);
    });

    test('typical English word is not Vietnamese', () {
      expect(detector.isVietnameseWord('computer'), isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // Transliterator
  // -------------------------------------------------------------------------

  group('transliterateWord', () {
    test('Vietnamese word passes through unchanged', () {
      expect(transliterateWord('tôi'), 'tôi');
    });

    test('English word gets transliterated', () {
      final result = transliterateWord('computer');
      expect(result, isNot('computer'));
      expect(result, isNotEmpty);
    });

    test('englishToVietnamese produces hyphenated output', () {
      final result = englishToVietnamese('hello');
      expect(result, isNotEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // VietnameseNormalizer (sync constructor — no CSV data)
  // -------------------------------------------------------------------------

  group('VietnameseNormalizer (no dictionary)', () {
    late VietnameseNormalizer normalizer;

    setUpAll(() {
      normalizer = VietnameseNormalizer.instance;
    });

    test('date is expanded', () {
      final result = normalizer.normalize('25/12/2023');
      expect(result, contains('ngày hai mươi lăm tháng mười hai năm'));
    });

    test('percentage is expanded', () {
      final result = normalizer.normalize('50%');
      expect(result, contains('năm mươi phần trăm'));
    });

    test('uppercase code is spelled out', () {
      final result = normalizer.normalize('NASA');
      // Not in dictionary → spelled out letter by letter
      expect(result, isNot('NASA'));
      expect(result.toLowerCase(), isNot('nasa'));
    });

    test('empty string returns empty', () {
      expect(normalizer.normalize(''), '');
    });

    test('whitespace is normalised', () {
      final result = normalizer.normalize('  hello   world  ');
      expect(result.contains('  '), isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // VietnameseNormalizer with inline dictionaries
  // -------------------------------------------------------------------------

  group('VietnameseNormalizer (with dictionaries)', () {
    late VietnameseNormalizer normalizer;

    setUpAll(() {
      normalizer = VietnameseNormalizer.custom(
        acronymMap: {'ubnd': 'ủy ban nhân dân', 'tv': 'ti vi', 'ai': 'ây ai'},
        nonVietnameseMap: {'container': 'công-tê-nơ', 'singapore': 'xin-ga-po'},
        enableTransliteration: false,
      );
    });

    test('acronym UBND is expanded', () {
      final result = normalizer.normalize('UBND tỉnh');
      expect(result, contains('ủy ban nhân dân'));
    });

    test('acronym TV is expanded', () {
      final result = normalizer.normalize('xem TV');
      expect(result, contains('ti vi'));
    });

    test('non-Vietnamese word is replaced', () {
      final result = normalizer.normalize('chiếc container này');
      expect(result, contains('công-tê-nơ'));
    });

    test('known word singapore is replaced', () {
      final result = normalizer.normalize('đến singapore');
      expect(result, contains('xin-ga-po'));
    });

    test('preprocessor disabled still does dictionary replacement', () {
      final result = normalizer.normalize(
        'container',
        enablePreprocessing: false,
      );
      expect(result, 'công-tê-nơ');
    });
  });
}
