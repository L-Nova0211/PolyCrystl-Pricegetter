// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IStrategy.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IVaultHealer {
    function poolInfo(uint256 pid) external view returns (IERC20 want, IStrategy strat);
    function deposit(uint256 _pid, uint256 _wantAmt, address _to) external;
    function poolLength() external view returns (uint);
    function userInfo(uint256 pid, address user) external view returns (uint256 shares);
}