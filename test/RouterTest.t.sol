// SPDX-License Indentifier: MIT
pragma solidity ^0.8.10;

import "lib/forge-std/src/Test.sol";
import "lib/forge-std/src/console.sol";
import "src/UniswapV2Pair.sol";
import "./mocks/ERC20Mintable.sol";
import "src/UniswapV2Router.sol";
import "src/UniswapV2PairFactory.sol";

contract RouterTest is Test {
    ERC20Mintable token0;
    ERC20Mintable token1;
    Uniswapv2PairRouter router;
    UniswapV2PairFactory factory;
    address LP1;
    address LP2;
    address swapper;
    address pairAddress;

    function setUp() public {
        factory = new UniswapV2PairFactory();
        router = new Uniswapv2PairRouter(address(factory));
        token0 = new ERC20Mintable("frogmonkee", "FROG");
        token1 = new ERC20Mintable("monkeefrog", "GROF");
        LP1 = makeAddr("LP1");
        token0.mint(address(LP1), 4 ether);
        token1.mint(address(LP1), 9 ether);
        LP2 = makeAddr("LP2");
        token0.mint(address(LP2), 9 ether);
        token1.mint(address(LP2), 6 ether);
    }

    function testPairCreation() public {
        vm.prank(LP1);
        token0.approve(address(router), 4 ether);
        vm.prank(LP1);
        token1.approve(address(router), 9 ether);
        vm.prank(LP1);
        (uint256 amountA, uint256 amountB, uint256 liquidity) = router.addLiquidity(address(token0), address(token1), 4 ether, 9 ether, 4 ether, 9 ether, LP1);
        assertEq(amountA, 4e18);
        assertEq(amountB, 9e18);
        assertEq(liquidity, 6e18 - 1000);
    }

    function testAddLiquidity() public {
        pairAddress = factory.createPair(address(token0), address(token1));        
        vm.prank(LP1);
        token0.approve(address(router), 4 ether);
        vm.prank(LP1);
        token1.approve(address(router), 9 ether);
        vm.prank(LP1);
        (uint256 LP1amountA, uint256 LP1amountB, uint256 LP1liquidity) = router.addLiquidity(address(token0), address(token1), 4 ether, 9 ether, 4 ether, 9 ether, LP1);
        assertEq(LP1amountA, 4e18);
        assertEq(LP1amountB, 9e18);
        assertEq(LP1liquidity, 6e18 - 1000);

        vm.prank(LP2);
        token0.approve(address(router), 9 ether);
        vm.prank(LP2);
        token1.approve(address(router), 6 ether);
        vm.prank(LP2);
        (, uint256 LP2amountB, uint256 LP2liquidity) = router.addLiquidity(address(token0), address(token1), 9 ether, 6 ether, 1 ether, 1 ether, LP2);
        assertEq(LP2amountB, 6e18);
        assertEq(LP2liquidity, 4e18 - 1);
    }
}