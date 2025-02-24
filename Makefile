.PHONY: test
test:
	@if command -v jag >/dev/null 2>&1; then \
		find tests -type d -name '.packages' -prune -o -type f \( -name '*_test.toit' -o -name '*.test.toit' \) -exec sh -c 'echo Running {} && jag run --device host {}' \; ; \
	elif command -v toit.run >/dev/null 2>&1; then \
		find tests -type d -name '.packages' -prune -o -type f \( -name '*_test.toit' -o -name '*.test.toit' \) -exec sh -c 'echo Running {} && toit.run {}' \; ; \
	else \
		echo "Error: Neither 'jag' nor 'toit.run' found in PATH"; \
		exit 1; \
	fi