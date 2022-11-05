// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Campaign.sol";
import "./AD3lib.sol";


contract AD3Hub is Ownable {
    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event Withdraw(address indexed advertiser);

    event Pushpay(address indexed advertiser);

    event Prepay(address indexed advertiser);

    event PayContentFee(address indexed advertiser);

    address public usdt_address = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    // Mapping from Advertiser address to campaign address
    mapping(address => address) internal campaigns;

    // Mapping from Advertiser address to historyCampaign address
    mapping(address => address) internal historyCampaigns;

    /**
     * 1）创建订单合约时需要确认 KOL 名单 - KOL 地址、KOL 固定制作费用、KOL 抽佣比例
     * 2）创建订单合约时需要确认广告主 - 固定制作费用总预算 + 用户激励总预算 = 广告总预算
     * 3）创建订单合约触发时机 - 广告主在签约页面上主动点击【创建广告】按钮触发，并签字转账
     */
    function createCampaign(
        AD3lib.kol[] kols,
        uint256 userBudget,
        uint256 totalBudget,
    ) external returns (address) {
        require(kols.length > 0, "AD3: kols is empty");
        require(userBudget > 0, "AD3: userBudget > 0");
        require(totalBudget > 0, "fixedBudget > 0");

        //create campaign
        Campaign xcampaign = new Campaign(userBudget, fixedBudget);

        //init amount
        IERC20(usdt_address).transferFrom(
            msg.sender,
            address(xcampaign),
            totalBudget,
        );

        //register to mapping
        campaigns[msg.sender] = address(xcampaign);
        return address(xcampaign);
    }

    /**
     * @dev Add campaign address to campaign mapping.
     * @param budget The address of the underlying nft used as collateral
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
     * @dev prepay triggered by ad3hub
     */
    function prepay() external {
        uint256 balance = campaigns[msg.sender].balanceOf();
        require(balance > 0; 'AD3: balance <= 0');

        bool prepaySuccess = Campaign(campaigns[msg.sender]).prepay(kols);
        require(prepaySuccess, "AD3: prepay failured");

        emit Prepay(msg.sender);
    }

    /**
     * @dev payContentFee triggered by ad3hub
     */
    function payContentFee() external {
        uint256 balance = campaigns[msg.sender].balanceOf();
        require(balance > 0; 'AD3: balance <= 0');

        bool payContentFeeSuccess = Campaign(campaigns[msg.sender]).prepay(kols);
        require(payContentFeeSuccess, "AD3: payContentFee failured");

        emit PayContentFee(msg.sender);
    }

    /**
     * @dev Withdraws an `amount` of underlying asset into the reserve, burning the equivalent bTokens owned.
     * - E.g. User deposits 100 USDC and gets in return 100 bUSDC
     * @param advertiser The address of the underlying nft used as collateral
     **/
    function pushPay(AD3lib.kolWithUsers[] memory kols) external {
        uint256 balance = campaigns[msg.sender].balanceOf();
        require(balance > 0; 'AD3: balance <= 0');

        bool pushPaySuccess = Campaign(campaigns[msg.sender]).pushPay(kols);
        require(pushPaySuccess, "AD3: pushPay failured");

        emit PushPay(msg.sender);
    }

    /**
     * @dev Withdraws an `amount` of underlying asset into the reserve, burning the equivalent bTokens owned.
     * - E.g. User deposits 100 USDC and gets in return 100 bUSDC
     * @param advertiser The address of the underlying nft used as collateral
     **/
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
