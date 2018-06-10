pragma solidity ^0.4.18;

import 'openzeppelin-solidity/contracts/lifecycle/Pausable.sol';



/**
 * @title TweedentityRegistry
 * @author Francesco Sullo <francesco@sullo.co>
 * @dev It store the tweedentities contracts addresses to allows dapp to be updated
 */


contract TweedentityRegistry  /** 1.0.0 */
is Pausable
{

  function TweedentityRegistry()
  public
  {
    paused = true;
  }

  uint public totalStores;
  mapping (bytes32 => address) public stores;
  address public manager;
  address public claimer;


  function setManager(
    address _address
  )
  external
  onlyOwner
  {
    require(_address != 0x0);
    manager = _address;
  }


  function setClaimer(
    address _address
  )
  external
  onlyOwner
  {
    require(_address != 0x0);
    claimer = _address;
  }


  function setManagerAndClaimer(
    address _manager,
    address _claimer
  )
  external
  onlyOwner
  {
    require(_manager != 0x0);
    require(_claimer != 0x0);
    manager = _manager;
    claimer = _claimer;
  }


  function setStore(
    string _appNickname,
    address _address
  )
  external
  onlyOwner
  {
    require(_address != 0x0);
    if (getStore(_appNickname) == address(0)) {
      totalStores++;
    }
    stores[keccak256(_appNickname)] = _address;
  }


  /**
   * @dev Gets the store managing the specified app
   * @param _appNickname The nickname of the app
   */
  function getStore(
    string _appNickname
  )
  public
  constant returns(address)
  {
    return stores[keccak256(_appNickname)];
  }


  /**
   * @dev Returns true if the registry looks ready
   */
  function isReady()
  external
  constant returns(bool)
  {
    return totalStores > 0 && manager != address(0) && claimer != address(0) && !paused;
  }


}
