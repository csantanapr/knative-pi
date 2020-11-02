# Build arm64 container image for nodejs

1. Install Docker-Desktop with experimental enable follow instructions here https://www.docker.com/blog/multi-arch-images/
1. Create a new builder if you don't have one already
    ```bash
    docker buildx create --name mybuilder
    ```
1. Configure your docker registry
    ```bash
    export DOCKER_HUB_USER=csantanapr
    ```
1. change directory to the root of the go app
    ```bash
    cd apps/helloworld-nodejs
    ```
1. Build and Push the image
    ```bash
    docker buildx build --platform linux/amd64,linux/arm64 -t ${DOCKER_HUB_USER}/helloworld-nodejs:latest --push .
    ```
1. Deploy as Knative service
    ```bash
    kn service create helloworld-nodejs --image docker.io/${DOCKER_HUB_USER}/helloworld-nodejs
    ```