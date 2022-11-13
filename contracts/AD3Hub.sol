// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Campaign.sol";


contract AD3Hub is Ownable {
    using SafeTransferLib for IERC20;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event Withdraw(address indexed advertiser);

    event Pushpay(address indexed advertiser);

    event Prepay(address indexed advertiser);

    event PayContentFee(address indexed advertiser);

    address private _paymentToken;

    // Mapping from Advertiser address to campaign address
    mapping(address => mapping(uint64 => address)) private campaigns;

    mapping(address => uint64) private campaignIds;


    /**
     * 
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
        Campaign xcampaign = new Campaign(kols, userFee, _paymentToken);

        //init amount
        IERC20(_paymentToken).safeTransferFrom(
            msg.sender,
            address(xcampaign),
            totalBudget
        );

        //register to mapping
        uint64 length = campaignIds[msg.sender];
        length++;
        campaigns[msg.sender][length] = address(xcampaign);
        campaignIds[msg.sender] = length;
        return address(xcampaign);
    }


    //The byte codes of EIP-1167 standard are as follows:
    //3d602d80600a3d3981f3_363d3d37_3d3d3d363d73_bebebebebebebebebebebebebebebebebebebebe_5a_f4_3d82803e_903d91602b57fd5bf3
    //notes:
    //3d602d80600a3d3981f3 Copying runtime code into memory
    //---------------proxy contract----------------
    //363d3d37 Get the calldata
    //3d3d3d363d73 prepare input and output parmeter
    //bebebebebebebebebebebebebebebebebebebebe address of impl
    //5a gas
    //f4 Delegating the call
    //3d82803e Get the result of an external call
    //903d91602b57fd5bf3 return or revert
    //---------------proxy contract----------------

    /**
     * @dev Add campaign address to campaign mapping.
     * @param budget The address of the underlying nft used as collateral
     */
    function createCampaignLowGas(address[] memory kols, uint256 budget) external returns (address instance) {
        require(kols.length > 0,"kols is empty");

        /// @solidity memory-safe-assembly
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
        IERC20(_paymentToken).safeTransferFrom(
            msg.sender,
            address(instance),
            budget
        );

        //register to mapping
        uint64 length = campaignIds[msg.sender];
        campaignIds[msg.sender] = length++;
        campaigns[msg.sender][length] = address(instance);
        return address(instance);
    }


    /**
     * @dev payContentFee triggered by ad3hub
     */
    function payfixFee(address[] memory kols, address advertiser, uint64 campaignId) external onlyOwner{
        uint256 balance = IERC20(_paymentToken).balanceOf(campaigns[advertiser][campaignId]);
        require(balance > 0, 'AD3: balance <= 0');

        bool payContentFeeSuccess = Campaign(campaigns[advertiser][campaignId]).payfixFee(kols);
        require(payContentFeeSuccess, "AD3: payContentFee failured");

        emit PayContentFee(msg.sender);
    }

    /**
     * @dev Withdraws an `amount` of underlying asset into the reserve, burning the equivalent bTokens owned.
     * - E.g. User deposits 100 USDC and gets in return 100 bUSDC
     * @param kols kols with his users list
     **/
    function pushPay(address advertiser, uint64 campaignId, AD3lib.kolWithUsers[] calldata kols) external{
        uint256 balance = IERC20(_paymentToken).balanceOf(campaigns[advertiser][campaignId]);
        require(balance > 0, 'AD3: balance <= 0');

        bool pushPaySuccess = Campaign(campaigns[advertiser][campaignId]).pushPay(kols);
        require(pushPaySuccess, "AD3: pushPay failured");
        emit Pushpay(advertiser);

    }

    /**
     * @dev Withdraws an `amount` of underlying asset into the reserve, burning the equivalent bTokens owned.
     * - E.g. User deposits 100 USDC and gets in return 100 bUSDC
     * @param advertiser The address of the underlying nft used as collateral
     **/
    function withdraw(address advertiser, uint64 campaignId) external onlyOwner{
        require(advertiser != address(0), "AD3Hub: advertiser is zero address");

        require(
            campaigns[advertiser][campaignId] != address(0),
            "AD3Hub: advertiser not create campaign"
        );

        bool withdrawSuccess = Campaign(campaigns[advertiser][campaignId]).withdraw(advertiser);
        require(withdrawSuccess, "AD3: withdraw failured");
        emit Withdraw(advertiser);

    }

    function setPaymentToken(address token) external onlyOwner{
        require(token != address(0), "AD3Hub: advertiser is zero address");
        _paymentToken = token;
    }

    function getPaymentToken() external view returns (address){
        return _paymentToken;
    }

    /**
     * @dev get Address of Campaign
     * @param advertiser The address of the advertiser who create campaign
     **/
    function getCampaignAddress(address advertiser, uint64 campaignId) public view returns(address){
        require(advertiser != address(0), "NFTPool: nftAsset is zero address");
        return campaigns[advertiser][campaignId];
    }

    /**
     * @dev get Address of Campaign
     * @param advertiser The address of the advertiser who create campaign
     **/
    function getCampaignAddressList(address advertiser) public view returns(address[] memory){
        require(advertiser != address(0), "NFTPool: nftAsset is zero address");
        uint64 length = campaignIds[advertiser];
        if(length == 0){
            revert();
        }
        address[] memory campaignList = new address[](length);
        for(uint64 i =0; i<length; i++){
            campaignList[i] = campaigns[advertiser][i+1];
        }
        return campaignList;
    }
}
