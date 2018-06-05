pragma solidity ^0.4.18;

import 'authorizable/contracts/AuthorizableLite.sol';

import './TweedentityStore.sol';
import './TweedentityManagerInterfaceCompact.sol';

contract TweedentityManager is AuthorizableLite, TweedentityManagerInterfaceCompact {

  uint public version = 1;

  struct Store {
    TweedentityStore store;
    address addr;
  }

  mapping(uint => bytes32) public appNicknames32;
  mapping(uint => string) public appNicknames;
  mapping(string => uint) private __appIds;

  function getAppId(
    string _nickname
  )
  external
  constant
  returns (uint) {
    return __appIds[_nickname];
  }

  mapping(uint => Store) private __stores;

  function setAStore(
    string _appNickname,
    address _address
  )
  external
  onlyOwner
  {
    require(bytes(_appNickname).length > 0);
    bytes32 _appNickname32 = keccak256(_appNickname);
    require(_address != address(0));
    TweedentityStore _store = TweedentityStore(_address);
    require(_store.getAppNickname() == _appNickname32);
    uint _appId = _store.getAppId();
    require(appNicknames32[_appId] == 0x0);
    appNicknames32[_appId] = _appNickname32;
    appNicknames[_appId] = _appNickname;
    __appIds[_appNickname] = _appId;

    __stores[_appId] = Store(
      TweedentityStore(_address),
      _address
    );
  }

  function isSettable(
    uint _id,
    string _nickname
  )
  external
  constant
  returns (bool)
  {
    return __appIds[_nickname] == 0 && appNicknames32[_id] == 0x0;
  }

  modifier isStoreSet(
    uint _appId
  ) {
    require(appNicknames32[_appId] != 0x0);
    _;
  }

  function __getStore(
    uint _id
  )
  internal
  constant returns (TweedentityStore)
  {
    return __stores[_id].store;
  }

  function getIsStoreSet(
    string _nickname
  )
  external
  constant returns (bool){
    return __appIds[_nickname] != 0;
  }

  uint public verifierLevel = 40;
  uint public customerServiceLevel = 30;
  uint public devLevel = 20;

  uint public minimumTimeBeforeUpdate = 1 days;

  // events

  event MinimumTimeBeforeUpdateChanged(
    uint time
  );

  event IdentityNotUpgradable(
    string nickname,
    address addr,
    string uid
  );

  // helpers

  function isUidUpgradable(
    TweedentityStore _store,
    string _uid
  )
  internal
  constant returns (bool)
  {
    uint lastUpdate = _store.getUidLastUpdate(_uid);
    return lastUpdate == 0 || now >= lastUpdate + minimumTimeBeforeUpdate;
  }

  function isAddressUpgradable(
    TweedentityStore _store,
    address _address
  )
  internal
  constant returns (bool)
  {
    uint lastUpdate = _store.getAddressLastUpdate(_address);
    return lastUpdate == 0 || now >= lastUpdate + minimumTimeBeforeUpdate;
  }

  function isUpgradable(
    TweedentityStore _store,
    address _address,
    string _uid
  )
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

  function getUpgradability(
    uint _id,
    address _address,
    string _uid
  )
  external
  constant returns (uint)
  {
    TweedentityStore _store = __getStore(_id);
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

  function setIdentity(
    uint _appId,
    address _address,
    string _uid
  )
  external
  onlyAuthorizedAtLevel(verifierLevel)
  isStoreSet(_appId)
  {
    require(_address != address(0));

    TweedentityStore _store = __getStore(_appId);
    require(_store.isUid(_uid));
    if (isUpgradable(_store, _address, _uid)) {
      _store.setIdentity(_address, _uid);
    } else {
      IdentityNotUpgradable(appNicknames[_appId], _address, _uid);
    }
  }

  function removeIdentity(
    uint _appId,
    address _address
  )
  external
  onlyAuthorizedAtLevel(customerServiceLevel)
  isStoreSet(_appId)
  {
    TweedentityStore _store = __getStore(_appId);
    _store.removeIdentity(_address);
  }

  function removeMyIdentity(
    uint _appId
  )
  external
  isStoreSet(_appId)
  {
    TweedentityStore _store = __getStore(_appId);
    _store.removeIdentity(msg.sender);
  }


  // Changes the minimum time required before being allowed to update
  // a tweedentity associating a new address to a uid
  function changeMinimumTimeBeforeUpdate(
    uint _newMinimumTime
  )
  external
  onlyAuthorizedAtLevel(devLevel)
  {
    minimumTimeBeforeUpdate = _newMinimumTime;
    MinimumTimeBeforeUpdateChanged(_newMinimumTime);
  }

  // string methods

  function __stringToUint(
    string s
  )
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

}
