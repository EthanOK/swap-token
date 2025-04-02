// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {FlashSwapUniswapV3, TransferHelper} from "../src/FlashSwapUniswapV3.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AttackedFlash} from "./demo/AttackedFlash.sol";

contract FlashSwapUniswapV3Test is Test {
    FlashSwapUniswapV3 public flashSwapUniswapV3;

    AttackedFlash public attackedFlash;

    address public constant uniswapV3Factory = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
    address public constant swapRouter = 0xE592427A0AEce92De3Edee1F18E0157C05861564;

    address public constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    address public constant owner = address(0xdddd);

    address public constant user = address(0xeeee);

    function setUp() public {
        vm.createSelectFork("https://1rpc.io/eth");
        flashSwapUniswapV3 = new FlashSwapUniswapV3(uniswapV3Factory, owner);

        attackedFlash = new AttackedFlash();

        deal(user, 100 ether);

        deal(USDT, address(attackedFlash), 10000 * 1e6);
    }

    function test_FlashSwap() public {
        vm.startPrank(user);

        uint256 amountIn_usdt = 1000 * 1e6;

        uint256 will_get_eth = AttackedFlash(attackedFlash).getETHByUSDT(amountIn_usdt);

        console.log("will_get_eth:", will_get_eth);

        uint256 will_get_usdt = AttackedFlash(attackedFlash).swapWETHForUSDT_ETH_CALLL(will_get_eth);

        uint256 amount_benifit = will_get_usdt - amountIn_usdt;

        console.log("Will earn USDT by flash swap:", amount_benifit / 1e6, ".", amount_benifit % 1e6);

        FlashSwapUniswapV3.CallParam memory callParam = FlashSwapUniswapV3.CallParam({
            target: address(attackedFlash),
            value: 0,
            data: abi.encodeWithSelector(AttackedFlash.swapWETHForUSDT.selector, will_get_eth)
        });

        console.log("execute flashSwap");

        flashSwapUniswapV3.flashSwapV3(WETH, USDT, 0, amountIn_usdt, 500, abi.encode(callParam));

        console.log("finish flashSwap");

        uint256 usdt_balance_after = IERC20(USDT).balanceOf(address(user));
        assertEq(amount_benifit, usdt_balance_after);

        console.log("usdt_balance_after:", usdt_balance_after / 1e6, ".", usdt_balance_after % 1e6);

        vm.stopPrank();
    }

    function getSwapFeesV3(uint256 amount, uint256 fee) public pure returns (uint256) {
        return amount * fee / 1e6;
    }
}
