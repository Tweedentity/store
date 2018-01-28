pragma solidity ^0.4.18;


import 'oraclize/usingOraclize.sol';
import 'zeppelin/ownership/Ownable.sol';

import './TweedentityStore.sol';


contract TweedentityManager is usingOraclize, Ownable {

  event newOraclizeQuery(bytes32 oraclizeID, string description);
  event ownershipConfirmation(bytes32 oraclizeID, address addr, string screenName, bool success);

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
  function verifyAccountOwnership(string _screenName, string _id) public payable {
    require(bytes(_screenName).length > 0);
    require(bytes(_id).length > 0);

    bytes32 oraclizeID = oraclize_query("URL", strConcat(
        "https://api.tweedentity.com/",
        strConcat(_screenName, "/", _id, "/", toString(msg.sender))
      ));
    newOraclizeQuery(oraclizeID, 'Asking Oraclize to load the sig from the tweet');
    _tempData[oraclizeID] = TempData(_screenName, msg.sender);
  }


  function __callback(bytes32 _oraclizeID, string _result) public {
    require(msg.sender == oraclize_cbAddress());
    require(bytes(_result).length == 132);

    string memory screenName = _tempData[_oraclizeID].screenName;
    address sender = _tempData[_oraclizeID].sender;

    if (keccak256(_result) == keccak256('true')) {
      store.addTweedentity(sender, screenName);
      ownershipConfirmation(_oraclizeID, sender, screenName, true);
    } else {
      ownershipConfirmation(_oraclizeID, sender, screenName, false);
    }
  }

  function toString(address x) returns (string) {
    bytes memory b = new bytes(20);
    for (uint i = 0; i < 20; i++)
      b[i] = byte(uint8(uint(x) / (2**(8*(19 - i)))));
    return string(b);
  }

}