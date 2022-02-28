#!/bin/sh

set -eux

main() {
  local dockerfile_path
  dockerfile_path="${1}"

  local registry_path
  registry_path="${2}"

  # Start Docker
  /usr/local/bin/dockerd-entrypoint.sh &

  # Docker takes a few seconds to initialize
  while (! docker stats --no-stream > /dev/null 2>&1 ); do
    sleep 1
  done

  # Login into ECR
  cat "${REGISTRY_PASSOWRD}" | docker login --username "${REGISTRY_USERNAME}" --password-stdin

  # Build docker image...
  cd "${dockerfile_path}"
  docker build -t "${registry_path}" .
  local docker_build_exitcode
  docker_build_exitcode="${?}"

  docker tag "${registry_path}":latest "${registry_path}":v$(date +%Y%d%m-$(git log -1 --pretty=%h))
  docker push "${registry_path}":v$(date +%Y%d%m-$(git log -1 --pretty=%h))

  # Stop Docker background job
  kill %1

  # Exit with exit code of docker build
  exit ${docker_build_exitcode}
}

main ${@}
