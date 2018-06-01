pragma solidity ^0.4.18;


import '../TweedentityManager.sol';


// This contract is for testing the TweedentityManager's methods
// which are callable from other contracts

contract TweedentityManagerCaller {

  TweedentityManager public manager;

  function setManager(address _managerAddress) public {
    manager = TweedentityManager(_managerAddress);
  }

  // callable methods
  // Theoretically, there is no need to test them because the
  // compiler with produce an error when calling any getter that
  // is return not-allowed dynamic data

  function isUidUpgradable(string _uid) public constant returns (bool) {
    return manager.isUidUpgradable(_uid);
  }

  function isAddressUpgradable(address _address) public constant returns (bool) {
    return manager.isAddressUpgradable(_address);
  }

  function isUpgradable(address _address, string _uid) public constant returns (bool) {
    return manager.isUpgradable(_address, _uid);
  }


}