// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IMasterchef {
    function deposit(uint256 _pid, uint256 _amount) external;

    function withdraw(uint256 _pid, uint256 _amount) external;

    function leaveStaking(uint256 _amount) external;

    function enterStaking(uint256 _amount) external;

    function emergencyWithdraw(uint256 _pid) external;
    
    function userInfo(uint256 _pid, address _address) external view returns (uint256, uint256);

    function poolInfo(uint256 _pid) external view returns (address lpToken, uint256 allocPoint, uint256 lastRewardBlock, uint256 accCrystalPerShare, uint16 depositFeeBP);
    
    function harvest(uint256 _pid, address _to) external;

    function totalAllocPoint() external view returns (uint256);
}