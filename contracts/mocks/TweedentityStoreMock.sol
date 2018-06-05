pragma solidity ^0.4.18;


import '../TweedentityStore.sol';


contract TweedentityStoreMock is TweedentityStore {

  function setApp(string _name, string _domain, string _nickname, uint _id)
  external
  onlyOwner
  {
    require(_id > 0);
    require(!appSet);
//    we are executing the store not from a contract
//    require(manager.isSettable(_id, _nickname));
    app = App(_name, _domain, _nickname, _id);
    appSet = true;
  }

}
