module.exports = async function ({ getNamedAccounts, deployments }) {
  const { deploy } = deployments

  const { deployer } = await getNamedAccounts()

  const portfolio = [
    ['0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6', '0xc907E116054Ad103354f2D350FD2514433D57F6f', 0, 25], // BTC
    ['0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619', '0xF9680D99D6C9589e2a93a78A04A279e509205945', 0, 25], // ETH
    ['0x2C89bbc92BD86F8075d1DEcc58C7F4E0107f286b', '0xe01eA2fbd8D76ee323FbEd03eB9a8625EC981A10', 0, 25], // AVAX
    ['0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270', '0xAB594600376Ec9fD91F8e885dADF0CE036862dE0', 0, 25], // MATIC
  ];
  await deploy("InzenPolygon4", {
    contract: 'InzenFunds',
    from: deployer,
    args: [
      'Inzen: Polygon4',
      '0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174',
      '0x1111111254EEB25477B68fb85Ed929f73A960582',
      portfolio
    ],
    log: true,
  })
}

module.exports.tags = ["InzenPolygon4"]
