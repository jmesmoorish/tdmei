pragma solidity >=0.4.22 <0.6.0;

contract RigidBit_Factory { //contract factory pattern
    address[] public deployedRigidBits;

    function createRigidBit() public {
        address newRigidBit = address (new RigidBit ());
        deployedRigidBits.push(newRigidBit);
    }

    function getDeployedRigidBit() public view returns (address[] memory) {
        return deployedRigidBits;
    }
}

contract RigidBit
{
    address payable public owner;

    struct Storage
    {
        uint timestamp;
    }
    mapping(bytes32 => Storage) s;

    constructor() public
    {
        owner = msg.sender;
    }

    modifier onlyOwner
    {
        require(msg.sender == owner);
        _;
    }

    function destroy() public onlyOwner { // mortal pattern
        selfdestruct(owner);
    }

    function destroyContract(address payable recipient) public onlyOwner { // mortal pattern
        selfdestruct(recipient);
    }

    function transferOwnership(address payable _newOwner) public onlyOwner
    {
        owner = _newOwner;
    }

    function getHash(bytes32 hash) public view returns(uint)
    {
        return s[hash].timestamp;
    }
    
    function storeHash(bytes32 hash) public onlyOwner
    {
        assert(s[hash].timestamp == 0);

        s[hash].timestamp = now;
    }
}