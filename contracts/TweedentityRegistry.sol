pragma solidity ^0.4.18;


import 'openzeppelin-solidity/contracts/ownership/HasNoEther.sol';


contract Pausable {

  bool public paused;
}


/**
 * @title TweedentityRegistry
 * @author Francesco Sullo <francesco@sullo.co>
 * @dev It store the tweedentities contracts addresses to allows dapp to be updated
 */


contract TweedentityRegistry
is HasNoEther
{

  string public version = "1.3.0";

  uint public totalStores;
  mapping (bytes32 => address) public stores;

  address public manager;
  address public claimer;

  bytes32 public managerKey = keccak256("manager");
  bytes32 public claimerKey = keccak256("claimer");
  bytes32 public storeKey = keccak256("store");

  event ContractRegistered(
    bytes32 indexed key,
    string spec,
    address addr
  );


  function setManager(
    address _manager
  )
  external
  onlyOwner
  {
    require(_manager != address(0));
    manager = _manager;
    ContractRegistered(managerKey, "", _manager);
  }


  function setClaimer(
    address _claimer
  )
  external
  onlyOwner
  {
    require(_claimer != address(0));
    claimer = _claimer;
    ContractRegistered(claimerKey, "", _claimer);
  }


  function setManagerAndClaimer(
    address _manager,
    address _claimer
  )
  external
  onlyOwner
  {
    require(_manager != address(0));
    require(_claimer != address(0));
    manager = _manager;
    claimer = _claimer;
    ContractRegistered(managerKey, "", _manager);
    ContractRegistered(claimerKey, "", _claimer);
  }


  function setAStore(
    string _appNickname,
    address _store
  )
  external
  onlyOwner
  {
    require(_store != address(0));
    if (getStore(_appNickname) == address(0)) {
      totalStores++;
    }
    stores[keccak256(_appNickname)] = _store;
    ContractRegistered(storeKey, _appNickname, _store);
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
    Pausable pausable = Pausable(manager);
    return totalStores > 0 && manager != address(0) && claimer != address(0) && pausable.paused() == false;
  }

}
