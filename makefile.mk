include makefile

pack: all
	rm -f *.png
	./tools/genplist.ls
	./pack-this.sh
