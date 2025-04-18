# swap token

[docs](./docs/src/SUMMARY.md)

## uniswap v2 swap proxy

[router-02](https://docs.uniswap.org/contracts/v2/reference/smart-contracts/router-02)

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

## flash swap uniswap v2

[FlashSwapUniswapV2](./src/FlashSwapUniswapV2.sol)

[using-flash-swaps](https://docs.uniswap.org/contracts/v2/guides/smart-contract-integration/using-flash-swaps)

手续费 计算公式

```
amount1In = balance1 - (_reserve1 - amount1Out) = (balance1 - _reserve1) + amount1Out;

fee =  balance1 - _reserve1;

1000 * balance1 - 3 * amount1In >=  _reserve1 * 1000;

(balance1 - _reserve1) * 1000 >= 3 * amount1In;

(balance1 - _reserve1) * 1000 >= 3 * ((balance1 - _reserve1) + amount1Out);

fee * 1000 >= 3 * (fee + amount1Out);

fee  >=  amount1Out * 3/997;
```

```solidity

    function uniswapV2Call(address sender, uint256 amount0, uint256 amount1, bytes calldata data) external {
        require(sender == address(this), "UniswapV2: INVALID_CALLER");
        address pair = msg.sender;
        address token0 = IUniswapV2Pair(pair).token0();
        address token1 = IUniswapV2Pair(pair).token1();
        require(pair == IUniswapV2Factory(factory).getPair(token0, token1), "UniswapV2: INVALID_PAIR");

        uint256 payAmount;

        // TODO: DO Flash

        (CallParam memory callParam) = abi.decode(data, (CallParam));

        (callParam.target).functionCallWithValue(callParam.data, callParam.value);

        if (amount0 > 0) {
            payAmount = amount0 * 1000 / 997 + 1;
            IERC20(token0).safeTransfer(pair, payAmount);
        }

        if (amount1 > 0) {
            payAmount = amount1 * 1000 / 997 + 1;
            IERC20(token1).safeTransfer(pair, payAmount);
        }
    }
```

## uniswap v3 swap proxy

[uniswap v3 docs](https://docs.uniswap.org/contracts/v3/overview)

## uniswap v4 swap proxy
[uniswap v4 docs](https://docs.uniswap.org/contracts/v4/overview)