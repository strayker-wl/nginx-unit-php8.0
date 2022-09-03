ifneq ("$(wildcard .env)","")
	include .env
endif

build:
	docker build -t ${TAG} --no-cache --build-arg tz="${TZ}" --build-arg ubuntu_release="${UBUNTU_RELEASE}" --build-arg unit_version="${UNIT_VERSION}" --build-arg php_version="${PHP_VERSION}" .
