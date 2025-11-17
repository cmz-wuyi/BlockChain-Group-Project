// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Crowdfunding.sol";
import "../src/CrowdfundingFactory.sol";

contract RefundTest is Test {
    CrowdfundingFactory public factory;
    
    address public owner = address(0x100);
    address public backer1 = address(0x200);
    address public backer2 = address(0x300);
    address public backer3 = address(0x400);
    
    uint256 public goal = 10 ether;
    uint256 public duration = 1; // 1 day, convenient for testing expiration
    
    function setUp() public {
        factory = new CrowdfundingFactory();
    }
    
    // Test 1: Normal refund successful
    function test_RefundSuccess() public {
        // constructive activity
        vm.prank(owner);
        factory.createCampaign("Refund Test", "Test", goal, duration);
        
        CrowdfundingFactory.Campaign[] memory campaigns = factory.getAllCampaigns();
        Crowdfunding campaign = Crowdfunding(campaigns[0].campaignAddress);
        
        // Add funding level
        vm.prank(owner);
        campaign.addTier("Basic", 0.1 ether);
        
        // User funding
        vm.deal(backer1, 1 ether);
        vm.prank(backer1);
        campaign.fund{value: 0.1 ether}(0);
        
        // Verify that the funding has been successful.
        assertEq(campaign.getContractBalance(), 0.1 ether, "Contract should have funds");
        assertTrue(campaign.hasFundedTier(backer1, 0), "Backer should have funded tier 0");
        
        // Make the activity expire and fail
        vm.warp(block.timestamp + 2 days);
        
        // The verification activity status has changed to "Failed".
        assertEq(uint(campaign.getCampaignStatus()), 2, "Campaign should be Failed");
        
        // Record the balance before the refund
        uint256 backerInitialBalance = backer1.balance;
        uint256 contractBalanceBefore = campaign.getContractBalance();
        
        emit log_named_uint("Backer balance before refund", backerInitialBalance);
        emit log_named_uint("Contract balance before refund", contractBalanceBefore);
        
        // refund
        vm.prank(backer1);
        campaign.refund();
        
        // Verify that the refund has been successful
        assertEq(backer1.balance, backerInitialBalance + 0.1 ether, "Backer should receive refund");
        assertEq(campaign.getContractBalance(), contractBalanceBefore - 0.1 ether, "Contract balance should decrease");
        
        emit log("Refund SUCCESS!");
    }
    
    // Test 2: Refund fails when the activity does not fail
    function test_RefundFail_CampaignNotFailed() public {
        // constructive activity
        vm.prank(owner);
        factory.createCampaign("Active Campaign", "Test", goal, duration);
        
        CrowdfundingFactory.Campaign[] memory campaigns = factory.getAllCampaigns();
        Crowdfunding campaign = Crowdfunding(campaigns[0].campaignAddress);
        
        // Add funding level
        vm.prank(owner);
        campaign.addTier("Basic", 0.1 ether);
        
        // User funding
        vm.deal(backer1, 1 ether);
        vm.prank(backer1);
        campaign.fund{value: 0.1 ether}(0);
        
        // Without advancing the time, the activity remains "Active".
        
        // Attempted to refund (should have failed)
        vm.prank(backer1);
        vm.expectRevert("Refunds not available.");
        campaign.refund();
        
        emit log("Refund correctly failed for active campaign");
    }
    
    // Test 3: Refund fails when there is no funding record
    function test_RefundFail_NoContribution() public {
        // constructive activity
        vm.prank(owner);
        factory.createCampaign("No Contribution", "Test", goal, duration);
        
        CrowdfundingFactory.Campaign[] memory campaigns = factory.getAllCampaigns();
        Crowdfunding campaign = Crowdfunding(campaigns[0].campaignAddress);
        
        // Add funding level
        vm.prank(owner);
        campaign.addTier("Basic", 0.1 ether);
        
        // Make the activity expire and fail
        vm.warp(block.timestamp + 2 days);
        
        // The user has not made any donations and is attempting to request a refund (this should fail).
        vm.prank(backer2);
        vm.expectRevert("No contribution to refund");
        campaign.refund();
        
        emit log("Refund correctly failed for no contribution");
    }
    
    // Test 4: Refunds for Multiple Users
    function test_Refund_MultipleUsers() public {
        // constructive activity
        vm.prank(owner);
        factory.createCampaign("Multiple Refunds", "Test", goal, duration);
        
        CrowdfundingFactory.Campaign[] memory campaigns = factory.getAllCampaigns();
        Crowdfunding campaign = Crowdfunding(campaigns[0].campaignAddress);
        
        // Add funding level
        vm.prank(owner);
        campaign.addTier("Basic", 0.1 ether);
        
        // Multiple user funding
        vm.deal(backer1, 1 ether);
        vm.deal(backer2, 1 ether);
        
        vm.prank(backer1);
        campaign.fund{value: 0.1 ether}(0);
        
        vm.prank(backer2);
        campaign.fund{value: 0.1 ether}(0);
        
        // Verify the total balance
        assertEq(campaign.getContractBalance(), 0.2 ether, "Contract should have 0.2 ETH");
        
        // Make the activity expire and fail
        vm.warp(block.timestamp + 2 days);
        
        // Record the balance before the refund
        uint256 backer1InitialBalance = backer1.balance;
        uint256 backer2InitialBalance = backer2.balance;
        uint256 contractBalanceBefore = campaign.getContractBalance();
        
        // User 1 makes a refund
        vm.prank(backer1);
        campaign.refund();
        
        // Verify that user 1 has received the refund.
        assertEq(backer1.balance, backer1InitialBalance + 0.1 ether, "Backer1 should receive refund");
        assertEq(campaign.getContractBalance(), contractBalanceBefore - 0.1 ether, "Contract balance should decrease");
        
        // User 2 makes a refund
        vm.prank(backer2);
        campaign.refund();
        
        // Verify that user 2 has received the refund and that the contract balance is zero.
        assertEq(backer2.balance, backer2InitialBalance + 0.1 ether, "Backer2 should receive refund");
        assertEq(campaign.getContractBalance(), 0, "Contract should be empty after all refunds");
        
        emit log("Multiple refunds SUCCESS!");
    }
    
    //  Test 5: Refund after Multiple Injections of Funding
    function test_Refund_MultipleContributions() public {
        // constructive activity
        vm.prank(owner);
        factory.createCampaign("Multiple Contributions", "Test", goal, duration);
        
        CrowdfundingFactory.Campaign[] memory campaigns = factory.getAllCampaigns();
        Crowdfunding campaign = Crowdfunding(campaigns[0].campaignAddress);
        
        vm.startPrank(owner);
        campaign.addTier("Tier1", 0.05 ether);
        campaign.addTier("Tier2", 0.1 ether);
        vm.stopPrank();
        
        // User has made multiple donations.
        vm.deal(backer1, 2 ether);
        vm.startPrank(backer1);
        campaign.fund{value: 0.05 ether}(0);
        campaign.fund{value: 0.1 ether}(1);
        vm.stopPrank();
        
        // Verify the total balance
        assertEq(campaign.getContractBalance(), 0.15 ether, "Contract should have 0.15 ETH");
        
        // Make the activity expire and fail
        vm.warp(block.timestamp + 2 days);
        
        // Record the balance before the refund
        uint256 backerInitialBalance = backer1.balance;
        uint256 totalContribution = 0.15 ether;
        
        // refund
        vm.prank(backer1);
        campaign.refund();
        
        // Verify that all refunds have been received.
        assertEq(backer1.balance, backerInitialBalance + totalContribution, "Backer should receive all contributions");
        assertEq(campaign.getContractBalance(), 0, "Contract should be empty");
        
        emit log("Multiple contributions refund SUCCESS!");
    }
}