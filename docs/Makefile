prg:
	# build programmer's reference guide documentation (PDF and HTML),
	# using asciidoctor-lists extension to generate tables of tables & code snippets
	asciidoctor     -r asciidoctor-lists prg-master.adoc -o prg-master.html
	asciidoctor-pdf -r asciidoctor-lists prg-master.adoc -o prg-master.pdf

sysop:
	# build sysop documentation (PDF and HTML),
	# using asciidoctor-lists extension to generate tables of tables & code snippets
	asciidoctor     -r asciidoctor-lists master.adoc -o sysop-master.html
	asciidoctor-pdf -r asciidoctor-lists master.adoc -o sysop-master.pdf

all: prg sysop

clean:
	rm --force *.pdf *.html
