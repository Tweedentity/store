pragma solidity ^0.4.18;

// File: zeppelin/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

// File: authorizable/contracts/Authorizable.sol

// @title Authorizable
// The Authorizable contract provides authorization control functions.

/*
  The level is a uint <= maxLevel (64 by default)
  
    0 means not authorized
    1..maxLevel means authorized

  Having more levels allows to create hierarchical roles.
  For example:
    ...
    operatorLevel: 6
    teamManagerLevel: 10
    ...
    CTOLevel: 32
    ...

  If the owner wants to execute functions which require explicit authorization, it must authorize itself.
  
  If you need complex level, in the extended contract, you can add a function to generate unique roles based on combination of levels. The possibilities are almost unlimited, since the level is a uint256
*/

contract Authorizable is Ownable {

  uint public totalAuthorized;

  mapping(address => uint) public authorized;
  address[] internal __authorized;

  event AuthorizedAdded(address _authorizer, address _authorized, uint _level);

  event AuthorizedRemoved(address _authorizer, address _authorized);

  uint public maxLevel = 64;
  uint public authorizerLevel = 56;

  function setLevels(uint _maxLevel, uint _authorizerLevel) external onlyOwner {
    // this must be called before authorizing any address
    require(totalAuthorized == 0);
    require(_maxLevel > 0 && _authorizerLevel > 0);
    require(_maxLevel >= _authorizerLevel);

    maxLevel = _maxLevel;
    authorizerLevel = _authorizerLevel;
  }

  // Throws if called by any account which is not authorized.
  modifier onlyAuthorized() {
    require(authorized[msg.sender] > 0);
    _;
  }

  // Throws if called by any account which is not authorized at a specific level.
  modifier onlyAuthorizedAtLevel(uint _level) {
    require(authorized[msg.sender] == _level);
    _;
  }

  // Throws if called by any account which is not authorized at some of the specified levels.
  modifier onlyAuthorizedAtLevels(uint[] _levels) {
    require(__hasLevel(authorized[msg.sender], _levels));
    _;
  }

  // Throws if called by any account which is not authorized at a minimum required level.
  modifier onlyAuthorizedAtLevelMoreThan(uint _level) {
    require(authorized[msg.sender] > _level);
    _;
  }

  // Throws if called by any account which has a level of authorization less than a certan maximum.
  modifier onlyAuthorizedAtLevelLessThan(uint _level) {
    require(authorized[msg.sender] > 0 && authorized[msg.sender] < _level);
    _;
  }

  // same modifiers but including the owner

  modifier onlyOwnerOrAuthorized() {
    require(msg.sender == owner || authorized[msg.sender] > 0);
    _;
  }

  modifier onlyOwnerOrAuthorizedAtLevel(uint _level) {
    require(msg.sender == owner || authorized[msg.sender] == _level);
    _;
  }

  modifier onlyOwnerOrAuthorizedAtLevels(uint[] _levels) {
    require(msg.sender == owner || __hasLevel(authorized[msg.sender], _levels));
    _;
  }

  modifier onlyOwnerOrAuthorizedAtLevelMoreThan(uint _level) {
    require(msg.sender == owner || authorized[msg.sender] > _level);
    _;
  }

  modifier onlyOwnerOrAuthorizedAtLevelLessThan(uint _level) {
    require(msg.sender == owner || (authorized[msg.sender] > 0 && authorized[msg.sender] < _level));
    _;
  }

  // Throws if called by anyone who is not an authorizer.
  modifier onlyAuthorizer() {
    require(msg.sender == owner || authorized[msg.sender] >= authorizerLevel);
    _;
  }


  // methods

  // Allows the current owner and authorized with level >= authorizerLevel to add a new authorized address, or remove it, setting _level to 0
  function authorize(address _address, uint _level) onlyAuthorizer external {
    __authorize(_address, _level);
  }

  // Allows the current owner to remove all the authorizations.
  function deAuthorizeAll() onlyOwner external {
    for (uint i = 0; i < __authorized.length; i++) {
      if (__authorized[i] != address(0)) {
        __authorize(__authorized[i], 0);
      }
    }
  }

  // Allows an authorized to de-authorize itself.
  function deAuthorize() onlyAuthorized external {
    __authorize(msg.sender, 0);
  }

  // internal functions
  function __authorize(address _address, uint _level) internal {
    require(_address != address(0));
    require(_level >= 0 && _level <= maxLevel);

    uint i;
    if (_level > 0) {
      bool alreadyIndexed = false;
      for (i = 0; i < __authorized.length; i++) {
        if (__authorized[i] == _address) {
          alreadyIndexed = true;
          break;
        }
      }
      if (alreadyIndexed == false) {
        __authorized.push(_address);
        totalAuthorized++;
      }
      AuthorizedAdded(msg.sender, _address, _level);
      authorized[_address] = _level;
    } else {
      for (i = 0; i < __authorized.length; i++) {
        if (__authorized[i] == _address) {
          __authorized[i] = address(0);
          totalAuthorized--;
          break;
        }
      }
      AuthorizedRemoved(msg.sender, _address);
      delete authorized[_address];
    }
  }

  function __hasLevel(uint _level, uint[] _levels) internal pure returns (bool) {
    bool has = false;
    for (uint i; i < _levels.length; i++) {
      if (_level == _levels[i]) {
        has = true;
        break;
      }
    }
    return has;
  }

  // helpers callable by other contracts

  function amIAuthorized() external constant returns (bool) {
    return authorized[msg.sender] > 0;
  }

  function getLevelOfAuthorization() external constant returns (uint) {
    return authorized[msg.sender];
  }

}

// File: contracts/Store.sol

// Handles the pure data and returns info about the data.
// The logic is implemented in Store, which is upgradable
// because can be set as the new owner of Store

contract Store is Authorizable {

  uint public identities;

  bool public isDatabase = true;

  uint public minimumTimeBeforeUpdate = 1 days;

  struct Uid {
    string lastUid;
    uint lastUpdate;
  }

  struct Address {
    address lastAddress;
    uint lastUpdate;
  }

  // mappings

  mapping(string => Address) internal __addressByUid;

  mapping(address => Uid) internal __uidByAddress;

  // events

  event TweedentityAdded(address indexed _address, string _uid);

  event TweedentityRemoved(address indexed _address, string _uid);

  // helpers

  function isUidSet(string _uid) public constant returns (bool){
    return __addressByUid[_uid].lastAddress != address(0);
  }

  function isAddressSet(address _address) public constant returns (bool){
    return bytes(__uidByAddress[_address].lastUid).length > 0;
  }

  function isUidUpgradable(string _uid) public constant returns (bool) {
    return __addressByUid[_uid].lastUpdate == 0 || now >= __addressByUid[_uid].lastUpdate + minimumTimeBeforeUpdate;
  }

  function isAddressUpgradable(address _address) public constant returns (bool) {
    return __uidByAddress[_address].lastUpdate == 0 || now >= __uidByAddress[_address].lastUpdate + minimumTimeBeforeUpdate;
  }

  function isUpgradable(address _address, string _uid) public constant returns (bool) {
    if (isAddressSet(_address)) {
      if (keccak256(__uidByAddress[_address].lastUid) == keccak256(_uid) // the couple is unchanged
      || !isAddressUpgradable(_address) || !isUidUpgradable(_uid)) {
        return false;
      }
    } else if (isUidSet(_uid)) {
      // last address associated with _uid must remove the identity before associating _uid with _address
      return false;
    }
    return true;
  }

  // primary methods

  function setIdentity(address _address, string _uid) external onlyAuthorized {
    require(_address != address(0));
    require(__isUid(_uid));
    require(isUpgradable(_address, _uid));

    if (isAddressSet(_address)) {
      // if _address is now associated with a new uid,
      // this removes the association between_address and last uid associated with it
      __addressByUid[__uidByAddress[_address].lastUid] = Address(address(0), __addressByUid[__uidByAddress[_address].lastUid].lastUpdate);
      identities--;
    }

    __uidByAddress[_address] = Uid(_uid, now);
    __addressByUid[_uid] = Address(_address, now);
    identities++;

    TweedentityAdded(_address, _uid);
  }

  function removeIdentity(address _address) external onlyOwnerOrAuthorized {
    __removeIdentity(_address);
  }

  function removeMyIdentity() external {
    __removeIdentity(msg.sender);
  }

  function __removeIdentity(address _address) internal {
    require(_address != address(0));
    require(isAddressSet(_address));

    string memory uid = __uidByAddress[_address].lastUid;
    __uidByAddress[_address] = Uid('', __uidByAddress[_address].lastUpdate);
    __addressByUid[uid] = Address(address(0), __addressByUid[uid].lastUpdate);
    identities--;

    TweedentityRemoved(_address, uid);
  }

  // Changes the minimum time required before being allowed to update
  // a tweedentity associating a new address to a screenName
  function changeMinimumTimeBeforeUpdate(uint _newMinimumTime) external onlyAuthorized {
    minimumTimeBeforeUpdate = _newMinimumTime;
  }

  // getters

  function getUid(address _address) external constant returns (string){
    return __uidByAddress[_address].lastUid;
  }

  function getUidAsInteger(address _address) external constant returns (uint){
    return __stringToUint(__uidByAddress[_address].lastUid);
  }

  function getAddress(string _uid) external constant returns (address){
    return __addressByUid[_uid].lastAddress;
  }

  function getAddressLastUpdate(address _address) external constant returns (uint) {
    return __uidByAddress[_address].lastUpdate;
  }

  function getUidLastUpdate(string _uid) external constant returns (uint) {
    return __addressByUid[_uid].lastUpdate;
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

  function __bytesToBytes32(bytes b, uint offset) internal pure returns (bytes32) {
    bytes32 out;

    for (uint i = 0; i < 32; i++) {
      out |= bytes32(b[offset + i] & 0xFF) >> (i * 8);
    }
    return out;
  }

}
