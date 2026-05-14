/// Vietnamese text normalizer for TTS (text-to-speech) pre-processing.
///
/// Handles number/date/time expansion, acronym lookup, non-Vietnamese word
/// dictionary replacement, and rule-based English→Vietnamese transliteration.
library;

export 'src/normalizer.dart' show VietnameseNormalizer, letterNames;
export 'src/processor.dart' show VietnameseTextProcessor;
export 'src/detector.dart' show VnLanguageDetector, isVietnameseWord;
export 'src/transliterator.dart' show englishToVietnamese, transliterateWord;
