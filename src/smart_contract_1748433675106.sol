Okay, let's design an advanced, creative, and trendy smart contract. We'll build a "ChronicleDAO" – a decentralized autonomous organization focused on collaboratively building and owning a decentralized, dynamic chronicle or body of knowledge/art. This involves governance, contribution systems, reputation, dynamic NFTs tied to participation, and a treasury.

It will have features like:
1.  **Governance:** Token-based voting on proposals (config changes, treasury spends, contribution acceptance).
2.  **Content Proposals:** Users propose additions/modifications to the "Chronicle".
3.  **Reputation System:** Earned by contributing, voting, and proposals passing. Influences proposal power and NFT status.
4.  **Dynamic NFTs:** Member NFTs whose metadata can change based on reputation, contribution count, or special achievements approved by the DAO.
5.  **Challenges:** A mechanism to challenge approved content entries.
6.  **Rewards:** Distributing tokens from the treasury to active participants.
7.  **Delegation:** Users can delegate their voting power.
8.  **On-chain Chronicle Index:** Maintaining an index of approved content entries (represented by IPFS hashes or similar).

This design combines elements of DAOs, NFTs, reputation systems, and content curation, aiming for uniqueness beyond standard OpenZeppelin templates.

---

**Outline and Function Summary**

**Contract Name:** ChronicleDAO

**Core Concept:** A decentralized autonomous organization for collaborative creation, curation, and ownership of a dynamic "Chronicle". Members propose content additions/modifications, vote on their inclusion, earn reputation, and potentially dynamic NFTs reflecting their participation level.

**Outline:**

1.  **State Variables:** Core parameters (tokens, thresholds, periods), mappings for proposals, reputation, votes, delegations, chronicle entries, challenges, rewards, user profiles.
2.  **Enums & Structs:** Defines proposal states, vote types, proposal structure, challenge structure, user profile structure.
3.  **Events:** Signals key actions (proposal creation, voting, execution, challenge, reputation change, etc.).
4.  **Modifiers:** Access control, state checks (paused, not paused).
5.  **Interfaces:** Defines required functions for ERC20 Governance Token and ERC721 Member NFT.
6.  **Constructor:** Initializes the DAO with core parameters and addresses.
7.  **Admin & Configuration:** Functions for initial setup and governance-approved configuration changes.
8.  **Treasury Management:** Functions for depositing and managing funds.
9.  **Proposal System:** Functions for creating different types of proposals.
10. **Voting & Delegation:** Functions for casting votes and managing voting power delegation.
11. **Execution:** Function to execute approved proposals.
12. **Chronicle Management:** Functions to view and manage the accepted Chronicle entries (via proposal execution).
13. **Reputation System:** Functions to view reputation (awarded via proposals).
14. **NFT Integration:** Functions to interact with the Member NFT contract (minting, triggering metadata updates, querying).
15. **Challenges:** Functions to challenge Chronicle entries and resolve challenges via a vote.
16. **Rewards:** Functions to claim accrued rewards.
17. **User Profile:** Functions to register and manage a simple on-chain profile.

**Function Summary (Minimum 20 required):**

1.  `constructor()`: Deploys and initializes the contract.
2.  `setGovernanceToken(address _governanceToken)`: Sets the address of the ERC20 token used for voting. (Admin/Governance)
3.  `setMemberNFTCollection(address _memberNFT)`: Sets the address of the ERC721 collection for member NFTs. (Admin/Governance)
4.  `setProposalThreshold(uint256 _proposalThresholdTokens, uint256 _proposalThresholdReputation)`: Sets minimum requirements to create proposals. (Admin/Governance)
5.  `setVotingPeriod(uint256 _votingPeriodBlocks)`: Sets the duration proposals are open for voting. (Admin/Governance)
6.  `setQuorumPercentage(uint256 _quorumPercentage)`: Sets the minimum percentage of total voting power needed for a proposal to pass. (Admin/Governance)
7.  `setChallengeDepositAmount(uint256 _depositAmount)`: Sets the token amount required to challenge an entry. (Admin/Governance)
8.  `pause()`: Pauses contract functionality. (Admin)
9.  `unpause()`: Unpauses contract functionality. (Admin)
10. `depositToTreasury()`: Allows anyone to send ETH or tokens to the DAO treasury.
11. `getTreasuryBalance()`: Gets the current balance of the treasury.
12. `proposeContribution(string memory _chronicleEntryHash, string memory _description)`: Creates a proposal to add a new entry to the Chronicle.
13. `proposeConfigChange(uint256 _paramIndex, uint256 _newValue, string memory _description)`: Creates a proposal to change a configuration parameter.
14. `proposeTreasurySpend(address _recipient, uint256 _amount, string memory _description)`: Creates a proposal to send funds from the treasury.
15. `getProposalState(uint256 _proposalId)`: Gets the current state of a proposal.
16. `castVote(uint256 _proposalId, VoteType _vote)`: Casts a vote on a proposal.
17. `delegateVotingPower(address _delegatee)`: Delegates voting power to another address.
18. `revokeDelegation()`: Revokes current delegation.
19. `getVotingPower(address _voter)`: Gets the current voting power of an address (considers delegation).
20. `executeProposal(uint256 _proposalId)`: Executes a proposal that has passed and ended.
21. `cancelProposal(uint256 _proposalId)`: Allows creator or governance to cancel a proposal before voting ends (under conditions).
22. `getChronicleEntry(uint256 _index)`: Retrieves a specific entry from the accepted Chronicle.
23. `getChronicleSize()`: Gets the total number of entries in the accepted Chronicle.
24. `getReputation(address _user)`: Gets the current reputation score of a user.
25. `mintMemberNFT(address _recipient, uint256 _tier)`: Mints a member NFT (intended to be called via `executeProposal`).
26. `signalNFTMetadataUpdate(address _user)`: Signals the NFT contract to potentially update a user's dynamic NFT metadata based on their DAO stats. (Intended via `executeProposal` or triggered by internal logic).
27. `getUserNFTs(address _user)`: Gets the list of NFT token IDs owned by a user from the member collection.
28. `challengeContribution(uint256 _chronicleEntryIndex)`: Initiates a challenge against an existing Chronicle entry (requires deposit). Creates a new proposal.
29. `resolveChallenge(uint256 _challengeProposalId)`: Executes the outcome of a challenge vote (removes entry or penalizes challenger).
30. `claimReward()`: Allows users to claim any accumulated rewards.
31. `registerContributorProfile(string memory _profileDataHash)`: Registers or updates a user's public contributor profile (e.g., IPFS hash).
32. `getUserProfile(address _user)`: Retrieves a user's registered profile hash.

*(Note: Some complex logic like calculating vote power including delegated votes, dynamic NFT metadata logic, and reward calculation/distribution would be handled within the respective functions or via interactions with linked contracts, making this design advanced.)*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

// Interfaces for linked contracts
interface IGovernanceToken is IERC20 {
    // Assuming a custom governance token that might have snapshotting or delegate features
    // We'll primarily use balanceOf for simplicity in voting here, but interface allows extension
    function getVotes(address account) external view returns (uint256); // Example custom function
    function delegate(address delegatee) external; // Example custom function
}

interface IMemberNFT is IERC721 {
    // Assuming the NFT supports owner/governance triggering metadata updates
    function mint(address to, uint256 tokenId, string memory uri) external; // Simplified mint
    function signalUpdateMetadata(address user, uint256 newTierOrLevel) external; // Function to trigger dynamic update logic in NFT contract
    function getTokenIdsOwnedBy(address user) external view returns (uint256[] memory); // Helper to list user's NFTs
}

contract ChronicleDAO is Ownable, ReentrancyGuard, Pausable {
    using SafeMath for uint256;
    using Address for address;

    // --- State Variables ---

    IGovernanceToken public governanceToken;
    IMemberNFT public memberNFTCollection;

    uint256 public proposalThresholdTokens; // Min tokens to create a proposal
    uint256 public proposalThresholdReputation; // Min reputation to create a proposal
    uint256 public votingPeriodBlocks; // Duration of voting in blocks
    uint256 public quorumPercentage; // % of total voting power needed for success
    uint256 public challengeDepositAmount; // Tokens required to challenge a Chronicle entry

    uint256 private _nextProposalId;
    uint256 private _nextChronicleEntryId;

    // DAO Treasury (contract balance holds funds)
    address public treasuryRecipient; // Default recipient for treasury spends (can be another contract or multisig)

    // Mappings for core data
    mapping(uint256 => Proposal) public proposals;
    mapping(address => uint256) public reputation; // User reputation score
    mapping(uint256 => mapping(address => VoteType)) private _votes; // proposalId => voter => vote (to prevent double voting)
    mapping(address => address) public delegations; // delegator => delegatee

    // Chronicle storage (IPFS hashes or similar identifiers)
    // Storing large amounts of data on-chain is expensive. Storing hashes is standard.
    mapping(uint256 => ChronicleEntry) public chronicle;
    uint256[] public chronicleEntryIds; // Ordered list of accepted entry IDs

    // Challenge system
    mapping(uint256 => Challenge) public challenges; // challengeProposalId => Challenge details

    // Reward system
    mapping(address => uint256) private _pendingRewards; // User => amount of tokens claimable

    mapping(address => UserProfile) public userProfiles; // User => Profile data

    // --- Enums & Structs ---

    enum ProposalState { Pending, Active, Canceled, Defeated, Succeeded, Queued, Expired, Executed }
    enum VoteType { Against, For, Abstain }
    enum ProposalType { Contribution, ConfigChange, TreasurySpend, ChallengeVote, MintNFT, SignalNFTUpdate }

    struct Proposal {
        uint256 id;
        ProposalType proposalType;
        address proposer;
        uint256 creationBlock;
        uint256 endBlock;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 votesAbstain;
        uint256 totalVotingPowerSnapshot; // Snapshot of total voting power at proposal creation
        string description;
        // Data payload for execution, depends on ProposalType
        bytes data; // ABI-encoded call data for execution (e.g., function selector + arguments)
        ProposalState state;
        bool executed;
    }

     struct ChronicleEntry {
        uint256 id;
        uint256 proposalId; // Proposal that approved this entry
        address contributor; // Address of the user who proposed it
        string dataHash; // e.g., IPFS hash of the content
        uint256 addedBlock;
        bool active; // Can be set to false if challenged and removed
    }

    struct Challenge {
        uint256 challengeProposalId; // The proposal ID for the vote on this challenge
        uint256 chronicleEntryId; // The ID of the entry being challenged
        address challenger;
        uint256 challengeBlock;
        bool resolved;
    }

    struct UserProfile {
        string profileDataHash; // e.g., IPFS hash for richer profile data
        bool registered;
    }

    // --- Events ---

    event GovernanceTokenSet(address indexed token);
    event MemberNFTCollectionSet(address indexed collection);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, ProposalType proposalType, string description, uint256 endBlock);
    event VoteCast(uint256 indexed proposalId, address indexed voter, VoteType vote, uint256 votingPower);
    event ProposalExecuted(uint256 indexed proposalId, address indexed executor);
    event ProposalCanceled(uint256 indexed proposalId);
    event DelegationUpdated(address indexed delegator, address indexed delegatee);
    event ChronicleEntryAdded(uint256 indexed entryId, uint256 indexed proposalId, string dataHash, address indexed contributor);
    event ReputationUpdated(address indexed user, uint256 newReputation);
    event ChallengeCreated(uint256 indexed challengeProposalId, uint256 indexed chronicleEntryId, address indexed challenger);
    event ChallengeResolved(uint256 indexed challengeProposalId, bool success); // success means challenge passed -> entry removed
    event RewardsClaimed(address indexed user, uint256 amount);
    event UserProfileUpdated(address indexed user, string profileDataHash);

    // --- Modifiers ---

    modifier onlyGovernanceTokenContract() {
        require(msg.sender == address(governanceToken), "Caller is not governance token");
        _;
    }

    modifier onlyMemberNFTContract() {
        require(msg.sender == address(memberNFTCollection), "Caller is not member NFT contract");
        _;
    }

    // --- Constructor ---

    constructor(
        address _governanceToken,
        address _memberNFT,
        uint256 _proposalThresholdTokens,
        uint256 _proposalThresholdReputation,
        uint256 _votingPeriodBlocks,
        uint256 _quorumPercentage,
        uint256 _challengeDepositAmount
    ) Ownable(msg.sender) Pausable(false) {
        require(_governanceToken != address(0), "Invalid governance token address");
        require(_memberNFT != address(0), "Invalid member NFT address");
        require(_votingPeriodBlocks > 0, "Voting period must be > 0");
        require(_quorumPercentage <= 100, "Quorum percentage invalid");

        governanceToken = IGovernanceToken(_governanceToken);
        memberNFTCollection = IMemberNFT(_memberNFT);
        proposalThresholdTokens = _proposalThresholdTokens;
        proposalThresholdReputation = _proposalThresholdReputation;
        votingPeriodBlocks = _votingPeriodBlocks;
        quorumPercentage = _quorumPercentage;
        challengeDepositAmount = _challengeDepositAmount;
        treasuryRecipient = address(this); // By default, treasury funds stay in this contract

        _nextProposalId = 1;
        _nextChronicleEntryId = 1;

        emit GovernanceTokenSet(_governanceToken);
        emit MemberNFTCollectionSet(_memberNFT);
    }

    // --- Admin & Configuration ---

    // These should ideally be callable only via successful governance proposals (ConfigChange)
    // For initial setup/testing, we'll make them owner-callable, but real DAO uses execution payload.
    // executeProposal function handles calling these internally.

    function setGovernanceToken(address _governanceToken) public onlyOwner {
         require(_governanceToken != address(0), "Invalid governance token address");
         governanceToken = IGovernanceToken(_governanceToken);
         emit GovernanceTokenSet(_governanceToken);
    }

    function setMemberNFTCollection(address _memberNFT) public onlyOwner {
         require(_memberNFT != address(0), "Invalid member NFT address");
         memberNFTCollection = IMemberNFT(_memberNFT);
         emit MemberNFTCollectionSet(_memberNFT);
    }

    function setProposalThreshold(uint256 _proposalThresholdTokens, uint256 _proposalThresholdReputation) public onlyOwner {
        proposalThresholdTokens = _proposalThresholdTokens;
        proposalThresholdReputation = _proposalThresholdReputation;
    }

    function setVotingPeriod(uint256 _votingPeriodBlocks) public onlyOwner {
        require(_votingPeriodBlocks > 0, "Voting period must be > 0");
        votingPeriodBlocks = _votingPeriodBlocks;
    }

    function setQuorumPercentage(uint256 _quorumPercentage) public onlyOwner {
        require(_quorumPercentage <= 100, "Quorum percentage invalid");
        quorumPercentage = _quorumPercentage;
    }

    function setChallengeDepositAmount(uint256 _depositAmount) public onlyOwner {
         challengeDepositAmount = _depositAmount;
    }

    function setTreasuryRecipient(address _recipient) public onlyOwner {
        require(_recipient != address(0), "Invalid recipient address");
        treasuryRecipient = _recipient;
    }

    function pause() public onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() public onlyOwner whenPaused {
        _unpause();
    }

    // --- Treasury Management ---

    // Receive ETH directly into the contract (the treasury)
    receive() external payable {
        // ETH deposit handled implicitly
    }

    // Function to allow depositing ERC20 tokens (requires caller to approve this contract first)
    function depositToTreasury(address tokenAddress, uint256 amount) external nonReentrant whenNotPaused {
         require(tokenAddress != address(0), "Invalid token address");
         IERC20 token = IERC20(tokenAddress);
         require(token.transferFrom(msg.sender, address(this), amount), "Token transfer failed");
    }

    function getTreasuryBalance(address tokenAddress) public view returns (uint256) {
        if (tokenAddress == address(0)) {
            return address(this).balance; // ETH balance
        } else {
            return IERC20(tokenAddress).balanceOf(address(this)); // ERC20 balance
        }
    }

    // Note: Withdrawal from treasury happens only via `executeProposal` with ProposalType.TreasurySpend

    // --- Proposal System ---

    function _checkProposalThreshold(address proposer) private view returns (bool) {
        uint256 tokenBalance = governanceToken.balanceOf(proposer);
        uint256 userReputation = reputation[proposer];
        return tokenBalance >= proposalThresholdTokens || userReputation >= proposalThresholdReputation;
    }

    function proposeContribution(string memory _chronicleEntryHash, string memory _description) external whenNotPaused nonReentrant {
        require(_checkProposalThreshold(msg.sender), "Insufficient tokens or reputation to propose");
        require(bytes(_chronicleEntryHash).length > 0, "Chronicle hash cannot be empty");

        uint256 proposalId = _nextProposalId++;
        uint256 snapshot = _getTotalVotingPower(); // Snapshot total power at proposal creation

        bytes memory callData = abi.encodeCall(this.addApprovedChronicleEntry, (_chronicleEntryHash, msg.sender));

        proposals[proposalId] = Proposal({
            id: proposalId,
            proposalType: ProposalType.Contribution,
            proposer: msg.sender,
            creationBlock: block.number,
            endBlock: block.number.add(votingPeriodBlocks),
            votesFor: 0,
            votesAgainst: 0,
            votesAbstain: 0,
            totalVotingPowerSnapshot: snapshot,
            description: _description,
            data: callData,
            state: ProposalState.Pending,
            executed: false
        });

        emit ProposalCreated(proposalId, msg.sender, ProposalType.Contribution, _description, block.number.add(votingPeriodBlocks));
    }

    function proposeConfigChange(uint256 _paramIndex, uint256 _newValue, string memory _description) external whenNotPaused nonReentrant {
         require(_checkProposalThreshold(msg.sender), "Insufficient tokens or reputation to propose");
         // Define valid param indices and their setter functions
         // Example mapping: 0 -> setProposalThresholdTokens, 1 -> setProposalThresholdReputation, etc.
         // A more robust solution would use a mapping or array of function selectors/indices
         // For simplicity, we'll represent param changes by an index and new value.
         // The `executeProposal` function will need logic to interpret `data` bytes based on `proposalType`.
         bytes memory callData;
         if (_paramIndex == 0) {
             callData = abi.encodeCall(this.setProposalThresholdTokens, (_newValue));
         } else if (_paramIndex == 1) {
              callData = abi.encodeCall(this.setProposalThresholdReputation, (_newValue));
         } else if (_paramIndex == 2) {
              callData = abi.encodeCall(this.setVotingPeriod, (_newValue));
         } else if (_paramIndex == 3) {
              callData = abi.encodeCall(this.setQuorumPercentage, (_newValue));
         } else if (_paramIndex == 4) {
              callData = abi.encodeCall(this.setChallengeDepositAmount, (_newValue));
         } // Add more param indices/setters as needed
         else {
             revert("Invalid config parameter index");
         }


        uint256 proposalId = _nextProposalId++;
        uint256 snapshot = _getTotalVotingPower();

        proposals[proposalId] = Proposal({
            id: proposalId,
            proposalType: ProposalType.ConfigChange,
            proposer: msg.sender,
            creationBlock: block.number,
            endBlock: block.number.add(votingPeriodBlocks),
            votesFor: 0,
            votesAgainst: 0,
            votesAbstain: 0,
            totalVotingPowerSnapshot: snapshot,
            description: _description,
            data: callData,
            state: ProposalState.Pending,
            executed: false
        });

        emit ProposalCreated(proposalId, msg.sender, ProposalType.ConfigChange, _description, block.number.add(votingPeriodBlocks));
    }

    function proposeTreasurySpend(address _recipient, uint256 _amount, string memory _description) external whenNotPaused nonReentrant {
        require(_checkProposalThreshold(msg.sender), "Insufficient tokens or reputation to propose");
        require(_recipient != address(0), "Invalid recipient address");
        require(_amount > 0, "Amount must be greater than zero");
        // Note: This only supports ETH spend for simplicity. Extend data payload for ERC20 spends.

        bytes memory callData = abi.encodeCall(this.withdrawFromTreasury, (_recipient, _amount));

        uint256 proposalId = _nextProposalId++;
        uint256 snapshot = _getTotalVotingPower();

        proposals[proposalId] = Proposal({
            id: proposalId,
            proposalType: ProposalType.TreasurySpend,
            proposer: msg.sender,
            creationBlock: block.number,
            endBlock: block.number.add(votingPeriodBlocks),
            votesFor: 0,
            votesAgainst: 0,
            votesAbstain: 0,
            totalVotingPowerSnapshot: snapshot,
            description: _description,
            data: callData,
            state: ProposalState.Pending,
            executed: false
        });

        emit ProposalCreated(proposalId, msg.sender, ProposalType.TreasurySpend, _description, block.number.add(votingPeriodBlocks));
    }

    // Allows proposing Minting an NFT to a user via governance
     function proposeMintNFT(address _recipient, uint256 _tier, string memory _description) external whenNotPaused nonReentrant {
        require(_checkProposalThreshold(msg.sender), "Insufficient tokens or reputation to propose");
        require(_recipient != address(0), "Invalid recipient address");
        // _tier would define parameters for the NFT minting logic in the NFT contract

        bytes memory callData = abi.encodeCall(this.mintMemberNFT, (_recipient, _tier));

        uint256 proposalId = _nextProposalId++;
        uint256 snapshot = _getTotalVotingPower();

         proposals[proposalId] = Proposal({
            id: proposalId,
            proposalType: ProposalType.MintNFT,
            proposer: msg.sender,
            creationBlock: block.number,
            endBlock: block.number.add(votingPeriodBlocks),
            votesFor: 0,
            votesAgainst: 0,
            votesAbstain: 0,
            totalVotingPowerSnapshot: snapshot,
            description: _description,
            data: callData,
            state: ProposalState.Pending,
            executed: false
        });

        emit ProposalCreated(proposalId, msg.sender, ProposalType.MintNFT, _description, block.number.add(votingPeriodBlocks));
    }


    // Allows proposing triggering a dynamic NFT metadata update for a user via governance
     function proposeSignalNFTUpdate(address _user, string memory _description) external whenNotPaused nonReentrant {
        require(_checkProposalThreshold(msg.sender), "Insufficient tokens or reputation to propose");
        require(_user != address(0), "Invalid user address");
        // The actual tier/level change logic would likely be in the NFT contract,
        // triggered by this signal function call which might pass the user's stats from the DAO.

        // We'll pass user's current reputation and contribution count as example data.
        bytes memory callData = abi.encodeCall(this.signalNFTMetadataUpdate, (_user)); // The NFT contract will query stats from the DAO

        uint256 proposalId = _nextProposalId++;
        uint256 snapshot = _getTotalVotingPower();

         proposals[proposalId] = Proposal({
            id: proposalId,
            proposalType: ProposalType.SignalNFTUpdate,
            proposer: msg.sender,
            creationBlock: block.number,
            endBlock: block.number.add(votingPeriodBlocks),
            votesFor: 0,
            votesAgainst: 0,
            votesAbstain: 0,
            totalVotingPowerSnapshot: snapshot,
            description: _description,
            data: callData,
            state: ProposalState.Pending,
            executed: false
        });

        emit ProposalCreated(proposalId, msg.sender, ProposalType.SignalNFTUpdate, _description, block.number.add(votingPeriodBlocks));
    }


    // Internal function to create a challenge proposal
    function _createChallengeProposal(uint256 _chronicleEntryId, address _challenger) private returns (uint256) {
         uint256 proposalId = _nextProposalId++;
         uint256 snapshot = _getTotalVotingPower();

        bytes memory callData = abi.encodeCall(this.resolveChallenge, (proposalId)); // Challenge proposal calls resolveChallenge

         proposals[proposalId] = Proposal({
            id: proposalId,
            proposalType: ProposalType.ChallengeVote,
            proposer: _challenger, // Challenger is the proposer of the challenge vote
            creationBlock: block.number,
            endBlock: block.number.add(votingPeriodBlocks),
            votesFor: 0, // Votes 'For' removing the entry
            votesAgainst: 0, // Votes 'Against' removing the entry (i.e., keeping it)
            votesAbstain: 0,
            totalVotingPowerSnapshot: snapshot,
            description: string(abi.encodePacked("Challenge vote for Chronicle Entry #", Strings.toString(_chronicleEntryId))),
            data: callData,
            state: ProposalState.Pending,
            executed: false
        });

        challenges[proposalId] = Challenge({ // Link the challenge proposal ID to the challenge details
             challengeProposalId: proposalId,
             chronicleEntryId: _chronicleEntryId,
             challenger: _challenger,
             challengeBlock: block.number,
             resolved: false
        });

        emit ProposalCreated(proposalId, _challenger, ProposalType.ChallengeVote, proposals[proposalId].description, proposals[proposalId].endBlock);
        emit ChallengeCreated(proposalId, _chronicleEntryId, _challenger);

        return proposalId;
    }


    function getProposalState(uint256 _proposalId) public view returns (ProposalState) {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.creationBlock == 0) { // Proposal ID doesn't exist
             return ProposalState.Expired; // Or maybe a dedicated 'NotFound' state
        }

        if (proposal.state == ProposalState.Canceled) {
            return ProposalState.Canceled;
        }
        if (proposal.executed) {
             return ProposalState.Executed;
        }

        if (block.number <= proposal.endBlock) {
            return ProposalState.Active;
        }

        // Voting period ended, determine outcome
        uint256 totalVotes = proposal.votesFor.add(proposal.votesAgainst).add(proposal.votesAbstain);
        // Check Quorum: total votes must meet the percentage of total voting power snapshot
        uint256 requiredVotesForQuorum = proposal.totalVotingPowerSnapshot.mul(quorumPercentage).div(100);

        if (totalVotes < requiredVotesForQuorum) {
            return ProposalState.Defeated; // Failed quorum
        }

        if (proposal.votesFor > proposal.votesAgainst) {
             return ProposalState.Succeeded;
        } else {
             return ProposalState.Defeated;
        }
    }

    // --- Voting & Delegation ---

    function _getVoterVotingPower(address voter) private view returns (uint256) {
        address delegatee = delegations[voter];
        if (delegatee != address(0)) {
            // If delegated, get delegatee's voting power (which might include their own token balance + received delegations)
            // A more complex system would sum delegated power recursively or use a token with checkpointing.
            // For simplicity here, we'll just return the delegatee's raw token balance.
            // A real implementation should use governanceToken.getVotes(delegatee) if the token supports it.
            return governanceToken.balanceOf(delegatee); // Simplified voting power
        } else {
             // If not delegated, get their own token balance
             return governanceToken.balanceOf(voter); // Simplified voting power
        }
         // Ideal: return governanceToken.getVotes(voter); // Assumes token supports delegation & votes
    }

     function getVotingPower(address _voter) public view returns (uint256) {
        // Returns the voting power considering delegation
        // This is a public view wrapper for _getVoterVotingPower
        return _getVoterVotingPower(_voter);
    }


    function castVote(uint256 _proposalId, VoteType _vote) external whenNotPaused nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.creationBlock != 0, "Proposal does not exist");
        require(getProposalState(_proposalId) == ProposalState.Active, "Proposal not active");
        require(_votes[_proposalId][msg.sender] == VoteType.Against, "Already voted on this proposal"); // Against == 0, which is default for uninitialized mapping

        uint256 votingPower = _getVoterVotingPower(msg.sender);
        require(votingPower > 0, "Insufficient voting power");

        _votes[_proposalId][msg.sender] = _vote;

        if (_vote == VoteType.For) {
            proposal.votesFor = proposal.votesFor.add(votingPower);
        } else if (_vote == VoteType.Against) {
            proposal.votesAgainst = proposal.votesAgainst.add(votingPower);
        } else if (_vote == VoteType.Abstain) {
            proposal.votesAbstain = proposal.votesAbstain.add(votingPower);
        }

        // Add pending rewards for the voter (e.g., a small fixed amount per vote or scaled by voting power)
        // For simplicity, let's add a fixed small amount. Reward pool needs funding.
        _addPendingReward(msg.sender, 1 ether / 1000); // Example: 0.001 RewardToken per vote

        emit VoteCast(_proposalId, msg.sender, _vote, votingPower);
    }

     function delegateVotingPower(address _delegatee) external whenNotPaused nonReentrant {
         require(_delegatee != msg.sender, "Cannot delegate to yourself");
         require(_delegatee != address(0), "Cannot delegate to zero address");
         // Revoke any existing delegation first implicitly by setting a new one
         delegations[msg.sender] = _delegatee;
         emit DelegationUpdated(msg.sender, _delegatee);
     }

    function revokeDelegation() external whenNotPaused nonReentrant {
        require(delegations[msg.sender] != address(0), "No active delegation to revoke");
        delegations[msg.sender] = address(0);
        emit DelegationUpdated(msg.sender, address(0));
    }


    // --- Execution ---

    function executeProposal(uint256 _proposalId) external payable whenNotPaused nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.creationBlock != 0, "Proposal does not exist");
        require(proposal.executed == false, "Proposal already executed");

        ProposalState currentState = getProposalState(_proposalId);
        require(currentState == ProposalState.Succeeded, "Proposal not in Succeeded state");

        // Optionally, check if the proposal is 'queued' or has passed a min delay since endBlock
        // This adds a security buffer. For simplicity, we execute immediately after it's succeeded.

        proposal.executed = true;

        // Execute the specific action based on proposal type and data
        bool success;
        // Use low-level call for flexibility, but requires careful encoding
        (success, ) = address(this).call(proposal.data);
        // Revert if the internal call failed
        require(success, "Proposal execution failed");

        // Grant reputation/rewards to proposer and possibly voters
        _grantReputation(proposal.proposer, 10); // Example: 10 reputation for proposer
        // Grant reputation/rewards to voters? Could be done here based on vote type/amount

        emit ProposalExecuted(_proposalId, msg.sender);
    }

    function cancelProposal(uint256 _proposalId) external whenNotPaused nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.creationBlock != 0, "Proposal does not exist");
        require(getProposalState(_proposalId) == ProposalState.Active || getProposalState(_proposalId) == ProposalState.Pending, "Proposal not cancellable (not active or pending)");

        // Allow proposer or owner to cancel
        require(msg.sender == proposal.proposer || msg.sender == owner(), "Only proposer or owner can cancel");

        // Optionally, add a condition like min votes received etc.
        // require(proposal.votesFor.add(proposal.votesAgainst).add(proposal.votesAbstain) == 0, "Cannot cancel proposal with votes");

        proposal.state = ProposalState.Canceled;
        emit ProposalCanceled(_proposalId);
    }


    // --- Chronicle Management (internal, called by executeProposal) ---

    function addApprovedChronicleEntry(string memory _chronicleEntryHash, address _contributor) external onlyThis nonReentrant {
        // This function should ONLY be callable by the contract itself via `executeProposal`
        // The `onlyThis` modifier ensures this.

        uint256 entryId = _nextChronicleEntryId++;
        chronicleEntryIds.push(entryId); // Add ID to the ordered list

        chronicle[entryId] = ChronicleEntry({
            id: entryId,
            proposalId: proposals[_nextProposalId -1].id, // Assumes the current proposal being executed
            contributor: _contributor,
            dataHash: _chronicleEntryHash,
            addedBlock: block.number,
            active: true
        });

        // Grant reputation to the contributor for getting an entry approved
        _grantReputation(_contributor, 50); // Example: 50 reputation for accepted entry

        // Increment contribution count for the user
        // userProfiles[_contributor].contributionCount = userProfiles[_contributor].contributionCount.add(1); // Requires adding contributionCount to UserProfile

        emit ChronicleEntryAdded(entryId, proposals[_nextProposalId -1].id, _chronicleEntryHash, _contributor);
    }

    // Helper modifier to ensure a function is called internally by this contract
    modifier onlyThis() {
        require(msg.sender == address(this), "Only callable internally");
        _;
    }

    function getChronicleEntry(uint256 _index) public view returns (ChronicleEntry memory) {
        require(_index < chronicleEntryIds.length, "Invalid chronicle index");
        uint256 entryId = chronicleEntryIds[_index];
        require(chronicle[entryId].active, "Entry is not active"); // Only return active entries
        return chronicle[entryId];
    }

    function getChronicleSize() public view returns (uint256) {
        // This returns the count including inactive entries.
        // Consider adding a function to count only active entries if needed.
        return chronicleEntryIds.length;
    }

    // --- Reputation System ---

    function _grantReputation(address _user, uint256 _amount) private {
        reputation[_user] = reputation[_user].add(_amount);
        emit ReputationUpdated(_user, reputation[_user]);
    }

    // _burnReputation could also be implemented internally if needed via governance proposals
    function _burnReputation(address _user, uint256 _amount) private {
         reputation[_user] = reputation[_user] > _amount ? reputation[_user].sub(_amount) : 0;
        emit ReputationUpdated(_user, reputation[_user]);
    }

    function getReputation(address _user) public view returns (uint256) {
        return reputation[_user];
    }

    // --- NFT Integration (internal/external, called by executeProposal or internal logic) ---

    function mintMemberNFT(address _recipient, uint256 _tier) external onlyThis nonReentrant {
        // This function is intended to be called by `executeProposal`
        // The NFT contract should have a mint function callable by the DAO.
        // tokenId and uri logic would be in the NFT contract based on _tier or other params.
        // Example: memberNFTCollection.mint(_recipient, nextNFTId, calculatedURI);
        // For demonstration, we'll call a simplified interface function.
        uint256 exampleTokenId = 1000 + _tier; // Example ID calculation
        string memory exampleURI = string(abi.encodePacked("ipfs://somehash/tier", Strings.toString(_tier))); // Example URI

        memberNFTCollection.mint(_recipient, exampleTokenId, exampleURI); // Call to the NFT contract
        // Optional: Grant reputation or reward for receiving an NFT
        _grantReputation(_recipient, 20);
    }

    // This function signals the NFT contract to potentially update metadata for a user's NFT(s)
    // Based on their current stats like reputation, contribution count, etc.
     function signalNFTMetadataUpdate(address _user) external onlyThis nonReentrant {
        // This function is intended to be called by `executeProposal` or potentially other internal logic
        // The NFT contract's `signalUpdateMetadata` function will look up the user's stats in this DAO contract
        // (e.g., reputation[_user], contributionCount) and update the tokenURI accordingly.
        uint256 userCurrentReputation = reputation[_user];
        // uint256 userContributionCount = userProfiles[_user].contributionCount; // Requires UserProfile update

        // Call the NFT contract to trigger its dynamic metadata update logic
        memberNFTCollection.signalUpdateMetadata(_user, userCurrentReputation); // Pass relevant data points
        // Note: The NFT contract needs to have a view function to query these stats or be passed them.
     }

    // Helper function to get NFTs owned by a user from the configured collection
    function getUserNFTs(address _user) public view returns (uint256[] memory) {
        // This assumes the IMemberNFT interface includes a helper function like getTokenIdsOwnedBy
        return memberNFTCollection.getTokenIdsOwnedBy(_user);
    }


    // --- Challenges ---

    function challengeContribution(uint256 _chronicleEntryIndex) external payable whenNotPaused nonReentrant {
        require(_chronicleEntryIndex < chronicleEntryIds.length, "Invalid chronicle index");
        uint256 entryId = chronicleEntryIds[_chronicleEntryIndex];
        ChronicleEntry storage entry = chronicle[entryId];
        require(entry.active, "Chronicle entry is not active and cannot be challenged");
        // Require deposit
        require(msg.value >= challengeDepositAmount, "Insufficient challenge deposit");
        // Transfer deposit to the DAO treasury (contract balance)
        if (challengeDepositAmount > 0) {
             // Deposit implicitly handled by payable if sending ETH.
             // If challengeDepositAmount is for an ERC20, need approval/transferFrom.
             // Assuming ETH for simplicity.
        }


        // Create a new proposal specifically for this challenge vote
        uint256 challengeProposalId = _createChallengeProposal(entryId, msg.sender);

        // Store link between entry and challenge proposal (already done in _createChallengeProposal)
        // challenges[challengeProposalId] = Challenge(...)
    }

    // Internal function called by executeProposal for ChallengeVote type
    function resolveChallenge(uint256 _challengeProposalId) external onlyThis nonReentrant {
        Challenge storage challenge = challenges[_challengeProposalId];
        require(challenge.challengeProposalId != 0, "Challenge does not exist");
        require(challenge.resolved == false, "Challenge already resolved");

        Proposal storage challengeVoteProposal = proposals[_challengeProposalId];
        require(challengeVoteProposal.proposalType == ProposalType.ChallengeVote, "Proposal is not a challenge vote");
        require(getProposalState(_challengeProposalId) == ProposalState.Succeeded || getProposalState(_challengeProposalId) == ProposalState.Defeated, "Challenge vote not ended or not succeeded/defeated");

        ChronicleEntry storage entry = chronicle[challenge.chronicleEntryId];

        bool challengeSuccessful = false; // Means the entry is REMOVED

        if (getProposalState(_challengeProposalId) == ProposalState.Succeeded) {
            // Challenge vote Succeeded => votes 'For' removing the entry won
            entry.active = false; // Mark the entry as inactive
            // Return deposit to challenger? Penalize contributor?
            // Example: Challenger gets deposit back, Contributor loses reputation.
            // uint256 deposit = challengeDepositAmount; // Or retrieve actual deposit amount if ERC20
            // (bool sent, bytes memory data) = payable(challenge.challenger).call{value: deposit}(""); // Return deposit
            // require(sent, "Failed to return challenge deposit");
             _burnReputation(entry.contributor, 30); // Example penalty
            challengeSuccessful = true;
        } else {
            // Challenge vote Defeated => votes 'Against' removing the entry won
            // Challenger loses deposit? Contributor gains reputation?
            // Example: Challenger loses deposit (stays in treasury), Contributor gains reputation.
            // Deposit remains in contract balance.
            _grantReputation(entry.contributor, 15); // Example reward
             _burnReputation(challenge.challenger, 10); // Example penalty for failed challenge
        }

        challenge.resolved = true;
        emit ChallengeResolved(_challengeProposalId, challengeSuccessful);
    }

    // --- Rewards ---

    // Add rewards internally (e.g., after successful vote, contribution accepted)
    function _addPendingReward(address _user, uint256 _amount) private {
        if (_amount > 0) {
            _pendingRewards[_user] = _pendingRewards[_user].add(_amount);
        }
    }

    // Claim accumulated rewards
    function claimReward() external nonReentrant whenNotPaused {
        uint256 amount = _pendingRewards[msg.sender];
        require(amount > 0, "No pending rewards");

        _pendingRewards[msg.sender] = 0; // Clear pending rewards before sending

        // Assume rewards are in governance token for simplicity
        // Transfer reward tokens from this contract's balance
        require(governanceToken.transfer(msg.sender, amount), "Reward transfer failed");

        emit RewardsClaimed(msg.sender, amount);
    }

    // --- User Profile ---

     function registerContributorProfile(string memory _profileDataHash) external whenNotPaused nonReentrant {
        // Store an identifier for external profile data (e.g., IPFS hash of a JSON file)
        require(bytes(_profileDataHash).length > 0, "Profile data hash cannot be empty");
        userProfiles[msg.sender] = UserProfile({
            profileDataHash: _profileDataHash,
            registered: true
        });
        emit UserProfileUpdated(msg.sender, _profileDataHash);
     }

     function getUserProfile(address _user) public view returns (UserProfile memory) {
        return userProfiles[_user];
     }

     function updateUserProfile(string memory _profileDataHash) external whenNotPaused nonReentrant {
         // Allow updating the profile data hash
         require(userProfiles[msg.sender].registered, "User profile not registered");
         require(bytes(_profileDataHash).length > 0, "Profile data hash cannot be empty");
         userProfiles[msg.sender].profileDataHash = _profileDataHash;
         emit UserProfileUpdated(msg.sender, _profileDataHash);
     }


    // --- Internal Helpers ---

    // Get total current voting power (sum of all token balances, considering delegations)
    // This is complex to do accurately and gas-efficiently on-chain for a large user base
    // using raw balances. A governance token with checkpointing/snapshotting is ideal.
    // This simplified version just returns the total supply of the governance token.
    // A real DAO would use governanceToken.totalSupplyAt(block.number) or similar
    // if the token supports snapshotting.
    function _getTotalVotingPower() private view returns (uint256) {
        // WARNING: This is a simplified snapshot using current total supply.
        // A proper DAO token should implement snapshotting based on block number.
        // E.g., `uint256 totalPower = governanceToken.totalSupply();`
        // Or, if using a token with `getPastTotalSupply(blockNumber)`:
        // `uint256 totalPower = governanceToken.getPastTotalSupply(block.number);`
        // For demonstration, we'll just use current total supply.
         return governanceToken.totalSupply();
    }

     // Internal function to withdraw ETH from the treasury (only via proposal execution)
    function withdrawFromTreasury(address _recipient, uint256 _amount) external onlyThis nonReentrant {
        require(_recipient != address(0), "Invalid recipient");
        require(_amount > 0, "Amount must be > 0");
        require(address(this).balance >= _amount, "Insufficient treasury balance");

        (bool success, ) = payable(_recipient).call{value: _amount}("");
        require(success, "ETH transfer failed");
    }

    // Simplified internal setters for config change proposals (called by executeProposal)
    function setProposalThresholdTokens(uint256 _value) external onlyThis {
        proposalThresholdTokens = _value;
    }
    function setProposalThresholdReputation(uint256 _value) external onlyThis {
        proposalThresholdReputation = _value;
    }
    // setVotingPeriod, setQuorumPercentage, setChallengeDepositAmount are already public owner functions,
    // executeProposal can call them directly if owner == address(this) or use internal variants if needed.
    // For this design, the public owner functions are sufficient targets for `abi.encodeCall`.

}
```