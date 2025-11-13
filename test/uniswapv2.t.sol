// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {WETH, DAI, MKR, UNISWAP_V2_ROUTER_02} from "../src/Constants.sol";
import {
    IUniswapV2Router02
} from "../lib/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import {IWETH} from "../src/interfaces/IWETH.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

contract UniswapV2SwapAmountsTest is Test {
    IERC20 private constant weth = IERC20(WETH);
    IERC20 private constant dai = IERC20(DAI);
    IERC20 private constant mkr = IERC20(MKR);
    IUniswapV2Router02 private constant router =
        IUniswapV2Router02(UNISWAP_V2_ROUTER_02);

    function test_getAmountsOut() public {
        // getAmountsOut(uint amountIn, address[] memory path)
        // returns(uint[] memory amounts)
        //first you need to prepare an array of addrs that is called path
        address[] memory path = new address[](3);
        path[0] = WETH;
        path[1] = DAI;
        path[2] = MKR;

        uint256 amountIn = 1e18; //10 **18;
        uint256[] memory amounts = router.getAmountsOut(amountIn, path);
        console.log("WETH:", amounts[0]);
        console.log("DAI:", amounts[1]);
        console.log("MKR:", amounts[2]);
    }

    function test_getAmountsIn() public {
        //    function getAmountsIn(uint amountOut, address[] memory path)
        //         public
        //         view
        //         virtual
        //         override
        //         returns (uint[] memory amounts)
        //first you need to prepare an array of addrs that is called path
        address[] memory path = new address[](3);
        path[0] = WETH;
        path[1] = DAI;
        path[2] = MKR;

        uint256 amountOut = 1e14; //10 **18;

        uint256[] memory amounts = router.getAmountsIn(amountOut, path);
        console.log("WETH:", amounts[0]);
        console.log("DAI:", amounts[1]);
        console.log("MKR:", amounts[2]);
        //   WETH: 40755611043506
        //   DAI: 137979305729246508
        //   MKR: 100000000000000
    }
}
