# ProxyUniswapV3
[Git Source](https://github.com/EthanOK/swap-token/blob/e2e0fd22e5959294cec712f2b99a2d5709d5b95a/src/ProxyUniswapV3.sol)

**Inherits:**
Ownable


## State Variables
### swapRouter

```solidity
ISwapRouter public immutable swapRouter;
```


### feePercent

```solidity
uint256 public feePercent = 50;
```


### feeBase

```solidity
uint256 public feeBase = 100;
```


## Functions
### constructor


```solidity
constructor(address _swapRouter, address _initialOwner) Ownable(_initialOwner);
```

### setFeePercent


```solidity
function setFeePercent(uint256 _percent, uint256 _base) external onlyOwner;
```

### swapExactETHForTokenWithFee

Swap exact ETH for token, and deduct fee


```solidity
function swapExactETHForTokenWithFee(address tokenOut, uint256 amountOutMin, uint24 fee, address recipient)
    external
    payable
    returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenOut`|`address`|TokenOut|
|`amountOutMin`|`uint256`|Minimum number of tokens expected to be obtained|
|`fee`|`uint24`|Fee|
|`recipient`|`address`|To address|


### swapExactTokenForTokenWithFee

Swap exact token for Token, and deduct fee


```solidity
function swapExactTokenForTokenWithFee(
    address tokenIn,
    address tokenOut,
    uint256 amountIn,
    uint256 amountOutMin,
    uint24 fee,
    address recipient
) external returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenIn`|`address`|TokenIn|
|`tokenOut`|`address`|TokenOut|
|`amountIn`|`uint256`|AmountIn|
|`amountOutMin`|`uint256`|Minimum number of tokens expected to be obtained|
|`fee`|`uint24`|Fee|
|`recipient`|`address`|To address|


### swapExactTokenForETHWithFee

Swap exact token for ETH, and deduct fee


```solidity
function swapExactTokenForETHWithFee(
    address tokenIn,
    uint256 amountIn,
    uint256 amountOutMin,
    uint24 fee,
    address recipient
) external returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenIn`|`address`|TokenIn|
|`amountIn`|`uint256`|AmountIn|
|`amountOutMin`|`uint256`|Minimum number of tokens expected to be obtained|
|`fee`|`uint24`|Fee|
|`recipient`|`address`|To address|


### swapExactETHForTokensWithFee

Swap exact ETH for Tokens, and deduct fee


```solidity
function swapExactETHForTokensWithFee(TokenOutInfo[] calldata tokenOutInfos, uint256 amountOutMin, address recipient)
    external
    payable
    returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenOutInfos`|`TokenOutInfo[]`|TokenOutInfos|
|`amountOutMin`|`uint256`|Minimum number of tokens expected to be obtained|
|`recipient`|`address`|To address|


### swapExactTokenForTokensWithFee

Swap exact token for tokens, and deduct fee


```solidity
function swapExactTokenForTokensWithFee(
    address tokenIn,
    TokenOutInfo[] calldata tokenOutInfos,
    uint256 amountIn,
    uint256 amountOutMin,
    address recipient
) external returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenIn`|`address`|TokenIn|
|`tokenOutInfos`|`TokenOutInfo[]`|TokenOutInfos|
|`amountIn`|`uint256`|AmountIn|
|`amountOutMin`|`uint256`|Minimum number of tokens expected to be obtained|
|`recipient`|`address`|To address|


### swapExactTokenForETHsWithFee

Swap exact token for ETH, and deduct fee


```solidity
function swapExactTokenForETHsWithFee(
    address tokenIn,
    TokenOutInfo[] calldata tokenOutInfos,
    uint256 amountIn,
    uint256 amountOutMin,
    address recipient
) external returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenIn`|`address`|TokenIn|
|`tokenOutInfos`|`TokenOutInfo[]`|TokenOutInfos|
|`amountIn`|`uint256`|AmountIn|
|`amountOutMin`|`uint256`|Minimum number of tokens expected to be obtained|
|`recipient`|`address`|To address|


### receive


```solidity
receive() external payable;
```

## Events
### ProxySwapV3

```solidity
event ProxySwapV3(
    address indexed tokenIn, address indexed tokenOut, uint256 amountIn, uint256 amountOut, address recipient
);
```

## Structs
### TokenOutInfo

```solidity
struct TokenOutInfo {
    uint24 poolFee;
    address tokenOut;
}
```

