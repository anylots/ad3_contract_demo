// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title TokenMintERC20Token
 * @author TokenMint (visit https://tokenmint.io)
 *
 * @dev Standard ERC20 token with burning and optional functions implemented.
 * For full specification of ERC-20 standard see:
 * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 */
/*
* TODO:
*   1) 增加函数：prepaid 预支付，创建实例时即向部分 KOL 支付内容制作费 OR 一口价
**/
contract Campaign is ERC20, Ownable {
    address private _owner;

    address[] private _sellers;

    uint256 private _budget;

    address public usdt = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    //serviceCharge percent value;
    uint256 serviceCharge = 5;

    struct kol{
        address kol_address;
        address[]users;
        uint8 ratio;
    }

    /**
     * @dev Constructor.
     * @param owner name of the token
     * @param sellers symbol of the token, 3-4 chars is recommended
     * @param budget number of decimal places of one token unit, 18 is widely used
     */
    constructor(
        address owner,
        address[] memory sellers,
        uint256 budget
    ) payable ERC20("name", "symbol") {
        _owner = owner;
        _sellers = sellers;
        _budget = budget;
    }

    /**
     * @dev See `IERC20.transfer`.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    /*
    * TODO：
    *    1）增加入参：传入 kols 与需要获得激励的用户 address 映射的集合（mapping(address => address[])
    *    2）调整入参：根据实际业务调整，不同 KOL 的抽佣比例是否一致，如果不一致要 unit8 ratio 参数要修改成 mapping(address => uint8)
    *    3）增加逻辑：结算逻辑需要对各个 KOL 支付抽佣金额、各个用户支付激励金额
    *    4）增加逻辑：结算后资金有剩余，需要退回剩余金额给广告主
    **/
    function pushPay(kol[] memory kols) public returns (bool) {
        require(kols.length > 0);
        uint256 balance = IERC20(usdt).balanceOf(address(this));
        uint256 amount = balance/2;
        uint256 pay_amount = amount/kols.length;

        for(uint64 i=0; i<kols.length; i++){
            address kol_address=kols[i].kol_address;
            address[] memory users = kols[i].users;
            uint8 ratio = kols[i].ratio;
            require(
                IERC20(usdt).transferFrom(address(this), kol_address, pay_amount * ratio/100)
            );
            uint256 userAmount = pay_amount*(100-ratio)/100/users.length;
            for(uint64 index=0; index<users.length; index++){
                require(
                IERC20(usdt).transferFrom(address(this), users[index], userAmount)
                );
            }
        }


        uint256 serviceAmount = amount * serviceCharge;

        // todo
        uint256 avgValue = (amount - serviceAmount) / _sellers.length;

        for (uint256 i = 0; i < _sellers.length; i++) {
            require(_sellers[i] != address(0));
            require(
                IERC20(usdt).transferFrom(address(this), _sellers[i], avgValue)
            );
        }
        require(
            IERC20(usdt).transferFrom(address(this), _owner, serviceAmount)
        );

        return true;
    }

    /**
     * @dev See `IERC20.transfer`.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    /*
    * TODO：
    *   1）调整函数名，含义为终止广告活动，提前结算并且返回剩余资金到广告主
    *   2）增加入参：传入 kols 与需要获得激励的用户 address 映射的集合（mapping(address => address[])
    *   3）增加逻辑：计算已产生的预支付费用 + kol 抽佣费用 + 用户激励费用，返回剩余金额给广告主
    */
    function withdraw(address advertiser) public onlyOwner {
        uint256 balance = IERC20(usdt).balanceOf(address(this));

        require(IERC20(usdt).transferFrom(address(this), advertiser, balance));
    }
}
