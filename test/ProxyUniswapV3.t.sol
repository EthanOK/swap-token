// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {ProxyUniswapV3, TransferHelper, IWETH9} from "../src/ProxyUniswapV3.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IQuoterV2} from "@uniswap/v3-periphery/contracts/interfaces/IQuoterV2.sol";

contract ProxyUniswapV3Test is Test {
    ProxyUniswapV3 public proxy;

    address public constant swapRouter = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address public constant quoterV2 = 0x61fFE014bA17989E743c5F6cB21bF9697530B21e;

    address public constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant LINK = 0x514910771AF9Ca656af840dff83E8264EcF986CA;

    address public constant owner = address(0xdddd);

    address public constant user = address(0xeeee);

    address public recipient = address(0xaaaa);

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

        console.log("UniswapV3 ETH/USDT: ", amountOut);

        console.log("user Pay 1 ETH");

        // 0.05% 500
        proxy.swapExactETHForTokenWithFee{value: payAmount}(USDT, 0, 500, user);

        console.log("Deduct %d % Proxy Fees After:", proxy.feePercent());

        uint256 balance_user = IERC20(USDT).balanceOf(user);

        console.log("user Get USDT: ", balance_user);

        vm.stopPrank();
    }

    function test_SwapExactTokenForTokenWithFee() public {
        vm.startPrank(user);
        uint256 payAmount = 1 ether;
        IWETH9(WETH).deposit{value: payAmount}();

        uint256 balance_weth = IERC20(WETH).balanceOf(user);

        assertEq(balance_weth, payAmount);

        IQuoterV2.QuoteExactInputSingleParams memory quoterParams = IQuoterV2.QuoteExactInputSingleParams({
            tokenIn: WETH,
            tokenOut: USDC,
            amountIn: payAmount,
            fee: 500,
            sqrtPriceLimitX96: 0
        });

        (uint256 amountOut,,,) = IQuoterV2(quoterV2).quoteExactInputSingle(quoterParams);
        console.log("WETH/USDC: ", amountOut);

        console.log("user Pay 1 WETH");

        TransferHelper.safeApprove(WETH, address(proxy), payAmount);

        proxy.swapExactTokenForTokenWithFee(WETH, USDC, payAmount, 0, 500, user);

        assertEq(IERC20(WETH).balanceOf(user), 0);

        console.log("Deduct %d % Proxy Fees After:", proxy.feePercent());

        uint256 balance_user_usdc = IERC20(USDC).balanceOf(user);

        console.log("user Get USDC: ", balance_user_usdc);
    }

    function test_SwapExactTokenForETHWithFee() public {
        vm.startPrank(user);

        uint256 usdc_decimals = 6;

        deal(USDC, user, 1000 * 10 ** usdc_decimals);

        uint256 userAmountOut = IERC20(USDC).balanceOf(user);
        console.log("user Pay USDC: ", userAmountOut);

        console.log("USDC -> ETH");
        // USDC -> ETH
        TransferHelper.safeApprove(USDC, address(proxy), userAmountOut);
        uint256 recipientAmountOut = proxy.swapExactTokenForETHWithFee(USDC, userAmountOut, 0, 500, recipient);
        console.log("Deduct %d % Proxy Fees After:", proxy.feePercent());
        assertEq(recipientAmountOut, (recipient).balance);
        console.log("recipient Get ETH: ", recipientAmountOut / 1e18, ".", recipientAmountOut % 1e18);
        vm.stopPrank();
    }

    function test_SwapExactETHForTokensWithFee() public {
        vm.startPrank(user);
        uint256 payAmount = 1 ether;

        console.log("user Pay 1 ETH");
        console.log("Swap Path: ETH -> USDT -> LINK");

        ProxyUniswapV3.TokenOutInfo[] memory tokenOutInfos = new ProxyUniswapV3.TokenOutInfo[](2);
        // ETH -> USDT (0.05%=fee/1e6) fee = 500
        tokenOutInfos[0] = ProxyUniswapV3.TokenOutInfo({poolFee: 500, tokenOut: USDT});
        // USDT -> LINK (0.3%=fee/1e6_ fee = 3000
        tokenOutInfos[1] = ProxyUniswapV3.TokenOutInfo({poolFee: 3000, tokenOut: LINK});

        uint256 userAmountOut = proxy.swapExactETHForTokensWithFee{value: payAmount}(tokenOutInfos, 0, user);
        console.log("Deduct %d % Proxy Fees After:", proxy.feePercent());
        uint256 balance_user_link = IERC20(LINK).balanceOf(user);
        assertEq(balance_user_link, userAmountOut);
        console.log("user Get LINK: ", balance_user_link / 1e18, ".", balance_user_link % 1e18);
        vm.stopPrank();
    }

    function test_SwapExactTokenForTokensWithFee() public {
        vm.startPrank(user);
        uint256 amountIn = 1 ether;

        console.log("user Pay 1 WETH");
        console.log("Swap Path: WETH -> USDT -> LINK");

        // eth -> weth
        IWETH9(WETH).deposit{value: amountIn}();
        // approve weth
        TransferHelper.safeApprove(WETH, address(proxy), amountIn);

        ProxyUniswapV3.TokenOutInfo[] memory tokenOutInfos = new ProxyUniswapV3.TokenOutInfo[](2);
        // WETH -> USDT (0.05%=fee/1e6) fee = 500
        tokenOutInfos[0] = ProxyUniswapV3.TokenOutInfo({poolFee: 500, tokenOut: USDT});
        // USDT -> LINK (0.3%=fee/1e6_ fee = 3000
        tokenOutInfos[1] = ProxyUniswapV3.TokenOutInfo({poolFee: 3000, tokenOut: LINK});

        uint256 userAmountOut = proxy.swapExactTokenForTokensWithFee(WETH, tokenOutInfos, amountIn, 0, user);
        console.log("Deduct %d % Proxy Fees After:", proxy.feePercent());
        uint256 balance_user_link = IERC20(LINK).balanceOf(user);
        assertEq(balance_user_link, userAmountOut);
        console.log("user Get LINK: ", balance_user_link / 1e18, ".", balance_user_link % 1e18);
        vm.stopPrank();
    }

    function test_SwapExactTokenForETHsWithFee() public {
        vm.startPrank(user);
        uint256 amountIn = 1 ether;
        console.log("user Pay 1 WETH");
        console.log("Swap Path: WETH -> USDT -> ETH");
        IWETH9(WETH).deposit{value: amountIn}();
        TransferHelper.safeApprove(WETH, address(proxy), amountIn);

        ProxyUniswapV3.TokenOutInfo[] memory tokenOutInfos = new ProxyUniswapV3.TokenOutInfo[](2);
        // WETH -> USDT (0.05%=fee/1e6) fee = 500
        tokenOutInfos[0] = ProxyUniswapV3.TokenOutInfo({poolFee: 500, tokenOut: USDT});
        // USDT -> WETH
        tokenOutInfos[1] = ProxyUniswapV3.TokenOutInfo({poolFee: 500, tokenOut: WETH});

        TransferHelper.safeApprove(WETH, address(proxy), amountIn);
        uint256 userAmountOut = proxy.swapExactTokenForETHsWithFee(WETH, tokenOutInfos, amountIn, 0, recipient);

        console.log("Deduct %d % Proxy Fees After:", proxy.feePercent());
        assertEq(recipient.balance, userAmountOut);
        console.log("recipient Get ETH: ", recipient.balance / 1e18, ".", recipient.balance % 1e18);
    }
}
