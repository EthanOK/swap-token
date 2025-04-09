# FlashSwapUniswapV2
[Git Source](https://github.com/EthanOK/swap-token/blob/a325d2d1a567d66af0e4cebf776dc8dd9b1a5d51/src/FlashSwapUniswapV2.sol)

**Inherits:**
IUniswapV2Callee, Ownable


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
constructor(address _factory, address _uniswapRouter, address _initialOwner) Ownable(_initialOwner);
```

### flashSwapV2

Flash swap tokens on Uniswap V2

*obtain amountOut token_i*

*use some token_i get more token_i in `uniswapV2Call`*

*repay (amountOut + swapFee) token_i*

*remainning USDT will be transfer to user*


```solidity
function flashSwapV2(address _token0, address _token1, uint256 _amountOut0, uint256 _amountOut1, bytes calldata _data)
    external
    payable;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_token0`|`address`|The token to swap|
|`_token1`|`address`|The token to swap|
|`_amountOut0`|`uint256`|The amount of token0 to obtain|
|`_amountOut1`|`uint256`|The amount of token1 to obtain|
|`_data`|`bytes`|Any data passed through by the caller|


### uniswapV2Call


```solidity
function uniswapV2Call(address sender, uint256 amount0, uint256 amount1, bytes calldata data) external;
```

### rescueTokens


```solidity
function rescueTokens(address token, uint256 amount) external onlyOwner;
```

### rescueETH


```solidity
function rescueETH() external onlyOwner;
```

### receive


```solidity
receive() external payable;
```

## Structs
### CallParam

```solidity
struct CallParam {
    address target;
    uint256 value;
    bytes data;
}
```

