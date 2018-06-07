var TweedentityStore = artifacts.require("./TweedentityStore")
var TweedentityManager = artifacts.require("./TweedentityManager")
var TweedentityClaimer = artifacts.require("./TweedentityClaimer")

module.exports = function(deployer) {
  // deployer.deploy(TweedentityStore)
  // deployer.deploy(TweedentityManager)
  deployer.deploy(TweedentityClaimer)
}
