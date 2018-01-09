pragma solidity ^0.4.18;

import '../Authorizable.sol';

contract AuthorizableMock is Authorizable {

  function getAuthorizedAddresses() public constant returns (address[]) {
    return _authorized;
  }

  uint public testVariable = 0;

  function setTestVariable1() onlyAuthorized public {
    testVariable = 1;
  }

  function setTestVariable2() onlyAuthorizedAtLevel(5) public {
    testVariable = 2;
  }

  function setTestVariable3() onlyAuthorizedAtLevelEqualOrMoreThan(4) public {
    testVariable = 3;
  }

  function setTestVariable4() onlyOwnerOrAuthorized public {
    testVariable = 4;
  }

  function setTestVariable5() onlyOwnerOrAuthorizedAtLevel(5) public {
    testVariable = 5;
  }

  function setTestVariable6() onlyOwnerOrAuthorizedAtLevelEqualOrMoreThan(5) public {
    testVariable = 6;
  }

}