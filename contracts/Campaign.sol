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
contract Campaign is ERC20, Ownable {

    enum CampaignStatus {
        //初始化
        INIT,
        //已预付款
        PREPAID,
        //已结算
        SETTLED
    }
    
    struct Kol {
        // kol 地址
        address kolAddress;
        //内容制作费
        uint32 fixedFee;
        //分佣比例
        uint8 ratio;
        //kol 带来的 user
        address[] users;
    }

    struct Budget {
        //campaign 总内容制作费预算
        uint32 fixedFee;
        //campaign 总效果计费预算
        uint32 effectCostFee;
        //campaign 单个用户预算
        uint32 costPerUser;
    }

    Budget public _campaignBudget;
    mapping(address => Kol) _kols;
    //serviceCharge percent value;
    uint32 _serviceCharge = 5;
    //fixedFeeRatio percent value;
    uint32 _fixedFeeRatio = 50;
    address public usdt = 0x5FbDB2315678afecb367f032d93F642f64180aa3;
    CampaignStatus _status;

    /**
     * @dev Constructor.
     * @param kols 传入的 kols 投放列表
     * @param budgets 预算
     */
    constructor(
        Kol[] memory kols,
        Budget memory budgets
    ) payable ERC20("name", "symbol") {
        uint32 campaignFixedFee = budgets.fixedFee;
        uint32 campaignEffectCostFee = budgets.effectCostFee;
        uint32 campaignCostPerUser = budgets.costPerUser;
        // pre check
        require(kols.length > 0,"AD3: kols is empty");
        require(campaignFixedFee > 0,"AD3: Campaign fixedFee < 0");
        require(campaignEffectCostFee > 0,"AD3: Campaign effectCostFee < 0");
        require(campaignCostPerUser > 0,"AD3: Campaign costPerUser < 0");

        for(uint32 i=0; i<kols.length; i++){
            address kolAddress = kols[i].kolAddress;
            uint32 fixedFee = kols[i].fixedFee;
            uint8 ratio = kols[i].ratio;
            require(kolAddress != address(0), "AD3Hub: kolAddress is zero address");
            require(fixedFee > 0,"AD3: kol fixedFee <= 0");
            require(ratio > 0 && ratio <= 100,"AD3: kol commission ratio <= 0 > 100");
            //装载 kols
            _kols[kolAddress] = kols[i];
        }
        _campaignBudget = budgets;
        //初始化 campaign 状态
        _status = CampaignStatus.INIT;
    }


    function prepay(Kol[] memory kols) public onlyOwner returns (bool) {
        //根据 campaign 状态判断是否可预支付
        require(CampaignStatus.INIT == _status, "AD3: prepay already done");
        uint256 balance = IERC20(usdt).balanceOf(address(this));
        require(balance > 0,"AD3: phaseTwoPay insufficient funds");

        for(uint32 i=0; i<kols.length; i++){
            address kol_address = kols[i].kolAddress;
            require(_kols[kol_address].kolAddress != address(0), "AD3Hub: kol_address does not exist");
            //pay for kol
            require(
                IERC20(usdt).transfer(kol_address, _kols[kol_address].fixedFee * _fixedFeeRatio / 100)
            );
        }

        _status = CampaignStatus.PREPAID;
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
    *    1）增加入参：传入 kols 与需要获得激励的用户 address 映射的集合（mapping(address => address[])
    *    2）调整入参：根据实际业务调整，不同 KOL 的抽佣比例是否一致，如果不一致要 unit8 ratio 参数要修改成 mapping(address => uint8)
    *    3）增加逻辑：结算逻辑需要对各个 KOL 支付抽佣金额、各个用户支付激励金额
    *    4）增加逻辑：结算后资金有剩余，需要退回剩余金额给广告主
    **/
    function settle(kol[] memory kols) public onlyOwner returns (bool) {
        require(kols.length > 0,"AD3: kols of pay is empty");
        uint256 balance = IERC20(usdt).balanceOf(address(this));
        require(balance > 0,"AD3: comletePay insufficient funds");

        for(uint32 i=0; i<kols.length; i++){
            address kol_address=kols[i].kolAddress;
            require(_kols[kol_address].kolAddress != address(0), "AD3Hub: kol_address does not exist");

            uint8 ratio = _kols[kol_address].ratio;
            //pay for fixedFee
            require(
                IERC20(usdt).transfer(kol_address, _kols[kol_address].fixedFee * (1-_fixedFeeRatio / 100))
            );
            //pay for effectCost
            require(
                IERC20(usdt).transfer(kol_address, _campaignBudget.effectCostFee * ratio/100)
            );
            address[] memory users = kols[i].users;
            uint256 userAmount = _campaignBudget.costPerUser * (100-ratio) / 100;
            //pay for users
            for(uint32 index=0; index<users.length; index++){
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

    /**
     * @dev setFixedFeeRatio.
     */
    function setFixedFeeRatio(uint8 value) public onlyOwner {
        require(value > 0,"AD3: serviceCharge <= 0");
        require(value <= 100,"AD3: serviceCharge > 100");
        _fixedFeeRatio = value;
    }
}
