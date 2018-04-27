.PHONY: cover test test-all

test:
	busted tests

test-all:
	busted tests integration-tests

cover:
	rm -f luacov.*
	busted --coverage tests integration-tests
	luacov pilosa/*.lua
	cat luacov.report.out
