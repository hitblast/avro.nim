# Imports.
import strutils
import ./../dictionary


# Procs.
proc isVowel*(text: string): bool =  ## Check if given string is a vowel.
    return toLower(text) in VOWELS


proc isConsonant*(text: string): bool =  ## Check if given string is a consonant.
    return toLower(text) in CONSONANTS


proc isNumber*(text: string): bool =  ## Check if given string is a number.
    return toLower(text) in NUMBERS


proc isPunctuation*(text: string): bool =  ## Check if given string is a punctuation.
    return not (toLower(text) in VOWELS or toLower(text) in CONSONANTS)


proc isCaseSensitive*(text: string): bool =  ## Check if given string is case sensitive.
    return toLower(text) in CASESENSITIVES


proc isExact*(needle: string, haystack: string, start: int, ending: int, matchnot: bool): bool =
    ## Check exact occurrence of needle in haystack.

    return (
        start >= 0 and 
        ending < len(haystack) and 
        haystack[start..ending] == needle
    ) != matchnot


proc fixStringCase*(text: string): string =
    ## Converts case-insensitive characters to lower case. 
    ## 
    ## Case-sensitive characters as defined in CASESENSITIVES
    ## retain their case, but others are converted to their lowercase
    ## equivalents. The result is a string with phonetic-compatible case
    ## which will the parser will understand without confusion.
    
    var fixed: seq[string] = @[]

    for i in text:
        let j = $i

        if isCaseSensitive(j):
            fixed.add(j)
        else:
            fixed.add(toLower(j))

    return join(fixed, "")