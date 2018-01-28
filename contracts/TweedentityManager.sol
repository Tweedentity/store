pragma solidity ^0.4.18;


import 'oraclize/usingOraclize.sol';
import 'zeppelin/ownership/Ownable.sol';

import './TweedentityStore.sol';


contract TweedentityManager is usingOraclize, Ownable {

  event ownershipConfirmation(address addr, string screenName, bool success);

  uint public version = 1;

  string public result;
  //  bytes32 public oraclizeID;

  string internal xPath = "//p[contains(@class,'tweet-text')]/text()";

  TweedentityStore public store;

  struct TempData {
    string screenName;
    address sender;
  }

  mapping(bytes32 => TempData) internal _tempData;

  // Sets a new store (only version 1)
  function TweedentityManager() public {
    store = new TweedentityStore();
    store.authorize(this, 9);
  }

  // When a new version of the manager is deployed,
  // it allows the new version to manage the existent store.
  function changeStoreOwnership(address _newOwner) onlyOwner public {
    store.authorize(_newOwner, 9);
    store.transferOwnership(_newOwner);
    store.deAuthorize();
  }

  // Sets an existent store instead of a new one (only versions 2+)
  function useExistentStore(address _address) onlyOwner public {
    require(_address != 0x0);
    store = TweedentityStore(_address);
  }

  // Updates xPath in case Twitter changes something
  function updateXpath(string _xPath) public onlyOwner {
    require(bytes(_xPath).length > 0);
    xPath = _xPath;
  }

  // Verifies that the signature published on twitter is correct
  function verifyAccountOwnership(string _screenName, string _id, uint _gasPrice) public payable {
    require(bytes(_screenName).length > 0);
    require(bytes(_id).length > 0);

    oraclize_setCustomGasPrice(_gasPrice);

    bytes32 oraclizeID = oraclize_query("URL", strConcat(
        "json(https://api.tweedentity.com/",
        strConcat(_screenName, "/", _id, "/0x", addressToString(msg.sender)),
        ").success"
      ), 160000);
    _tempData[oraclizeID] = TempData(_screenName, msg.sender);
  }

  function __callback(bytes32 _oraclizeID, string _result) public {
    require(msg.sender == oraclize_cbAddress());

    string memory screenName = _tempData[_oraclizeID].screenName;
    address sender = _tempData[_oraclizeID].sender;

    if (keccak256(_result) == keccak256('true')) {
      store.addTweedentity(sender, screenName);
      ownershipConfirmation(sender, screenName, true);
    } else {
      ownershipConfirmation(sender, screenName, false);
    }
  }

  function addressToString(address x) public pure returns (string) {
    bytes memory s = new bytes(40);
    for (uint i = 0; i < 20; i++) {
      byte b = byte(uint8(uint(x) / (2**(8*(19 - i)))));
      byte hi = byte(uint8(b) / 16);
      byte lo = byte(uint8(b) - 16 * uint8(hi));
      s[2*i] = char(hi);
      s[2*i+1] = char(lo);
    }
    return string(s);
  }

  function char(byte b) internal pure returns (byte c) {
    if (b < 10) return byte(uint8(b) + 0x30);
    else return byte(uint8(b) + 0x57);
  }

}