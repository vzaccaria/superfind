.DEFAULT_GOAL := all

.build/0-workflow.js: src/workflow.ls
	lsc -p -c src/workflow.ls > .build/0-workflow.js

lib/workflow.js: .build/0-workflow.js
	@mkdir -p lib/
	cp .build/0-workflow.js $@

.PHONY : lib
lib: lib/workflow.js

.PHONY : all
all: lib

.PHONY : clean-1
clean-1: 
	rm -rf .build/0-workflow.js lib/workflow.js

.PHONY : clean-2
clean-2: 
	rm -rf .build

.PHONY : clean-3
clean-3: 
	mkdir -p .build

.PHONY : clean-4
clean-4: 
	rm -rf lib

.PHONY : clean-5
clean-5: 
	rm -f *.png

.PHONY : clean-6
clean-6: 
	rm -f *.alfredworkflow

.PHONY : clean
clean: clean-1 clean-2 clean-3 clean-4 clean-5 clean-6
