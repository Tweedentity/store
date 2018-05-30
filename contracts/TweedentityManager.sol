pragma solidity ^0.4.18;


import '../ethereum-api/oraclizeAPI.sol';
import 'zeppelin-solidity/contracts/ownership/Ownable.sol';

import './TweedentityStore.sol';


contract TweedentityManager is usingOraclize, Ownable {

  event StartVerification(address addr, string uid);
  event OwnershipConfirmed(address addr, string uid);
  event VerificatioFailed(address addr);

  uint public version = 1;

  TweedentityStore public store;
  bool public storeSet;

  mapping(bytes32 => address) internal __tempData;

  modifier isStoreSet() {
    require(storeSet);
    _;
  }

  function setStore(address _address) onlyOwner public {
    require(!storeSet);
    require(_address != 0x0);
    store = TweedentityStore(_address);
    require(store.authorized(this) == store.managerLevel());
    storeSet = true;
  }

  // Verifies that the signature published on twitter is correct
  function verifyTwitterAccountOwnership(string _id, uint _gasPrice, uint _gasLimit) public isStoreSet payable {
    require(bytes(_id).length >= 18);
    require(msg.value == _gasPrice * _gasLimit);

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

    store.setIdentity(sender, _result);
    if (store.isAddressSet(sender)) {
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