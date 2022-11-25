module.exports = async function ({ getNamedAccounts, deployments }) {
  const { deploy } = deployments

  const { deployer } = await getNamedAccounts()

  const fundAddress = (await deployments.get("InzenWeb3")).address
  await deploy("InzenWeb3Governor", {
    contract: 'InzenGovernor',
    from: deployer,
    args: [
      'InzenGovernor: Web3',
      fundAddress,
      600,
      20
    ],
    log: true,
  })
}

module.exports.tags = ["InzenWeb3Governor"]
module.exports.dependencies = ["InzenWeb3"]