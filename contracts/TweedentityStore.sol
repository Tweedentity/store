pragma solidity ^0.4.18;


import 'openzeppelin-solidity/contracts/ownership/HasNoEther.sol';


interface UidChecker {
  function isUid(string _uid) public pure returns (bool);
}


/**
 * @title TweedentityStore
 * @author Francesco Sullo <francesco@sullo.co>
 * @dev It store the tweedentities related to the app
 */



contract TweedentityStore
is HasNoEther
{

  string public version = "1.5.0";

  uint public appId;
  string public appNickname;

  uint public identities;

  address public manager;
  address public newManager;

  UidChecker public checker;

  struct Uid {
    string lastUid;
    uint lastUpdate;
  }

  struct Address {
    address lastAddress;
    uint lastUpdate;
  }

  mapping(string => Address) internal __addressByUid;
  mapping(address => Uid) internal __uidByAddress;

  bool public appSet;



  // events


  event IdentitySet(
    address indexed addr,
    string uid
  );


  event IdentityUnset(
    address indexed addr,
    string uid
  );



  // modifiers


  modifier onlyManager() {
    require(msg.sender == manager || (newManager != address(0) && msg.sender == newManager));
    _;
  }


  modifier whenAppSet() {
    require(appSet);
    _;
  }



  // config


  /**
  * @dev Updates the checker for the store
  * @param _address Checker's address
  */
  function setNewChecker(
    address _address
  )
  external
  onlyOwner
  {
    require(_address != address(0));
    checker = UidChecker(_address);
  }


  /**
  * @dev Sets the manager
  * @param _address Manager's address
  */
  function setManager(
    address _address
  )
  external
  onlyOwner
  {
    require(_address != address(0));
    manager = _address;
  }


  /**
  * @dev Sets new manager
  * @param _address New manager's address
  */
  function setNewManager(
    address _address
  )
  external
  onlyOwner
  {
    require(_address != address(0) && manager != address(0));
    newManager = _address;
  }


  /**
  * @dev Sets new manager
  */
  function switchManagerAndRemoveOldOne()
  external
  onlyOwner
  {
    manager = newManager;
    newManager = address(0);
  }


  /**
  * @dev Sets the app
  * @param _appNickname Nickname (e.g. twitter)
  * @param _appId ID (e.g. 1)
  */
  function setApp(
    string _appNickname,
    uint _appId,
    address _checker
  )
  external
  onlyOwner
  {
    require(!appSet);
    require(_appId > 0);
    require(_checker != address(0));
    require(bytes(_appNickname).length > 0);
    appId = _appId;
    appNickname = _appNickname;
    checker = UidChecker(_checker);
    appSet = true;
  }



  // helpers


  /**
   * @dev Checks if a tweedentity is upgradable
   * @param _address The address
   * @param _uid The user-id
   */
  function isUpgradable(
    address _address,
    string _uid
  )
  public
  constant returns (bool)
  {
    if (__addressByUid[_uid].lastAddress != address(0)) {
      return keccak256(getUid(_address)) == keccak256(_uid);
    }
    return true;
  }



  // primary methods


  /**
   * @dev Sets a tweedentity
   * @param _address The address of the wallet
   * @param _uid The user-id of the owner user account
   */
  function setIdentity(
    address _address,
    string _uid
  )
  external
  onlyManager
  whenAppSet
  {
    require(_address != address(0));
    require(isUid(_uid));
    require(isUpgradable(_address, _uid));

    if (bytes(__uidByAddress[_address].lastUid).length > 0) {
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


  /**
   * @dev Unset a tweedentity
   * @param _address The address of the wallet
   */
  function unsetIdentity(
    address _address
  )
  external
  onlyManager
  whenAppSet
  {
    require(_address != address(0));
    require(bytes(__uidByAddress[_address].lastUid).length > 0);

    string memory uid = __uidByAddress[_address].lastUid;
    __uidByAddress[_address] = Uid('', __uidByAddress[_address].lastUpdate);
    __addressByUid[uid] = Address(address(0), __addressByUid[uid].lastUpdate);
    identities--;
    IdentityUnset(_address, uid);
  }



  // getters


  /**
   * @dev Returns the keccak256 of the app nickname
   */
  function getAppNickname()
  external
  whenAppSet
  constant returns (bytes32) {
    return keccak256(appNickname);
  }


  /**
   * @dev Returns the appId
   */
  function getAppId()
  external
  whenAppSet
  constant returns (uint) {
    return appId;
  }


  /**
   * @dev Returns the user-id associated to a wallet
   * @param _address The address of the wallet
   */
  function getUid(
    address _address
  )
  public
  constant returns (string)
  {
    return __uidByAddress[_address].lastUid;
  }


  /**
   * @dev Returns the address associated to a user-id
   * @param _uid The user-id
   */
  function getAddress(
    string _uid
  )
  external
  constant returns (address)
  {
    return __addressByUid[_uid].lastAddress;
  }


  /**
   * @dev Returns the timestamp of last update by address
   * @param _address The address of the wallet
   */
  function getAddressLastUpdate(
    address _address
  )
  external
  constant returns (uint)
  {
    return __uidByAddress[_address].lastUpdate;
  }


  /**
 * @dev Returns the timestamp of last update by user-id
 * @param _uid The user-id
 */
  function getUidLastUpdate(
    string _uid
  )
  external
  constant returns (uint)
  {
    return __addressByUid[_uid].lastUpdate;
  }



  // utils


  function isUid(
    string _uid
  )
  public
  view
  returns (bool)
  {
    return checker.isUid(_uid);
  }

}
