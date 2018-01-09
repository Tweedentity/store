pragma solidity ^0.4.18;

import 'zeppelin/math/SafeMath.sol';

import './AuthorizableLite.sol';


contract TweedentityStore is AuthorizableLite {
  using SafeMath for uint;

  mapping(address => string) public tweedentities;
  uint public totalTweedentities = 0;

  uint public minimumTimeRequiredBeforeUpdate = 1 days;

  struct ScreenName {
    uint lastUpdate;
    address lastAddress;
  }

  mapping(string => ScreenName) internal _screenNames;

  event MinimumTimeRequiredBeforeUpdateChanged(uint _time);
  event TweedentityAdded(address _address, string _screenName);
  event TweedentityRemoved(address _address, string _screenName);

  // Adds a new tweedentity
  function addTweedentity(address _address, string _screenName) onlyAuthorized public {
    require(_address != 0x0);
    require(bytes(_screenName).length > 0);
    require(_screenNames[toLower(_screenName)].lastAddress == 0x0);

    tweedentities[_address] = _screenName;
    _screenNames[toLower(_screenName)] = ScreenName(now, _address);

    TweedentityAdded(_address, _screenName);
    totalTweedentities = totalTweedentities.add(1);
  }

  // Remove an existent tweedentity.
  function removeTweedentity(address _address) onlyAuthorized public {
    return _removeTweedentity(_address);
  }

  // Remove the tweedentity associated to msg.sender
  function removeMyTweedentity() public {
    return _removeTweedentity(msg.sender);
  }

  // Remove an existent tweedentity.
  // This is allowed only if a certain time is passed since last update.
  function _removeTweedentity(address _address) internal {
    require(_address != 0x0);
    require(bytes(tweedentities[_address]).length > 0);
    require(now >= _screenNames[toLower(tweedentities[_address])].lastUpdate + minimumTimeRequiredBeforeUpdate);

    _screenNames[toLower(tweedentities[_address])] = ScreenName(now, 0x0);
    TweedentityRemoved(_address, tweedentities[_address]);
    delete tweedentities[_address];
    totalTweedentities = totalTweedentities.sub(1);
  }

  // Changes the minimum time required before being allowed to remove
  // a tweedentity and associate a screenName to a new address
  function changeMinimumTimeRequiredBeforeUpdate(uint _newMinimumTime) onlyAuthorized public {
    require(_newMinimumTime >= 1 hours && _newMinimumTime <= 1 weeks);

    minimumTimeRequiredBeforeUpdate = _newMinimumTime;
    MinimumTimeRequiredBeforeUpdateChanged(_newMinimumTime);
  }

  // Returns last address associated with a Twitter.
  // It is payable, to avoid spam.
  function getAddressByScreenName(string _screenName) public constant returns (address) {
    require(bytes(_screenName).length > 0);
    if (_screenNames[toLower(_screenName)].lastUpdate > 0) {
      return _screenNames[toLower(_screenName)].lastAddress;
    } else {
      return address(0);
    }
  }


  // Converts a string to the lower case
  // @thanks https://gist.github.com/thomasmaclean/276cb6e824e48b7ca4372b194ec05b97
  function toLower(string str) public constant returns (string) {
    bytes memory bStr = bytes(str);
    bytes memory bLower = new bytes(bStr.length);
    for (uint i = 0; i < bStr.length; i++) {
      if ((bStr[i] >= 65) && (bStr[i] <= 90)) {
        bLower[i] = bytes1(int(bStr[i]) + 32);
      } else {
        bLower[i] = bStr[i];
      }
    }
    return string(bLower);
  }

}