// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/CrowdfundingFactory.sol";
import "../src/Crowdfunding.sol";

contract CampaignCreationTest is Test {
    CrowdfundingFactory public factory;
    address public owner = address(0x1);
    address public creator = address(0x2);
    address public creator2 = address(0x3);
    
    function setUp() public {
        // Deploy the new factory contract before each test
        factory = new CrowdfundingFactory();
    }
    
    // Test 1: Can the factory contract be deployed normally ?
    function test_FactoryDeployment() public view {
        assertTrue(address(factory) != address(0));
        assertEq(factory.owner(), address(this));
    }
    
    // Test 2: Will the crowdfunding campaign be successfully launched?
    function test_CreateCampaignSuccess() public {
        string memory campaignName = "Test Campaign";
        string memory campaignDescription = "Test Description";
        uint256 goal = 10 ether;
        uint256 durationInDays = 30;
        
        // Record the number of activities before the creation of the record
        uint256 initialCampaignCount = factory.getAllCampaigns().length;
        
        vm.prank(creator);
        factory.createCampaign(
            campaignName,
            campaignDescription,
            goal,
            durationInDays
        );
        
        //Obtain the newly created activity
        CrowdfundingFactory.Campaign[] memory allCampaigns = factory.getAllCampaigns();
        
        // The number of verification activities has increased.
        assertEq(allCampaigns.length, initialCampaignCount + 1);
        
        address campaignAddress = allCampaigns[initialCampaignCount].campaignAddress;
        
        // Verify that the activity address is not zero.
        assertTrue(campaignAddress != address(0));
        
        // Verify activity information
        Crowdfunding campaign = Crowdfunding(campaignAddress);
        assertEq(campaign.name(), campaignName);
        assertEq(campaign.description(), campaignDescription);
        assertEq(campaign.goal(), goal);
        assertEq(campaign.owner(), creator);
        assertTrue(campaign.deadline() > block.timestamp);
    }
    
    // Test 3: Can obtain all activity lists
    function test_GetAllCampaigns() public {
        string memory campaignName = "Test Campaign";
        string memory campaignDescription = "Test Description";
        uint256 goal = 5 ether;
        uint256 durationInDays = 15;
        
        // Record the initial quantity
        uint256 initialCount = factory.getAllCampaigns().length;
        
        // Create two activities
        vm.startPrank(creator);
        factory.createCampaign(campaignName, campaignDescription, goal, durationInDays);
        factory.createCampaign(campaignName, campaignDescription, goal, durationInDays);
        vm.stopPrank();
        
        // Get the list of activities
        CrowdfundingFactory.Campaign[] memory allCampaigns = factory.getAllCampaigns();
        
        // Verify the length and content of the list
        assertEq(allCampaigns.length, initialCount + 2);
        assertTrue(allCampaigns[initialCount].campaignAddress != address(0));
        assertTrue(allCampaigns[initialCount + 1].campaignAddress != address(0));
    }

    // Test 4: Can obtain the activity list of a specific user
    function test_GetUserCampaigns() public {
        string memory campaignName = "Test Campaign";
        string memory campaignDescription = "Test Description";
        uint256 goal = 5 ether;
        uint256 durationInDays = 15;
        
        //Record the initial quantity
        uint256 initialUserCount = factory.getUserCampaigns(creator).length;
        
        // Create two activities
        vm.startPrank(creator);
        factory.createCampaign(campaignName, campaignDescription, goal, durationInDays);
        factory.createCampaign(campaignName, campaignDescription, goal, durationInDays);
        vm.stopPrank();
        
        // Obtain the list of user activities
        CrowdfundingFactory.Campaign[] memory userCampaigns = factory.getUserCampaigns(creator);
        
        // Verify the length and content of the list
        assertEq(userCampaigns.length, initialUserCount + 2);
        assertTrue(userCampaigns[initialUserCount].campaignAddress != address(0));
        assertTrue(userCampaigns[initialUserCount + 1].campaignAddress != address(0));
    }
    
    // Test 5: The activities created by different users are independent of each other.
    function test_MultipleUsersCampaigns() public {
        string memory campaignName = "Test Campaign";
        string memory campaignDescription = "Test Description";
        uint256 goal = 3 ether;
        uint256 durationInDays = 10;
        
        // User 1 initiates an activity
        vm.prank(creator);
        factory.createCampaign(campaignName, campaignDescription, goal, durationInDays);
        
        // User 2 initiates an activity
        vm.prank(creator2);
        factory.createCampaign(campaignName, campaignDescription, goal, durationInDays);
        
        // Verify the total number of activities
        CrowdfundingFactory.Campaign[] memory allCampaigns = factory.getAllCampaigns();
        assertEq(allCampaigns.length, 2);
        
        // Verify that user 1 can only view their own activities.
        CrowdfundingFactory.Campaign[] memory creator1Campaigns = factory.getUserCampaigns(creator);
        assertEq(creator1Campaigns.length, 1);
        assertEq(creator1Campaigns[0].owner, creator);
        
        // Verify that user 2 can only view their own activities.
        CrowdfundingFactory.Campaign[] memory creator2Campaigns = factory.getUserCampaigns(creator2);
        assertEq(creator2Campaigns.length, 1);
        assertEq(creator2Campaigns[0].owner, creator2);
    }
    
    // Test 6: The created activity information is correctly stored
    function test_CampaignInfoStorage() public {
        string memory campaignName = "My Awesome Project";
        string memory campaignDescription = "This is a detailed description of my project";
        uint256 goal = 15 ether;
        uint256 durationInDays = 45;
        
        vm.prank(creator);
        factory.createCampaign(campaignName, campaignDescription, goal, durationInDays);
        
        // Obtain activity information
        CrowdfundingFactory.Campaign[] memory allCampaigns = factory.getAllCampaigns();
        CrowdfundingFactory.Campaign memory createdCampaign = allCampaigns[0];
        
        // Verify the stored information
        assertEq(createdCampaign.name, campaignName);
        assertEq(createdCampaign.owner, creator);
        assertTrue(createdCampaign.creationTime > 0);
        assertTrue(createdCampaign.creationTime <= block.timestamp);
        
        // Verify the activity contract information obtained from the address.
        Crowdfunding campaignContract = Crowdfunding(createdCampaign.campaignAddress);
        assertEq(campaignContract.name(), campaignName);
        assertEq(campaignContract.description(), campaignDescription);
        assertEq(campaignContract.goal(), goal);
    }
}