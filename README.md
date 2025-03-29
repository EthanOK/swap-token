# swap token

## uniswap v2 swap

[RouterProxy](./src/RouterProxy.sol)

### eth swap token and deduct proxy fee

```solidity
    /// @notice Users use ETH to exchange for Tokens, and deduct proxy fee
    /// @param amountOutMin  Minimum number of tokens expected to be obtained
    /// @param path  Path of tokens to swap, e.g. [WETH, USDC]
    /// @param to To address
    /// @return uint256 Amount of tokens obtained
    function swapExactETHForTokensWithFee(uint256 amountOutMin, address[] calldata path, address to)
        external
        payable
        returns (uint256);
```

### token swap token and deduct proxy fee

```solidity
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
    ) external returns (uint256);
```

### token swap eth and deduct proxy fee

```solidity
    /// @notice Users use one token to exchange for ETH, and deduct proxy fee
    /// @param amountIn  Amount of input token to swap
    /// @param amountOutMin  Minimum number of ETH expected to be obtained
    /// @param path  Path of tokens to swap, e.g. [USDC, WETH]
    /// @param to  To address
    /// @return uint256 Amount of ETH obtained
    function swapExactTokensForETHWithFee(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to)
        external
        returns (uint256);
```
