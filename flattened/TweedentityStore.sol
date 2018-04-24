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

// File: authorizable/contracts/Authorizable.sol

/**
 * @title Authorizable
 * @author Francesco Sullo <francesco@sullo.co>
 * @dev The Authorizable contract provides governance.
 */

contract Authorizable /** 0.1.6 */ is Ownable {

  uint public totalAuthorized;

  mapping(address => uint) public authorized;
  address[] internal __authorized;

  event AuthorizedAdded(address _authorizer, address _authorized, uint _level);

  event AuthorizedRemoved(address _authorizer, address _authorized);

  uint public maxLevel = 64;
  uint public authorizerLevel = 56;

  bool public selfRevoke = true;
  mapping (uint => bool) public selfRevokeException;

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
  * @dev Allows to decide if users will be able to self revoke their level
  * @param _selfRevoke The new value
  */
  function setSelfRevoke(bool _selfRevoke) onlyOwner external {
    selfRevoke = _selfRevoke;
  }

  /**
  * @dev Allows to set exceptions to selfRevoke when this is true
  * @param _level The level not allowed to self-revoke
  * @param _isActive `true` adds the lock, `false` removes it
  */
  function addSelfRevokeException(uint _level, bool _isActive) onlyOwner external {
    selfRevokeException[_level] = _isActive;
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
   * @dev Throws if called by any account which is not authorized
   *      at some of the specified levels.
   * @param _levels Levels required
   */
  modifier onlyAuthorizedAtLevels(uint[] _levels) {
    require(__hasLevel(authorized[msg.sender], _levels));
    _;
  }

  /**
   * @dev Throws if called by any account which has
   *      a level of authorization not in the interval
   * @param _minLevel Minimum level required
   * @param _maxLevel Maximum level required
   */
  modifier onlyAuthorizedAtLevelsWithin(uint _minLevel, uint _maxLevel) {
    require(authorized[msg.sender] >= _minLevel && authorized[msg.sender] <= _maxLevel);
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

  modifier onlyOwnerOrAuthorizedAtLevels(uint[] _levels) {
    require(msg.sender == owner || __hasLevel(authorized[msg.sender], _levels));
    _;
  }

  modifier onlyOwnerOrAuthorizedAtLevelsIn(uint _minLevel, uint _maxLevel) {
    require(msg.sender == owner || (authorized[msg.sender] >= _minLevel && authorized[msg.sender] <= _maxLevel));
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
    * @dev Allows to add a list of new authorized addresses.
    *      Useful, for example, with whitelists
    * @param _addresses Array of addresses to be authorized
    * @param _level The level of authorization
    */
  function authorizeBatch(address[] _addresses, uint _level) onlyAuthorizer external {
    require(_level > 0);
    for (uint i = 0; i < _addresses.length; i++) {
      __authorize(_addresses[i], _level);
    }
  }

  /**
   * @dev Allows to remove all the authorizations. Callable by the owner only.
   *      We check the gas to avoid going out of gas when there are tons of
   *      authorized addresses (for example when used for a whitelist).
   *      If at the end of the operation there are still authorized
   *      wallets the operation must be repeated.
   */
  function deAuthorizeAll() onlyOwner external {
    for (uint i = 0; i < __authorized.length && msg.gas > 33e3; i++) {
      if (__authorized[i] != address(0)) {
        __authorize(__authorized[i], 0);
      }
    }
  }

  /**
   * @dev Allows to remove all the authorizations at a specific level.
   * @param _level The level of authorization
   */
  function deAuthorizeAllAtLevel(uint _level) onlyAuthorizer external {
    for (uint i = 0; i < __authorized.length && msg.gas > 33e3; i++) {
      if (__authorized[i] != address(0) && authorized[__authorized[i]] == _level) {
        __authorize(__authorized[i], 0);
      }
    }
  }

  /**
   * @dev Allows an authorized to de-authorize itself.
   */
  function deAuthorize() onlyAuthorized external {
    require(selfRevoke == true && selfRevokeException[authorized[msg.sender]] == false);
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

// File: contracts/TweedentityStore.sol

// Handles the pure data and returns info about the data.
// The logic is implemented in TweedentityTweedentityStore, which is upgradable
// because can be set as the new owner of TweedentityStore

contract TweedentityStore is Authorizable {

  uint public identities;
  uint public managerLevel = 40;
  uint public customerServiceLevel = 30;
  uint public devLevel = 20;

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

  event MinimumTimeBeforeUpdateChanged(uint _time);

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

  function setIdentity(address _address, string _uid) public onlyAuthorizedAtLevel(managerLevel) {
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

  function removeIdentity(address _address) public onlyAuthorizedAtLevel(customerServiceLevel) {
    __removeIdentity(_address);
  }

  function removeMyIdentity() public {
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
  function changeMinimumTimeBeforeUpdate(uint _newMinimumTime) onlyAuthorizedAtLevel(devLevel) public {
    minimumTimeBeforeUpdate = _newMinimumTime;
    MinimumTimeBeforeUpdateChanged(_newMinimumTime);
  }

  // getters

  function getUid(address _address) public constant returns (string){
    return __uidByAddress[_address].lastUid;
  }

  function getUidAsInteger(address _address) public constant returns (uint){
    return __stringToUint(__uidByAddress[_address].lastUid);
  }

  function getAddress(string _uid) public constant returns (address){
    return __addressByUid[_uid].lastAddress;
  }

  function getAddressLastUpdate(address _address) public constant returns (uint) {
    return __uidByAddress[_address].lastUpdate;
  }

  function getUidLastUpdate(string _uid) public constant returns (uint) {
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
