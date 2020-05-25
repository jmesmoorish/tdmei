pragma solidity ^0.5.0;
import "../authorization/Ownership.sol";

contract ContractRegister is Owned {
    address backendContract;
    address[] previousBackends;

    function Register() public {
        owner = msg.sender;
    }

    function changeBackend(address newBackend) public onlyOwner() returns (bool) {
        if(newBackend != backendContract) {
            previousBackends.push(backendContract);
            backendContract = newBackend;
            return true;
        }
        return false;
    }
}