// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IQuoterV2} from "@uniswap/v3-periphery/contracts/interfaces/IQuoterV2.sol";

contract AttackedFlash {
    using SafeERC20 for IERC20;

    address public constant quoterV2 = 0x61fFE014bA17989E743c5F6cB21bF9697530B21e;

    address public constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    uint256 ethPrice = 0;

    mapping(address => bool) public withdrawStatus;

    mapping(address => uint256) bases;

    constructor() {
        bases[USDT] = 100;
        ethPrice = getETHPriceBaseUSDT();
    }

    function withdraw(address token) external {
        require(withdrawStatus[token] == false, "Already withdraw");

        require(IERC20(token).balanceOf(address(this)) > 0, "Not enough balance in this contract");

        uint256 balance = IERC20(token).balanceOf(msg.sender);

        IERC20(token).safeTransfer(msg.sender, balance / bases[token]);

        withdrawStatus[token] = true;
    }

    function getBenifit(address token, uint256 amount) external view returns (uint256) {
        uint256 base = bases[token];
        return base > 0 ? amount / bases[token] : 0;
    }

    function swapWETHForUSDT(uint256 amountIn) external payable returns (uint256) {
        IERC20(WETH).safeTransferFrom(msg.sender, address(this), amountIn);

        uint256 amountOut = amountIn * ethPrice / 1e18;
        IERC20(USDT).safeTransfer(msg.sender, amountOut);
        return amountOut;
    }

    function swapWETHForUSDT_ETH_CALLL(uint256 amountIn) external view returns (uint256) {
        uint256 amountOut = amountIn * ethPrice / 1e18;
        return amountOut;
    }

    function getETHByUSDT(uint256 amountIn) external returns (uint256) {
        IQuoterV2.QuoteExactInputSingleParams memory quoterParams = IQuoterV2.QuoteExactInputSingleParams({
            tokenIn: USDT,
            tokenOut: WETH,
            amountIn: amountIn,
            fee: 500,
            sqrtPriceLimitX96: 0
        });

        (uint256 amountOut,,,) = IQuoterV2(quoterV2).quoteExactInputSingle(quoterParams);

        return amountOut;
    }

    function getETHPriceBaseUSDT() public returns (uint256) {
        IQuoterV2.QuoteExactInputSingleParams memory quoterParams = IQuoterV2.QuoteExactInputSingleParams({
            tokenIn: WETH,
            tokenOut: USDT,
            amountIn: 1 ether,
            fee: 500,
            sqrtPriceLimitX96: 0
        });

        (uint256 amountOut,,,) = IQuoterV2(quoterV2).quoteExactInputSingle(quoterParams);

        return amountOut + 10 * 1e6;
    }
}
