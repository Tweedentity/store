pragma solidity ^0.4.18;


import './Authorizable.sol';


// Handles the pure data and returns info about the data.
// The logic is implemented in Store, which is upgradable
// because can be set as the new owner of Database

contract Database is Authorizable {

  uint public identities = 0;

  bool public isDatabase = true;

  uint public minimumTimeBeforeUpdate = 1 days;

  struct Uid {
    string lastUid;
    uint lastUpdate;
  }

  struct Address {
    string lastAddress;
    uint lastUpdate;
  }

  // mappings

  mapping(string => Address) internal addressByUid;

  mapping(address => Uid) internal uidByAddress;

  // events

  event tweedentityAdded(address _address, string _screenName, string _uid);

  event tweedentityRemoved(address _address, string _screenName, string _uid);

  event minimumTimeBeforeUpdateChanged(uint _time);

  // helpers

  function isUidSet(string _uid) public constant returns (bool){
    return addressByUid[_uid].lastAddress != address(0);
  }

  function isAddressSet(address _address) public constant returns (bool){
    return bytes(profileByAddress[_address].uid).length > 0;
  }

  function isUidUpgradable(address _uid) public constant returns (bool) {
    return addressByUid[_uid].lastUpdate == 0 || now >= addressByUid[_uid].lastUpdate + minimumTimeRequiredBeforeUpdate;
  }

  function isAddressUpgradable(address _address) public constant returns (bool) {
    return uidByAddress[_address].lastUpdate == 0 || now >= uidByAddress[_address].lastUpdate + minimumTimeRequiredBeforeUpdate;
  }

  function isUpgradable(address _address, string _uid) public constant returns (bool) {
    if (isAddressSet(_address)) {
      if (keccak256(uidByAddress[_address].lastUid) == keccak256(_uid) // the couple is unchanged
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

  function setIdentity(address _address, string _uid) public onlyAuthorized {
    require(_address != address(0));
    require(bytes(_uid).length > 0);
    require(isUpgradable(_address, _uid));

    if (isAddressSet(_address)) {
      // if _address is now associated with a new uid,
      // this removes the association between_address and last uid associated with it
      addressByUid[uidByAddress[_address].lastUid] = Address(address(0), addressByUid[uidByAddress[_address].lastUid].lastUpdate);
    }

    uidByAddress[_address] = Uid(_uid, now);
    addressByUid[uid] = Address(_address, now);
    identities++;

    tweedentityAdded(_address, _screenName, _uid);
  }

  function removeIdentity(address _address) public onlyAuthorized {
    require(_address != address(0));
    require(isAddressSet(_address));

    string memory uid = uidByAddress[_address].lastUid;
    uidByAddress[_address] = Uid('', uidByAddress[_address].lastUpdate);
    addressByUid[uid] = Address(address(0), addressByUid[uid].lastUpdate);
    identities--;

    tweedentityRemoved(_address, screenNameByAddress[_address], uid);
  }

  // Changes the minimum time required before being allowed to update
  // a tweedentity associating a new address to a screenName
  function changeMinimumTimeBeforeUpdate(uint _newMinimumTime) onlyAuthorized public {
    minimumTimeBeforeUpdate = _newMinimumTime;
    minimumTimeBeforeUpdateChanged(_newMinimumTime);
  }

  // getters

  function getUid(address _address) public constant returns (string){
    return uidByAddress[_address].lastUid;
  }

  function getAddress(string _uid) public constant returns (address){
    return addressByUid[_uid].lastAddress;
  }

  function getUidHashByAddressByScreenName(address _address) public constant returns (bytes32){
    if (isAddressSet(_address)) {
      return keccak256(uidByAddress[_address].lastUid);
    } else {
      return keccak256('-');
    }
  }

}