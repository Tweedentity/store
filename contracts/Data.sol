pragma solidity ^0.4.18;


import './Authorizable.sol';


// Handles the pure data and returns info about the data.
// The logic is implemented in Store, which is upgradable
// because can be set as the new owner of Data

contract Data is Authorizable {

  uint public totalTweedentities = 0;

  bool public isData = true;

  uint public minimumTimeRequiredBeforeUpdate = 1 days;

  struct Uid {
    string screenName;
    address lastAddress;
    uint lastUpdate;
  }

  // mappings

  mapping(address => string) public screenNameByAddress;

  mapping(string => string) internal uidByScreenName;

  mapping(string => Uid) internal dataByUid;

  // events

  event tweedentityAdded(address _address, string _screenName, string _uid);

  event tweedentityRemoved(address _address, string _screenName, string _uid);

  event minimumTimeRequiredBeforeUpdateChanged(uint _time);

  // modifiers

  modifier canUpgrade(string _uid) {
    require(isUpgradable(_uid));
    _;
  }

  modifier canRemove(address _address) {
    require(isSet(_address));
    _;
  }

  modifier canSet(address _address) {
    require(!isSet(_address));
    _;
  }

  function setIdentity(address _address, string _screenName, string _uid) public onlyAuthorized canUpgrade(_uid) {
    //    if (isSet(_address)) {
    //      // only screenName change allowed
    //      require()
    //    }
    _screenName = toLower(_screenName);
    screenNameByAddress[_address] = _screenName;
    uidByScreenName[_screenName] = _uid;
    if (!isSetU(_uid)) {
      totalTweedentities++;
    } else {
      if (dataByUid[_uid].lastAddress != _address) {
        // the user is changing the address
        delete screenNameByAddress[dataByUid[_uid].lastAddress];
      }
      if (keccak256(dataByUid[_uid].screenName) != keccak256(_screenName)) {
        // the user has changed the screenName <<< bad move!
        delete uidByScreenName[dataByUid[_uid].screenName];
      }
    }
    dataByUid[_uid] = Uid(_screenName, _address, now);
    tweedentityAdded(_address, _screenName, _uid);
  }

  function removeIdentity(address _address) public onlyAuthorized canRemove(_address) {
    string memory uid = uidByScreenName[screenNameByAddress[_address]];
    delete uidByScreenName[screenNameByAddress[_address]];
    delete screenNameByAddress[_address];
    delete dataByUid[uid];
    totalTweedentities--;
    tweedentityRemoved(_address, screenNameByAddress[_address], uid);
  }

  // Changes the minimum time required before being allowed to update
  // a tweedentity associating a new address to a screenName
  function changeMinimumTimeRequiredBeforeUpdate(uint _newMinimumTime) onlyAuthorized public {
    minimumTimeRequiredBeforeUpdate = _newMinimumTime;
    minimumTimeRequiredBeforeUpdateChanged(_newMinimumTime);
  }

  // helpers callable by other contracts

  function isSetU(string _uid) public constant returns (bool){
    return dataByUid[_uid].lastAddress != address(0);
  }

  function isSet(address _address) public constant returns (bool){
    return bytes(screenNameByAddress[_address]).length > 0;
  }

  function isUpgradable(string _uid) public constant returns (bool) {
    return isSetU(_uid) == false || now >= dataByUid[_uid].lastUpdate + minimumTimeRequiredBeforeUpdate;
  }

  function isScreenNameAssociatedWithUidOrAbsent(string _screenName, string _uid) public constant returns (bool){
    _screenName = toLower(_screenName);
    string memory screenName = dataByUid[_uid].screenName;
    if (bytes(screenName).length > 0 && keccak256(screenName) != keccak256(_screenName)) {
      return false;
    } else {
      return true;
    }
  }

  function isUidAssociatedWithScreenNameOrAbsent(string _screenName, string _uid) public constant returns (bool){
    _screenName = toLower(_screenName);
    string memory uid = uidByScreenName[_screenName];
    if (bytes(uid).length > 0 && keccak256(uid) != keccak256(_uid)) {
      return false;
    } else {
      return true;
    }
  }

  function getScreenNameHashByUid(string _uid) public constant returns (bytes32){
    if (bytes(dataByUid[_uid].screenName).length > 0) {
      return keccak256(dataByUid[_uid].screenName);
    }
    else {
      return keccak256('-');
    }
  }

  function getUidHashByScreenName(string _screenName) public constant returns (bytes32){
    _screenName = toLower(_screenName);
    if (bytes(uidByScreenName[_screenName]).length > 0) {
      return keccak256(uidByScreenName[_screenName]);
    }
    else {
      return keccak256('-');
    }
  }

  function getAddressByUid(string _uid) public constant returns (address){
    return dataByUid[_uid].lastAddress;
  }

  function getAddressByScreenName(string _screenName) public constant returns (address){
    _screenName = toLower(_screenName);
    return dataByUid[uidByScreenName[_screenName]].lastAddress;
  }

  // Converts a string to the lower case
  // @thanks https://gist.github.com/thomasmaclean/276cb6e824e48b7ca4372b194ec05b97
  function toLower(string str) public constant returns (string) {
    bytes memory bStr = bytes(str);
    bytes memory bLower = new bytes(bStr.length);
    for (uint i = 0; i < bStr.length; i++) {
      if (bStr[i] >= 65 && bStr[i] <= 90) {
        bLower[i] = bytes1(int(bStr[i]) + 32);
      }
      else {
        bLower[i] = bStr[i];
      }
    }
    return string(bLower);
  }


}