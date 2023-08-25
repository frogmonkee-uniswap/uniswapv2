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
    ERC20Mintable token2;
    Uniswapv2PairRouter router;
    UniswapV2PairFactory factory;
    
    address LP1;
    address LP2;
    address swapper;

    function setUp() public {
        // Init contracts
        factory = new UniswapV2PairFactory();
        router = new Uniswapv2PairRouter(address(factory));
        token0 = new ERC20Mintable("frogmonkee", "FROG");
        token1 = new ERC20Mintable("monkeefrog", "GROF");
        token2 = new ERC20Mintable("DeezNuts" , "NUTS");
        // Init LP1
        LP1 = makeAddr("LP1");
        token0.mint(address(LP1), 20 ether);
        token1.mint(address(LP1), 20 ether);
        token2.mint(address(LP1), 20 ether);
        // Init LP2
        LP2 = makeAddr("LP2");
        token0.mint(address(LP2), 20 ether);
        token1.mint(address(LP2), 20 ether);
        // Init swapper
        swapper = makeAddr("swapper");
        token0.mint(address(swapper), 1 ether);
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

    function testAddRemoveLiquidity() public {
        address pairAddress = factory.createPair(address(token0), address(token1));        
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

        UniswapV2Pair pair = UniswapV2Pair(pairAddress);
        vm.prank(LP2);
        pair.approve(address(router), LP2liquidity);
        vm.prank(LP2);
        (uint256 amountA, uint256 amountB) = router.removeLiquidity(address(token0), address(token1), LP2liquidity, 5 ether, 2 ether, LP2);
        assertEq(amountA, 6e18 - 1);
        assertEq(amountB, 2666666666666666666);
    }

    function testSwapExactTokensForTokens() public {
        // Pair1 = Token0 (20) <> Token1 (10)
        // Pair2 = Token1 (10) <> Token2 (20)
        factory.createPair(address(token0), address(token1));
        factory.createPair(address(token1), address(token2));
        
        // Seed Pair1 liquidity
        vm.prank(LP1);
        token0.approve(address(router), 20 ether);
        vm.prank(LP1);
        token1.approve(address(router), 10 ether);
        vm.prank(LP1);
        (uint256 Pair1Token0, uint256 Pair1Token1, ) = router.addLiquidity(address(token0), address(token1), 20 ether, 10 ether, 20 ether, 10 ether, LP1);
        assertEq(Pair1Token0, 20e18);
        assertEq(Pair1Token1, 10e18);

        // Seed Pair2 liquidity
        vm.prank(LP1);
        token1.approve(address(router), 10 ether);
        vm.prank(LP1);
        token2.approve(address(router), 20 ether);
        vm.prank(LP1);
        (uint256 Pair2Token1, uint256 Pair2Token2, ) = router.addLiquidity(address(token1), address(token2), 10 ether, 20 ether, 10 ether, 20 ether, LP1);
        assertEq(Pair2Token1, 10e18);
        assertEq(Pair2Token2, 20e18);

        // Swap in 1e18 token0 and out X token2
        address[] memory path = new address[](3);
        path[0] = address(token0);
        path[1] = address(token1);
        path[2] = address(token2);
        vm.prank(swapper);
        token0.approve(address(router), 1 ether);
        vm.prank(swapper);
        router.swapExactTokensForTokens( 1e18,0, path, swapper);
        
        // Assert that swapper receives token2
        assertEq(token2.balanceOf(swapper), 909090909090909090);
    }

    // Inverse flow of testSwapExactTokensForTokens. Exact output is 909090909090909090 and expecitng input as 1e18
    function testSwapTokensForExactTokens() public {
        // Pair1 = Token0 (20) <> Token1 (10)
        // Pair2 = Token1 (10) <> Token2 (20)
        factory.createPair(address(token0), address(token1));
        factory.createPair(address(token1), address(token2));

        // Seed Pair1 liquidity with 20e18 token0 and 10e18 token1
        vm.prank(LP1);
        token0.approve(address(router), 20 ether);
        vm.prank(LP1);
        token1.approve(address(router), 10 ether);
        vm.prank(LP1);
        (uint256 Pair1Token0, uint256 Pair1Token1, ) = router.addLiquidity(address(token0), address(token1), 1 ether, 1 ether, 1 ether, 1 ether, LP1);
        assertEq(Pair1Token0, 1e18);
        assertEq(Pair1Token1, 1e18);

        // Seed Pair2 liquidity with 10e18 token1 and 20e18 token2
        vm.prank(LP1);
        token1.approve(address(router), 10 ether);
        vm.prank(LP1);
        token2.approve(address(router), 20 ether);
        vm.prank(LP1);
        (uint256 Pair2Token1, uint256 Pair2Token2, ) = router.addLiquidity(address(token1), address(token2), 1 ether, 1 ether, 1 ether, 1 ether, LP1);
        assertEq(Pair2Token1, 1e18);
        assertEq(Pair2Token2, 1e18);

        // Swap in X token0 and out 909090909090909090 token 2
        vm.prank(swapper);
        token0.approve(address(router), 0.3e18);
        address[] memory path = new address[](3);
        path[0] = address(token0);
        path[1] = address(token1);
        path[2] = address(token2);
        vm.prank(swapper);
        router.swapTokensForExactTokens(0.186691414219734305 ether, 0.3 ether, path, swapper);
        // Assert that swapper receives token2
        console.log(token0.balanceOf(swapper));


    }

}