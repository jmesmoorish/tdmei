pragma solidity ^0.5.0;
import "../authorization/Ownership.sol";

contract ContractRelay is Owned {
    address public currentVersion;

    constructor (address initAddr) public {
        currentVersion = initAddr;
        owner = msg.sender;
    }

    function changeContract(address newVersion) public onlyOwner() {
        currentVersion = newVersion;
    }
    
    // fallback function
    function f() public {
        require(currentVersion.delegatecall(msg.data));
    }
}