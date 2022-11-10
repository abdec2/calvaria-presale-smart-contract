// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/Math.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/utils/SafeERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol";

contract Presale is Context, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // The token being sold
    IERC20 private _token;

    // Address where funds are collected
    address payable private _wallet; // receives 90% of total payment
    address payable private _wallet2; // receives 10% of total payment

    // token distribution wallet address
    address private _tokenWallet;

    // payment accept in usdt
    IERC20 private _usdt;


    uint256 private _rate;

    // Amount of wei raised
    uint256 private _weiRaised;

    event TokensPurchased(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    constructor (uint256 __rate, address payable _wallet90, address payable _wallet10, IERC20 __token, address __tokenWallet, address usdt) {
        require(__rate > 0, "Crowdsale: rate is 0");
        require(_wallet90 != address(0), "Crowdsale: wallet90 is the zero address");
        require(_wallet10 != address(0), "Crowdsale: wallet10 is the zero address");
        require(address(__token) != address(0), "Crowdsale: token is the zero address");
        require(__tokenWallet != address(0), "AllowanceCrowdsale: token wallet is the zero address");
        require(usdt != address(0), "PRESALE: USDT address is the zero address");

        _rate = __rate; // 40000000000000 
        _wallet = _wallet90;
        _wallet2 = _wallet10;
        _token = __token;
        _tokenWallet = __tokenWallet;
        _usdt = IERC20(usdt);
    }

    fallback() external  {}
    receive () external payable {
    }

    function token() public view returns (IERC20) {
        return _token;
    }

    function wallet() public view returns (address payable) {
        return _wallet;
    }

    function wallet10() public view returns (address payable) {
        return _wallet2;
    }

    function tokenWallet() public view returns (address) {
        return _tokenWallet;
    }

    function rate() public view returns (uint256) {
        return _rate;
    }

    function weiRaised() public view returns (uint256) {
        return _weiRaised;
    }

    function buyTokens(address beneficiary, uint256 amount) public nonReentrant {
        uint256 weiAmount = amount;
        _preValidatePurchase(beneficiary, weiAmount);
        uint256 amount90 = weiAmount.mul(90).div(100);
        uint256 amount10 = weiAmount.mul(10).div(100);
        require(_usdt.transferFrom(beneficiary, _wallet, amount90), "PRESALE: USDT transfer to wallet90 fail.");
        require(_usdt.transferFrom(beneficiary, _wallet2, amount10), "PRESALE: USDT transfer to wallet10 fail.");


        // calculate token amount to be created
        uint256 tokens = _getTokenAmount(weiAmount);

        // update state
        _weiRaised = _weiRaised.add(weiAmount);

        _processPurchase(beneficiary, tokens);
        emit TokensPurchased(_msgSender(), beneficiary, weiAmount, tokens);

    }

    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
        require(beneficiary != address(0), "Crowdsale: beneficiary is the zero address");
        require(weiAmount != 0, "Crowdsale: weiAmount is 0");
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    }

    function _processPurchase(address beneficiary, uint256 tokenAmount) internal {
        _deliverTokens(beneficiary, tokenAmount);
    }

    function _getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
        return weiAmount.mul(_rate);
    }

    function remainingTokens() public view returns (uint256) {
        return Math.min(token().balanceOf(_tokenWallet), token().allowance(_tokenWallet, address(this)));
    }

    function _deliverTokens(address beneficiary, uint256 tokenAmount) internal {
        _token.safeTransferFrom(_tokenWallet, beneficiary, tokenAmount);
    }

}