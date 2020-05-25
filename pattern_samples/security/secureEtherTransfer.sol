pragma solidity ^0.5.0;

contract SecureEtherReceiver {

    function () public payable {}
}

contract SecureEtherSender {

    SecureEtherReceiver private receiverAdr = new SecureEtherReceiver();

    function sendEther(uint _amount) public payable {
        if (!address(receiverAdr).send(_amount)) {
            //handle failed send
        }
    }

    function callValueEther(uint _amount) public payable {
        require(address(receiverAdr).call.value(_amount).gas(35000)());
    }

    function transferEther(uint _amount) public payable {
        address(receiverAdr).transfer(_amount);
    }
}

