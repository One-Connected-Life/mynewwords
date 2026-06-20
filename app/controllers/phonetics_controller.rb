class PhoneticsController < ApplicationController
  skip_before_action :require_onboarding

  # IPA cheat sheet — ~30 symbols relevant to our 7 supported languages.
  # Reachable via the "what's this?" link next to any IPA line.
  def guide
    @symbols = IPA_SYMBOLS
  end

  private

  # Compact set of IPA symbols that appear in our 7 languages (en/nl/es/fr/it/ro/ru).
  # Each entry: [symbol, name, example_word, example_lang, example_ipa_fragment].
  IPA_SYMBOLS = [
    # Vowels
    { symbol: "ə",  name: "schwa",          example: "about",     lang: "en", fragment: "əˈbaʊt" },
    { symbol: "ɛ",  name: "open-mid front", example: "bed",       lang: "en", fragment: "bɛd" },
    { symbol: "ɪ",  name: "near-close front",example: "bit",      lang: "en", fragment: "bɪt" },
    { symbol: "ʊ",  name: "near-close back", example: "book",     lang: "en", fragment: "bʊk" },
    { symbol: "ɔ",  name: "open-mid back",   example: "lot",      lang: "en", fragment: "lɔt" },
    { symbol: "æ",  name: "near-open front", example: "cat",      lang: "en", fragment: "kæt" },
    { symbol: "y",  name: "close front rounded", example: "lune", lang: "fr", fragment: "lyn" },
    { symbol: "ø",  name: "mid front rounded", example: "peu",    lang: "fr", fragment: "pø" },
    { symbol: "œ",  name: "open-mid front rounded", example: "peur", lang: "fr", fragment: "pœʁ" },
    { symbol: "ɑ",  name: "open back",       example: "paard",    lang: "nl", fragment: "pɑːrt" },
    { symbol: "ɯ",  name: "close back unrounded", example: "ы (byk)", lang: "ru", fragment: "bɯk" },
    # Long vowels
    { symbol: "ː",  name: "long vowel",      example: "brood",    lang: "nl", fragment: "broːt" },
    # Nasals
    { symbol: "ɛ̃",  name: "nasal ɛ",         example: "pain",     lang: "fr", fragment: "pɛ̃" },
    { symbol: "ɔ̃",  name: "nasal ɔ",         example: "bon",      lang: "fr", fragment: "bɔ̃" },
    { symbol: "ã",  name: "nasal a",          example: "ân (ro)",  lang: "ro", fragment: "ãn" },
    # Stress
    { symbol: "ˈ",  name: "primary stress",  example: "father",   lang: "en", fragment: "ˈfɑːðə" },
    { symbol: "ˌ",  name: "secondary stress", example: "understand", lang: "en", fragment: "ˌʌndəˈstænd" },
    # Consonants
    { symbol: "ʃ",  name: "sh",              example: "ship",     lang: "en", fragment: "ʃɪp" },
    { symbol: "ʒ",  name: "zh (measure)",    example: "je",       lang: "fr", fragment: "ʒə" },
    { symbol: "θ",  name: "th (thin)",       example: "thin",     lang: "en", fragment: "θɪn" },
    { symbol: "ð",  name: "th (this)",       example: "this",     lang: "en", fragment: "ðɪs" },
    { symbol: "ŋ",  name: "ng",             example: "ring",      lang: "en", fragment: "ɹɪŋ" },
    { symbol: "ɲ",  name: "ny (España)",    example: "año",       lang: "es", fragment: "aɲo" },
    { symbol: "x",  name: "ch (loch)",      example: "хлеб",      lang: "ru", fragment: "xlʲep" },
    { symbol: "ɣ",  name: "voiced x",       example: "agua",      lang: "es", fragment: "ˈaɣwa" },
    { symbol: "ʁ",  name: "French r",       example: "rue",       lang: "fr", fragment: "ʁy" },
    { symbol: "ʔ",  name: "glottal stop",   example: "uh-oh",     lang: "en", fragment: "ʔʌʔoʊ" },
    { symbol: "ʲ",  name: "palatalised",    example: "хлеб",      lang: "ru", fragment: "xlʲep" },
    { symbol: "tʃ", name: "ch",             example: "ciao",      lang: "it", fragment: "tʃaʊ" },
    { symbol: "dʒ", name: "j (jump)",       example: "già",       lang: "it", fragment: "dʒa" },
  ].freeze
end
