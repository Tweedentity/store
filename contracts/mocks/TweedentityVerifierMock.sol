pragma solidity ^0.4.18;


import '../TweedentityVerifier.sol';


contract TweedentityVerifierMock is TweedentityVerifier {

  address public managerAddress;

  function setManager(address _address) onlyOwner public {
    super.setManager(_address);
    managerAddress = _address;
  }

}
