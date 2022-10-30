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

    /**
     * @dev Add nft->xnft address pair to nfts.
     * @param budget The address of the underlying nft used as collateral
     * 
     */
    function createCampaign(address[] memory kols, uint256 budget) external returns (address){
        require(kols.length > 0,"kols is empty");

        //create campaign
        Campaign xcampaign = new Campaign(address(this), kols, budget);

        //init amount
        IERC20(usdt_address).transferFrom(
            msg.sender,
            address(xcampaign),
            budget
        );

        //register to mapping
        campaigns[msg.sender] = address(xcampaign);
        return address(xcampaign);
    }


    /**
     * @dev Add campaign address to campaign mapping.
     * @param budget The address of the underlying nft used as collateral
     * 
     */
    function createCampaignLowGas(address[] memory kols, uint256 budget) external returns (address instance){
        require(kols.length > 0,"kols is empty");

        //create campaign
        assembly{
            let proxy :=mload(0x40)
            mstore(proxy, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(proxy, 0x14), 0xdAC17F958D2ee523a2206206994597C13D831ec7)
            mstore(add(proxy, 0x28),0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
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
    function pushPay(address advertiser, uint8 ratio) external onlyOwner {
        require(advertiser != address(0), "AD3Hub: advertiser is zero address");

        require(
            campaigns[advertiser] != address(0),
            "AD3Hub: advertiser not create campaign"
        );

        //withdraw campaign amount to advertiser
        Campaign(campaigns[advertiser]).pushPay(ratio);

        emit Pushpay(advertiser, ratio);
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
