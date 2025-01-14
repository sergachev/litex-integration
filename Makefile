DOCKER_LITEX_ENV_COMPOSE_FILE=submodules/docker-litex-env-composed/docker-compose.yml
USER_ID=$(shell id -u ${USER})
# This is the home created inside the image
IMAGE_HOME=/home/user
# Submodules folder
SUBMODULES=submodules
# Litex env composed
LITEX_ENV_COMPOSED_REPO=docker-litex-env-composed
# Firmware folder
FIRMWARE_DIR=litex-integration/firmware

# Passed to litex top-level script
SOC_ARGS?=litex.boards.platforms.arty
# TTY device
TTY_DEV?=/dev/ttyUSB1

# Variables passed to docker-compose
# Xilinx PATH
XIL_PATH?=/opt/Xilinx
# Vivado version
VIVADO_VER?=2019.1

DOCKER_IMAGE="litex-env"
# Docker command defualt options

.PHONY: run prepare-env clean sanity

run: sanity prepare-env
	bash -c " \
		export XIL_PATH=$(XIL_PATH) && \
		export VIVADO_VER=$(VIVADO_VER) && \
		docker-compose -f $(DOCKER_LITEX_ENV_COMPOSE_FILE) \
		run \
		--rm \
		-e LOCAL_USER_ID=$(USER_ID) \
		-v "${PWD}"/litex-integration:/litex-integration \
		-v "${PWD}"/build:/build \
		$(DOCKER_IMAGE) \
		python3 /litex-integration/simple.py $(SOC_ARGS)"

%.bin:
	bash -c " \
		export XIL_PATH=$(XIL_PATH) && \
		export VIVADO_VER=$(VIVADO_VER) && \
		docker-compose -f $(DOCKER_LITEX_ENV_COMPOSE_FILE) \
		run \
		--rm \
		-e LOCAL_USER_ID=$(USER_ID) \
		-v "${PWD}"/litex-integration:/litex-integration \
		-v "${PWD}"/build:/build \
		$(DOCKER_IMAGE) \
		make -C /litex-integration/firmware all"

download_%: $(FIRMWARE_DIR)/%.bin
	bash -c " \
		export XIL_PATH=$(XIL_PATH) && \
		export VIVADO_VER=$(VIVADO_VER) && \
		docker-compose -f $(DOCKER_LITEX_ENV_COMPOSE_FILE) \
		run \
		--rm \
		--entrypoint '/bin/bash -c' \
		-v "${PWD}"/litex-integration:/litex-integration \
		-v "${PWD}"/build:/build \
		$(DOCKER_IMAGE) \
		\"python3 /litex/litex/litex/soc/tools/litex_term.py \
			--kernel \
			/litex-integration/firmware/firmware.bin \
			$(TTY_DEV)\""

# Check if repo was cloned --recursive
sanity:
	if [ -z "$(shell ls -A $(SUBMODULES)/$(LITEX_ENV_COMPOSED_REPO))" ]; then \
		git submodule update --init; \
	fi

prepare-env:
	mkdir -p build

clean:
	rm -rf build
