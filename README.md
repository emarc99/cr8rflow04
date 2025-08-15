# Cr8rFlow: Empowering Creators with Programmable Royalties on Mantle

**Cr8rFlow** is a project built for the **Mantle Cookathon 4** (@0xMantleDevs), enabling creators to mint ERC721 NFTs with automated royalty splits, real-time payouts, and tiered fan access. Deployed on Mantle’s low-cost, high-speed Layer 2 blockchain, Cr8rFlow empowers artists, musicians, and content creators to monetize their work transparently and engage fans through exclusive NFT-based perks, fostering direct creator-fan relationships without centralized platforms.

## Project Overview

Cr8rFlow is a programmable royalty engine designed to decentralize content monetization and fan engagement. Creators can group NFTs into projects (e.g., albums, art collections), define royalty splits for collaborators, and offer tiered perks (e.g., bonus tracks, VIP access) to fans based on NFT ownership. The contract ensures fair, transparent revenue distribution and tracks fan engagement on-chain, leveraging Mantle’s scalability to make Web3 accessible and affordable.

### Key Features
- **NFT Minting**: Creators mint ERC721 NFTs with IPFS-hosted metadata for projects like music albums or digital art.
- **Automated Royalty Splits**: Define contributor percentages (in basis points) for instant, transparent payouts.
- **Tiered Fan Perks**: Fans unlock exclusive rewards based on NFT holdings, enhancing engagement.
- **Engagement Tracking**: On-chain tracking of fan interactions for personalized experiences.
- **Gas Efficiency**: Optimized for Mantle’s Layer 2 to minimize transaction costs.
- **Robust Testing**: Comprehensive Foundry test suite covering project creation, minting, revenue distribution, perk unlocking, and edge cases.

### Target Audience
- **Creators**: Artists, musicians, writers, and digital creators seeking decentralized monetization.
- **Fans**: Supporters who want exclusive access to creator content via NFT ownership.
- **Collaborators**: Contributors (e.g., producers, co-writers) benefiting from transparent royalty splits.

## Why Mantle?
Cr8rFlow leverages Mantle’s high-speed, low-cost Layer 2 infrastructure to make NFT minting, royalty distribution, and fan interactions affordable and scalable. Mantle’s ecosystem ensures creators and fans can engage without high gas fees, aligning with the Cookathon’s focus on innovative, user-friendly Web3 solutions.

## MVP Status
The Cr8rFlow MVP has following completed:
- A Solidity contract (`Cr8rFlow.sol`) implementing ERC721 with custom royalty and perk logic.
- A stunning landing page with a Neo-style cyberpunk aesthetic.

The MVP is ready for testnet deployment and frontend integration, demonstrating a scalable solution for creator economies.

## Future Integrations
To enhance Cr8rFlow’s functionality and align with its goal of empowering creators, the following integrations are planned:

- **Chainlink (@chainlink)**:
  - **Purpose**: Use Chainlink’s decentralized oracles to fetch real-world data, such as streaming metrics or social media engagement, to trigger dynamic royalty splits or perk unlocks.
  - **Impact**: Enables data-driven payouts (e.g., royalties based on streaming numbers) and enhances fan perks with off-chain triggers, making Cr8rFlow adaptable to creator needs and real-world use cases.

- **Orb (@0xOrbLabs)**:
  - **Purpose**: Integrate Orb’s chain abstraction to unify balances and enable multichain transactions, allowing Cr8rFlow’s NFTs and royalty payouts to operate seamlessly across EVM-compatible chains.[](https://www.orblabs.xyz/)
  - **Impact**: Expands Cr8rFlow’s reach by enabling creators to mint NFTs and distribute royalties on multiple blockchains, while fans can interact using a single wallet, enhancing accessibility and user experience.

- **Para (@get_para)**:
  - **Purpose**: Integrate Para’s embedded wallet and authentication suite to simplify fan onboarding with secure, cross-app wallets using social logins and passkeys, supporting EVM, Solana, and Cosmos chains.[](https://www.getpara.com/)
  - **Impact**: Lowers barriers for non-crypto-native fans by enabling seamless wallet creation and interaction with Cr8rFlow’s NFTs and perks, boosting adoption and engagement.

These integrations will make Cr8rFlow a cross-chain, user-friendly, and data-driven platform, amplifying its value for creators and fans in the Web3 ecosystem.
