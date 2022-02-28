#!/bin/sh

set -eux

main() {
  local dockerfile_path
  dockerfile_path="${1}"

  local registry_path
  registry_path="${2}"

  # Start Docker
  printf '=%.0s' {1..80}; echo
  service docker start
  # the service can be started but the docker socket not ready, wait for ready
  WAIT_N=0
  MAX_WAIT=5
  while true; do
    # docker ps -q should only work if the daemon is ready
    docker ps -q > /dev/null 2>&1 && break
    if [[ ${WAIT_N} -lt ${MAX_WAIT} ]]; then
        WAIT_N=$((WAIT_N+1))
        echo "Waiting for docker to be ready, sleeping for ${WAIT_N} seconds."
        sleep ${WAIT_N}
    else
        echo "Reached maximum attempts, not waiting any longer..."
        break
    fi
  done
  printf '=%.0s' {1..80}; echo
  echo "Done setting up docker in docker."
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
