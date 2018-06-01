pragma solidity ^0.4.18;

// File: zeppelin-solidity/contracts/ownership/Ownable.sol

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
  function Ownable() public {
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
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

// File: contracts/TweedentityStore.sol

contract TweedentityStore is Ownable {

  bytes32 public contractName = keccak256("TweedentityStore");

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

  function setManager(address _address) onlyOwner external {
    require(_address != address(0));
    manager = _address;
  }

  // events

  event TweedentityAdded(address indexed _address, string _uid);

  event TweedentityRemoved(address indexed _address, string _uid);


  // mappings

  mapping(string => Address) internal __addressByUid;

  mapping(address => Uid) internal __uidByAddress;

  // helpers

  function isUidSet(string _uid) public constant returns (bool){
    return __addressByUid[_uid].lastAddress != address(0);
  }

  function isAddressSet(address _address) public constant returns (bool){
    return bytes(__uidByAddress[_address].lastUid).length > 0;
  }

  function isUpgradable(address _address, string _uid) public constant returns (bool) {
    if (isAddressSet(_address)) {
      if (keccak256(getUid(_address)) == keccak256(_uid)) {
        return false;
      }
    }
    else if (isUidSet(_uid)) {
      // last address associated with _uid must remove the identity before associating _uid with _address
      return false;
    }
    return true;
  }

  // primary methods

  function setIdentity(address _address, string _uid) external onlyManager {
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

  function removeIdentity(address _address) external onlyManager {
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

  // getters

  function getUid(address _address) public constant returns (string){
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

}

// File: authorizable/contracts/AuthorizableLite.sol

/**
 * @title AuthorizableLite
 * @author Francesco Sullo <francesco@sullo.co>
 * @dev The Authorizable contract provides governance.
 */

contract AuthorizableLite /** 0.1.8 */ is Ownable {

  uint public totalAuthorized;

  mapping(address => uint) public authorized;
  address[] internal __authorized;

  event AuthorizedAdded(address _authorizer, address _authorized, uint _level);

  event AuthorizedRemoved(address _authorizer, address _authorized);

  uint public maxLevel = 64;
  uint public authorizerLevel = 56;

  /**
   * @dev Set the range of levels accepted by the contract
   * @param _maxLevel The max level acceptable
   * @param _authorizerLevel The minimum level to qualify a wallet as authorizer
   */
  function setLevels(uint _maxLevel, uint _authorizerLevel) external onlyOwner {
    // this must be called before authorizing any address
    require(totalAuthorized == 0);
    require(_maxLevel > 0 && _authorizerLevel > 0);
    require(_maxLevel >= _authorizerLevel);

    maxLevel = _maxLevel;
    authorizerLevel = _authorizerLevel;
  }

  /**
   * @dev Throws if called by any account which is not authorized.
   */
  modifier onlyAuthorized() {
    require(authorized[msg.sender] > 0);
    _;
  }

  /**
   * @dev Throws if called by any account which is not
   *      authorized at a specific level.
   * @param _level Level required
   */
  modifier onlyAuthorizedAtLevel(uint _level) {
    require(authorized[msg.sender] == _level);
    _;
  }

  /**
    * @dev same modifiers above, but including the owner
    */
  modifier onlyOwnerOrAuthorized() {
    require(msg.sender == owner || authorized[msg.sender] > 0);
    _;
  }

  modifier onlyOwnerOrAuthorizedAtLevel(uint _level) {
    require(msg.sender == owner || authorized[msg.sender] == _level);
    _;
  }

  /**
    * @dev Throws if called by anyone who is not an authorizer.
    */
  modifier onlyAuthorizer() {
    require(msg.sender == owner || authorized[msg.sender] >= authorizerLevel);
    _;
  }


  /**
    * @dev Allows to add a new authorized address, or remove it, setting _level to 0
    * @param _address The address to be authorized
    * @param _level The level of authorization
    */
  function authorize(address _address, uint _level) onlyAuthorizer external {
    __authorize(_address, _level);
  }

  /**
   * @dev Allows an authorized to de-authorize itself.
   */
  function deAuthorize() onlyAuthorized external {
    __authorize(msg.sender, 0);
  }

  /**
   * @dev Performs the actual authorization/de-authorization
   *      If there's no change, it doesn't emit any event, to reduce gas usage.
   * @param _address The address to be authorized
   * @param _level The level of authorization. 0 to remove it.
   */
  function __authorize(address _address, uint _level) internal {
    require(_address != address(0));
    require(_level <= maxLevel);

    uint i;
    if (_level > 0 && authorized[_address] != _level) {
        bool alreadyIndexed = false;
        for (i = 0; i < __authorized.length; i++) {
          if (__authorized[i] == _address) {
            alreadyIndexed = true;
            break;
          }
        }
        if (alreadyIndexed == false) {
          bool emptyFound = false;
          // before we try to reuse an empty element of the array
          for (i = 0; i < __authorized.length; i++) {
            if (__authorized[i] == 0) {
              __authorized[i] = _address;
              emptyFound = true;
              break;
            }
          }
          if (emptyFound == false) {
            __authorized.push(_address);
          }
          totalAuthorized++;
        }
        AuthorizedAdded(msg.sender, _address, _level);
        authorized[_address] = _level;
    } else if (_level == 0 && authorized[_address] > 0) {
      for (i = 0; i < __authorized.length; i++) {
        if (__authorized[i] == _address) {
          __authorized[i] = address(0);
          totalAuthorized--;
          AuthorizedRemoved(msg.sender, _address);
          delete authorized[_address];
          break;
        }
      }
    }
  }

  /**
   * @dev Check is a level is included in an array of levels. Used by modifiers
   * @param _level Level to be checked
   * @param _levels Array of required levels
   */
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

  /**
   * @dev Allows a wallet to check if it is authorized
   */
  function amIAuthorized() external constant returns (bool) {
    return authorized[msg.sender] > 0;
  }

  /**
   * @dev Allows any authorizer to get the list of the authorized wallets
   */
  function getAuthorized() external onlyAuthorizer constant returns (address[]) {
    return __authorized;
  }

}

// File: contracts/TweedentityManager.sol

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
