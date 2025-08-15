// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Cr8rFlow} from "../src/Cr8rFlow.sol";

contract Cr8FlowTest is Test {
    Cr8rFlow cr8rflow;
    address creator = address(0x1);
    address fan = address(0x2);
    address contributor1 = address(0x3);
    address contributor2 = address(0x4);
    address nonOwner = address(0x5);

    // Setup function to deploy the contract before each test
    function setUp() public {
        cr8rflow = new Cr8rFlow();
        vm.deal(creator, 10 ether); // Fund creator for revenue distribution
        vm.deal(fan, 1 ether); // Fund fan for NFT interactions
    }

    // Helper function to create a project
    function createTestProject() internal returns (uint256) {
        address[] memory contributors = new address[](2);
        contributors[0] = contributor1;
        contributors[1] = contributor2;
        uint256[] memory percentages = new uint256[](2);
        percentages[0] = 5000; // 50%
        percentages[1] = 5000; // 50%
        vm.prank(creator);
        return cr8rflow.createProject("Test Album", contributors, percentages);
    }

    // Helper function to mint an NFT
    function mintTestContent(uint256 projectId) internal returns (uint256) {
        address[] memory contributors = new address[](2);
        contributors[0] = contributor1;
        contributors[1] = contributor2;
        uint256[] memory percentages = new uint256[](2);
        percentages[0] = 5000; // 50%
        percentages[1] = 5000; // 50%
        Cr8rFlow.Tier[] memory tiers = new Cr8rFlow.Tier[](2);
        tiers[0] = Cr8rFlow.Tier("Bonus Track", 1, true);
        tiers[1] = Cr8rFlow.Tier("VIP Access", 2, true);
        vm.prank(creator);
        return cr8rflow.mintContent(projectId, "ipfs://test-uri", contributors, percentages, tiers);
    }

    // Test project creation
    function testCreateProject() public {
        address[] memory contributors = new address[](2);
        contributors[0] = contributor1;
        contributors[1] = contributor2;
        uint256[] memory percentages = new uint256[](2);
        percentages[0] = 5000; // 50%
        percentages[1] = 5000; // 50%

        vm.prank(creator);
        vm.expectEmit(true, true, false, true);
        emit Cr8rFlow.ProjectCreated(0, "Test Album", creator);
        uint256 projectId = cr8rflow.createProject("Test Album", contributors, percentages);

        assertEq(projectId, 0, "Project ID should be 0");
        assertEq(cr8rflow.getProjectName(projectId), "Test Album", "Project name incorrect");
        assertEq(cr8rflow.getProjectOwner(projectId), creator, "Project owner incorrect");
        assertTrue(cr8rflow.getProjectExists(projectId), "Project should exist");
        assertEq(cr8rflow.getProjectTokenIds(projectId).length, 0, "Project tokenIds should be empty");
        assertEq(cr8rflow.nextProjectId(), 1, "Next project ID should increment");
    }

    // Test project creation with invalid splits
    function test_RevertWhen_CreateProjectInvalidSplits() public {
        address[] memory contributors = new address[](2);
        contributors[0] = contributor1;
        contributors[1] = contributor2;
        uint256[] memory percentages = new uint256[](2);
        percentages[0] = 5000; // 50%
        percentages[1] = 3000; // 30% (total 80%, should fail)

        vm.prank(creator);
        vm.expectRevert("Invalid royalty splits");
        cr8rflow.createProject("Test Album", contributors, percentages);
    }

    // Test project creation with mismatched inputs
    function test_RevertWhen_CreateProjectMismatchedInputs() public {
        address[] memory contributors = new address[](2);
        contributors[0] = contributor1;
        contributors[1] = contributor2;
        uint256[] memory percentages = new uint256[](1);
        percentages[0] = 10000;

        vm.prank(creator);
        vm.expectRevert("Mismatched input lengths");
        cr8rflow.createProject("Test Album", contributors, percentages); // Should revert
    }

    // Test minting content
    function testMintContent() public {
        uint256 projectId = createTestProject();
        address[] memory contributors = new address[](2);
        contributors[0] = contributor1;
        contributors[1] = contributor2;
        uint256[] memory percentages = new uint256[](2);
        percentages[0] = 5000;
        percentages[1] = 5000;
        Cr8rFlow.Tier[] memory tiers = new Cr8rFlow.Tier[](2);
        tiers[0] = Cr8rFlow.Tier("Bonus Track", 1, true);
        tiers[1] = Cr8rFlow.Tier("VIP Access", 2, true);

        vm.prank(creator);
        vm.expectEmit(true, true, true, true);
        emit Cr8rFlow.ContentMinted(projectId, 0, creator, "ipfs://test-uri");
        uint256 tokenId = cr8rflow.mintContent(projectId, "ipfs://test-uri", contributors, percentages, tiers);

        assertEq(cr8rflow.ownerOf(tokenId), creator, "Creator should own NFT");
        assertEq(cr8rflow.tokenURI(tokenId), "ipfs://test-uri", "Token URI incorrect");
        assertEq(cr8rflow.getProjectTokenIds(projectId).length, 1, "Token not added to project");
        assertEq(cr8rflow.getProjectTokenIds(projectId)[0], tokenId, "Token ID mismatch in project");
        assertEq(cr8rflow.getTokenRoyaltySplitsLength(tokenId), 2, "Royalty splits not set");
        assertEq(cr8rflow.getTokenTiersLength(tokenId), 2, "Tiers not set");
    }

    // Test minting with invalid project
    function test_RevertWhen_MintInvalidProject() public {
        address[] memory contributors = new address[](1);
        contributors[0] = contributor1;
        uint256[] memory percentages = new uint256[](1);
        percentages[0] = 10000;
        Cr8rFlow.Tier[] memory tiers = new Cr8rFlow.Tier[](1);
        tiers[0] = Cr8rFlow.Tier("Bonus Track", 1, true);

        vm.prank(creator);
        vm.expectRevert("Invalid project");
        cr8rflow.mintContent(999, "ipfs://test-uri", contributors, percentages, tiers);
    }

    // Test minting by non-owner
    function test_RevertWhen_MintNonOwner() public {
        uint256 projectId = createTestProject();
        address[] memory contributors = new address[](1);
        contributors[0] = contributor1;
        uint256[] memory percentages = new uint256[](1);
        percentages[0] = 10000;
        Cr8rFlow.Tier[] memory tiers = new Cr8rFlow.Tier[](1);
        tiers[0] = Cr8rFlow.Tier("Bonus Track", 1, true);

        vm.prank(nonOwner);
        vm.expectRevert("Not project owner");
        cr8rflow.mintContent(projectId, "ipfs://test-uri", contributors, percentages, tiers); // Should revert
    }

    // Test revenue distribution
    function testDistributeRevenue() public {
        uint256 projectId = createTestProject();
        uint256 tokenId = mintTestContent(projectId);

        uint256 initialBalance1 = contributor1.balance;
        uint256 initialBalance2 = contributor2.balance;
        uint256 amount = 1 ether;

        vm.prank(creator);
        vm.expectEmit(true, true, false, true);
        emit Cr8rFlow.FundsReceived(tokenId, creator, amount);
        vm.expectEmit(true, true, false, true);
        emit Cr8rFlow.RevenueDistributed(tokenId, contributor1, amount / 2);
        vm.expectEmit(true, true, false, true);
        emit Cr8rFlow.RevenueDistributed(tokenId, contributor2, amount / 2);
        cr8rflow.distributeRevenue{value: amount}(tokenId);

        assertEq(contributor1.balance, initialBalance1 + amount / 2, "Contributor1 balance incorrect");
        assertEq(contributor2.balance, initialBalance2 + amount / 2, "Contributor2 balance incorrect");
    }

    // Test revenue distribution with zero funds
    function test_RevertWhen_DistributeRevenueZeroFunds() public {
        uint256 projectId = createTestProject();
        uint256 tokenId = mintTestContent(projectId);

        vm.prank(creator);
        vm.expectRevert("No funds sent");
        cr8rflow.distributeRevenue{value: 0}(tokenId); // Should revert
    }

    // Test revenue distribution for non-existent token
    function test_RevertWhen_DistributeRevenueInvalidToken() public {
        vm.prank(creator);
        vm.expectRevert("ERC721NonexistentToken(999)");
        cr8rflow.distributeRevenue{value: 1 ether}(999); // Should revert
    }

    // Test revenue distribution by non-owner
    function test_RevertWhen_DistributeRevenueNonOwner() public {
        uint256 projectId = createTestProject();
        uint256 tokenId = mintTestContent(projectId);

        vm.deal(nonOwner, 1 ether); // fund nonOwner for attempt
        vm.prank(nonOwner);
        vm.expectRevert("Not token owner");
        cr8rflow.distributeRevenue{value: 1 ether}(tokenId); // Should revert
    }

    // Test perk unlocking
    function testUnlockPerk() public {
        uint256 projectId = createTestProject();
        uint256 tokenId = mintTestContent(projectId);

        // Transfer NFT to fan
        vm.prank(creator);
        cr8rflow.transferFrom(creator, fan, tokenId);

        vm.prank(fan);
        vm.expectEmit(true, true, false, true);
        emit Cr8rFlow.PerkUnlocked(fan, tokenId, "Bonus Track");
        cr8rflow.unlockPerk(tokenId, 0);

        // Verify fan balance allows unlocking
        assertEq(cr8rflow.balanceOf(fan), 1, "Fan should own 1 NFT");
    }

    // Test perk unlocking with insufficient holdings
    function test_RevertWhen_UnlockPerkInsufficientHoldings() public {
        uint256 projectId = createTestProject();
        uint256 tokenId = mintTestContent(projectId);

        vm.prank(fan);
        vm.expectRevert("Insufficient NFT holdings");
        cr8rflow.unlockPerk(tokenId, 1); // Requires 2 NFTs, fan has 0, should revert
    }

    // Test perk unlocking for inactive tier
    function test_RevertWhen_UnlockPerkInactiveTier() public {
        uint256 projectId = createTestProject();
        address[] memory contributors = new address[](1);
        contributors[0] = contributor1;
        uint256[] memory percentages = new uint256[](1);
        percentages[0] = 10000;
        Cr8rFlow.Tier[] memory tiers = new Cr8rFlow.Tier[](1);
        tiers[0] = Cr8rFlow.Tier("Inactive Perk", 1, false); // Inactive tier
        vm.prank(creator);
        uint256 tokenId = cr8rflow.mintContent(projectId, "ipfs://test-uri", contributors, percentages, tiers);

        vm.prank(creator);
        cr8rflow.transferFrom(creator, fan, tokenId);

        vm.prank(fan);
        vm.expectRevert("Perk is not active");
        cr8rflow.unlockPerk(tokenId, 0); // Should revert
    }

    // Test engagement tracking
    function testTrackEngagement() public {
        vm.prank(cr8rflow.owner());
        vm.expectEmit(true, false, false, true);
        emit Cr8rFlow.EngagementTracked(fan, 1);
        cr8rflow.trackEngagement(fan);

        assertEq(cr8rflow.fanEngagement(fan), 1, "Engagement score incorrect");
    }

    // Test engagement tracking by non-owner
    function test_RevertWhen_TrackEngagementNonOwner() public {
        vm.prank(nonOwner);
        vm.expectRevert("OwnableUnauthorizedAccount(0x0000000000000000000000000000000000000005)");
        cr8rflow.trackEngagement(fan); // Should revert
    }

    // Test token URI
    function testTokenURI() public {
        uint256 projectId = createTestProject();
        uint256 tokenId = mintTestContent(projectId);
        assertEq(cr8rflow.tokenURI(tokenId), "ipfs://test-uri", "Token URI incorrect");
    }

    // Test token URI for non-existent token
    function test_RevertWhen_TokenURIInvalidToken() public {
        vm.expectRevert("Token does not exist");
        cr8rflow.tokenURI(999); // Should revert
    }

    // Test fallback function
    function test_RevertWhen_ReceiveEther() public {
        vm.prank(creator);
        vm.expectRevert("Use distributeRevenue to send funds");
        (bool sent,) = address(cr8rflow).call{value: 1 ether}("");
    }
}
