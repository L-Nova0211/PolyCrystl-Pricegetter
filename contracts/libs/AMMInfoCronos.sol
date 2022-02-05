// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.9;

/*
Join us at Crystl.Finance!
█▀▀ █▀▀█ █░░█ █▀▀ ▀▀█▀▀ █▀▀█ █░░ 
█░░ █▄▄▀ █▄▄█ ▀▀█ ░░█░░ █▄▄█ █░░ 
▀▀▀ ▀░▀▀ ▄▄▄█ ▀▀▀ ░░▀░░ ▀░░▀ ▀▀▀
*/

import "./IAMMInfo.sol";

contract AMMInfoCronos is IAMMInfo {

    address constant private PHOTON_FACTORY = 0x462C98Cae5AffEED576c98A55dAA922604e2D875;
    address constant private CRODEX_FACTORY = 0xe9c29cB475C0ADe80bE0319B74AD112F1e80058F; //0xe9c29cB475C0ADe80bE0319B74AD112F1e80058F
    address constant private CRONA_FACTORY = 0x73A48f8f521EB31c55c0e1274dB0898dE599Cb11; //0x73A48f8f521EB31c55c0e1274dB0898dE599Cb11
    address constant private ELK_FACTORY = 0xEEa0e2830D09D8786Cb9F484cA20898b61819ef1; //0xEEa0e2830D09D8786Cb9F484cA20898b61819ef1
    address constant private CHRONO_FACTORY = 0x6C50Ee65CFcfC59B09C570e55D76daa7c67D6da5; //0x6C50Ee65CFcfC59B09C570e55D76daa7c67D6da5
    address constant private VVS_FACTORY = 0x3B44B2a187a7b3824131F8db5a74194D0a42Fc15;
    //address constant private SMOL_FACTORY = address(0);

    //used for internally locating a pair without an external call to the factory
    bytes32 constant private PHOTON_PAIRCODEHASH = hex'01429e880a7972ebfbba904a5bbe32a816e78273e4b38ffa6bdeaebce8adba7c';
    bytes32 constant private CRODEX_PAIRCODEHASH = hex'03f6509a2bb88d26dc77ecc6fc204e95089e30cb99667b85e653280b735767c8';
    bytes32 constant private CRONA_PAIRCODEHASH = hex'c93158cffa5b575e32566e81e847754ce517f8fa988d3e25cf346d916216e06f';
    bytes32 constant private ELK_PAIRCODEHASH = hex'84845e7ccb283dec564acfcd3d9287a491dec6d675705545a2ab8be22ad78f31';
    bytes32 constant private CHRONO_PAIRCODEHASH = hex'c98c8a44f227342a1b0a885d127d26c6fedc5cc43f38c469de814ed4d0e383b1';
    bytes32 constant private VVS_PAIRCODEHASH = hex'a77ee1cc0f39570ddde947459e293d7ebc2c30ff4e8fc45860afdcb2c2d3dc17';
    //bytes32 constant private SMOL_PAIRCODEHASH = hex''; //?

    // Fees are in increments of 1 basis point (0.01%)
    uint8 constant private PHOTON_FEE = 30; 
    uint8 constant private CRODEX_FEE = 30;
    uint8 constant private CRONA_FEE = 25;
    uint8 constant private ELK_FEE = 30;
    uint8 constant private CHRONO_FEE = 20;
    uint8 constant private VVS_FEE = 30;
    //uint8 constant private SMOL_FEE = 30; //?

    constructor() {
        AmmInfo[] memory list = getAmmList();
        for (uint i; i < list.length; i++) {
            require(IUniRouter02(list[i].router).factory() == list[i].factory, "wrong router/factory");

            IUniFactory f = IUniFactory(list[i].factory);
            IUniPair pair = IUniPair(f.allPairs(0));
            address token0 = pair.token0();
            address token1 = pair.token1();
            
            require(pairFor(token0, token1, list[i].factory, list[i].paircodehash) == address(pair), "bad initcodehash?");

        }

    }

    function getAmmList() public pure returns (AmmInfo[] memory list) {
        list = new AmmInfo[](6);
        list[0] = AmmInfo({
            name: "PhotonSwap", 
            router: 0x69004509291F4a4021fA169FafdCFc2d92aD02Aa, 
            factory: PHOTON_FACTORY,
            paircodehash: PHOTON_PAIRCODEHASH,
            fee: PHOTON_FEE
        });
        list[1] = AmmInfo({
            name: "Crodex", 
            router: 0xeC0A7a0C2439E8Cb67b992b12ecd020Ea943c7Be,
            factory: CRODEX_FACTORY,
            paircodehash: CRODEX_PAIRCODEHASH,
            fee: CRODEX_FEE
        });
        list[2] = AmmInfo({
            name: "CronaSwap", 
            router: 0xcd7d16fB918511BF7269eC4f48d61D79Fb26f918, 
            factory: CRONA_FACTORY,
            paircodehash: CRONA_PAIRCODEHASH,
            fee: CRONA_FEE
        });
        list[3] = AmmInfo({
            name: "Elk Finance", 
            router: 0xdB02A597b283eACb9436Cd2a2d15039a11A3299d,
            factory: ELK_FACTORY,
            paircodehash: ELK_PAIRCODEHASH,
            fee: ELK_FEE
        });
        list[4] = AmmInfo({
            name: "ChronoSwap", 
            router: 0x5bFc95C3BbF50579bD57957cD074fa96a4d5fF9F, 
            factory: CHRONO_FACTORY,
            paircodehash: CHRONO_PAIRCODEHASH,
            fee: CHRONO_FEE
        });
        list[5] = AmmInfo({
            name: "VVS", 
            router: 0x145863Eb42Cf62847A6Ca784e6416C1682b1b2Ae,
            factory: VVS_FACTORY,
            paircodehash: VVS_PAIRCODEHASH,
            fee: VVS_FEE
        });
/*        list[6] = AmmInfo({
            name: "SmolSwap", 
            router: address(0), //!?
            factory: SMOL_FACTORY,
            paircodehash: SMOL_PAIRCODEHASH,
            fee: SMOL_FEE
        });
*/
    }

}