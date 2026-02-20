class SupportedLanguage {
  final String code;
  final String name;

  const SupportedLanguage({required this.code, required this.name});
}

class LanguagesData {
  LanguagesData._();

  static const List<SupportedLanguage> supported = [
    SupportedLanguage(code: 'hi', name: 'Hindi'),
    SupportedLanguage(code: 'en', name: 'English'),
    SupportedLanguage(code: 'bn', name: 'Bengali'),
    SupportedLanguage(code: 'gu', name: 'Gujarati'),
    SupportedLanguage(code: 'mr', name: 'Marathi'),
    SupportedLanguage(code: 'ta', name: 'Tamil'),
    SupportedLanguage(code: 'te', name: 'Telugu'),
    SupportedLanguage(code: 'pa', name: 'Punjabi'),
  ];
}


