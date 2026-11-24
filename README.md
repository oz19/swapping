# SwapApp

A thin wrapper around a Uniswap V2-compatible router for token-to-token swaps. The caller approves `SwapApp` to spend the input token; the contract pulls the tokens, approves the router, and executes the swap in a single call.

## Contract

`SwapApp.sol`

| Function | Description |
|---|---|
| `swapTokens(amountIn, amountOutMin, path, deadline)` | Swaps exact `amountIn` of `path[0]` for at least `amountOutMin` of `path[last]`. |

**Constructor parameters**

| Parameter | Description |
|---|---|
| `v2Router02Address_` | Address of the Uniswap V2-compatible router |

## Flow

```
Caller:  approve(swapApp, amountIn)
         → swapTokens(amountIn, amountOutMin, [tokenIn, tokenOut], deadline)

SwapApp: safeTransferFrom caller → self
         forceApprove router for amountIn
         router.swapExactTokensForTokens → tokenOut sent to caller
         emit SwapTokens(...)
```

## Security notes

- Path must contain at least 2 tokens; reverts otherwise.
- Uses `forceApprove` (SafeERC20) instead of `approve` to handle tokens like USDT that require allowance reset before update.

## Usage

```shell
# Build
forge build

# Run unit tests (no RPC needed)
forge test --match-contract TestSwapApp

# Run fork tests (requires Arbitrum RPC)
forge test --match-contract TestSwapAppFork --fork-url https://arb1.arbitrum.io/rpc

# Coverage (unit tests only)
forge coverage
```
