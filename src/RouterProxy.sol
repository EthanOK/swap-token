// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract RouterProxy is Ownable {
    using SafeERC20 for IERC20;

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

    /// @notice Users use ETH to exchange for Tokens, and 50% fee
    /// @param amountOutMin  Minimum number of tokens expected to be obtained
    /// @param token Token address
    /// @param to To address
    function swapExactETHForTokensWithFee(uint256 amountOutMin, address token, address to) external payable {
        address[] memory path = new address[](2);
        require(token != address(0), "Invalid token address");
        require(to != address(0), "Invalid recipient");

        path[0] = uniswapRouter.WETH();
        path[1] = token;

        uint256 deadline = block.timestamp + 100;

        uint256[] memory amounts =
            uniswapRouter.swapExactETHForTokens{value: msg.value}(amountOutMin, path, address(this), deadline);

        uint256 receivedToken = amounts[1];
        uint256 feeAmount = (receivedToken * feePercent) / 100;
        uint256 userAmount = receivedToken - feeAmount;

        IERC20(token).safeTransfer(to, userAmount);
    }

    /// @notice Users use one token to exchange for another token, and 50% fee
    /// @param amountIn  Amount of input token to swap
    /// @param amountOutMin  Minimum number of output tokens expected to be obtained
    /// @param tokenIn  Input token address
    /// @param tokenOut  Output token address
    /// @param to  To address
    function swapExactTokensForTokensWithFee(
        uint256 amountIn,
        uint256 amountOutMin,
        address tokenIn,
        address tokenOut,
        address to
    ) external {
        require(tokenIn != address(0), "Invalid input token address");
        require(tokenOut != address(0), "Invalid output token address");
        require(to != address(0), "Invalid recipient");

        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;

        // Transfer the input tokens from the user to this contract
        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);

        // Approve the Uniswap router to spend the input tokens
        IERC20(tokenIn).safeIncreaseAllowance(address(uniswapRouter), amountIn);

        uint256 deadline = block.timestamp + 100;

        // Perform the swap
        uint256[] memory amounts =
            uniswapRouter.swapExactTokensForTokens(amountIn, amountOutMin, path, address(this), deadline);

        uint256 receivedToken = amounts[1];
        uint256 feeAmount = (receivedToken * feePercent) / 100;
        uint256 userAmount = receivedToken - feeAmount;

        // Transfer the output tokens to the user
        IERC20(tokenOut).safeTransfer(to, userAmount);
    }

    function rescueTokens(address token, uint256 amount) external onlyOwner {
        IERC20(token).safeTransfer(owner(), amount);
    }

    function rescueETH() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    receive() external payable {}
}
