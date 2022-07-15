MAJOR ?= 1
MINOR ?= 5
PATCH ?= 0

TAG = ghcr.io/g0dscookie/aptly
TAGLIST = -t ${TAG}:${MAJOR} -t ${TAG}:${MAJOR}.${MINOR} -t ${TAG}:${MAJOR}.${MINOR}.${PATCH}
BUILDARGS = --build-arg APTLY_VERSION=v${MAJOR}.${MINOR}.${PATCH}

PLATFORM_FLAGS	= --platform linux/amd64
PUSH ?= --push

build:
	docker buildx build ${PUSH} ${PLATFORM_FLAGS} ${BUILDARGS} ${TAGLIST} .
.PHONY: build

latest: TAGLIST := -t ${TAG}:latest ${TAGLIST}
latest: build
.PHONY: latest
