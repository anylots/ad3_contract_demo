// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


library AD3lib {

    struct kol {
        // kol 地址
        address _address;
        // 固定制作费用
        uint256 fixedFee;
    }

    struct kolWithUsers {
        // kol 地址
        address _address;
        // 抽佣比例
        uint8 ratio;
        // 抽佣用户
        address[] users;
    }
}
