pragma solidity ^0.4.18;

// File: contracts/TweedentityManagerInterfaceMinimal.sol

/**
 * @title TweedentityManagerInterfaceMinimal
 * @author Francesco Sullo <francesco@sullo.co>
 * @dev It store the tweedentities related to the app
 */


contract TweedentityManagerInterfaceMinimal  /** 1.0.0 */
{

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

/**
 * @title TweedentityStore
 * @author Francesco Sullo <francesco@sullo.co>
 * @dev It store the tweedentities related to the app
 */



contract TweedentityStore /** 1.0.0 */
is Ownable
{

  uint public identities;

  TweedentityManagerInterfaceMinimal public manager;
  address public managerAddress;

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

  struct App {
    string name;
    string domain;
    string nickname;
    uint id;
  }

  App public app;
  bool public appSet;



  // events


  event IdentitySet(
    address addr,
    string uid
  );


  event IdentityRemoved(
    address addr,
    string uid
  );



  // modifiers


  modifier onlyManager() {
    require(msg.sender == address(manager));
    _;
  }


  modifier isAppSet() {
    require(appSet);
    _;
  }



  // config


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
    managerAddress = _address;
    manager = TweedentityManagerInterfaceMinimal(_address);
  }


  /**
  * @dev Sets the app
  * @param _name Name (e.g. Twitter)
  * @param _domain Domain (e.g. twitter.com)
  * @param _nickname Nickname (e.g. twitter)
  * @param _id ID (e.g. 1)
  */
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


  // helpers

  /**
   * @dev Checks if a user-id's been used
   * @param _uid The user-id
   */
  function isUidSet(
    string _uid
  )
  public
  constant returns (bool)
  {
    return __addressByUid[_uid].lastAddress != address(0);
  }


  /**
   * @dev Checks if an address's been used
   * @param _address The address
   */
  function isAddressSet(
    address _address
  )
  public
  constant returns (bool)
  {
    return bytes(__uidByAddress[_address].lastUid).length > 0;
  }


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
    if (isUidSet(_uid)) {
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


  /**
   * @dev Unset a tweedentity
   * @param _address The address of the wallet
   */
  function unsetIdentity(
    address _address
  )
  external
  onlyManager
  isAppSet
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


  /**
   * @dev Returns the keccak256 of the app nickname
   */
  function getAppNickname()
  external
  isAppSet
  constant returns (bytes32) {
    return keccak256(app.nickname);
  }


  /**
   * @dev Returns the appId
   */
  function getAppId()
  external
  isAppSet
  constant returns (uint) {
    return app.id;
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
   * @dev Returns the user-id associated to a wallet as a unsigned integer
   * @param _address The address of the wallet
   */
  function getUidAsInteger(
    address _address
  )
  external
  constant returns (uint)
  {
    return __stringToUint(__uidByAddress[_address].lastUid);
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
