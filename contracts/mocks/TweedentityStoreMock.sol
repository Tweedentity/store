pragma solidity ^0.4.18;

import '../TweedentityStore.sol';

contract TweedentityStoreMock is TweedentityStore {


  function changeMinimumTimeRequiredBeforeUpdate(uint _newMinimumTime) onlyAuthorized public {
    require(_newMinimumTime >= 0 && _newMinimumTime <= 1 weeks);

    minimumTimeRequiredBeforeUpdate = _newMinimumTime;

    minimumTimeRequiredBeforeUpdateChanged(_newMinimumTime);
  }

}