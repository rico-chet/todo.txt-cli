#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

shellcheck "${0}"

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

	WORKDIR /root
EOF
)"

repo_name="$(basename "$(git rev-parse --show-toplevel)")"

container_script="$(cat <<-EOF
	set -o errexit

	cp --recursive "${repo_name}" "${repo_name}-rw"
	cd "${repo_name}-rw"
	export BUILD_DIR="\$(pwd)"
	make install
	todo.sh -h
EOF
)"

docker run                                      \
	--interactive                           \
	--rm                                    \
	--tty                                   \
	--volume "$(pwd):/root/${repo_name}:ro" \
	--workdir "/root"                       \
	"${image_id}"                           \
	sh -c "${container_script}"             \
	;
