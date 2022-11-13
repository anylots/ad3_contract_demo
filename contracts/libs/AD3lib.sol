// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;


library AD3lib {

    struct kol {
        //kol address
        address _address;
        //fixed production cost
        uint256 fixedFee;
        //percentage of get
        uint8 ratio;
        //Payment stage
        uint _paymentStage;
    }

    struct kolWithUsers {
        // Kol address
        address _address;
        // user address
        address[] users;
    }
}
