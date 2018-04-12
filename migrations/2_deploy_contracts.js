var TweedentityStore = artifacts.require("./TweedentityStore")
var TweedentityManager = artifacts.require("./TweedentityManager")

module.exports = function(deployer) {
  deployer.deploy(TweedentityStore)
  deployer.deploy(TweedentityManager)
}
