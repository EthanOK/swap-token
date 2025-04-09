// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {ProxyUniswapV4, PoolKey} from "../src/ProxyUniswapV4.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {IPermit2} from "@uniswap/permit2/src/interfaces/IPermit2.sol";
import {TransferHelper} from "../src/libraries/TransferHelper.sol";
import {IV4Quoter} from "@uniswap/v4-periphery/src/interfaces/IV4Quoter.sol";

contract ProxyUniswapV4Test is Test {
    ProxyUniswapV4 public proxy;

    address public constant universalRouter = 0x66a9893cC07D91D95644AEDD05D03f95e1dBA8Af;
    address public constant permit2 = 0x000000000022D473030F116dDEE9F6B43aC78BA3;
    address public constant quoterV4 = 0x52F0E24D1c21C8A0cB1e5a5dD6198556BD9E1203;

    address public constant ZERO = 0x0000000000000000000000000000000000000000;
    address public constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant LINK = 0x514910771AF9Ca656af840dff83E8264EcF986CA;

    address public constant owner = address(0xdddd);

    address public constant user = address(0xeeee);

    address public recipient = address(0xaaaa);

    function setUp() public {
        vm.createSelectFork("https://1rpc.io/eth");
        proxy = new ProxyUniswapV4(universalRouter, permit2, owner);

        // set user balance
        deal(owner, 100 ether);
        deal(user, 100 ether);
        deal(USDT, user, 10000 * 1e6);

        vm.prank(owner);
        proxy.setFeePercent(5000); // 10_000

        PoolKey memory poolKey = PoolKey({
            currency0: Currency.wrap(ZERO),
            currency1: Currency.wrap(USDT),
            fee: 500,
            tickSpacing: 10,
            hooks: IHooks(address(0))
        });

        IV4Quoter quoter = IV4Quoter(quoterV4);

        (uint256 amountOut,) = quoter.quoteExactInputSingle(
            IV4Quoter.QuoteExactSingleParams({
                poolKey: poolKey,
                zeroForOne: true,
                exactAmount: 1 ether,
                hookData: bytes("")
            })
        );
        console.log("UniswapV4 ETH/USDT: ", amountOut / 1e6, ".", amountOut % 1e6);
    }

    function test_SwapExactETHForTokenWithFee() public {
        vm.startPrank(user);

        uint256 amountIn = 1 ether;

        console.log("user Pay 1 ETH");

        PoolKey memory poolKey = PoolKey({
            currency0: Currency.wrap(ZERO),
            currency1: Currency.wrap(USDT),
            fee: 500,
            tickSpacing: 10,
            hooks: IHooks(address(0))
        });

        bool zeroForOne = true;

        proxy.swapExactInputSingle{value: amountIn}(poolKey, zeroForOne, uint128(amountIn), 0, recipient);

        console.log("Deduct %d/%d Proxy Fees After:", proxy.feePercent(), proxy.FEE_DENOMINATOR());

        uint256 balance_recipient = IERC20(USDT).balanceOf(recipient);

        console.log("recipient Get USDT: ", balance_recipient / 1e6, ".", balance_recipient % 1e6);
        vm.stopPrank();
    }

    function test_SwapExactETHForTokenOfficialWithFee() public {
        vm.startPrank(user);

        uint256 amountIn = 1 ether;

        console.log("user Pay 1 ETH");

        PoolKey memory poolKey = PoolKey({
            currency0: Currency.wrap(ZERO),
            currency1: Currency.wrap(USDT),
            fee: 500,
            tickSpacing: 10,
            hooks: IHooks(address(0))
        });

        bool zeroForOne = true;

        proxy.swapExactInputSingleOfficial{value: amountIn}(poolKey, zeroForOne, uint128(amountIn), 0, recipient);

        console.log("Deduct %d/%d Proxy Fees After:", proxy.feePercent(), proxy.FEE_DENOMINATOR());

        uint256 balance_recipient = IERC20(USDT).balanceOf(recipient);

        console.log("recipient Get USDT: ", balance_recipient / 1e6, ".", balance_recipient % 1e6);
        vm.stopPrank();
    }

    function test_SwapExactTokenForETHWithFee() public {
        vm.startPrank(user);

        uint256 amountIn = 2000 * 1e6;

        console.log("user Pay 2000 USDT");

        // approve USDT to proxy
        TransferHelper.safeApprove(USDT, address(proxy), amountIn);

        PoolKey memory poolKey = PoolKey({
            currency0: Currency.wrap(ZERO),
            currency1: Currency.wrap(USDT),
            fee: 500,
            tickSpacing: 10,
            hooks: IHooks(address(0))
        });

        bool zeroForOne = false;

        proxy.swapExactInputSingle(poolKey, zeroForOne, uint128(amountIn), 0, recipient);

        console.log("Deduct %d/%d Proxy Fees After:", proxy.feePercent(), proxy.FEE_DENOMINATOR());

        uint256 balance_recipient = recipient.balance;
        console.log("recipient Get ETH: ", balance_recipient / 1e18, ".", balance_recipient % 1e18);

        vm.stopPrank();
    }

    function test_SwapExactTokenForETHOfficialWithFee() public {
        vm.startPrank(user);

        uint256 amountIn = 2000 * 1e6;

        console.log("user Pay 2000 USDT");

        // approve USDT to proxy
        TransferHelper.safeApprove(USDT, address(proxy), amountIn);

        PoolKey memory poolKey = PoolKey({
            currency0: Currency.wrap(ZERO),
            currency1: Currency.wrap(USDT),
            fee: 500,
            tickSpacing: 10,
            hooks: IHooks(address(0))
        });

        bool zeroForOne = false;

        proxy.swapExactInputSingleOfficial(poolKey, zeroForOne, uint128(amountIn), 0, recipient);

        console.log("Deduct %d/%d Proxy Fees After:", proxy.feePercent(), proxy.FEE_DENOMINATOR());

        uint256 balance_recipient = recipient.balance;
        console.log("recipient Get ETH: ", balance_recipient / 1e18, ".", balance_recipient % 1e18);

        vm.stopPrank();
    }
}
