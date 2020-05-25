pragma solidity ^0.5.0;

contract RateLimit {
    uint enabledAt = now;

    modifier enabledEvery(uint t) {
        if (now >= enabledAt) {
            enabledAt = now + t;
            _;
        }
    }

    function withdraw() public enabledEvery (uint minutes) {
        // some code
    }
    
}

