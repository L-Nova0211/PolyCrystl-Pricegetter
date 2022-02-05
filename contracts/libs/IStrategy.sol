// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// For interacting with our own strategy
interface IStrategy {
    // Want address
    function wantAddress() external view returns (address);

    function earnedAddress() external view returns (address);
    
    // Total want tokens managed by strategy
    function wantLockedTotal() external view returns (uint256);

    function vaultSharesTotal() external view returns (uint256);

    // Is strategy paused
    function paused() external view returns (bool);

    // Sum of all shares of users to wantLockedTotal
    function sharesTotal() external view returns (uint256);
    
    // Univ2 router used by this strategy
    function uniRouterAddress() external view returns (address);

    // Main want token compounding function
    function earn() external;

    // Main want token compounding function
    function earn(address _to) external;

    // Transfer want tokens autoFarm -> strategy
    function deposit(address _userAddress, uint256 _wantAmt) external returns (uint256);

    // Transfer want tokens strategy -> vaultChef
    function withdraw(address _userAddress, uint256 _wantAmt) external returns (uint256);
    
    // Returns the strategy's recorded burned amount
    function burnedAmount() external view returns (uint256);

    function pid() external view returns (uint256);
    function tolerance() external view returns (uint256);
    function masterchefAddress() external view returns (address);
}