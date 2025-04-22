// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/LandRegistry.sol";
import "../src/LandSwap.sol";
import "../src/UserRegistry.sol";

contract DeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy LandRegistry
        LandRegistry landRegistry = new LandRegistry();
        console.log("LandRegistry deployed at:", address(landRegistry));

        // Deploy LandSwap
        LandSwap landSwap = new LandSwap(address(landRegistry));
        console.log("LandSwap deployed at:", address(landSwap));

        // Set LandSwap address in LandRegistry
        landRegistry.setLandSwap(address(landSwap));
        console.log("LandSwap address set in LandRegistry");

        // Deploy UserRegistry
        UserRegistry userRegistry = new UserRegistry(address(landRegistry));
        console.log("UserRegistry deployed at:", address(userRegistry));

        // Set UserRegistry address in LandRegistry
        landRegistry.setUserRegistry(address(userRegistry));
        console.log("UserRegistry address set in LandRegistry");

        vm.stopBroadcast();
    }
}
