pragma solidity ^0.4.18;

import 'openzeppelin-solidity/contracts/ownership/Ownable.sol';

import './TweedentityStore.sol';
import './TweedentityManagerInterfaceCompact.sol';



/** Tweedentity 0.0.0 */

/**
 * @title TweedentityManager
 * @author Francesco Sullo <francesco@sullo.co>
 * @dev Sets and removes tweedentities in the store,
 * adding more logic to the simple logic of the store
 */

contract TweedentityManager
is TweedentityManagerInterfaceCompact, Ownable
{

  string public versionDate = "2018-06-06";

  struct Store {
    TweedentityStore store;
    address addr;
  }

  mapping(uint => Store) private __stores;

  mapping(uint => bytes32) public appNicknames32;
  mapping(uint => string) public appNicknames;
  mapping(string => uint) private __appIds;

  address public claimer;
  mapping(address => bool) public customerService;
  address[] public customerServiceAddress;

  uint public upgradable = 0;
  uint public notUpgradableInStore = 1;
  uint public uidNotUpgradable = 2;
  uint public addressNotUpgradable = 3;
  uint public uidAndAddressNotUpgradable = 4;

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



  // config


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


  function setClaimer(
    address _address
  )
  public
  onlyOwner
  {
    require(_address != 0x0);
    claimer = _address;
  }


  function setCustomerService(
    address _address,
    bool status
  )
  public
  onlyOwner
  {
    require(_address != 0x0);
    customerService[_address] = status;
    bool found;
    for (uint i = 0; i < customerServiceAddress.length; i++) {
      if (customerServiceAddress[i] == _address) {
        found = true;
        break;
      }
    }
    if (!found) {
      customerServiceAddress.push(_address);
    }
  }



  //modifiers


  modifier isStoreSet(
    uint _appId
  ) {
    require(appNicknames32[_appId] != 0x0);
    _;
  }


  modifier onlyClaimer() {
    require(msg.sender == claimer);
    _;
  }


  modifier onlyCustomerService() {
    bool ok = msg.sender == owner ? true : false;
    if (!ok) {
      for (uint i = 0; i < customerServiceAddress.length; i++) {
        if (customerServiceAddress[i] == msg.sender) {
          ok = true;
          break;
        }
      }
    }
    require(ok);
    _;
  }



  // internal getters


  function __getStore(
    uint _id
  )
  internal
  constant returns (TweedentityStore)
  {
    return __stores[_id].store;
  }



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



  // getters


  function getAppId(
    string _nickname
  )
  external
  constant
  returns (uint) {
    return __appIds[_nickname];
  }


  function getIsStoreSet(
    string _nickname
  )
  external
  constant returns (bool){
    return __appIds[_nickname] != 0;
  }


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
  onlyClaimer
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
  onlyCustomerService
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


  function changeMinimumTimeBeforeUpdate(
    uint _newMinimumTime
  )
  external
  onlyOwner
  {
    minimumTimeBeforeUpdate = _newMinimumTime;
    MinimumTimeBeforeUpdateChanged(_newMinimumTime);
  }



  // private methods


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
