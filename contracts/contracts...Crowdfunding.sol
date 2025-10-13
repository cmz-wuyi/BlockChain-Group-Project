// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Crowdfunding {
    string public name;
    string public description;
    uint256 public goal;
    uint256 public deadline;
    address public owner;
    bool public paused;

    enum CampaignState { Active, Successful, Failed } //众筹活动状态
    CampaignState public state;

    struct Tier { //捐款等级
        string name;
        uint256 amount;
        uint256 backers; //支持者数量
    }
    Tier[] public tiers;

    struct Backer { //支持者信息
        uint256 totalContribution; //捐款金额
        mapping(uint256 => bool) fundedTiers; //支持者的捐款等级
    }
    mapping(address => Backer) public backers;

    modifier onlyOwner() { //操作人限制
        require(msg.sender == owner, "Not the owner");
        _;
    }
    
    modifier campaignOpen() { //活动状态限制
        require(state == CampaignState.Active, "Campaign is not active.");
        _;
    }

    modifier notPaused() { //活动暂停限制
        require(!paused, "Contract is paused.");
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
        state = CampaignState.Active;
    }

    function checkAndUpdateCampaignState() internal { //检查并更新众筹活动状态，是否结束或达到要求
        if(state == CampaignState.Active) {
            if(block.timestamp >= deadline) {
                state = address(this).balance >= goal ? CampaignState.Successful : CampaignState.Failed;            
            } else {
                state = address(this).balance >= goal ? CampaignState.Successful : CampaignState.Active;
            }
        }
    }

    function fund(uint256 _tierIndex) public payable campaignOpen notPaused{ //捐款
        require(_tierIndex < tiers.length, "Invalid tier.");
        require(msg.value == tiers[_tierIndex].amount, "Incorrect amount.");
        tiers[_tierIndex].backers++;
        backers[msg.sender].totalContribution += msg.value; //录入支持者捐款数量
        backers[msg.sender].fundedTiers[_tierIndex] = true; //录入支持者钱包地址与支持等级
        checkAndUpdateCampaignState(); //检查活动是否结束或达到要求
    }

    function withdraw() public onlyOwner{ //提款
        checkAndUpdateCampaignState(); //检查活动是否结束或达到要求
        require(state == CampaignState.Successful, "Campaign not successful.");
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");
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

    function getTiers() public view returns (Tier[] memory) { //显示捐款等级
        return tiers;
    }

    function refund() public { //活动失败后进行退款
        checkAndUpdateCampaignState(); //检查活动是否结束或达到要求
        require(state == CampaignState.Failed, "Refunds not available.");
        uint256 amount = backers[msg.sender].totalContribution;
        require(amount > 0, "No contribution to refund");
        backers[msg.sender].totalContribution = 0;
        payable(msg.sender).transfer(amount);
    }

    function hasFundedTier(address _backer, uint256 _tierIndex) public view returns (bool) { //检查用户是否为某个捐款等级提供资金
        return backers[_backer].fundedTiers[_tierIndex];
    }

    function togglePause() public onlyOwner { //暂停操作
        paused = !paused;
    }

    function getCampaignStatus() public view returns (CampaignState) { //显示众筹活动状态
        if (state == CampaignState.Active && block.timestamp > deadline) {
            return address(this).balance >= goal ? CampaignState.Successful : CampaignState.Failed;
        }
        return state;
    }

    function extendDeadline(uint256 _daysToAdd) public onlyOwner campaignOpen { //延长总筹活动天数
        deadline += _daysToAdd * 1 days;
    }
}