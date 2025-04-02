// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {ProxyUniswapV2, IUniswapV2Router02, IERC20} from "../src/ProxyUniswapV2.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ProxyUniswapV2Test is Test {
    using SafeERC20 for IERC20;

    ProxyUniswapV2 public proxy;

    address public constant uniswapV2Router02 = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    address public constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    address public constant owner = address(0xdddd);

    address public constant user = address(0xeeee);

    function setUp() public {
        vm.createSelectFork("https://1rpc.io/eth");
        proxy = new ProxyUniswapV2(uniswapV2Router02, owner);

        // set user balance
        vm.deal(user, 100 ether);
    }

    function test_SwapExactETHForTokensWithFee() public {
        vm.startPrank(user);
        uint256 payAmount = 1 ether;

        address[] memory path = new address[](2);
        path[0] = IUniswapV2Router02(uniswapV2Router02).WETH();
        path[1] = USDT;

        uint256[] memory amountOuts = IUniswapV2Router02(uniswapV2Router02).getAmountsOut(payAmount, path);
        console.log("user Pay 1 ETH");
        uint256 usdt_decimals = ERC20(USDT).decimals();
        console.log("no fee get USDT: ", amountOuts[1] / 10 ** usdt_decimals, ".", amountOuts[1] % 10 ** usdt_decimals);

        proxy.swapExactETHForTokensWithFee{value: payAmount}(1, path, user);

        console.log("Deduct %d % Proxy Fees After:", proxy.feePercent());

        uint256 balance_user = IERC20(USDT).balanceOf(user);
        console.log("balance_user: ", balance_user / 10 ** usdt_decimals, ".", balance_user % 10 ** usdt_decimals);

        vm.stopPrank();
    }

    function test_SwapExactTokensForTokensWithFee() public {
        vm.startPrank(user);

        deal(USDT, user, 1000 * 1e6);

        uint256 balance_user = IERC20(USDT).balanceOf(user);

        console.log("user Pay USDT: ", balance_user / 1e6, ".", balance_user % 1e6);

        IERC20(USDT).safeIncreaseAllowance(address(proxy), type(uint256).max);

        address[] memory path_USDT_USDC_WETH = new address[](3);
        path_USDT_USDC_WETH[0] = USDT;
        path_USDT_USDC_WETH[1] = USDC;
        path_USDT_USDC_WETH[2] = WETH;

        uint256[] memory amountOuts =
            IUniswapV2Router02(uniswapV2Router02).getAmountsOut(balance_user, path_USDT_USDC_WETH);
        console.log(
            "no fee get WETH: ",
            amountOuts[path_USDT_USDC_WETH.length - 1] / 1e18,
            ".",
            amountOuts[path_USDT_USDC_WETH.length - 1] % 1e18
        );

        // swap USDT ->USDC-> WETH
        console.log("swap Path: USDT ->USDC-> WETH");
        proxy.swapExactTokensForTokensWithFee(balance_user, 1, path_USDT_USDC_WETH, user);

        uint256 balance = IERC20(WETH).balanceOf(user);

        console.log("user WETH balance: ", balance / 1e18, ".", balance % 1e18);

        assertGt(balance, 0);

        vm.stopPrank();
    }

    function test_SwapExactTokensForETHWithFee() public {
        vm.startPrank(user);

        deal(USDT, user, 1000 * 1e6);

        uint256 user_usdt_before = IERC20(USDT).balanceOf(user);

        console.log("user Pay USDT: ", user_usdt_before / 1e6, ".", user_usdt_before % 1e6);

        uint256 user_eth_before = user.balance;

        address[] memory path_USDT_WETH = new address[](2);
        path_USDT_WETH[0] = USDT;
        path_USDT_WETH[1] = WETH;

        // user approve USDT to proxy
        IERC20(USDT).safeIncreaseAllowance(address(proxy), type(uint256).max);
        // USDT TO ETH
        proxy.swapExactTokensForETHWithFee(user_usdt_before, 1, path_USDT_WETH, user);

        uint256 swap_eth = user.balance - user_eth_before;
        console.log("user Get ETH: ", swap_eth / 1e18, ".", swap_eth % 1e18);
    }
}
