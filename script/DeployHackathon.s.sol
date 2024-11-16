// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../lib/forge-std/src/Script.sol";
import "../src/Hackathon.sol";

contract DeployHackathon is Script {
    function run() external {
        // Load environment variables or hardcoded values
        address linkToken = vm.envAddress("LINK_TOKEN");
        address oracle = vm.envAddress("ORACLE_ADDRESS");
        bytes32 jobId = vm.envBytes32("JOB_ID");
        uint256 fee = vm.envUint("FEE"); // Fee in LINK tokens

        // Start broadcasting (deploy transaction)
        vm.startBroadcast();

        // Deploy the contract with constructor arguments
        HackathonCrowdfunding hackathon = new HackathonCrowdfunding(
            linkToken,
            oracle,
            jobId,
            fee
        );

        console.log("HackathonCrowdfunding deployed at:", address(hackathon));

        // Stop broadcasting
        vm.stopBroadcast();
    }
}
