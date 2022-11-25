module.exports = async function ({ getNamedAccounts, deployments }) {
  const { deploy } = deployments

  const { deployer } = await getNamedAccounts()

  const portfolio = [
    ['0x53E0bca35eC356BD5ddDFebbD1Fc0fD03FaBad39', '0xd9FFdb71EbE7496cC440152d43986Aae0AB76665', 0, 50], // LINK
    ['0x5fe2B58c013d7601147DcdD68C143A77499f5531', '0x3FabBfb300B1e2D7c9B84512fe9D30aeDF24C410', 0, 25], // GRT
    ['0x282d8efCe846A88B159800bd4130ad77443Fa1A1', '0xdcda79097C44353Dee65684328793695bd34A629', 0, 25], // OCEAN
  ];
  await deploy("InzenWeb3", {
    contract: 'InzenFunds',
    from: deployer,
    args: [
      'Inzen: Web3',
      '0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174',
      '0x1111111254EEB25477B68fb85Ed929f73A960582',
      portfolio
    ],
    log: true,
  })
}

module.exports.tags = ["InzenWeb3"]
