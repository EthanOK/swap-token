# ProxyUniswapV4
[Git Source](https://github.com/EthanOK/swap-token/blob/a325d2d1a567d66af0e4cebf776dc8dd9b1a5d51/src/ProxyUniswapV4.sol)

**Inherits:**
Ownable


## State Variables
### router

```solidity
IUniversalRouter public immutable router;
```


### poolManager

```solidity
IPoolManager public immutable poolManager;
```


### permit2

```solidity
IPermit2 public immutable permit2;
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
constructor(address _router, address _permit2, address _initialOwner) Ownable(_initialOwner);
```

### setFeePercent


```solidity
function setFeePercent(uint256 _percent, uint256 _base) external onlyOwner;
```

### swapExactInputSingle


```solidity
function swapExactInputSingle(
    PoolKey calldata key,
    bool zeroForOne,
    uint128 amountIn,
    uint128 amountOutMin,
    address recipient
) external payable returns (uint256 amountOut);
```

### receive


```solidity
receive() external payable;
```

