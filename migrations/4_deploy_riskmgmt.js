const RiskMgmt = artifacts.require('./RiskMgmt.sol');
const RiskMgmtV1 = artifacts.require('./RiskMgmtV1.sol');

module.exports = aync (deployer, network) => {
  if (network == "development") {
    await deployer.deploy(RiskMgmt);
  }
  if (network == "kovan") {
    await deployer.deploy(RiskMgmtV1);
  }
};