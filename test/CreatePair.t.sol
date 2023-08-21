// SPDX-License Indentifier: MIT
pragma solidity ^0.8.10;

import "lib/forge-std/src/Test.sol";
import "lib/forge-std/src/console.sol";
import "src/UniswapV2Pair.sol";
import "./mocks/ERC20Mintable.sol";
import "src/UniswapV2PairFactory.sol";
import "src/interfaces/IUniswapv2Pair.sol";

contract CreatePair is Test {
    ERC20Mintable token0;
    ERC20Mintable token1;
    UniswapV2PairFactory factory;
    UniswapV2Pair pair;
    address LP1;
    address LP2;

    function setUp() public {
        token0 = new ERC20Mintable("frogmonkee", "FROG");
        token1 = new ERC20Mintable("monkeefrog", "GROF");
        factory = new UniswapV2PairFactory();
        address pairAddress = factory.createPair(address(token0), address(token1));
        pair = UniswapV2Pair(pairAddress);
        LP1 = makeAddr("LP1");
        token0.mint(address(LP1), 4 ether);
        token1.mint(address(LP1), 9 ether);
        LP2 = makeAddr("LP2");
        token0.mint(address(LP2), 9 ether);
        token1.mint(address(LP2), 6 ether);
    }

    function testMintAndBurn() public {
        vm.prank(LP1);
        token0.transfer(address(pair), 4 ether);
        vm.prank(LP1);
        token1.transfer(address(pair), 9 ether);
        vm.prank(LP1);        
        pair.mint(LP1);

        assertEq(pair.balanceOf(LP1), 6 ether - 1000);
        assertEq(pair.reserve1(), 4 ether);
        assertEq(pair.reserve0(), 9 ether);
        assertEq(pair.totalSupply(), 6 ether);

        vm.prank(LP2);
        token0.transfer(address(pair), 9 ether);
        vm.prank(LP2);
        token1.transfer(address(pair), 6 ether);
        vm.prank(LP2);
        pair.mint(LP2);

        // Assets that the mininum # of LP tokens are returned
        assertEq(pair.balanceOf(LP2), 4 ether);
        assertEq(pair.reserve1(), 13 ether);
        assertEq(pair.reserve0(), 15 ether);
        assertEq(pair.totalSupply(), 10 ether);


        vm.prank(LP2);
        pair.burn();
        assertEq(pair.balanceOf(LP2), 0);
        // Not 9 ETH bc LP2 provided lopsided liquidity and only got LP tokens based on 6e18 of token1
        assertEq(token0.balanceOf(LP2), 5.2 ether);
        assertEq(token1.balanceOf(LP2), 6 ether);
    }

    function testCreatePairRevertIdentiticalAddresses() public {
        vm.expectRevert();
        factory.createPair(address(token1), address(token1));
    }
}