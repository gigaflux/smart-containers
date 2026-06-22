
# Discover all subdirectories that contain a local 'Makefile'
DIRS ?= $(patsubst %/Makefile,%,$(wildcard src/*/Makefile))

.PHONY: build clean init up down

## build: Loop through modified or discovered directories and trigger child compilation
build:
	@for dir in $(DIRS); do \
		if [ -d "$$dir" ] && [ -f "$$dir/Makefile" ]; then \
			echo "--> Accessing directory for build: $$dir"; \
			$(MAKE) -C $$dir build || exit 1; \
		fi; \
	done
	@echo "All specified services verified successfully."


## clean: Delegate cleanup target to child directories
clean:
	@for dir in $(DIRS); do \
		if [ -d "$$dir" ] && [ -f "$$dir/Makefile" ]; then \
			$(MAKE) -C $$dir clean; \
		fi; \
	done
	@echo "Cleaning up dangling local Docker build cache layers..."
	@docker image prune -f
	@docker buildx prune -f
	@docker volume prune -f

## init
init:
	@bash ./src/airflow/init.sh

## run
up:
	docker compose --project-directory ./src/airflow -f ./src/airflow/docker-compose.yml up -d

## down
down:
	docker compose --project-directory ./src/airflow -f ./src/airflow/docker-compose.yml rm -f -s
