// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/Hackathon.sol";

contract HackathonCrowdfundingTest is Test {
    HackathonCrowdfunding public hackathon;

    address owner = address(0x1);
    address hacker1 = address(0x2);
    address hacker2 = address(0x3);
    address sponsor1 = address(0x4);
    address sponsor2 = address(0x5);

    function setUp() public {
        vm.prank(owner);
        hackathon = new HackathonCrowdfunding();
    }

    function testRegisterHacker() public {
        vm.prank(hacker1);
        string[] memory hackerProfile = new string[](1);
        string;
        hackerProfile[0] = "GitHub: hacker1";
        hackerProfile[1] = "LinkedIn: hacker1";

        hackathon.registerHacker(
            "Hacker One",
            "hacker1@example.com",
            "Project 1",
            100 ether,
            2000,
            hackerProfile
        );

        HackathonCrowdfunding.Hacker string[] hacker = hackathon.hackers(hacker1);
        assertEq(hacker.name, "Hacker One");
        assertEq(hacker.email, "hacker1@example.com");
        assertEq(hacker.projectDescription, "Project 1");
        assertEq(hacker.requestedAmount, 100 ether);
    }

    function testFundHacker() public {
        testRegisterHacker();

        vm.prank(sponsor1);
        hackathon.fundHacker{value: 10 ether}(hacker1);

        (, , , , uint256 receivedAmount, , , , ) = hackathon.hackers(hacker1);
        assertEq(receivedAmount, 10 ether);

        uint256 sponsorBalance = hackathon.sponsorBalances(sponsor1);
        assertEq(sponsorBalance, 10 ether);
    }

    function testGetAllHackers() public {
        testRegisterHacker();

        vm.prank(hacker2);
        string[] memory hackerProfile = new string[](1);
        hackerProfile[0] = "GitHub: hacker2";
        hackathon.registerHacker(
            "Hacker Two",
            "hacker2@example.com",
            "Project 2",
            50 ether,
            1500,
            hackerProfile
        );

        address[] memory hackers = hackathon.getAllHackers();
        assertEq(hackers.length, 2);
        assertEq(hackers[0], hacker1);
        assertEq(hackers[1], hacker2);
    }

    function testGetAllSponsors() public {
        testFundHacker();

        vm.prank(sponsor2);
        hackathon.fundHacker{value: 5 ether}(hacker1);

        address[] memory sponsors = hackathon.getAllSponsors(hacker1);
        assertEq(sponsors.length, 2);
        assertEq(sponsors[0], sponsor1);
        assertEq(sponsors[1], sponsor2);
    }

    function testClaimPrize() public {
        testFundHacker();

        uint256 initialBalance = hacker1.balance;
        vm.prank(owner);
        hackathon.depositPrize{value: 20 ether}(hacker1);

        vm.prank(hacker1);
        hackathon.claimPrize(payable(hacker1));

        uint256 finalBalance = hacker1.balance;
        assertEq(finalBalance, initialBalance + 20 ether);
    }
}
