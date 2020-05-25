pragma solidity ^0.5.0;

contract Proxy_Factory { //contract factory pattern
    address[] public deployedProxys;

    function createProxy() public {
        address newProxy = address (new Proxy ());
        deployedProxys.push(newProxy);
    }

    function getDeployedProxy() public view returns (address[] memory) {
        return deployedProxys;
    }
}

contract Proxy {
    address private targetAddress;

    address payable private admin;
    constructor() public {
        targetAddress = 0xea265f4004D4536dE02b96E0556200c9Ef68374D;
        //targetAddress = 0xC139a8c21239f1A6ee193C21388183e33ecA48c7;
        admin = msg.sender;
    }

      modifier onlyOwner
    {
        require(msg.sender == admin);
        _;
    }

    function destroy() public onlyOwner { // mortal pattern
        selfdestruct(admin);
    }

    function destroyContract(address payable recipient) public onlyOwner { // mortal pattern
        selfdestruct(recipient);
    }

    function setTargetAddress(address _address) public {
        require(msg.sender==admin , "Admin only function");
        require(_address != address(0));
        targetAddress = _address;
    }

    function getContAdr() public view returns (address) {
        require(msg.sender==admin , "Admin only function");
        return targetAddress;
        
    }
    function () external payable {
        address contractAddr = targetAddress;
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize)
            let result := delegatecall(gas, contractAddr, ptr, calldatasize, 0, 0)
            let size := returndatasize
            returndatacopy(ptr, 0, size)

            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }
}