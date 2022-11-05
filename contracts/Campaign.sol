// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./AD3lib.sol";


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
    mapping(address => AD3lib.kol) public _kolStorages;
    address public storage _ad3hub;
    uint256 public storage _totalBudget;
    uint256 public storage _userBudget;
    uint256 public storage _serviceCharge = 5;
    uint public storage _userFee;
    uint public storage _paymentStage = 0;
    address public usdt = 0x5FbDB2315678afecb367f032d93F642f64180aa3;

    modifier onlyAd3Hub() {
        require(
            msg.sender == _ad3hub,
            "The caller of this function must be a nftPool"
        );
        _;
    }

    /**
     * @dev Constructor.
     * @param userBudget number of decimal places of one token unit, 18 is widely used
     * @param totalBuget 
     */
    constructor(
        AD3lib.kol[] kols,
        uint256 userBudget,
        uint256 totalBudget,
        uint256 userFee,
    ) payable ERC20("name", "symbol") {
        _ad3hub = msg.sender;
        _userBudget = userBudget;
        _totalBudget = totalBudget;
        _userFee = userFee;

        for (uint64 i = 0; i < kols.length; i++) {
            AD3lib.kol kol = kols[i];
            require(kol._address, "AD3: kol_address does not exist");
            require(kol.fixedFee > 0, "AD3: kol fixedFee <= 0");
            require(kol.ratio >= 0, "AD3: kol ratio < 0");
            require(kol.ratio < 100, "AD3: kol ratio >= 100");

            _kolStorages[kol._address] = kol;
        }
    }

    function balanceOf() view onlyAd3Hub returns (uint256) {
        uint256 balance = IERC20(usdt).balanceOf(address(this));
        return balance;
    }

    function prepay(address[] memory kols) public onlyAd3Hub returns (bool) {
        require(_paymentStage < 2, "AD3: prepay already done");

        for (uint64 i = 0; i < kols.length; i++) {
            address kolAddress = kols[i];
            AD3lib.kol kol = _kolStorages[kolAddress];
            
            //pay for kol
            require(
                IERC20(usdt).transfer(kol._address, kol.fixedFee / 2);
            );
        }

        _paymentStage++;
        return true;
    }
    function pushPay(AD3lib.kolWithUsers[] memory kols) public onlyAd3Hub returns (bool) {
        require(kols.length > 0,"AD3: kols of pay is empty");

        uint256 balance = IERC20(usdt).balanceOf(address(this));
        require(balance > 0,"AD3: comletePay insufficient funds");

        for (uint64 i = 0; i < kols.length; i++) { 
            address kol_address = kols[i].kol_address;
            require(_kolStorages[kol_address].kol_address != address(0), "AD3: kol_address does not exist");

            uint8 ratio = _kolStorages[kol_address].ratio;
            ////pay for kol
            require(
                IERC20(usdt).transfer(kol_address, _userBudget * ratio/100)
            );
            address[] memory users = kols[i].users;
            uint256 userAmount = _userBudget * (100-ratio) / 100;
            //pay for users
            for(uint64 index=0; index<users.length; index++){
                require(
                    IERC20(usdt).transfer(users[index], userAmount)
                );
            }
        }

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


    /**
     * @dev setServiceCharge.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function setServiceCharge(uint8 value) public onlyOwner {
        require(value > 0,"AD3: serviceCharge <= 0");
        require(value <= 10,"AD3: serviceCharge > 10");
        _serviceCharge = value;
    }
}
