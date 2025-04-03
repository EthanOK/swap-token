// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IUniswapV2Factory} from "lib/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import {IUniswapV2Router02} from "lib/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import {IUniswapV2Pair} from "lib/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import {IWETH9, IERC20} from "./interfaces/IWETH9.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {TransferHelper} from "./libraries/TransferHelper.sol";

contract OptimalOneSideUniswapV2 {
    IUniswapV2Factory public immutable factory;
    IUniswapV2Router02 public immutable uniswapRouter;

    event OptimalSwapPool(address tokenIn, address tokenOut, uint256 amountIn, uint256 swapAmount, uint256 liquidity);

    constructor(address _uniswapRouter) {
        uniswapRouter = IUniswapV2Router02(_uniswapRouter);
        factory = IUniswapV2Factory(uniswapRouter.factory());
    }

    function getPair(address tokenA, address tokenB) external view returns (address pair) {
        pair = factory.getPair(tokenA, tokenB);
    }
    /// @notice add liquidity optimal one side
    /// @param tokenIn tokenIn
    /// @param tokenOut tokenOut
    /// @param amountIn amountIn
    /// @return liquidity liquidity

    function addLiquidityOptimalOneSide(address tokenIn, address tokenOut, uint256 amountIn)
        external
        payable
        returns (uint256 liquidity)
    {
        address weth = uniswapRouter.WETH();
        if (tokenIn == weth && msg.value > 0) {
            IWETH9(weth).deposit{value: msg.value}();
            amountIn = msg.value;
        } else {
            TransferHelper.safeTransferFrom(tokenIn, msg.sender, address(this), amountIn);
        }

        (address pair) = IUniswapV2Factory(factory).getPair(tokenIn, tokenOut);

        (uint256 reserve0, uint256 reserve1,) = IUniswapV2Pair(pair).getReserves();

        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;
        // get optimal swap amount
        uint256 swapAmountIn = getOptimalSwapAmount(amountIn, tokenIn < tokenOut ? reserve0 : reserve1);

        require(swapAmountIn <= amountIn, "swap amount too high");
        // approve swap
        TransferHelper.safeApprove(tokenIn, address(uniswapRouter), swapAmountIn);
        // swap tokenIn to tokenOut
        uniswapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            swapAmountIn, 0, path, address(this), block.timestamp
        );

        uint256 tokenIn_balance = IERC20(tokenIn).balanceOf(address(this));
        uint256 tokenOut_balance = IERC20(tokenOut).balanceOf(address(this));

        // approve
        TransferHelper.safeApprove(tokenIn, address(uniswapRouter), tokenIn_balance);
        TransferHelper.safeApprove(tokenOut, address(uniswapRouter), tokenOut_balance);

        // add liquidity
        (,, liquidity) = uniswapRouter.addLiquidity(
            tokenIn, tokenOut, tokenIn_balance, tokenOut_balance, 0, 0, address(this), block.timestamp
        );

        // transfer liquidity
        TransferHelper.safeTransfer(address(pair), msg.sender, liquidity);

        emit OptimalSwapPool(tokenIn, tokenOut, amountIn, swapAmountIn, liquidity);

        // IERC20(tokenIn).balanceOf(address(this));
        // IERC20(tokenOut).balanceOf(address(this));

        return liquidity;
    }

    function getOptimalSwapAmount(uint256 amountIn, uint256 reserveIn) public pure returns (uint256) {
        uint256 swapAmountIn =
            (Math.sqrt(reserveIn * (reserveIn * 3988009 + 3988000 * amountIn)) - 1997 * reserveIn) / 1994;
        return swapAmountIn;
    }
}
