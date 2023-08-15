// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./libraries/Math.sol";
import "solmate/tokens/ERC20.sol";

interface IERC20 {
  function balanceOf(address) external returns (uint256);
  function transfer(address to, uint256 amount) external;
}

error InsufficientLiquidityMinted();
error InsufficientLiquidityBurned();

contract UniswapV2Pair is ERC20, Math {
  uint public reserve0;
  uint public reserve1;
  address public token0;
  address public token1;
  uint256 constant MINIMUM_LIQUIDITY = 1000;

  event Mint(address indexed sender, uint256 amount0, uint256 amount1);
  event Burn(address indexed sender, uint256 amount0, uint256 amount1);

  constructor(address _token0, address _token1) ERC20("UniswapV2Pair", "UniV2", 18) {
    token0 = _token0;
    token1 = _token1;
  }

  function mint() public {
    uint256 liquidity;
    uint256 balance0 = IERC20(token0).balanceOf(address(this));
    uint256 balance1 = IERC20(token1).balanceOf(address(this)); 
    uint256 amount0 = balance0 - reserve0;
    uint256 amount1 = balance1 - reserve1;

    if (totalSupply == 0 ){
      liquidity = Math.sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY;
      _mint(address(0), MINIMUM_LIQUIDITY);
    } else {
      liquidity = Math.min(
        (amount0 * totalSupply) / reserve0,
        (amount1 * totalSupply) / reserve1
      );
    }

    if (liquidity <= 0) revert InsufficientLiquidityMinted();

    _mint(msg.sender, liquidity);
    _update(balance0, balance1);

    emit Mint(msg.sender, amount0, amount1);
  }

  function burn() public {
    uint256 liquidity = balanceOf[msg.sender];
    uint256 balance0 = IERC20(token0).balanceOf(address(this));
    uint256 balance1 = IERC20(token1).balanceOf(address(this));
    uint256 amount0 = (balance0 * liquidity) / totalSupply;
    uint256 amount1 = (balance1 * liquidity) / totalSupply;

    if (amount0 <= 0 || amount1 <= 0) revert InsufficientLiquidityBurned();

    _burn(msg.sender, liquidity);

    IERC20(token0).transfer(msg.sender, amount0);
    IERC20(token1).transfer(msg.sender, amount1);

    balance0 = IERC20(token0).balanceOf(address(this));
    balance1 = IERC20(token1).balanceOf(address(this));

    _update(balance0, balance1);

    emit Burn(msg.sender, amount0, amount1);
  }

  function _update(uint256 _balance0, uint256 _balance1) private {
    reserve0 = _balance0;
    reserve1 = _balance1;
  }
}