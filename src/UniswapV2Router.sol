// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "src/libraries/UniswapV2Library.sol";

error InsufficientAAmount();
error InsufficientBAmount();
error SafeTransferFailed();

contract Uniswapv2PairRouter {
    IUniswapV2PairFactory factory;

    constructor(address factoryAddress) {
        factory = IUniswapV2PairFactory(factoryAddress);
    }

    function addLiquidity(
        address tokenA, 
        address tokenB, 
        uint256 amountADesired, 
        uint256 amountBDesired, 
        uint256 amountAMin,
        uint256 amountBMin,
        address to) public returns(
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        ) {
        // Creates Uniswapv2 LP if token-pair is not registered in `pairs` mapping
        if (factory.pairs(tokenA, tokenB) == address(0)) {
            factory.createPair(tokenA, tokenB);
        }
        (amountA, amountB) = _calculateLiquidity(
            tokenA,
            tokenB,
            amountADesired,
            amountBDesired,
            amountAMin,
            amountBMin);
        address pairAddress = UniswapV2Library.pairFor(address(factory), tokenA, tokenB);
        _safeTransferFrom(tokenA, msg.sender, pairAddress, amountA);
        _safeTransferFrom(tokenB, msg.sender, pairAddress, amountB);
        liquidity = IUniswapV2Pair(pairAddress).mint(to);
    }

    function _calculateLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin) internal returns(
            uint256 amountA,
            uint256 amountB
        ) {
            (uint256 reserveA, uint256 reserveB) = UniswapV2Library.getReserves(
                address(factory),
                tokenA,
                tokenB
            );
            if(reserveA == 0 && reserveB == 0) {
                // If reserves are empty then this is a new pair,
                // Our newly deposited liquidity will define reserve ratios
                (amountA, amountB) = (amountADesired, amountBDesired);
            } else {
                uint256 amountBOptimal = UniswapV2Library.getQuote(
                    amountADesired,
                    reserveA,
                    reserveB
                );
                if(amountBOptimal <= amountBDesired) {
                    if (amountBOptimal <= amountBMin) revert InsufficientBAmount();
                    (amountA, amountB) = (amountADesired, amountBOptimal);
                } else {
                    uint256 amountAOptimal = UniswapV2Library.getQuote(
                        amountBDesired,
                        reserveB,
                        reserveA
                    );
                    assert(amountAOptimal <= amountADesired);
                    if (amountAOptimal <= amountAMin) revert InsufficientAAmount();
                    (amountA, amountB) = (amountAOptimal, amountBDesired);
                }
            }
        }
    function _safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
        ) private {
            (bool success, bytes memory data) = token.call(
                abi.encodeWithSignature(
                    "transferFrom(address,address,uint256)",
                    from,
                    to,
                    value
                )
            );
            if (!success || (data.length != 0 && !abi.decode(data, (bool))))
                revert SafeTransferFailed();
        }
}