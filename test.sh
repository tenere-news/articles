#!/bin/bash
set -euo pipefail

tmpfile="$(mktemp /tmp/article.XXXXXX)"
for article in './_template/article.md' ./articles/*/article.md 
do
    echo "Using article: ${article}; in tmpfile: ${tmpfile}"

    meta_file="$(dirname "${article}")/meta.yaml"
    echo "Using meta file: ${meta_file}"
    yamllint "${meta_file}"
    # Grab the language setting and strip the spaces
    lang=$(grep -P '^language: ' "${meta_file}" | cut -d: -f2 | sed 's/ //g')
    echo "Using lanague: ${lang}"

    comrak --extension table --extension strikethrough --to html "${article}" > "${tmpfile}"
    xmllint --html --valid "${tmpfile}" > /dev/null
    echo "Checking for spelling suggestions"

    # Maybe we want to use this list of errors later?
    errors=$(cat "${tmpfile}" | aspell --lang="${lang}" --sug-mode=bad-spellers --mode=html list | tee "${tmpfile}.errors")

    echo ""
    echo " === Article Report ==="
    echo " -- name: $(basename ${article})"
    echo " -- language: ${lang}"
    echo " -- spelling errors: "
    for error in ${errors[@]}
    do
        echo "    - ${error}"
    done
    echo " === End of Report ==="
    echo ""
done
rm -f "${tmpfile}"