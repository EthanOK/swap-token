// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IUniswapV2Router02} from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {TransferHelper} from "./libraries/TransferHelper.sol";

contract ProxyUniswapV2 is Ownable {
    using Address for address payable;

    IUniswapV2Router02 public immutable uniswapRouter;
    uint256 public feePercent = 50;

    event FeeRecipientUpdated(address indexed newRecipient);
    event FeePercentUpdated(uint256 newPercent);

    constructor(address _uniswapRouter, address _initialOwner) Ownable(_initialOwner) {
        uniswapRouter = IUniswapV2Router02(_uniswapRouter);
    }

    function setFeePercent(uint256 _percent) external onlyOwner {
        require(_percent <= 100, "Fee cannot exceed 100%");
        feePercent = _percent;
        emit FeePercentUpdated(_percent);
    }

    /// @notice Users use ETH to exchange for Tokens, and deduct proxy fee
    /// @param amountOutMin  Minimum number of tokens expected to be obtained
    /// @param path  Path of tokens to swap, e.g. [WETH, USDC]
    /// @param to To address
    /// @return uint256 Amount of tokens obtained
    function swapExactETHForTokensWithFee(uint256 amountOutMin, address[] calldata path, address to)
        external
        payable
        returns (uint256)
    {
        address tokenOut = path[path.length - 1];
        require(msg.value > 0, "Invalid ETH amount");
        require(path[0] == uniswapRouter.WETH(), "Invalid WETH address");
        require(tokenOut != address(0), "Invalid tokenOut address");
        require(to != address(0), "Invalid recipient");

        uint256 deadline = block.timestamp + 100;

        uint256 beforeBalance = IERC20(tokenOut).balanceOf(address(this));

        uniswapRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            amountOutMin, path, address(this), deadline
        );

        uint256 afterBalance = IERC20(tokenOut).balanceOf(address(this));
        uint256 receivedToken = afterBalance - beforeBalance;
        uint256 feeAmount = (receivedToken * feePercent) / 100;
        uint256 userAmount = receivedToken - feeAmount;

        TransferHelper.safeTransfer(tokenOut, to, userAmount);
        TransferHelper.safeTransfer(tokenOut, owner(), feeAmount);

        return userAmount;
    }

    /// @notice Users use one token to exchange for another token, and deduct proxy fee
    /// @param amountIn  Amount of input token to swap
    /// @param amountOutMin  Minimum number of output tokens expected to be obtained
    /// @param path  Path of tokens to swap, e.g. [USDC, WBTC]
    /// @param to  To address
    /// @return uint256 Amount of output tokens obtained
    function swapExactTokensForTokensWithFee(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to
    ) external returns (uint256) {
        address tokenIn = path[0];
        address tokenOut = path[path.length - 1];

        require(tokenIn != address(0), "Invalid input token address");
        require(tokenOut != address(0), "Invalid output token address");
        require(to != address(0), "Invalid recipient");

        TransferHelper.safeTransferFrom(tokenIn, msg.sender, address(this), amountIn);
        TransferHelper.safeApprove(tokenIn, address(uniswapRouter), amountIn);

        uint256 deadline = block.timestamp + 100;

        uint256 beforeBalance = IERC20(tokenOut).balanceOf(address(this));

        // Perform the swap
        uniswapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountIn, amountOutMin, path, address(this), deadline
        );

        uint256 afterBalance = IERC20(tokenOut).balanceOf(address(this));

        uint256 receivedToken = afterBalance - beforeBalance;
        uint256 feeAmount = (receivedToken * feePercent) / 100;
        uint256 userAmount = receivedToken - feeAmount;

        // Transfer the output tokens to the user
        TransferHelper.safeTransfer(tokenOut, to, userAmount);
        TransferHelper.safeTransfer(tokenOut, owner(), feeAmount);

        return userAmount;
    }

    /// @notice Users use one token to exchange for ETH, and deduct proxy fee
    /// @param amountIn  Amount of input token to swap
    /// @param amountOutMin  Minimum number of ETH expected to be obtained
    /// @param path  Path of tokens to swap, e.g. [USDC, WETH]
    /// @param to  To address
    /// @return uint256 Amount of ETH obtained
    function swapExactTokensForETHWithFee(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to)
        external
        returns (uint256)
    {
        address tokenIn = path[0];

        require(path[path.length - 1] == uniswapRouter.WETH(), "Invalid WETH address");
        require(tokenIn != address(0), "Invalid input token address");
        require(to != address(0), "Invalid recipient");

        TransferHelper.safeTransferFrom(tokenIn, msg.sender, address(this), amountIn);
        TransferHelper.safeApprove(tokenIn, address(uniswapRouter), amountIn);
        uint256 deadline = block.timestamp + 100;

        uint256 beforeBalance = address(this).balance;

        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountIn, amountOutMin, path, address(this), deadline
        );

        uint256 receivedETH = address(this).balance - beforeBalance;
        uint256 feeAmount = (receivedETH * feePercent) / 100;
        uint256 userAmount = receivedETH - feeAmount;

        TransferHelper.safeTransferETH(to, userAmount);
        TransferHelper.safeTransferETH(owner(), feeAmount);

        return userAmount;
    }

    function rescueTokens(address token, uint256 amount) external onlyOwner {
        TransferHelper.safeTransfer(token, owner(), amount);
    }

    function rescueETH() external onlyOwner {
        TransferHelper.safeTransferETH(owner(), address(this).balance);
    }

    receive() external payable {}
}
