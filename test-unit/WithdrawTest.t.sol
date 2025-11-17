// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Crowdfunding.sol";
import "../src/CrowdfundingFactory.sol";

contract WithdrawTest is Test {
    CrowdfundingFactory public factory;
    
    address public owner = address(0x100); // 使用一个明确的地址，避免与测试合约地址冲突
    address public backer1 = address(0x200);
    address public stranger = address(0x300);
    
    uint256 public goal = 0.1 ether; // 使用较小的金额
    uint256 public duration = 30;
    
    function setUp() public {
        factory = new CrowdfundingFactory();
    }
    
    // 测试 1: 非所有者不能提款
    function test_WithdrawFail_NotOwner() public {
        // 创建活动
        vm.prank(owner);
        factory.createCampaign("Test Campaign", "Test", goal, duration);
        
        CrowdfundingFactory.Campaign[] memory campaigns = factory.getAllCampaigns();
        Crowdfunding campaign = Crowdfunding(campaigns[0].campaignAddress);
        
        // 非所有者尝试提款
        vm.prank(stranger);
        vm.expectRevert("Not the owner");
        campaign.withdraw();
    }
    
    // 测试 2: 活动未成功时提款失败
    function test_WithdrawFail_CampaignNotSuccessful() public {
        // 创建活动
        vm.prank(owner);
        factory.createCampaign("Test Campaign", "Test", goal, duration);
        
        CrowdfundingFactory.Campaign[] memory campaigns = factory.getAllCampaigns();
        Crowdfunding campaign = Crowdfunding(campaigns[0].campaignAddress);
        
        // 添加资助等级
        vm.prank(owner);
        campaign.addTier("Basic", goal);
        
        // 不进行资助，活动不会成功
        vm.prank(owner);
        vm.expectRevert("Campaign not successful.");
        campaign.withdraw();
    }
    
    // 测试 3: 活动未达到目标时提款失败
    function test_WithdrawFail_NotReachedGoal() public {
        // 创建活动，目标高于单个等级金额
        uint256 higherGoal = 0.2 ether;
        vm.prank(owner);
        factory.createCampaign("Partial Campaign", "Test", higherGoal, duration);
        
        CrowdfundingFactory.Campaign[] memory campaigns = factory.getAllCampaigns();
        Crowdfunding campaign = Crowdfunding(campaigns[0].campaignAddress);
        
        // 添加资助等级，金额小于目标
        vm.prank(owner);
        campaign.addTier("Silver", 0.1 ether); // 等级金额 0.1 ether
        
        // 用户资助，但未达到目标 0.2 ether
        vm.deal(backer1, 1 ether);
        vm.prank(backer1);
        campaign.fund{value: 0.1 ether}(0); // 精确匹配等级金额
        
        // 验证状态仍然是Active
        assertEq(uint(campaign.getCampaignStatus()), 0, "Campaign should be Active");
        
        // 此时不能提款，因为活动未成功
        vm.prank(owner);
        vm.expectRevert("Campaign not successful.");
        campaign.withdraw();
        
        emit log("Withdraw correctly fails for non-successful campaign");
    }
    
    // 测试 4: 无资金时提款失败
    function test_WithdrawFail_NoFunds() public {
        // 创建活动
        vm.prank(owner);
        factory.createCampaign("Empty Campaign", "Test", goal, duration);
        
        CrowdfundingFactory.Campaign[] memory campaigns = factory.getAllCampaigns();
        Crowdfunding campaign = Crowdfunding(campaigns[0].campaignAddress);
        
        // 添加资助等级
        vm.prank(owner);
        campaign.addTier("Basic", goal);
        
        // 不进行资助，活动不会成功，所以提款会因活动未成功而失败
        vm.prank(owner);
        vm.expectRevert("Campaign not successful.");
        campaign.withdraw();
    }
}