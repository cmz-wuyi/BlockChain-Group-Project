// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Crowdfunding} from "./Crowdfunding.sol";

contract CrowdfundingFactory {
    address public owner;
    bool public paused;

    /// @notice Struct to store basic campaign information
    struct Campaign {
        address campaignAddress;
        address owner;
        string name;
        uint256 creationTime;
    }

    Campaign[] public campaigns;
    mapping(address => Campaign[]) public userCampaigns;

    /// @notice Modifier to restrict actions to the owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner.");
        _;
    }

    /// @notice Modifier to ensure the factory is not paused
    modifier notPaused() {
        require(!paused, "Factory is paused");
        _;
    }

    /// @notice Sets the contract deployer as the owner
    constructor() {
        owner = msg.sender;
    }

    /// @notice Creates and deploys a new Crowdfunding contract
    function createCampaign(
        string memory _name,
        string memory _description,
        uint256 _goal,
        uint256 _durationInDays
    ) external notPaused {
        Crowdfunding newCampaign = new Crowdfunding(
            msg.sender, // The creator is the owner of the new campaign
            _name,
            _description,
            _goal,
            _durationInDays
        );
        
        address campaignAddress = address(newCampaign);

        Campaign memory campaign = Campaign({
            campaignAddress: campaignAddress,
            owner: msg.sender,
            name: _name,
            creationTime: block.timestamp
        });
        
        campaigns.push(campaign);
        userCampaigns[msg.sender].push(campaign);
    }

    /// @notice Gets all campaigns created by a specific user
    function getUserCampaigns(address _user) external view returns (Campaign[] memory) {
        return userCampaigns[_user];
    }

    /// @notice Gets all campaigns created by this factory
    function getAllCampaigns() external view returns (Campaign[] memory) {
        return campaigns;
    }

    /// @notice Toggles the paused state of the factory (owner only)
    function togglePause() external onlyOwner {
        paused = !paused;
    }
}