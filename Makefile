.PHONY: cover test test-all

test:
	busted tests

test-all:
	busted tests integration-tests

cover:
	busted --coverage tests integration-tests
	luacov pilosa/*.lua
	cat luacov.report.out
