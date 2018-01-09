pragma solidity ^0.4.18;


import 'oraclize/usingOraclize.sol';
import 'zeppelin/ownership/Ownable.sol';

import './ECTools.sol';
import './TweedentityStore.sol';


contract TweedentityManager is usingOraclize, Ownable {

  event newOraclizeQuery(string description);

  uint public version = 1;

  string public result;
  //  bytes32 public oraclizeID;

  string internal xPath = "//p[contains(@class,'tweet-text')]/text()";

  TweedentityStore public store;

  mapping(bytes32 => string) internal _screeNamesByOraclizeId;

  // Sets a new store (only in version 1)
  function TweedentityManager() public {
    store = new TweedentityStore();
//    oraclize_getPrice("URL", 1000000);
  }

  // When a new version of the manager is deployed,
  // it allows the new version to manage the existent store.
  function changeStoreOwnership(address _newOwner) onlyOwner public {
    store.transferOwnership(_newOwner);
  }

  // Allow to set an existent store instead of a new one.
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
  // 0xec37e45e
  function verifyAccountOwnership(string _screenName, string _id) public payable {
    require(bytes(_screenName).length > 0);
    require(bytes(_id).length > 0);

    bytes32 oraclizeID = oraclize_query("URL", strConcat(
        "html(",
        strConcat("https://twitter.com/", _screenName, "/status/", _id),
        ").xpath(", xPath, ")"
      ), 2000000);
    _screeNamesByOraclizeId[oraclizeID] = _screenName;
    uu = msg.gas;
  }

  string public ss;
  bytes32 public bb;
  uint public uu;
  uint public uu2;
  uint public uu3;

  // The callback called by Oraclize
  function __callback(bytes32 _oraclizeID, string _result) public {
    require(msg.sender == oraclize_cbAddress());
    require(bytes(_result).length == 132);

    uu = msg.gas;
    result = _result;
    string memory _msg = strConcat(_screeNamesByOraclizeId[_oraclizeID], "@tweedentity");
    //  bytes32 hashedScreenName = toEthereumSignedMessage(strConcat(_screeNamesByOraclizeId[_oraclizeID], "@tweedentity"));


    uu2 = msg.gas;

//    uint len = bytes(_msg).length;
//    require(len > 0);
//    bb = checkCheck();
//    uu3 = msg.gas;
    //uintToString(len);
    //    hmm = keccak256("\x19Ethereum Signed Message:\n", uintToString(len), _msg);
    //

    //  hmm = toEthereumSignedMessage(_msg);
    //    if (isSignedBy(hashedScreenName, _result, msg.sender)) {

    // store.addTweedentity(msg.sender, _screeNamesByOraclizeId[_oraclizeID]);
    //    }
  }

  function checkCheck() public constant returns (bytes32) {
    return 0x01;
  }


}