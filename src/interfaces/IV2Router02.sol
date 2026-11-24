// SPDX-License-Identifier: MIT

pragma solidity 0.8.34;

/**
 * @title IV2Router02
 * @notice Minimal interface for a Uniswap V2-compatible router.
 */
interface IV2Router02 {

    /**
     * @notice Swaps an exact amount of input tokens for as many output tokens as possible.
     * @param amountIn The amount of input tokens to send.
     * @param amountOutMin The minimum amount of output tokens to receive.
     * @param path An array of token addresses representing the swap path.
     * @param to The recipient address for the output tokens.
     * @param deadline Unix timestamp after which the transaction will revert.
     * @return amounts The input and output amounts for each step in the path.
     */
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

}
