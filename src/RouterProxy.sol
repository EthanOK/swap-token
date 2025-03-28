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

    function rescueTokens(address token, uint256 amount) external onlyOwner {
        IERC20(token).safeTransfer(owner(), amount);
    }

    function rescueETH() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    receive() external payable {}
}
