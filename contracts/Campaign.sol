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
contract Campaign is ERC20, Ownable{

    address private _owner;
    
    address[] private _sellers;

    uint256 private _budget;

    address public usdt = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    //serviceCharge percent value;
    uint256  serviceCharge = 5;



    /**
     * @dev Constructor.
     * @param owner name of the token
     * @param sellers symbol of the token, 3-4 chars is recommended
     * @param budget number of decimal places of one token unit, 18 is widely used
     */
    constructor(address owner, address[] memory sellers, uint256 budget) ERC20("name", "symbol") payable {
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
    function pushPay(uint256 ratio) public returns (bool) {

        require(_sellers.length > 0);
        require(ratio > 0);
        require(101 > ratio);

        uint256 balance = IERC20(usdt).balanceOf(address(this));
        uint256 amount = balance * ratio;
        uint256 serviceAmount = amount * serviceCharge;


        //todo
        uint256 avgValue = (amount - serviceAmount)/_sellers.length;

        for(uint256 i=0; i<_sellers.length; i++){
            require(_sellers[i] != address(0));
            require(IERC20(usdt).transferFrom(address(this), _sellers[i], avgValue));
        }
        require(IERC20(usdt).transferFrom(address(this), _owner, serviceAmount));

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
    function withdraw(address advertiser) public onlyOwner {

        uint256 balance = IERC20(usdt).balanceOf(address(this));

        require(IERC20(usdt).transferFrom(address(this), advertiser, balance));
    }


}