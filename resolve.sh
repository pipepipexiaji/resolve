#!/bin/bash

cmdName="resolve"
cmdVersion="0.1.2"

function main() {
    base="$1"
    suf="$2"
    
    if [[ -z "$base" || "$base" == '-h' ]]; then
        showUsage
        return 1
    fi
    
    stringResolve "$base" "$suf"
}

function showUsage() {
    echo "$cmdName $cmdVersion"
    echo "Usage: $cmdName basePath [relPath]"
    echo
    echo "Resolves a relative path against a base path or URI. Given only a basePath,"
    echo "simplifies it."
    echo
    echo "Examples:"
    echo "\$ $cmdName /path/to/base ../hello/world/program//"
    echo "/path/to/hello/world/program/"
    echo
    echo "\$ $cmdName http://example.com/catalog ../app1/download/file.tar.bz2"
    echo "http://example.com/app1/download/file.tar.bz2"
    echo
    echo "\$ $cmdName /messy/../../complicated////../path/before/../tidied"
    echo "/path/tidied"
}

function stringResolve() {
    base="$1"
    suf="$2"
    
    suf="$(simplifyFilePath "$suf")"
    domain="$(getDomain "$base")"
    basePath="${base#$domain}"
    if [[ "$basePath" != */ && -n "$suf" ]]; then
        basePath="$basePath"/
    fi
    if [[ "$suf" == /* ]]; then
        result="$suf"
    else
        result="$basePath$suf"
    fi
    result="$(simplifyFilePath "$result")"
    result="$domain$result"
    echo "$result"
}

function simplifyFilePath() {
    path="$1"
    path="$(removeSingleDots "$path")"
    path="$(stripRepeatedSlashes "$path")"
    path="$(simplifyDoubleDots "$path")"
    path="$(stripRepeatedSlashes "$path")"
    echo "$path"
}

function removeSingleDots() {
    result="$(echo "$1" | sed 's@/\./@/@g')"
    [[ "$result" == "./"* ]] && result="${result#./}"
    echo "$result"
}

function stripRepeatedSlashes() {
    echo "$1" | sed 's@///*@/@g'
}

function simplifyDoubleDots() {
# assumes that $1 has been passed through
# removeSingleDots and stripRepeatedSlashes
    pre=''
    work="$1"
    
    if [[ "$work" == "/"* ]]; then
        pre='/'
        work="${work#/}"
    fi
    while [[ -n "$work" ]]; do
        if  [[ "$work" == "../"* ]]; then
            work="${work#../}"
            if [[ "$pre" == *'../' || -z "$pre" ]]; then
                pre="${pre}../"
            elif [[ "$pre" == / ]]; then
                pre=/
            else
                pre="$(dirname "$pre")/"
            fi 
        elif [[ "$work" == ?*/* ]]; then
            pre="${pre}${work%%/*}/"
            work="${work#*/}"
        else
            pre="${pre}${work}"
            work=''
        fi
    done
    echo "$pre"
}

function getDomain() {
    path="$1"
    scheme="$(getScheme "$path")"
    if [[ -z "$scheme" ]]; then
        return
    fi
    result="$scheme"
    path="${path#$scheme}"
    while [[ "$path" == /* ]]; do
        result="$result"/
        path="${path#/}"
    done
    result="$result${path%%/*}"
    echo "$result"
}

function getScheme() {
    path="$1"
    echo "$path" | grep -o '^[a-zA-Z][a-zA-Z0-9+\-\.]*:'
}

# if not sourcing, run main
if [[ "$0" != "-bash" ]]; then
    main "$@"
fi

