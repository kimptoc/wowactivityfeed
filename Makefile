MOCHA_OPTS=-A
REPORTER = dot

check: test

test: coffee-compile test-unit

coffee-compile:
	./node_modules/.bin/coffee --compile --output js/ src/ spec/ src_common
	./node_modules/.bin/coffee --compile --output public/js-cs src_client src_common

test-unit:
	@NODE_ENV=test ./node_modules/.bin/mocha \
		--reporter $(REPORTER) \
		$(MOCHA_OPTS) \
		js/*Spec.js

test-acceptance:
	@NODE_ENV=test ./node_modules/.bin/mocha \
		--reporter $(REPORTER) \
		--bail \
		test/acceptance/*.js

test-cov: lib-cov
	@EXPRESS_COV=1 $(MAKE) test REPORTER=html-cov > coverage.html

lib-cov:
	@jscoverage lib lib-cov

benchmark:
	@./support/bench

clean:
	rm -f coverage.html
	rm -fr lib-cov

.PHONY: test test-unit test-acceptance benchmark clean