// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {RouterProxy, IUniswapV2Router02, IERC20} from "../src/RouterProxy.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract RouterProxyTest is Test {
    RouterProxy public router;

    address public constant uniswapV2Router02 = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    address public constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    address public constant owner = address(0xdddd);

    address public constant user = address(0xeeee);

    function setUp() public {
        vm.createSelectFork("https://1rpc.io/eth");
        router = new RouterProxy(uniswapV2Router02, owner);

        // set user balance
        vm.deal(user, 100 ether);
    }

    function test_Owner() public view {
        address owner_ = router.owner();
        assertEq(owner_, owner);
    }

    function testFuzz_RouterSwapTokenByETH() public {
        vm.startPrank(user);
        uint256 payAmount = 1 ether;

        address[] memory path = new address[](2);
        path[0] = IUniswapV2Router02(uniswapV2Router02).WETH();
        path[1] = USDT;

        uint256[] memory amountOuts = IUniswapV2Router02(uniswapV2Router02).getAmountsOut(payAmount, path);
        console.log("user Pay 1 ETH");
        uint256 usdt_decimals = ERC20(USDT).decimals();
        console.log("get USDT: ", amountOuts[1] / 10 ** usdt_decimals, ".", amountOuts[1] % 10 ** usdt_decimals);

        router.swapExactETHForTokensWithFee{value: payAmount}(1, USDT, user);
        uint256 balance_user = IERC20(USDT).balanceOf(user);
        uint256 balance_router = IERC20(USDT).balanceOf(address(router));

        console.log("balance_user: ", balance_user);
        console.log("balance_router: ", balance_router);
        assertLe(balance_user + balance_router, amountOuts[1]);

        vm.stopPrank();
    }
}
