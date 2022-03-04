#!/bin/bash

export dockerfile_path="${1}"
export registry_path="${2}"

# util function
function error {
    printf '\E[31m'; echo "$@"; printf '\E[0m'
}

# runs custom docker data root cleanup binary and debugs remaining resources
cleanup_dind() {
    if [[ "${DOCKER_IN_DOCKER_ENABLED:-false}" == "true" ]]; then
        echo "Cleaning up after docker"
        docker ps -aq | xargs -r docker rm -f || true
        service docker stop || true
    fi
}

# Check for DOCKER_IN_DOCKER_ENABLED
export DOCKER_IN_DOCKER_ENABLED=${DOCKER_IN_DOCKER_ENABLED:-false}
if [[ "${DOCKER_IN_DOCKER_ENABLED}" == "true" ]]; then
    echo "Docker in Docker enabled, initializing..."
    printf '=%.0s' {1..80}; echo
    # If we have opted in to docker in docker, start the docker daemon,
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
            error "Reached maximum attempts, not waiting any longer..."
            exit 1
        fi
    done
    printf '=%.0s' {1..80}; echo
    echo "Done setting up docker in docker."
fi

# Check for REGISTRY creds
export REGISTRY_ENABLED=${REGISTRY_ENABLED:-false}
if [[ "${REGISTRY_ENABLED}" == "true" ]]; then
  echo "Registry is enabled, building and pushing image to ${registry_path}"
  export REGISTRY_USERNAME=${REGISTRY_USERNAME:-false}
  export REGISTRY_PASSWORD=${REGISTRY_PASSWORD:-false}
  export AWS_ACCESS_KEY_ID=$(cat ${AWS_ACCESS_KEY_ID})
  export AWS_SECRET_ACCESS_KEY=$(cat ${AWS_SECRET_ACCESS_KEY})
  # Login into registry
  aws ecr-public get-login-password --region us-east-1 | docker login --username $(cat ${REGISTRY_USERNAME}) --password-stdin public.ecr.aws || { error "Failed to login to ECR"; exit 1; }
  # Build image
  cd "${dockerfile_path}"
  docker build -t "${registry_path}" . || { error "Failed to build image in ${registry_path}"; exit 1; }
  # Push image to registry
  docker tag "${registry_path}":latest "${registry_path}":v$(date +%Y%d%m-$(git log -1 --pretty=%h)) || { error "Failed to tag ${registry_path}:latest"; exit 1; }
  docker push "${registry_path}":v$(date +%Y%d%m-$(git log -1 --pretty=%h)) || { error "Failed to push ${registry_path}:v$(date +%Y%d%m-$(git log -1 --pretty=%h))"; exit 1; }
fi

# cleanup after job
if [[ "${DOCKER_IN_DOCKER_ENABLED}" == "true" ]]; then
    echo "Cleaning up after docker in docker."
    printf '=%.0s' {1..80}; echo
    cleanup_dind
    printf '=%.0s' {1..80}; echo
    echo "Done cleaning up after docker in docker."
fi

