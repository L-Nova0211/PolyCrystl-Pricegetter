// SPDX-License-Identifier: GPL
pragma solidity ^0.8.6;


import "./libs/IAMMInfo.sol";
import "./BasePriceGetter.sol";

// This library provides simple price calculations for ApeSwap tokens, accounting
// for commonly used pairings. Will break if USDT, BUSD, or DAI goes far off peg.
// Should NOT be used as the sole oracle for sensitive calculations such as 
// liquidation, as it is vulnerable to manipulation by flash loans, etc. BETA
// SOFTWARE, PROVIDED AS IS WITH NO WARRANTIES WHATSOEVER.

// Polygon mainnet version

contract PolygonPriceGetter is BasePriceGetter {

    //Ape LP addresses
    address private constant WMATIC_USDT_PAIR = 0x65D43B64E3B31965Cd5EA367D4c2b94c03084797;
    address private constant WMATIC_DAI_PAIR = 0x84964d9f9480a1dB644c2B2D1022765179A40F68;
    address private constant WMATIC_USDC_PAIR = 0x019011032a7ac3A87eE885B6c08467AC46ad11CD;
    
    address private constant WETH_USDT_PAIR = 0x7B2dD4bab4487a303F716070B192543eA171d3B2;
    address private constant USDC_WETH_PAIR = 0x84964d9f9480a1dB644c2B2D1022765179A40F68;
    address private constant WETH_DAI_PAIR = 0xb724E5C1Aef93e972e2d4b43105521575f4ca855;

    constructor(address _data) BasePriceGetter(
        _data,
        0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270, //wnative
        0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619, //weth
        0xc2132D05D31c914a87C6611C10748AEb04B58e8F, //usdt
        0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174, //usdc
        0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063 //dai
    ) {}

    //returns the current USD price of MATIC based on primary stablecoin pairs
    function getGasPrice() internal override view returns (uint) {
        (uint wmaticReserve0, uint usdtReserve,) = IUniPair(WMATIC_USDT_PAIR).getReserves();
        (uint wmaticReserve1, uint daiReserve,) = IUniPair(WMATIC_DAI_PAIR).getReserves();
        (uint wmaticReserve2, uint usdcReserve,) = IUniPair(WMATIC_USDC_PAIR).getReserves();
        uint wmaticTotal = wmaticReserve0 + wmaticReserve1 + wmaticReserve2;
        uint usdTotal = daiReserve + (usdcReserve + usdtReserve)*1e12; // 1e18 USDC/T == 1e30 DAI
        
        return usdTotal * PRECISION / wmaticTotal; 
    }
    
    //returns the current USD price of MATIC based on primary stablecoin pairs
    function getETHPrice() internal override view returns (uint) {
        (uint wethReserve0, uint usdtReserve,) = IUniPair(WETH_USDT_PAIR).getReserves();
        (uint usdcReserve, uint wethReserve1,) = IUniPair(USDC_WETH_PAIR).getReserves();
        (uint wethReserve2, uint daiReserve,) = IUniPair(WETH_DAI_PAIR).getReserves();
        uint wethTotal = wethReserve0 + wethReserve1 + wethReserve2;
        uint usdTotal = daiReserve + (usdcReserve + usdtReserve)*1e12; // 1e18 USDC/T == 1e30 DAI
        
        return usdTotal * PRECISION / wethTotal; 
    }
    
}