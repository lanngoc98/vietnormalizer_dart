import 'package:vietnormalizer_dart/vietnormalizer_dart.dart';

void main() {
  // ------------------------------------------------------------------
  // 1. Singleton — bundled dictionaries, rule-based transliteration
  // ------------------------------------------------------------------
  final basic = VietnameseNormalizer.instance;

  print(basic.normalize('Hôm nay là 25/12/2023'));
  // → hôm nay là ngày hai mươi lăm tháng mười hai năm hai nghìn không trăm hai mươi ba

  print(basic.normalize('Cuộc họp lúc 14:30'));
  // → cuộc họp lúc mười bốn giờ ba mươi phút

  print(basic.normalize('Giá 1.500.000đ'));
  // → giá một triệu năm trăm nghìn đồng

  print(basic.normalize('50%'));
  // → năm mươi phần trăm

  // ------------------------------------------------------------------
  // 2. Inline dictionaries
  // ------------------------------------------------------------------
  final withDict = VietnameseNormalizer.custom(
    acronymMap: {'ubnd': 'ủy ban nhân dân', 'tv': 'ti vi'},
    nonVietnameseMap: {'container': 'công-tê-nơ'},
    enableTransliteration: false,
  );

  print(withDict.normalize('UBND tỉnh ra quyết định'));
  // → ủy ban nhân dân tỉnh ra quyết định

  print(withDict.normalize('chiếc container này'));
  // → chiếc công-tê-nơ này

  // ------------------------------------------------------------------
  // 3. Singleton — same instance as above
  // ------------------------------------------------------------------
  final full = VietnameseNormalizer.instance;
  print(full.normalize('container'));
  // → công-tê-nơ  (from bundled non-vietnamese-words dictionary)

  // ------------------------------------------------------------------
  // 4. Lower-level APIs
  // ------------------------------------------------------------------
  final processor = VietnameseTextProcessor();
  print(processor.numberToWords('1234567'));
  // → một triệu hai trăm ba mươi bốn nghìn năm trăm sáu mươi bảy

  print(isVietnameseWord('tôi')); // true
  print(isVietnameseWord('hello')); // false

  print(transliterateWord('software'));
  // → xốp-ueo (approximate Vietnamese phonetics)
}
