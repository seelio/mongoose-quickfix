.PHONY: all test

all:
	@echo "usage:"
	@echo
	@echo "make\t\tshows this help dialog"
	@echo "make test\truns test suite (mocha)"
	@echo "make compile\tcompiles coffee -> js"

test:
	mocha --bail -r lib/test/helpers -R dot lib/test

compile:
	coffee -w -o lib -c src
