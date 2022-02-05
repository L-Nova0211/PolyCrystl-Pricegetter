// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./libs/IAMMInfo.sol";

abstract contract BasePriceGetter is Ownable {
    
    function getGasPrice() internal virtual view returns (uint);
    function getETHPrice() internal virtual view returns (uint);

    address immutable WNATIVE;
    address immutable USDT;
    address immutable USDC;
    address immutable WETH;
    address immutable DAI;

    address public datafile;

    //Returned prices calculated with this precision (18 decimals)
    uint public constant DECIMALS = 18;
    uint constant PRECISION = 1e18; //1e18 == $1
    
    event SetDatafile(address data);

    constructor(address _data, address _wnative, address _weth, address _usdt, address _usdc, address _dai) {
        datafile = _data;

        WNATIVE = _wnative;
        USDT = _usdt;
        USDC = _usdc;
        WETH = _weth;
        DAI = _dai;
    }

    function setData(address _data) external onlyOwner {
        datafile = _data;
        emit SetDatafile(_data);
    }

    // Normalized to specified number of decimals based on token's decimals and
    // specified number of decimals
    function getPrice(address token, uint _decimals) external view returns (uint) {
        return normalize(getRawPrice(token), token, _decimals);
    }

    function getLPPrice(address token, uint _decimals) external view returns (uint) {
        return normalize(getRawLPPrice(token), token, _decimals);
    }
    function getPrices(address[] calldata tokens, uint _decimals) external view returns (uint[] memory prices) {
        prices = getRawPrices(tokens);
        
        for (uint i; i < prices.length; i++) {
            prices[i] = normalize(prices[i], tokens[i], _decimals);
        }
    }
    function getLPPrices(address[] calldata tokens, uint _decimals) external view returns (uint[] memory prices) {
        prices = getRawLPPrices(tokens);
        
        for (uint i; i < prices.length; i++) {
            prices[i] = normalize(prices[i], tokens[i], _decimals);
        }
    }

    //returns the price of any token in USD based on common pairings; zero on failure
    function getRawPrice(address token) internal view returns (uint) {
        uint pegPrice = pegTokenPrice(token);
        if (pegPrice != 0) return pegPrice;
        
        return getRawPrice(token, getGasPrice(), getETHPrice());
    }


    //returns the value of a LP token if it is one, or the regular price if it isn't LP
    function getRawLPPrice(address token) internal view returns (uint) {
        uint pegPrice = pegTokenPrice(token);
        if (pegPrice != 0) return pegPrice;
        
        return getRawLPPrice(token, getGasPrice(), getETHPrice());
    }
    //returns the prices of multiple tokens which may or may not be LPs
    function getRawLPPrices(address[] calldata tokens) internal view returns (uint[] memory prices) {
        prices = new uint[](tokens.length);
        uint gasPrice = getGasPrice();
        uint ethPrice = getETHPrice();
        
        for (uint i; i < prices.length; i++) {
            address token = tokens[i];
            
            uint pegPrice = pegTokenPrice(token, gasPrice, ethPrice);
            if (pegPrice != 0) prices[i] = pegPrice;
            else prices[i] = getRawLPPrice(token, gasPrice, ethPrice);
        }
    }

        //normalize a token price to a specified number of decimals
    function normalize(uint price, address token, uint _decimals) internal view returns (uint) {
        uint tokenDecimals;
        
        try IERC20Metadata(token).decimals() returns (uint8 dec) {
            tokenDecimals = dec;
        } catch {
            tokenDecimals = 18;
        }

        if (tokenDecimals + _decimals <= 2*DECIMALS) return price / 10**(2*DECIMALS - tokenDecimals - _decimals);
        else return price * 10**(_decimals + tokenDecimals - 2*DECIMALS);
    
    }

    //returns the prices of multiple tokens, zero on failure
    function getRawPrices(address[] calldata tokens) public view returns (uint[] memory prices) {
        prices = new uint[](tokens.length);
        uint gasPrice = getGasPrice();
        uint ethPrice = getETHPrice();
        
        for (uint i; i < prices.length; i++) {
            address token = tokens[i];
            
            uint pegPrice = pegTokenPrice(token, gasPrice, ethPrice);
            if (pegPrice != 0) prices[i] = pegPrice;
            else prices[i] = getRawPrice(token, gasPrice, ethPrice);
        }
    }

    //if one of the peg tokens, returns that price, otherwise zero
    function pegTokenPrice(address token, uint gasPrice, uint ethPrice) internal virtual view returns (uint) {
        if (token == USDT || token == USDC) return PRECISION*1e12;
        if (token == WNATIVE) return gasPrice;
        if (token == WETH) return ethPrice;
        if (token == DAI) return PRECISION;
        return 0;
    }
    function pegTokenPrice(address token) internal virtual view returns (uint) {
        if (token == USDT || token == USDC) return PRECISION*1e12;
        if (token == WNATIVE) return getGasPrice();
        if (token == WETH) return getETHPrice();
        if (token == DAI) return PRECISION;
        return 0;
    }

    // checks for primary tokens and returns the correct predetermined price if possible, otherwise calculates price
    function getRawPrice(address token, uint gasPrice, uint ethPrice) internal view returns (uint rawPrice) {
        uint pegPrice = pegTokenPrice(token, gasPrice, ethPrice);
        if (pegPrice != 0) return pegPrice;

        uint numTokens;
        uint pairedValue;
        
        uint lpTokens;
        uint lpValue;
        
        (lpTokens, lpValue) = pairTokensAndValueMulti(token, WNATIVE);
        numTokens += lpTokens;
        pairedValue += lpValue;
        
        (lpTokens, lpValue) = pairTokensAndValueMulti(token, WETH);
        numTokens += lpTokens;
        pairedValue += lpValue;
        
        (lpTokens, lpValue) = pairTokensAndValueMulti(token, DAI);
        numTokens += lpTokens;
        pairedValue += lpValue;
        
        (lpTokens, lpValue) = pairTokensAndValueMulti(token, USDC);
        numTokens += lpTokens;
        pairedValue += lpValue;
        
        (lpTokens, lpValue) = pairTokensAndValueMulti(token, USDT);
        numTokens += lpTokens;
        pairedValue += lpValue;
        
        if (numTokens > 0) return pairedValue / numTokens;
    }

    //returns the number of tokens and the USD value within a single LP. peg is one of the listed primary, pegPrice is the predetermined USD value of this token
    function pairTokensAndValue(address token, address peg, address factory, bytes32 initcodehash) internal view returns (uint tokenNum, uint pegValue) {

        address tokenPegPair = pairFor(token, peg, factory, initcodehash);
        
        // if the address has no contract deployed, the pair doesn't exist
        uint256 size;
        assembly { size := extcodesize(tokenPegPair) }
        if (size == 0) return (0,0);
        
        try IUniPair(tokenPegPair).getReserves() returns (uint112 reserve0, uint112 reserve1, uint32) {
            uint reservePeg;
            (tokenNum, reservePeg) = token < peg ? (reserve0, reserve1) : (reserve1, reserve0);
            pegValue = reservePeg * pegTokenPrice(peg);
        } catch {
            return (0,0);
        }

    }

    function pairTokensAndValueMulti(address token, address peg) private view returns (uint tokenNum, uint pegValue) {
        
        AmmInfo[] memory amms = IAMMInfo(datafile).getAmmList();
        //across all AMMs in AMMData library
        for (uint i; i < amms.length; i++) {
            (uint tokenNumLocal, uint pegValueLocal) = pairTokensAndValue(token, peg, amms[i].factory, amms[i].paircodehash);
            tokenNum += tokenNumLocal;
            pegValue += pegValueLocal;
        }
    }

    //Calculate LP token value in USD. Generally compatible with any UniswapV2 pair but will always price underlying
    //tokens using Crodex prices. If the provided token is not a LP, it will attempt to price the token as a
    //standard token. This is useful for MasterChef farms which stake both single tokens and pairs
    function getRawLPPrice(address lp, uint gasPrice, uint ethPrice) internal view returns (uint) {
        
        //if not a LP, handle as a standard token
        try IUniPair(lp).getReserves() returns (uint112 reserve0, uint112 reserve1, uint32) {
            
            address token0 = IUniPair(lp).token0();
            address token1 = IUniPair(lp).token1();
            uint totalSupply = IUniPair(lp).totalSupply();
            
            //price0*reserve0+price1*reserve1
            uint totalValue = getRawPrice(token0, gasPrice, ethPrice) * reserve0 
                + getRawPrice(token1, gasPrice, ethPrice) * reserve1;
            
            return totalValue / totalSupply;
            
        } catch {
            return getRawPrice(lp, gasPrice, ethPrice);
        }
    }

}