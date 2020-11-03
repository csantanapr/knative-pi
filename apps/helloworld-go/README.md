# Build arm64 container image for go

1. Install `ko` version `v0.6.0`+ from https://github.com/google/ko
1. Setup your docker registry info, replace the value of `DOCKER_HUB_USER`
    ```bash
    export DOCKER_HUB_USER=csantanapr
    export KO_DOCKER_REPO="docker.io/${DOCKER_HUB_USER}"
    ```
1. change directory to the root of the go app
    ```bash
    cd apps/helloworld-go
    ```
1. Publish container image for all architecture types including `arm64`
    ```bash
    ko publish --platform=all -B .
    ```
1. Deploy as Knative service
    ```bash
    kn service create helloworld-go --image ${KO_DOCKER_REPO}/helloworld-go
    ```
1. Run the app
    ```bash
    curl $(kn service describe helloworld-go -o url)
    ```