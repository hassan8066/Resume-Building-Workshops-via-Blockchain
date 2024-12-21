// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ResumeWorkshop {

    struct Workshop {
        uint id;
        string name;
        string description;
        address host;
        uint price;
        uint startTime;
        uint participantLimit;
        uint participantCount;
    }

    struct Participant {
        address walletAddress;
        bool attended;
    }

    uint public workshopCounter;
    mapping(uint => Workshop) public workshops;
    mapping(uint => mapping(address => Participant)) public workshopParticipants;

    event WorkshopCreated(
        uint id,
        string name,
        string description,
        address host,
        uint price,
        uint startTime,
        uint participantLimit
    );

    event ParticipantRegistered(
        uint workshopId,
        address participant
    );

    event WorkshopCompleted(
        uint workshopId,
        address host
    );

    modifier onlyHost(uint workshopId) {
        require(msg.sender == workshops[workshopId].host, "Only the host can perform this action.");
        _;
    }

    modifier isParticipant(uint workshopId) {
        require(workshopParticipants[workshopId][msg.sender].walletAddress == msg.sender, "You are not a registered participant.");
        _;
    }

    function createWorkshop(
        string memory name,
        string memory description,
        uint price,
        uint startTime,
        uint participantLimit
    ) public {
        require(startTime > block.timestamp, "Start time must be in the future.");
        require(participantLimit > 0, "Participant limit must be greater than zero.");

        workshopCounter++;
        workshops[workshopCounter] = Workshop({
            id: workshopCounter,
            name: name,
            description: description,
            host: msg.sender,
            price: price,
            startTime: startTime,
            participantLimit: participantLimit,
            participantCount: 0
        });

        emit WorkshopCreated(workshopCounter, name, description, msg.sender, price, startTime, participantLimit);
    }

    function registerForWorkshop(uint workshopId) public payable {
        Workshop storage workshop = workshops[workshopId];
        require(workshop.id != 0, "Workshop does not exist.");
        require(block.timestamp < workshop.startTime, "Registration is closed.");
        require(workshop.participantCount < workshop.participantLimit, "Workshop is full.");
        require(msg.value == workshop.price, "Incorrect payment amount.");

        workshop.participantCount++;
        workshopParticipants[workshopId][msg.sender] = Participant({
            walletAddress: msg.sender,
            attended: false
        });

        emit ParticipantRegistered(workshopId, msg.sender);
    }

    function markAttendance(uint workshopId, address participantAddress) public onlyHost(workshopId) {
        Participant storage participant = workshopParticipants[workshopId][participantAddress];
        require(participant.walletAddress != address(0), "Participant is not registered.");
        require(!participant.attended, "Attendance already marked.");

        participant.attended = true;
    }

    function finalizeWorkshop(uint workshopId) public onlyHost(workshopId) {
        require(block.timestamp > workshops[workshopId].startTime, "Workshop has not yet started.");
        
        payable(workshops[workshopId].host).transfer(workshops[workshopId].price * workshops[workshopId].participantCount);
        emit WorkshopCompleted(workshopId, workshops[workshopId].host);
    }
}
