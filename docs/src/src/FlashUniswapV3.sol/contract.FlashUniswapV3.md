# FlashUniswapV3
[Git Source](https://github.com/EthanOK/swap-token/blob/a2aa2546e6929eba7509523938fdff83b022530a/src/FlashUniswapV3.sol)

**Inherits:**
Ownable, IUniswapV3FlashCallback


## State Variables
### factory

```solidity
address public immutable factory;
```


### WETH9

```solidity
address public immutable WETH9;
```


## Functions
### constructor


```solidity
constructor(address _factory, address _WETH9, address _initialOwner) Ownable(_initialOwner);
```

### flash


```solidity
function flash(address _token0, address _token1, uint256 _amount0, uint256 _amount1, uint24 _fee, bytes calldata data)
    external
    payable;
```

### uniswapV3FlashCallback


```solidity
function uniswapV3FlashCallback(uint256 fee0, uint256 fee1, bytes calldata data) external;
```

## Structs
### FlashCallbackData

```solidity
struct FlashCallbackData {
    address token0;
    address token1;
    uint256 amount0;
    uint256 amount1;
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

