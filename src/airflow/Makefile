# Discover all subdirectories that contain a local 'Makefile'
DIRS ?= $(patsubst %/Makefile,%,$(wildcard */Makefile))

.PHONY: build

## build: Loop through modified or discovered directories and trigger child compilation
build:
	@for dir in $(DIRS); do \
		if [ -d "$$dir" ] && [ -f "$$dir/Makefile" ]; then \
			echo "--> Accessing directory for build: $$dir"; \
			$(MAKE) -C $$dir build || exit 1; \
		fi; \
	done
	@echo "All specified services verified successfully."

