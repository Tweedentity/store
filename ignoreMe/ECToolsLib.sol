pragma solidity ^0.4.18;


library ECTools {

  // @dev Hashes the signed message
  function toEthereumSignedMessage(string _msg) public constant returns (bytes32) {
    uint len = bytes(_msg).length;
    require(len > 0);
    return keccak256("\x19Ethereum Signed Message:\n", _uintToString(len), _msg);
  }

  // @dev Recovers the address which has signed a message
  // _sig is a full signature, like "0xa78ef6a2...", 134-chars long
  function recoverSigner(bytes32 _hashedMsg, string _sig) public constant returns (address){
    bytes memory sig = _hexstrToBytes(_substring(_sig, 2, 132));
    return recover(_hashedMsg, sig);
  }

  // @dev Verifies if the message is signed by an address
  function isSignedBy(bytes32 _hashedMsg, string _sig, address _addr) public constant returns (bool){
    require(_addr != 0x0);

    return _addr == recoverSigner(_hashedMsg, _sig);
  }

  // @dev Recovers the address which has signed a message
  // @thanks https://gist.github.com/axic/5b33912c6f61ae6fd96d6c4a47afde6d
  function recover(bytes32 _hashedMsg, bytes _sig) private pure returns (address){

    require(_hashedMsg != 0x00);
    require(_sig.length == 65);

    bytes32 r;
    bytes32 s;
    uint8 v;
    assembly {
      r := mload(add(_sig, 32))
      s := mload(add(_sig, 64))
      v := byte(0, mload(add(_sig, 96)))
    }

    if (v < 27) {
      v += 27;
    }
    if (v < 27 || v > 28) {
      return address(0);
    }
    return ecrecover(_hashedMsg, v, r, s);
  }

  // @dev Converts a uint to a bytes32
  // @thanks https://ethereum.stackexchange.com/questions/4170/how-to-convert-a-uint-to-bytes-in-solidity
  function _uintToBytes32(uint _uint) internal pure returns (bytes b) {
    b = new bytes(32);
    assembly {mstore(add(b, 32), _uint)}
  }

  // @dev Converts an hexstring to bytes
  function _hexstrToBytes(string _hexstr) internal pure returns (bytes) {
    uint len = bytes(_hexstr).length;
    require(len % 2 == 0);

    bytes memory bstr = bytes(new string(len / 2));
    uint k = 0;
    string memory s;
    string memory r;
    for (uint i = 0; i < len; i += 2) {
      s = _substring(_hexstr, i, i + 1);
      r = _substring(_hexstr, i + 1, i + 2);
      uint p = _parseInt16Char(s) * 16 + _parseInt16Char(r);
      bstr[k++] = _uintToBytes32(p)[31];
    }
    return bstr;
  }

  // @dev Parses a hexchar, like 'a', and returns its hex value, in this case 10
  function _parseInt16Char(string _char) internal pure returns (uint) {
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

  // @dev Converts a uint in a string
  function _uintToString(uint _uint) internal pure returns (string) {
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
    return string(b);
  }

  // @dev extract a _substring
  // @thanks https://ethereum.stackexchange.com/questions/31457/_substring-in-solidity
  function _substring(string _str, uint _startIndex, uint _endIndex) internal pure returns (string) {
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

