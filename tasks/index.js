const axios = require('axios');
const { task } = require("hardhat/config")
const { BigNumber } = require('ethers')

function expandTo18Decimals(n) {
	return BigNumber.from(n).mul(BigNumber.from(10).pow(18))
}

task('accounts', 'Prints the list of accounts', async (_args, hre) => {
	const accounts = await hre.ethers.getSigners();
	for (const account of accounts) {
		console.log(account.address);
	}
});

task("getvalue", "Get current total value")
	.setAction(async (_args, hre) => {
		const poolAddress = (await hre.deployments.get("InzenFunds")).address
		const pool = await hre.ethers.getContractAt('InzenFunds', poolAddress)
		console.log(`Total Value:`, (await pool.totalValue()).toString());
	})

task("deposit", "Deposit USDC to pool")
	.setAction(async (_args, hre) => {
		const poolAddress = (await hre.deployments.get("InzenFunds")).address
		const pool = await hre.ethers.getContractAt('InzenFunds', poolAddress)

		let total = 0;
		const datas = [];
		const toTokens = [
			'0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6',
			// '0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619',
			// '0x3BA4c387f786bFEE076A58914F5Bd38d668B42c3',
			// '0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270',
		];
		for (let toToken of toTokens) {
			const amount = 1000000;
			total += amount;
			const url = `https://api.1inch.io/v5.0/137/swap?fromTokenAddress=0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174&toTokenAddress=${toToken}&amount=${amount}&fromAddress=${poolAddress}&slippage=1&disableEstimate=true`
			const data = (await axios.get(url)).data.tx.data;
			datas.push(data);
		}
		console.log(total, datas);

		// const tx = await pool.deposit(total, datas);
		// console.log(tx)
	})

task("withdraw", "Withdraw token from pool")
	.setAction(async (_args, hre) => {
		const poolAddress = (await hre.deployments.get("InzenFunds")).address
		const pool = await hre.ethers.getContractAt('InzenFunds', poolAddress)
		const tx = await pool.withdrawToken('0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619', '767769243808401');
		console.log(tx)
	})
