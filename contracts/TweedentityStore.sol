pragma solidity ^0.4.18;


import 'openzeppelin-solidity/contracts/ownership/Ownable.sol';

contract TweedentityStore is Ownable {

  uint public identities;

  struct Uid {
    string lastUid;
    uint lastUpdate;
  }

  struct Address {
    address lastAddress;
    uint lastUpdate;
  }

  address public manager;

  modifier onlyManager() {
    require(msg.sender == manager);
    _;
  }

  function setManager(address _address)
  external
  onlyOwner
  {
    require(_address != address(0));
    manager = _address;
  }

  // declaring app
  // example: (Twitter, twitter.com, twitter)

  struct App {
    string name;
    string domain;
    string identifier;
  }

  App public app;
  bool public appSet;

  modifier isAppSet() {
    require(appSet);
    _;
  }

  function setApp(string _name, string _domain, string _identifier)
  external
  onlyOwner
  {
    require(!appSet);
    app = App(_name, _domain, _identifier);
    appSet = true;
  }

  function getAppIdentifier()
  external
  isAppSet
  constant returns (bytes32) {
    return keccak256(app.identifier);
  }

  // events

  event IdentitySet(address addr, string uid);

  event IdentityRemoved(address addr, string uid);


  // mappings

  mapping(string => Address) internal __addressByUid;

  mapping(address => Uid) internal __uidByAddress;

  // helpers

  function isUidSet(string _uid)
  public
  constant returns (bool)
  {
    return __addressByUid[_uid].lastAddress != address(0);
  }

  function isAddressSet(address _address)
  public
  constant returns (bool)
  {
    return bytes(__uidByAddress[_address].lastUid).length > 0;
  }

  function isUpgradable(address _address, string _uid)
  public
  constant returns (bool)
  {
    if (isUidSet(_uid)) {
      return keccak256(getUid(_address)) == keccak256(_uid);
    }
    return true;
  }

  // primary methods

  function setIdentity(address _address, string _uid)
  external
  onlyManager
  isAppSet
  {
    require(_address != address(0));
    require(__isUid(_uid));
    require(isUpgradable(_address, _uid));

    if (isAddressSet(_address)) {
      // if _address is associated with an oldUid,
      // this removes the association between _address and oldUid
      __addressByUid[__uidByAddress[_address].lastUid] = Address(address(0), __addressByUid[__uidByAddress[_address].lastUid].lastUpdate);
      identities--;
    }

    __uidByAddress[_address] = Uid(_uid, now);
    __addressByUid[_uid] = Address(_address, now);
    identities++;
    IdentitySet(_address, _uid);
  }

  function removeIdentity(address _address)
  external
  onlyManager
  isAppSet
  {
    __removeIdentity(_address);
  }

  function removeMyIdentity()
  external
  isAppSet
  {
    __removeIdentity(msg.sender);
  }

  function __removeIdentity(address _address)
  internal
  {
    require(_address != address(0));
    require(isAddressSet(_address));

    string memory uid = __uidByAddress[_address].lastUid;
    __uidByAddress[_address] = Uid('', __uidByAddress[_address].lastUpdate);
    __addressByUid[uid] = Address(address(0), __addressByUid[uid].lastUpdate);
    identities--;
    IdentityRemoved(_address, uid);
  }

  // getters

  function getUid(address _address)
  public
  constant returns (string)
  {
    return __uidByAddress[_address].lastUid;
  }

  function getUidAsInteger(address _address)
  external
  constant returns (uint)
  {
    return __stringToUint(__uidByAddress[_address].lastUid);
  }

  function getAddress(string _uid)
  external
  constant returns (address)
  {
    return __addressByUid[_uid].lastAddress;
  }

  function getAddressLastUpdate(address _address)
  external
  constant returns (uint)
  {
    return __uidByAddress[_address].lastUpdate;
  }

  function getUidLastUpdate(string _uid)
  external
  constant returns (uint)
  {
    return __addressByUid[_uid].lastUpdate;
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

}
