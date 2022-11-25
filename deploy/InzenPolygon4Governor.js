module.exports = async function ({ getNamedAccounts, deployments }) {
  const { deploy } = deployments

  const { deployer } = await getNamedAccounts()

  const fundAddress = (await deployments.get("InzenPolygon4")).address
  await deploy("InzenPolygon4Governor", {
    contract: 'InzenGovernor',
    from: deployer,
    args: [
      'InzenGovernor: Polygon4',
      fundAddress,
      3600 * 24,
      20
    ],
    log: true,
  })
}

module.exports.tags = ["InzenPolygon4Governor"]
module.exports.dependencies = ["InzenPolygon4"]