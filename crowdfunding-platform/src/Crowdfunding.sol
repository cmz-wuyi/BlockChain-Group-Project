// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Crowdfunding {
    string public name;
    string public description;
    uint256 public goal;
    uint256 public deadline;
    address public owner;
    bool public paused;

    enum CampaignState { Active, Successful, Failed } //Crowdfunding campaign status
    CampaignState public state;

    struct Tier { //Crowdfunding tier
        string name;
        uint256 amount;
        uint256 backers; //Number of backers
    }
    Tier[] public tiers;

    struct Backer { //Backer information
        uint256 totalContribution; //Contribution amount
        mapping(uint256 => bool) fundedTiers; //Backer's funded tiers
    }
    mapping(address => Backer) public backers;

    modifier onlyOwner() { //Owner restriction
        require(msg.sender == owner, "Not the owner");
        _;
    }

    modifier campaignOpen() { //Campaign status restriction
        require(state == CampaignState.Active, "Campaign is not active.");
        _;
    }

    modifier notPaused() { //Pause restriction
        require(!paused, "Contract is paused.");
        _;
    }

    constructor( //Input information
        address _owner,
        string memory _name, //Donation name
        string memory _description, //Donation description
        uint256 _goal, //Donation goal
        uint256 _duratyionInDays //Deadline in days
    ) {
        name = _name;
        description = _description;
        goal = _goal;
        deadline = block.timestamp + (_duratyionInDays * 1 days);
        owner = _owner;
        state = CampaignState.Active;
    }

    function checkAndUpdateCampaignState() internal { //Check and update the status of the crowdfunding campaign to see if it has ended or met the requirements.
        if(state == CampaignState.Active) {
            if(block.timestamp >= deadline) {
                state = address(this).balance >= goal ? CampaignState.Successful : CampaignState.Failed;            
            } else {
                state = address(this).balance >= goal ? CampaignState.Successful : CampaignState.Active;
            }
        }
    }

    function fund(uint256 _tierIndex) public payable campaignOpen notPaused{ //Fund a campaign
        require(_tierIndex < tiers.length, "Invalid tier.");
        require(msg.value == tiers[_tierIndex].amount, "Incorrect amount.");
        tiers[_tierIndex].backers++;
        backers[msg.sender].totalContribution += msg.value; //Record backer's contribution amount
        backers[msg.sender].fundedTiers[_tierIndex] = true; //Record backer's wallet address and funded tier
        checkAndUpdateCampaignState(); //Check if the campaign has ended or met the requirements
    }

    function withdraw() public onlyOwner{ //Withdraw funds
        checkAndUpdateCampaignState(); //Check if the campaign has ended or met the requirements
        require(state == CampaignState.Successful, "Campaign not successful.");
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");
        payable(owner).transfer(balance);
    }

    function getContractBalance() public view returns (uint256) {//View donation amount
        return address(this).balance;
    }

    function addTier( //Add donation tier
        string memory _name,
        uint256 _amount
    ) public onlyOwner {
        require(_amount > 0, "Amount must be greater than 0.");
        tiers.push(Tier(_name, _amount, 0));
    }

    function removeTier(uint256 _index) public onlyOwner { //Remove donation tier
        require(tiers[_index].backers == 0, "Cannot remove a tier that already has backers.");
        require(_index < tiers.length, "Tier does not exist.");
        tiers[_index] = tiers[tiers.length -1];
        tiers.pop();
    }

    function getTiers() public view returns (Tier[] memory) { //Show donation tiers
        return tiers;
    }

    function refund() public { //Refund after campaign failure
        checkAndUpdateCampaignState(); //Check if the campaign has ended or met the requirements
        require(state == CampaignState.Failed, "Refunds not available.");
        uint256 amount = backers[msg.sender].totalContribution;
        require(amount > 0, "No contribution to refund");
        backers[msg.sender].totalContribution = 0;
        payable(msg.sender).transfer(amount);
    }

    function hasFundedTier(address _backer, uint256 _tierIndex) public view returns (bool) { //Check if user has funded a specific tier
        return backers[_backer].fundedTiers[_tierIndex];
    }

    function togglePause() public onlyOwner { //Pause operations
        paused = !paused;
    }

    function getCampaignStatus() public view returns (CampaignState) { //Show crowdfunding campaign status
        if (state == CampaignState.Active && block.timestamp > deadline) {
            return address(this).balance >= goal ? CampaignState.Successful : CampaignState.Failed;
        }
        return state;
    }

    function extendDeadline(uint256 _daysToAdd) public onlyOwner campaignOpen { //Extend crowdfunding campaign duration
        deadline += _daysToAdd * 1 days;
    }
}