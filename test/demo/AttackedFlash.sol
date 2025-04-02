// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract AttackedFlash {
    using SafeERC20 for IERC20;

    address public constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    mapping(address => bool) public withdrawStatus;

    mapping(address => uint256) bases;

    constructor() {
        bases[USDT] = 100;
    }

    function withdraw(address token) external {
        require(withdrawStatus[token] == false, "Already withdraw");

        require(IERC20(token).balanceOf(address(this)) > 0, "Not enough balance in this contract");

        uint256 balance = IERC20(token).balanceOf(msg.sender);

        IERC20(token).safeTransfer(msg.sender, balance / bases[token]);

        withdrawStatus[token] = true;
    }

    function getBenifit(address token, uint256 amount) external view returns (uint256) {
        uint256 base = bases[token];
        return base > 0 ? amount / bases[token] : 0;
    }
}
