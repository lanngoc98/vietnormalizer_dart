import 'package:vietnormalizer_dart/vietnormalizer_dart.dart';

void main() async {
  // ------------------------------------------------------------------
  // 1. Sync usage — no CSV dictionary, rule-based transliteration only
  // ------------------------------------------------------------------
  final basic = VietnameseNormalizer(enableTransliteration: true);

  print(basic.normalize('Hôm nay là 25/12/2023'));
  // → hôm nay là ngày hai mươi lăm tháng mười hai năm hai nghìn không trăm hai mươi ba

  print(basic.normalize('Cuộc họp lúc 14:30'));
  // → cuộc họp lúc mười bốn giờ ba mươi phút

  print(basic.normalize('Giá 1.500.000đ'));
  // → giá một triệu năm trăm nghìn đồng

  print(basic.normalize('50%'));
  // → năm mươi phần trăm

  print(basic.normalize('AI'));
  // → ây i  (spelled out: A=ây, I=i)

  // ------------------------------------------------------------------
  // 2. Inline dictionaries
  // ------------------------------------------------------------------
  final withDict = VietnameseNormalizer(
    acronymMap: {
      'ubnd': 'ủy ban nhân dân',
      'tv': 'ti vi',
    },
    nonVietnameseMap: {
      'container': 'công-tê-nơ',
    },
    enableTransliteration: false,
  );

  print(withDict.normalize('UBND tỉnh ra quyết định'));
  // → ủy ban nhân dân tỉnh ra quyết định

  print(withDict.normalize('chiếc container này'));
  // → chiếc công-tê-nơ này

  // ------------------------------------------------------------------
  // 3. Async factory — loads bundled CSV files automatically
  // ------------------------------------------------------------------
  // (bundled CSV files are in lib/data/ within the package)
  final full = await VietnameseNormalizer.create();
  print(full.normalize('container'));
  // → công-tê-nơ  (from non-vietnamese-words.csv)

  // ------------------------------------------------------------------
  // 4. Lower-level APIs
  // ------------------------------------------------------------------
  final processor = VietnameseTextProcessor();
  print(processor.numberToWords('1234567'));
  // → một triệu hai trăm ba mươi bốn nghìn năm trăm sáu mươi bảy

  print(isVietnameseWord('tôi'));   // true
  print(isVietnameseWord('hello')); // false

  print(transliterateWord('software'));
  // → xốp-ueo (approximate Vietnamese phonetics)
}
