// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {IUniswapV3FlashCallback} from "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3FlashCallback.sol";
import {IUniswapV3Factory} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {TransferHelper} from "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

contract FlashUniswapV3 is Ownable, IUniswapV3FlashCallback {
    using Address for address;

    address public immutable factory;
    address public immutable WETH9;

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

    struct CallParam {
        address target;
        uint256 value;
        bytes data;
    }

    constructor(address _factory, address _WETH9, address _initialOwner) Ownable(_initialOwner) {
        factory = _factory;
        WETH9 = _WETH9;
    }

    function flash(
        address _token0,
        address _token1,
        uint256 _amount0,
        uint256 _amount1,
        uint24 _fee,
        bytes calldata data
    ) external payable {
        require(_token0 != _token1, "Identical Tokens");
        require(_amount0 > 0 || _amount1 > 0, "Zero Amount");

        (address token0, address token1) = _token0 < _token1 ? (_token0, _token1) : (_token1, _token0);

        (uint256 amount0, uint256 amount1) = _token0 == token0 ? (_amount0, _amount1) : (_amount1, _amount0);

        address pool = IUniswapV3Factory(factory).getPool(token0, token1, _fee);

        require(pool != address(0), "Pool Not Exists");

        uint256 _balance0_before = IERC20(token0).balanceOf(address(this));
        uint256 _balance1_before = IERC20(token1).balanceOf(address(this));

        CallParam memory callParam = abi.decode(data, (CallParam));

        bytes memory flash_data = abi.encode(
            FlashCallbackData({
                token0: token0,
                token1: token1,
                amount0: amount0,
                amount1: amount1,
                pool: pool,
                target: callParam.target,
                targetCallValue: callParam.value,
                targetCallData: callParam.data
            })
        );

        IUniswapV3Pool(pool).flash(address(this), amount0, amount1, flash_data);

        uint256 _balance0_after = IERC20(token0).balanceOf(address(this));
        uint256 _balance1_after = IERC20(token1).balanceOf(address(this));
        if (_balance0_after > _balance0_before) {
            TransferHelper.safeTransfer(token0, msg.sender, _balance0_after - _balance0_before);
        }
        if (_balance1_after > _balance1_before) {
            TransferHelper.safeTransfer(token1, msg.sender, _balance1_after - _balance1_before);
        }
    }

    function uniswapV3FlashCallback(uint256 fee0, uint256 fee1, bytes calldata data) external {
        FlashCallbackData memory decoded = abi.decode(data, (FlashCallbackData));

        require(msg.sender == decoded.pool, "Invalid Pool");
        require(fee0 > 0 || fee1 > 0, "Zero Fees");

        // TODO: Do Flash
        (decoded.target).functionCallWithValue(decoded.targetCallData, decoded.targetCallValue);

        // Repay borrow
        if (fee0 > 0) {
            {
                TransferHelper.safeTransfer(decoded.token0, decoded.pool, decoded.amount0 + fee0);
            }
        }

        if (fee1 > 0) {
            {
                TransferHelper.safeTransfer(decoded.token1, decoded.pool, decoded.amount1 + fee1);
            }
        }
    }
}
