var TweedentityStore = artifacts.require("./TweedentityStore")
var TweedentityManager = artifacts.require("./TweedentityManager")
var TweedentityVerifier = artifacts.require("./TweedentityVerifier")

module.exports = function(deployer) {
  deployer.deploy(TweedentityStore)
  deployer.deploy(TweedentityManager)
  deployer.deploy(TweedentityVerifier)
}
