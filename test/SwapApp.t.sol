// SPDX-License-Identifier: MIT

// Fork tests (require Arbitrum RPC):
// forge test --fork-url https://arb1.arbitrum.io/rpc --match-test testSwapTokensCorrectly
// forge coverage --fork-url https://arb1.arbitrum.io/rpc

pragma solidity 0.8.34;

import "forge-std/Test.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "../src/SwapApp.sol";
import "../src/interfaces/IV2Router02.sol";

// ─── Mocks ───────────────────────────────────────────────────────────────────

contract MockERC20 is ERC20 {
    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

/// @dev Simulates a V2 router. Mints tokenOut to `to` on every swap call.
contract MockRouter is IV2Router02 {
    function swapExactTokensForTokens(
        uint amountIn,
        uint, /* amountOutMin */
        address[] calldata path,
        address to,
        uint /* deadline */
    ) external override returns (uint[] memory amounts) {
        // Mint tokenOut to recipient to simulate a 1:1 swap
        MockERC20(path[path.length - 1]).mint(to, amountIn);

        amounts = new uint[](path.length);
        for (uint i = 0; i < path.length; i++) {
            amounts[i] = amountIn;
        }
    }
}

// ─── Unit tests (no fork required) ───────────────────────────────────────────

contract TestSwapApp is Test {

    SwapApp app;
    MockRouter router;
    MockERC20 tokenIn;
    MockERC20 tokenOut;
    address user = vm.addr(1);
    uint256 amountIn = 100 ether;

    function setUp() public {
        router = new MockRouter();
        tokenIn = new MockERC20("Token In", "TIN");
        tokenOut = new MockERC20("Token Out", "TOUT");
        app = new SwapApp(address(router));

        tokenIn.mint(user, amountIn);
    }

    function testIsCorrectlyInitialized() public view {
        assert(app.v2Router02Address() == address(router));
    }

    function testSwapRevertsIfPathTooShort() public {
        vm.startPrank(user);
        tokenIn.approve(address(app), amountIn);

        address[] memory path = new address[](1);
        path[0] = address(tokenIn);

        vm.expectRevert("Path must have at least 2 tokens");
        app.swapTokens(amountIn, 0, path, block.timestamp + 1);

        vm.stopPrank();
    }

    function testSwapTokensCorrectlyWithMocks() public {
        vm.startPrank(user);
        tokenIn.approve(address(app), amountIn);

        address[] memory path = new address[](2);
        path[0] = address(tokenIn);
        path[1] = address(tokenOut);

        uint256 tokenInBefore = tokenIn.balanceOf(user);
        uint256 tokenOutBefore = tokenOut.balanceOf(user);

        vm.expectEmit(true, true, false, true);
        emit SwapApp.SwapTokens(address(tokenIn), address(tokenOut), amountIn, amountIn);
        app.swapTokens(amountIn, 0, path, block.timestamp + 1);

        assertEq(tokenIn.balanceOf(user), tokenInBefore - amountIn);
        assertGt(tokenOut.balanceOf(user), tokenOutBefore);

        vm.stopPrank();
    }

}

// ─── Fork tests (Arbitrum Mainnet) ───────────────────────────────────────────

contract TestSwapAppFork is Test {

    SwapApp app;
    address v2Router02Address = 0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24;
    address user = 0xa7A1fe8dDaDE572A76Cebd4c43B2c5ce38893Fde;
    address usdt = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;
    address dai = 0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1;

    function setUp() public {
        // Skip fork tests when no Arbitrum fork is active
        if (block.chainid != 42161) {
            vm.skip(true);
            return;
        }
        app = new SwapApp(v2Router02Address);
    }

    function testSwapTokensCorrectly() public {
        vm.startPrank(user);

        uint256 usdtDecimals_ = 10 ** IERC20Metadata(usdt).decimals();
        uint256 amountIn = 5 * usdtDecimals_;
        IERC20(usdt).approve(address(app), amountIn);

        uint256 daiDecimals_ = 10 ** IERC20Metadata(dai).decimals();
        uint256 amountOutMin = 4 * daiDecimals_;

        uint256 deadline = block.timestamp + 30 days;

        address[] memory path = new address[](2);
        path[0] = usdt;
        path[1] = dai;

        uint256 usdtBefore = IERC20(usdt).balanceOf(user);
        uint256 daiBefore = IERC20(dai).balanceOf(user);

        app.swapTokens(amountIn, amountOutMin, path, deadline);

        uint256 usdtAfter = IERC20(usdt).balanceOf(user);
        uint256 daiAfter = IERC20(dai).balanceOf(user);

        assert(usdtAfter == usdtBefore - amountIn);
        assert(daiAfter > daiBefore);
        assert(daiAfter - daiBefore > amountOutMin);

        vm.stopPrank();
    }

}
