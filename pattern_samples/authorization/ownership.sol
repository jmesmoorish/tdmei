pragma solidity ^0.5.0;

contract Ownership {
    address public owner;
    event LogOwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function Owned() public {
        owner = msg.sender;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit LogOwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}
