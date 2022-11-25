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
$ yarn mainnet:deploy
```

(Optional) Verify contract

- Sign up for polygonscan account: https://polygonscan.com/register
- Generate api token: https://polygonscan.com/myapikey

```bash
$ export ETHERSCAN_API_KEY=<polygonscan_api_token>
$ yarn mainnet:verify
```
