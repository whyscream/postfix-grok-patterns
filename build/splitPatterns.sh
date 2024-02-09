#!/bin/bash
# needs bash 4.0, cut, grep, sed, cmp

# setup
mkdir -p tmp
rm tmp/*

# loop through all patterns in postfix.grok
while IFS="" read -r line || [ -n "$line" ]
do
    # skip empty and comment lines
    if [[ "$line" == "" || "${line:0:1}" == "#" ]]; then continue; fi

    # cut the name of the pattern
    name=$(echo "$line" | cut -d ' ' -f 1)

    echo "Finding patterns for $name"

    echo "$line" > "tmp/patterns.tmp"

    # loop until all required patterns are found
    while true
    do

        # loop through all patterns that were found so far in patterns.tmp
        while IFS="" read -r pattern || [ -n "$pattern" ]
        do

            # search for %{} placeholder in each line and add its pattern to morePatterns.tmp
            while IFS="" read -r placeholder || [ -n "$placeholder" ]
            do
                grep -E "^$placeholder " "../postfix.grok" >> "tmp/morePatterns.tmp"
            done <<< $( echo "${pattern}" | grep -oE '%{[^:}]+(:[^}]+)?}' | sed -E 's/^%{([^:}]+)(:.*)?}/\1/' )

        done < "tmp/patterns.tmp"

        # combine patterns.tmp and morePatterns.tmp, remove duplicate lines
        cat tmp/patterns.tmp tmp/morePatterns.tmp |sort |uniq > tmp/combinedPatterns.tmp

        # if patterns.tmp and combinedPatterns.tmp are equal we've found all patterns
        if cmp --silent -- "tmp/patterns.tmp" "tmp/combinedPatterns.tmp"; then
           rm tmp/morePatterns.tmp tmp/combinedPatterns.tmp
           break
        fi

        # run once again with the updated set of found patterns
        mv tmp/combinedPatterns.tmp tmp/patterns.tmp
        rm tmp/morePatterns.tmp

    done

    # rename pattern file to actual name of the pattern
    mv tmp/patterns.tmp "tmp/${name}.grok"

done < "../postfix.grok"
