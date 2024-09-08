/*
   *******************************************************
   *                                                     *
   *             ACS Contract Audit Program              *
   *   _______________________________________________   *
   *                                                     *
   *   A structured path for auditors and bug bounty      *
   *   hunters to learn by finding and reporting          *
   *   vulnerabilities in smart contracts.                *
   *                                                     *
   *   Level: Beginner                                    *
   *   Special thanks: Aniket Tyagi                       *
   *                                                     *
   *******************************************************
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

contract Zerovault {


    uint256 public totalCollateral;
    uint256 public tokenPrice = 1 ether;
    uint256 public collateralizationRatio = 150;
    string private ownerkey;
    mapping(address => uint256) public collateralBalances;
    mapping(address => uint256) public tokenBalances;
    mapping(address => mapping(address => uint256)) public allowances;
    address public owner;

    event onlyOwnercallthefunction();

    constructor(address _owner) {
        owner = _owner;
    }

    modifier onlyOwner { 
        owner == msg.sender;
        _;
    }

    function mint() public  payable {

        require(msg.sender != owner, "Only Owner Call this function");
        require(msg.value > 0, "No collateral provided");
        uint256 tokensToMint = msg.value * 100 / collateralizationRatio / tokenPrice;
        collateralBalances[msg.sender] += msg.value;
        tokenBalances[msg.sender] += tokensToMint;
        totalCollateral += msg.value;
    }

    function burn(uint256 amount) external {
        
        require(tokenBalances[msg.sender] >= amount, "Not enough tokens");

        uint256 collateralToReturn = amount * collateralizationRatio * tokenPrice / 100;
        payable(msg.sender).transfer(collateralToReturn);

        tokenBalances[msg.sender] -= amount;
        collateralBalances[msg.sender] -= collateralToReturn;
      
        totalCollateral -= collateralToReturn;
    }

    function changeCollateralizationRatio(uint256 newRatio) public {

        if (msg.sender != owner) { 
            emit onlyOwnercallthefunction();
        } else {
            collateralizationRatio = newRatio;
        }
    }

  
    function liquidate(address user) public  {

        uint256 userCollateral = collateralBalances[user];
        uint256 userTokens = tokenBalances[user];


        uint256 requiredCollateral = userTokens * collateralizationRatio * tokenPrice / 100;
        require(userCollateral < requiredCollateral, "Position is sufficiently collateralized");


        payable(msg.sender).transfer(userCollateral);
        collateralBalances[user] = 0;
        tokenBalances[user] = 0;

        totalCollateral -= userCollateral;
    }


    function approve(address spender, uint256 amount) public {

        allowances[msg.sender][spender] = amount;
    }

    function transferFrom(address from, address to, uint256 amount) external {
        
        require(tokenBalances[from] >= amount, "Insufficient token balance");
        require(allowances[from][msg.sender] >= amount, "Allowance exceeded");


        tokenBalances[from] -= amount;
        tokenBalances[to] += amount;

        allowances[from][msg.sender] -= amount;
    }


    function emergencyWithdraw(address _owner) external  {
        require(msg.sender != owner, "Only owner can withdraw");


        payable(_owner).transfer(address(this).balance);
    }

    function settokenprice(uint256 m_price) public onlyOwner{

        tokenPrice = m_price;
    }

    function setownerkey(string memory _data) public {

        require(msg.sender == owner, "Only Owner Call this function");
        ownerkey = _data;
    }

    function getOnwerKey() public view returns(string memory) {
        require(msg.sender == owner, "Only Owner Call this function");
        return ownerkey;
    }   

    receive() external payable {
        totalCollateral += msg.value;
    }
}
