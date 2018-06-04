pragma solidity ^0.4.18;

import 'authorizable/contracts/AuthorizableLite.sol';

import './TweedentityStore.sol';

contract TweedentityManager is AuthorizableLite {

  struct Store {
    TweedentityStore store;
    address addr;
  }

  mapping(bytes32 => Store) private __store;
  string[] public identifiers;
  mapping(string => bool) private __storeSet;

  function setAStore(string _identifier, address _address)
  external
  onlyOwner
  {
    require(bytes(_identifier).length > 0);
    bytes32 identifier = keccak256(_identifier);
    require(!__storeSet[_identifier]);
    require(_address != 0x0);
    __store[identifier] = Store(
      TweedentityStore(_address),
      _address
    );
    // we want to be sure that we set the right store
    require(__store[identifier].store.getAppIdentifier() == identifier);
    identifiers.push(_identifier);
    __storeSet[_identifier] = true;
  }

  modifier isStoreSet(string _identifier) {
    require(__storeSet[_identifier]);
    _;
  }

  function __getStore(string _identifier)
  internal
  constant returns (TweedentityStore)
  {
    bytes32 identifier = keccak256(_identifier);
    return __store[identifier].store;
  }

  function getStoreSet(string _identifier)
  external
  constant returns (bool){
    return __storeSet[_identifier];
  }

  uint public verifierLevel = 40;
  uint public customerServiceLevel = 30;
  uint public devLevel = 20;

  uint public minimumTimeBeforeUpdate = 1 days;

  // events

  event MinimumTimeBeforeUpdateChanged(uint time);

  event IdentityNotUpgradable(string identifier, address addr, string uid);

  // helpers

  function isUidUpgradable(TweedentityStore _store, string _uid)
  internal
  constant returns (bool)
  {
    uint lastUpdate = _store.getUidLastUpdate(_uid);
    return lastUpdate == 0 || now >= lastUpdate + minimumTimeBeforeUpdate;
  }

  function isAddressUpgradable(TweedentityStore _store, address _address)
  internal
  constant returns (bool)
  {
    uint lastUpdate = _store.getAddressLastUpdate(_address);
    return lastUpdate == 0 || now >= lastUpdate + minimumTimeBeforeUpdate;
  }

  function isUpgradable(TweedentityStore _store, address _address, string _uid)
  internal
  constant returns (bool)
  {
    if (!_store.isUpgradable(_address, _uid) || !isAddressUpgradable(_store, _address) || !isUidUpgradable(_store, _uid)) {
      return false;
    }
    return true;
  }

  // error codes
  uint public upgradable = 0;
  uint public notUpgradableInStore = 1;
  uint public uidNotUpgradable = 2;
  uint public addressNotUpgradable = 3;
  uint public uidAndAddressNotUpgradable = 4;

  function getUpgradability(string _identifier, address _address, string _uid)
  external
  constant returns (uint)
  {
    TweedentityStore _store = __getStore(_identifier);
    if (!_store.isUpgradable(_address, _uid)) {
      return notUpgradableInStore;
    }
    if (!isAddressUpgradable(_store, _address) && !isUidUpgradable(_store, _uid)) {
      return uidAndAddressNotUpgradable;
    } else if (!isAddressUpgradable(_store, _address)) {
      return addressNotUpgradable;
    } else if (!isUidUpgradable(_store, _uid)) {
      return uidNotUpgradable;
    }
    return upgradable;
  }

  // primary methods

  function setIdentity(string _identifier, address _address, string _uid)
  external
  onlyAuthorizedAtLevel(verifierLevel)
  isStoreSet(_identifier)
  {
    require(_address != address(0));
    require(__isUid(_uid));

    TweedentityStore _store = __getStore(_identifier);
    if (isUpgradable(_store, _address, _uid)) {
      _store.setIdentity(_address, _uid);
    } else {
      IdentityNotUpgradable(_identifier, _address, _uid);
    }
  }

  function removeIdentity(string _identifier, address _address)
  external
  onlyAuthorizedAtLevel(customerServiceLevel)
  isStoreSet(_identifier)
  {
    TweedentityStore _store = __getStore(_identifier);
    _store.removeIdentity(_address);
  }

  function removeMyIdentity(string _identifier)
  external
  isStoreSet(_identifier)
  {
    TweedentityStore _store = __getStore(_identifier);
    _store.removeIdentity(msg.sender);
  }

  // Changes the minimum time required before being allowed to update
  // a tweedentity associating a new address to a uid
  function changeMinimumTimeBeforeUpdate(uint _newMinimumTime)
  external
  onlyAuthorizedAtLevel(devLevel)
  {
    minimumTimeBeforeUpdate = _newMinimumTime;
    MinimumTimeBeforeUpdateChanged(_newMinimumTime);
  }

  // string methods

  function __isUid(string _uid)
  internal
  pure
  returns (bool)
  {
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

  function __stringToUint(string s)
  internal
  pure
  returns (uint result)
  {
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

  function __uintToBytes(uint x)
  internal
  pure
  returns (bytes b)
  {
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
