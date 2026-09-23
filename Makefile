# The paper in its three forms, all built from the shared paper/body.tex and
# paper/abstract.tex.
#   make paper   paper/critical-values.pdf          (XeLaTeX, biber)
#   make arxiv   arxiv/critical-values-arxiv.pdf    (pdfLaTeX) and the arXiv tarball
#   make amm     AMM/manuscript_author/ and AMM/manuscript_anonymous/ (each
#                self-contained, with its PDF) and the cover letter
#   make all     all three
SHARED = paper/body.tex paper/abstract.tex

.PHONY: all paper arxiv amm clean

all: paper arxiv amm

paper: paper/critical-values.pdf

paper/critical-values.pdf: paper/critical-values.tex paper/refs.bib $(SHARED)
	cd paper && latexmk -xelatex -interaction=nonstopmode critical-values.tex

arxiv/body.tex: paper/body.tex
	cp $< $@

arxiv/abstract.tex: paper/abstract.tex
	cp $< $@

arxiv: arxiv/critical-values-arxiv.pdf arxiv/critical-values-arxiv.tar.gz

arxiv/critical-values-arxiv.pdf: arxiv/critical-values-arxiv.tex arxiv/body.tex arxiv/abstract.tex
	cd arxiv && latexmk -pdf -interaction=nonstopmode critical-values-arxiv.tex

arxiv/critical-values-arxiv.tar.gz: arxiv/critical-values-arxiv.pdf
	cd arxiv && tar czf critical-values-arxiv.tar.gz critical-values-arxiv.tex body.tex abstract.tex qr-repo.png qr-site.png

AMM/body.tex: paper/body.tex
	cp $< $@

AMM/abstract.tex: paper/abstract.tex
	cp $< $@

amm: AMM/body.tex AMM/abstract.tex
	sh AMM/build.sh

clean:
	cd paper && latexmk -C critical-values.tex
	cd arxiv && latexmk -C critical-values-arxiv.tex
	rm -f AMM/*.aux AMM/*.log AMM/*.bbl AMM/*.blg AMM/*.out
