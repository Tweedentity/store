pragma solidity ^0.4.18;


contract ECTools {

  // @dev Hashes a message to be verified
  function toEthereumSignedMessage(string _msg) public constant returns (bytes32) {
    uint len = bytes(_msg).length;
    require(len > 0);
    bytes memory prefix = "\x19Ethereum Signed Message:\n";
    return keccak256(prefix, uintToString(len), _msg);
  }

  // @dev Recovers the address which has signed a message
  // @thanks https://gist.github.com/axic/5b33912c6f61ae6fd96d6c4a47afde6d
  // @param _hashedMsg is an hashed prefixed message
  // @param _sig is a full, 132-chars long sig
  function recoverSigner(bytes32 _hashedMsg, string _sig) public constant returns (address){
    require(bytes(_sig).length == 132);

    bytes32 r;
    bytes32 s;
    uint8 v;
    bytes memory sig = hexstrToBytes(substring(_sig, 2, 132));
    assembly {
      r := mload(add(sig, 32))
      s := mload(add(sig, 64))
      v := byte(0, mload(add(sig, 96)))
    }
    if (v < 27) {
      v += 27;
    }
    if (v < 27 || v > 28) {
      return address(0);
    }
    return ecrecover(_hashedMsg, v, r, s);
  }

  // @dev Verifies if the message is signed by an address
  function isSignedBy(bytes32 _hashedMsg, string _sig, address _addr) public constant returns (bool){

    return _addr == recoverSigner(_hashedMsg, _sig);
  }

  // @dev Converts an hexstring to bytes
  function hexstrToBytes(string _hexstr) public constant returns (bytes) {
    uint len = bytes(_hexstr).length;
    require(len % 2 == 0);

    bytes memory bstr = bytes(new string(len / 2));
    uint k = 0;
    string memory s;
    string memory r;
    for (uint i = 0; i < len; i += 2) {
      s = substring(_hexstr, i, i + 1);
      r = substring(_hexstr, i + 1, i + 2);
      uint p = parseInt16Char(s) * 16 + parseInt16Char(r);
      bstr[k++] = uintToBytes32(p)[31];
    }
    return bstr;
  }

  // @dev Parses a hexchar, like 'a', and returns its hex value, in this case 10
  function parseInt16Char(string _char) public constant returns (uint) {
    bytes memory bresult = bytes(_char);
    bool decimals = false;
    if ((bresult[0] >= 48) && (bresult[0] <= 57)) {
      return uint(bresult[0]) - 48;
    } else if ((bresult[0] >= 65) && (bresult[0] <= 70)) {
      return uint(bresult[0]) - 55;
    } else if ((bresult[0] >= 97) && (bresult[0] <= 102)) {
      return uint(bresult[0]) - 87;
    } else {
      revert();
    }
  }

  // @dev Converts a uint to a bytes32
  // @thanks https://ethereum.stackexchange.com/questions/4170/how-to-convert-a-uint-to-bytes-in-solidity
  function uintToBytes32(uint _uint) public constant returns (bytes b) {
    b = new bytes(32);
    assembly {mstore(add(b, 32), _uint)}
  }

  // @dev Converts a uint in a string
  function uintToString(uint _uint) public constant returns (string str) {
    uint len = 0;
    uint m = _uint + 0;
    while (m != 0) {
      len++;
      m /= 10;
    }
    bytes memory b = new bytes(len);
    uint i = len - 1;
    while (_uint != 0) {
      uint remainder = _uint % 10;
      _uint = _uint / 10;
      b[i--] = byte(48 + remainder);
    }
    str = string(b);
  }


  // @dev extract a substring
  // @thanks https://ethereum.stackexchange.com/questions/31457/substring-in-solidity
  function substring(string _str, uint _startIndex, uint _endIndex) public constant returns (string) {
    bytes memory strBytes = bytes(_str);
    require(_startIndex <= _endIndex);
    require(_startIndex >= 0);
    require(_endIndex <= strBytes.length);

    bytes memory result = new bytes(_endIndex - _startIndex);
    for (uint i = _startIndex; i < _endIndex; i++) {
      result[i - _startIndex] = strBytes[i];
    }
    return string(result);
  }

}