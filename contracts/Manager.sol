pragma solidity ^0.4.18;


import 'oraclize/usingOraclize.sol';
import 'zeppelin/ownership/Ownable.sol';

import './Store.sol';


contract Manager is usingOraclize, Ownable {

  event ownershipConfirmation(address addr, string screenName, bool success);

  uint public version = 1;

  string public result;

  Store public store;
  bool public storeSet;

  struct TempData {
    string screenName;
    address sender;
  }

  mapping(bytes32 => TempData) internal _tempData;

  modifier isStoreSet() {
    require(storeSet);
    _;
  }

  function setStore(address _address) onlyOwner public {
    require(_address != 0x0);
    store = Store(_address);
    require(store.authorized(address(this)) > 0);
    storeSet = true;
  }

  // Verifies that the signature published on twitter is correct
  function verifyAccountOwnership(string _screenName, string _id, uint _gasPrice) public isStoreSet payable {
    require(bytes(_screenName).length > 0 && bytes(_screenName).length <= 15);
    require(bytes(_id).length >= 18);

    oraclize_setCustomGasPrice(_gasPrice);

    bytes32 oraclizeID = oraclize_query("URL", strConcat(
        "https://api.tweedentity.com/",
        strConcat(_screenName, "/", _id, "/0x", addressToString(msg.sender))
      ), 160000);
    _tempData[oraclizeID] = TempData(_screenName, msg.sender);
  }

  function __callback(bytes32 _oraclizeID, string _result) public {
    require(msg.sender == oraclize_cbAddress());

    string memory screenName = _tempData[_oraclizeID].screenName;
    address sender = _tempData[_oraclizeID].sender;

    if (isUid(_result)) {
      store.setIdentity(sender, screenName, _result);
      ownershipConfirmation(sender, screenName, true);
    } else {
      ownershipConfirmation(sender, screenName, false);
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

  function isUid(string _uid) internal pure returns (bool) {
    bytes memory uid = bytes(_uid);
    for (uint i = 0; i < uid.length; i++) {
      if (uid[i] < 48 || uid[i] > 57) {
        return false;
      }
    }
    return true;
  }

}