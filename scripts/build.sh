#!/bin/bash

set -e

PROJECT_NAME="microservices"
REGISTRY="${REGISTRY:-registry.gitlab.com}"
NAMESPACE="${NAMESPACE:-your-namespace/your-project}"
TAG="${TAG:-latest}"

echo "Building microservices..."

echo "Building user-service..."
docker build \
  -t "${REGISTRY}/${NAMESPACE}/user-service:${TAG}" \
  -f services/user-service/Dockerfile \
  services/user-service/

echo "Building order-service..."
docker build \
  -t "${REGISTRY}/${NAMESPACE}/order-service:${TAG}" \
  -f services/order-service/Dockerfile \
  services/order-service/

echo "✓ Build complete!"
echo ""
echo "Images created:"
echo "  - ${REGISTRY}/${NAMESPACE}/user-service:${TAG}"
echo "  - ${REGISTRY}/${NAMESPACE}/order-service:${TAG}"
echo ""
echo "To push images: docker push <image-name>"
