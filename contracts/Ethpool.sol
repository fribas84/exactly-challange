// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;


/**despite safemath is not needed since 0.8.x I consider is a good practice */
import "../node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol"; 
import "../node_modules/@openzeppelin/contracts/access/AccessControlEnumerable.sol";  

contract Ethpool is AccessControl  {
  using SafeMath for uint256;

  bytes32 public constant MINTER_ROLE = keccak256("TEAM_ROLE");

  mapping(address => uint) public balances;
  mapping(address=>uint) public shares;
  address[] beneficiaryList;
  
  uint contractBalance;

  constructor() public {

    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }


  function deposit() payable external{
    if (hasRole(keccak256("TEAM_ROLE"),msg.sender)) {
      _teamDeposit(msg.value);
    }
    else {
      _userDeposit(msg.sender, msg.value);
    }
  }

  function _userDeposit(address user, uint value) internal {

   // beneficiaryList[user] = True; // mal, validar si user es beneficiario previamente, 
    
    
    balances[user] = balances[user].add(value);
    contractBalance = contractBalance.add(value); 
    shares[user] = balances[user].div(contractBalance);
    shares[user] = balances[user].mul(100);


  }

  function _teamDeposit(uint value) internal {
    uint i;
    uint balance;
    contractBalance = contractBalance.add(value);
    for (i = 0; i < beneficiaryList.length;i++){
      balance = balances[beneficiaryList[i]];
    }

  }


  //function withdraw();

  function grantTeamRole(address member) public {
    //a Team member cannot contain balance in the EthPool
    require(balances[member]==0,"This address contains funds in Balance.");
    grantRole(keccak256("TEAM_ROLE"),member);      
  }


}
