// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import {TransferHelper} from "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IPeripheryImmutableState} from "@uniswap/v3-periphery/contracts/interfaces/IPeripheryImmutableState.sol";

contract ProxyUniswapV3 is Ownable {
    event ProxySwapV3(
        address indexed tokenIn, address indexed tokenOut, uint256 amountIn, uint256 amountOut, address recipient
    );

    ISwapRouter public immutable swapRouter;

    uint256 public feePercent = 50;

    constructor(address _swapRouter, address _initialOwner) Ownable(_initialOwner) {
        swapRouter = ISwapRouter(_swapRouter);
    }

    function setFeePercent(uint256 _percent) external onlyOwner {
        require(_percent <= 100, "Fee cannot exceed 100%");
        feePercent = _percent;
    }

    /// @notice Swap exact ETH for token, and deduct fee
    /// @param tokenOut TokenOut
    /// @param amountOutMin Minimum number of tokens expected to be obtained
    /// @param fee Fee
    /// @param recipient To address
    function swapExactETHForTokenWithFee(address tokenOut, uint256 amountOutMin, uint24 fee, address recipient)
        external
        payable
        returns (uint256)
    {
        uint256 amountIn = msg.value;
        require(amountIn > 0, "Invalid amountIn");
        address tokenIn = IPeripheryImmutableState(address(swapRouter)).WETH9();

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            fee: fee,
            recipient: address(this),
            deadline: block.timestamp + 100,
            amountIn: amountIn,
            amountOutMinimum: amountOutMin,
            sqrtPriceLimitX96: 0 // No Price Limit
        });

        uint256 amountOut = swapRouter.exactInputSingle{value: amountIn}(params);
        uint256 feeAmount = (amountOut * feePercent) / 100;
        uint256 userAmount = amountOut - feeAmount;

        require(userAmount >= amountOutMin, "AmountOutMin not met");

        TransferHelper.safeTransfer(tokenOut, recipient, userAmount);
        TransferHelper.safeTransfer(tokenOut, owner(), feeAmount);

        emit ProxySwapV3(tokenIn, tokenOut, amountIn, userAmount, recipient);

        return userAmount;
    }

    /// @notice Swap exact token for Token, and deduct fee
    /// @param tokenIn TokenIn
    /// @param tokenOut TokenOut
    /// @param amountIn AmountIn
    /// @param amountOutMin Minimum number of tokens expected to be obtained
    /// @param fee Fee
    /// @param recipient To address
    function swapExactTokenForTokenWithFee(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMin,
        uint24 fee,
        address recipient
    ) external returns (uint256) {
        require(amountIn > 0, "Invalid amountIn");
        require(tokenIn != address(0), "Invalid tokenIn address");
        require(tokenOut != address(0), "Invalid tokenOut address");
        require(recipient != address(0), "Invalid recipient");

        TransferHelper.safeTransferFrom(tokenIn, msg.sender, address(this), amountIn);
        TransferHelper.safeApprove(tokenIn, address(swapRouter), amountIn);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            fee: fee,
            recipient: address(this),
            deadline: block.timestamp + 100,
            amountIn: amountIn,
            amountOutMinimum: amountOutMin,
            sqrtPriceLimitX96: 0 // No Price Limit
        });

        uint256 amountOut = swapRouter.exactInputSingle(params);

        uint256 feeAmount = (amountOut * feePercent) / 100;
        uint256 userAmount = amountOut - feeAmount;

        require(userAmount >= amountOutMin, "AmountOutMin not met");

        TransferHelper.safeTransfer(tokenOut, recipient, userAmount);
        TransferHelper.safeTransfer(tokenOut, owner(), feeAmount);

        emit ProxySwapV3(tokenIn, tokenOut, amountIn, userAmount, recipient);

        return userAmount;
    }

    receive() external payable {}
}
