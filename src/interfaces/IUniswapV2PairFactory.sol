// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IUniswapV2PairFactory {
    function pairs(address, address) external pure returns (address);
    function createPair(address, address) external returns (address);
}