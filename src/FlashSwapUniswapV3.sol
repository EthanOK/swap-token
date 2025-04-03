// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {TransferHelper} from "./libraries/TransferHelper.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {IUniswapV3Factory} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import {IUniswapV3SwapCallback} from "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol";

contract FlashSwapUniswapV3 is Ownable, IUniswapV3SwapCallback {
    using Address for address;

    event PoolDelta(address pool, address token0, address token1, int256 amount0, int256 amount1);

    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    IUniswapV3Factory public immutable uniswapV3Factory;

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

    struct CallParam {
        address target;
        uint256 value;
        bytes data;
    }

    constructor(address _uniswapV3Factory, address _initialOwner) Ownable(_initialOwner) {
        uniswapV3Factory = IUniswapV3Factory(_uniswapV3Factory);
    }

    /// @notice Flash swap tokens on Uniswap V3
    /// @dev pool0: WETH/USDT = 2000, pool1: WETH/USDT = 2100
    /// @dev swap amountIn USDT to WETH in pool0
    /// @dev use some WETH get more USDT (swap WETH for USDT in pool1) in `uniswapV3SwapCallback`
    /// @dev repay amountIn USDT
    /// @dev remainning USDT will be transfer to user
    /// @param token0_ The token to swap
    /// @param token1_ The token to swap
    /// @param amountIn0_ The amount of token0 to swap
    /// @param amountIn1_ The amount of token1 to swap
    /// @param fee_ The pool fee
    /// @param data_ Any data passed through by the caller
    function flashSwapV3(
        address token0_,
        address token1_,
        uint256 amountIn0_,
        uint256 amountIn1_,
        uint24 fee_,
        bytes calldata data_
    ) external payable {
        (address token0, address token1) = token0_ < token1_ ? (token0_, token1_) : (token1_, token0_);
        (uint256 amount0, uint256 amount1) = token0 == token0_ ? (amountIn0_, amountIn1_) : (amountIn1_, amountIn0_);

        {
            IUniswapV3Pool pool = IUniswapV3Pool(uniswapV3Factory.getPool(token0, token1, fee_));
            bool zeroForOne = amount0 > 0;
            /// amountSpecified: the swap as exact input (positive), or exact output (negative)
            int256 amountSpecified = int256(zeroForOne ? amount0 : amount1);
            uint160 sqrtPriceLimitX96 = 0;

            CallParam memory callParam = abi.decode(data_, (CallParam));

            SwapCallbackData memory swapCallbackData = SwapCallbackData({
                token0: token0,
                token1: token1,
                amount0: amount0,
                amount1: amount1,
                fee: fee_,
                pool: address(pool),
                target: callParam.target,
                targetCallValue: callParam.value,
                targetCallData: callParam.data
            });

            (int256 amount0_delta, int256 amount1_delta) = pool.swap(
                address(this),
                zeroForOne,
                amountSpecified,
                sqrtPriceLimitX96 == 0 ? (zeroForOne ? MIN_SQRT_RATIO + 1 : MAX_SQRT_RATIO - 1) : sqrtPriceLimitX96,
                abi.encode(swapCallbackData)
            );

            emit PoolDelta(address(pool), token0, token1, amount0_delta, amount1_delta);

            (amount0, amount1) = (0, 0);

            amount0 = IERC20(token0).balanceOf(address(this));
            amount1 = IERC20(token1).balanceOf(address(this));

            if (amount0 > 0) {
                TransferHelper.safeTransfer(token0, msg.sender, amount0);
            }
            if (amount1 > 0) {
                TransferHelper.safeTransfer(token1, msg.sender, amount1);
            }
        }
    }

    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data) external {
        SwapCallbackData memory swapCallbackData = abi.decode(data, (SwapCallbackData));
        address pool = uniswapV3Factory.getPool(swapCallbackData.token0, swapCallbackData.token1, swapCallbackData.fee);
        require(msg.sender == pool, "Invalid Pool");
        if (amount0Delta < 0) {
            TransferHelper.safeApprove(swapCallbackData.token0, swapCallbackData.target, uint256(-amount0Delta));
        }
        if (amount1Delta < 0) {
            TransferHelper.safeApprove(swapCallbackData.token1, swapCallbackData.target, uint256(-amount1Delta));
        }

        // DO flash
        (swapCallbackData.target).functionCallWithValue(
            swapCallbackData.targetCallData, swapCallbackData.targetCallValue
        );

        if (amount0Delta > 0) {
            TransferHelper.safeTransfer(swapCallbackData.token0, pool, uint256(amount0Delta));
        }
        if (amount1Delta > 0) {
            TransferHelper.safeTransfer(swapCallbackData.token1, pool, uint256(amount1Delta));
        }
    }
}
