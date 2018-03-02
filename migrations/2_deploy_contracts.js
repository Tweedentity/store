var Store = artifacts.require("./Store")
var Manager = artifacts.require("./Manager")

module.exports = function(deployer) {
  deployer.deploy(Store)
  deployer.deploy(Manager)
}
