#!/bin/bash

set -e

echo "Setting up microservices project..."

# Check prerequisites
if ! command -v docker &> /dev/null; then
    echo "✗ Docker is not installed"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "✗ Docker Compose is not installed"
    exit 1
fi

echo "✓ Docker and Docker Compose found"

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    echo "Creating .env file..."
    cat > .env << EOF
# Database Configuration
DB_USER=postgres
DB_PASSWORD=postgres
DB_HOST=user-db
DB_PORT=5432

# AWS Configuration (for Terraform)
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=your-key-id
AWS_SECRET_ACCESS_KEY=your-secret-key

# Container Registry
REGISTRY=registry.gitlab.com
REGISTRY_USER=your-username
REGISTRY_PASSWORD=your-token
EOF
    echo "✓ .env file created (edit with your values)"
fi

# Create Python virtual environment (optional)
if [ ! -d "venv" ]; then
    echo "Creating Python virtual environment..."
    python3 -m venv venv
    source venv/bin/activate
    echo "✓ Virtual environment created"
fi

echo ""
echo "✓ Setup complete!"
echo ""
echo "Next steps:"
echo "1. Edit .env file with your configuration"
echo "2. Run 'docker-compose up' to start services"
echo "3. Access services at:"
echo "   - User Service: http://localhost:8001"
echo "   - Order Service: http://localhost:8002"
