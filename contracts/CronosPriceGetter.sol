// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "./libs/IAMMInfo.sol";
import "./BasePriceGetter.sol";

// This library provides simple price calculations for Crodex tokens, accounting
// for commonly used pairings. Will break if USDT, BUSD, or DAI goes far off peg.
// Should NOT be used as the sole oracle for sensitive calculations such as 
// liquidation, as it is vulnerable to manipulation by flash loans, etc. BETA
// SOFTWARE, PROVIDED AS IS WITH NO WARRANTIES WHATSOEVER.

// Cronos mainnet version

contract CronosPriceGetter is BasePriceGetter {
    
    //Token addresses
    //address constant WBTC = 0x062E66477Faf219F25D27dCED647BF57C3107d52; //8 decimals

    // Crodex LP addresses
    address private constant WCRO_USDT_PAIR = 0x47AB43F8176696CA569b14A24621A46b318096A7;
    address private constant WCRO_DAI_PAIR = 0x586e3658d0299d5e79B53aA51B641d6A0B8A4Dd3;
    address private constant WCRO_USDC_PAIR = 0x182414159C3eeF1435aF91Bcf0d12AbcBe277A46;
    
    address private constant WETH_USDT_PAIR = 0xc061A750B252f36337e960BbC2A7dB96b3Bc7906;
    address private constant USDC_WETH_PAIR = 0x50BEAbE48641D324DB5a1d0EF0e882Db22AE1a75; 
    address private constant WETH_DAI_PAIR = 0x5515094dB1a1B9487955ABe0744ACaa2fa1451F3; 
    
    constructor(address _data) BasePriceGetter(
        _data,
        0x5C7F8A570d578ED84E63fdFA7b1eE72dEae1AE23, //wnative
        0xe44Fd7fCb2b1581822D0c862B68222998a0c299a, //weth
        0x66e428c3f67a68878562e79A0234c1F83c208770, // usdt
        0xc21223249CA28397B4B6541dfFaEcC539BfF0c59, // usdc 6 decimals
        0xF2001B145b43032AAF5Ee2884e456CCd805F677D // dai 18 decimals
    ) {}

    //returns the current USD price of CRO based on primary stablecoin pairs
    function getGasPrice() internal override view returns (uint) {
        (uint wcroReserve0, uint usdtReserve,) = IUniPair(WCRO_USDT_PAIR).getReserves();
        (uint wcroReserve1, uint daiReserve,) = IUniPair(WCRO_DAI_PAIR).getReserves();
        (uint wcroReserve2, uint usdcReserve,) = IUniPair(WCRO_USDC_PAIR).getReserves();
        uint wcroTotal = wcroReserve0 + wcroReserve1 + wcroReserve2;
        uint usdTotal = daiReserve + (usdcReserve + usdtReserve)*1e12; // 1e18 USDC/T == 1e30 DAI
        
        return usdTotal * PRECISION / wcroTotal; 
    }
    
    // //returns the current USD price of CRO based on primary stablecoin pairs
    function getETHPrice() internal override view returns (uint) {
        (uint usdtReserve, uint wethReserve0,) = IUniPair(WETH_USDT_PAIR).getReserves();
//        (uint usdcReserve, uint wethReserve1,) = IUniPair(USDC_WETH_PAIR).getReserves();
//        (uint wethReserve2, uint daiReserve,) = IUniPair(WETH_DAI_PAIR).getReserves();
        uint wethTotal = wethReserve0; //+ wethReserve1 + wethReserve2;
        uint usdTotal = usdtReserve*1e12; //daiReserve + (usdcReserve + usdtReserve)*1e12 //1e18 USDC/T == 1e30 DAI
        
        return usdTotal * PRECISION / wethTotal; 
    }
    
}