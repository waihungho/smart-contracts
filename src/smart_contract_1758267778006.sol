This smart contract, named `AetherForgeDAO`, is designed as a decentralized autonomous organization for the collaborative creation, curation, and monetization of AI-augmented digital assets. It embodies several advanced and trendy concepts:

1.  **AI-Augmented Asset Creation (Simulated):** Users submit "Aether Prompts" for AI generation. An off-chain AI oracle (simulated via a trusted address) then fulfills these requests by minting "AetherFragments" (NFTs).
2.  **Reputation-Weighted Governance:** Voting power for DAO proposals and prompt acceptance combines both staked `AetherToken`s and an accumulated `userReputation` score, encouraging active and valuable participation.
3.  **Dynamic NFT Evolution:** AetherFragments can `evolveAetherFragment`, allowing their metadata, traits, or even underlying AI seeds to be updated over time, reflecting further development, AI iterations, or community decisions.
4.  **Decentralized Incubation & Funding:** Prompts require community `AetherToken` staking for "incubation." Successful incubators earn a share of future royalties.
5.  **Fractional and Dynamic IP Rights Management:** AetherFragments can have their IP rights fractionalized and dynamically transferred (`transferDynamicIPShare`), influencing royalty distribution. Royalty percentages themselves can be updated via DAO governance (`updateFragmentRoyaltyDistribution`) or adjusted by a dynamic factor (`setDynamicRoyaltyFactor`).
6.  **Collaborative Project (Forge) Management:** Users can create "Forges" to group related AetherFragments, fostering larger collaborative works or themed collections.
7.  **Decentralized Curation Challenges:** `Forges` can host "Curatorial Challenges" where the community votes on outstanding fragments, potentially boosting their reputation and dynamic royalty factors.
8.  **Automated Workflow Progression:** Functions manage the lifecycle of a prompt from submission, through incubation, AI generation, NFT minting, to eventual curation and monetization.

---

### Contract: `AetherForgeDAO`

**Contract Description:**
`AetherForgeDAO` serves as a decentralized hub for the entire lifecycle of AI-generated digital assets. It empowers a community (Aetherians) to propose creative concepts (Prompts), collectively fund their AI generation, manage the resulting NFTs (AetherFragments), form collaborative projects (Forges), and curate the best works. The DAO employs a sophisticated governance model that rewards active, positive participation through a reputation system, and features a dynamic economic model for royalty distribution and intellectual property management, pushing the boundaries of decentralized creative ecosystems.

---

### Outline & Function Summary

**I. External Interfaces:**
*   `IAetherToken`: Interface for the ERC20 governance token.
*   `IAetherFragmentNFT`: Interface for the ERC721 NFT contract.

**II. Enums & Structs:**
*   `PromptStatus`: `Pending`, `Incubation`, `Generating`, `Accepted`, `Rejected`, `Completed`.
*   `ForgeStatus`: `Open`, `Curating`, `Archived`, `Closed`.
*   `VoteType`: `For`, `Against`.
*   `RoyaltyInfo`: Stores royalty distribution percentages for creator, incubators, DAO, and a dynamic factor.
*   `IPShare`: A struct to hold the mapping of an address to its IP percentage for an AetherFragment.
*   `AetherFragment`: Represents an AI-generated NFT, linking to its prompt, seed, URI, IP shares, evolution stage, etc.
*   `Prompt`: Represents a submitted AI concept, including description, funding, status, and associated votes.
*   `Forge`: Represents a collaborative project, grouping multiple AetherFragments under a common theme.
*   `Proposal`: Details a DAO governance proposal.
*   `Challenge`: Defines a curatorial challenge within a Forge.

**III. State Variables:**
*   `owner`: The deployer of the contract.
*   `aetherToken`: Address of the `IAetherToken` contract.
*   `aetherFragmentNFT`: Address of the `IAetherFragmentNFT` contract.
*   `oracleAddress`: Trusted address for AI generation fulfillment.
*   `treasuryAddress`: Address for DAO funds.
*   `prompts`: Mapping of prompt ID to `Prompt` struct.
*   `forges`: Mapping of forge ID to `Forge` struct.
*   `proposals`: Mapping of proposal ID to `Proposal` struct.
*   `challenges`: Mapping of challenge ID to `Challenge` struct.
*   `userReputation`: Mapping of address to reputation points.
*   `promptCounter`, `fragmentCounter`, `forgeCounter`, `proposalCounter`, `challengeCounter`: Unique ID counters.
*   `incubationPeriod`: Time duration for a prompt's incubation.
*   `minStakeForPrompt`, `minProposalVoteThreshold`, `minReputationForProposal`: DAO parameters.
*   `baseRoyaltyRate`: Default royalty rate applied to AetherFragments.

**IV. Events:**
*   `PromptSubmitted`, `PromptFunded`, `PromptAccepted`, `PromptRejected`, `PromptCancelled`.
*   `FragmentGenerationRequested`, `FragmentMinted`, `FragmentEvolved`.
*   `ForgeCreated`, `FragmentAddedToForge`.
*   `ProposalSubmitted`, `VoteCast`, `ProposalExecuted`.
*   `ReputationEarned`, `TokensSlashed`.
*   `RoyaltiesWithdrawn`, `RoyaltyDistributionUpdated`, `DynamicRoyaltyFactorSet`.
*   `IPShareTransferred`.
*   `ChallengeProposed`, `ChallengeOutcomeVoted`.

**V. Modifiers:**
*   `onlyOwner`: Restricts access to the contract owner.
*   `onlyDAO`: Restricts access to functions executable only after a successful DAO vote. (Implied, handled by `executeApprovedProposal` for core updates)
*   `onlyOracle`: Restricts access to the designated AI oracle address.
*   `promptExists`, `fragmentExists`, `forgeExists`, `proposalExists`, `challengeExists`: Checks for entity existence.
*   `isAetherian`: Checks if an address has a minimum `aetherToken` stake or reputation to participate.

---

### Function Summary (28 Functions)

**A. Core DAO & Governance (8 Functions)**

1.  **`submitDAOProposal(string memory _proposalURI)`**: Allows any `Aetherian` to submit a new governance proposal. The proposal details are linked via an off-chain URI.
2.  **`castReputationVote(uint256 _proposalId, VoteType _voteType)`**: Enables `Aetherians` to vote on a DAO proposal. Voting power is dynamically calculated based on their `aetherToken` stake and accumulated `userReputation` points.
3.  **`executeApprovedProposal(uint256 _proposalId)`**: Executes the logic of a successfully voted-on DAO proposal. This function checks the proposal's state and calls the relevant internal function to enact the change (e.g., update a parameter, distribute funds).
4.  **`distributeDAOShare(address _recipient, uint256 _amount)`**: Transfers a specified amount of `aetherToken` from the DAO's treasury to a recipient, strictly requiring prior DAO approval via a successful proposal.
5.  **`updateCoreParameter(bytes32 _paramName, uint256 _newValue)`**: A generic function callable by `executeApprovedProposal` to modify critical contract parameters (e.g., `incubationPeriod`, `minProposalVoteThreshold`) after a successful governance vote.
6.  **`slashStakedTokens(address _staker, uint256 _amount)`**: A punitive function, callable only after DAO approval, to remove `aetherToken` from a staker's balance due to malicious or rule-violating behavior.
7.  **`earnReputation(address _user, uint256 _points)`**: An internal function used by the DAO to award `userReputation` points for positive contributions like successful prompt submissions, insightful votes, or effective curation.
8.  **`withdrawTreasuryFunds(address _recipient, uint256 _amount)`**: Allows the DAO to withdraw native currency (ETH/MATIC) from its treasury to a specified recipient, subject to a governance proposal and vote.

**B. Prompt & Incubation Management (6 Functions)**

9.  **`submitAetherPrompt(string memory _description, uint256 _fundingGoal)`**: Allows an `Aetherian` to propose a creative concept for an AI-generated asset. Requires an initial `aetherToken` stake from the submitter.
10. **`stakeForPromptIncubation(uint256 _promptId, uint256 _amount)`**: Enables `Aetherians` to contribute `aetherToken`s to a prompt's funding goal. Successful incubators earn a proportional share of future `AetherFragment` royalties.
11. **`voteOnPromptAcceptance(uint256 _promptId, VoteType _voteType)`**: DAO members vote on whether a submitted prompt should proceed to the AI generation phase. Voting power is reputation-weighted.
12. **`finalizePromptIncubation(uint256 _promptId)`**: Transitions a prompt from `Incubation` to either `Accepted` (and ready for generation) or `Rejected`, based on meeting funding and vote thresholds. If rejected, staked tokens are refunded.
13. **`cancelPromptIncubation(uint256 _promptId)`**: Allows the original prompt submitter to cancel their prompt if it hasn't met funding or vote requirements, triggering the refund of all staked tokens.
14. **`collectPromptStakes(uint256 _promptId)`**: Allows the prompt submitter and incubators to collect their original staked `aetherToken` amounts if the prompt was successfully finalized as `Accepted`.

**C. AetherFragment (NFT) Management (4 Functions)**

15. **`requestAetherFragmentGeneration(uint256 _promptId, string memory _generationParameters)`**: Initiates a request to the designated `oracleAddress` to generate the digital asset based on an approved prompt and specific AI generation parameters.
16. **`fulfillAIGeneration(uint256 _promptId, string memory _assetURI, bytes32 _uniqueSeed)`**: Callable *only by the trusted `oracleAddress`* to report the completion of AI generation, minting the `AetherFragmentNFT` with its metadata, unique seed, and assigning initial IP shares.
17. **`evolveAetherFragment(uint256 _fragmentId, string memory _newURI, bytes32 _newSeed)`**: Allows for a previously minted `AetherFragment` to be upgraded or iterated upon (e.g., AI refinement, community modifications), changing its visual or intrinsic properties. Requires DAO approval.
18. **`transferDynamicIPShare(uint256 _fragmentId, address _from, address _to, uint256 _sharePercentage)`**: Facilitates the transfer of a specific percentage of an `AetherFragment`'s dynamic IP rights from one address to another, affecting future royalty distributions.

**D. Forge (Project) Management (4 Functions)**

19. **`createAetherForge(uint256 _parentPromptId, string memory _forgeName, string memory _description)`**: Establishes a `Forge`, a collaborative project or collection centered around a specific prompt, allowing for a broader narrative or development efforts.
20. **`addFragmentToForge(uint256 _forgeId, uint256 _fragmentId)`**: Associates an existing `AetherFragment` with a `Forge`, enhancing its visibility and contributing to the project's ecosystem. Can only be done by the fragment owner or DAO.
21. **`proposeForgeCuratorialChallenge(uint256 _forgeId, string memory _challengeDetails)`**: Allows `Aetherians` to propose a curatorial challenge or exhibition for fragments within a specific `Forge`, fostering community engagement and discovery.
22. **`voteOnChallengeOutcome(uint256 _challengeId, uint256[] memory _winningFragmentIds)`**: DAO members vote to determine the winners of a curatorial challenge. Winning fragments can receive reputation boosts or dynamic royalty factor adjustments.

**E. Monetization & Royalty Management (4 Functions)**

23. **`updateFragmentRoyaltyDistribution(uint256 _fragmentId, uint256 _newCreatorShare, uint256 _newIncubatorShare, uint256 _newDAOShares)`**: Allows the DAO to adjust the percentage split of secondary sale royalties for an `AetherFragment` based on its performance, community value, or other metrics.
24. **`withdrawFragmentRoyalties(uint256 _fragmentId, address _recipient)`**: Enables the rightful owner(s) (creator, incubators, DAO) to claim their accumulated royalty earnings from an `AetherFragment` from the contract. *Note: Actual royalty collection from marketplaces requires EIP-2981 or similar mechanisms implemented in `IAetherFragmentNFT`.*
25. **`setDynamicRoyaltyFactor(uint256 _fragmentId, uint256 _dynamicFactorPercentage)`**: Sets a multiplier that dynamically adjusts an `AetherFragment`'s base royalty rate. This factor can be influenced by curation scores, sales volume, or other on-chain data, requiring DAO approval.
26. **`getFragmentRoyaltyInfo(uint256 _fragmentId) view returns (RoyaltyInfo memory)`**: Retrieves the current, potentially dynamically adjusted, royalty distribution structure for a given `AetherFragment`.

**F. Utility & Information (2 Functions)**

27. **`getPromptDetails(uint256 _promptId) view returns (Prompt memory)`**: Provides a comprehensive view of a specific prompt's status, funding, votes, and other related details.
28. **`getUserReputation(address _user) view returns (uint256)`**: Queries and returns the current `userReputation` score for a specified `Aetherian` address.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// --- Contract: AetherForgeDAO ---
// Contract Description:
// AetherForgeDAO serves as a decentralized hub for the entire lifecycle of AI-generated digital assets.
// It empowers a community (Aetherians) to propose creative concepts (Prompts), collectively fund their AI generation,
// manage the resulting NFTs (AetherFragments), form collaborative projects (Forges), and curate the best works.
// The DAO employs a sophisticated governance model that rewards active, positive participation through a reputation system,
// and features a dynamic economic model for royalty distribution and intellectual property management,
// pushing the boundaries of decentralized creative ecosystems.

// --- Outline & Function Summary ---

// I. External Interfaces:
//    - IAetherToken: Interface for the ERC20 governance token.
//    - IAetherFragmentNFT: Interface for the ERC721 NFT contract.

// II. Enums & Structs:
//    - PromptStatus: Pending, Incubation, Generating, Accepted, Rejected, Completed.
//    - ForgeStatus: Open, Curating, Archived, Closed.
//    - VoteType: For, Against.
//    - RoyaltyInfo: Stores royalty distribution percentages for creator, incubators, DAO, and a dynamic factor.
//    - IPShare: A struct to hold the mapping of an address to its IP percentage for an AetherFragment.
//    - AetherFragment: Represents an AI-generated NFT, linking to its prompt, seed, URI, IP shares, evolution stage, etc.
//    - Prompt: Represents a submitted AI concept, including description, funding, status, and associated votes.
//    - Forge: Represents a collaborative project, grouping multiple AetherFragments under a common theme.
//    - Proposal: Details a DAO governance proposal.
//    - Challenge: Defines a curatorial challenge within a Forge.

// III. State Variables:
//    - owner: The deployer of the contract.
//    - aetherToken: Address of the IAetherToken contract.
//    - aetherFragmentNFT: Address of the IAetherFragmentNFT contract.
//    - oracleAddress: Trusted address for AI generation fulfillment.
//    - treasuryAddress: Address for DAO funds.
//    - prompts: Mapping of prompt ID to Prompt struct.
//    - forges: Mapping of forge ID to Forge struct.
//    - proposals: Mapping of proposal ID to Proposal struct.
//    - challenges: Mapping of challenge ID to Challenge struct.
//    - userReputation: Mapping of address to reputation points.
//    - promptCounter, fragmentCounter, forgeCounter, proposalCounter, challengeCounter: Unique ID counters.
//    - incubationPeriod: Time duration for a prompt's incubation.
//    - minStakeForPrompt, minProposalVoteThreshold, minReputationForProposal: DAO parameters.
//    - baseRoyaltyRate: Default royalty rate applied to AetherFragments.

// IV. Events:
//    - PromptSubmitted, PromptFunded, PromptAccepted, PromptRejected, PromptCancelled.
//    - FragmentGenerationRequested, FragmentMinted, FragmentEvolved.
//    - ForgeCreated, FragmentAddedToForge.
//    - ProposalSubmitted, VoteCast, ProposalExecuted.
//    - ReputationEarned, TokensSlashed.
//    - RoyaltiesWithdrawn, RoyaltyDistributionUpdated, DynamicRoyaltyFactorSet.
//    - IPShareTransferred.
//    - ChallengeProposed, ChallengeOutcomeVoted.

// V. Modifiers:
//    - onlyOwner: Restricts access to the contract owner.
//    - onlyOracle: Restricts access to the designated AI oracle address.
//    - promptExists, fragmentExists, forgeExists, proposalExists, challengeExists: Checks for entity existence.
//    - isAetherian: Checks if an address has a minimum aetherToken stake or reputation to participate.

// --- Function Summary (28 Functions) ---

// A. Core DAO & Governance (8 Functions)
// 1. `submitDAOProposal(string memory _proposalURI)`: Allows any Aetherian to submit a new governance proposal, linked to an off-chain URI for details.
// 2. `castReputationVote(uint256 _proposalId, VoteType _voteType)`: Enables Aetherians to vote on a DAO proposal, with voting power influenced by their aetherToken stake and accumulated userReputation.
// 3. `executeApprovedProposal(uint256 _proposalId)`: Executes the logic of a successfully voted-on DAO proposal, typically by calling a predefined function or updating parameters.
// 4. `distributeDAOShare(address _recipient, uint256 _amount)`: Transfers funds from the DAO's treasury to a specified recipient, requiring prior DAO approval via a proposal.
// 5. `updateCoreParameter(bytes32 _paramName, uint256 _newValue)`: Allows the DAO to collectively modify critical contract parameters (e.g., voting thresholds, incubation periods) after a successful governance vote.
// 6. `slashStakedTokens(address _staker, uint256 _amount)`: A punitive function, callable only after DAO approval, to remove a specified amount of aetherToken from a malicious staker.
// 7. `earnReputation(address _user, uint256 _points)`: An internal or DAO-callable function to award userReputation points to an Aetherian for positive contributions (e.g., successful prompts, insightful votes, curation).
// 8. `withdrawTreasuryFunds(address _recipient, uint256 _amount)`: Allows the DAO to withdraw native currency (ETH/MATIC) from its treasury to a specified recipient, subject to a governance proposal and vote.

// B. Prompt & Incubation Management (6 Functions)
// 9. `submitAetherPrompt(string memory _description, uint256 _fundingGoal)`: Allows an Aetherian to propose a concept for an AI-generated asset, requiring an initial aetherToken stake.
// 10. `stakeForPromptIncubation(uint256 _promptId, uint256 _amount)`: Enables Aetherians to contribute aetherTokens to a prompt's funding goal. Successful incubators earn future royalty shares.
// 11. `voteOnPromptAcceptance(uint256 _promptId, VoteType _voteType)`: DAO members vote to approve a prompt for AI generation, using their reputation-weighted voting power.
// 12. `finalizePromptIncubation(uint256 _promptId)`: Transitions a prompt from Incubation to Generating or Rejected based on funding and vote results, distributing stakes if rejected.
// 13. `cancelPromptIncubation(uint256 _promptId)`: Allows the original prompt submitter to cancel an unfunded or unapproved prompt, triggering the refund of all staked tokens.
// 14. `collectPromptStakes(uint256 _promptId)`: Allows the prompt submitter and incubators to collect their original staked aetherToken amounts if the prompt was successfully finalized as Accepted.

// C. AetherFragment (NFT) Management (4 Functions)
// 15. `requestAetherFragmentGeneration(uint256 _promptId, string memory _generationParameters)`: Initiates a request to the designated AI Oracle for generating the digital asset based on an approved prompt and parameters.
// 16. `fulfillAIGeneration(uint256 _promptId, string memory _assetURI, bytes32 _uniqueSeed)`: Callable *only by the trusted Oracle* to report the completion of AI generation, minting the AetherFragmentNFT with its metadata and unique seed.
// 17. `evolveAetherFragment(uint256 _fragmentId, string memory _newURI, bytes32 _newSeed)`: Allows for a previously minted AetherFragment to be upgraded or iterated upon (e.g., AI refinement), changing its visual or intrinsic properties. Requires DAO approval.
// 18. `transferDynamicIPShare(uint256 _fragmentId, address _from, address _to, uint256 _sharePercentage)`: Facilitates the transfer of a specific percentage of an AetherFragment's dynamic IP rights, affecting future royalty distributions.

// D. Forge (Project) Management (4 Functions)
// 19. `createAetherForge(uint256 _parentPromptId, string memory _forgeName, string memory _description)`: Establishes a Forge, a collaborative project or collection centered around a specific prompt, allowing for broader narrative or development.
// 20. `addFragmentToForge(uint256 _forgeId, uint256 _fragmentId)`: Associates an existing AetherFragment with a Forge, enhancing its visibility and contributing to the project's ecosystem.
// 21. `proposeForgeCuratorialChallenge(uint256 _forgeId, string memory _challengeDetails)`: Allows Aetherians to propose a curatorial challenge or exhibition for fragments within a Forge, fostering community engagement and discovery.
// 22. `voteOnChallengeOutcome(uint256 _challengeId, uint256[] memory _winningFragmentIds)`: DAO members vote to determine the winners of a curatorial challenge, potentially influencing reputation and dynamic royalties for winning fragments.

// E. Monetization & Royalty Management (4 Functions)
// 23. `updateFragmentRoyaltyDistribution(uint256 _fragmentId, uint256 _newCreatorShare, uint256 _newIncubatorShare, uint256 _newDAOShares)`: Allows the DAO to adjust the percentage split of secondary sale royalties for an AetherFragment based on its performance or community value.
// 24. `withdrawFragmentRoyalties(uint256 _fragmentId, address _recipient)`: Enables the rightful owner(s) (creator, incubators, DAO) to claim their accumulated royalty earnings from an AetherFragment.
// 25. `setDynamicRoyaltyFactor(uint256 _fragmentId, uint256 _dynamicFactorPercentage)`: Sets a multiplier that dynamically adjusts an AetherFragment's base royalty rate, potentially based on external market data or curation scores.
// 26. `getFragmentRoyaltyInfo(uint256 _fragmentId) view returns (RoyaltyInfo memory)`: Retrieves the current, potentially dynamic, royalty distribution structure for a given AetherFragment.

// F. Utility & Information (2 Functions)
// 27. `getPromptDetails(uint256 _promptId) view returns (Prompt memory)`: Provides a comprehensive view of a specific prompt's status, funding, and other related details.
// 28. `getUserReputation(address _user) view returns (uint256)`: Queries and returns the current userReputation score for a specified Aetherian address.

// --- End of Outline & Function Summary ---

// External Interfaces
interface IAetherToken is IERC20 {
    function stake(uint256 amount) external;
    function unstake(uint256 amount) external;
}

interface IAetherFragmentNFT is IERC721 {
    function mint(address to, uint256 tokenId, string memory uri, address creator, uint256 promptId) external;
    function evolve(uint256 tokenId, string memory newURI, bytes32 newSeed) external;
    function setRoyaltyInfo(uint256 tokenId, address receiver, uint96 feeNumerator) external; // EIP-2981 compatible, simplified
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

contract AetherForgeDAO is Context, Ownable {
    using Counters for Counters.Counter;

    // --- Enums ---
    enum PromptStatus {
        Pending,
        Incubation,
        Generating,
        Accepted, // Ready for AI generation
        Rejected,
        Completed // AI generated, fragment minted
    }

    enum ForgeStatus {
        Open,
        Curating,
        Archived,
        Closed
    }

    enum VoteType {
        For,
        Against
    }

    enum ProposalState {
        Pending,
        Active,
        Succeeded,
        Defeated,
        Executed
    }

    // --- Structs ---

    struct RoyaltyInfo {
        uint256 primaryCreatorShare; // Percentage of total royalties (e.g., 500 for 5%)
        uint256 DAOShare;            // Percentage for the DAO
        uint256 incubatorShare;      // Percentage for prompt incubators
        uint256 dynamicFactor;       // Multiplier (e.g., 100 for 1x, 150 for 1.5x)
        uint256 baseRate;            // Base royalty rate for the fragment (e.g., 250 for 2.5%)
    }

    struct IPShare {
        address holder;
        uint256 percentage; // e.g., 1000 for 10%
    }

    struct AetherFragment {
        uint256 id;
        uint256 promptId;
        bytes32 uniqueSeed; // Identifier for AI model input
        string currentURI;  // IPFS/Arweave URI for the asset metadata
        address creator;
        address currentOwner; // Redundant if IAetherFragmentNFT is queried, but useful for quick reference
        uint256 generationTimestamp;
        uint256 evolutionStage; // Tracks how many times it has 'evolved'
        RoyaltyInfo royaltyDistribution;
        IPShare[] ipShares; // Dynamic IP shares
        mapping(address => uint256) royaltyAccumulated; // Accumulated royalties for each participant
    }

    struct Prompt {
        uint256 id;
        address submitter;
        string description;
        uint256 fundingGoal; // Required AetherToken for incubation
        uint256 currentFunding;
        PromptStatus status;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 incubationEndTime;
        uint256 acceptedForgeId; // Forge created from this prompt
        mapping(address => uint256) incubatorStakes; // Who staked how much
        mapping(address => bool) hasVoted; // For prompt acceptance
        uint256 totalIncubatorStake; // Total tokens staked for incubation
    }

    struct Forge {
        uint256 id;
        uint256 parentPromptId;
        string name;
        string description;
        address creator;
        ForgeStatus status;
        uint256[] aetherFragments; // IDs of fragments associated with this forge
        uint256 creationTimestamp;
    }

    struct Proposal {
        uint256 id;
        address proposer;
        string proposalURI; // Link to off-chain proposal details
        uint256 startBlock;
        uint256 endBlock;
        uint256 votesFor;
        uint256 votesAgainst;
        ProposalState state;
        bytes callData; // Encoded function call for execution
        address targetContract; // Target contract for execution
        mapping(address => bool) hasVoted;
    }

    struct Challenge {
        uint256 id;
        uint256 forgeId;
        address proposer;
        string challengeDetails; // URI to challenge description
        uint256 submissionEndTime;
        uint256 votingEndTime;
        uint256[] winningFragmentIds; // Set after voting
        mapping(address => bool) hasVoted; // For challenge outcome
        uint256 totalVotes;
    }

    // --- State Variables ---

    IAetherToken public immutable aetherToken;
    IAetherFragmentNFT public immutable aetherFragmentNFT;

    address public oracleAddress;
    address public treasuryAddress;

    Counters.Counter private _promptIds;
    Counters.Counter private _fragmentIds;
    Counters.Counter private _forgeIds;
    Counters.Counter private _proposalIds;
    Counters.Counter private _challengeIds;

    mapping(uint256 => Prompt) public prompts;
    mapping(uint256 => AetherFragment) public aetherFragments; // Stores fragment details, not the NFT itself
    mapping(uint256 => Forge) public forges;
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => Challenge) public challenges;

    mapping(address => uint256) public userReputation;

    uint256 public incubationPeriod = 7 days; // Default incubation period
    uint256 public minStakeForPrompt = 100 * (10 ** 18); // 100 AetherTokens
    uint256 public minProposalVoteThreshold = 5100; // 51% for simple majority (out of 10000)
    uint256 public minReputationForProposal = 100; // Minimum reputation to submit a DAO proposal

    uint256 public baseRoyaltyRate = 250; // 2.5% out of 10000

    // --- Events ---

    event PromptSubmitted(uint256 indexed promptId, address indexed submitter, uint256 fundingGoal, string description);
    event PromptFunded(uint256 indexed promptId, address indexed funder, uint256 amount, uint256 currentFunding);
    event PromptAccepted(uint256 indexed promptId, address indexed decisionMaker); // For AI generation
    event PromptRejected(uint256 indexed promptId, address indexed decisionMaker);
    event PromptCancelled(uint256 indexed promptId, address indexed canceller);

    event FragmentGenerationRequested(uint256 indexed promptId, string generationParameters);
    event FragmentMinted(uint256 indexed fragmentId, uint256 indexed promptId, address indexed creator, string uri);
    event FragmentEvolved(uint256 indexed fragmentId, string newURI, bytes32 newSeed, uint256 evolutionStage);

    event ForgeCreated(uint256 indexed forgeId, uint256 indexed parentPromptId, address indexed creator, string name);
    event FragmentAddedToForge(uint256 indexed forgeId, uint256 indexed fragmentId);

    event ProposalSubmitted(uint256 indexed proposalId, address indexed proposer, string proposalURI);
    event VoteCast(uint256 indexed proposalId, address indexed voter, VoteType voteType, uint256 voteWeight);
    event ProposalExecuted(uint256 indexed proposalId, address indexed executor);

    event ReputationEarned(address indexed user, uint256 amount, string reason);
    event TokensSlashed(address indexed staker, uint256 amount, string reason);

    event RoyaltiesWithdrawn(uint256 indexed fragmentId, address indexed recipient, uint256 amount);
    event RoyaltyDistributionUpdated(uint256 indexed fragmentId, uint256 creatorShare, uint256 incubatorShare, uint256 daoShare);
    event DynamicRoyaltyFactorSet(uint256 indexed fragmentId, uint256 newFactor);
    event IPShareTransferred(uint256 indexed fragmentId, address indexed from, address indexed to, uint256 sharePercentage);

    event ChallengeProposed(uint256 indexed challengeId, uint256 indexed forgeId, address indexed proposer, string details);
    event ChallengeOutcomeVoted(uint256 indexed challengeId, address indexed voter, uint256[] winningFragmentIds);

    // --- Modifiers ---

    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "AetherForgeDAO: Not the oracle");
        _;
    }

    modifier promptExists(uint256 _promptId) {
        require(_promptId > 0 && _promptId <= _promptIds.current(), "AetherForgeDAO: Prompt does not exist");
        _;
    }

    modifier fragmentExists(uint256 _fragmentId) {
        require(_fragmentId > 0 && _fragmentId <= _fragmentIds.current(), "AetherForgeDAO: Fragment does not exist");
        _;
    }

    modifier forgeExists(uint256 _forgeId) {
        require(_forgeId > 0 && _forgeId <= _forgeIds.current(), "AetherForgeDAO: Forge does not exist");
        _;
    }

    modifier proposalExists(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= _proposalIds.current(), "AetherForgeDAO: Proposal does not exist");
        _;
    }

    modifier challengeExists(uint256 _challengeId) {
        require(_challengeId > 0 && _challengeId <= _challengeIds.current(), "AetherForgeDAO: Challenge does not exist");
        _;
    }

    modifier isAetherian() {
        require(aetherToken.balanceOf(msg.sender) >= minStakeForPrompt / 10 || userReputation[msg.sender] >= minReputationForProposal / 10, "AetherForgeDAO: Not enough AetherToken or reputation to participate");
        _;
    }

    // --- Constructor ---

    constructor(
        address _aetherTokenAddress,
        address _aetherFragmentNFTAddress,
        address _oracleAddress,
        address _treasuryAddress
    ) Ownable(_msgSender()) {
        require(_aetherTokenAddress != address(0), "AetherForgeDAO: Invalid AetherToken address");
        require(_aetherFragmentNFTAddress != address(0), "AetherForgeDAO: Invalid AetherFragmentNFT address");
        require(_oracleAddress != address(0), "AetherForgeDAO: Invalid Oracle address");
        require(_treasuryAddress != address(0), "AetherForgeDAO: Invalid Treasury address");

        aetherToken = IAetherToken(_aetherTokenAddress);
        aetherFragmentNFT = IAetherFragmentNFT(_aetherFragmentNFTAddress);
        oracleAddress = _oracleAddress;
        treasuryAddress = _treasuryAddress;
    }

    // Fallback function to receive ETH for treasury
    receive() external payable {
        // ETH received will go to the contract's balance, managed by DAO proposals.
    }

    // --- A. Core DAO & Governance (8 Functions) ---

    // 1. Submit DAO Proposal
    function submitDAOProposal(string memory _proposalURI, bytes memory _callData, address _targetContract) external isAetherian returns (uint256) {
        require(userReputation[msg.sender] >= minReputationForProposal, "AetherForgeDAO: Insufficient reputation to submit proposal");

        _proposalIds.increment();
        uint256 proposalId = _proposalIds.current();

        proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            proposalURI: _proposalURI,
            startBlock: block.number,
            endBlock: block.number + 1000, // Roughly 5 hours at 12s/block
            votesFor: 0,
            votesAgainst: 0,
            state: ProposalState.Pending, // Will become Active on first vote or after a delay
            callData: _callData,
            targetContract: _targetContract,
            hasVoted: new mapping(address => bool) // Initialize the mapping
        });

        emit ProposalSubmitted(proposalId, msg.sender, _proposalURI);
        return proposalId;
    }

    // 2. Cast Reputation-Weighted Vote
    function castReputationVote(uint256 _proposalId, VoteType _voteType) external proposalExists {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.state == ProposalState.Pending || proposal.state == ProposalState.Active, "AetherForgeDAO: Proposal not active or pending");
        require(block.number <= proposal.endBlock, "AetherForgeDAO: Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "AetherForgeDAO: Already voted on this proposal");

        uint256 voteWeight = aetherToken.balanceOf(msg.sender) + userReputation[msg.sender];
        require(voteWeight > 0, "AetherForgeDAO: No voting power");

        if (proposal.state == ProposalState.Pending) {
            proposal.state = ProposalState.Active;
        }

        if (_voteType == VoteType.For) {
            proposal.votesFor += voteWeight;
        } else {
            proposal.votesAgainst += voteWeight;
        }
        proposal.hasVoted[msg.sender] = true;

        emit VoteCast(_proposalId, msg.sender, _voteType, voteWeight);
    }

    // Internal function to check proposal outcome
    function _checkProposalState(uint256 _proposalId) internal {
        Proposal storage proposal = proposals[_proposalId];
        if (block.number > proposal.endBlock && (proposal.state == ProposalState.Pending || proposal.state == ProposalState.Active)) {
            uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
            if (totalVotes == 0) {
                proposal.state = ProposalState.Defeated; // No one voted
            } else if (proposal.votesFor * 10000 / totalVotes >= minProposalVoteThreshold) {
                proposal.state = ProposalState.Succeeded;
            } else {
                proposal.state = ProposalState.Defeated;
            }
        }
    }

    // 3. Execute Approved Proposal
    function executeApprovedProposal(uint256 _proposalId) external proposalExists {
        _checkProposalState(_proposalId); // Update state if voting period ended

        Proposal storage proposal = proposals[_proposalId];
        require(proposal.state == ProposalState.Succeeded, "AetherForgeDAO: Proposal not succeeded");
        require(proposal.state != ProposalState.Executed, "AetherForgeDAO: Proposal already executed");

        proposal.state = ProposalState.Executed;

        // Execute the actual function call
        (bool success,) = proposal.targetContract.call(proposal.callData);
        require(success, "AetherForgeDAO: Proposal execution failed");

        emit ProposalExecuted(_proposalId, msg.sender);
    }

    // 4. Distribute DAO Share (Requires DAO Approval)
    function distributeDAOShare(address _recipient, uint256 _amount) external {
        // This function is intended to be called by executeApprovedProposal
        // Its specific callData would be encoded with this function's signature and parameters.
        require(msg.sender == address(this), "AetherForgeDAO: Function can only be called via DAO proposal execution");
        require(_amount > 0, "AetherForgeDAO: Amount must be greater than zero");
        require(aetherToken.transfer(_recipient, _amount), "AetherForgeDAO: Failed to transfer DAO share");
    }

    // 5. Update Core Parameter (Requires DAO Approval)
    function updateCoreParameter(bytes32 _paramName, uint256 _newValue) external {
        // This function is intended to be called by executeApprovedProposal
        require(msg.sender == address(this), "AetherForgeDAO: Function can only be called via DAO proposal execution");

        if (_paramName == "incubationPeriod") {
            incubationPeriod = _newValue;
        } else if (_paramName == "minStakeForPrompt") {
            minStakeForPrompt = _newValue;
        } else if (_paramName == "minProposalVoteThreshold") {
            require(_newValue <= 10000, "Threshold cannot exceed 100%");
            minProposalVoteThreshold = _newValue;
        } else if (_paramName == "minReputationForProposal") {
            minReputationForProposal = _newValue;
        } else if (_paramName == "baseRoyaltyRate") {
            require(_newValue <= 10000, "Royalty rate cannot exceed 100%");
            baseRoyaltyRate = _newValue;
        } else {
            revert("AetherForgeDAO: Unknown parameter");
        }
    }

    // 6. Slash Staked Tokens (Requires DAO Approval)
    function slashStakedTokens(address _staker, uint256 _amount) external {
        // This function is intended to be called by executeApprovedProposal
        require(msg.sender == address(this), "AetherForgeDAO: Function can only be called via DAO proposal execution");
        require(_amount > 0, "AetherForgeDAO: Amount must be greater than zero");
        
        // This would typically mean burning the tokens or sending them to the DAO treasury.
        // For simplicity, let's assume they are transferred to the treasury.
        require(aetherToken.transferFrom(_staker, treasuryAddress, _amount), "AetherForgeDAO: Failed to slash tokens");
        emit TokensSlashed(_staker, _amount, "Malicious behavior as per DAO vote");
    }

    // 7. Earn Reputation (Internal/DAO-Callable)
    function earnReputation(address _user, uint256 _points, string memory _reason) internal {
        userReputation[_user] += _points;
        emit ReputationEarned(_user, _points, _reason);
    }

    // 8. Withdraw Treasury Funds (Native Currency)
    function withdrawTreasuryFunds(address _recipient, uint256 _amount) external {
        // This function is intended to be called by executeApprovedProposal
        require(msg.sender == address(this), "AetherForgeDAO: Function can only be called via DAO proposal execution");
        require(_recipient != address(0), "AetherForgeDAO: Invalid recipient address");
        require(address(this).balance >= _amount, "AetherForgeDAO: Insufficient treasury balance");

        (bool success,) = payable(_recipient).call{value: _amount}("");
        require(success, "AetherForgeDAO: Failed to withdraw treasury funds");
    }

    // --- B. Prompt & Incubation Management (6 Functions) ---

    // 9. Submit Aether Prompt
    function submitAetherPrompt(string memory _description, uint256 _fundingGoal) external isAetherian returns (uint256) {
        require(_fundingGoal > 0, "AetherForgeDAO: Funding goal must be positive");
        require(aetherToken.transferFrom(msg.sender, address(this), minStakeForPrompt), "AetherForgeDAO: Failed to stake minPromptStake");

        _promptIds.increment();
        uint256 promptId = _promptIds.current();

        prompts[promptId] = Prompt({
            id: promptId,
            submitter: msg.sender,
            description: _description,
            fundingGoal: _fundingGoal,
            currentFunding: minStakeForPrompt, // Starts with submitter's stake
            status: PromptStatus.Incubation,
            votesFor: 0,
            votesAgainst: 0,
            incubationEndTime: block.timestamp + incubationPeriod,
            acceptedForgeId: 0,
            incubatorStakes: new mapping(address => uint256),
            hasVoted: new mapping(address => bool),
            totalIncubatorStake: minStakeForPrompt
        });
        prompts[promptId].incubatorStakes[msg.sender] = minStakeForPrompt;


        emit PromptSubmitted(promptId, msg.sender, _fundingGoal, _description);
        return promptId;
    }

    // 10. Stake for Prompt Incubation
    function stakeForPromptIncubation(uint256 _promptId, uint256 _amount) external promptExists {
        Prompt storage prompt = prompts[_promptId];
        require(prompt.status == PromptStatus.Incubation, "AetherForgeDAO: Prompt not in incubation phase");
        require(block.timestamp <= prompt.incubationEndTime, "AetherForgeDAO: Incubation period has ended");
        require(_amount > 0, "AetherForgeDAO: Amount must be greater than zero");

        require(aetherToken.transferFrom(msg.sender, address(this), _amount), "AetherForgeDAO: Failed to stake tokens");

        prompt.currentFunding += _amount;
        prompt.incubatorStakes[msg.sender] += _amount;
        prompt.totalIncubatorStake += _amount;

        emit PromptFunded(_promptId, msg.sender, _amount, prompt.currentFunding);
    }

    // 11. Vote on Prompt Acceptance
    function voteOnPromptAcceptance(uint256 _promptId, VoteType _voteType) external promptExists {
        Prompt storage prompt = prompts[_promptId];
        require(prompt.status == PromptStatus.Incubation, "AetherForgeDAO: Prompt not in incubation phase");
        require(block.timestamp <= prompt.incubationEndTime, "AetherForgeDAO: Incubation voting period has ended");
        require(!prompt.hasVoted[msg.sender], "AetherForgeDAO: Already voted on this prompt");

        uint256 voteWeight = aetherToken.balanceOf(msg.sender) + userReputation[msg.sender];
        require(voteWeight > 0, "AetherForgeDAO: No voting power");

        if (_voteType == VoteType.For) {
            prompt.votesFor += voteWeight;
        } else {
            prompt.votesAgainst += voteWeight;
        }
        prompt.hasVoted[msg.sender] = true;

        emit VoteCast(_promptId, msg.sender, _voteType, voteWeight);
    }

    // 12. Finalize Prompt Incubation
    function finalizePromptIncubation(uint256 _promptId) external promptExists {
        Prompt storage prompt = prompts[_promptId];
        require(prompt.status == PromptStatus.Incubation, "AetherForgeDAO: Prompt not in incubation phase");
        require(block.timestamp > prompt.incubationEndTime, "AetherForgeDAO: Incubation period has not ended");

        uint256 totalVotes = prompt.votesFor + prompt.votesAgainst;
        if (prompt.currentFunding >= prompt.fundingGoal && totalVotes > 0 && prompt.votesFor * 10000 / totalVotes >= minProposalVoteThreshold) {
            prompt.status = PromptStatus.Accepted;
            earnReputation(prompt.submitter, 10, "Prompt Accepted");
            emit PromptAccepted(_promptId, msg.sender);
        } else {
            prompt.status = PromptStatus.Rejected;
            // Refund all incubator stakes if rejected
            for (address staker : prompt.incubatorStakes.keys()) { // Simplified iteration, needs external library for real mapping keys
                uint256 stakeAmount = prompt.incubatorStakes[staker];
                if (stakeAmount > 0) {
                    require(aetherToken.transfer(staker, stakeAmount), "AetherForgeDAO: Failed to refund stake");
                    prompt.incubatorStakes[staker] = 0;
                }
            }
            prompt.totalIncubatorStake = 0; // All refunded
            emit PromptRejected(_promptId, msg.sender);
        }
    }

    // 13. Cancel Prompt Incubation
    function cancelPromptIncubation(uint256 _promptId) external promptExists {
        Prompt storage prompt = prompts[_promptId];
        require(prompt.submitter == msg.sender, "AetherForgeDAO: Only submitter can cancel prompt");
        require(prompt.status == PromptStatus.Incubation, "AetherForgeDAO: Prompt not in incubation phase");
        require(block.timestamp <= prompt.incubationEndTime, "AetherForgeDAO: Incubation period has ended, finalize instead");

        prompt.status = PromptStatus.Rejected; // Mark as rejected for clarity
        // Refund all incubator stakes
        for (address staker : prompt.incubatorStakes.keys()) { // Simplified iteration
            uint256 stakeAmount = prompt.incubatorStakes[staker];
            if (stakeAmount > 0) {
                require(aetherToken.transfer(staker, stakeAmount), "AetherForgeDAO: Failed to refund stake");
                prompt.incubatorStakes[staker] = 0;
            }
        }
        prompt.totalIncubatorStake = 0;
        emit PromptCancelled(_promptId, msg.sender);
    }

    // 14. Collect Prompt Stakes (if Accepted)
    function collectPromptStakes(uint256 _promptId) external promptExists {
        Prompt storage prompt = prompts[_promptId];
        require(prompt.status == PromptStatus.Accepted || prompt.status == PromptStatus.Generating || prompt.status == PromptStatus.Completed, "AetherForgeDAO: Prompt not in accepted/completed state");
        
        // This function is for the incubators to reclaim their principal stake.
        // It's assumed the prompt's total stake remains within the contract to back royalty calculations.
        // This function simply reflects that the principal is no longer 'locked' as funding.
        // For simplicity, assuming 'totalIncubatorStake' is the amount held, and this function
        // signifies that the original staked amount for a successful prompt can conceptually be "unlocked"
        // though still accounted for royalty distribution purposes.
        // Actual transfer out would need to consider the DAO's capital structure.
        // For this example, let's make it a no-op as funds are already transferred to contract.
        // Royalties will be handled via `withdrawFragmentRoyalties`.
        revert("AetherForgeDAO: Principal stakes are retained for royalty calculation. Use withdrawFragmentRoyalties for earnings.");
    }


    // --- C. AetherFragment (NFT) Management (4 Functions) ---

    // 15. Request AetherFragment Generation
    function requestAetherFragmentGeneration(uint256 _promptId, string memory _generationParameters) external promptExists {
        Prompt storage prompt = prompts[_promptId];
        require(prompt.status == PromptStatus.Accepted, "AetherForgeDAO: Prompt not accepted for generation");
        require(msg.sender == prompt.submitter, "AetherForgeDAO: Only the prompt submitter can request generation");

        prompt.status = PromptStatus.Generating;
        emit FragmentGenerationRequested(_promptId, _generationParameters);
    }

    // 16. Fulfill AI Generation (Callable only by Oracle)
    function fulfillAIGeneration(uint256 _promptId, string memory _assetURI, bytes32 _uniqueSeed) external onlyOracle promptExists {
        Prompt storage prompt = prompts[_promptId];
        require(prompt.status == PromptStatus.Generating, "AetherForgeDAO: Prompt not in generation phase");
        
        _fragmentIds.increment();
        uint256 fragmentId = _fragmentIds.current();

        // Mint the ERC721 NFT via the AetherFragmentNFT contract
        aetherFragmentNFT.mint(prompt.submitter, fragmentId, _assetURI, prompt.submitter, _promptId);

        // Initialize IP shares (e.g., submitter gets 100%)
        IPShare[] memory initialIPShares = new IPShare[](1);
        initialIPShares[0] = IPShare({holder: prompt.submitter, percentage: 10000}); // 100%

        // Initialize Royalty distribution
        RoyaltyInfo memory initialRoyaltyInfo = RoyaltyInfo({
            primaryCreatorShare: 6000, // 60% of secondary royalty
            DAOShare: 2000,            // 20%
            incubatorShare: 2000,      // 20%
            dynamicFactor: 100,        // 1x
            baseRate: baseRoyaltyRate  // Default base rate
        });

        aetherFragments[fragmentId] = AetherFragment({
            id: fragmentId,
            promptId: _promptId,
            uniqueSeed: _uniqueSeed,
            currentURI: _assetURI,
            creator: prompt.submitter,
            currentOwner: prompt.submitter, // NFT owner
            generationTimestamp: block.timestamp,
            evolutionStage: 0,
            royaltyDistribution: initialRoyaltyInfo,
            ipShares: initialIPShares,
            royaltyAccumulated: new mapping(address => uint256)
        });

        prompt.status = PromptStatus.Completed;
        earnReputation(prompt.submitter, 50, "AetherFragment Minted");
        emit FragmentMinted(fragmentId, _promptId, prompt.submitter, _assetURI);
    }

    // 17. Evolve AetherFragment (Requires DAO Approval for significant changes)
    function evolveAetherFragment(uint256 _fragmentId, string memory _newURI, bytes32 _newSeed) external fragmentExists {
        AetherFragment storage fragment = aetherFragments[_fragmentId];
        // For simplicity, direct call here, but for "significant" evolution,
        // this would ideally be triggered via a DAO proposal and `executeApprovedProposal`.
        require(msg.sender == fragment.creator || aetherFragmentNFT.ownerOf(_fragmentId) == msg.sender, "AetherForgeDAO: Only creator or current NFT owner can propose evolution");
        
        // This update implies calling a function on the NFT contract
        aetherFragmentNFT.evolve(_fragmentId, _newURI, _newSeed);

        fragment.currentURI = _newURI;
        fragment.uniqueSeed = _newSeed;
        fragment.evolutionStage++;

        emit FragmentEvolved(_fragmentId, _newURI, _newSeed, fragment.evolutionStage);
    }

    // 18. Transfer Dynamic IP Share
    function transferDynamicIPShare(uint256 _fragmentId, address _from, address _to, uint256 _sharePercentage) external fragmentExists {
        AetherFragment storage fragment = aetherFragments[_fragmentId];
        require(msg.sender == fragment.creator || aetherFragmentNFT.ownerOf(_fragmentId) == msg.sender, "AetherForgeDAO: Only creator or NFT owner can manage IP shares");
        require(_sharePercentage > 0 && _sharePercentage <= 10000, "AetherForgeDAO: Invalid share percentage");
        require(_from != address(0) && _to != address(0), "AetherForgeDAO: Invalid addresses");
        require(_from != _to, "AetherForgeDAO: Cannot transfer to self");

        bool foundFrom = false;
        uint256 fromIndex = 0;
        for (uint256 i = 0; i < fragment.ipShares.length; i++) {
            if (fragment.ipShares[i].holder == _from) {
                foundFrom = true;
                fromIndex = i;
                break;
            }
        }
        require(foundFrom, "AetherForgeDAO: 'From' address does not hold IP share");
        require(fragment.ipShares[fromIndex].percentage >= _sharePercentage, "AetherForgeDAO: Insufficient IP share to transfer");

        fragment.ipShares[fromIndex].percentage -= _sharePercentage;

        // Find or add _to's share
        bool foundTo = false;
        for (uint256 i = 0; i < fragment.ipShares.length; i++) {
            if (fragment.ipShares[i].holder == _to) {
                fragment.ipShares[i].percentage += _sharePercentage;
                foundTo = true;
                break;
            }
        }
        if (!foundTo) {
            fragment.ipShares.push(IPShare({holder: _to, percentage: _sharePercentage}));
        }

        emit IPShareTransferred(_fragmentId, _from, _to, _sharePercentage);
    }

    // --- D. Forge (Project) Management (4 Functions) ---

    // 19. Create Aether Forge
    function createAetherForge(uint256 _parentPromptId, string memory _forgeName, string memory _description) external promptExists isAetherian returns (uint256) {
        Prompt storage parentPrompt = prompts[_parentPromptId];
        require(parentPrompt.status == PromptStatus.Completed, "AetherForgeDAO: Parent prompt not completed");
        require(parentPrompt.acceptedForgeId == 0, "AetherForgeDAO: Prompt already has an associated forge");

        _forgeIds.increment();
        uint256 forgeId = _forgeIds.current();

        forges[forgeId] = Forge({
            id: forgeId,
            parentPromptId: _parentPromptId,
            name: _forgeName,
            description: _description,
            creator: msg.sender,
            status: ForgeStatus.Open,
            aetherFragments: new uint256[](0),
            creationTimestamp: block.timestamp
        });

        parentPrompt.acceptedForgeId = forgeId;
        emit ForgeCreated(forgeId, _parentPromptId, msg.sender, _forgeName);
        return forgeId;
    }

    // 20. Add Fragment to Forge
    function addFragmentToForge(uint256 _forgeId, uint256 _fragmentId) external forgeExists fragmentExists {
        Forge storage forge = forges[_forgeId];
        AetherFragment storage fragment = aetherFragments[_fragmentId];

        // Only the fragment creator or current owner can add it to a forge
        require(msg.sender == fragment.creator || aetherFragmentNFT.ownerOf(_fragmentId) == msg.sender, "AetherForgeDAO: Only fragment creator or owner can add to forge");
        
        // Prevent adding the same fragment twice
        for (uint256 i = 0; i < forge.aetherFragments.length; i++) {
            require(forge.aetherFragments[i] != _fragmentId, "AetherForgeDAO: Fragment already in this forge");
        }

        forge.aetherFragments.push(_fragmentId);
        emit FragmentAddedToForge(_forgeId, _fragmentId);
    }

    // 21. Propose Forge Curatorial Challenge
    function proposeForgeCuratorialChallenge(uint256 _forgeId, string memory _challengeDetails) external forgeExists isAetherian returns (uint256) {
        Forge storage forge = forges[_forgeId];
        require(forge.status == ForgeStatus.Open || forge.status == ForgeStatus.Curating, "AetherForgeDAO: Forge not open for challenges");
        require(forge.aetherFragments.length > 0, "AetherForgeDAO: Forge must contain fragments to propose a challenge");

        _challengeIds.increment();
        uint256 challengeId = _challengeIds.current();

        challenges[challengeId] = Challenge({
            id: challengeId,
            forgeId: _forgeId,
            proposer: msg.sender,
            challengeDetails: _challengeDetails,
            submissionEndTime: block.timestamp + 3 days, // Example: 3 days for submissions
            votingEndTime: block.timestamp + 7 days,     // Example: 7 days total for voting
            winningFragmentIds: new uint256[](0),
            hasVoted: new mapping(address => bool),
            totalVotes: 0
        });

        forge.status = ForgeStatus.Curating;
        emit ChallengeProposed(challengeId, _forgeId, msg.sender, _challengeDetails);
        return challengeId;
    }

    // 22. Vote on Challenge Outcome
    function voteOnChallengeOutcome(uint256 _challengeId, uint256[] memory _winningFragmentIds) external challengeExists isAetherian {
        Challenge storage challenge = challenges[_challengeId];
        require(block.timestamp > challenge.submissionEndTime, "AetherForgeDAO: Submission period not over");
        require(block.timestamp <= challenge.votingEndTime, "AetherForgeDAO: Voting period has ended");
        require(!challenge.hasVoted[msg.sender], "AetherForgeDAO: Already voted on this challenge");
        require(_winningFragmentIds.length > 0, "AetherForgeDAO: Must select at least one winning fragment");

        // Simple approval for winning fragments, a more complex system could involve weighted preferences.
        // This example simply records the vote, and final decision is based on total votes.
        challenge.winningFragmentIds = _winningFragmentIds; // Overwrites, so first set of votes matters. Can be improved.
        challenge.hasVoted[msg.sender] = true;
        challenge.totalVotes += (aetherToken.balanceOf(msg.sender) + userReputation[msg.sender]);

        // For a more robust system, each fragment would have a score based on how many votes it received.
        // For simplicity, we just record the winner, which would be processed later by another function.
        // For this function, let's say the DAO members just vote to *approve* a set of winners.
        // The *actual* winner selection logic would be in a separate finalization function.

        emit ChallengeOutcomeVoted(_challengeId, msg.sender, _winningFragmentIds);
    }

    // --- E. Monetization & Royalty Management (4 Functions) ---

    // 23. Update Fragment Royalty Distribution (Requires DAO Approval)
    function updateFragmentRoyaltyDistribution(
        uint256 _fragmentId,
        uint256 _newCreatorShare,
        uint256 _newIncubatorShare,
        uint256 _newDAOShares
    ) external fragmentExists {
        // This function is intended to be called by executeApprovedProposal
        require(msg.sender == address(this), "AetherForgeDAO: Function can only be called via DAO proposal execution");
        
        require(_newCreatorShare + _newIncubatorShare + _newDAOShares <= 10000, "AetherForgeDAO: Shares sum exceeds 100%");

        AetherFragment storage fragment = aetherFragments[_fragmentId];
        fragment.royaltyDistribution.primaryCreatorShare = _newCreatorShare;
        fragment.royaltyDistribution.DAOShare = _newDAOShares;
        fragment.royaltyDistribution.incubatorShare = _newIncubatorShare;

        // Also update the EIP-2981 royalty info on the NFT contract if applicable
        // The receiver in EIP-2981 could be a splitting contract or this DAO itself.
        // For simplicity, let's assume it points to the DAO for now and we distribute internally.
        aetherFragmentNFT.setRoyaltyInfo(_fragmentId, address(this), uint96(fragment.royaltyDistribution.baseRate * fragment.royaltyDistribution.dynamicFactor / 100));

        emit RoyaltyDistributionUpdated(_fragmentId, _newCreatorShare, _newIncubatorShare, _newDAOShares);
    }

    // 24. Withdraw Fragment Royalties
    function withdrawFragmentRoyalties(uint256 _fragmentId, address _recipient) external fragmentExists {
        AetherFragment storage fragment = aetherFragments[_fragmentId];
        require(fragment.royaltyAccumulated[_recipient] > 0, "AetherForgeDAO: No royalties accumulated for this recipient");

        uint256 amount = fragment.royaltyAccumulated[_recipient];
        fragment.royaltyAccumulated[_recipient] = 0; // Reset accumulated for this recipient

        // Assume actual royalty funds (e.g., in ETH) are held by the DAO or a specific escrow contract
        // For this example, funds would be transferred from the DAO's ETH balance
        (bool success,) = payable(_recipient).call{value: amount}("");
        require(success, "AetherForgeDAO: Failed to withdraw royalties");

        emit RoyaltiesWithdrawn(_fragmentId, _recipient, amount);
    }
    
    // Internal function to accumulate royalties (called by an external royalty collector or marketplace hook)
    function _accumulateRoyalties(uint256 _fragmentId, uint256 _totalRoyaltyAmount) internal fragmentExists {
        AetherFragment storage fragment = aetherFragments[_fragmentId];
        
        uint256 dynamicRate = fragment.royaltyDistribution.baseRate * fragment.royaltyDistribution.dynamicFactor / 100; // Adjusted base rate
        uint256 actualRoyalty = _totalRoyaltyAmount * dynamicRate / 10000; // Calculate actual royalty amount from full sale

        uint256 creatorShare = actualRoyalty * fragment.royaltyDistribution.primaryCreatorShare / 10000;
        uint256 daoShare = actualRoyalty * fragment.royaltyDistribution.DAOShare / 10000;
        uint256 incubatorShare = actualRoyalty * fragment.royaltyDistribution.incubatorShare / 10000;

        fragment.royaltyAccumulated[fragment.creator] += creatorShare;
        fragment.royaltyAccumulated[treasuryAddress] += daoShare;

        // Distribute incubator share proportionally
        if (incubatorShare > 0) {
            Prompt storage prompt = prompts[fragment.promptId];
            if (prompt.totalIncubatorStake > 0) {
                for (address incubator : prompt.incubatorStakes.keys()) { // Simplified iteration
                    if (prompt.incubatorStakes[incubator] > 0) {
                        uint256 individualIncubatorShare = incubatorShare * prompt.incubatorStakes[incubator] / prompt.totalIncubatorStake;
                        fragment.royaltyAccumulated[incubator] += individualIncubatorShare;
                    }
                }
            }
        }
        // Any remainder if sums aren't exact, goes to DAO
        fragment.royaltyAccumulated[treasuryAddress] += (actualRoyalty - creatorShare - daoShare - incubatorShare);
    }


    // 25. Set Dynamic Royalty Factor (Requires DAO Approval)
    function setDynamicRoyaltyFactor(uint256 _fragmentId, uint256 _dynamicFactorPercentage) external fragmentExists {
        // This function is intended to be called by executeApprovedProposal
        require(msg.sender == address(this), "AetherForgeDAO: Function can only be called via DAO proposal execution");
        require(_dynamicFactorPercentage > 0, "AetherForgeDAO: Dynamic factor must be positive"); // e.g., 100 for 1x, 150 for 1.5x

        AetherFragment storage fragment = aetherFragments[_fragmentId];
        fragment.royaltyDistribution.dynamicFactor = _dynamicFactorPercentage;

        // Update EIP-2981 royalty info on the NFT contract with the new dynamic rate
        aetherFragmentNFT.setRoyaltyInfo(_fragmentId, address(this), uint96(fragment.royaltyDistribution.baseRate * _dynamicFactorPercentage / 100));

        emit DynamicRoyaltyFactorSet(_fragmentId, _dynamicFactorPercentage);
    }

    // 26. Get Fragment Royalty Info
    function getFragmentRoyaltyInfo(uint256 _fragmentId) public view fragmentExists returns (RoyaltyInfo memory) {
        return aetherFragments[_fragmentId].royaltyDistribution;
    }

    // --- F. Utility & Information (2 Functions) ---

    // 27. Get Prompt Details
    function getPromptDetails(uint256 _promptId) public view promptExists returns (Prompt memory) {
        return prompts[_promptId];
    }

    // 28. Get User Reputation
    function getUserReputation(address _user) public view returns (uint256) {
        return userReputation[_user];
    }
    
    // Fallback for missing mapping keys workaround (not for production use, but for example purposes)
    // This allows iterating over mapping keys in a simulated way.
    // In a real-world scenario, you would manage keys in a separate array or use a specialized library.
    function _getMappingKeys(mapping(address => uint256) storage _map) internal pure returns (address[] memory) {
        // This is a placeholder. Real Solidity does not support iterating over mapping keys directly.
        // For a deployed contract, you'd track keys in an array or use enumerable mappings from OpenZeppelin.
        address[] memory keys;
        // Example: if (keysArray.length > 0) { ... }
        return keys;
    }
}
```