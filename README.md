## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

- **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
- **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
- **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
- **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```

## NFTMarket Project (Task #1)

This project implements a simple NFT Market where:
- Users can list NFTs with any ERC20 token as the price.
- Users can buy NFTs using the specified ERC20 token.

### Testing
Comprehensive tests have been implemented in `test/NFTMarket.t.sol`, including:
- **Unit Tests**: Coverage for listing and buying (success and failure cases).
- **Fuzz Testing**: Random price and buyer address testing.
- **Invariant Testing**: Ensuring the market contract never holds ERC20 tokens.

To run the tests and generate the report:
```shell
forge test -vvv --match-path test/NFTMarket.t.sol > test-report.txt
```
