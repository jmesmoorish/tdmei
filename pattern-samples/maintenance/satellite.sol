pragma solidity ^0.5.0;

contract Satellite {
    function calculateVariable() public pure returns (uint){
        // calculate var
        return 2 * 3;
    }
}

contract Base is Owned {
    uint public variable;
    address satelliteAddress;

    function setVariable() public onlyOwner {
        Satellite s = Satellite(satelliteAddress);
        variable = s.calculateVariable();
    }

    function updateSatelliteAddress(address _address) public onlyOwner {
        satelliteAddress = _address;
    }
}