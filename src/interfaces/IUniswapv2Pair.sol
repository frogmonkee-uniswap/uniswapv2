// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IUniswapV2Pair {
    function initialize (address, address) external;
    function getReserves() external returns(uint256, uint256);
    function mint(address) external returns(uint256);
}