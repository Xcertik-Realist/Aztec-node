# Aztec Sequencer Node

This repository provides tools to set up and run an Aztec sequencer node on the Aztec Network alpha-testnet. Sequencer nodes are critical components of the Aztec Network's ZK-rollup infrastructure, responsible for processing transactions and maintaining the state of the rollup.

## Overview

The Aztec Network is a privacy-focused Layer 2 solution built on Ethereum, using zero-knowledge proofs to enable private transactions and smart contracts. Running a sequencer node contributes to the network's decentralization and allows you to participate in the consensus process.

This repository includes:
- A bash script for automated setup and deployment
- Documentation on configuration options
- Troubleshooting guidance
- Monitoring recommendations

## Prerequisites

Before running an Aztec sequencer node, ensure you have:

### Hardware Requirements
- **Minimum**: 4 CPU cores, 8GB RAM, 100GB SSD
- **Recommended**: 8+ CPU cores, 16GB+ RAM, 500GB+ SSD
- **Network**: Stable internet connection with at least 10 Mbps up/down

### Software Requirements
- **Operating System**: Ubuntu 20.04 LTS or later (recommended)
- **Docker**: Latest stable version
- **Node.js**: v18 or later
- **Yarn**: Latest version

### External Services
- Ethereum L1 execution client RPC access (e.g., Alchemy, Infura, or your own node)
- Ethereum L1 consensus client RPC access (e.g., Quicknode, dRPC, or your own node)
- Validator private key (for sequencer operations)

### Network Configuration
- Open ports `40400-40408` (TCP/UDP) for P2P communication

## Quick Start

1. Clone this repository:
   ```
   git clone https://github.com/yourusername/aztec-sequencer-node.git
   cd aztec-sequencer-node
   ```

2. Make the script executable:
   ```
   chmod +x run_aztec_sequencer.sh
   ```

3. Create a configuration file (optional):
   ```
   cat > aztec.conf << EOF
   L1_RPC_URL="https://your-ethereum-rpc-url"
   L1_CONSENSUS_URL="https://your-consensus-rpc-url"
   VALIDATOR_PRIVATE_KEY="your-validator-private-key"
   # Optional configurations
   DATA_DIR="$HOME/aztec-node/data"
   LOG_LEVEL="info"
   P2P_IP="0.0.0.0"
   P2P_TCP_PORT="40400"
   P2P_UDP_PORT="40400"
   EOF
   ```

4. Run the script:
   ```
   ./run_aztec_sequencer.sh
   ```

## Configuration Options

The script supports the following configuration options:

| Parameter | Description | Default |
|-----------|-------------|---------|
| `NETWORK` | Aztec network to connect to | `alpha-testnet` |
| `DATA_DIR` | Directory to store node data | `$HOME/aztec-node/data` |
| `DOCKER_IMAGE` | Docker image for the Aztec node | `aztecprotocol/aztec:0.85.0-alpha-testnet.5` |
| `LOG_LEVEL` | Logging verbosity (debug, info, warn, error) | `info` |
| `P2P_IP` | IP address to bind P2P services | `0.0.0.0` |
| `P2P_TCP_PORT` | Port for P2P TCP communication | `40400` |
| `P2P_UDP_PORT` | Port for P2P UDP communication | `40400` |
| `L1_RPC_URL` | Ethereum execution client RPC URL | *Required* |
| `L1_CONSENSUS_URL` | Ethereum consensus client RPC URL | *Required* |
| `VALIDATOR_PRIVATE_KEY` | Private key for validating transactions | *Required* |

## Security Recommendations

- **Never** store your validator private key in plain text files that are committed to version control
- Use environment variables or a secrets manager for sensitive information
- Run the node behind a firewall, only exposing necessary ports
- Regularly update the Docker image to get the latest security patches
- Consider using a dedicated machine for running the sequencer node

## Monitoring & Maintenance

### View Node Logs
```
docker logs -f aztec-node
```

### Check Node Status
```
docker ps -a | grep aztec-node
```

### Update Node Software
```
docker pull aztecprotocol/aztec:latest
docker stop aztec-node
docker rm aztec-node
./run_aztec_sequencer.sh
```

### Backup Node Data
```
tar -czvf aztec-node-backup.tar.gz $HOME/aztec-node/data
```

## Troubleshooting

### Common Issues

1. **Node fails to start**
   - Check if Docker is running: `systemctl status docker`
   - Verify L1 RPC URLs are accessible
   - Ensure ports are not already in use: `netstat -tulpn | grep 40400`

2. **Node starts but doesn't sync**
   - Check logs for errors: `docker logs aztec-node`
   - Verify your validator key is correctly formatted
   - Ensure your L1 clients are fully synced

3. **Out of disk space**
   - Clear Docker cache: `docker system prune -a`
   - Move data directory to a larger disk

## Additional Resources

- [Aztec Network Documentation](https://docs.aztec.network/)
- [Aztec Discord Community](https://discord.gg/aztec)
- [Aztec GitHub Repository](https://github.com/AztecProtocol/aztec-packages)

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Disclaimer

This software is provided as-is without any guarantees or warranties. Running a sequencer node involves handling cryptocurrency and may expose you to financial risks. Always secure your private keys and follow best practices for server security.
