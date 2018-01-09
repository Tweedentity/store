// var Authorizable = artifacts.require("./Authorizable")
// var TweedentityStore = artifacts.require("./TweedentityStore")
// var ECTools = artifacts.require("./ECTools")
// var ECRecovery = artifacts.require("zeppelin/ECRecovery")
// var Authorizable = artifacts.require("./Authorizable")
// var TweedentityStore = artifacts.require("./TweedentityStore")
var TweedentityManager = artifacts.require("./TweedentityManager")

module.exports = function(deployer) {
  // deployer.deploy(ECRecovery)
  // deployer.link(ECRecovery, ECTools)
  // deployer.deploy(ECTools)
  // deployer.link(ECTools, TweedentityManager)
  deployer.deploy(TweedentityManager)
}
