pragma solidity ^0.5.0;

contract DataStorage {
    mapping(bytes32 => uint) uintStorage;

    function getUintValue(bytes32 key) public constant returns (uint) {
        return uintStorage[key];
    }

    function setUintValue(bytes32 key, uint value) public {
        uintStorage[key] = value;
    }
}

contract Logic {
    DataStorage dataStorage;
    
    function Logic(address _address) public {
        dataStorage = DataStorage(_address);
    }

    function f() public {
        bytes32 key = keccak256("emergency");
        dataStorage.setUintValue(key, 911);
        dataStorage.getUintValue(key);
    }
}