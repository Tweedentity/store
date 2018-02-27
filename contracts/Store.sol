pragma solidity ^0.4.18;


import 'zeppelin/math/SafeMath.sol';
import 'zeppelin/ownership/Ownable.sol';

import './Authorizable.sol';
import './Data.sol';


contract Store is Authorizable {
  using SafeMath for uint;

  Data public data;

  bool public isStore = true;

  uint public version = 1;

  uint public minimumTimeRequiredBeforeUpdate = 1 days;

  function setData(address _address) public onlyOwner {
    data = Data(_address);
    require(data.isData());
  }

  // Adds a new identity
  function setIdentity(address _address, string _screenName, string _uid) onlyAuthorized public {
    require(_address != 0x0);
    require(bytes(_screenName).length > 0);
    require(bytes(_uid).length > 0);

    // this version does not allow to change
    // the screenName associated with a certain userId
    require(data.isScreenNameAssociatedWithUidOrAbsent(_screenName, _uid));
    require(data.isUidAssociatedWithScreenNameOrAbsent(_screenName, _uid));

    data.setIdentity(_address, _screenName, _uid);
  }

  // Remove an existent identity.
  function removeIdentity(address _address) onlyAuthorized public {
    return _removeIdentity(_address);
  }

  // Remove the identity associated to msg.sender
  function removeMyIdentity() public {
    return _removeIdentity(msg.sender);
  }

  // Remove an existent identity.
  // This is allowed only if a certain time is passed since last update.
  function _removeIdentity(address _address) internal {
    require(_address != 0x0);

    data.removeIdentity(_address);
  }

  // Changes the minimum time required before being allowed to update
  // an identity associating a new address to a screenName
  function changeMinimumTimeRequiredBeforeUpdate(uint _newMinimumTime) onlyAuthorized public {
    data.changeMinimumTimeRequiredBeforeUpdate(_newMinimumTime);
  }

}