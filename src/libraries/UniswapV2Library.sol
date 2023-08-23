// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "src/interfaces/IUniswapv2Pair.sol";
import "src/interfaces/IUniswapv2PairFactory.sol";
import "src/UniswapV2Pair.sol";

library UniswapV2Library {
//    error InsufficientLiquidity();
    error InsufficientAmount();
    error InvalidPath();

    function getReserves(
        address factoryAddress,
        address tokenA,
        address tokenB
    ) public returns (uint256 reserveA, uint256 reserveB) {
        // Creates local variables for tokens sorted such that token0 > token1
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1) = IUniswapV2Pair(pairFor(factoryAddress, token0, token1)).getReserves();
        // Verifies that the token0 address matches tokenA. Otherwise the order is reversed
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // Standardizes storage mapping such that the less token address is mapped to greater token address
    function sortTokens(address tokenA, address tokenB) internal pure returns(address token0, address token1) {
        return tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    }

    function pairFor(address tokenFactory, address tokenA, address tokenB) internal pure returns (address pairdAdress) {
        return IUniswapV2PairFactory(tokenFactory).pairs(address(tokenA), address(tokenB));
    }

    function getQuote(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
        ) public pure returns (uint256 amountOut) {
            if (amountIn == 0) revert InsufficientAmount();
            if (reserveIn == 0 || reserveOut == 0) revert InsufficientLiquidity();
            return (amountIn * reserveOut) / reserveIn;
        }

    // Single path
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) public pure returns(uint256) {
        if (amountIn == 0) revert InsufficientAmount();
        if (reserveIn == 0 || reserveOut == 0) revert InsufficientLiquidity();
        // Fee is 0.3% = 3/1000
        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = (reserveIn * 1000) + amountInWithFee;
        return (numerator / denominator) + 1;
    }

    // Multiple paths
    function getAmountsOut(
        address factoryAddress,
        uint256 amountIn,
        address[] memory path
    ) public returns(uint256[] memory) {
        // Check to make sure there are at least 2 tokens in the path
        if (path.length < 2) revert InvalidPath();
        uint256[] memory amounts = new uint256[](path.length);
        amounts[0] = amountIn;
        // Iteratively calls getAmountOut for each token in path to build an array of output amounts.
        for(uint i; i < path.length - 1; i++) {
            (uint256 reserve0, uint256 reserve1) = getReserves(factoryAddress, path[i], path[i + 1]);
            amounts[i+1] = getAmountOut(amountIn, reserve0, reserve1);
        }
        return amounts;
    }
}