// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Crowdfunding {
    string public name;
    string public description;
    uint256 public goal;
    uint256 public deadline;
    address public owner;
    bool public paused;

    struct Tier { //捐款等级
        string name;
        uint256 amount;
        uint256 backers; //支持者数量
    }

    Tier[] public tiers;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the Owner");
        _;
    }

    constructor( //录入信息
        string memory _name, //捐款名称
        string memory _description, //捐款描述
        uint256 _goal, //捐款目标
        uint256 _duratyionInDays //截止天数
    ) {
        name = _name;
        description = _description;
        goal = _goal;
        deadline = block.timestamp + (_duratyionInDays * 1 days);
        owner = msg.sender;
    }

    function fund(uint256 _tierIndex) public payable { //捐款
        require(_tierIndex < tiers.length, "Invalid tier.");
        require(block.timestamp < deadline, "Campaign has ended");
        require(msg.value == tiers[_tierIndex].amount, "Incorrect amount.");
        tiers[_tierIndex].backers++;
    }

    function withdraw() public onlyOwner{ //提款
        require(msg.sender == owner, "Only the owner can withdraw");
        require(address(this).balance >= goal, "Goal had not been reached");
        uint256 balance = address(this).balance;
        require(balance >0 , "No balance to withdraw");
        payable(owner).transfer(balance);
    }

    function getContractBalance() public view returns (uint256) {//查看捐款数量
        return address(this).balance;
    }

    function addTier( //添加捐款等级
        string memory _name,
        uint256 _amount
    ) public onlyOwner {
        require(_amount > 0, "Amount must be greater than 0.");
        tiers.push(Tier(_name, _amount, 0));
    }

    function removeTier(uint256 _index) public onlyOwner { //移除捐款等级
        require(_index < tiers.length, "Tier does not exist.");
        tiers[_index] = tiers[tiers.length -1];
        tiers.pop();
    }
}