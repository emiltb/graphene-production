JOURNALS = $(wildcard lab_journal/*)

default: lab_journal.html
	Rscript -e "browseURL('$(<F)')"

lab_journal.html: lab_journal.Rmd $(JOURNALS)
	Rscript -e "rmarkdown::render('$(<F)')"
	rm -f includes.Rmd

.PHONY: clean
clean:
	rm -rf includes.Rmd lab_journal_cache/ lab_journal_files/ lab_journal.html lab_journal.md
