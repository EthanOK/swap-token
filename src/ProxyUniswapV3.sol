// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import {TransferHelper} from "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IPeripheryImmutableState} from "@uniswap/v3-periphery/contracts/interfaces/IPeripheryImmutableState.sol";
import {IWETH9} from "./interfaces/IWETH9.sol";

contract ProxyUniswapV3 is Ownable {
    event ProxySwapV3(
        address indexed tokenIn, address indexed tokenOut, uint256 amountIn, uint256 amountOut, address recipient
    );

    struct TokenOutInfo {
        uint24 poolFee;
        address tokenOut;
    }

    ISwapRouter public immutable swapRouter;

    uint256 public feePercent = 50;

    uint256 public feeBase = 100;

    constructor(address _swapRouter, address _initialOwner) Ownable(_initialOwner) {
        swapRouter = ISwapRouter(_swapRouter);
    }

    function setFeePercent(uint256 _percent, uint256 _base) external onlyOwner {
        require(_percent <= _base, "Fee cannot exceed  feeBase%");
        feePercent = _percent;
        feeBase = _base;
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
            deadline: block.timestamp,
            amountIn: amountIn,
            amountOutMinimum: amountOutMin,
            sqrtPriceLimitX96: 0 // No Price Limit
        });

        uint256 amountOut = swapRouter.exactInputSingle{value: amountIn}(params);
        uint256 feeAmount = (amountOut * feePercent) / feeBase;
        uint256 userAmount = amountOut - feeAmount;

        require(userAmount >= amountOutMin, "AmountOutMin not met");

        TransferHelper.safeTransfer(tokenOut, recipient, userAmount);
        TransferHelper.safeTransfer(tokenOut, owner(), feeAmount);

        emit ProxySwapV3(address(0), tokenOut, amountIn, userAmount, recipient);

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
            deadline: block.timestamp,
            amountIn: amountIn,
            amountOutMinimum: amountOutMin,
            sqrtPriceLimitX96: 0 // No Price Limit
        });

        uint256 amountOut = swapRouter.exactInputSingle(params);

        uint256 feeAmount = (amountOut * feePercent) / feeBase;
        uint256 userAmount = amountOut - feeAmount;

        require(userAmount >= amountOutMin, "AmountOutMin not met");

        TransferHelper.safeTransfer(tokenOut, recipient, userAmount);
        TransferHelper.safeTransfer(tokenOut, owner(), feeAmount);

        emit ProxySwapV3(tokenIn, tokenOut, amountIn, userAmount, recipient);

        return userAmount;
    }

    /// @notice Swap exact token for ETH, and deduct fee
    /// @param tokenIn TokenIn
    /// @param amountIn AmountIn
    /// @param amountOutMin Minimum number of tokens expected to be obtained
    /// @param fee Fee
    /// @param recipient To address
    function swapExactTokenForETHWithFee(
        address tokenIn,
        uint256 amountIn,
        uint256 amountOutMin,
        uint24 fee,
        address recipient
    ) external returns (uint256) {
        require(amountIn > 0, "Invalid amountIn");
        require(tokenIn != address(0), "Invalid tokenIn address");
        require(recipient != address(0), "Invalid recipient");

        address tokenOut = IPeripheryImmutableState(address(swapRouter)).WETH9();

        TransferHelper.safeTransferFrom(tokenIn, msg.sender, address(this), amountIn);
        TransferHelper.safeApprove(tokenIn, address(swapRouter), amountIn);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            fee: fee,
            recipient: address(this),
            deadline: block.timestamp,
            amountIn: amountIn,
            amountOutMinimum: amountOutMin,
            sqrtPriceLimitX96: 0 // No Price Limit
        });

        uint256 amountOut = swapRouter.exactInputSingle(params);

        // WETH Swap ETH
        IWETH9(tokenOut).withdraw(amountOut);

        uint256 feeAmount = (amountOut * feePercent) / feeBase;
        uint256 userAmount = amountOut - feeAmount;

        require(userAmount >= amountOutMin, "AmountOutMin not met");

        TransferHelper.safeTransferETH(recipient, userAmount);
        TransferHelper.safeTransferETH(owner(), feeAmount);

        emit ProxySwapV3(tokenIn, address(0), amountIn, userAmount, recipient);

        return userAmount;
    }

    /// @notice Swap exact ETH for Tokens, and deduct fee
    /// @param tokenOutInfos TokenOutInfos
    /// @param amountOutMin Minimum number of tokens expected to be obtained
    /// @param recipient To address
    function swapExactETHForTokensWithFee(
        TokenOutInfo[] calldata tokenOutInfos,
        uint256 amountOutMin,
        address recipient
    ) external payable returns (uint256) {
        uint256 tokens_len = tokenOutInfos.length;
        require(tokens_len > 0, "Invalid tokenOutInfos");
        uint256 amountIn = msg.value;
        require(amountIn > 0, "Invalid amountIn");
        address tokenIn = IPeripheryImmutableState(address(swapRouter)).WETH9();
        address tokenOut = tokenOutInfos[tokens_len - 1].tokenOut;
        require(tokenOut != address(0), "Invalid tokenOut address");

        bytes memory path = abi.encodePacked(tokenIn, tokenOutInfos[0].poolFee, tokenOutInfos[0].tokenOut);

        for (uint256 i = 1; i < tokens_len;) {
            path = abi.encodePacked(path, tokenOutInfos[i].poolFee, tokenOutInfos[i].tokenOut);

            unchecked {
                ++i;
            }
        }

        ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams({
            path: path,
            recipient: address(this),
            deadline: block.timestamp,
            amountIn: amountIn,
            amountOutMinimum: amountOutMin
        });

        uint256 amountOut = swapRouter.exactInput{value: amountIn}(params);
        uint256 feeAmount = (amountOut * feePercent) / feeBase;
        uint256 userAmount = amountOut - feeAmount;

        require(userAmount > amountOutMin, "AmountOutMin not met");

        // Transfer Token
        TransferHelper.safeTransfer(tokenOut, recipient, userAmount);
        TransferHelper.safeTransfer(tokenOut, owner(), feeAmount);

        emit ProxySwapV3(address(0), tokenOut, amountIn, userAmount, recipient);

        return userAmount;
    }

    /// @notice Swap exact token for tokens, and deduct fee
    /// @param tokenIn TokenIn
    /// @param tokenOutInfos TokenOutInfos
    /// @param amountIn AmountIn
    /// @param amountOutMin Minimum number of tokens expected to be obtained
    /// @param recipient To address
    function swapExactTokenForTokensWithFee(
        address tokenIn,
        TokenOutInfo[] calldata tokenOutInfos,
        uint256 amountIn,
        uint256 amountOutMin,
        address recipient
    ) external returns (uint256) {
        uint256 tokens_len = tokenOutInfos.length;
        require(tokens_len > 0, "Invalid tokenOutInfos");
        require(amountIn > 0, "Invalid amountIn");
        require(tokenIn != address(0), "Invalid tokenIn address");
        require(recipient != address(0), "Invalid recipient");
        address tokenOut = tokenOutInfos[tokens_len - 1].tokenOut;
        require(tokenOut != address(0), "Invalid tokenOut address");

        bytes memory path = abi.encodePacked(tokenIn, tokenOutInfos[0].poolFee, tokenOutInfos[0].tokenOut);

        for (uint256 i = 1; i < tokens_len;) {
            path = abi.encodePacked(path, tokenOutInfos[i].poolFee, tokenOutInfos[i].tokenOut);

            unchecked {
                ++i;
            }
        }

        ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams({
            path: path,
            recipient: address(this),
            deadline: block.timestamp,
            amountIn: amountIn,
            amountOutMinimum: amountOutMin
        });

        TransferHelper.safeTransferFrom(tokenIn, msg.sender, address(this), amountIn);
        TransferHelper.safeApprove(tokenIn, address(swapRouter), amountIn);

        uint256 amountOut = swapRouter.exactInput(params);

        uint256 feeAmount = (amountOut * feePercent) / feeBase;
        uint256 userAmount = amountOut - feeAmount;

        require(userAmount >= amountOutMin, "AmountOutMin not met");
        TransferHelper.safeTransfer(tokenOut, recipient, userAmount);
        TransferHelper.safeTransfer(tokenOut, owner(), feeAmount);

        emit ProxySwapV3(tokenIn, tokenOut, amountIn, userAmount, recipient);
        return userAmount;
    }

    /// @notice Swap exact token for ETH, and deduct fee
    /// @param tokenIn TokenIn
    /// @param tokenOutInfos TokenOutInfos
    /// @param amountIn AmountIn
    /// @param amountOutMin Minimum number of tokens expected to be obtained
    /// @param recipient To address
    function swapExactTokenForETHsWithFee(
        address tokenIn,
        TokenOutInfo[] calldata tokenOutInfos,
        uint256 amountIn,
        uint256 amountOutMin,
        address recipient
    ) external returns (uint256) {
        uint256 tokens_len = tokenOutInfos.length;
        require(tokens_len > 0, "Invalid tokenOutInfos");
        require(amountIn > 0, "Invalid amountIn");
        require(tokenIn != address(0), "Invalid tokenIn address");
        require(recipient != address(0), "Invalid recipient");
        address tokenOut = tokenOutInfos[tokens_len - 1].tokenOut;
        require(tokenOut == IPeripheryImmutableState(address(swapRouter)).WETH9(), "Invalid tokenOut address");

        bytes memory path = abi.encodePacked(tokenIn, tokenOutInfos[0].poolFee, tokenOutInfos[0].tokenOut);

        for (uint256 i = 1; i < tokens_len;) {
            path = abi.encodePacked(path, tokenOutInfos[i].poolFee, tokenOutInfos[i].tokenOut);

            unchecked {
                ++i;
            }
        }
        ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams({
            path: path,
            recipient: address(this),
            deadline: block.timestamp,
            amountIn: amountIn,
            amountOutMinimum: amountOutMin
        });

        TransferHelper.safeTransferFrom(tokenIn, msg.sender, address(this), amountIn);
        TransferHelper.safeApprove(tokenIn, address(swapRouter), amountIn);

        uint256 amountOut = swapRouter.exactInput(params);

        // WETH Swap ETH
        IWETH9(tokenOut).withdraw(amountOut);

        uint256 feeAmount = (amountOut * feePercent) / feeBase;
        uint256 userAmount = amountOut - feeAmount;
        require(userAmount >= amountOutMin, "AmountOutMin not met");

        TransferHelper.safeTransferETH(recipient, userAmount);
        TransferHelper.safeTransferETH(owner(), feeAmount);

        emit ProxySwapV3(tokenIn, address(0), amountIn, userAmount, recipient);
        return userAmount;
    }

    receive() external payable {}
}
