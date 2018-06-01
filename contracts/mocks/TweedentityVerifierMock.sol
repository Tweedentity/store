pragma solidity ^0.4.18;


import '../TweedentityVerifier.sol';


contract TweedentityVerifierMock is TweedentityVerifier {

  address public managerAddress;

  function setManager(address _address) onlyOwner public {
    require(_address != 0x0);
    managerAddress = _address;
    manager = TweedentityManager(_address);
    require(manager.contractName() == keccak256("TweedentityManager"));
  }

}