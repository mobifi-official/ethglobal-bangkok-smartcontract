// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {FunctionsClient} from "@chainlink/contracts/v0.8/functions/dev/v1_0_0/FunctionsClient.sol";
import {ConfirmedOwner} from "@chainlink/contracts/v0.8/shared/access/ConfirmedOwner.sol";
import {FunctionsRequest} from "@chainlink/contracts/v0.8/functions/dev/v1_0_0/libraries/FunctionsRequest.sol";

contract HackathonCrowdfunding is FunctionsClient, ConfirmedOwner {
    using FunctionsRequest for FunctionsRequest.Request;

    struct Hacker {
        string name;
        string email;
        string projectDescription;
        string[] hackerProfile;
        address hackerAddress;
        uint256 requestedAmount;
        uint256 receivedAmount;
        uint256 prizePercentageForSponsor; // Basis points (e.g., 20% = 2000)
        bool exists;
        mapping(address => uint256) sponsorContributions;
        address[] sponsorList;
        bytes32 lastRequestId;
    }

    address private immutable oracle;
    uint64 private immutable chainLinkId = 3941;
    uint32 private immutable gasLimit = 300000;
    bytes32 private immutable donID =
        0x66756e2d657468657265756d2d7365706f6c69612d3100000000000000000000;

    address router = 0xb83E47C2bC239B3bf370bc41e1459A34b41238D0;

    mapping(bytes32 => bool) public bookingStatus;
    mapping(address => Hacker) public hackers;
    mapping(bytes32 => address) public requestToHacker;
    mapping(address => uint256) public sponsorBalances;

    address[] private hackerAddresses;

    event HackerRegistered(
        address indexed hacker,
        string name,
        uint256 requestedAmount
    );
    event SponsorFunded(
        address indexed sponsor,
        address indexed hacker,
        uint256 amount
    );
    event PrizeDeposited(address indexed hacker, uint256 amount);
    event FundsWithdrawn(
        address indexed hacker,
        address indexed recipient,
        uint256 amount
    );
    event BookingRequestSent(bytes32 indexed requestId);
    event BookingResponseReceived(bytes32 indexed requestId, bool success);

    constructor() FunctionsClient(router) ConfirmedOwner(msg.sender) {}

    modifier onlyHacker(address hackerAddress) {
        require(
            msg.sender == hackerAddress,
            "Only the hacker can perform this action."
        );
        _;
    }

    function registerHacker(
        string memory _name,
        string memory _email,
        string memory _projectDescription,
        uint256 _requestedAmount,
        uint256 _prizePercentageForSponsor,
        string[] memory _hackerProfile
    ) external {
        require(!hackers[msg.sender].exists, "Hacker already registered.");
        require(
            _prizePercentageForSponsor <= 10000,
            "Percentage cannot exceed 100%."
        );

        Hacker storage hacker = hackers[msg.sender];
        hacker.name = _name;
        hacker.email = _email;
        hacker.projectDescription = _projectDescription;
        hacker.hackerAddress = msg.sender;
        hacker.requestedAmount = _requestedAmount;
        hacker.receivedAmount = 0;
        hacker.hackerProfile = _hackerProfile;
        hacker.prizePercentageForSponsor = _prizePercentageForSponsor;
        hacker.exists = true;

        hackerAddresses.push(msg.sender);

        emit HackerRegistered(msg.sender, _name, _requestedAmount);
    }

    function fundHacker(address _hackerAddress) external payable {
        require(hackers[_hackerAddress].exists, "Hacker does not exist.");
        require(msg.value > 0, "Funding amount must be greater than zero.");

        Hacker storage hacker = hackers[_hackerAddress];
        hacker.receivedAmount += msg.value;

        if (hacker.sponsorContributions[msg.sender] == 0) {
            hacker.sponsorList.push(msg.sender);
        }

        hacker.sponsorContributions[msg.sender] += msg.value;
        sponsorBalances[msg.sender] += msg.value;

        emit SponsorFunded(msg.sender, _hackerAddress, msg.value);
    }

    function bookingAccommodation(
        string[] calldata args
    ) external onlyHacker(msg.sender) {
        require(args.length == 5, "Invalid number of arguments.");

        string memory detripBooking = "const bookHash = args[0];"
        "const guestName = args[1];"
        "const hotelId = args[2];"
        "const checkInTime = args[3];"
        "const checkOutTime = args[4];"
        "const apiResponse = await Functions.makeHttpRequest({"
        "url: 'https://dev-api.mobifi.info/api/v2/hotel/booking',"
        "method: 'POST',"
        "headers: { 'Content-Type': 'application/json' },"
        "data: {"
        "hotel_id: hotelId,"
        "hotel_name: 'Test Hotel (Do Not Book)',"
        "hotel_address: '123 Moscow street, Belogorsk',"
        "checkin: checkInTime,"
        "checkout: checkOutTime,"
        "guest_detail: [{"
        "first_name: guestName,"
        "last_name: guestName,"
        "is_child: false,"
        "age: 20"
        "}],"
        "book_hash: bookHash"
        "}"
        "});"
        "if (apiResponse.error) {"
        "return Functions.encodeString('Error: Request failed');"
        "}"
        "return Functions.encodeString(JSON.stringify(apiResponse.data));";

        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(detripBooking);
        req.setArgs(args);

        Hacker storage hacker = hackers[msg.sender];
        bytes32 requestId = _sendRequest(
            req.encodeCBOR(),
            chainLinkId,
            gasLimit,
            donID
        );

        hacker.lastRequestId = requestId;
        requestToHacker[requestId] = msg.sender;

        emit BookingRequestSent(requestId);
    }

    function fulfillRequest(
        bytes32 requestId,
        bytes memory _response,
        bytes memory err
    ) internal override {
        address hackerAddress = requestToHacker[requestId];
        require(hackerAddress != address(0), "Request ID not recognized.");

        Hacker storage hacker = hackers[hackerAddress];
        require(hacker.lastRequestId == requestId, "Unexpected request ID.");

        // Process the response
        // Add logic to handle response if needed

        emit BookingResponseReceived(requestId, err.length == 0);
    }

    function depositPrize(address _hackerAddress) external payable {
        require(hackers[_hackerAddress].exists, "Hacker does not exist.");
        require(msg.value > 0, "Prize amount must be greater than zero.");

        emit PrizeDeposited(_hackerAddress, msg.value);
    }

    function claimPrize(address payable _hackerAddress) external {
        require(hackers[_hackerAddress].exists, "Hacker does not exist.");
        require(address(this).balance > 0, "No prize available.");

        Hacker storage hacker = hackers[_hackerAddress];
        uint256 totalPrize = address(this).balance;
        uint256 sponsorTotalContribution;

        bool success = false;

        for (uint256 i = 0; i < hacker.sponsorList.length; i++) {
            sponsorTotalContribution += hacker.sponsorContributions[
                hacker.sponsorList[i]
            ];
        }

        for (uint256 i = 0; i < hacker.sponsorList.length; i++) {
            address sponsor = hacker.sponsorList[i];
            uint256 sponsorShare = (totalPrize *
                hacker.sponsorContributions[sponsor]) /
                sponsorTotalContribution;
            (success, ) = payable(sponsor).call{value: sponsorShare}("");
            require(success, "Sponsor transfer failed.");
        }

        uint256 hackerShare = totalPrize - sponsorTotalContribution;
        (success, ) = _hackerAddress.call{value: hackerShare}("");
        require(success, "Hacker transfer failed.");
    }

    function getAllHackers() external view returns (address[] memory) {
        return hackerAddresses;
    }

    function getAllSponsors(
        address _hackerAddress
    ) external view returns (address[] memory) {
        require(hackers[_hackerAddress].exists, "Hacker does not exist.");
        return hackers[_hackerAddress].sponsorList;
    }
}
