pragma solidity ^0.4.18;


import '../Store.sol';


contract StoreMock is Store {

  function getNowPlus(string _uid) public constant returns (uint[3]) {
    return [now, __addressByUid[_uid].lastUpdate, __addressByUid[_uid].lastUpdate + minimumTimeBeforeUpdate];
  }

  uint public counter;

  function incCounter() public {
    // we use this to mine a new block during tests
    counter++;
  }

}