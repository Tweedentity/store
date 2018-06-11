pragma solidity ^0.4.18;



/**
 * @title TweedentityManagerInterfaceMinimal
 * @author Francesco Sullo <francesco@sullo.co>
 * @dev It store the tweedentities related to the app
 */


interface TweedentityManagerInterfaceMinimal  /** 1.0.0 */
{

  function isSettable(uint _id, string _nickname)
  external
  constant
  returns (bool);

}
