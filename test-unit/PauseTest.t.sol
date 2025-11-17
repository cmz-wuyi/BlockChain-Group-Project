// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Crowdfunding.sol";
import "../src/CrowdfundingFactory.sol";

contract PauseTest is Test {
    CrowdfundingFactory public factory;
    
    address public owner = address(0x100);
    address public backer1 = address(0x200);
    address public nonOwner = address(0x300);
    
    uint256 public goal = 10 ether;
    uint256 public duration = 7;
    
    function setUp() public {
        factory = new CrowdfundingFactory();
    }

     //Test 1: The owner has normally suspended the permissions.
    function test_TogglePause_OwnerCanPause() public {
        // constructive activity
        vm.prank(owner);
        factory.createCampaign("Pause Test", "Test", goal, duration);
        
        CrowdfundingFactory.Campaign[] memory campaigns = factory.getAllCampaigns();
        Crowdfunding campaign = Crowdfunding(campaigns[0].campaignAddress);
        
        // Add funding level
        vm.prank(owner);
        campaign.addTier("Basic", 1 ether);
        
        // Initially, there was no pause.
        assertEq(campaign.paused(), false, "Initially should not be paused");
        
        // The owner can suspend
        vm.prank(owner);
        campaign.togglePause();
        
        assertEq(campaign.paused(), true, "Should be paused after toggle");
        
        emit log("Owner can pause - SUCCESS!");
    }

    //Test 2: Failure in suspending non-owner users
    function test_TogglePause_NonOwnerCannotPause() public {
        // constructive activity
        vm.prank(owner);
        factory.createCampaign("Non Owner Pause", "Test", goal, duration);
        
        CrowdfundingFactory.Campaign[] memory campaigns = factory.getAllCampaigns();
        Crowdfunding campaign = Crowdfunding(campaigns[0].campaignAddress);
        
        // Not all attempts by non-owners to suspend - should fail
        vm.prank(nonOwner);
        vm.expectRevert("Not the owner");
        campaign.togglePause();
        
        emit log("Non-owner cannot pause - SUCCESS!");
    }

    //Test 3: The pause and resume function is working properly.
    function test_TogglePause_CanUnpause() public {
        // constructive activity
        vm.prank(owner);
        factory.createCampaign("Unpause Test", "Test", goal, duration);
        
        CrowdfundingFactory.Campaign[] memory campaigns = factory.getAllCampaigns();
        Crowdfunding campaign = Crowdfunding(campaigns[0].campaignAddress);
        
        //Add funding level
        vm.prank(owner);
        campaign.addTier("Basic", 1 ether);
        
        // pause
        vm.prank(owner);
        campaign.togglePause();
        assertEq(campaign.paused(), true, "Should be paused");
        
        // Cancel the pause
        vm.prank(owner);
        campaign.togglePause();
        assertEq(campaign.paused(), false, "Should be unpaused");
        
        emit log("Can unpause - SUCCESS!");
    }

    //Test 4: Funding fails in the suspended state
    function test_FundFails_WhenPaused() public {
        //constructive activity
        vm.prank(owner);
        factory.createCampaign("Paused Funding", "Test", goal, duration);
        
        CrowdfundingFactory.Campaign[] memory campaigns = factory.getAllCampaigns();
        Crowdfunding campaign = Crowdfunding(campaigns[0].campaignAddress);
        
        // Add funding level
        vm.prank(owner);
        campaign.addTier("Basic", 1 ether);
        
        // Termination of contract
        vm.prank(owner);
        campaign.togglePause();
        
        //  Attempt to provide funding while in a paused state
        vm.deal(backer1, 2 ether);
        vm.prank(backer1);
        vm.expectRevert("Contract is paused.");
        campaign.fund{value: 1 ether}(0);
        
        emit log("Funding fails when paused - SUCCESS!");
    }

    //Test 5: The funding function returned to normal after restoration.
    function test_FundWorks_AfterUnpausing() public {
        // constructive activity
        vm.prank(owner);
        factory.createCampaign("Unpaused Funding", "Test", goal, duration);
        
        CrowdfundingFactory.Campaign[] memory campaigns = factory.getAllCampaigns();
        Crowdfunding campaign = Crowdfunding(campaigns[0].campaignAddress);
        
        // Add funding level
        vm.prank(owner);
        campaign.addTier("Basic", 1 ether);
        
        // First, pause; then, cancel the pause.
        vm.prank(owner);
        campaign.togglePause();
        vm.prank(owner);
        campaign.togglePause();
        
        // Now the funding should be normal.
        vm.deal(backer1, 2 ether);
        vm.prank(backer1);
        campaign.fund{value: 1 ether}(0);
        
        // Verify that the funding has been successful.
        assertEq(campaign.getContractBalance(), 1 ether, "Contract should have funds");
        
        emit log("Funding works after unpausing - SUCCESS!");
    }

    //Test 6: Withdrawal fails when the transaction is suspended and unsuccessful
    function test_WithdrawFail_WhenPausedAndNotSuccessful() public {
        // constructive activity
        vm.prank(owner);
        factory.createCampaign("Paused Withdraw Fail", "Test", 5 ether, 7);
        
        CrowdfundingFactory.Campaign[] memory campaigns = factory.getAllCampaigns();
        Crowdfunding campaign = Crowdfunding(campaigns[0].campaignAddress);
        
        // Add funding level
        vm.prank(owner);
        campaign.addTier("Basic", 1 ether);
        
        // Funded but not reaching the target
        vm.deal(backer1, 10 ether);
        vm.prank(backer1);
        campaign.fund{value: 1 ether}(0);
        
        // Termination of contract
        vm.prank(owner);
        campaign.togglePause();
        
        // The verification activity was not successful.
        assertEq(uint(campaign.getCampaignStatus()), 0, "Campaign should be Active");
        
        // Attempting to withdraw funds should have failed because the activity was not successful.
        vm.prank(owner);
        vm.expectRevert("Campaign not successful.");
        campaign.withdraw();
        
        emit log("Withdraw correctly fails when paused and campaign not successful");
    }

    //Test 7: The refund function works properly in the paused state.
    function test_RefundWorks_WhenPaused() public {
        // constructive activity
        vm.prank(owner);
        factory.createCampaign("Paused Refund", "Test", goal, duration);
        
        CrowdfundingFactory.Campaign[] memory campaigns = factory.getAllCampaigns();
        Crowdfunding campaign = Crowdfunding(campaigns[0].campaignAddress);
        
        // Add funding level
        vm.prank(owner);
        campaign.addTier("Basic", 1 ether);
        
        // Funded but not reaching the target
        vm.deal(backer1, 2 ether);
        vm.prank(backer1);
        campaign.fund{value: 1 ether}(0);
        
        // The progress time has exceeded the deadline.
        vm.warp(block.timestamp + 8 days);
        
        // Termination of contract
        vm.prank(owner);
        campaign.togglePause();
        
        // Refunds should still be able to be processed even when the service is suspended.
        uint256 backerInitialBalance = backer1.balance;
        vm.prank(backer1);
        campaign.refund();
        
        assertEq(backer1.balance, backerInitialBalance + 1 ether, "Backer should receive refund even when paused");
        
        emit log("Refund works when paused - SUCCESS!");
    }
}