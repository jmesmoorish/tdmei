pragma solidity ^0.5.0;

contract ContractX {
    address public creator;

    constructor(address c) public {
        creator = c;
    }
}

contract ContractX_Factory {
    address[] public deployedContractsX;

    function createContractX() public {
        address newContractX = new ContractX (msg.sender);
        deployedContractX.push(newContractX);
    }

    function getDeployedContractsX() public view returns (address[]) {
        return deployedContractsX;
    }
}

