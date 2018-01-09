pragma solidity ^0.4.18;

import 'zeppelin/ownership/Ownable.sol';


// @title AuthorizableLite
// Version simplified ot Authorizable

contract AuthorizableLite is Ownable {

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

  // Allows the current owner and authorized with level >=8 to add a new authorized address.
  function authorize(address _address) onlyOwnerOrAuthorized public {
    _authorize(_address, 1);
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