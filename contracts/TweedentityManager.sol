pragma solidity ^0.4.18;


import 'oraclize/usingOraclize.sol';
import 'zeppelin/ownership/Ownable.sol';

import './ECTools.sol';
import './TweedentityStore.sol';


contract TweedentityManager is usingOraclize, Ownable, ECTools {

//  event newOraclizeQuery(string description);

  uint public version = 1;

  string public result;
  //  bytes32 public oraclizeID;

  string internal xPath = "//p[contains(@class,'tweet-text')]/text()";

  TweedentityStore public store;

  mapping(bytes32 => string) internal _screeNamesByOraclizeId;
  mapping(bytes32 => address) internal _msgSendersByOraclizeId;

  // Sets a new store (only in version 1)
  function TweedentityManager() public {
    store = new TweedentityStore();
    store.authorize(this);
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
  function verifyAccountOwnership(string _screenName, string _id) public payable {
    require(bytes(_screenName).length > 0);
    require(bytes(_id).length > 0);

    bytes32 oraclizeID = oraclize_query("URL", strConcat(
        "html(",
        strConcat("https://twitter.com/", _screenName, "/status/", _id),
        ").xpath(", xPath, ")"
      ), 2000000);
    _screeNamesByOraclizeId[oraclizeID] = _screenName;
    _msgSendersByOraclizeId[oraclizeID] = msg.sender;
    uu = msg.gas;
  }

  string public ss;
  bytes32 public bb;
  uint public uu;
  uint public uu2;
  address public uu3;
  address public uu4;

  function __callback(bytes32 _oraclizeID, string _result) public {
    require(msg.sender == oraclize_cbAddress());
    require(bytes(_result).length == 132);

    string memory screenName = _screeNamesByOraclizeId[_oraclizeID];
    address msgSender = _msgSendersByOraclizeId[_oraclizeID];
//
    result = _result;
    bytes32 hashedScreenName = toEthereumSignedMessage(strConcat(screenName, "@tweedentity"));

    bb = hashedScreenName;
    address signer = recoverSigner(hashedScreenName, _result);
    if (signer == msgSender) {
      ss = 'Ok';
      store.addTweedentity(msgSender, screenName);
    }
    uu3 = signer;
    uu4 = msgSender;
  }

  function checkCheck() public constant returns (bytes32) {
    return 0x01;
  }


}