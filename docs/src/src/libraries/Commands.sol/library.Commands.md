# Commands
[Git Source](https://github.com/EthanOK/swap-token/blob/a2aa2546e6929eba7509523938fdff83b022530a/src/libraries/Commands.sol)

Command Flags used to decode commands


## State Variables
### FLAG_ALLOW_REVERT

```solidity
bytes1 internal constant FLAG_ALLOW_REVERT = 0x80;
```


### COMMAND_TYPE_MASK

```solidity
bytes1 internal constant COMMAND_TYPE_MASK = 0x3f;
```


### V3_SWAP_EXACT_IN

```solidity
uint256 constant V3_SWAP_EXACT_IN = 0x00;
```


### V3_SWAP_EXACT_OUT

```solidity
uint256 constant V3_SWAP_EXACT_OUT = 0x01;
```


### PERMIT2_TRANSFER_FROM

```solidity
uint256 constant PERMIT2_TRANSFER_FROM = 0x02;
```


### PERMIT2_PERMIT_BATCH

```solidity
uint256 constant PERMIT2_PERMIT_BATCH = 0x03;
```


### SWEEP

```solidity
uint256 constant SWEEP = 0x04;
```


### TRANSFER

```solidity
uint256 constant TRANSFER = 0x05;
```


### PAY_PORTION

```solidity
uint256 constant PAY_PORTION = 0x06;
```


### V2_SWAP_EXACT_IN

```solidity
uint256 constant V2_SWAP_EXACT_IN = 0x08;
```


### V2_SWAP_EXACT_OUT

```solidity
uint256 constant V2_SWAP_EXACT_OUT = 0x09;
```


### PERMIT2_PERMIT

```solidity
uint256 constant PERMIT2_PERMIT = 0x0a;
```


### WRAP_ETH

```solidity
uint256 constant WRAP_ETH = 0x0b;
```


### UNWRAP_WETH

```solidity
uint256 constant UNWRAP_WETH = 0x0c;
```


### PERMIT2_TRANSFER_FROM_BATCH

```solidity
uint256 constant PERMIT2_TRANSFER_FROM_BATCH = 0x0d;
```


### BALANCE_CHECK_ERC20

```solidity
uint256 constant BALANCE_CHECK_ERC20 = 0x0e;
```


### V4_SWAP

```solidity
uint256 constant V4_SWAP = 0x10;
```


### V3_POSITION_MANAGER_PERMIT

```solidity
uint256 constant V3_POSITION_MANAGER_PERMIT = 0x11;
```


### V3_POSITION_MANAGER_CALL

```solidity
uint256 constant V3_POSITION_MANAGER_CALL = 0x12;
```


### V4_INITIALIZE_POOL

```solidity
uint256 constant V4_INITIALIZE_POOL = 0x13;
```


### V4_POSITION_MANAGER_CALL

```solidity
uint256 constant V4_POSITION_MANAGER_CALL = 0x14;
```


### EXECUTE_SUB_PLAN

```solidity
uint256 constant EXECUTE_SUB_PLAN = 0x21;
```


