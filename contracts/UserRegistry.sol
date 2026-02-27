// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract UserRegistry {

    address public insurer;

    // ================================
    // PATIENT STRUCT
    // ================================
    struct Patient {
        uint patientId;

        // 1. BASIC DETAILS
        string name;
        string dob;
        string gender;
        string mobile;
        string email;
        string location;

        // 2. OTP VERIFICATION
        bool otpVerified;

        // 3. AADHAAR VERIFICATION
        string aadharHash;

        // 4. FACE RECOGNITION
        string photoHash;

        // SYSTEM FIELDS
        address walletAddress;
        string status;
        uint timestamp;
    }

    // ================================
    // INPUT STRUCT
    // (fixes stack too deep error)
    // ================================
    struct PatientInput {
        string name;
        string dob;
        string gender;
        string mobile;
        string email;
        string location;
        bool otpVerified;
        string aadharHash;
        string photoHash;
    }

    // ================================
    // STORAGE
    // ================================
    uint public patientCount = 0;

    mapping(address => Patient) public patients;
    mapping(address => bool) public isRegistered;
    mapping(address => bool) public isApproved;
    mapping(string => bool) public aadharExists;

    address[] public pendingPatients;
    address[] public allPatients;

    // ================================
    // EVENTS
    // ================================
    event PatientRegistered(
        uint patientId,
        string name,
        address walletAddress,
        uint timestamp
    );

    event PatientApproved(
        address walletAddress,
        string name,
        uint timestamp
    );

    event PatientRejected(
        address walletAddress,
        string name,
        uint timestamp
    );

    // ================================
    // MODIFIER
    // ================================
    modifier onlyInsurer() {
        require(
            msg.sender == insurer,
            "Only insurer can do this"
        );
        _;
    }

    // ================================
    // CONSTRUCTOR
    // ================================
    constructor() {
        insurer = msg.sender;
    }

    // ================================
    // REGISTER PATIENT
    // uses struct input to avoid
    // stack too deep error
    // ================================
    function registerPatient(
        PatientInput memory input
    ) public {

        // checks
        require(
            !isRegistered[msg.sender],
            "Patient already registered"
        );

        require(
            !aadharExists[input.aadharHash],
            "Aadhar already registered"
        );

        require(
            input.otpVerified == true,
            "OTP not verified"
        );

        require(
            bytes(input.photoHash).length > 0,
            "Photo not uploaded"
        );

        require(
            bytes(input.aadharHash).length > 0,
            "Aadhar not provided"
        );

        // increment count
        patientCount++;

        // store patient
        patients[msg.sender] = Patient(
            patientCount,
            input.name,
            input.dob,
            input.gender,
            input.mobile,
            input.email,
            input.location,
            input.otpVerified,
            input.aadharHash,
            input.photoHash,
            msg.sender,
            "Pending",
            block.timestamp
        );

        // update mappings
        isRegistered[msg.sender] = true;
        aadharExists[input.aadharHash] = true;

        // add to lists
        pendingPatients.push(msg.sender);
        allPatients.push(msg.sender);

        // emit event
        emit PatientRegistered(
            patientCount,
            input.name,
            msg.sender,
            block.timestamp
        );
    }

    // ================================
    // APPROVE PATIENT
    // only insurer can call
    // ================================
    function approvePatient(
        address _walletAddress
    ) public onlyInsurer {

        require(
            isRegistered[_walletAddress],
            "Patient not registered"
        );

        require(
            !isApproved[_walletAddress],
            "Patient already approved"
        );

        patients[_walletAddress].status = "Approved";
        isApproved[_walletAddress] = true;

        emit PatientApproved(
            _walletAddress,
            patients[_walletAddress].name,
            block.timestamp
        );
    }

    // ================================
    // REJECT PATIENT
    // only insurer can call
    // ================================
    function rejectPatient(
        address _walletAddress
    ) public onlyInsurer {

        require(
            isRegistered[_walletAddress],
            "Patient not registered"
        );

        patients[_walletAddress].status = "Rejected";

        emit PatientRejected(
            _walletAddress,
            patients[_walletAddress].name,
            block.timestamp
        );
    }

    // ================================
    // GET PATIENT DETAILS
    // ================================
    function getPatient(
        address _walletAddress
    ) public view returns (Patient memory) {

        require(
            isRegistered[_walletAddress],
            "Patient not registered"
        );

        return patients[_walletAddress];
    }

    // ================================
    // GET PENDING PATIENTS
    // ================================
    function getPendingPatients()
        public
        view
        returns (address[] memory)
    {
        return pendingPatients;
    }

    // ================================
    // GET ALL PATIENTS
    // ================================
    function getAllPatients()
        public
        view
        returns (address[] memory)
    {
        return allPatients;
    }

    // ================================
    // CHECK IF PATIENT APPROVED
    // ================================
    function checkPatientApproved(
        address _walletAddress
    ) public view returns (bool) {
        return isApproved[_walletAddress];
    }

    // ================================
    // CHECK IF PATIENT REGISTERED
    // ================================
    function checkPatientRegistered(
        address _walletAddress
    ) public view returns (bool) {
        return isRegistered[_walletAddress];
    }
}
