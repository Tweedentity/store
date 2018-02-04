pragma solidity ^0.4.18;

import './Authorizable.sol';


// Handles the pure data and returns info about the data.
// The logic is implemented in TweedentityStore, which is upgradable
// because can be set as the new owner of this contract

contract TweedentityData is Authorizable {

  mapping(address => string) public screenNameByAddress;
  uint public totalTweedentities = 0;

  uint public minimumTimeRequiredBeforeUpdate = 1 days;

  struct Uid {
    string screenName;
    uint lastUpdate;
    address lastAddress;
  }

  bool public isTweedentityData = true;

  mapping(string => string) internal uidByScreenName;
  mapping(string => Uid) internal dataByUid;

  event tweedentityAdded(address _address, string _screenName);
  event tweedentityRemoved(address _address, string _screenName);
  event minimumTimeRequiredBeforeUpdateChanged(uint _time);

  function addTweedentity(address _address, string _screenName, string _uid) public onlyAuthorized {
    require(!isSet(_uid) || isUpgradable(_uid));

    _screenName = toLower(_screenName);
    screenNameByAddress[_address] = _screenName;
    uidByScreenName[_screenName] = _uid;
    dataByUid[_uid] = Uid(_screenName, now, _address);
    totalTweedentities++;
    tweedentityAdded(_address, _screenName);
  }

  function removeTweedentity(address _address) public onlyAuthorized {
    dataByUid[uidByScreenName[screenNameByAddress[_address]]].lastAddress = address(0);
    totalTweedentities--;
    delete screenNameByAddress[_address];
    tweedentityRemoved(_address, screenNameByAddress[_address]);
  }

  // Changes the minimum time required before being allowed to update
  // a tweedentity associating a new address to a screenName
  function changeMinimumTimeRequiredBeforeUpdate(uint _newMinimumTime) onlyAuthorized public {
    minimumTimeRequiredBeforeUpdate = _newMinimumTime;
    minimumTimeRequiredBeforeUpdateChanged(_newMinimumTime);
  }

  // helpers

  function isSet(string _uid) public constant returns (bool){
    return dataByUid[_uid].lastAddress != address(0);
  }

  function isSet(address _address) public constant returns (bool){
    return bytes(screenNameByAddress[_address]).length > 0;
  }

  function isUpgradable(string _uid) public constant returns (bool) {
    return now >= dataByUid[_uid].lastUpdate + minimumTimeRequiredBeforeUpdate;
  }

  function getScreenNameHashByUid(string _uid) public constant returns (bytes32){
    return keccak256(dataByUid[_uid].screenName);
  }

  function getUidHashByScreenName(string _screenName) public constant returns (bytes32){
    return keccak256(uidByScreenName[_screenName]);
  }

  function getAddressByUid(string _uid) public constant returns (address){
    return dataByUid[_uid].lastAddress;
  }

  function getAddressByScreenName(string _screenName) public constant returns (address){
    return dataByUid[uidByScreenName[_screenName]].lastAddress;
  }

  function getLastUpdateByUid(string _uid) public constant returns(uint) {
    return dataByUid[_uid].lastUpdate;
  }

  function getLastUpdateByScreenName(string _screenName) public constant returns(uint) {
    return dataByUid[uidByScreenName[_screenName]].lastUpdate;
  }

  // Converts a string to the lower case
  // @thanks https://gist.github.com/thomasmaclean/276cb6e824e48b7ca4372b194ec05b97
  function toLower(string str) public constant returns (string) {
    bytes memory bStr = bytes(str);
    bytes memory bLower = new bytes(bStr.length);
    for (uint i = 0; i < bStr.length; i++) {
      if (bStr[i] >= 65 && bStr[i] <= 90) {
        bLower[i] = bytes1(int(bStr[i]) + 32);
      } else {
        bLower[i] = bStr[i];
      }
    }
    return string(bLower);
  }


}