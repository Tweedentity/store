pragma solidity ^0.4.18;

// File: contracts/TweedentityManagerInterfaceCompact.sol

contract TweedentityManagerInterfaceCompact {

  function isSettable(uint _id, string _nickname)
  external
  constant
  returns (bool)
  {}

}

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

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

  uint public identities;

  TweedentityManagerInterfaceCompact private manager;

  struct Uid {
    string lastUid;
    uint lastUpdate;
  }

  struct Address {
    address lastAddress;
    uint lastUpdate;
  }

  address public managerAddress;

  modifier onlyManager() {
    require(msg.sender == managerAddress);
    _;
  }

  function setManager(
    address _address
  )
  external
  onlyOwner
  {
    require(_address != address(0));
    managerAddress = _address;
    manager = TweedentityManagerInterfaceCompact(_address);
  }

  // declaring app
  // example: (Twitter, twitter.com, twitter)

  struct App {
    string name;
    string domain;
    string nickname;
    uint id;
  }

  App public app;
  bool public appSet;

  modifier isAppSet() {
    require(appSet);
    _;
  }

  function setApp(
    string _name,
    string _domain,
    string _nickname,
    uint _id
  )
  external
  onlyOwner
  {
    require(_id > 0);
    require(!appSet);
    require(manager.isSettable(_id, _nickname));
    app = App(_name, _domain, _nickname, _id);
    appSet = true;
  }

  function getAppNickname()
  external
  isAppSet
  constant returns (bytes32) {
    return keccak256(app.nickname);
  }

  function getAppId()
  external
  isAppSet
  constant returns (uint) {
    return app.id;
  }

  // events

  event IdentitySet(
    address addr,
    string uid
  );

  event IdentityRemoved(
    address addr,
    string uid
  );


  // mappings

  mapping(string => Address) internal __addressByUid;

  mapping(address => Uid) internal __uidByAddress;

  // helpers

  function isUidSet(
    string _uid
  )
  public
  constant returns (bool)
  {
    return __addressByUid[_uid].lastAddress != address(0);
  }

  function isAddressSet(
    address _address
  )
  public
  constant returns (bool)
  {
    return bytes(__uidByAddress[_address].lastUid).length > 0;
  }

  function isUpgradable(
    address _address,
    string _uid
  )
  public
  constant returns (bool)
  {
    if (isUidSet(_uid)) {
      return keccak256(getUid(_address)) == keccak256(_uid);
    }
    return true;
  }

  // primary methods

  function setIdentity(
    address _address,
    string _uid
  )
  external
  onlyManager
  isAppSet
  {
    require(_address != address(0));
    require(isUid(_uid));
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

  function removeIdentity(
    address _address
  )
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

  function __removeIdentity(
    address _address
  )
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

  function getUid(
    address _address
  )
  public
  constant returns (string)
  {
    return __uidByAddress[_address].lastUid;
  }

  function getUidAsInteger(
    address _address
  )
  external
  constant returns (uint)
  {
    return __stringToUint(__uidByAddress[_address].lastUid);
  }

  function getAddress(
    string _uid
  )
  external
  constant returns (address)
  {
    return __addressByUid[_uid].lastAddress;
  }

  function getAddressLastUpdate(
    address _address
  )
  external
  constant returns (uint)
  {
    return __uidByAddress[_address].lastUpdate;
  }

  function getUidLastUpdate(
    string _uid
  )
  external
  constant returns (uint)
  {
    return __addressByUid[_uid].lastUpdate;
  }

  // string methods

  function isUid(
    string _uid
  )
  public
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

// File: authorizable/contracts/AuthorizableLite.sol

/**
 * @title AuthorizableLite
 * @author Francesco Sullo <francesco@sullo.co>
 * @dev The Authorizable contract provides governance.
 */

contract AuthorizableLite /** 0.1.9 */ is Ownable {

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
