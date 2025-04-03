// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {
    OptimalOneSideUniswapV2,
    IUniswapV2Router02,
    IERC20,
    TransferHelper,
    IUniswapV2Pair
} from "../src/OptimalOneSideUniswapV2.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract OptimalOneSideUniswapV2Test is Test {
    OptimalOneSideUniswapV2 public proxy;

    address public constant uniswapV2Router02 = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    address public constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    address public constant owner = address(0xdddd);

    address public constant user = address(0xeeee);

    function setUp() public {
        vm.createSelectFork("https://1rpc.io/eth");
        proxy = new OptimalOneSideUniswapV2(uniswapV2Router02);

        deal(user, 100 ether);
        deal(USDT, user, 100000 * 1e6);
    }

    function test_SwapOptimalOneSide() public {
        vm.startPrank(user);
        address pair = proxy.getPair(WETH, USDT);

        // uint256 lpAmount = proxy.addLiquidityOptimalOneSide{value: 1 ether}(WETH, USDT, 1 ether);

        TransferHelper.safeApprove(USDT, address(proxy), 10000 * 1e6);
        uint256 lpAmount = proxy.addLiquidityOptimalOneSide(USDT, WETH, 6789 * 1e6);

        uint256 balance_lp = IERC20(address(pair)).balanceOf(user);
        assertEq(balance_lp, lpAmount);

        vm.stopPrank();
    }
}
