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
    mapping(address => mapping(uint256 => address)) internal campaigns;

    mapping(address => uint64) internal campaignIds;


    // Mapping from Advertiser address to historyCampaign address
    mapping(address => address) internal historyCampaigns;

    /**
     * 1）创建订单合约时需要确认 KOL 名单 - KOL 地址、KOL 固定制作费用、KOL 抽佣比例
     * 2）创建订单合约时需要确认广告主 - 固定制作费用总预算 + 用户激励总预算 = 广告总预算
     * 3）创建订单合约触发时机 - 广告主在签约页面上主动点击【创建广告】按钮触发，并签字转账
     */
    function createCampaign(
        AD3lib.kol[] memory kols,
        uint256 totalBudget,
        uint256 userFee
    ) external returns (address) {
        require(kols.length > 0, "AD3: kols is empty");
        require(totalBudget > 0, "AD3: totalBudget > 0");
        require(userFee > 0, "AD3: userFee <= 0");

        //create campaign
        Campaign xcampaign = new Campaign(kols, userFee);

        //init amount
        IERC20(usdt_address).transferFrom(
            msg.sender,
            address(xcampaign),
            totalBudget
        );

        //register to mapping
        uint256 length = campaignIds[msg.sender];
        campaigns[msg.sender][length] = address(xcampaign);
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
        uint256 length = campaignIds[msg.sender];
        campaigns[msg.sender][length] = address(instance);


        return address(instance);
    }

    /**
     * @dev prepay triggered by ad3hub
     */
    function prepay(address[] memory kols, address advertiser, uint256 campaignId) external {
        uint256 balance = IERC20(usdt_address).balanceOf(campaigns[advertiser][campaignId]);
        require(balance > 0, 'AD3: balance <= 0');

        bool prepaySuccess = Campaign(campaigns[advertiser][campaignId]).prepay(kols);
        require(prepaySuccess, "AD3: prepay failured");

        emit Prepay(msg.sender);
    }

    /**
     * @dev payContentFee triggered by ad3hub
     */
    function payContentFee(address[] memory kols, address advertiser, uint256 campaignId) external {
        uint256 balance = IERC20(usdt_address).balanceOf(campaigns[advertiser][campaignId]);
        require(balance > 0, 'AD3: balance <= 0');

        bool payContentFeeSuccess = Campaign(campaigns[advertiser][campaignId]).prepay(kols);
        require(payContentFeeSuccess, "AD3: payContentFee failured");

        emit PayContentFee(msg.sender);
    }

    /**
     * @dev Withdraws an `amount` of underlying asset into the reserve, burning the equivalent bTokens owned.
     * - E.g. User deposits 100 USDC and gets in return 100 bUSDC
     * @param kols kols with his users list
     **/
    function pushPay(AD3lib.kolWithUsers[] memory kols, address advertiser, uint256 campaignId) external {
        uint256 balance = IERC20(usdt_address).balanceOf(campaigns[advertiser][campaignId]);
        require(balance > 0, 'AD3: balance <= 0');

        bool pushPaySuccess = Campaign(campaigns[advertiser][campaignId]).pushPay(kols);
        require(pushPaySuccess, "AD3: pushPay failured");
        emit Pushpay(advertiser);

        bool withdrawSuccess = Campaign(campaigns[advertiser][campaignId]).withdraw(advertiser);
        require(withdrawSuccess, "AD3: withdraw failured");
        emit Withdraw(advertiser);
    }

    /**
     * @dev Withdraws an `amount` of underlying asset into the reserve, burning the equivalent bTokens owned.
     * - E.g. User deposits 100 USDC and gets in return 100 bUSDC
     * @param advertiser The address of the underlying nft used as collateral
     **/
    function withdraw(address advertiser, uint256 campaignId) external {
        require(advertiser != address(0), "AD3Hub: advertiser is zero address");

        require(
            campaigns[advertiser][campaignId] != address(0),
            "AD3Hub: advertiser not create campaign"
        );

        bool withdrawSuccess = Campaign(campaigns[advertiser][campaignId]).withdraw(advertiser);
        require(withdrawSuccess, "AD3: withdraw failured");
        emit Withdraw(advertiser);

        historyCampaigns[advertiser] = campaigns[advertiser][campaignId];
        delete campaigns[advertiser][campaignId];


        emit Withdraw(advertiser);
    }

    /**
     * @dev get Address of Campaign
     * @param advertiser The address of the advertiser who create campaign
     **/
    function getCampaignAddress(address advertiser, uint256 campaignId) public view returns(address){
        require(advertiser != address(0), "NFTPool: nftAsset is zero address");
        return campaigns[advertiser][campaignId];
    }

    /**
     * @dev get Address of Campaign
     * @param advertiser The address of the advertiser who create campaign
     **/
    function getCampaignAddressList(address advertiser) public view returns(address[] memory){
        require(advertiser != address(0), "NFTPool: nftAsset is zero address");
        uint256 length = campaignIds[msg.sender];
        address[] memory campaignList;
        for(uint256 i =0; i<length; i++){
            campaignList[i] = campaigns[msg.sender][i];
        }
        return campaignList;
    }
}
