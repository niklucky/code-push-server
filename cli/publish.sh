#!/usr/bin/env sh

VERSION=$1
IMAGE=code-push-cli
echo $VERSION

docker buildx build \
  --platform linux/amd64 \
  --tag "niklucky/$IMAGE:${VERSION}" \
  --tag "niklucky/$IMAGE:latest" \
  .

docker push niklucky/$IMAGE:$VERSION
docker push niklucky/$IMAGE:latest
