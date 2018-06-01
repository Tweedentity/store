pragma solidity ^0.4.18;

import 'authorizable/contracts/AuthorizableLite.sol';

import './TweedentityStore.sol';

contract TweedentityManager is AuthorizableLite {

  bytes32 public contractName = keccak256("TweedentityManager");

  TweedentityStore public store;
  address public storeAddress;

  modifier isStoreSet() {
    require(store.manager() == address(this));
    _;
  }

  function setStore(address _address) onlyOwner public {
    require(storeAddress == address(0));
    require(_address != 0x0);
    storeAddress = _address;
    store = TweedentityStore(_address);
    require(store.contractName() == keccak256("TweedentityStore"));
  }

  uint public identities;

  uint public verifierLevel = 40;
  uint public customerServiceLevel = 30;
  uint public devLevel = 20;

  bool public isDatabase = true;

  uint public minimumTimeBeforeUpdate = 1 days;

  // events

  event MinimumTimeBeforeUpdateChanged(uint _time);

  // helpers

  function isAddressSet(address _address) public constant returns (bool){
    return store.isAddressSet(_address);
  }

  function isUidUpgradable(string _uid) public constant returns (bool) {
    uint lastUpdate = store.getUidLastUpdate(_uid);
    return lastUpdate == 0 || now >= lastUpdate + minimumTimeBeforeUpdate;
  }

  function isAddressUpgradable(address _address) public constant returns (bool) {
    uint lastUpdate = store.getAddressLastUpdate(_address);
    return lastUpdate == 0 || now >= lastUpdate + minimumTimeBeforeUpdate;
  }

  function isUpgradable(address _address, string _uid) public constant returns (bool) {
    if (!store.isUpgradable(_address, _uid)) {
      return false;
    }
    if (store.isAddressSet(_address) && (
    !isAddressUpgradable(_address) || !isUidUpgradable(_uid)
    )) {
      return false;
    }
    return true;
  }

  // primary methods

  function setIdentity(address _address, string _uid) external onlyAuthorizedAtLevel(verifierLevel) {
    require(_address != address(0));
    require(__isUid(_uid));
    require(isUpgradable(_address, _uid));

    store.setIdentity(_address, _uid);
  }

  function removeIdentity(address _address) external onlyAuthorizedAtLevel(customerServiceLevel) {
    store.removeIdentity(_address);
  }

  function removeMyIdentity() external {
    store.removeIdentity(msg.sender);
  }

  // Changes the minimum time required before being allowed to update
  // a tweedentity associating a new address to a screenName
  function changeMinimumTimeBeforeUpdate(uint _newMinimumTime) onlyAuthorizedAtLevel(devLevel) external {
    minimumTimeBeforeUpdate = _newMinimumTime;
    MinimumTimeBeforeUpdateChanged(_newMinimumTime);
  }

  // string methods

  function __isUid(string _uid) internal pure returns (bool) {
    bytes memory uid = bytes(_uid);
    if (uid.length == 0) {
      return false;
    } else {
      for (uint i = 0; i < uid.length; i++) {
        if (uid[i] < 48 || uid[i] > 57) {
          return false;
        }
      }
    }
    return true;
  }

  function __stringToUint(string s) internal pure returns (uint result) {
    bytes memory b = bytes(s);
    uint i;
    result = 0;
    for (i = 0; i < b.length; i++) {
      uint c = uint(b[i]);
      if (c >= 48 && c <= 57) {
        result = result * 10 + (c - 48);
      }
    }
  }

  function __uintToBytes(uint x) internal pure returns (bytes b) {
    b = new bytes(32);
    for (uint i = 0; i < 32; i++) {
      b[i] = byte(uint8(x / (2 ** (8 * (31 - i)))));
    }
  }

  //  function __uintToString(uint _uint) internal pure returns (string) {
  //    bytes32 data = bytes32(_uint);
  //    bytes memory bytesString = new bytes(32);
  //    for (uint j = 0; j < 32; j++) {
  //      byte char = byte(bytes32(uint(data) * 2 ** (8 * j)));
  //      if (char != 0) {
  //        bytesString[j] = char;
  //      }
  //    }
  //    return string(bytesString);
  //  }

}