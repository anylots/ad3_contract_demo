// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Campaign.sol";


contract AD3Hub is Ownable {
    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event Withdraw(address indexed advertiser);

    event Pushpay(address indexed advertiser, uint8 indexed ratio);

    address public usdt_address = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    // Mapping from Advertiser address to campaign address
    mapping(address => address) internal campaigns;

    // Mapping from Advertiser address to historyCampaign address
    mapping(address => address) internal historyCampaigns;

    /**
     * @dev Add nft->xnft address pair to nfts.
     */
    /*
    *   TODO:
    *     1) 增加入参：prepaidKols，用于标识需要提前支付内容制作费 OR 一口价的 KOL 以及金额（mapping(address => uint8)）
    *     2）增加逻辑：调用 xcampaign 内部的 prepaid 预支付函数
    */ 
    function createCampaign(address[] memory kols,
        uint32[] memory fixedFees,
        uint8[] memory ratios,
        uint32 fixedFeeBudget,
        uint32 effectCostFeeBudget,
        uint256 costPerUser
        ) external returns (address){
        require(kols.length > 0,"kols is empty");
        require(fixedFee.length > 0,"fixedFee is empty");
        require(ratios.length > 0,"ratios is empty");

        //kol
        Kol[] _kols;
        for(uint32 i=0; i<kols.length; i++){
            address kolAddress = kols[i];
            uint32 fixedFee = fixedFees[i];
            uint8 ratio = ratios[i];
            require(kolAddress != address(0), "AD3Hub: kolAddress is zero address");
            require(fixedFee > 0,"AD3: kol fixedFee <= 0");
            require(ratio > 0 && ratio <= 100,"AD3: kol commission ratio <= 0 > 100");

            _kols.push(Kol(kolAddress, fixedFee, ratio));
        }

        //budget
        uint32 totalBudget = fixedFeeBudget + effectCostFeeBudget;
        Budget budget = Budget(fixedFeeBudget, effectCostFeeBudget, costPerUser);

        //create campaign
        Campaign xcampaign = new Campaign(_kols, budget);

        //init amount
        IERC20(usdt_address).transferFrom(
            msg.sender,
            address(xcampaign),
            totalBudget
        );

        //register to mapping
        campaigns[msg.sender] = address(xcampaign);
        return address(xcampaign);
    }

    /**
     * @dev Add campaign address to campaign mapping.
     * @param budget The address of the underlying nft used as collateral
     */
    /*
    *   TODO:
    *     1) 增加入参：prepaidKols，用于标识需要提前支付内容制作费 OR 一口价的 KOL 以及金额（mapping(address => uint8)）
    *     2）增加逻辑：调用 xcampaign 内部的 prepaid 预支付函数
    */ 
    function createCampaignLowGas(address[] memory kols, uint256 budget) external returns (address instance) {
        require(kols.length > 0,"kols is empty");

        //create campaign
        assembly{
            let proxy :=mload(0x40)
            mstore(proxy, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(proxy, 0x14), 0xdAC17F958D2ee523a2206206994597C13D831ec7)
            mstore(add(proxy, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, proxy, 0x37)
        }
        
        //init kols,other params
        (bool success, bytes memory returnData) = instance.call(abi.encodeWithSignature("init(address,address,string,string)", address(this)));
        require(success == true,"createCampaign init fail");

        //init amount
        IERC20(usdt_address).transferFrom(
            msg.sender,
            address(instance),
            budget
        );

        //register to mapping
        campaigns[msg.sender] = address(instance);


        return address(instance);
    }


    /**
     * @dev Withdraws an `amount` of underlying asset into the reserve, burning the equivalent bTokens owned.
     * - E.g. User deposits 100 USDC and gets in return 100 bUSDC
     * @param advertiser The address of the underlying nft used as collateral
     **/
    /*
    * TODO：
    *    1）增加入参：传入 kols 与需要获得激励的用户 address 映射的集合（mapping(address => address[])
    *    2）调整入参：根据实际业务调整，不同 KOL 的抽佣比例是否一致，如果不一致要 unit8 ratio 参数要修改成 mapping(address => uint8)
    **/
    function pushPay(address advertiser, AD3lib.kol[] memory kols) external onlyOwner {
        require(advertiser != address(0), "AD3Hub: advertiser is zero address");

        require(
            campaigns[advertiser] != address(0),
            "AD3Hub: advertiser not create campaign"
        );

        //withdraw campaign amount to advertiser
        // Campaign(campaigns[advertiser]).pushPay(kols);

        // emit Pushpay(advertiser, ratio);
    }

    /**
     * @dev Withdraws an `amount` of underlying asset into the reserve, burning the equivalent bTokens owned.
     * - E.g. User deposits 100 USDC and gets in return 100 bUSDC
     * @param advertiser The address of the underlying nft used as collateral
     **/
    /*
    * TODO：
    *   1）调整函数名，含义为终止广告活动，提前结算并且返回剩余资金到广告主
    *   2）增加入参：传入 kols 与需要获得激励的用户 address 映射的集合（mapping(address => address[])
    */
    function withdraw(address advertiser) external onlyOwner {
        require(advertiser != address(0), "AD3Hub: advertiser is zero address");

        require(
            campaigns[advertiser] != address(0),
            "AD3Hub: advertiser not create campaign"
        );

        //withdraw campaign amount to advertiser
        Campaign(campaigns[advertiser]).withdraw(advertiser);

        historyCampaigns[advertiser] = campaigns[advertiser];
        delete campaigns[advertiser];


        emit Withdraw(advertiser);
    }

    /**
     * @dev get Address of Campaign
     * @param advertiser The address of the advertiser who create campaign
     **/
    function getCampaignAddress(address advertiser) public view returns(address){
        require(advertiser != address(0), "NFTPool: nftAsset is zero address");
        return campaigns[advertiser];
    }
}
