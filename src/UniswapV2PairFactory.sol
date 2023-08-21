// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./UniswapV2Pair.sol";
import "./interfaces/IUniswapv2Pair.sol";

error IdentiticalAddresses();
error PairExists();
error ZeroAddress();

contract UniswapV2PairFactory {
    // Mapping of pair to token1 to token0
    mapping(address => mapping(address => address)) public pairs;
    address[] public allPairs;
    
    event PairCreated(address indexed tokenA, address indexed tokenB, address pair, uint256);

    function createPair(address tokenA, address tokenB) public returns(address pair){
        if (tokenA == tokenB) revert IdentiticalAddresses();
        // If else statement to sort tokens such that lower token value is stored in token0
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        if (token0 == address(0)) revert ZeroAddress();
        if (pairs[token0][token1] != address(0)) revert PairExists();

        // Creates dynamically-sized array with the creation bytecode of the contract
        // https://docs.soliditylang.org/en/latest/units-and-global-variables.html#type-information
        bytes memory bytecode = type(UniswapV2Pair).creationCode;
        // Unique value (salt) derived from the hash of the concatenated token0 and token1 values.
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        IUniswapv2Pair(pair).initialize(token0, token1);
        pairs[token0][token1] = pair;
        pairs[token1][token0] = pair;
        allPairs.push(pair);

        emit PairCreated(token0, token1, pair, allPairs.length);
    }
}