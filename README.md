# Local Eth node

Below setup provides **3 RPC endpoints** running at (ports 8545, 8546, 8547) all sharing  **same Anvil ETH state**.

## Architecture

```
┌───────────────────────────┐
RPC #1 (8545)  ─────────►   │
RPC #2 (8546)  ─────────►   │  ONE ANVIL
RPC #3 (8547)  ─────────►   │  (the blockchain)
                            │
└───────────────────────────┘
```

## Quick Start

### Start the Environment

```bash
docker-compose up -d
```

### Verify All Endpoints

Check that all three endpoints return the same block number:

```bash

# Node #1
curl -X POST http://localhost:8545 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'

# Node #2
curl -X POST http://localhost:8546 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'

# Node #3
curl -X POST http://localhost:8547 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'
```

### Test Fetch State by firing dummy transactions via test-endpoints.sh


```bash
bash test_endpoints.sh
```

```bash
sudo docker-compose down
```

