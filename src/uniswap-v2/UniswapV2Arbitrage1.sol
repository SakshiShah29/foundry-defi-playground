//SPDX_License-Identifier: MIT

pragma solidity ^0.8.24;

import {
    IUniswapV2Pair
} from "../../lib/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import {
    IUniswapV2Router02
} from "../../lib/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import {
    IUniswapV2Pair
} from "../../lib/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

contract UniswapV2Arbitrage1 {
    struct SwapParams {
        address router0; //This will be the router that will execute the first swap. tokenIn for tokenOut
        address router1; //This will be the router that will execute the second swap. tokenOut for tokenIn
        address tokenIn; //The tokenIn of first swap and tokenOut of second swap
        address tokenOut; //The tokenOut of first swap and tokenIn of second swap
        uint256 amountIn; //The amount of tokenIn to swap in the first swap
        uint256 minProfit; //Revert the arbitrage if the profit is less than minProfit
    }

   //
    function _swap(
        SwapParams memory params
    ) private returns (uint256 amountOut) {
        //approve the router0 to spend tokenIn
        IERC20(params.tokenIn).approve(
            address(params.router0),
            params.amountIn
        );
        //1. Execute the first swap from tokenIn to tokenOut using router0
        address[] memory path1 = new address[](2);
        path1[0] = params.tokenIn;
        path1[1] = params.tokenOut;

        //Definition of IUniswapV2Router02.swapExactTokensForTokens(amountIn, amountOutMin, path, to, deadline);
        //  function swapExactTokensForTokens(
        //     uint amountIn,
        //     uint amountOutMin,
        //     address[] calldata path,
        //     address to,
        //     uint deadline
        // ) external virtual override ensure(deadline) returns (uint[] memory amounts)
        uint256[] memory amounts = IUniswapV2Router02(params.router0)
            .swapExactTokensForTokens({
                amountIn: params.amountIn,
                amountOutMin: 0,
                path: path1,
                to: address(this),
                deadline: block.timestamp
            });

        //2. Execute the second swap from tokenOut to tokenIn using router1
        IERC20(params.tokenOut).approve(address(params.router1), amounts[1]);
        address[] memory path2 = new address[](2);
        path2[0] = params.tokenOut;
        path2[1] = params.tokenIn;

        //Same definition as above
        amounts = IUniswapV2Router02(params.router1).swapExactTokensForTokens({
            amountIn: amounts[1],
            amountOutMin: params.amountIn,
            path: path2,
            to: address(this),
            deadline: block.timestamp
        });

        amountOut = amounts[1];
    }

 //Execute the arbitrage between router0 and router1
    //Pull the tokenIn from the msg.sender
    //Send amountIn+profit of tokenIn back to the msg.sender
    function swap(SwapParams calldata params) external {
    //Pull in the tokenIn from msg.sender
    IERC20(params.tokenIn).transferFrom(
        msg.sender,
        address(this),
        params.amountIn
    );
    //Execute the arbitrage
    uint256 amountOut = _swap(params);
    //Calculate the profit
    uint256 profit = amountOut - params.amountIn;
    //Require the profit is greater than minProfit
    require(profit >= params.minProfit, "UniswapV2Arbitrage1: PROFIT_TOO_LOW");
    //Send back amountIn + profit to msg.sender
    IERC20(params.tokenIn).transfer(msg.sender, amountOut);
    }


    // - Execute an arbitrage between router0 and router1 using flash swap
    // - Borrow tokenIn with flash swap from pair
    // - Send profit back to msg.sender
    /**
     * @param pair Address of pair contract to flash swap and borrow tokenIn
     * @param isToken0 True if token to borrow is token0 of pair
     * @param params Swap parameters
     */
    function flashSwap(address pair, bool isToken0, SwapParams calldata params)
        external
    {
     IUniswapV2Pair(pair).swap({
        amount0Out:isToken0?params.amountIn:0,
        amount1Out:isToken0?0:params.amountIn,
        to:address(this),
        data:abi.encode(msg.sender, params,pair)
     });
    }

    function uinswapv2Call(
        address sender,
        uint256 amount0Out,
        uint256 amount1Out,
        bytes calldata data
    ) external {

        //Decode data
        (address caller, SwapParams memory params,address pair) = abi.decode(
            data,
            (address, SwapParams,address)
        );

        //call _swap
        uint256 amountOut = _swap(params);

        //Calculate fee
        uint256 fee = (params.amountIn * 3) / 997 + 1;
        uint256 amountToRepay = params.amountIn + fee;

        //Require profit(amountOut-amountToRepay) is greater than amountToRepay + minProfit
        require(amountOut-amountToRepay >= params.minProfit, "UniswapV2Arbitrage1: PROFIT_TOO_LOW");

        //Repay the pair
        IERC20(params.tokenIn).transfer(address(pair), amountToRepay);

        //Send profit to caller
        IERC20(params.tokenIn).transfer(caller, amountOut - amountToRepay);

       

    }
}
