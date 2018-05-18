pragma solidity ^0.4.21;
contract Titles {
    
    address[] ownerIDs;
    address[] adminIDs;
    address state;
    
    //add events here
    
    enum StatusCodes { active, ownerFlag, adminFlag, initFlag, plateFlag, deactivated }

    struct Owner {
        address ownerID;
        address insurance;
        string name;
        string physicalAddress;
        bytes17[] vehicleIDs;
        StatusCodes status;
        bool registrar;
    }
    
    
    struct Vehicle {
        address ownerID;
        bytes17 VIN;
        string make;
        uint16 year;
        string licensePlate;
        StatusCodes status;
        uint[] serviceRecord;
        uint[] damageRecord;
    }
    
    struct Admin {
        address adminID;
        string name;
        string position;
        string contact;
        StatusCodes status;
        //powers
        bool ownerInit;
        bool setOwnerStatus;
        bool setVehicleStatus;
        bool setLicensePlate;
        bool registrar;
        bool appendService;
        bool appendDamage;
    }
    
    
    struct vehicleEvent {
        uint timestamp;
        string description;
        address signer;
    }
    
    mapping (address => Owner) public owners;
    mapping (bytes17 => Vehicle) public vehicles;
    mapping (address => Admin) public admins;
    mapping (uint => vehicleEvent) vehicleEvents;
    uint nextVE = 0;

    event registerVehicleSuccess(bytes17 VIN);
    event registerOwnerSuccess(address newOwnerID, string newOwnerName);
    event transferVehicleSuccess(address recipientID, bytes17 VIN);
    
    function Titles() public {
        state = msg.sender;
    }
    
    ////////////////////////////////////////////////////////
    //ADMIN FUNCTIONS
    function registerAdmin(address adminID, string name, string position, string contact, bool oI, bool sOS, bool sVS, bool sLP, bool reg, bool aS, bool aD) public returns (bool){
        require(msg.sender == state);
        adminIDs.push(adminID);
        admins[adminID] = Admin(adminID, name, position, contact, StatusCodes.active, oI, sOS, sVS, sLP, reg, aS, aD);
        return true;
    }
    
    function setRegistrar(address subject) public returns (bool){
        require(admins[msg.sender].registrar == true && owners[subject].status == StatusCodes.active);
        owners[subject].registrar = true;
        return owners[subject].registrar;
    }
    
    function adminRegisterVehicle(address owner,bytes17 VIN, string make, uint16 year) public returns (bool){
        require(admins[msg.sender].registrar == true && vehicles[VIN].VIN == bytes17(0) && owners[owner].status == StatusCodes.active);
        vehicles[VIN] = Vehicle(owner, VIN, make, year, "none", StatusCodes.plateFlag, new uint[](0), new uint[](0));
        owners[owner].vehicleIDs.push(VIN);
        //push vehicle to admin queue to be issued a plate
        // vehicleAdminQueue.push(VIN);
        return true;
    }

    function appendDamage(bytes17 VIN, string description) public returns (bool){
        require(admins[msg.sender].appendDamage == true && vehicles[VIN].VIN != bytes17(0) && bytes(description).length != 0);
        uint VE = nextVE;
        nextVE++;
        vehicleEvents[VE] = vehicleEvent(block.timestamp, description, msg.sender);
        vehicles[VIN].damageRecord.push(VE);
        return true;
    }
    
    function appendService(bytes17 VIN, string description) public returns (bool){
        require((admins[msg.sender].appendService == true || msg.sender == vehicles[VIN].ownerID) && vehicles[VIN].VIN != bytes17(0) && bytes(description).length != 0);
        uint VE = nextVE;
        nextVE++;
        vehicleEvents[VE] = vehicleEvent(block.timestamp, description, msg.sender);
        vehicles[VIN].serviceRecord.push(VE);
        return true;
    }
    
     
    function adminSetOwnerStatus(address subjectID, StatusCodes newStatus) public returns (StatusCodes){
        require(admins[msg.sender].setOwnerStatus == true && owners[subjectID].ownerID != address(0));
        owners[subjectID].status = newStatus;
        return owners[subjectID].status;
    }
    
    
    ///////////////////////////////////////////////////////////////////////
    //OWNER FUNCTIONS
    function registerOwner(address insuranceContract, string name, string physicalAddress) public returns (bool){
        //check that owner does not already exist
        require(owners[msg.sender].ownerID == address(0));
        
        ownerIDs.push(msg.sender);
        owners[msg.sender] = Owner(msg.sender, insuranceContract, name, physicalAddress, new bytes17[] (0), StatusCodes.initFlag, false);
        // ownerAdminQueue.push(msg.sender);
        return true;
        // need to add check for validity of insuranceContract
        
    }
    
    function setOwnerStatus(StatusCodes newStatus) public returns (StatusCodes) {
        //owner status must be either active or ownerFlag
        require(owners[msg.sender].status == StatusCodes.active || owners[msg.sender].status == StatusCodes.ownerFlag);
        //owners can set status to either active, ownerFlag or deactivated
        require(newStatus == StatusCodes.ownerFlag || newStatus == StatusCodes.deactivated || newStatus == StatusCodes.active);
        
        owners[msg.sender].status = newStatus;
        return owners[msg.sender].status;
    }

    
    function setInsurance(address insuranceContract, address subject) public returns (bool){
        //owners or insurance contracts can change an owner's insurance variable
        if (subject == address(0)){
            owners[msg.sender].insurance = insuranceContract;
            return true;
        }
        require(msg.sender == owners[subject].insurance);
        owners[subject].insurance = insuranceContract;
        //need to add check for legitimacy of insuranceContract
        return true;
    }
  
    
    function registerVehicle(bytes17 VIN, string make, uint16 year) public returns (bool) {
        //require that VIN does not exist and msg.sender is registrar
        require(vehicles[VIN].VIN == bytes17(0) && owners[msg.sender].registrar == true);
        
        vehicles[VIN] = Vehicle(msg.sender, VIN, make, year, "none", StatusCodes.active, new uint[] (0) , new uint[] (0));
        owners[msg.sender].vehicleIDs.push(VIN);
        
        return true;
    }
    
    
    function setVehicleStatus(bytes17 VIN, StatusCodes newStatus) public returns (StatusCodes) {
        //vehicleStatus admin has power to unilaterally set status
        if (admins[msg.sender].setVehicleStatus == true) {
            vehicles[VIN].status = newStatus;
            return vehicles[VIN].status;
        }
        //vehicle owner can set status with conditions
        require(msg.sender == vehicles[VIN].ownerID && owners[msg.sender].status == StatusCodes.active);
        //vehicle status must be either active or ownerFlag
        require(vehicles[VIN].status == StatusCodes.active || vehicles[VIN].status == StatusCodes.ownerFlag);
        //owners can set status to either active, ownerFlag or deactivated
        require(newStatus == StatusCodes.ownerFlag || newStatus == StatusCodes.deactivated || newStatus == StatusCodes.active);
        
        vehicles[VIN].status = newStatus;
        return vehicles[VIN].status;
    }


    function setPlate(bytes17 VIN, string newPlate) public returns (string){
        require(admins[msg.sender].setLicensePlate == true);
        vehicles[VIN].licensePlate = newPlate;
        
        //if status == plateFlag, set it to active after setting a plate
        if (vehicles[VIN].status == StatusCodes.plateFlag){
            vehicles[VIN].status = StatusCodes.active;
        }
        return vehicles[VIN].licensePlate;
    }
    

    
    //to do: implement 2 party approval for license plate changes
    //use mapping from vin to vehicleAdmin
    //function setplate(string licensePlate, bytes17 VIN)
    
    
    function transferVehicle(bytes17 VIN, address recipient) public returns (bool){
        require(vehicles[VIN].ownerID == msg.sender && owners[recipient].status == StatusCodes.active && owners[msg.sender].status == StatusCodes.active && vehicles[VIN].status == StatusCodes.active);
        //allocate vehicle to new owner
        vehicles[VIN].ownerID = recipient;
        vehicles[VIN].status = StatusCodes.plateFlag;
        vehicles[VIN].licensePlate = "none";
        owners[recipient].vehicleIDs.push(VIN);
        //update original owner's vehicleIDs array
        //this needs a better solution to deal with registrars with many vehicles
        uint32 i = 0;
        uint len = owners[msg.sender].vehicleIDs.length - 1;
        while(owners[msg.sender].vehicleIDs[i] != VIN && i <= len) {
            i++;
        }
        //swap last and ith element before delete to preserve array continuity
        owners[msg.sender].vehicleIDs[i] = owners[msg.sender].vehicleIDs[len];
        delete owners[msg.sender].vehicleIDs[len];
        return true;
    }
    
    
}