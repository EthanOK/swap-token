// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {FlashUniswapV3, TransferHelper} from "../src/FlashUniswapV3.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AttackedFlash} from "./demo/AttackedFlash.sol";

contract FlashUniswapV3Test is Test {
    FlashUniswapV3 public flashUniswapV3;

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
        flashUniswapV3 = new FlashUniswapV3(uniswapV3Factory, swapRouter, owner);

        attackedFlash = new AttackedFlash();

        deal(user, 100 ether);

        deal(USDT, address(attackedFlash), 1000 * 1e6);
    }

    function test_FlashSwap() public {
        vm.startPrank(user);

        uint256 amount_debt = 1000 * 1e6;

        uint256 benifit = AttackedFlash(attackedFlash).getBenifit(USDT, amount_debt);
        uint256 flashFees = getSwapFeesV3(amount_debt, 500);
        console.log("benifit:", benifit);
        console.log("flashFees:", flashFees);

        uint256 amount_benifit = benifit - flashFees;
        console.log("Will earn USDT by flash loan:", amount_benifit / 1e6, ".", amount_benifit % 1e6);

        uint256 usdt_balance_before = IERC20(USDT).balanceOf(address(user));
        console.log("usdt_balance_before:", usdt_balance_before);

        FlashUniswapV3.CallParam memory callParam = FlashUniswapV3.CallParam({
            target: address(attackedFlash),
            value: 0,
            data: abi.encodeWithSelector(AttackedFlash.withdraw.selector, address(USDT))
        });

        console.log("execute flash loan");

        flashUniswapV3.flash(WETH, USDT, 0, amount_debt, 500, abi.encode(callParam));

        console.log("finish flash loan");

        uint256 usdt_balance_after = IERC20(USDT).balanceOf(address(user));
        assertEq(amount_benifit, usdt_balance_after - usdt_balance_before);

        console.log("usdt_balance_after:", usdt_balance_after / 1e6, ".", usdt_balance_after % 1e6);

        vm.stopPrank();
    }

    function getSwapFeesV3(uint256 amount, uint256 fee) public pure returns (uint256) {
        return amount * fee / 1e6;
    }
}
