# FlashSwapUniswapV3
[Git Source](https://github.com/EthanOK/swap-token/blob/a325d2d1a567d66af0e4cebf776dc8dd9b1a5d51/src/FlashSwapUniswapV3.sol)

**Inherits:**
Ownable, IUniswapV3SwapCallback


## State Variables
### MIN_SQRT_RATIO

```solidity
uint160 internal constant MIN_SQRT_RATIO = 4295128739;
```


### MAX_SQRT_RATIO

```solidity
uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;
```


### uniswapV3Factory

```solidity
IUniswapV3Factory public immutable uniswapV3Factory;
```


## Functions
### constructor


```solidity
constructor(address _uniswapV3Factory, address _initialOwner) Ownable(_initialOwner);
```

### flashSwapV3

Flash swap tokens on Uniswap V3

*pool0: WETH/USDT = 2000, pool1: WETH/USDT = 2100*

*swap amountIn USDT to WETH in pool0*

*use some WETH get more USDT (swap WETH for USDT in pool1) in `uniswapV3SwapCallback`*

*repay amountIn USDT*

*remainning USDT will be transfer to user*


```solidity
function flashSwapV3(
    address token0_,
    address token1_,
    uint256 amountIn0_,
    uint256 amountIn1_,
    uint24 fee_,
    bytes calldata data_
) external payable;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token0_`|`address`|The token to swap|
|`token1_`|`address`|The token to swap|
|`amountIn0_`|`uint256`|The amount of token0 to swap|
|`amountIn1_`|`uint256`|The amount of token1 to swap|
|`fee_`|`uint24`|The pool fee|
|`data_`|`bytes`|Any data passed through by the caller|


### uniswapV3SwapCallback

amountSpecified: the swap as exact input (positive), or exact output (negative)


```solidity
function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data) external;
```

## Events
### PoolDelta

```solidity
event PoolDelta(address pool, address token0, address token1, int256 amount0, int256 amount1);
```

## Structs
### SwapCallbackData

```solidity
struct SwapCallbackData {
    address token0;
    address token1;
    uint256 amount0;
    uint256 amount1;
    uint24 fee;
    address pool;
    address target;
    uint256 targetCallValue;
    bytes targetCallData;
}
```

### CallParam

```solidity
struct CallParam {
    address target;
    uint256 value;
    bytes data;
}
```

