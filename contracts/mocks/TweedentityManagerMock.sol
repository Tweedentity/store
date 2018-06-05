pragma solidity ^0.4.18;


import '../TweedentityManager.sol';


contract TweedentityManagerMock is TweedentityManager {

  function isSettable(uint _id, string _nickname)
  external
  constant
  returns (bool)
  {
    return true;
  }

}
