#!/bin/bash

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Testing Multiple RPC Endpoints ===${NC}\n"

test_endpoint() {
  local port=$1
  echo -e "${YELLOW}Testing RPC endpoint on port $port...${NC}"

  response=$(curl -s -X POST http://localhost:$port \
    -H "Content-Type: application/json" \
    -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}')

  echo "response "$response

  block_number=$(echo $response | grep -o '"result":"[^"]*"' | cut -d'"' -f4)

  if [ -n "$block_number" ]; then
    # Convert hex to decimal
    decimal=$((16#${block_number#0x}))
    echo -e "${GREEN}✓ Port $port: Block number = $decimal (hex: $block_number)${NC}\n"
    echo "$decimal"
  else
    echo -e "${RED}✗ Port $port: Failed to get block number${NC}\n"
    echo "0"
  fi
}

# Test all three endpoints
echo -e "${BLUE}Step 1: Checking block numbers on all endpoints${NC}\n"
block1=$(test_endpoint 8545)
block2=$(test_endpoint 8546)
block3=$(test_endpoint 8547)
echo "block from node 1 " : $block1
echo "block from node 2 " : $block2
echo "block from node 3 " : $block3

# Test state synchronization
echo -e "${BLUE}Step 2: Testing state synchronization${NC}\n"

echo -e "${YELLOW}Sending transaction via port 8545...${NC}"
tx_response=$(curl -s -X POST http://localhost:8545 \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc":"2.0",
    "method":"eth_sendTransaction",
    "params":[{
      "from":"0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",
      "to":"0x70997970C51812dc3A010C7d01b50e0d17dc79C8",
      "value":"0xde0b6b3a7640000"
    }],
    "id":1
  }')

tx_hash=$(echo $tx_response | grep -o '"result":"[^"]*"' | cut -d'"' -f4)

if [ -n "$tx_hash" ]; then
  echo -e "${GREEN}✓ Transaction sent: $tx_hash${NC}\n"
else
  echo -e "${RED}✗ Failed to send transaction${NC}\n"
  exit 1
fi

echo -e "${YELLOW}Waiting for block to be mined (3 seconds)...${NC}"
sleep 3

# Check transaction on all endpoints
echo -e "\n${YELLOW}Verifying transaction is visible on all endpoints...${NC}\n"

for port in 8545 8546 8547; do
  echo -e "${YELLOW}Checking port $port...${NC}"
  receipt=$(curl -s -X POST http://localhost:$port \
    -H "Content-Type: application/json" \
    -d "{
        \"jsonrpc\":\"2.0\",
        \"method\":\"eth_getTransactionReceipt\",
        \"params\":[\"$tx_hash\"],
        \"id\":1
      }")

  status=$(echo $receipt | grep -o '"status":"[^"]*"' | cut -d'"' -f4)

  if [ "$status" == "0x1" ]; then
    echo -e "${GREEN}✓ Port $port: Transaction confirmed${NC}\n"
  else
    echo -e "${RED}✗ Port $port: Transaction not found or failed${NC}\n"
    exit 1
  fi
done

echo -e "${GREEN}=== All tests passed! ===${NC}"
echo -e "${GREEN}All three RPC endpoints are sharing the same Anvil state.${NC}"
