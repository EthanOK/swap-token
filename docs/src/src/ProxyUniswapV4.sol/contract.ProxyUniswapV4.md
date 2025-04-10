# ProxyUniswapV4
[Git Source](https://github.com/EthanOK/swap-token/blob/a2aa2546e6929eba7509523938fdff83b022530a/src/ProxyUniswapV4.sol)

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
uint256 public feePercent = 5_000;
```


### FEE_DENOMINATOR

```solidity
uint256 public constant FEE_DENOMINATOR = 10_000;
```


## Functions
### constructor


```solidity
constructor(address _router, address _permit2, address _initialOwner) Ownable(_initialOwner);
```

### setFeePercent


```solidity
function setFeePercent(uint256 _percent) external onlyOwner;
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

### swapExactInputSingleOfficial


```solidity
function swapExactInputSingleOfficial(
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

