MAKEFLAGS += --warn-undefined-variables -j1
SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := all
.DELETE_ON_ERROR:
.SUFFIXES:
.PHONY:

# Environment switches
MAKE_ENV ?= docker
MAKE_SUB_ENV ?= false
DOCKER_MOUNT_MODE ?= rw
IMAGE_VENDOR ?= hausgold
PREBUILD_IMAGE_SEARCH ?= kafka-playground
PROJECT_NAME ?= kafka-playground
START ?= foreground
START_CONTAINERS ?= kafka schema-registry schema-registry-ui
COMPOSE_RUN_SHELL_FLAGS ?= --rm
BASH_RUN_SHELL_FLAGS ?=
BUNDLE_FLAGS ?=

# Directories
LOG_DIR ?= log

# Host binaries
AWK ?= awk
BASH ?= bash
CHMOD ?= chmod
COMPOSE ?= docker-compose
CP ?= cp
CUT ?= cut
DOCKER ?= docker
ECHO ?= echo
FIND ?= find
GREP ?= grep
HEAD ?= head
LS ?= ls
MKDIR ?= mkdir
MV ?= mv
NODE ?= node
NPM ?= npm
NPROC ?= nproc
PRINTF ?= printf
RM ?= rm
TAIL ?= tail
TEE ?= tee
TEST ?= test
WC ?= wc
XARGS ?= xargs

# Container binaries
BUNDLE ?= bundle

# Check all binaries which needs to be available
CHECK_BINS ?= AWK BASH CHMOD ECHO HEAD FIND GREP LS MKDIR \
	MV NODE NPM NPROC PRINTF TAIL TEE TEST WC XARGS

ifeq ($(MAKE_ENV),docker)
# Check also the docker binaries
CHECK_BINS += COMPOSE DOCKER
else ifeq ($(MAKE_ENV),baremetal)
# Nothing to do here - just a env check
else
$(error MAKE_ENV got an invalid value. Use `docker` or `baremetal`)
endif

all:
	# Apache Kafka Playground
	#
	# install                 Install the dependencies
	# start                   Start the containers
	# stop                    Stop all running containers
	# logs                    Monitor the started containers
	# update-images           Pull the latest Docker images and rebuild ours
	#
	# shell                   Start an interactive shell session
	#
	# clean                   Clean all temporary application files
	# clean-containers        Clean the Docker containers (also database data)
	# distclean               Same as clean and cleans Docker images

# Check a binary
# $1 - The binary
define check-binary
	$(shell if [ -n "`which g$($(1)) 2>/dev/null`" ]; then \
		echo 'g$($(1))'; \
		elif [ -n "`which $($(1)) 2>/dev/null`" ]; then \
		echo '$($(1))'; \
		else \
		echo '$$(error Neither "$($(1))" nor "g$($(1))" is available ($(1)))'; \
		fi)
endef

# Define a generic shell run wrapper
# $1 - The command to run
ifeq ($(MAKE_ENV),docker)
define run-shell
	$(PRINTF) '# (Docker mount mode: $(DOCKER_MOUNT_MODE))\n'; \
	$(COMPOSE) run $(COMPOSE_RUN_SHELL_FLAGS) \
		-e LANG=en_US.UTF-8 -e LANGUAGE=en_US.UTF-8 -e LC_ALL=en_US.UTF-8 \
		-u app app bash $(BASH_RUN_SHELL_FLAGS) -c 'sleep 0.1; echo; $(1)'
endef
else ifeq ($(MAKE_ENV),baremetal)
define run-shell
	$(1)
endef
endif

# Define a retry helper
# $1 - The command to run
define retry
	if eval "$(call run-shell,$(1))"; then exit 0; fi; \
	for i in 1; do sleep 10s; echo "Retrying $$i..."; \
		if eval "$(call run-shell,$(1))"; then exit 0; fi; \
	done; \
	exit 1
endef

# Check all binaries
_ := $(foreach BIN,$(CHECK_BINS),$(eval $(BIN) := $(call check-binary,$(BIN))))

COMPOSE := $(COMPOSE) -p $(PROJECT_NAME)
PREBUILT_IMAGE ?= $(PROJECT_NAME)_app:latest

.interactive:
	@$(eval BASH_RUN_SHELL_FLAGS = --login)

.not-implemented:
	# Not yet implemented.

install:
	# Install the dependencies
ifeq ($(MAKE_ENV),docker)
	@$(eval INSTALL_NAME = $(PROJECT_NAME)_install)
	@$(eval COMPOSE_RUN_SHELL_FLAGS = --no-deps --name $(INSTALL_NAME))
	@$(DOCKER) rm -f $(INSTALL_NAME) 2>/dev/null || true
endif
	@$(call retry,$(BUNDLE) check || \
		$(BUNDLE) install --jobs $(shell $(NPROC)) \
			--retry 3 $(BUNDLE_FLAGS))
ifeq ($(MAKE_ENV),docker)
	@$(DOCKER) commit $(INSTALL_NAME) $(PREBUILT_IMAGE)
	@$(DOCKER) rm -f $(INSTALL_NAME) 2>/dev/null || true
endif

start: stop
	# Start the application
ifeq ($(START),foreground)
	@$(COMPOSE) up $(START_CONTAINERS)
else
	$(error START got an invalid value. Use `foreground`.)
endif

restart:
	# Restart the application
	@$(MAKE) stop start

logs:
	# Monitor the started application
	@$(COMPOSE) logs -f --tail='all'

stop: clean-containers
stop-containers:
	# Stop all running containers
	@$(COMPOSE) stop -t 5 || true
	@$(DOCKER) ps -a | $(GREP) $(PROJECT_NAME)_ | $(CUT) -d ' ' -f1 \
		| $(XARGS) -rn10 $(DOCKER) stop -t 5 || true

shell:
	# Start an interactive shell session
	@$(call run-shell,$(BASH) -i)

update-images: clean-containers clean-images
	# Pull latest Docker images
	@$(GREP) -Pih 'from|image:' docker-compose.yml Dockerfile \
		| $(GREP) -Po '$(IMAGE_VENDOR).*' \
		| $(XARGS) -rn1 $(DOCKER) pull
	@$(MAKE) install

clean-logs:
	# Clean logs
	@$(RM) -rf $(LOG_DIR)
	@$(MKDIR) -p $(LOG_DIR)

clean-containers: stop-containers
	# Stop and kill all containers
	@$(COMPOSE) rm -vf || true
	@$(DOCKER) ps -a | $(GREP) $(PROJECT_NAME)_ | $(CUT) -d ' ' -f1 \
		| $(XARGS) -rn10 $(DOCKER) rm -vf || true

clean-images: clean-containers
	# Remove all docker images
	$(eval APP_NAME = $(shell $(CUT) -d: -f2 <<< $(PREBUILD_IMAGE_SEARCH)))
	$(eval EMPTY = ) $(eval CLEAN_IMAGES = $(PROJECT_NAME)_ $(PREBUILT_IMAGE))
	$(eval CLEAN_IMAGES += $(PREBUILD_IMAGE_SEARCH) \s+$(APP_NAME): <none>)
	@$(DOCKER) images -a --format '{{.ID}} {{.Repository}}:{{.Tag}}' \
		| $(GREP) -P "$(subst $(EMPTY) $(EMPTY),|,$(CLEAN_IMAGES))" \
		| $(AWK) '{print $$0}' \
		| $(XARGS) -rn1 $(DOCKER) rmi -f 2>&1 \
		| $(GREP) -vP 'cannot be forced|invalid reference' || true

clean: clean-logs clean-containers
distclean: clean clean-images

usage: .not-implemented
docs: .not-implemented
stats: .not-implemented
test: .not-implemented
watch: .not-implemented
