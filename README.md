# Dark Node

1111 hand-painted oracle NFTs on BNB Chain. Every node has a keeper.

- Website: https://subclip.fun
- X: https://x.com/DarkNode402x

## Mint
| Tier | Price | Max per wallet |
|---|---|---|
| Free Mint | 0.0005 BNB | 10 |
| Paid Mint | 0.005 BNB | 10 |

Shared supply: 1111. 13 series, Golden Oracle legendary x11.

## Repo layout
- `index.html` + assets: the mint site (served by GitHub Pages at subclip.fun)
- `contract/DarkNode.sol`: ERC-721 contract (OpenZeppelin 5.0.2, solc 0.8.24), `DarkNode.abi.json`
- `images/1.jpg ... 1111.jpg`: artwork
- `metadata/1.json ... 1111.json`: token metadata (images served from subclip.fun)
- `hidden.json`, `hidden.jpg`: pre-reveal metadata

## Launch steps
1. Deploy `contract/DarkNode.sol` on BNB Chain (Remix), constructor:
   - `_unrevealedURI` = `https://subclip.fun/hidden.json`
   - `royaltyReceiver` = your wallet (5% royalty)
2. Put the contract address in `index.html` (`const CONTRACT = "0x...";`).
3. `setMintOpen(true, true)` to open both tiers.
4. After sell-out: `reveal("https://subclip.fun/metadata/")`.
5. `withdraw()` to collect mint funds.

Contract is unaudited. Test on BNB Testnet first.
