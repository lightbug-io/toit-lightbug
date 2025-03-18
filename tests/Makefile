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