# swap token

## uniswap v2 swap

[RouterProxy](./src/RouterProxy.sol)

### eth swap token and deduct 50% swap fee

```solidity
    function swapExactETHForTokensWithFee(uint256 amountOutMin, address token, address to) external payable {}
```

### token swap token and deduct 50% swap fee

```solidity
    function swapExactTokensForTokensWithFee(
        uint256 amountIn,
        uint256 amountOutMin,
        address tokenIn,
        address tokenOut,
        address to
    ) external {}
```
