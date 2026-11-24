// SPDX-License-Identifier: MIT

pragma solidity 0.8.34;

import "./interfaces/IV2Router02.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title SwapApp
 * @notice Thin wrapper around a Uniswap V2-compatible router for token-to-token swaps.
 * @dev Pulls tokenIn from the caller, approves the router, executes the swap,
 *      and emits an event with the resulting amounts.
 */
contract SwapApp {
    using SafeERC20 for IERC20;

    /// @notice Address of the Uniswap V2-compatible router used to execute swaps.
    address public v2Router02Address;

    /**
     * @notice Emitted after a successful token swap.
     * @param tokenIn The address of the input token.
     * @param tokenOut The address of the output token.
     * @param amountIn The amount of tokenIn spent.
     * @param amountOut The amount of tokenOut received.
     */
    event SwapTokens(address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOut);

    /**
     * @notice Deploys the swap wrapper pointing to a specific V2 router.
     * @param v2Router02Address_ Address of the Uniswap V2-compatible router.
     */
    constructor(address v2Router02Address_) {
        v2Router02Address = v2Router02Address_;
    }

    /**
     * @notice Swaps an exact amount of tokenIn for at least amountOutMin of tokenOut.
     * @dev Caller must approve this contract to spend at least amountIn_ of path_[0].
     *      Uses forceApprove to handle tokens (e.g. USDT) that require allowance reset before update.
     * @param amountIn_ Amount of input token to swap.
     * @param amountOutMin_ Minimum amount of output token to receive (slippage protection).
     * @param path_ Swap path as an array of token addresses. Must have at least 2 elements.
     * @param deadline_ Unix timestamp after which the transaction will revert.
     */
    function swapTokens(
        uint256 amountIn_,
        uint256 amountOutMin_,
        address[] memory path_,
        uint256 deadline_
    ) external {
        require(path_.length >= 2, "Path must have at least 2 tokens");

        IERC20(path_[0]).safeTransferFrom(msg.sender, address(this), amountIn_);
        IERC20(path_[0]).forceApprove(v2Router02Address, amountIn_);

        uint[] memory amountsOut_ = IV2Router02(v2Router02Address).swapExactTokensForTokens(
            amountIn_,
            amountOutMin_,
            path_,
            msg.sender,
            deadline_
        );

        emit SwapTokens(path_[0], path_[path_.length - 1], amountIn_, amountsOut_[amountsOut_.length - 1]);
    }

}
