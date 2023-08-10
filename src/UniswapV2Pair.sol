// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./libraries/Math.sol";
import "solmate/tokens/ERC20.sol";

contract UniswapV2Pair is ERC20, Math {
  uint256 private reserve0;
  uint256 private reserve1;
//  uint256 private totalSupply;
  address public token0;
  address public token1;

  constructor ()

  function mint() public {
    uint256 liquidity;
    uint256 balance0 = IERC20(token0).balanceOf(address(this));
    uint256 balance1 = IERC20(token1).balanceOf(address(this)); 
    uint256 amount0 = balance0 - reserve0;
    uint256 amount1 = balance1 - reserve1;

    if (totalSupply == 0 ){
      liquidity = Math.sqrt(amount0, amount1) - MINIMUM_LIQUIDITY;
      _mint(address(0), MINIMUM_LIQUIDITY);
    } else {
      liquidity = Math.min(
        (amount0 * totalSupply) / _reserve0,
        (amount1 * totalSupply) / _reserve1
      )
    }

    if (liquidity <= 0) revert insufficientLiquidityMinted()

    _mint(msg.sender, liquidity);
    _update(balance0, balance1);

    emit Mint(msg.sender, amount0, amount1);
  }
}