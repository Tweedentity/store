pragma solidity ^0.4.18;

import 'zeppelin/ownership/Ownable.sol';


// @title Authorizable
// The Authorizable contract provides authorization control functions.

/*
  The level is a uint8 between 0 and 9
  0 means not authorized, 1..9 means authorized

  Having more levels allows to create hierarchical roles.
  For example:
    ...
    operatorLevel: 2
    teamManagerLevel: 3
    ...
    CEOLevel: 7
    ...
    one less than owner: 9

  If the owner wants to execute function which require authorization,
  it has to authorize itself.
*/


contract Authorizable is Ownable {

  mapping(address => uint8) public authorized;
  address[] internal _authorized;

  event AuthorizedAdded(address indexed _address, uint8 _level);

  event AuthorizedRemoved(address indexed _address);

  // Throws if called by any account which is not authorized.
  modifier onlyAuthorized() {
    require(authorized[msg.sender] > 0);
    _;
  }

  modifier onlyOwnerOrAuthorized() {
    require(msg.sender == owner || authorized[msg.sender] > 0);
    _;
  }

  // Throws if called by any account which is not authorized at a specific level.
  modifier onlyAuthorizedAtLevel(uint8 _level) {
    require(authorized[msg.sender] == _level);
    _;
  }

  modifier onlyOwnerOrAuthorizedAtLevel(uint8 _level) {
    require(msg.sender == owner || authorized[msg.sender] == _level);
    _;
  }

  // Throws if called by any account which is not authorized at a minimum required level.
  modifier onlyAuthorizedAtLevelEqualOrMoreThan(uint8 _level) {
    require(authorized[msg.sender] >= _level);
    _;
  }

  modifier onlyOwnerOrAuthorizedAtLevelEqualOrMoreThan(uint8 _level) {
    require(msg.sender == owner || authorized[msg.sender] >= _level);
    _;
  }

  // Allows the current owner and authorized with level >=8 to add a new authorized address.
  function authorize(address _address, uint8 _level) onlyOwnerOrAuthorizedAtLevel(9) public {
    _authorize(_address, _level);
  }

  // Allows the current owner to remove all the authorizations.
  function deAuthorizeAll() onlyOwner public {
    for (uint i = 0; i < _authorized.length; i++) {
      _authorize(_authorized[i], 0);
    }
  }

  // Allows an authorized to de-authorize itself.
  function deAuthorize() onlyAuthorized public {
    _authorize(msg.sender, 0);
  }

  // internal function which performs the action
  function _authorize(address _address, uint8 _level) internal {
    require(_address != 0x0);

    uint i;
    if (_level > 0) {
      bool alreadyIndexed = false;
      for (i = 0; i < _authorized.length; i++) {
        if (_authorized[i] == _address) {
          alreadyIndexed = true;
          break;
        }
      }
      if (alreadyIndexed == false) {
        _authorized.push(_address);
      }
      AuthorizedAdded(_address, _level);
      authorized[_address] = _level;
    } else {
      for (i = 0; i < _authorized.length; i++) {
        if (_authorized[i] == _address) {
          _authorized[i] = 0x0;
          break;
        }
      }
      AuthorizedRemoved(_address);
      delete authorized[_address];
    }
  }

}