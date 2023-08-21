// SPDX-License Indentifier: MIT
pragma solidity ^0.8.10;

import "lib/forge-std/src/Test.sol";
import "lib/forge-std/src/console.sol";
import "src/UniswapV2Pair.sol";
import "./mocks/ERC20Mintable.sol";

contract MintBurnTest is Test {
    ERC20Mintable token0;
    ERC20Mintable token1;
    UniswapV2Pair pair;
    address LP1;
    address swapper;

    function setUp() public {
        token0 = new ERC20Mintable("frogmonkee", "FROG");
        token1 = new ERC20Mintable("monkeefrog", "GROF");
        pair = new UniswapV2Pair();
        pair.initialize(address(token0), address(token1));
        swapper = makeAddr("swapper");
        token0.mint(address(swapper), 2 ether);
        token1.mint(address(swapper), 2 ether);
        LP1 = makeAddr("LP1");
        token0.mint(address(LP1), 4 ether);
        token1.mint(address(LP1), 9 ether);
        
        vm.prank(LP1);
        token0.transfer(address(pair), 4 ether);
        vm.prank(LP1);
        token1.transfer(address(pair), 9 ether);
        vm.prank(LP1);
        pair.mint();
    }

    function testOneWaySwap() public {
        vm.prank(swapper);
        token0.transfer(address(pair), 2 ether);
        // Assert that balance of token0 has updated
        assertEq(token0.balanceOf(address(pair)), 6 ether);
        // Assert that pair reserves have not udpated
        assertEq(pair.reserve0(), 4 ether);
        vm.prank(swapper);
        pair.swap(0, 3 ether, address(swapper));
        // Assert that swapper has been transferred 3e18 of token1 after swap (initial balance of 2e18)
        assertEq(token1.balanceOf(swapper), 5 ether);

        // Assert that reserves have been updated
        (uint _reserve0, uint _reserve1) = pair.getReserves();
        assertEq(_reserve0, 6 ether);
        assertEq(_reserve1, 6 ether);
    }

        // Test situation when swapping both tokens for each other
        function testTwoWaySwap() public {
        vm.prank(swapper);
        token0.transfer(address(pair), 2 ether);
        vm.prank(swapper);
        token1.transfer(address(pair), 2 ether);
        vm.prank(swapper);
        // Expects 1 ether of token0Out and 3 ether of token1Out
        pair.swap(1 ether, 3 ether, address(swapper));
        assertEq(token1.balanceOf(swapper), 3 ether);
        assertEq(token0.balanceOf(swapper), 1 ether);
        (uint _reserve0, uint _reserve1) = pair.getReserves();
        assertEq(_reserve0, 5 ether);
        assertEq(_reserve1, 8 ether);
    }

    function testSwapRevertInvalidK() public {
        vm.prank(swapper);
        token0.transfer(address(pair), 2 ether);
        vm.expectRevert();
        vm.prank(swapper);
        pair.swap(0, 4 ether, address(swapper));
    }

    function testSwapRevertInsufficientLiquidity() public {
        vm.prank(swapper);
        token0.transfer(address(pair), 2 ether);
        vm.expectRevert();
        vm.prank(swapper);
        pair.swap(0, 11 ether, address(swapper));
    }
}