//SPDX-License-Identifier:UNLICENSE
pragma solidity ^0.8.17;


contract FlexibleStaking{
    //Variable and other Declarations
    address public PAW;
    uint256 public TotalDeposits;
    uint256 public RewardMultiplier;
    address public Operator;

    //Add Total Staked (for projections)

    mapping(address => uint256) public Deposits;
    mapping(address => uint256) public LastUpdateUnix;

    //Events
    event Deposited(uint256 NewBalance, address user);
    event Withdrawn(uint256 NewBalance, address user);
    event Claimed(uint256 Amount, address user);
    event ReInvested(uint256 NewBalance, address user);


    constructor(address _PAW, uint256 APY){ /
        PAW = _PAW;
        RewardMultiplier = APY * 792744;
        Operator = msg.sender;
    }


    //Public Functions
    function Deposit(uint256 amount) public returns(bool success){  
        require(amount >= 1000000000000000000, "The minimum deposit for staking is 1 PAW");
        require(ERC20(PAW).balanceOf(msg.sender) >= amount, "You do not have enough PAW to stake this amount");
        require(ERC20(PAW).allowance(msg.sender, address(this)) >= amount, "You have not given the staking contract enough allowance");

        if(Deposits[msg.sender] > 0){
            ReInvest();
        }

        Update(msg.sender);
        ERC20(PAW).transferFrom(msg.sender, address(this), amount);
        TotalDeposits = TotalDeposits + amount;
        Deposits[msg.sender] = (Deposits[msg.sender] + amount);

        emit Deposited(Deposits[msg.sender], msg.sender);
        return(success);
    }

    function Withdraw(uint256 amount) public returns(bool success){
        require(Deposits[msg.sender] >= amount);
        
        if((ERC20(PAW).balanceOf(address(this)) - (GetUnclaimed(msg.sender))) >= TotalDeposits){
            Claim();
        }

        Deposits[msg.sender] = Deposits[msg.sender] - amount;
        TotalDeposits = TotalDeposits - amount;
        ERC20(PAW).transfer(msg.sender, amount);
        
        emit Withdrawn(Deposits[msg.sender], msg.sender);
        return(success);
    }

    function ReInvest() public returns(bool success){
        require(GetUnclaimed(msg.sender) > 0);
        
        uint256 Unclaimed = GetUnclaimed(msg.sender);
        require((ERC20(PAW).balanceOf(address(this)) - Unclaimed) >= TotalDeposits, "The contract does not have enough PAW to pay profits at the moment"); //This exists as protection in the case that the contract has not been refilled with PAW in time
        Update(msg.sender);

        Deposits[msg.sender] = Deposits[msg.sender] + Unclaimed;
        TotalDeposits = TotalDeposits + Unclaimed;
        
        emit ReInvested(Deposits[msg.sender], msg.sender);
        return(success);
    }


    function Claim() public returns(bool success){
        uint256 Unclaimed = GetUnclaimed(msg.sender);
        require(Unclaimed > 0);

        require((ERC20(PAW).balanceOf(address(this)) - Unclaimed) >= TotalDeposits, "The contract does not have enough PAW to pay profits at the moment"); //This exists as protection in the case that the contract has not been refilled with PAW in time
        Update(msg.sender);

        ERC20(PAW).transfer(msg.sender, Unclaimed);
        
        emit Claimed(Unclaimed, msg.sender);
        return(success);
    }

    //OwnerOnly Functions

    function ChangeMultiplier(uint256 NewMultiplier) public returns(bool success){
        require(msg.sender == Operator);

        RewardMultiplier = NewMultiplier;

        return(success);
    }

    //Internal Functions
    function Update(address user) internal{
        LastUpdateUnix[user] = block.timestamp;
    }


    //Functional view functions

    function GetUnclaimed(address user) public view returns(uint256){
        uint256 Time = (block.timestamp - LastUpdateUnix[user]);
        uint256 Unclaimed;

        Unclaimed = (((RewardMultiplier * Time) * Deposits[user]) / 1000000000000000); //7927448 per %

        return(Unclaimed);
    }

    //Informatical view functions
}

interface ERC20 {
  function balanceOf(address owner) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function approve(address spender, uint value) external returns (bool);
  function Mint(address _MintTo, uint256 _MintAmount) external;
  function transfer(address to, uint value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool); 
  function totalSupply() external view returns (uint);
}    