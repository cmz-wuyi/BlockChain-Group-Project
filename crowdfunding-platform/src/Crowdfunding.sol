// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Crowdfunding {
    string public name;
    string public description;
    uint256 public goal;
    uint256 public deadline;
    address public owner;
    bool public paused;

    /// @notice Enum for the state of the crowdfunding campaign
    enum CampaignState { Active, Successful, Failed }
    CampaignState public state;

    /// @notice Struct for donation tiers
    struct Tier {
        string name;
        uint256 amount;
        uint256 backers; // Number of backers for this tier
    }
    Tier[] public tiers;

    /// @notice Struct for backer information
    struct Backer {
        uint256 totalContribution; // Total contribution amount from this backer
        mapping(uint256 => bool) fundedTiers; // Mapping of tiers this backer has funded
    }
    mapping(address => Backer) public backers;

    /// @notice Modifier to restrict actions to the owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }
    
    /// @notice Modifier to ensure the campaign is active
    modifier campaignOpen() {
        require(state == CampaignState.Active, "Campaign is not active.");
        _;
    }

    /// @notice Modifier to ensure the contract is not paused
    modifier notPaused() {
        require(!paused, "Contract is paused.");
        _;
    }

    /// @notice Constructor to initialize the campaign
    constructor(
        address _owner,
        string memory _name, // Campaign name
        string memory _description, // Campaign description
        uint256 _goal, // Campaign goal
        uint256 _duratyionInDays // Campaign duration in days
    ) {
        name = _name;
        description = _description;
        goal = _goal;
        deadline = block.timestamp + (_duratyionInDays * 1 days);
        owner = _owner;
        state = CampaignState.Active;
    }

    /// @notice Internal function to check and update the campaign state
    function checkAndUpdateCampaignState() internal {
        if(state == CampaignState.Active) {
            if(block.timestamp >= deadline) {
                state = address(this).balance >= goal ?
                    CampaignState.Successful : CampaignState.Failed;            
            } else {
                state = address(this).balance >= goal ?
                    CampaignState.Successful : CampaignState.Active;
            }
        }
    }

    /// @notice Allows a user to fund a specific tier
    function fund(uint256 _tierIndex) public payable campaignOpen notPaused {
        require(_tierIndex < tiers.length, "Invalid tier.");
        require(msg.value == tiers[_tierIndex].amount, "Incorrect amount.");
        
        tiers[_tierIndex].backers++;
        backers[msg.sender].totalContribution += msg.value; // Record the backer's contribution
        backers[msg.sender].fundedTiers[_tierIndex] = true; // Mark the tier as funded by this backer

        checkAndUpdateCampaignState(); // Check if state needs updating
    }

    /// @notice Allows the owner to withdraw funds if the campaign is successful
    function withdraw() public onlyOwner {
        checkAndUpdateCampaignState(); // Ensure state is current
        require(state == CampaignState.Successful, "Campaign not successful.");
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");
        
        payable(owner).transfer(balance);
    }

    /// @notice Gets the current balance of the contract
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /// @notice Adds a new funding tier (owner only)
    function addTier(
        string memory _name,
        uint256 _amount
    ) public onlyOwner {
        require(_amount > 0, "Amount must be greater than 0.");
        tiers.push(Tier(_name, _amount, 0));
    }

    /// @notice Removes a funding tier (owner only)
    function removeTier(uint256 _index) public onlyOwner {
        require(_index < tiers.length, "Tier does not exist.");
        // Note: This logic for removal is potentially unsafe if tiers have backers.
        // A safer approach would be to check tiers[_index].backers == 0
        tiers[_index] = tiers[tiers.length -1];
        tiers.pop();
    }

    /// @notice Returns all available tiers
    function getTiers() public view returns (Tier[] memory) {
        return tiers;
    }

    /// @notice Allows backers to claim a refund if the campaign failed
    function refund() public {
        checkAndUpdateCampaignState(); // Ensure state is current
        require(state == CampaignState.Failed, "Refunds not available.");
        
        uint256 amount = backers[msg.sender].totalContribution;
        require(amount > 0, "No contribution to refund");
        
        backers[msg.sender].totalContribution = 0;
        payable(msg.sender).transfer(amount);
    }

    /// @notice Checks if a specific backer has funded a specific tier
    function hasFundedTier(address _backer, uint256 _tierIndex) public view returns (bool) {
        return backers[_backer].fundedTiers[_tierIndex];
    }

    /// @notice Toggles the paused state of the contract (owner only)
    function togglePause() public onlyOwner {
        paused = !paused;
    }

    /// @notice Gets the current status of the campaign
    function getCampaignStatus() public view returns (CampaignState) {
        if (state == CampaignState.Active && block.timestamp > deadline) {
            return address(this).balance >= goal ?
                CampaignState.Successful : CampaignState.Failed;
        }
        return state;
    }

    /// @notice Extends the campaign deadline (owner only, only if active)
    function extendDeadline(uint256 _daysToAdd) public onlyOwner campaignOpen {
        deadline += _daysToAdd * 1 days;
    }
}