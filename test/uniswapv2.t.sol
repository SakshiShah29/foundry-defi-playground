// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {
    WETH,
    DAI,
    MKR,
    UNISWAP_V2_ROUTER_02,
    UNISWAP_V2_FACTORY,
    UNISWAP_V2_PAIR_DAI_WETH
} from "../src/Constants.sol";
import {
    IUniswapV2Router02
} from "../lib/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import {
    IUniswapV2Factory
} from "../lib/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import {
    IUniswapV2Pair
} from "../lib/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import {IWETH} from "../src/interfaces/IWETH.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {TestToken} from "../src/TestToken.sol";
import {UniswapV2FlashSwap} from "./../src/uniswap-v2/UniswapV2FlashSwap.sol";
import {UniswapV2Twap} from "./../src/uniswap-v2/UniswapV2Twap.sol";

contract UniswapV2SwapAmountsTest is Test {
    IERC20 private constant weth = IERC20(WETH);
    IERC20 private constant dai = IERC20(DAI);
    IERC20 private constant mkr = IERC20(MKR);
    address private constant user = address(1);
    IUniswapV2Router02 private constant router =
        IUniswapV2Router02(UNISWAP_V2_ROUTER_02);
    IUniswapV2Factory private constant factory =
        IUniswapV2Factory(UNISWAP_V2_FACTORY);

    IUniswapV2Pair private constant pair =
        IUniswapV2Pair(UNISWAP_V2_PAIR_DAI_WETH);
    UniswapV2FlashSwap private flashSwap;
    UniswapV2Twap private twap;
    uint256 private constant MIN_WAIT = 300;
    function setUp() public {
        flashSwap = new UniswapV2FlashSwap(UNISWAP_V2_PAIR_DAI_WETH);
        twap = new UniswapV2Twap(address(pair));

        deal(user, 1000 * 1e18);
        vm.startPrank(user);
        IWETH(WETH).deposit{value: 100 * 1e18}();
        weth.approve(address(router), type(uint256).max);
        vm.stopPrank();

        //Fund Dai to the user
        deal(DAI, user, 1000000 * 1e18); //1 million DAI
        vm.startPrank(user);
        dai.approve(address(router), type(uint256).max);
        vm.stopPrank();
    }

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

    function test_swapExactTokensForTokens() public {
        //     //   function swapExactTokensForTokens(
        //     uint amountIn,
        //     uint amountOutMin,
        //     address[] calldata path,
        //     address to,
        //     uint deadline
        // )
        // returns (uint[] memory amounts)
        address[] memory path = new address[](3);
        path[0] = WETH;
        path[1] = DAI;
        path[2] = MKR;

        uint256 amountIn = 1e18;
        uint256 amountOutMin = 1;

        vm.prank(user);
        uint256[] memory amounts = router.swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            path,
            address(user),
            block.timestamp
        );
        console.log("WETH:", amounts[0]);
        console.log("DAI:", amounts[1]);
        console.log("MKR:", amounts[2]);
        assertGe(
            mkr.balanceOf(user),
            amountOutMin,
            "Did not receive minimum amount of MKR"
        );
    }

    function test_swapTokensForExactTokens() public {
        //   function swapTokensForExactTokens(
        //         uint amountOut,
        //         uint amountInMax,
        //         address[] calldata path,
        //         address to,
        //         uint deadline
        // )
        // returns (uint[] memory amounts)
        deal(address(mkr), user, 0);
        address[] memory path = new address[](3);
        path[0] = WETH;
        path[1] = DAI;
        path[2] = MKR;

        uint256 amountOut = 1e16;
        uint256 amountInMax = 1e18;

        vm.prank(user);
        uint256[] memory amounts = router.swapTokensForExactTokens(
            amountOut,
            amountInMax,
            path,
            address(user),
            block.timestamp
        );
        console.log("WETH:", amounts[0]);
        console.log("DAI:", amounts[1]);
        console.log("MKR:", amounts[2]);
        assertEq(
            mkr.balanceOf(user),
            amountOut,
            "Did not receive exact amount of MKR"
        );
    }

    function test_createPair() public {
        TestToken token = new TestToken();

        address pair = factory.createPair(address(token), WETH);

        address token0 = IUniswapV2Pair(pair).token0();
        address token1 = IUniswapV2Pair(pair).token1();
        if (address(token) < WETH) {
            assertEq(token0, address(token), "Token0 address mismatch");
            assertEq(token1, WETH, "Token1 address mismatch");
        } else {
            assertEq(token0, WETH, "Token0 address mismatch");
            assertEq(token1, address(token), "Token1 address mismatch");
        }
    }

    function test_addLiquidity() public {
        //    function addLiquidity(
        //     address tokenA,
        //     address tokenB,
        //     uint amountADesired,
        //     uint amountBDesired,
        //     uint amountAMin,
        //     uint amountBMin,
        //     address to,
        //     uint deadline
        // ) external virtual override ensure(deadline) returns (uint amountA, uint amountB, uint liquidity)
        //DAI/WETH PAIR
        //Current funds of tokens as in setUp functions is 100 DAI and 10 WETH
        uint256 amountADesired = 1e6 * 1e18; //1,000,000 DAI
        uint256 amountBDesired = 100 * 1e18; //100 WETH
        uint256 amountAMin = 1;
        uint256 amountBMin = 1;

        vm.prank(user);
        (uint256 amountA, uint256 amountB, uint256 liquidity) = router
            .addLiquidity(
                DAI,
                WETH,
                amountADesired,
                amountBDesired,
                amountAMin,
                amountBMin,
                user,
                block.timestamp
            );
        console.log("Amount A (DAI):", amountA);
        console.log("Amount B (WETH):", amountB);
        console.log("Liquidity (LP tokens):", liquidity);
        assertGt(pair.balanceOf(user), 0, "LP > 0");
    }

    function test_removeLiquidity() public {
        vm.startPrank(user);
        (, , uint256 liquidity) = router.addLiquidity({
            tokenA: DAI,
            tokenB: WETH,
            amountADesired: 1000000 * 1e18,
            amountBDesired: 100 * 1e18,
            amountAMin: 1,
            amountBMin: 1,
            to: user,
            deadline: block.timestamp
        });
        pair.approve(address(router), liquidity);
        //  function removeLiquidity(
        //         address tokenA,
        //         address tokenB,
        //         uint liquidity,
        //         uint amountAMin,
        //         uint amountBMin,
        //         address to,
        //         uint deadline
        //     ) public virtual override ensure(deadline) returns (uint amountA, uint amountB)

        (uint256 amountA, uint256 amountB) = router.removeLiquidity({
            tokenA: WETH,
            tokenB: DAI,
            liquidity: liquidity,
            amountAMin: 1,
            amountBMin: 1,
            to: user,
            deadline: block.timestamp
        });
        console.log("Removed Amount A:", amountA);
        console.log("Removed Amount B:", amountB);

        vm.stopPrank();

        assertEq(pair.balanceOf(user), 0, "LP = 0");
    }

    function test_flashSwap() public {
        uint256 dai0 = dai.balanceOf(UNISWAP_V2_PAIR_DAI_WETH);
        vm.startPrank(user);
        dai.approve(address(flashSwap), type(uint256).max);
        flashSwap.flashSwap(DAI, 1e4 * 1e18);
        vm.stopPrank();
        uint256 dai1 = dai.balanceOf(UNISWAP_V2_PAIR_DAI_WETH);

        console.log("DAI fee", dai1 - dai0);
        assertGe(dai1, dai0, "DAI balance of pair");
    }

    function test_twap_same_price() public {
        skip(MIN_WAIT + 1);
        twap.update();

        uint256 twap0 = twap.consult(WETH, 1e18);

        skip(MIN_WAIT + 1);
        twap.update();

        uint256 twap1 = twap.consult(WETH, 1e18);

        assertApproxEqAbs(twap0, twap1, 1, "ETH TWAP");
    }

    function test_twap_close_to_last_spot() public {
        // Update TWAP
        skip(MIN_WAIT + 1);
        twap.update();

        // Get TWAP
        uint256 twap0 = twap.consult(WETH, 1e18);

        // Swap
        swap();
        uint256 spot = getSpot();
        console.log("ETH spot price", spot);

        // Update TWAP
        skip(MIN_WAIT + 1);
        twap.update();

        // Get TWAP
        uint256 twap1 = twap.consult(WETH, 1e18);

        console.log("twap0", twap0);
        console.log("twap1", twap1);

        // Check TWAP is close to last spot
        assertLt(twap1, twap0, "twap1 >= twap0");
        assertGe(twap1, spot, "twap1 < spot");
    }
    function getSpot() internal view returns (uint256) {
        (uint112 reserve0, uint112 reserve1, ) = pair.getReserves();
        // DAI / WETH
        return (uint256(reserve0) * 1e18) / uint256(reserve1);
    }

    function swap() internal {
        deal(WETH, address(this), 100 * 1e18);
        weth.approve(address(router), type(uint256).max);

        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = DAI;

        // Input token amount and all subsequent output token amounts
        uint256[] memory amounts = router.swapExactTokensForTokens({
            amountIn: 100 * 1e18,
            amountOutMin: 1,
            path: path,
            to: address(this),
            deadline: block.timestamp
        });
    }
}
