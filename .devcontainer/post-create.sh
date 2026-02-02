#!/bin/bash
set -e

echo "🐳 Setting up Container Fundamentals environment..."

# Verify Docker is working
echo "Verifying Docker installation..."
docker --version
docker compose version

# Pull commonly used images to save time during labs
echo "Pre-pulling common images (this may take a minute)..."
docker pull python:3.11-slim &
docker pull python:3.11-alpine &
docker pull nginx:alpine &
docker pull busybox:latest &
wait

echo "Verifying Python..."
python3 --version
pip3 --version

# Create a student workspace directory
mkdir -p ~/labs

echo ""
echo "✅ Environment setup complete!"
echo ""
echo "Quick verification:"
echo "  docker run hello-world"
echo ""
echo "To get started with Week 1:"
echo "  cd week-01/labs"
echo ""
