pragma solidity ^0.4.18;

import '../TweedentityManager.sol';

contract TweedentityManagerMock is TweedentityManager {

  string public result;
  string public url;
  bytes32 public oraclizeID;

  event log(string s);

  uint public remainingGas;

//  function verifyAccountOwnership(string _screenName, string _id, uint _gasPrice) public payable {
//    super.verifyAccountOwnership(_screenName, _id, _gasPrice);
//
////    remainingGas = msg.gas;
//  }

//  function __callback(bytes32 _oraclizeID, string _result) public {
//    super.__callback(_oraclizeID, _result);
//    remainingGas = msg.gas;
//  }


}