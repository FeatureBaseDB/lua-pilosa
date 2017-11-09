.PHONY: cover test test-all

test:
	busted tests

test-all:
	busted tests integration-tests

cover: luacov.report.out
	cat luacov.report.out

luacov.report.out: luacov.stats.out
	luacov pilosa/*.lua

luacov.stats.out:
	busted --coverage tests integration-tests

