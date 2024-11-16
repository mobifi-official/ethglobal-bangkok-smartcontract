// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../lib/forge-std/src/Script.sol";
import "../src/Hackathon.sol";

contract DeployHackathon is Script {
    function run() external {
        // Start broadcasting (deploy transaction)
        vm.startBroadcast();

        // Deploy the contract with constructor arguments
        HackathonCrowdfunding hackathon = new HackathonCrowdfunding();

        console.log("HackathonCrowdfunding deployed at:", address(hackathon));

        // Stop broadcasting
        vm.stopBroadcast();
    }
}
