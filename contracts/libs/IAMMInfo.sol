// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.9;

/*
Join us at Crystl.Finance!
█▀▀ █▀▀█ █░░█ █▀▀ ▀▀█▀▀ █▀▀█ █░░ 
█░░ █▄▄▀ █▄▄█ ▀▀█ ░░█░░ █▄▄█ █░░ 
▀▀▀ ▀░▀▀ ▄▄▄█ ▀▀▀ ░░▀░░ ▀░░▀ ▀▀▀
*/


import "./IUniRouter.sol";
import "./IUniPair.sol";

// calculates the CREATE2 address for a pair without making any external calls
function pairFor(address tokenA, address tokenB, address factory, bytes32 initcodehash) view returns (address pair) {
    if (initcodehash == 0) return IUniFactory(factory).getPair(tokenA, tokenB);

    (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    pair = address(uint160(uint(keccak256(abi.encodePacked(
            hex'ff',
            factory,
            keccak256(abi.encodePacked(token0, token1)),
            initcodehash
    )))));
}

struct AmmInfo {
    string name;
    address router;
    address factory;
    uint8 fee;
    bytes32 paircodehash;
}

interface IAMMInfo {

    function getAmmList() external pure returns (AmmInfo[] memory list);

}