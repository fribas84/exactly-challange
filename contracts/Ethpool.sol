// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;


/**despite safemath is not needed since 0.8.x I consider it's a good practice */
import "../node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol"; 
import "../node_modules/@openzeppelin/contracts/access/AccessControlEnumerable.sol";  

contract Ethpool is AccessControl  {
  using SafeMath for uint256;

  bytes32 public constant TEAM_ROLE = keccak256("TEAM_ROLE");

  //Balances
  mapping(address => uint) public balances;
  uint contractBalance;
  //Users accumulatedRewards, they can cam
  mapping(address=>uint) public accumulatedRewards;
  uint rewardsToDiburse;

  // To make the beneficiary iterable and be able to add or remove them.
  address[] beneficiaryList;
  
  struct BeneficiaryStruct{
    uint lastDeposit;
    uint listPointer;
  }
  mapping (address => BeneficiaryStruct) beneficiaryStructs;

  uint public lastRewardBlock; 

  constructor() public {

    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    grantTeamRole(msg.sender);
  }


  function _rewardPerBlock(uint _reward) internal returns (uint){
      
      uint rewardBlockLenght = block.number - lastRewardBlock;
      return _reward.div(rewardBlockLenght);


  }
  function deposit() payable external{
    if (hasRole(keccak256("TEAM_ROLE"),msg.sender)) {
      _teamDeposit(msg.value);
    }
    else {
      _userDeposit(msg.sender, msg.value);
    }
  }

    /*  @notice Performs  beneficiary deposits.
        @dev If this is a new user, it will be added to the list and struct mapping, so it can be iterable to diburse rewards
        @param _user The account address.
        @param _value Deposit Value.
    */
  function _userDeposit(address _user,uint _value)
    internal {
      if(!_isEntity(_user)) {
        beneficiaryList.push(_user);
        beneficiaryStructs[_user].listPointer= beneficiaryList.length - 1;
      }
      balances[_user] = balances[_user].add(_value);
      contractBalance = contractBalance.add(_value);
      beneficiaryStructs[_user].lastDeposit = block.number; 
    }

  function getBalance(address user)
    external view returns(uint){
      return balances[user];
    }

  function _teamDeposit(uint _rwd)
    internal {
      contractBalance = contractBalance.add(_rwd);
      rewardsToDiburse = _rwd;
      _diburseRewards(_rwd);
      lastRewardBlock = block.number;
      contractBalance = contractBalance.add(_rwd);

    }

  function _diburseRewards(uint _rwd) 
  internal {

    uint rwdPerBlock =  _rewardPerBlock(_rwd);
    for (uint256 i = 0; i < beneficiaryList.length; i++) {
      if(balances[beneficiaryList[i]]>0){
        accumulatedRewards[beneficiaryList[i]] =
        (accumulatedRewards[beneficiaryList[i]].add(balances[beneficiaryList[i]])).mul(rwdPerBlock); 
        }   
      }
  }

  function withdraw(uint _amount)
    external {
      require(balances[msg.sender]>= _amount, "Insufficient balance.");
      balances[msg.sender] = balances[msg.sender].sub(_amount);
      payable(msg.sender).transfer(_amount);
      if(balances[msg.sender]==0){
        _deleteEntity(msg.sender);
      }
  }

  function claimRewards(uint _amount)
    external {
      require(accumulatedRewards[msg.sender]>0,"Insufficient rewards to claim.");
      accumulatedRewards[msg.sender] = accumulatedRewards[msg.sender].sub(_amount);
      payable(msg.sender).transfer(_amount);
  }

  /*  @notice Grant team role to an specific account. 
      @param _member Address of the account to add a team role.
  */
  function grantTeamRole(address _member)
    public {
      require(balances[_member]==0,"This address contains funds in Balance.");
      grantRole(keccak256("TEAM_ROLE"),_member);      
  }

  function getContractBalance() external view returns (uint){
    return contractBalance;
  }

  function getAccumlatedRewards() external view returns(uint) {
    return accumulatedRewards[msg.sender];
  } 

  /*  @notice Checks if the account address is in the beneficiaryList, by checking the mapping
      @param _address Address of the account
      @return If the account is a beneficiary or not as Boolean
  */
  function _isEntity(address _address)
    internal view returns(bool isIndeed) {
      if(beneficiaryList.length == 0) return false;
      return (beneficiaryList[beneficiaryStructs[_address].listPointer] == _address);
  }

  /*  @notice delete beneficiary entity from list and resets the related struct.
      @dev It swaps the row to delete with the latest of the array and just do a pop.
      @param _address Address of the account to delete.
  */  
  function _deleteEntity(address _address)
    internal {
      if(!_isEntity(_address)) revert();
      uint rowToDelete = beneficiaryStructs[_address].listPointer; 
      address keyToMove   = beneficiaryList[beneficiaryList.length-1];
      beneficiaryList[rowToDelete] = keyToMove;
      beneficiaryStructs[keyToMove].listPointer = rowToDelete;
      beneficiaryList.pop();
      delete beneficiaryStructs[_address];
  }
}
