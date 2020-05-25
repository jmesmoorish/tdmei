pragma solidity ^0.5.0;

interface Service{
    function setupContract(string v1 , string v2 , uint v3);
}

contract ContractOne is Service {
    string var1;
    string var2;
    uint var3;

    function setupContract(string v1 , string v2 , uint v3){
        var1 = v1;
        var2 = v2;
        var3 = v3 ;
    }

    function getInfo constant returns (string , string , uint){
        return var1 , var2 , var3;
    }
    // some code
}

contract ContractTwo is Service {
    // some code
}
contract ContractThree is Service {
    // some code
}
contract ContractComposer{
    ContractOne ContractOneService;
    ContractTwo ContractTwoService;
    ContractThree ContractThreeService;
    // some code
}