pragma solidity ^0.4.18;


import 'zeppelin/math/SafeMath.sol';
import 'zeppelin/ownership/Ownable.sol';

import './Authorizable.sol';
import './TweedentityData.sol';


contract TweedentityStore is Authorizable {
  using SafeMath for uint;

  TweedentityData public data;

  bool public isTweedentityStore = true;

  uint public version = 1;

  uint public minimumTimeRequiredBeforeUpdate = 1 days;

  function setData(address _address) public onlyOwner {
    data = TweedentityData(_address);
    require(data.isTweedentityData());
  }

  // Adds a new tweedentity
  function addTweedentity(address _address, string _screenName, string _uid) onlyAuthorized public {
    require(_address != 0x0);
    require(bytes(_screenName).length > 0);

    // this version does not allow to change
    // the screenName associated with a certain userId
    bytes32 hash = data.getScreenNameHashByUid(_uid);
    require(hash == keccak256('0') || hash == keccak256(toLower(_screenName)));

    data.addTweedentity(_address, _screenName, _uid);
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

    data.removeTweedentity(_address);
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