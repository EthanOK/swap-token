// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IUniswapV2Pair} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import {IUniswapV2Callee} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Callee.sol";
import {IUniswapV2Factory} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract FlashSwapUniswapV2 is IUniswapV2Callee {
    using SafeERC20 for IERC20;

    IUniswapV2Factory public immutable factory;

    constructor(address _factory) {
        factory = IUniswapV2Factory(_factory);
    }

    function flashSwap(address _token0, address _token1, uint256 _amount0, uint256 _amount1, bytes calldata data)
        external
    {
        address pair = factory.getPair(_token0, _token1);
        require(pair != address(0), "Pair does not exist");
        address token0_ = IUniswapV2Pair(pair).token0();
        address token1_ = IUniswapV2Pair(pair).token1();

        IUniswapV2Pair(pair).swap(
            token0_ == _token0 ? _amount0 : _amount1, token1_ == _token1 ? _amount1 : _amount0, address(this), data
        );
    }

    function uniswapV2Call(address sender, uint256 amount0, uint256 amount1, bytes calldata data) external {
        require(sender == address(this), "UniswapV2: INVALID_CALLER");
        address pair = msg.sender;
        address token0 = IUniswapV2Pair(pair).token0();
        address token1 = IUniswapV2Pair(pair).token1();
        require(pair == IUniswapV2Factory(factory).getPair(token0, token1), "UniswapV2: INVALID_PAIR");

        uint256 payAmount;

        // TODO: DO Flash

        abi.decode(data, (address));

        if (amount0 > 0) {
            payAmount = amount0 * (1000 + 3) / 1000;
            IERC20(token0).safeTransfer(pair, payAmount);
        }

        if (amount1 > 0) {
            payAmount = amount1 * (1000 + 3) / 1000;
            IERC20(token1).safeTransfer(pair, payAmount);
        }
    }
}
