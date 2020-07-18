#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

shellcheck "${0}"

#base_img="${1}"
#FROM "\${base_img}"

image_id="$(docker build --quiet - <<-EOF
	FROM debian:stable-slim

	RUN export DEBIAN_FRONTEND=noninteractive \
		&& apt-get update && apt-get dist-upgrade
	RUN export DEBIAN_FRONTEND=noninteractive                 \
		&& apt-get update && apt-get install --assume-yes \
			make                                      \
			stow                                      \
		;

	RUN export DEBIAN_FRONTEND=noninteractive                 \
		&& apt-get update && apt-get install --assume-yes \
			apt-utils                                 \
			bash-completion                           \
			dialog                                    \
			less                                      \
			sudo                                      \
			vim                                       \
		;

	RUN export DEBIAN_FRONTEND=noninteractive                 \
		&& apt-get update && apt-get install --assume-yes \
			locales-all                               \
		;
	ENV LANG     en_US.UTF-8
	ENV LANGUAGE en_US.UTF-8
	ENV LC_ALL   en_US.UTF-8
	ENV TERM=${TERM}

	RUN addgroup --gid $(id --group) $(id --group --name)
	RUN adduser --gid $(id --group) \
		--shell /bin/bash \
		--uid $(id --user) $(id --user --name)
	RUN echo "$(id --user --name) ALL=(ALL) NOPASSWD:ALL" >> \
		/etc/sudoers.d/$(id --user --name)
	WORKDIR /home/$(id --user --name)
	USER $(id --user --name)
EOF
)"

docker run                          \
	--interactive               \
	--rm                        \
	--tty                       \
	--volume "$(pwd):$(pwd):ro" \
	--workdir "$(pwd)"          \
	"${image_id}"               \
	make test
