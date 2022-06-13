TAG = ghcr.io/g0dscookie/aptly

push: build
	docker push ${TAG}

build:
	docker build -t ${TAG} .
