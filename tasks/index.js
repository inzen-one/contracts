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

task("overview", "Get current total value")
	.setAction(async (_args, hre) => {
		const poolAddress = (await hre.deployments.get("InzenFunds")).address
		const pool = await hre.ethers.getContractAt('InzenFunds', poolAddress)
		console.log(`Overview:`, await pool.overview());
	})

task("deposit", "Deposit USDC to pool")
	.setAction(async (_args, hre) => {
		const poolAddress = (await hre.deployments.get("InzenFunds")).address
		const pool = await hre.ethers.getContractAt('InzenFunds', poolAddress)

		let total = 0;
		const datas = [];
		const baseToken = '0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174';
		const toTokens = [
			'0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6',
			'0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619',
			'0x2C89bbc92BD86F8075d1DEcc58C7F4E0107f286b',
			'0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270',
		];
		for (let toToken of toTokens) {
			const amount = 500000;
			total += amount;
			const url = `https://api.1inch.io/v5.0/137/swap?fromTokenAddress=${baseToken}&toTokenAddress=${toToken}&amount=${amount}&fromAddress=${poolAddress}&slippage=1&disableEstimate=true`
			const data = (await axios.get(url)).data.tx.data;
			datas.push(data);
		}
		const tx = await pool.deposit(total, datas);
		console.log(tx)
	})

task("withdraw", "Withdraw token from pool")
	.setAction(async (_args, hre) => {
		const poolAddress = (await hre.deployments.get("InzenFunds")).address
		const pool = await hre.ethers.getContractAt('InzenFunds', poolAddress)
		const tx = await pool.withdrawToken('0x0d500b1d8e8ef31e21c99d1db9a6444d3adf1270', '1152764046729820367');
		console.log(tx)
	})
