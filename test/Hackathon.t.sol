// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../lib/forge-std/src/Test.sol";
import "../src/Hackathon.sol";

contract HackathonCrowdfundingTest is Test {
    HackathonCrowdfunding hackathon;

    address organizer = address(0x1); // Organizer address
    address hacker1 = address(0x2); // Hacker 1
    address hacker2 = address(0x3); // Hacker 2
    address sponsor1 = address(0x4); // Sponsor 1
    address sponsor2 = address(0x5); // Sponsor 2

    function setUp() public {
        // Deploy the HackathonCrowdfunding contract and simulate the organizer
        vm.prank(organizer);
        hackathon = new HackathonCrowdfunding(
            0x123456789aBCdEF123456789aBCdef123456789A, // LINK token address
            0xABcdEFABcdEFabcdEfAbCdefabcdeFABcDEFabCD, // Oracle address
            "0x1234abcd5678efgh9012ijklmnopqrstuvwx3456", // Job ID
            0.1 ether // Chainlink fee
        );
    }

    function testRegisterHacker() public {
        vm.prank(hacker1);
        hackathon.registerHacker(
            "Hacker1",
            "hacker1@email.com",
            "Project1",
            10 ether,
            2000
        );

        (
            string memory name,
            string memory email,
            string memory projectDescription,
            ,
            uint256 requestedAmount,
            ,
            ,

        ) = hackathon.hackers(hacker1);

        assertEq(name, "Hacker1");
        assertEq(email, "hacker1@email.com");
        assertEq(projectDescription, "Project1");
        assertEq(requestedAmount, 10 ether);
    }

    function testFundHacker() public {
        vm.prank(hacker1);
        hackathon.registerHacker(
            "Hacker1",
            "hacker1@email.com",
            "Project1",
            10 ether,
            2000
        );

        vm.deal(sponsor1, 5 ether);
        vm.prank(sponsor1);
        hackathon.fundHacker{value: 5 ether}(hacker1);

        (, , , , , uint256 receivedAmount, , ) = hackathon.hackers(hacker1);
        assertEq(receivedAmount, 5 ether, "Hacker should receive 5 ether");
    }

    function testWithdrawFunds() public {
        vm.prank(hacker1);
        hackathon.registerHacker(
            "Hacker1",
            "hacker1@email.com",
            "Project1",
            10 ether,
            2000
        );

        vm.deal(sponsor1, 5 ether);
        vm.prank(sponsor1);
        hackathon.fundHacker{value: 5 ether}(hacker1);

        vm.prank(hacker1);
        hackathon.withdrawFunds(payable(hacker1), 3 ether);

        assertEq(
            hacker1.balance,
            3 ether,
            "Hacker1 should have withdrawn 3 ether"
        );
    }

    function testDepositPrize() public {
        vm.deal(organizer, 10 ether);
        vm.prank(hacker1);
        hackathon.registerHacker(
            "Hacker1",
            "hacker1@email.com",
            "Project1",
            10 ether,
            2000
        );

        vm.prank(organizer);
        hackathon.depositPrize{value: 10 ether}(hacker1);

        assertEq(
            address(hackathon).balance,
            10 ether,
            "Prize should be stored in the contract"
        );
    }

    function testClaimPrize() public {
        vm.prank(hacker1);
        hackathon.registerHacker(
            "Hacker1",
            "hacker1@email.com",
            "Project1",
            10 ether,
            2000
        );

        vm.deal(sponsor1, 5 ether);
        vm.prank(sponsor1);
        hackathon.fundHacker{value: 5 ether}(hacker1);

        vm.deal(sponsor2, 5 ether);
        vm.prank(sponsor2);
        hackathon.fundHacker{value: 5 ether}(hacker1);

        vm.deal(organizer, 10 ether);
        vm.prank(organizer);
        hackathon.depositPrize{value: 10 ether}(hacker1);

        vm.deal(hacker1, 0);
        vm.deal(sponsor1, 0);
        vm.deal(sponsor2, 0);

        vm.prank(hacker1);
        hackathon.claimPrize(payable(hacker1));

        assertEq(
            sponsor1.balance,
            5 ether,
            "Sponsor1 should have received 5 ether"
        );
        assertEq(
            sponsor2.balance,
            5 ether,
            "Sponsor2 should have received 5 ether"
        );
        assertEq(
            hacker1.balance,
            10 ether,
            "Hacker1 should have received 10 ether"
        );
    }

    function testSponsorCannotOverfund() public {
        vm.prank(hacker1);
        hackathon.registerHacker(
            "Hacker1",
            "hacker1@email.com",
            "Project1",
            10 ether,
            2000
        );

        vm.deal(sponsor1, 15 ether);
        vm.prank(sponsor1);

        // Expect revert if funding exceeds requested amount
        vm.expectRevert("Funding exceeds requested amount");
        hackathon.fundHacker{value: 15 ether}(hacker1);
    }
}
