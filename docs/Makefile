prg:
	# build programmer's reference guide documentation
	asciidoctor -r asciidoctor-lists prg-master.adoc -o prg-master.html
	asciidoctor -r asciidoctor-pdf   prg-master.adoc -o prg-master.pdf

sysop:
	# build sysop documentation
	asciidoctor -r asciidoctor-lists master.adoc -o sysop-master.html
	asciidoctor -r asciidoctor-pdf   master.adoc -o sysop-master.pdf

all: prg sysop

clean:
	rm --force *.pdf *.html
