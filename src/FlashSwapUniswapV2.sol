// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IUniswapV2Pair} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import {IUniswapV2Callee} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Callee.sol";
import {IUniswapV2Factory} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IUniswapV2Router02} from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {TransferHelper} from "./libraries/TransferHelper.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract FlashSwapUniswapV2 is IUniswapV2Callee, Ownable {
    using SafeERC20 for IERC20;
    using Address for address;

    struct CallParam {
        address target;
        uint256 value;
        bytes data;
    }

    IUniswapV2Factory public immutable factory;

    IUniswapV2Router02 public immutable uniswapRouter;

    constructor(address _factory, address _uniswapRouter, address _initialOwner) Ownable(_initialOwner) {
        factory = IUniswapV2Factory(_factory);
        uniswapRouter = IUniswapV2Router02(_uniswapRouter);
    }

    /// @notice Flash swap tokens on Uniswap V2
    /// @dev obtain amountOut token_i
    /// @dev use some token_i get more token_i in `uniswapV2Call`
    /// @dev repay (amountOut + swapFee) token_i
    /// @dev remainning USDT will be transfer to user
    /// @param _token0 The token to swap
    /// @param _token1 The token to swap
    /// @param _amountOut0 The amount of token0 to obtain
    /// @param _amountOut1 The amount of token1 to obtain
    /// @param _data Any data passed through by the caller
    function flashSwapV2(
        address _token0,
        address _token1,
        uint256 _amountOut0,
        uint256 _amountOut1,
        bytes calldata _data
    ) external payable {
        address pair = factory.getPair(_token0, _token1);
        require(pair != address(0), "Pair does not exist");
        address token0_ = IUniswapV2Pair(pair).token0();
        address token1_ = IUniswapV2Pair(pair).token1();

        uint256 _balance0_before = IERC20(token0_).balanceOf(address(this));
        uint256 _balance1_before = IERC20(token1_).balanceOf(address(this));

        IUniswapV2Pair(pair).swap(
            token0_ == _token0 ? _amountOut0 : _amountOut1,
            token1_ == _token1 ? _amountOut1 : _amountOut0,
            address(this),
            _data
        );

        uint256 _balance0_after = IERC20(token0_).balanceOf(address(this));
        uint256 _balance1_after = IERC20(token1_).balanceOf(address(this));
        if (_balance0_after > _balance0_before) {
            IERC20(token0_).safeTransfer(msg.sender, _balance0_after - _balance0_before);
        }
        if (_balance1_after > _balance1_before) {
            IERC20(token1_).safeTransfer(msg.sender, _balance1_after - _balance1_before);
        }
    }

    function uniswapV2Call(address sender, uint256 amount0, uint256 amount1, bytes calldata data) external {
        require(sender == address(this), "UniswapV2: INVALID_CALLER");
        address pair = msg.sender;
        address token0 = IUniswapV2Pair(pair).token0();
        address token1 = IUniswapV2Pair(pair).token1();
        require(pair == IUniswapV2Factory(factory).getPair(token0, token1), "UniswapV2: INVALID_PAIR");

        uint256 payAmount;

        // TODO: DO Flash

        (CallParam memory callParam) = abi.decode(data, (CallParam));

        (callParam.target).functionCallWithValue(callParam.data, callParam.value);

        if (amount0 > 0) {
            payAmount = amount0 * 1000 / 997 + 1;
            IERC20(token0).safeTransfer(pair, payAmount);
        }

        if (amount1 > 0) {
            payAmount = amount1 * 1000 / 997 + 1;
            IERC20(token1).safeTransfer(pair, payAmount);
        }
    }

    function rescueTokens(address token, uint256 amount) external onlyOwner {
        IERC20(token).safeTransfer(owner(), amount);
    }

    function rescueETH() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    receive() external payable {}
}
