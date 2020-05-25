pragma solidity ^0.4.23;

contract Ownership { //ownership pattern
    address public owner;
    event LogOwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     constructor() public {
        owner = msg.sender;
    }

     modifier condition(bool _condition) { //access restriction pattern
        require(_condition); 
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner condition(newOwner != address(0)) {
        //require(newOwner != address(0));
        emit LogOwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract RVC is Ownership {
    mapping (address => uint256) private balances;
    string public name;
    uint8 public decimals;
    string public symbol;
    uint256 public totalSupply;
    address public owner;
    event Transfer(address indexed _from, address indexed _to, uint256 _value); 
    constructor(
        uint256 _initialAmount,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol,
        address _owner
    ) public {
        balances[_owner] = _initialAmount;
        totalSupply = _initialAmount;
        name = _tokenName;
        decimals = _decimalUnits;
        symbol = _tokenSymbol;
        owner = _owner;
    }
    function transfer(address _to, uint256 _value) public returns (bool success) {
        if(_to != address(0)){
            require(balances[msg.sender] >= _value);
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        }
    }
    function burnFrom(address _who,uint256 _value)public returns (bool){
        require(msg.sender == owner);
        assert(balances[_who] >= _value);
        totalSupply -= _value;
        balances[_who] -= _value;
        return true;
    }
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
}