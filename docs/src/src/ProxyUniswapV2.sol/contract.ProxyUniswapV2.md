# ProxyUniswapV2
[Git Source](https://github.com/EthanOK/swap-token/blob/e2e0fd22e5959294cec712f2b99a2d5709d5b95a/src/ProxyUniswapV2.sol)

**Inherits:**
Ownable


## State Variables
### uniswapRouter

```solidity
IUniswapV2Router02 public immutable uniswapRouter;
```


### feePercent

```solidity
uint256 public feePercent = 50;
```


## Functions
### constructor


```solidity
constructor(address _uniswapRouter, address _initialOwner) Ownable(_initialOwner);
```

### setFeePercent


```solidity
function setFeePercent(uint256 _percent) external onlyOwner;
```

### swapExactETHForTokensWithFee

Users use ETH to exchange for Tokens, and deduct proxy fee


```solidity
function swapExactETHForTokensWithFee(uint256 amountOutMin, address[] calldata path, address to)
    external
    payable
    returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amountOutMin`|`uint256`| Minimum number of tokens expected to be obtained|
|`path`|`address[]`| Path of tokens to swap, e.g. [WETH, USDC]|
|`to`|`address`|To address|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|uint256 Amount of tokens obtained|


### swapExactTokensForTokensWithFee

Users use one token to exchange for another token, and deduct proxy fee


```solidity
function swapExactTokensForTokensWithFee(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to)
    external
    returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amountIn`|`uint256`| Amount of input token to swap|
|`amountOutMin`|`uint256`| Minimum number of output tokens expected to be obtained|
|`path`|`address[]`| Path of tokens to swap, e.g. [USDC, WBTC]|
|`to`|`address`| To address|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|uint256 Amount of output tokens obtained|


### swapExactTokensForETHWithFee

Users use one token to exchange for ETH, and deduct proxy fee


```solidity
function swapExactTokensForETHWithFee(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to)
    external
    returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amountIn`|`uint256`| Amount of input token to swap|
|`amountOutMin`|`uint256`| Minimum number of ETH expected to be obtained|
|`path`|`address[]`| Path of tokens to swap, e.g. [USDC, WETH]|
|`to`|`address`| To address|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|uint256 Amount of ETH obtained|


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

## Events
### FeeRecipientUpdated

```solidity
event FeeRecipientUpdated(address indexed newRecipient);
```

### FeePercentUpdated

```solidity
event FeePercentUpdated(uint256 newPercent);
```

