# Inzen Smart Contract

## Requirement

- Nodejs
- Yarn

## Setup

Clone the repo

```bash
$ git clone https://github.com/inzen-one/contracts
$ pushd contracts
```

Install dependencies

```bash
$ yarn
```

Compile contract

```bash
$ yarn compile
```

Deploy contract

```bash
$ yarn mainnet:deploy # for bsc mainnet or
$ yarn testnet:deploy # for bsc testnet
```

(Optional) Verify contract

- Sign up for bscscan account: https://bscscan.com/register
- Generate api token: https://bscscan.com/myapikey

```bash
$ export ETHERSCAN_API_KEY=<bscscan_api_token>
$ yarn mainnet:verify # for bsc mainnet or
$ yarn testnet:verify # for bsc testnet
```
