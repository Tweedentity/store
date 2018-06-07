pragma solidity ^0.4.18;


import '../ethereum-api/oraclizeAPI.sol';
import 'openzeppelin-solidity/contracts/ownership/Ownable.sol';

import './TweedentityManager.sol';


contract TweedentityClaimer is usingOraclize, Ownable {

  uint public version = 1;

  event VerificationStarted(
    bytes32 oraclizeId,
    address addr,
    string appNickname,
    string postId
  );

  event VerificatioFailed(
    bytes32 oraclizeId
  );

  string public apiUrl = "https://api.tweedentity.net/";

  TweedentityManager public manager;
  address public managerAddress;

  struct TempData {
    address sender;
    uint appId;
  }

  mapping(bytes32 => TempData) internal __tempData;

  modifier isManagerSet() {
    require(managerAddress != address(0));
    // this would be better but consumes 33000 gas more
    //    require(manager.authorized(address(this)) == manager.verifierLevel());
    _;
  }

  function setManager(
    address _address
  )
  public
  onlyOwner
  {
    require(_address != 0x0);
    managerAddress = _address;
    manager = TweedentityManager(_address);
  }

  // Verifies that the signature published on twitter is correct
  function claimOwnership(
    string _appNickname,
    string _pathname,
    uint _gasPrice,
    uint _gasLimit
  )
  public
  isManagerSet
  payable
  {
    require(bytes(_pathname).length > 0);
    require(msg.value == _gasPrice * _gasLimit);

    oraclize_setCustomGasPrice(_gasPrice);

    string[6] memory str;
    str[0] = apiUrl;
    str[1] = _appNickname;
    str[2] = "/";
    str[3] = _pathname;
    str[4] = "/0x";
    str[5] = __addressToString(msg.sender);

    bytes32 oraclizeID = oraclize_query(
      "URL",
      __concat(str),
      _gasLimit
    );
    VerificationStarted(oraclizeID, msg.sender, _appNickname, _pathname);
    __tempData[oraclizeID] = TempData(msg.sender, manager.getAppId(_appNickname));
  }



  function __callback(
    bytes32 _oraclizeID,
    string _result
  )
  public
  {
    require(msg.sender == oraclize_cbAddress());
    if (bytes(_result).length > 0) {
      manager.setIdentity(__tempData[_oraclizeID].appId, __tempData[_oraclizeID].sender, _result);
    } else {
      VerificatioFailed(_oraclizeID);
    }
  }

  function __addressToString(
    address _address
  )
  internal
  pure
  returns (string)
  {
    bytes memory s = new bytes(40);
    for (uint i = 0; i < 20; i++) {
      byte b = byte(uint8(uint(_address) / (2 ** (8 * (19 - i)))));
      byte hi = byte(uint8(b) / 16);
      byte lo = byte(uint8(b) - 16 * uint8(hi));
      s[2 * i] = __char(hi);
      s[2 * i + 1] = __char(lo);
    }
    return string(s);
  }

  function __char(
    byte b
  )
  internal
  pure
  returns (byte c)
  {
    if (b < 10) return byte(uint8(b) + 0x30);
    else return byte(uint8(b) + 0x57);
  }

  function __concat(
    string[6] _strings
  )
  internal
  returns (string)
  {
    uint len = 0;
    uint i;
    for (i=0;i<_strings.length;i++) {
      len = len + bytes(_strings[i]).length;
    }
    string memory str = new string(len);
    bytes memory bstr = bytes(str);
    uint k = 0;
    uint j;
    bytes memory b;
    for (i=0;i<_strings.length;i++) {
      b = bytes(_strings[i]);
      for (j = 0; j < b.length; j++) bstr[k++] = b[j];
    }
    return string(bstr);
  }

}
