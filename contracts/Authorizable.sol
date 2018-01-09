pragma solidity ^0.4.18;

import 'zeppelin/ownership/Ownable.sol';

import './AuthorizableLite.sol';


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

  If the owner wants to execute function which require authorization,
  it has to authorize itself.
*/


contract Authorizable is AuthorizableLite {

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
  function authorizeLevel(address _address, uint8 _level) onlyOwnerOrAuthorizedAtLevel(9) public {
    _authorize(_address, _level);
  }


}