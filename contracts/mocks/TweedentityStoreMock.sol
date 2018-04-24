pragma solidity ^0.4.18;


import '../TweedentityStore.sol';


contract TweedentityStoreMock is TweedentityStore {

  function getNowPlus(string _uid) public constant returns (uint[3]) {
    return [now, __addressByUid[_uid].lastUpdate, __addressByUid[_uid].lastUpdate + minimumTimeBeforeUpdate];
  }

  uint public counter;

  function incCounter() public {
    // we use this to mine a new block during tests
    counter++;
  }

}