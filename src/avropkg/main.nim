# Imports.
import std/[
    json,
    options,
    strutils,
    strformat,
    sugar,
    unicode
]

import private/[
    dictionary,
    utils/validate
]

# Declaring different types of patterns.
let
    RULE_PATTERNS*: seq[JsonNode] = collect:
        for pattern in PATTERNS:
            if "rules" in pattern: pattern

    NON_RULE_PATTERNS*: seq[JsonNode] = collect:
        for pattern in PATTERNS:
            if "rules" notin pattern: pattern

# Procs.
proc exactFindInPattern(fixed_text: string, reversed: bool, cur: int = 0, patterns: seq[JsonNode]): seq[JsonNode] =
    ## Returns pattern items that match given text, cursor position and pattern.
    
    var list: seq[JsonNode] = @[]

    if reversed:
        list = collect:
            for p in patterns:
                let compare = p["replace"].getStr()

                if (
                    (cur + len(compare) + 1 <= len(fixed_text) - 1) and 
                    (compare == fixed_text[cur + 1 .. (cur + len(compare) - 1)])
                ):
                    p
    else:
        list = collect:
            for p in patterns:
                if hasKey(p, "find"):
                    let compare = p["find"].getStr()
                    if (
                        (cur + len(compare) <= len(fixed_text)) and
                        compare == fixed_text[cur .. (cur + len(compare) - 1)]
                    ):
                        p
    return list


proc reverseWithRules(cur: int, fixed_text: string, text_reversed: string): string =
    ## Enhances the word with rules for reverse-parsing.

    var added_suffix = ""
    let primary_char = $fixed_text[cur]

    if not (
        (primary_char in KAR) or 
        (primary_char in SHORBORNO) or 
        (primary_char in IGNORE) or 
        (len(fixed_text) == cur + 1)
    ):
        added_suffix = "o"

    try:
        if (
            ($fixed_text[cur + 1] in KAR) or 
            (($fixed_text[cur + 2] in KAR) and (not cur == 1))
        ):
            added_suffix = ""

    except IndexDefect:
        discard

    if text_reversed == "": 
        return text_reversed
    else: 
        return fmt"{text_reversed}{added_suffix}"
                

proc matchPatterns(fixed_text: string, cur: int = 0, rule: bool = false, reversed: bool = false): JsonNode =
    ## Matches given text at cursor position with rule / non rule patterns.
    ## 
    ## Returns a dictionary of three elements:
    ## - `matched` - Bool: depending on if match found.
    ## - `found` - string/None: Value of matched pattern's 'find' key or none.
    ## - `replaced` - string: Replaced string if match found else input string at cursor.

    let 
        rule_type = if rule: RULE_PATTERNS else: NON_RULE_PATTERNS
        pattern = exactFindInPattern(fixed_text, reversed, cur, rule_type)

    if len(pattern) > 0:
        if not rule:
            return %* {
                "matched": true,
                "found": pattern[0]{"find"}.getStr(),
                "replaced": pattern[0]{"replace"}.getStr(),
                "reversed": reverseWithRules(cur, fixed_text, pattern[0]{"reverse"}.getStr())
            }
        else:
            return %* {
                "matched": true,
                "found": pattern[0]["find"],
                "replaced": pattern[0]["replace"],
                "rules": pattern[0]["rules"]
            }
    else:
        var node = %* {
            "matched": false,
            "found": nil,
            "replaced": $fixed_text[cur]
        }
        if rule: node["rules"] = nil
        return node


proc processMatch(match: JsonNode, fixed_text: string, cur: int, cur_end: int): bool =
    ## Processes a single match in rules.
    
    # Initial/default value for replace.
    var replace = true

    # Set check cursor depending on match['type']
    let
        match_type = match["type"].getStr()
        chk = if match_type == "prefix": cur - 1 else: cur_end

    # Set scope based on whether scope is negative.
    let scope_var = match["scope"].getStr()
    var 
        scope: string
        negative: bool

    if ($scope_var).startswith("!"):
        scope = scope_var[1 .. ^1]
        negative = true
    else:
        scope = scope_var
        negative = false

    # Let the matching begin!
    if scope == "punctuation":
        if (
            not (
                (chk < 0 and match_type == "prefix") or
                (chk >= len(fixed_text) and match_type == "suffix") or
                isPunctuation($fixed_text[chk])
            ) != negative
        ):
            replace = false

    elif scope == "vowel":
        if (
            not (
                (
                    (chk >= 0 and match_type == "prefix") or
                    (chk < len(fixed_text) and match_type == "suffix")
                ) and isVowel($fixed_text[chk])
            ) != negative
        ):
            replace = false

    elif scope == "consonant":
        if (
            not (
                (
                    (chk >= 0 and match_type == "prefix") or 
                    (chk < len(fixed_text) and match_type == "suffix")
                ) and isConsonant($fixed_text[chk])
            ) != negative
        ):
            replace = false

    elif scope == "exact":
        var exact_start, exact_end: int
        let match_value = match["value"].getStr()

        if match_type == "prefix":
            exact_start = cur - len(match_value)
            exact_end = cur
        else:
            exact_start = cur_end
            exact_end = cur_end + len(match_value)

        if not isExact(match_value, fixed_text, exact_start, exact_end, negative):
            replace = false

    return replace


proc processRules(rules: JsonNode, fixed_text: string, cur: int = 0, cur_end: int = 1): Option[string] =
    ## Process rules matched in pattern and returns suitable replacement.
    ## 
    ## If any rule's condition is satisfied, output the rules "replace", else output none.

    var 
        replaced: string
        matched: bool

    # Iterate through rules.
    for rule in rules:
        matched = false

        for match in rule["matches"]:
            matched = processMatch(match, fixed_text, cur, cur_end)

            if not matched:
                break

        if matched:
            replaced = rule["replace"].getStr()
            break

    return if matched: some(replaced) else: none(string)





proc parse*(text: string, ascii_mode: bool = false): string =
    ## Parses input text, matches and replaces using Avro Dictionary.
    ## 
    ## If a valid replacement is found, then it returns the replaced string.
    ## If no replacement is found, then it instead returns the input text.
    ## 
    ## Parameters:
    ## - `text` (string): The text to parse.
    ## - `ascii_mode` (bool): Output in ASCII format. Defaults to false.
    ## 
    ## Usage:
    
    # Sanitize text case to meet phonetic comparison standards.
    let fixed_text = fixStringCase(text)

    var
        output: seq[string] = @[]  # Output list.
        cur_end: int = 0  # Cursor end point.

    # Iterate through input text.
    for cur, i in fixed_text:
        let text = $i
        var uni_pass: bool
        
        if validateUtf8(text) == -1:
            uni_pass = true
        else:
            uni_pass = false

        var match = %* {"matched": false}

        if not uni_pass:
            cur_end = cur + 1
            output.add(text)

        elif cur >= cur_end and uni_pass:
            match = matchPatterns(fixed_text, cur, rule=false)

            var
                matched = match["matched"].getBool()
                found = match["found"].getStr()
                replaced = match["replaced"].getStr()

            if matched:
                output.add(replaced)
                cur_end = cur + len(found)

            else:
                match = matchPatterns(fixed_text, cur, rule=true)
                
                # resign modified value
                matched = match["matched"].getBool()
                found = match["found"].getStr()
                replaced = match["replaced"].getStr()

                if matched:
                    cur_end = cur + len(found)
                    let processed = processRules(match["rules"], fixed_text, cur, cur_end)

                    if processed.isSome:
                        output.add(processed.get())
                    else:
                        output.add(replaced)

            if not matched:
                cur_end = cur + 1
                output.add(text)

    return join(output, "")