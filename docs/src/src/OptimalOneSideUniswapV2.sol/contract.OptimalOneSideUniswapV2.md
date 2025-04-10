# OptimalOneSideUniswapV2
[Git Source](https://github.com/EthanOK/swap-token/blob/a2aa2546e6929eba7509523938fdff83b022530a/src/OptimalOneSideUniswapV2.sol)


## State Variables
### factory

```solidity
IUniswapV2Factory public immutable factory;
```


### uniswapRouter

```solidity
IUniswapV2Router02 public immutable uniswapRouter;
```


## Functions
### constructor


```solidity
constructor(address _uniswapRouter);
```

### getPair


```solidity
function getPair(address tokenA, address tokenB) external view returns (address pair);
```

### addLiquidityOptimalOneSide

add liquidity optimal one side

*a: amountIn*

*s: optimal swap amount*

*f: fee*

*r0: tokenIn reserve*

*r1: tokenOut reserve*

*swap: `r0*r1 = (r0 + s(1 - f))*(r1 - b)` base on `x * y = k`*

*addLiquidity: `(a - s) / (r0 + s) = b / (r1 - b)` base on `Dx / Rx = Dy / Ry = Dl / Rl`*

*s = [sqrt(((2 - f)r)^2 + 4(1 - f)ar) - (2 - f)r] / [2(1 - f)]*


```solidity
function addLiquidityOptimalOneSide(address tokenIn, address tokenOut, uint256 amountIn)
    external
    payable
    returns (uint256 liquidity);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenIn`|`address`|tokenIn|
|`tokenOut`|`address`|tokenOut|
|`amountIn`|`uint256`|amountIn|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`liquidity`|`uint256`|liquidity|


### getOptimalSwapAmount


```solidity
function getOptimalSwapAmount(uint256 amountIn, uint256 reserveIn) public pure returns (uint256);
```

## Events
### OptimalSwapPool

```solidity
event OptimalSwapPool(address tokenIn, address tokenOut, uint256 amountIn, uint256 swapAmount, uint256 liquidity);
```

