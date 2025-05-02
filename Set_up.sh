#!/bin/bash

# Aztec Sequencer Node Setup Script
# This script automates the setup and deployment of an Aztec sequencer node
# Based on Aztec documentation and community resources

# Exit immediately if a command exits with a non-zero status
set -e

# Color codes for pretty output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Log function
log() {
    echo -e "${BLUE}[$(date +"%T")]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Configuration Variables
NETWORK="alpha-testnet"
DATA_DIR="$HOME/aztec-node/data"
DOCKER_IMAGE="aztecprotocol/aztec:0.85.0-alpha-testnet.5"
LOG_LEVEL="info"
P2P_IP="0.0.0.0"
P2P_TCP_PORT="40400"
P2P_UDP_PORT="40400"

# Header
echo -e "${GREEN}=================================${NC}"
echo -e "${GREEN}  Aztec Sequencer Node Setup     ${NC}"
echo -e "${GREEN}=================================${NC}"
echo

# Check for configuration file
CONFIG_FILE="./aztec.conf"
if [ -f "$CONFIG_FILE" ]; then
    log "Loading configuration from $CONFIG_FILE"
    source "$CONFIG_FILE"
else
    warning "No configuration file found at $CONFIG_FILE. Using default values."
    
    # Prompt for L1 RPC URLs if not set
    if [ -z "${L1_RPC_URL}" ]; then
        read -p "Enter your Ethereum L1 RPC URL: " L1_RPC_URL
        if [ -z "$L1_RPC_URL" ]; then
            error "Ethereum L1 RPC URL is required."
        fi
    fi
    
    if [ -z "${L1_CONSENSUS_URL}" ]; then
        read -p "Enter your Ethereum L1 Consensus RPC URL: " L1_CONSENSUS_URL
        if [ -z "$L1_CONSENSUS_URL" ]; then
            error "Ethereum L1 Consensus RPC URL is required."
        fi
    fi
    
    # Prompt for validator private key if not set
    if [ -z "${VALIDATOR_PRIVATE_KEY}" ]; then
        read -sp "Enter your validator private key: " VALIDATOR_PRIVATE_KEY
        echo
        if [ -z "$VALIDATOR_PRIVATE_KEY" ]; then
            error "Validator private key is required."
        fi
    fi
fi

# Check for required tools
log "Checking for required tools..."
for cmd in docker curl; do
    if ! command -v $cmd &> /dev/null; then
        error "$cmd is required but not installed. Please install it first."
    fi
done
success "All required system tools are installed."

# Check Docker is running
if ! docker info &> /dev/null; then
    error "Docker is not running. Please start the Docker service."
fi

# Install Node.js and Yarn if not present
if ! command -v node &> /dev/null || ! command -v yarn &> /dev/null; then
    log "Installing Node.js and Yarn..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt-get update
    sudo apt-get install -y nodejs
    npm install -g yarn
    success "Node.js and Yarn installed successfully."
else
    log "Node.js and Yarn are already installed."
fi

# Install aztec-cli
log "Installing aztec-cli..."
npm install -g @aztec/cli
success "aztec-cli installed successfully."

# Create data directory
log "Creating data directory at $DATA_DIR..."
mkdir -p "$DATA_DIR"
success "Data directory created."

# Create .env file for configuration
log "Creating .env file..."
cat << EOF > .env
ETHEREUM_HOSTS=$L1_RPC_URL
L1_CONSENSUS_HOST_URLS=$L1_CONSENSUS_URL
DATA_DIRECTORY=$DATA_DIR
VALIDATOR_PRIVATE_KEY=$VALIDATOR_PRIVATE_KEY
P2P_IP=$P2P_IP
P2P_TCP_PORT=$P2P_TCP_PORT
P2P_UDP_PORT=$P2P_UDP_PORT
LOG_LEVEL=$LOG_LEVEL
EOF
success ".env file created with your configuration."

# Source the .env file
source .env

# Pull the Aztec Docker image
log "Pulling Aztec Docker image ($DOCKER_IMAGE)..."
if ! docker pull $DOCKER_IMAGE; then
    error "Failed to pull Docker image. Check your internet connection or if the image tag exists."
fi
success "Docker image pulled successfully."

# Check if a node is already running
if docker ps | grep -q "aztec-node"; then
    warning "An Aztec node is already running. Stopping it..."
    docker stop aztec-node
    docker rm aztec-node
fi

# Run the Aztec sequencer node
log "Starting Aztec sequencer node on $NETWORK..."
if command -v aztec &> /dev/null; then
    log "Using aztec-cli to start the node..."
    aztec start --network $NETWORK --archiver --node --sequencer
else
    # Fallback to direct Docker command
    log "aztec-cli not found in PATH, using direct Docker command..."
    docker run -d \
        --name aztec-node \
        --restart unless-stopped \
        --network host \
        -v "$DATA_DIR:/data" \
        -e ETHEREUM_HOSTS="$L1_RPC_URL" \
        -e L1_CONSENSUS_HOST_URLS="$L1_CONSENSUS_URL" \
        -e DATA_DIRECTORY="/data" \
        -e VALIDATOR_PRIVATE_KEY="$VALIDATOR_PRIVATE_KEY" \
        -e P2P_IP="$P2P_IP" \
        -e P2P_TCP_PORT="$P2P_TCP_PORT" \
        -e P2P_UDP_PORT="$P2P_UDP_PORT" \
        -e LOG_LEVEL="$LOG_LEVEL" \
        $DOCKER_IMAGE \
        sh -c "node --no-warnings /usr/src/yarn-project/aztec/dest/bin/index.js start --network $NETWORK --node --archiver --sequencer"
fi

# Check if the node started successfully
if docker ps | grep -q "aztec-node"; then
    success "Aztec sequencer node is running!"
    log "To view logs, run: docker logs -f aztec-node"
    log "To stop the node, run: docker stop aztec-node && docker rm aztec-node"
    log "Node data is stored in: $DATA_DIR"
else
    error "Failed to start the Aztec sequencer node. Check the logs for details."
fi

# Print node information
echo
echo -e "${GREEN}======== Aztec Sequencer Node Info ========${NC}"
echo -e "Network: ${YELLOW}$NETWORK${NC}"
echo -e "Data Directory: ${YELLOW}$DATA_DIR${NC}"
echo -e "P2P Address: ${YELLOW}$P2P_IP:$P2P_TCP_PORT${NC}"
echo -e "Log Level: ${YELLOW}$LOG_LEVEL${NC}"
echo -e "${GREEN}=========================================${NC}"

log "Setup complete! Your Aztec sequencer node is now running."
