// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/LandRegistry.sol";
import "../src/LandSwap.sol";
import "../src/UserRegistry.sol";

contract LandGrabTest is Test {
    LandRegistry public landRegistry;
    LandSwap public landSwap;
    UserRegistry public userRegistry;

    address public alice = address(1);
    address public bob = address(2);
    address public charlie = address(3);

    function setUp() public {
        landRegistry = new LandRegistry();
        landSwap = new LandSwap(address(landRegistry));
        userRegistry = new UserRegistry(address(landRegistry));

        // Set up contract dependencies
        landRegistry.setLandSwap(address(landSwap));
        landRegistry.setUserRegistry(address(userRegistry));
    }

    function testUserRegistration() public {
        vm.startPrank(alice);
        userRegistry.registerUser("alice");
        UserRegistry.User memory user = userRegistry.getUser(alice);
        assertEq(user.username, "alice");
        assertEq(user.isActive, true);
        assertEq(user.createdAt, block.timestamp);
        assertEq(user.lastActive, block.timestamp);
        vm.stopPrank();
    }

    function testInvalidUsernameRegistration() public {
        vm.startPrank(alice);
        // Test username too short
        vm.expectRevert("Invalid username format");
        userRegistry.registerUser("al");

        // Test username too long
        vm.expectRevert("Invalid username format");
        userRegistry.registerUser("thisusernameiswaytoolongforthecontract");

        // Test invalid characters
        vm.expectRevert("Invalid username format");
        userRegistry.registerUser("alice!");
        vm.stopPrank();
    }

    function testUsernameChange() public {
        vm.startPrank(alice);
        userRegistry.registerUser("alice");
        userRegistry.changeUsername("alice_new");
        UserRegistry.User memory user = userRegistry.getUser(alice);
        assertEq(user.username, "alice_new");
        assertEq(user.lastActive, block.timestamp);
        vm.stopPrank();
    }

    function testLandClaim() public {
        vm.startPrank(alice);
        userRegistry.registerUser("alice");
        landRegistry.claimLand("test.land.one");

        LandRegistry.Land memory land = landRegistry.getLandDetails(
            "test.land.one"
        );
        assertEq(land.owner, alice);
        assertEq(land.isClaimed, true);
        assertEq(land.claimedAt, block.timestamp);

        // Verify land is in user's array
        string[] memory userLands = landRegistry.getUserLands(alice);
        assertEq(userLands.length, 1);
        assertEq(userLands[0], "test.land.one");
        vm.stopPrank();
    }

    function testMultipleLandClaims() public {
        vm.startPrank(alice);
        userRegistry.registerUser("alice");

        // Claim multiple lands
        landRegistry.claimLand("land1");
        landRegistry.claimLand("land2");
        landRegistry.claimLand("land3");

        // Verify all lands are in user's array
        string[] memory userLands = landRegistry.getUserLands(alice);
        assertEq(userLands.length, 3);

        // Verify land details
        for (uint256 i = 0; i < userLands.length; i++) {
            LandRegistry.Land memory land = landRegistry.getLandDetails(
                userLands[i]
            );
            assertEq(land.owner, alice);
            assertEq(land.isClaimed, true);
        }
        vm.stopPrank();
    }

    function testLandRelease() public {
        vm.startPrank(alice);
        userRegistry.registerUser("alice");
        landRegistry.claimLand("test.land.one");
        landRegistry.claimLand("test.land.two");

        // Verify initial state
        string[] memory userLands = landRegistry.getUserLands(alice);
        assertEq(userLands.length, 2);

        // Release one land
        landRegistry.releaseLand("test.land.one");

        // Verify land is released
        LandRegistry.Land memory land = landRegistry.getLandDetails(
            "test.land.one"
        );
        assertEq(land.owner, address(0));
        assertEq(land.isClaimed, false);

        // Verify user's land array is updated
        userLands = landRegistry.getUserLands(alice);
        assertEq(userLands.length, 1);
        assertEq(userLands[0], "test.land.two");
        vm.stopPrank();
    }

    function testLandSwap() public {
        // Setup
        vm.startPrank(alice);
        userRegistry.registerUser("alice");
        landRegistry.claimLand("alice.land.one");
        vm.stopPrank();

        vm.startPrank(bob);
        userRegistry.registerUser("bob");
        landRegistry.claimLand("bob.land.one");
        vm.stopPrank();

        // Verify initial ownership
        string[] memory aliceLands = landRegistry.getUserLands(alice);
        string[] memory bobLands = landRegistry.getUserLands(bob);
        assertEq(aliceLands.length, 1);
        assertEq(bobLands.length, 1);
        assertEq(aliceLands[0], "alice.land.one");
        assertEq(bobLands[0], "bob.land.one");

        // Propose swap
        vm.startPrank(alice);
        landSwap.proposeSwap("alice.land.one", "bob.land.one");
        vm.stopPrank();

        // Approve swap
        vm.startPrank(bob);
        landSwap.approveSwap(alice);
        vm.stopPrank();

        // Verify swap
        LandRegistry.Land memory aliceLand = landRegistry.getLandDetails(
            "bob.land.one"
        );
        LandRegistry.Land memory bobLand = landRegistry.getLandDetails(
            "alice.land.one"
        );
        assertEq(aliceLand.owner, alice);
        assertEq(bobLand.owner, bob);

        // Verify land arrays are updated
        aliceLands = landRegistry.getUserLands(alice);
        bobLands = landRegistry.getUserLands(bob);
        assertEq(aliceLands.length, 1);
        assertEq(bobLands.length, 1);
        assertEq(aliceLands[0], "bob.land.one");
        assertEq(bobLands[0], "alice.land.one");
    }

    function testSwapExpiration() public {
        // Setup
        vm.startPrank(alice);
        userRegistry.registerUser("alice");
        landRegistry.claimLand("alice.land.one");
        vm.stopPrank();

        vm.startPrank(bob);
        userRegistry.registerUser("bob");
        landRegistry.claimLand("bob.land.one");
        vm.stopPrank();

        // Propose swap
        vm.startPrank(alice);
        landSwap.proposeSwap("alice.land.one", "bob.land.one");
        vm.stopPrank();

        // Fast forward past expiration
        vm.warp(block.timestamp + landSwap.SWAP_EXPIRY_TIME() + 1);

        // Try to approve swap
        vm.startPrank(bob);
        vm.expectRevert("Swap proposal expired");
        landSwap.approveSwap(alice);
        vm.stopPrank();

        // Verify ownership remains unchanged
        string[] memory aliceLands = landRegistry.getUserLands(alice);
        string[] memory bobLands = landRegistry.getUserLands(bob);
        assertEq(aliceLands.length, 1);
        assertEq(bobLands.length, 1);
        assertEq(aliceLands[0], "alice.land.one");
        assertEq(bobLands[0], "bob.land.one");
    }

    function testUserDeletion() public {
        vm.startPrank(alice);
        userRegistry.registerUser("alice");
        landRegistry.claimLand("test.land.one");
        landRegistry.claimLand("test.land.two");

        // Verify user exists and owns lands
        UserRegistry.User memory user = userRegistry.getUser(alice);
        assertEq(user.isActive, true);
        assertEq(user.username, "alice");

        string[] memory userLands = landRegistry.getUserLands(alice);
        assertEq(userLands.length, 2);

        // Delete user
        userRegistry.deleteUser();

        // Verify user is deleted
        user = userRegistry.getUser(alice);
        assertEq(user.isActive, false);
        assertEq(user.username, "");
        assertEq(user.createdAt, 0);
        assertEq(user.lastActive, 0);

        // Verify lands are released
        LandRegistry.Land memory land1 = landRegistry.getLandDetails(
            "test.land.one"
        );
        LandRegistry.Land memory land2 = landRegistry.getLandDetails(
            "test.land.two"
        );
        assertEq(land1.owner, address(0));
        assertEq(land1.isClaimed, false);
        assertEq(land2.owner, address(0));
        assertEq(land2.isClaimed, false);

        // Verify user has no lands
        userLands = landRegistry.getUserLands(alice);
        assertEq(userLands.length, 0);

        // Verify username is no longer associated
        address userAddress = userRegistry.usernameToAddress("alice");
        assertEq(userAddress, address(0));

        vm.stopPrank();
    }

    function testBatchLandUpdate() public {
        vm.startPrank(alice);
        userRegistry.registerUser("alice");
        landRegistry.claimLand("land1");
        landRegistry.claimLand("land2");
        vm.stopPrank();

        vm.startPrank(bob);
        userRegistry.registerUser("bob");
        vm.stopPrank();

        // Verify initial state
        string[] memory aliceLands = landRegistry.getUserLands(alice);
        assertEq(aliceLands.length, 2);

        // Batch update lands
        string[] memory lands = new string[](2);
        lands[0] = "land1";
        lands[1] = "land2";

        vm.prank(address(landSwap));
        landRegistry.batchUpdateLands(lands, bob);

        // Verify ownership
        assertEq(landRegistry.getLandDetails("land1").owner, bob);
        assertEq(landRegistry.getLandDetails("land2").owner, bob);

        // Verify land arrays are updated
        aliceLands = landRegistry.getUserLands(alice);
        string[] memory bobLands = landRegistry.getUserLands(bob);
        assertEq(aliceLands.length, 0);
        assertEq(bobLands.length, 2);
    }
}
