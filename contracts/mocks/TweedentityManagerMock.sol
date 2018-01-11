pragma solidity ^0.4.18;

import '../TweedentityManager.sol';

contract TweedentityManagerMock is TweedentityManager {

  function __callback(bytes32 _oraclizeID, string _result) public {
    require(msg.sender == oraclize_cbAddress());
    result = _result;
  }

}