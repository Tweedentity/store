pragma solidity ^0.4.18;


import '../TweedentityManager.sol';


contract TweedentityManagerMock is TweedentityManager {

  uint public counter;

  function incCounter() public {
    // we use this to mine a new block during tests
    counter++;
  }

}