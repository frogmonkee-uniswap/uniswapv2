// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "src/libraries/UniswapV2Library.sol";

error InsufficientAAmount();
error InsufficientBAmount();
error SafeTransferFailed();
error ExcessiveOutputAmount();

contract Uniswapv2PairRouter {
    IUniswapV2PairFactory factory;
    IUniswapV2Pair pair;
    

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
        
        // Returns numebr of tokenA and tokenB we need to deposit according to x*y=k
        (amountA, amountB) = _calculateLiquidity(
            tokenA,
            tokenB,
            amountADesired,
            amountBDesired,
            amountAMin,
            amountBMin);
        address pairAddress = UniswapV2Library.pairFor(address(factory), tokenA, tokenB);
        // In UniswapV2Pair.sol, the user has to manually do this. Routing contract transfers automatically
        _safeTransferFrom(tokenA, msg.sender, pairAddress, amountA);
        _safeTransferFrom(tokenB, msg.sender, pairAddress, amountB);
        liquidity = IUniswapV2Pair(pairAddress).mint(to);
    }

    function removeLiquidity(
        address tokenA,
        address tokenB,
        // Amount of LP tokens to burn
        uint256 liquidity,
        // Minimal # of tokens. Protects against slippage
        uint256 amountAMin,
        uint256 amountBMin,
        address to
    ) public returns(uint256 amountA, uint256 amountB) {
        address pairAddress = UniswapV2Library.pairFor(address(factory), tokenA, tokenB);
        pair = IUniswapV2Pair(pairAddress);
        pair.transferFrom(msg.sender, pairAddress, liquidity);
        (amountA, amountB) = pair.burn(to);
        if (amountA < amountAMin) revert InsufficientAAmount();
        if (amountB < amountBMin) revert InsufficientBAmount();
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to
    ) public returns(uint256[] memory amounts) {
        amounts = UniswapV2Library.getAmountsOut(
            address(factory),
            amountIn,
            path
        );
        // Checks the final amount in array is greater than the minimum amount we want to receive
        if (amounts[amounts.length - 1] < amountOutMin) revert InsufficientOutputAmount();
        _safeTransferFrom(
            path[0],
            msg.sender,
            UniswapV2Library.pairFor(address(factory), path[0], path[1]),
            amounts[0]);

        _swap(amounts, path, to);
    }

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to
    ) public returns (uint256[] memory amounts) {
        amounts = UniswapV2Library.getAmountsIn(
            address(factory),
            amountOut,
            path
        );
        // Checks the final amount in array is greater than the minimum amount we want to receive
        if (amounts[0] > amountInMax) revert ExcessiveOutputAmount();
        _safeTransferFrom(
            path[0],
            msg.sender,
            UniswapV2Library.pairFor(address(factory), path[0], path[1]),
            amounts[0]);

        _swap(amounts, path, to);
    }

    }

    function _calculateLiquidity(
        address tokenA,
        address tokenB,
        // Amount of token A & token B we want to deposit. Upper bound.
        // This is in place of the user manualy transfering tokens into the pair contract (see SwapTest.t.sol)
        uint256 amountADesired,
        uint256 amountBDesired,
        // Minimum amounts of tokens A & B we want to deposit. The lower amount determines LP tokens
        // See `mint` function in UniswapV2Pair.sol
        uint256 amountAMin,
        uint256 amountBMin) internal returns(
            uint256 amountA,
            uint256 amountB
        ) {
            // Need to call library for getReserves instead of directly in UniswapV2Pair.sol contract bc...
            // ... the pair address is not known
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
                // AmountB we need to add if we're depositing AmountADesired
                uint256 amountBOptimal = UniswapV2Library.getQuote(
                    amountADesired,
                    reserveA,
                    reserveB
                );
                // If AmountBOptimial is less than the amountB we're depositing
                // Then only deposit the minimum amountB required (optimal, not desired)
                if(amountBOptimal <= amountBDesired) {
                    if (amountBOptimal <= amountBMin) revert InsufficientBAmount();
                    (amountA, amountB) = (amountADesired, amountBOptimal);
                } else {
                    // AmountA we need to add if we're depositing AmountBDesired
                    uint256 amountAOptimal = UniswapV2Library.getQuote(
                        amountBDesired,
                        reserveB,
                        reserveA
                    );
                    // If this line executes, then amountBOptimal is more than what we are depositing (amountBDesired)
                    // If AmountA has the same problem, then we need to revert. Otherwise user will lose funds
                    assert(amountAOptimal <= amountADesired);
                    if (amountAOptimal <= amountAMin) revert InsufficientAAmount();
                    (amountA, amountB) = (amountAOptimal, amountBDesired);
                }
            }
        }
    
    function _swap(
            uint256[] memory amounts, 
            address[] memory path, 
            address to_) internal {
                for(uint256 i; i < path.length - 1; i++) {
                    (address input, address output) = (path[i], path[i+1]);
                    (address token0, ) = UniswapV2Library.sortTokens(input, output);
                    uint256 amountOut = amounts[i + 1];
                    (uint256 amount0Out, uint256 amount1Out) = input == token0 ? (uint256(0), amountOut) : (amountOut, uint256(0));
                    address to = i < path.length - 2 ? UniswapV2Library.pairFor(address(factory), output, path[i + 2]) : to_; 
                    IUniswapV2Pair(UniswapV2Library.pairFor(address(factory), input, output)).swap(
                        amount0Out,
                        amount1Out,
                        to,
                        ""
                    );
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