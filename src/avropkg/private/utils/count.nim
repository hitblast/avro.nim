# Imports.
import strutils
import ./../dictionary


# Procs.
proc countVowels*(text: string): int =  ## Count number of occurrences of vowels in a given string.
    var count = 0

    for i in text:
        if toLower($i) in VOWELS:
            count += 1

    return count


proc countConsonants*(text: string): int =  ## Count number of occurrences of consonants in a given string.
    var count = 0

    for i in text:
        if toLower($i) in CONSONANTS:
            count += 1

    return count