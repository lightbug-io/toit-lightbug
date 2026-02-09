.PHONY: install
install:
	@if command -v jag >/dev/null 2>&1; then \
		echo "Running 'jag pkg install'"; \
		jag pkg install; \
	elif command -v toit.pkg >/dev/null 2>&1; then \
		echo "Running 'toit.pkg install'"; \
		toit.pkg install; \
	elif command -v toit >/dev/null 2>&1; then \
		echo "Running 'toit pkg install'"; \
		toit pkg install; \
	else \
		echo "Error: Neither 'jag' nor 'toit.pkg' or 'toit' found in PATH"; \
		exit 1; \
	fi

# We need a blocking jag run in order for this to work properly for things like BLE scans
.PHONY: test
test: install-tests
	@DEVICE_TARGET=$${DEVICE:-host}; \
	if [ "$$DEVICE_TARGET" != "host" ]; then \
		echo "⚠️  WARNING: Running tests on device ($$DEVICE_TARGET) instead of host."; \
		echo "   Some tests may exit early due to timing issues with long-running operations (BLE scans, etc.)"; \
		echo "   For complete test results, consider running on host: make test DEVICE=host"; \
		echo ""; \
	fi; \
	FAILED=0; \
	if command -v jag >/dev/null 2>&1; then \
		find tests -type d -name '.packages' -prune -o -type f \( -name '*_test.toit' -o -name '*.test.toit' \) -exec sh -c 'echo Running {} && jag run --device $${DEVICE:-host} {} || FAILED=1' \; ; \
	elif command -v toit.run >/dev/null 2>&1; then \
		find tests -type d -name '.packages' -prune -o -type f \( -name '*_test.toit' -o -name '*.test.toit' \) -exec sh -c 'echo Running {} && toit.run --device $${DEVICE:-host} {} || FAILED=1' \; ; \
	elif command -v toit >/dev/null 2>&1; then \
		find tests -type d -name '.packages' -prune -o -type f \( -name '*_test.toit' -o -name '*.test.toit' \) -exec sh -c 'echo Running {} && toit run --device $${DEVICE:-host} {} || FAILED=1' \; ; \
	else \
		echo "Error: Neither 'jag' nor 'toit.run' or 'toit' found in PATH"; \
		exit 1; \
	fi; \
	if [ $$FAILED -ne 0 ]; then \
		exit 1; \
	fi

.PHONY: install-tests
install-tests:
	@cd tests && $(MAKE) install