// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {StateLibrary} from "@uniswap/v4-core/src/libraries/StateLibrary.sol";
import {IV4Router} from "@uniswap/v4-periphery/src/interfaces/IV4Router.sol";
import {Actions} from "@uniswap/v4-periphery/src/libraries/Actions.sol";
import {IPermit2} from "@uniswap/permit2/src/interfaces/IPermit2.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IUniversalRouter} from "./interfaces/IUniversalRouter.sol";
import {Commands} from "./libraries/Commands.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {TransferHelper} from "./libraries/TransferHelper.sol";
import {ActionConstants} from "@uniswap/v4-periphery/src/libraries/ActionConstants.sol";

contract ProxyUniswapV4 is Ownable {
    using StateLibrary for IPoolManager;

    IUniversalRouter public immutable router;
    IPoolManager public immutable poolManager;
    IPermit2 public immutable permit2;

    uint256 public feePercent = 5_000;

    uint256 public constant FEE_DENOMINATOR = 10_000;

    constructor(address _router, address _permit2, address _initialOwner) Ownable(_initialOwner) {
        router = IUniversalRouter(_router);
        permit2 = IPermit2(_permit2);
        // poolManager = IPoolManager(_poolManager);
    }

    function setFeePercent(uint256 _percent) external onlyOwner {
        require(_percent <= FEE_DENOMINATOR, "Fee cannot exceed  feeBase%");
        feePercent = _percent;
    }

    function swapExactInputSingle(
        PoolKey calldata key,
        bool zeroForOne,
        uint128 amountIn,
        uint128 amountOutMin,
        address recipient
    ) external payable returns (uint256 amountOut) {
        (Currency currencyIn, Currency currencyOut) =
            zeroForOne ? (key.currency0, key.currency1) : (key.currency1, key.currency0);

        // Transfer the input token to Proxy Router
        if (!currencyIn.isAddressZero()) {
            address tokenIn = Currency.unwrap(currencyIn);
            TransferHelper.safeTransferFrom(tokenIn, msg.sender, address(this), amountIn);
            TransferHelper.safeApprove(tokenIn, address(permit2), amountIn);
            permit2.approve(tokenIn, address(router), amountIn, uint48(block.timestamp + 10));
        }

        // Encode the Universal Router command
        bytes memory commands = abi.encodePacked(uint8(Commands.V4_SWAP));
        bytes[] memory inputs = new bytes[](1);

        // Encode V4Router actions
        bytes memory actions =
            abi.encodePacked(uint8(Actions.SWAP_EXACT_IN_SINGLE), uint8(Actions.SETTLE_ALL), uint8(Actions.TAKE_ALL));

        // Prepare parameters for each action
        bytes[] memory params = new bytes[](3);
        params[0] = abi.encode(
            IV4Router.ExactInputSingleParams({
                poolKey: key,
                zeroForOne: zeroForOne,
                amountIn: amountIn,
                amountOutMinimum: amountOutMin,
                hookData: bytes("")
            })
        );

        params[1] = abi.encode(currencyIn, amountIn);
        params[2] = abi.encode(currencyOut, amountOutMin);

        // Combine actions and params into inputs
        inputs[0] = abi.encode(actions, params);

        uint256 amountOut_before = currencyOut.balanceOf(address(this));

        // Execute the swap
        uint256 deadline = block.timestamp + 20;
        router.execute{value: amountIn}(commands, inputs, deadline);

        // Verify and return the output amount
        amountOut = currencyOut.balanceOf(address(this)) - amountOut_before;
        uint256 feeAmount = (amountOut * feePercent) / FEE_DENOMINATOR;
        uint256 userAmount = amountOut - feeAmount;
        require(userAmount >= amountOutMin, "AmountOutMin not met");

        currencyOut.transfer(recipient, userAmount);
        currencyOut.transfer(owner(), feeAmount);

        return userAmount;
    }

    function swapExactInputSingleOfficial(
        PoolKey calldata key,
        bool zeroForOne,
        uint128 amountIn,
        uint128 amountOutMin,
        address recipient
    ) external payable returns (uint256 amountOut) {
        (Currency currencyIn, Currency currencyOut) =
            zeroForOne ? (key.currency0, key.currency1) : (key.currency1, key.currency0);

        // Transfer the input token to Proxy Router
        if (!currencyIn.isAddressZero()) {
            address tokenIn = Currency.unwrap(currencyIn);
            TransferHelper.safeTransferFrom(tokenIn, msg.sender, address(this), amountIn);
            TransferHelper.safeApprove(tokenIn, address(permit2), amountIn);
            permit2.approve(tokenIn, address(router), amountIn, uint48(block.timestamp + 10));
        }

        // Encode the Universal Router command
        bytes memory commands =
            abi.encodePacked(uint8(Commands.V4_SWAP), uint8(Commands.PAY_PORTION), uint8(Commands.SWEEP));
        bytes[] memory inputs = new bytes[](3);

        // Commands.V4_SWAP
        bytes memory actions =
            abi.encodePacked(uint8(Actions.SWAP_EXACT_IN_SINGLE), uint8(Actions.SETTLE), uint8(Actions.TAKE));

        // Prepare parameters for each action
        bytes[] memory params = new bytes[](3);

        // SWAP_EXACT_IN_SINGLE calldata
        params[0] = abi.encode(
            IV4Router.ExactInputSingleParams({
                poolKey: key,
                zeroForOne: zeroForOne,
                amountIn: amountIn,
                amountOutMinimum: amountOutMin,
                hookData: bytes("")
            })
        );

        // SETTLE (Currency currency, uint256 amount, bool payerIsUser)
        params[1] = abi.encode(currencyIn, ActionConstants.OPEN_DELTA, true);

        // TAKE (Currency currency, address recipient, uint256 amount)
        params[2] = abi.encode(currencyOut, ActionConstants.ADDRESS_THIS, ActionConstants.OPEN_DELTA);

        // TODO:Commands.V4_SWAP
        inputs[0] = abi.encode(actions, params);

        // TODO:Commands.PAY_PORTION encode(token, recipient, bips)
        inputs[1] = abi.encode(currencyOut, owner(), feePercent);

        // TODO:Commands.SWEEP encode(token, recipient, amountMinimum)
        inputs[2] = abi.encode(currencyOut, recipient, amountOutMin);

        uint256 amountOut_before = currencyOut.balanceOf(recipient);

        router.execute{value: amountIn}(commands, inputs, block.timestamp + 20);

        amountOut = currencyOut.balanceOf(recipient) - amountOut_before;
    }

    receive() external payable {}
}
