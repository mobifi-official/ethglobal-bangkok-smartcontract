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
        address[] sponsorList; // List of sponsors
        bytes32 s_lastRequestId;
    }

    address private oracle;
    bytes32 private jobId;
    uint256 private fee;

    uint256 private chainLinkId = 3941;

    address private sepoliaROuter = 0xb83E47C2bC239B3bf370bc41e1459A34b41238D0;

    uint32 private gasLimit = 300000;
    bytes32 private donID =
        0x66756e2d657468657265756d2d7365706f6c69612d3100000000000000000000;

    mapping(bytes32 => bool) public bookingStatus;

    mapping(address => Hacker) public hackers;
    mapping(bytes32 => Hacker) public hackersRequestId;
    mapping(address => uint256) public sponsorBalances;

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

    constructor() FunctionsClient(sepoliaROuter) ConfirmedOwner(msg.sender) {}

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
        uint256 _prizePercentageForSponsor
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
        hacker.prizePercentageForSponsor = _prizePercentageForSponsor;
        hacker.exists = true;

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

    function bookingAccomodation(
        string[] calldata args
    ) external onlyHacker(msg.sender) {
        string detripBooking = "const bookHash = args[0];"
        "const guestName = args[1];"
        "const hotelId = args[2];"
        "const apiResponse = await Functions.makeHttpRequest({"
        "url: 'https://dev-api.mobifi.info/api/v2/hotel/booking',"
        "method: 'POST',"
        "headers: { 'Content-Type': 'application/json' },"
        "data: {"
        "hotel_id: hotelId,"
        "hotel_name: 'Test Hotel (Do Not Book)',"
        "hotel_address: '123 Moscow street, Belogorsk',"
        "hotel_booking_rate: {},"
        "checkin: '2024-12-14',"
        "checkout: '2024-12-15',"
        "currency: 'EUR',"
        "user_billing_detail: {},"
        "guest_detail: [{"
        "first_name: guestName.split(' ')[0],"
        "last_name: guestName.split(' ')[1] || '',"
        "is_child: false,"
        "age: 20"
        "}],"
        "book_hash: bookHash"
        "}"
        "});"
        "if (apiResponse.error) {"
        "throw Error('Request failed');"
        "}"
        "const { data } = apiResponse;"
        "return Functions.encodeString(JSON.stringify(data));";

        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(detripBooking); // Initialize the request with JS code
        if (args.length > 0) req.setArgs(args); // Set the arguments for the request

        Hacker storage hacker = hackers[msg.sender];

        // Send the request and store the request ID
        hacker.s_lastRequestId = _sendRequest(
            req.encodeCBOR(),
            chainLinkId,
            gasLimit,
            donID
        );

        return hacker.s_lastRequestId;
    }

    function fulfillRequest(
        bytes32 requestId,
        bytes memory response,
        bytes memory err
    ) internal override {
        Hacker storage hacker = requestId[requestId]; // I want to find the hacker
        if (hacker.s_lastRequestId != requestId) {
            revert UnexpectedRequestID(requestId); // Check if request IDs match
        }
        // Update the contract's state variables with the response and any errors
        s_lastResponse = response;
        s_lastError = err;

        // Emit an event to log the response
        emit Response(requestId, s_lastResponse, s_lastError);

        address targetContractAddress = 0x6F003fe9Fe4dd0d28DcA1749Fef54ec57fd3BCD2;

        // Call target contract if address is set
        if (targetContractAddress != address(0)) {
            ITargetContract(targetContractAddress).targetMethod(response);
        }
    }

    function depositPrize(address _hackerAddress) external payable {
        require(hackers[_hackerAddress].exists, "Hacker does not exist.");
        require(msg.value > 0, "Prize amount must be greater than zero.");

        emit PrizeDeposited(_hackerAddress, msg.value);
    }

    function claimPrize(address payable _hackerAddress) external {
        require(hackers[_hackerAddress].exists, "Hacker does not exist.");
        require(address(this).balance > 0, "No prize available.");

        bool success = false;

        Hacker storage hacker = hackers[_hackerAddress];
        uint256 totalPrize = address(this).balance;
        uint256 sponsorTotalContribution;

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
}
