// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Crowdfunding.sol";
import "../src/CrowdfundingFactory.sol";

contract FundTest is Test {
    Crowdfunding public campaign;
    CrowdfundingFactory public factory;
    
    address public owner = address(0x1);
    address public backer1 = address(0x2);
    address public backer2 = address(0x3);
    
    uint256 public goal = 10 ether;
    uint256 public duration = 30;
    
    function setUp() public {
        // 部署工厂合约并创建一个测试活动
        factory = new CrowdfundingFactory();
        
        vm.prank(owner);
        factory.createCampaign(
            "Test Campaign",
            "Test Description",
            goal,
            duration
        );
        
        // 获取新创建的活动
        CrowdfundingFactory.Campaign[] memory campaigns = factory.getAllCampaigns();
        campaign = Crowdfunding(campaigns[0].campaignAddress);
        
        // 添加测试用的资助等级 - 必须用所有者身份调用
        vm.prank(owner);
        campaign.addTier("Basic", 0.1 ether);
        
        vm.prank(owner);
        campaign.addTier("Premium", 1 ether);
    }
    
    // 测试 1: 正常资助成功
    function test_FundSuccess() public {
        vm.deal(backer1, 1 ether);
        vm.prank(backer1);
        campaign.fund{value: 0.1 ether}(0);
        
        assertEq(campaign.getContractBalance(), 0.1 ether);
        assertTrue(campaign.hasFundedTier(backer1, 0));
    }
    
    // 测试 2: 资金不足情况
    function test_FundFail_InsufficientValue() public {
        vm.deal(backer1, 0.05 ether); // 只有0.05 ETH，但需要0.1 ETH
        
        vm.prank(backer1);
        vm.expectRevert("Incorrect amount.");
        campaign.fund{value: 0.05 ether}(0);
    }
    
    // 测试 3: 活动暂停时资助失败
    function test_FundFail_WhenPaused() public {
        // 先暂停合约
        vm.prank(owner);
        campaign.togglePause();
        
        vm.deal(backer1, 1 ether);
        vm.prank(backer1);
        vm.expectRevert("Contract is paused.");
        campaign.fund{value: 0.1 ether}(0);
    }
    
    // 测试 4: 无效等级索引
    function test_FundFail_InvalidTier() public {
        vm.deal(backer1, 1 ether);
        vm.prank(backer1);
        vm.expectRevert("Invalid tier.");
        campaign.fund{value: 0.1 ether}(999); // 不存在的等级索引
    }
    
    // 测试 5: 多个用户资助同一活动
    function test_MultipleUsersFunding() public {
        // 用户1资助
        vm.deal(backer1, 1 ether);
        vm.prank(backer1);
        campaign.fund{value: 0.1 ether}(0);
        
        // 用户2资助
        vm.deal(backer2, 2 ether);
        vm.prank(backer2);
        campaign.fund{value: 1 ether}(1); // 资助Premium等级
        
        // 验证总余额
        assertEq(campaign.getContractBalance(), 1.1 ether);
        
        // 验证各自的资助记录
        assertTrue(campaign.hasFundedTier(backer1, 0));
        assertTrue(campaign.hasFundedTier(backer2, 1));
    }
    
    // 测试 6: 同一用户多次资助
    function test_SameUserMultipleFunding() public {
        vm.deal(backer1, 2 ether);
        
        vm.startPrank(backer1);
        campaign.fund{value: 0.1 ether}(0);
        campaign.fund{value: 1 ether}(1);
        vm.stopPrank();
        
        assertEq(campaign.getContractBalance(), 1.1 ether);
        assertTrue(campaign.hasFundedTier(backer1, 0));
        assertTrue(campaign.hasFundedTier(backer1, 1));
    }
    
    // 测试 7: 活动结束后资助失败 - 简化版本
    function test_FundFail_CampaignEnded() public {
        // 创建一个新的短期活动专门测试这个场景
        vm.prank(owner);
        factory.createCampaign("Short Campaign", "Short", 5 ether, 1); // 1天
        
        CrowdfundingFactory.Campaign[] memory campaigns = factory.getAllCampaigns();
        Crowdfunding shortCampaign = Crowdfunding(campaigns[campaigns.length - 1].campaignAddress);
        
        vm.prank(owner);
        shortCampaign.addTier("Basic", 0.1 ether);
        
        // 立即推进时间到活动结束后
        vm.warp(block.timestamp + 2 days);
        
        vm.deal(backer1, 1 ether);
        vm.prank(backer1);
        vm.expectRevert("Campaign has ended.");
        shortCampaign.fund{value: 0.1 ether}(0);
    }
}