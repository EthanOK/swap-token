// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {ProxyUniswapV3} from "../src/ProxyUniswapV3.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IQuoterV2} from "@uniswap/v3-periphery/contracts/interfaces/IQuoterV2.sol";

contract ProxyUniswapV3Test is Test {
    ProxyUniswapV3 public proxy;

    address public constant swapRouter = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address public constant quoterV2 = 0x61fFE014bA17989E743c5F6cB21bF9697530B21e;

    address public constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    address public constant owner = address(0xdddd);

    address public constant user = address(0xeeee);

    function setUp() public {
        vm.createSelectFork("https://1rpc.io/eth");
        proxy = new ProxyUniswapV3(swapRouter, owner);

        // set user balance
        vm.deal(user, 100 ether);
    }

    function test_SwapExactETHForTokenWithFee() public {
        vm.startPrank(user);
        uint256 payAmount = 1 ether;

        IQuoterV2.QuoteExactInputSingleParams memory quoterParams = IQuoterV2.QuoteExactInputSingleParams({
            tokenIn: WETH,
            tokenOut: USDT,
            amountIn: payAmount,
            fee: 500,
            sqrtPriceLimitX96: 0
        });

        (uint256 amountOut,,,) = IQuoterV2(quoterV2).quoteExactInputSingle(quoterParams);

        console.log("ETH/USDT: ", amountOut);

        console.log("user Pay 1 ETH");

        // 0.05% 500
        proxy.swapExactETHForTokenWithFee{value: payAmount}(USDT, 0, 500, user);

        uint256 balance_user = IERC20(USDT).balanceOf(user);

        console.log("Deduct %d % Proxy Fees After:", proxy.feePercent());

        console.log("user Get USDT: ", balance_user);

        vm.stopPrank();
    }
}
