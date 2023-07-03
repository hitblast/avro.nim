# Imports.
import std/[
    json,
    tables,
    unittest
]
import avropkg/[
    main,
    private/dictionary
]


#[
    The code written below represents the unit tests associated with the main components of the library.
    Modification without justification is discouraged.
]#


test "test patterns without rules from config":
    ## Tests all patterns from config that don't have rules.

    for pattern in PATTERNS:
        if "rules" notin pattern:
            if pattern{"find"} != nil:
                check pattern["replace"].getStr() == parse(pattern["find"].getStr())


test "test patterns without rules not from config":
    ## Tests all patterns not from config that don't have rules.
    ## 
    ## This test is done in addition to test_patterns_without_rules_from_config() 
    ## to ensure that text passed manually to parse() are properly parsed when 
    ## they don't exact match a pattern that has no rules specified.

    let conjunctions = {
        "ভ্ল": parse("bhl"),
        "ব্ধ": parse("bdh"),
        "ড্ড": parse("DD"),
        "স্তব্ধ বক": parse("stbdh bk")  # Stunned stork!
    }.toTable

    for key, value in conjunctions:
        check key == value


test "test patterns - numbers":
    ## Test patterns (numbers).

    let numbers = {
        "০": parse("0"),
        "১": parse("1"),
        "২": parse("2"),
        "৩": parse("3"),
        "৪": parse("4"),
        "৫": parse("5"),
        "৬": parse("6"),
        "৭": parse("7"),
        "৮": parse("8"),
        "৯": parse("9")
    }.toTable

    for key, value in numbers:
        check key == value


test "test patterns - punctuations":
    ## Test patterns (punctuations).

    let punctuations = {
        "।": parse("."), 
        "।।": parse(".."),
        "...": parse("...")
    }.toTable

    for key, value in punctuations:
        check key == value


test "test patterns with rules (shoroborno)":
    ## Test patterns with rules - shoroborno (derived from Bengali).

    let shoroborno = {
        "অ": parse("o"),
        "আ": parse("a"),
        "ই": parse("i"),
        "ঈ": parse("I"),
        "উ": parse("u"),
        "ঊ": parse("oo"),
        "ঊ": parse("U"),
        "এ": parse("e"),
        "ঐ": parse("OI"),
        "ও": parse("O"),
        "ঔ": parse("OU"),
    }.toTable

    for key, value in shoroborno:
        check key == value


test "test non-ASCII characters":
    let nonAscii = {
        "ব": parse("ব"),
        "অভ্র": parse("অভ্র"),
        "বআবা গো": parse("বaba gO"),  # Mixed strings.
        "আমি বাংলায় গান গাই": parse("aমি বাংলায় gaন গাi"),
    }.toTable

    for key, value in nonAscii:
        check key == value


test "test words with punctuations":
    let wordsWithPunctuations = {
        "আয়রে,": parse("ayre,"),
        "ভোলা;": parse("bhOla;"),
        "/খেয়াল": parse("/kheyal"),
        "খোলা|": parse("khOla|"),
    }.toTable

    for key, value in wordsWithPunctuations:
        check key == value


test "test sentences (default / unicode)":
    check "আমি বাংলায় গান গাই" == parse("ami banglay gan gai")
