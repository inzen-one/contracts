module.exports = async function ({ getNamedAccounts, deployments }) {
  const { deploy } = deployments

  const { deployer } = await getNamedAccounts()

  const portfolio = [
    ['0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6', '0xc907E116054Ad103354f2D350FD2514433D57F6f', 0, 20], // BTC
    ['0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619', '0xF9680D99D6C9589e2a93a78A04A279e509205945', 0, 20], // ETH
    ['0x2C89bbc92BD86F8075d1DEcc58C7F4E0107f286b', '0xe01eA2fbd8D76ee323FbEd03eB9a8625EC981A10', 0, 20], // AVAX
    ['0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270', '0x327e23A4855b6F663a28c5161541d69Af8973302', 0, 20], // MATIC
    ['0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174', '0xfE4A8cc5b5B2366C1B58Bea3858e81843581b2F7', 0, 20], // USDC
  ];
  await deploy("InzenFunds", {
    from: deployer,
    args: [
      'Inzen: Polygon5',
      '0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174',
      '0x1111111254EEB25477B68fb85Ed929f73A960582',
      portfolio
    ],
    log: true,
  })
}

module.exports.tags = ["InzenFunds"]
