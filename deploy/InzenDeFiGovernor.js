module.exports = async function ({ getNamedAccounts, deployments }) {
  const { deploy } = deployments

  const { deployer } = await getNamedAccounts()

  const fundAddress = (await deployments.get("InzenDeFi")).address
  await deploy("InzenDeFiGovernor", {
    contract: 'InzenGovernor',
    from: deployer,
    args: [
      'InzenGovernor: DeFi',
      fundAddress,
      3600,
      20
    ],
    log: true,
  })
}

module.exports.tags = ["InzenDeFiGovernor"]
module.exports.dependencies = ["InzenDeFi"]