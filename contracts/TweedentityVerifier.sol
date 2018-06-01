pragma solidity ^0.4.18;


import '../ethereum-api/oraclizeAPI.sol';
import 'zeppelin-solidity/contracts/ownership/Ownable.sol';

import './TweedentityManager.sol';


contract TweedentityVerifier is usingOraclize, Ownable {

  event StartVerification(address addr);
  event OwnershipConfirmed(address addr, string uid);
  event VerificatioFailed(address addr);

  uint public version = 1;

  TweedentityManager public manager;
  address public managerAddress;

  mapping(bytes32 => address) internal __tempData;

  modifier isManagerSet() {
    require(managerAddress != address(0));
    // this would be better but consumes 33000 gas more
//    require(manager.authorized(address(this)) == manager.verifierLevel());
    _;
  }

  function setManager(address _address) onlyOwner public {
    require(_address != 0x0);
    managerAddress = _address;
    manager = TweedentityManager(_address);
    require(manager.contractName() == keccak256("TweedentityManager"));
  }

  // Verifies that the signature published on twitter is correct
  function verifyTwitterAccountOwnership(string _id, uint _gasPrice, uint _gasLimit) public isManagerSet payable {
    require(bytes(_id).length >= 18);
    require(msg.value == _gasPrice * _gasLimit);

    StartVerification(msg.sender);
    oraclize_setCustomGasPrice(_gasPrice);

    bytes32 oraclizeID = oraclize_query(
      "URL",
      strConcat("https://api.tweedentity.net/tweet/", _id, "/0x", addressToString(msg.sender)),
      _gasLimit
    );
    __tempData[oraclizeID] = msg.sender;
  }

  function __callback(bytes32 _oraclizeID, string _result) public {
    require(msg.sender == oraclize_cbAddress());

    address sender = __tempData[_oraclizeID];

    manager.setIdentity(sender, _result);
    if (manager.isAddressSet(sender)) {
      OwnershipConfirmed(sender, _result);
    } else {
      VerificatioFailed(sender);
    }
  }

  function addressToString(address x) internal pure returns (string) {
    bytes memory s = new bytes(40);
    for (uint i = 0; i < 20; i++) {
      byte b = byte(uint8(uint(x) / (2 ** (8 * (19 - i)))));
      byte hi = byte(uint8(b) / 16);
      byte lo = byte(uint8(b) - 16 * uint8(hi));
      s[2 * i] = char(hi);
      s[2 * i + 1] = char(lo);
    }
    return string(s);
  }

  function char(byte b) internal pure returns (byte c) {
    if (b < 10) return byte(uint8(b) + 0x30);
    else return byte(uint8(b) + 0x57);
  }

}