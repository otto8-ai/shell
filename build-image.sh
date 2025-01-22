#!/bin/sh
gh auth token > github-token
trap "rm github-token" EXIT
docker buildx build --platform linux/arm64,linux/amd64 -f Dockerfile --secret id=github-token -t ghcr.io/otto8-ai/shell . "$@"
