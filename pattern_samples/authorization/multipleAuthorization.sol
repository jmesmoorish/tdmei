pragma solidity ^0.5.0;

contract MultipleAuthorization {

  uint public nonce = 0;                
  uint public threshold;            
  mapping (address => bool) isOwner; 
  address[] public ownersArr;        

  constructor (uint threshold_, address[] owners_) {
    if (owners_.length > 10 || threshold_ > owners_.length || threshold_ == 0) {throw;}

    for (uint i=0; i<owners_.length; i++) {
      isOwner[owners_[i]] = true;
    }
    ownersArr = owners_;
    threshold = threshold_;
  }

  //address recovered from signatures must be strictly increasing
  function execute(uint8[] sigV, bytes32[] sigR, bytes32[] sigS, address destination, uint value, bytes data) {
    if (sigR.length != threshold) {throw;}
    if (sigR.length != sigS.length || sigR.length != sigV.length) {throw;}
    bytes32 txHash = sha3(byte(0x19), byte(0), this, destination, value, data, nonce);

    address lastAdd = address(0); // cannot have address(0) as an owner
    for (uint i = 0; i < threshold; i++) {
        address recovered = ecrecover(txHash, sigV[i], sigR[i], sigS[i]);
        if (recovered <= lastAdd || !isOwner[recovered]) {throw;}
        lastAdd = recovered;
    }

    //all signatures are accounted for
    nonce = nonce + 1;
    if (!destination.call.value(value)(data)) {throw;}
  }

}
