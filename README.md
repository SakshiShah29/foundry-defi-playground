# Foundry DeFi Playground

A hands-on testing environment for exploring and interacting with major DeFi protocols using Foundry's mainnet forking capabilities.

## Overview

This repository contains practical tests and examples for understanding how core DeFi protocols work under the hood. Each test file demonstrates real interactions with production contracts on Ethereum mainnet.

## Protocols Covered

- [x] **Uniswap V2** - AMM swaps, liquidity calculations, routing
- [ ] **Uniswap V3** - Concentrated liquidity, tick math, range orders
- [ ] **Uniswap V4** - Hooks, singleton architecture
- [ ] **Curve** - Stableswap invariant, pools
- [ ] **Aave** - Lending, borrowing, flash loans
- [ ] **Compound** - Money markets, cTokens
- [ ] **Balancer** - Weighted pools, stable pools

## Setup

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- Ethereum mainnet RPC URL (Alchemy, Infura, or similar)

### Installation

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/foundry-defi-playground
cd foundry-defi-playground

# Install dependencies
forge install
```

### Configuration

Add your RPC URL to `foundry.toml`:

```toml
[rpc_endpoints]
mainnet = "https://eth-mainnet.g.alchemy.com/v2/YOUR_API_KEY"
```

Alternatively, use environment variables:

```bash
export ETH_RPC_URL="your_rpc_url"
forge test --fork-url $ETH_RPC_URL
```

## Usage

### Run All Tests

```bash
forge test -vv
```

### Run Specific Protocol Tests

```bash
forge test --match-path test/uniswapv2.t.sol -vv
```

### Run Specific Test Function

```bash
forge test --match-test test_getAmountsOut -vvv
```

### Gas Reporting

```bash
forge test --gas-report
```

## Project Structure

```
src/          # Protocol interaction contracts
test/         # Test files for each protocol
lib/          # Foundry dependencies
```

## Resources

- [Foundry Book](https://book.getfoundry.sh/)
- [Uniswap V2 Documentation](https://docs.uniswap.org/contracts/v2/overview)
- [DeFi Developer Roadmap](https://github.com/OffcierCia/DeFi-Developer-Road-Map)

## License

MIT
