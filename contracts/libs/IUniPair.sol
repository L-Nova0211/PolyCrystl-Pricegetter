// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;

interface IUniPair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112, uint112, uint32);
    function totalSupply() external view returns (uint256);
    function factory() external view returns (address);
}