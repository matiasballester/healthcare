// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract HealthCareRegistry { 
    enum Role {
        Patient,
        Doctor,
        NotDefined
    }

    struct Record { 
        string cid;
        string fileName; 
        address patientId;
        address doctorId;
        uint256 timeAdded;
    }

    struct Patient {
        address id;
        Record[] records;
        AuthorizedRelative[] authorizedRelatives;
    }

    struct Doctor {
        address id;
    }

    struct AuthorizedRelative {
        address id;
    }

    mapping (address => Patient) public patients;
    mapping (address => Doctor) public doctors;

    event PatientAdded(address patientId, uint256 timestamp);
    event DoctorAdded(address doctorId, uint256 timestamp);
    event RecordAdded(string cid, address patientId, address doctorId, uint256 timestamp); 
    event AuthorizedRelativeAdded(address patientId, address authorizedRelativeId, uint256 timestamp);

    modifier senderIsDoctor {
        require(doctors[msg.sender].id == msg.sender, "Sender is not a doctor");
        _;
    }

    modifier senderIsPatient {
        require(patients[msg.sender].id == msg.sender, "Sender is not a patient");
        _;
    }

    modifier senderExists {
        require(doctors[msg.sender].id == msg.sender || patients[msg.sender].id == msg.sender, "Sender does not exist");
        _;
    }

    modifier patientExists(address patientId) {
        require(patients[patientId].id == patientId, "Patient does not exist");
        _;
    }

    // Verify if the entity that wants to see patient records is authorized by him
    modifier isAuthorized(address patientId) {
        bool isAuth = false;
        for (uint i = 0; i < patients[patientId].authorizedRelatives.length; i++) {
            if (patients[patientId].authorizedRelatives[i].id == msg.sender) {
                isAuth = true;
                break;
            }
        }
        require(isAuth == true, "Not authorized");
        _;
    }

    function addDoctor() public {
        require(doctors[msg.sender].id != msg.sender, "This doctor already exists.");
        doctors[msg.sender].id = msg.sender;

        emit DoctorAdded(msg.sender, block.timestamp);
    }

    function addPatient() public {
        require(patients[msg.sender].id != msg.sender, "This patient already exists.");
        patients[msg.sender].id = msg.sender;
        addAuthorized(msg.sender, msg.sender);

        emit PatientAdded(msg.sender, block.timestamp);
    }

    function addPatient(address _patientId) public senderIsDoctor {
        require(patients[_patientId].id != _patientId, "This patient already exists.");
        patients[_patientId].id = _patientId;
        
        addAuthorized(_patientId, _patientId); 
        addAuthorized(_patientId, msg.sender);
        
        emit AuthorizedRelativeAdded(_patientId, msg.sender, block.timestamp);
        emit PatientAdded(_patientId, block.timestamp);
    }

    function addAuthorizedRelative(address _authorizedRelativeId) public senderIsPatient {
        AuthorizedRelative memory authorizedRelative = AuthorizedRelative(_authorizedRelativeId);
        patients[msg.sender].authorizedRelatives.push(authorizedRelative);

        emit AuthorizedRelativeAdded(msg.sender, _authorizedRelativeId, block.timestamp);
    }

    function addAuthorized(address _patientId, address _authorizedId) private {
        bool alreadyExists = false;
        AuthorizedRelative[] memory authorizedArray = getPatientAuthorized(_patientId);
        for (uint i = 0; i < authorizedArray.length; i++) {
            if (authorizedArray[i].id == _authorizedId) {
                alreadyExists = true;
                break;
            }
        }
        require(alreadyExists == false, "Authorized already exists for this patient");
        patients[_patientId].authorizedRelatives.push(AuthorizedRelative(_authorizedId));
    }

    function addRecord(string memory _cid, string memory _fileName, address _patientId) public senderIsDoctor patientExists(_patientId) {
        Record memory record = Record(_cid, _fileName, _patientId, msg.sender, block.timestamp);
        patients[_patientId].records.push(record);

        emit RecordAdded(_cid, _patientId, msg.sender, block.timestamp);
    } 

    function getRecords(address _patientId) public view senderExists patientExists(_patientId) isAuthorized(_patientId) returns (Record[] memory) {
        return patients[_patientId].records;
    } 

    function getPatientAuthorized(address _patientId) public view senderExists patientExists(_patientId) returns (AuthorizedRelative[] memory) {
        return patients[_patientId].authorizedRelatives;
    }

    function getSenderRole() public view returns (string memory) {
        Role role;
        if (doctors[msg.sender].id == msg.sender) {
            role = Role.Doctor;
        } else if (patients[msg.sender].id == msg.sender) {
            role = Role.Patient;
        } else {
            role = Role.NotDefined;
        }
        return getRoleByValue(role);
    }

    function getRoleByValue(Role _role) internal pure returns (string memory) {
        require(uint8(_role) <= 2);
        if (Role.Patient == _role) return "Patient";
        if (Role.Doctor == _role) return "Doctor";
        return "Not defined";
    }

    function getPatientExists(address _patientId) private view senderIsDoctor returns (bool) {
        return patients[_patientId].id == _patientId;
    }
}    
