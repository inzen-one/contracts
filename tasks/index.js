const axios = require('axios');
const { task } = require("hardhat/config")
const { BigNumber } = require('ethers')

function expandTo18Decimals(n) {
	return BigNumber.from(n).mul(BigNumber.from(10).pow(18))
}

const checkValidPool = (name) => {
	if (!['DeFi', 'Polygon4', 'Web3'].includes(name)) throw 'Invalid pool name'
}

task('accounts', 'Prints the list of accounts', async (_args, hre) => {
	const accounts = await hre.ethers.getSigners();
	for (const account of accounts) {
		console.log(account.address);
	}
});

task("overview", "Get pool overview")
	.addParam("name", "Pool name (DeFi, Polygon4, Web3)")
	.setAction(async ({ name }, hre) => {
		checkValidPool(name);
		const poolAddress = (await hre.deployments.get(`Inzen${name}`)).address
		const pool = await hre.ethers.getContractAt('InzenFunds', poolAddress)

		console.log(`*** Pool Info ***`);
		const overview = await pool.overview();
		console.log(`Name:`, overview.fundName);
		console.log(`Address:`, poolAddress);
		console.log(`Total USD:`, overview.usdValue.toString())
		console.log(`Token Supply:`, overview.tokenSupply.toString())
		for (let asset of overview.assets) {
			console.log(`-`, asset.token, asset.weight.toString(), asset.amount.toString());
		}

		console.log(`*** User Info ***`);
		const userinfo = await pool.userInfo('0xe2027d0569ca3CFc65a3d001D38e2e36104d7308');
		console.log(`Total USD:`, userinfo.usdValue.toString())
		console.log(`Token Balance:`, userinfo.tokenBalance.toString())

	})

task("deposit", "Deposit USDC to pool")
	.setAction(async (_args, hre) => {
		const poolAddress = (await hre.deployments.get("InzenFunds")).address
		const pool = await hre.ethers.getContractAt('InzenFunds', poolAddress)
		const baseToken = '0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174';
		const usdc = await hre.ethers.getContractAt('ERC20', baseToken);

		const toTokens = [
			'0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6',
			'0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619',
			'0x2C89bbc92BD86F8075d1DEcc58C7F4E0107f286b',
			'0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270',
		];

		let total = 0;
		const datas = [];
		for (let toToken of toTokens) {
			const amount = 500000;
			total += amount;
			const url = `https://api.1inch.io/v5.0/137/swap?fromTokenAddress=${baseToken}&toTokenAddress=${toToken}&amount=${amount}&fromAddress=${poolAddress}&slippage=1&disableEstimate=true`
			const data = (await axios.get(url)).data.tx.data;
			datas.push(data);
		}

		const approveTx = await usdc.approve(poolAddress, total);
		console.log(`ApproveTx: ${JSON.stringify(approveTx)}`)
		const depositTx = await pool.deposit(total, datas);
		console.log(`DepositTx: ${JSON.stringify(depositTx)}`)
	})

task("withdraw", "Withdraw token from pool")
	.setAction(async (_args, hre) => {
		const poolAddress = (await hre.deployments.get("InzenFunds")).address
		const pool = await hre.ethers.getContractAt('InzenFunds', poolAddress)
		const withdrawTx = await pool.withdraw('1504023');
		console.log(`WithdrawTx: ${JSON.stringify(withdrawTx)}`)
	})

task("recover", "Recover token from pool")
	.setAction(async (_args, hre) => {
		const poolAddress = (await hre.deployments.get("InzenFunds")).address
		const pool = await hre.ethers.getContractAt('InzenFunds', poolAddress)

		const toTokens = [
			'0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6',
			'0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619',
			'0x2C89bbc92BD86F8075d1DEcc58C7F4E0107f286b',
			'0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270',
		];
		for (let tokenAddress of toTokens) {
			const token = await hre.ethers.getContractAt('ERC20', tokenAddress);
			const balance = await token.balanceOf(poolAddress);
			const tx = await pool.withdrawToken(token, balance);
			console.log(token, balance, tx.hash)
		}
	})

task("setgovernor", "Set pool governor")
	.addParam("name", "Pool name (DeFi, Polygon4, Web3)")
	.setAction(async ({ name }, hre) => {
		checkValidPool(name);
		const poolAddress = (await hre.deployments.get(`Inzen${name}`)).address
		const pool = await hre.ethers.getContractAt('InzenFunds', poolAddress)
		const governorAddress = (await hre.deployments.get(`Inzen${name}Governor`)).address
		const role = await pool.DEFAULT_ADMIN_ROLE()
		const grantTx = await pool.grantRole(role, governorAddress);
		console.log(`GrantTx: ${JSON.stringify(grantTx)}`)
	})
