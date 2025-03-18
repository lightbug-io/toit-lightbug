.PHONY: install
install:
	@if command -v jag >/dev/null 2>&1; then \
		echo "Running 'jag pkg install'"; \
		jag pkg install; \
	elif command -v toit.pkg >/dev/null 2>&1; then \
		echo "Running 'toit.pkg install'"; \
		toit.pkg install; \
	else \
		echo "Error: Neither 'jag' nor 'toit.pkg' found in PATH"; \
		exit 1; \
	fi

.PHONY: test
test: install-tests
	@FAILED=0; \
	if command -v jag >/dev/null 2>&1; then \
		find tests -type d -name '.packages' -prune -o -type f \( -name '*_test.toit' -o -name '*.test.toit' \) -exec sh -c 'echo Running {} && jag run --device host {} || FAILED=1' \; ; \
	elif command -v toit.run >/dev/null 2>&1; then \
		find tests -type d -name '.packages' -prune -o -type f \( -name '*_test.toit' -o -name '*.test.toit' \) -exec sh -c 'echo Running {} && toit.run {} || FAILED=1' \; ; \
	else \
		echo "Error: Neither 'jag' nor 'toit.run' found in PATH"; \
		exit 1; \
	fi; \
	if [ $$FAILED -ne 0 ]; then \
		exit 1; \
	fi

.PHONY: install-tests
install-tests:
	@cd tests && $(MAKE) install