// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract AttackedFlash {
    using SafeERC20 for IERC20;

    mapping(address => bool) public withdrawStatus;

    function withdraw(address token) external {
        require(withdrawStatus[token] == false, "Already withdraw");

        require(IERC20(token).balanceOf(address(this)) > 0, "Not enough balance in this contract");

        uint256 balance = IERC20(token).balanceOf(msg.sender);

        IERC20(token).safeTransfer(msg.sender, balance / 100);

        withdrawStatus[token] = true;
    }
}
