# Sourced by setup.sh and teardown.sh: picks the container engine (docker or podman).
# Force one with CONTAINER_ENGINE=docker|podman. Default: Docker if it is the real Docker
# (not the podman-docker shim), otherwise Podman.

if [ -z "${CONTAINER_ENGINE:-}" ]; then
  if command -v docker > /dev/null && ! docker --version 2> /dev/null | grep -qi podman; then
    CONTAINER_ENGINE=docker
  elif command -v podman > /dev/null; then
    CONTAINER_ENGINE=podman
  else
    echo "Docker or Podman is required" >&2
    exit 1
  fi
fi

case "$CONTAINER_ENGINE" in
  docker)
    COMPOSE=(docker compose)
    MINIKUBE_FLAGS=(--driver=docker)
    ;;
  podman)
    if podman compose version > /dev/null 2>&1; then
      COMPOSE=(podman compose)
    elif command -v podman-compose > /dev/null; then
      COMPOSE=(podman-compose)
    else
      echo "Podman needs a compose provider: install podman-compose or docker-compose" >&2
      exit 1
    fi
    # Rootless Podman does not support the docker runtime inside minikube
    MINIKUBE_FLAGS=(--driver=podman --container-runtime=containerd)
    # Without this, minikube runs "sudo podman" and the cluster lands in root's Podman,
    # where the Jenkins container (started without sudo) cannot reach its network
    if [ "$(podman info --format '{{.Host.Security.Rootless}}')" = true ]; then
      export MINIKUBE_ROOTLESS=true
    fi
    ;;
  *)
    echo "CONTAINER_ENGINE must be docker or podman (got: $CONTAINER_ENGINE)" >&2
    exit 1
    ;;
esac

echo ">> Container engine: $CONTAINER_ENGINE (compose: ${COMPOSE[*]})"
