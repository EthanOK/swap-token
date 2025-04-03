// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {FlashSwapUniswapV2, IERC20, SafeERC20} from "../src/FlashSwapUniswapV2.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {AttackedFlash} from "./demo/AttackedFlash.sol";

contract FlashSwapUniswapV2Test is Test {
    using SafeERC20 for IERC20;

    FlashSwapUniswapV2 public flashSwapUniswapV2;

    AttackedFlash public attackedFlash;

    address public constant uniswapV2Factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address public constant uniswapV2Router02 = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    address public constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    address public constant owner = address(0xdddd);

    address public constant user = address(0xeeee);

    function setUp() public {
        vm.createSelectFork("https://1rpc.io/eth");
        flashSwapUniswapV2 = new FlashSwapUniswapV2(uniswapV2Factory, uniswapV2Router02, owner);

        attackedFlash = new AttackedFlash();

        // set ETH balance to user
        deal(user, 100 ether);
        // set USDT balance to attackedFlash
        deal(USDT, address(attackedFlash), 1000 * 1e6);

        uint256 balance_attackedFlash = IERC20(USDT).balanceOf(address(attackedFlash));

        console.log("balance_attackedFlash", balance_attackedFlash);
    }

    function test_FlashSwap() public {
        vm.startPrank(user);

        FlashSwapUniswapV2.CallParam memory callParam = FlashSwapUniswapV2.CallParam({
            target: address(attackedFlash),
            value: 0,
            data: abi.encodeWithSelector(AttackedFlash.withdraw.selector, address(USDT))
        });

        bytes memory data = abi.encode(callParam);

        uint256 amount_debt = 1000 * 1e6;

        uint256 benifit = AttackedFlash(attackedFlash).getBenifit(USDT, amount_debt);
        uint256 swapFees = getSwapFeesV2(amount_debt);
        console.log("benifit:", benifit);
        console.log("swapFees:", swapFees);

        uint256 amount_benifit = benifit - swapFees;
        console.log("Will earn USDT by flashSwap:", amount_benifit / 1e6, ".", amount_benifit % 1e6);

        uint256 usdt_balance_before = IERC20(USDT).balanceOf(address(user));
        console.log("usdt_balance_before:", usdt_balance_before);

        console.log("execute flashSwap");

        // obtain amountOut USDT
        // use some USDT get more USDT in `uniswapV2Call`
        // repay amountOut + fee USDT
        // remainning USDT will be transfer to user
        flashSwapUniswapV2.flashSwapV2(WETH, USDT, 0, amount_debt, data);

        console.log("finish flashSwap");

        uint256 usdt_balance_after = IERC20(USDT).balanceOf(address(user));

        assertEq(amount_benifit, usdt_balance_after - usdt_balance_before);

        console.log("usdt_balance_after:", usdt_balance_after / 1e6, ".", usdt_balance_after % 1e6);

        vm.stopPrank();
    }

    function getSwapFeesV2(uint256 amount) public pure returns (uint256) {
        return amount * 3 / 997 + 1;
    }
}
