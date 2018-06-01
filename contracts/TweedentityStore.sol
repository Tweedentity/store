pragma solidity ^0.4.18;


import 'zeppelin-solidity/contracts/ownership/Ownable.sol';

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