#!/bin/sh
# Builds the Monthly submission from critical-values-AMM.tex, body.tex and
# abstract.tex (the last two are copied here from paper/ by `make amm`).
#   manuscript_author/     manuscript with author details, self-contained
#   manuscript_anonymous/  manuscript without author details, self-contained
#   cover_letter.pdf
# Each manuscript folder holds its own .tex (the wrapper with the anonymity
# switch set), body.tex, abstract.tex, the .bib and .bbl, the style file and
# the .bst, and the PDF, so it compiles on its own with pdflatex and bibtex.
set -e
cd "$(dirname "$0")"
for v in author anonymous; do
  d=manuscript_$v
  mkdir -p "$d"
  cp body.tex abstract.tex references.bib maa-monthly.sty vancouver.bst "$d/"
  if [ "$v" = anonymous ]; then sw='\\anonymoustrue'; else sw='\\anonymousfalse'; fi
  perl -pe 's/^\\ifdefined\\anonymous\\anonymoustrue\\else\\anonymousfalse\\fi$/'"$sw"'/' \
    critical-values-AMM.tex > "$d/$d.tex"
  (
    cd "$d"
    pdflatex -interaction=nonstopmode "$d" >/dev/null
    bibtex "$d" >/dev/null
    pdflatex -interaction=nonstopmode "$d" >/dev/null
    pdflatex -interaction=nonstopmode "$d" >/dev/null
    rm -f ./*.aux ./*.blg ./*.out
  )
done
pdflatex -interaction=nonstopmode cover_letter >/dev/null
echo "built manuscript_author/manuscript_author.pdf, manuscript_anonymous/manuscript_anonymous.pdf, cover_letter.pdf"
