pragma solidity ^0.4.18;


import './ECToolsLib.sol';

contract ECToolsMock {

  using ECToolsLib for *;

  function toEthereumSignedMessage(string _msg) public constant returns (bytes32) {
    return _msg.toEthereumSignedMessage();
  }

  function recoverSigner(bytes32 _hashedMsg, string _sig) public constant returns (address){
    return _hashedMsg.recoverSigner(_sig);
  }

  function isSignedBy(bytes32 _hashedMsg, string _sig, address _addr) public constant returns (bool){
    return _hashedMsg.isSignedBy(_sig, _addr);
  }

}

