pragma solidity ^0.4.18;


import '../TweedentityStore.sol';


// This contract is for testing the TweedentityStore's methods
// which are callable from other contracts

contract TweedentityStoreCaller {

  TweedentityStore public store;

  function setStore(address _storeAddress) public {
    store = TweedentityStore(_storeAddress);
  }

  // callable methods
  // Theoretically, there is no need to test them because the
  // compiler with produce an error when calling any getter that
  // is return not-allowed dynamic data

  function isUidSet(string _uid) public constant returns (bool){
    return store.isUidSet(_uid);
  }

  function isAddressSet(address _address) public constant returns (bool){
    return store.isAddressSet(_address);
  }

  function isUidUpgradable(string _uid) public constant returns (bool) {
    return store.isUidUpgradable(_uid);
  }

  function isAddressUpgradable(address _address) public constant returns (bool) {
    return store.isAddressUpgradable(_address);
  }

  function isUpgradable(address _address, string _uid) public constant returns (bool) {
    return store.isUpgradable(_address, _uid);
  }

  function getUidAsInteger(address _address) public constant returns (uint){
    return store.getUidAsInteger(_address);
  }

  function getAddress(string _uid) public constant returns (address){
    return store.getAddress(_uid);
  }

  function getAddressLastUpdate(address _address) public constant returns (uint) {
    return store.getAddressLastUpdate(_address);
  }

  function getUidLastUpdate(string _uid) public constant returns (uint) {
    return store.getUidLastUpdate(_uid);
  }

}