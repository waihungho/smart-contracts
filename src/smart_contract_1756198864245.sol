Here's a Solidity smart contract named `Aethelgard` that implements an advanced, creative, and trendy concept: a decentralized protocol for AI-driven collaborative content generation and curation with dynamic, evolving NFTs and a reputation-based governance model.

This contract aims to be unique by integrating:
1.  **AI Oracle Interaction (Simulated):** For objective content appraisal.
2.  **Dynamic/Evolving NFTs:** NFTs that change based on new contributions and AI appraisal.
3.  **Collaborative Creation & Curation:** A multi-stage process for content creation.
4.  **Reputation System:** To reward positive contributions and influence.
5.  **Staking & Governance:** Enabling community-driven decision-making and value capture.

---

### Aethelgard: Decentralized AI-Driven Collaborative Content Protocol

**Outline and Function Summary:**

This contract orchestrates a collaborative ecosystem where users contribute creative fragments, curators combine and propose them into "AethelNFTs," and these NFTs can evolve over time, all guided by AI appraisals and community governance.

**I. Core Setup & Administration (5 functions)**

*   `constructor(address _initialGovernance, address _aethelTokenAddress, address _aiOracleAddress)`: Initializes the contract, sets up the initial governance, the Aethel utility token, and the AI Oracle.
*   `setGovernanceAddress(address _newGovernance)`: Allows the current governance to transfer governance control to a new address.
*   `setAethelTokenAddress(address _tokenAddress)`: Sets the address of the Aethel utility token (ERC20). Can only be set once or by governance.
*   `setAIOracleAddress(address _oracleAddress)`: Sets the address of the AI Oracle contract. Can only be set once or by governance.
*   `updateProtocolFee(uint256 _newFeePercent)`: Governance function to adjust the percentage of AETHEL tokens collected as fees for protocol operations.

**II. Creative Fragment Management (Contributions) (4 functions)**

*   `submitCreativeFragment(string calldata _contentHash, string calldata _description)`: Allows any user to submit a hash of their creative content fragment (e.g., IPFS hash) along with a brief description. Requires a small AETHEL fee.
*   `requestAIAppraisal(uint256 _fragmentId)`: Allows an authorized entity (e.g., a curator or governance) to request an AI appraisal for a specific fragment. This triggers a call to the AI Oracle.
*   `receiveAIAppraisal(uint256 _fragmentId, uint256 _aiScore)`: A callback function designed to be called *only* by the designated AI Oracle contract to deliver an appraisal score for a fragment.
*   `getFragmentDetails(uint256 _fragmentId)`: Retrieves comprehensive details of a submitted creative fragment, including its owner, content hash, AI score, and status.

**III. Curator Staking & AethelNFT Creation (5 functions)**

*   `stakeForCuration(uint256 _amount)`: Users stake AETHEL tokens to become active curators, gaining voting power and the ability to propose AethelNFTs. Staked tokens are locked.
*   `unstakeFromCuration(uint256 _amount)`: Users can request to unstake their AETHEL tokens. This initiates an unbonding period before tokens become claimable.
*   `proposeAethelNFT(uint256[] calldata _fragmentIds, string calldata _metadataURI)`: Curators combine multiple AI-appraised fragments (requiring minimum AI scores) to propose a new AethelNFT, including its initial metadata URI. Requires a curator stake.
*   `voteOnAethelNFTProposal(uint256 _proposalId, bool _approve)`: AETHEL stakers (curators) vote on proposed AethelNFTs. Their voting power is proportional to their stake.
*   `mintAethelNFT(uint256 _proposalId)`: If an AethelNFT proposal passes its vote, the proposing curator can mint the new AethelNFT, paying a fee that is distributed as rewards.

**IV. AethelNFT Management & Evolution (4 functions)**

*   `getAethelNFTDetails(uint256 _tokenId)`: Retrieves comprehensive details about a specific AethelNFT, including its constituent fragments, current metadata, AI score, and generation.
*   `requestNFTEvolution(uint256 _tokenId, uint256 _newFragmentId, string calldata _newMetadataURI)`: An AethelNFT owner can propose an evolution for their NFT by integrating a new, highly-appraised fragment and an updated metadata URI.
*   `submitEvolutionAppraisal(uint256 _evolutionId, uint256 _newAIScore)`: A callback function for the AI Oracle to appraise a proposed NFT evolution, providing a new combined AI score.
*   `approveNFTEvolution(uint256 _evolutionId)`: Governance or a sufficiently voted body approves a proposed NFT evolution if its AI appraisal meets a threshold, updating the NFT's properties and potentially increasing its value.

**V. Reputation & Rewards (2 functions)**

*   `getContributorReputation(address _contributor)`: Returns the accumulated reputation score for a specific contributor. Reputation increases with high AI-scored fragments, successful NFT proposals, and positive votes.
*   `claimRewards()`: Allows eligible users (contributors for high-quality fragments, curators for successful proposals, stakers for participation) to claim their accumulated AETHEL token rewards from fees and distribution pools.

**VI. Governance & Treasury (4 functions)**

*   `proposeProtocolParameterChange(bytes32 _paramName, uint256 _newValue)`: AETHEL stakers can propose changes to key protocol parameters (e.g., fee percentages, staking requirements, minimum AI scores).
*   `voteOnProposal(uint256 _proposalId, bool _support)`: Allows AETHEL stakers (curators) to vote on active governance proposals.
*   `executeProposal(uint256 _proposalId)`: Executes a governance proposal that has met the required voting thresholds (e.g., quorum and approval percentage).
*   `withdrawTreasuryFunds(address _recipient, uint256 _amount)`: Allows governance to withdraw AETHEL tokens from the protocol's treasury, typically for operational costs or further development.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol"; // Using a base ERC721 for brevity, focus is on new logic.
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Minimal interface for our mock AI Oracle.
// In a real scenario, this would be a Chainlink external adapter or similar.
interface I_AIOracle {
    function requestFragmentAppraisal(uint256 _fragmentId, string calldata _contentHash) external;
    function requestNFTEvolutionAppraisal(uint256 _evolutionId, string calldata _metadataURI) external;
    // The oracle would call back to Aethelgard with results.
    // For this example, we'll simulate an internal callback from 'governance' or a 'trusted AI agent'.
}

// Custom ERC721 for AethelNFTs
contract AethelNFTBase is ERC721 {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("Aethelgard Content Asset", "AETHELNFT") {}

    function _mint(address to, string memory tokenURI, uint256 currentAIScore, uint256 generation) internal returns (uint256) {
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();
        _safeMint(to, newTokenId);
        _setTokenURI(newTokenId, tokenURI);
        // We'll manage other NFT properties (AI Score, Generation) in the main Aethelgard contract.
        return newTokenId;
    }

    function _getCurrentTokenId() internal view returns (uint256) {
        return _tokenIdCounter.current();
    }
}


contract Aethelgard is Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    // --- State Variables ---

    // --- Core Protocol Parameters ---
    IERC20 public aethelToken;
    I_AIOracle public aiOracle;
    address public governanceAddress; // The address controlling core protocol parameters and treasury
    uint256 public protocolFeePercent = 500; // 5% (500 basis points out of 10000)
    uint256 public minFragmentAIScoreForNFT = 60; // Minimum AI score required for a fragment to be included in an NFT
    uint256 public minCuratorStake = 100 ether; // Minimum AETHEL tokens required to be a curator
    uint256 public unbondingPeriod = 7 days; // Time in seconds before staked tokens can be fully unstaked
    uint256 public proposalQuorumPercent = 5000; // 50% of total staked tokens needed for a proposal to pass
    uint256 public proposalVoteDuration = 3 days; // Duration for voting on proposals
    uint256 public minEvolutionAIScore = 70; // Minimum combined AI score for an NFT evolution to be approved


    // --- Fragment Management ---
    struct Fragment {
        uint256 id;
        address owner;
        string contentHash; // IPFS hash or similar
        string description;
        uint256 aiScore;
        uint256 submittedTimestamp;
        bool appraised;
        bool exists; // To check if a fragment ID is valid
    }
    Counters.Counter private _fragmentIdCounter;
    mapping(uint256 => Fragment) public fragments;

    // --- AethelNFT Management ---
    AethelNFTBase public aethelNFT; // Our custom ERC721 contract
    struct AethelNFT {
        uint256 id;
        address owner;
        uint256[] fragmentIds; // IDs of fragments composing this NFT
        string metadataURI; // Current metadata URI for the NFT
        uint256 currentAIScore;
        uint256 generation; // How many times it has evolved
        uint256 lastEvolutionTimestamp;
        bool exists;
    }
    mapping(uint256 => AethelNFT) public aethelNFTs; // ERC721 token ID => AethelNFT data

    // --- NFT Creation Proposals ---
    struct AethelNFTProposal {
        uint256 id;
        address proposer;
        uint256[] fragmentIds;
        string metadataURI;
        uint256 totalYesVotes;
        uint256 totalNoVotes;
        uint256 createdTimestamp;
        uint256 minterReward; // Rewards for the proposer if minted
        mapping(address => bool) hasVoted; // For tracking who voted
        ProposalStatus status;
    }
    Counters.Counter private _aethelNFTProposalIdCounter;
    mapping(uint256 => AethelNFTProposal) public aethelNFTProposals;

    // --- NFT Evolution Proposals ---
    struct NFTEvolutionProposal {
        uint256 id;
        uint256 tokenId;
        uint256 newFragmentId;
        string newMetadataURI;
        uint256 aiScore; // Combined AI score after proposed evolution
        address proposer;
        uint256 requestedTimestamp;
        ProposalStatus status;
    }
    Counters.Counter private _nftEvolutionProposalIdCounter;
    mapping(uint256 => NFTEvolutionProposal) public nftEvolutionProposals;

    // --- Reputation & Rewards ---
    mapping(address => uint256) public contributorReputation; // Higher score for better contributions/curation
    mapping(address => uint256) public rewards; // AETHEL rewards accumulated
    uint256 public totalProtocolFees = 0; // Total AETHEL fees collected by the protocol

    // --- Curator Staking ---
    mapping(address => uint256) public curatorStakes;
    mapping(address => (uint256 amount, uint256 unlockTime)) public pendingUnstakes;
    uint256 public totalStakedTokens = 0;

    // --- Governance Proposals ---
    enum ProposalStatus { Pending, Succeeded, Failed, Executed }
    struct GovernanceProposal {
        uint256 id;
        bytes32 paramName; // Example: "protocolFeePercent"
        uint256 newValue;
        address proposer;
        uint256 createdTimestamp;
        uint256 totalYesVotes;
        uint256 totalNoVotes;
        mapping(address => bool) hasVoted;
        ProposalStatus status;
    }
    Counters.Counter private _govProposalIdCounter;
    mapping(uint256 => GovernanceProposal) public governanceProposals;

    // --- Events ---
    event FragmentSubmitted(uint256 indexed fragmentId, address indexed owner, string contentHash, string description);
    event FragmentAppraisalReceived(uint256 indexed fragmentId, uint256 aiScore);
    event CuratorStaked(address indexed curator, uint256 amount);
    event CuratorUnstakeRequested(address indexed curator, uint256 amount, uint256 unlockTime);
    event CuratorUnstakeClaimed(address indexed curator, uint256 amount);
    event AethelNFTProposalCreated(uint256 indexed proposalId, address indexed proposer, uint256[] fragmentIds, string metadataURI);
    event AethelNFTProposalVoted(uint256 indexed proposalId, address indexed voter, bool support);
    event AethelNFTMinted(uint256 indexed tokenId, uint256 indexed proposalId, address indexed owner, string metadataURI);
    event NFTEvolutionRequested(uint256 indexed evolutionId, uint256 indexed tokenId, uint256 newFragmentId, string newMetadataURI);
    event NFTEvolutionAppraisalReceived(uint256 indexed evolutionId, uint256 aiScore);
    event NFTEvolutionApproved(uint256 indexed evolutionId, uint256 indexed tokenId, uint256 newAIScore);
    event RewardsClaimed(address indexed recipient, uint256 amount);
    event GovernanceProposalCreated(uint256 indexed proposalId, address indexed proposer, bytes32 paramName, uint256 newValue);
    event GovernanceProposalVoted(uint256 indexed proposalId, address indexed voter, bool support);
    event GovernanceProposalExecuted(uint256 indexed proposalId);
    event ProtocolFeeUpdated(uint256 newFeePercent);
    event TreasuryFundsWithdrawn(address indexed recipient, uint256 amount);

    // --- Modifiers ---
    modifier onlyAIOracle() {
        require(msg.sender == address(aiOracle), "Aethelgard: Only AI Oracle can call this function");
        _;
    }

    modifier onlyGovernance() {
        require(msg.sender == governanceAddress, "Aethelgard: Only governance can call this function");
        _;
    }

    modifier onlyCurator() {
        require(curatorStakes[msg.sender] >= minCuratorStake, "Aethelgard: Caller is not an active curator");
        _;
    }

    // --- Constructor ---
    constructor(address _initialGovernance, address _aethelTokenAddress, address _aiOracleAddress) Ownable(msg.sender) {
        require(_initialGovernance != address(0), "Aethelgard: Initial governance address cannot be zero");
        require(_aethelTokenAddress != address(0), "Aethelgard: AethelToken address cannot be zero");
        require(_aiOracleAddress != address(0), "Aethelgard: AIOracle address cannot be zero");

        governanceAddress = _initialGovernance;
        aethelToken = IERC20(_aethelTokenAddress);
        aiOracle = I_AIOracle(_aiOracleAddress);

        // Deploy the AethelNFTBase contract
        aethelNFT = new AethelNFTBase();
    }

    // --- I. Core Setup & Administration (5 functions) ---

    function setGovernanceAddress(address _newGovernance) public onlyGovernance {
        require(_newGovernance != address(0), "Aethelgard: New governance address cannot be zero");
        governanceAddress = _newGovernance;
    }

    function setAethelTokenAddress(address _tokenAddress) public onlyGovernance {
        require(address(aethelToken) == address(0), "Aethelgard: AethelToken address already set");
        require(_tokenAddress != address(0), "Aethelgard: Token address cannot be zero");
        aethelToken = IERC20(_tokenAddress);
    }

    function setAIOracleAddress(address _oracleAddress) public onlyGovernance {
        require(address(aiOracle) == address(0), "Aethelgard: AIOracle address already set");
        require(_oracleAddress != address(0), "Aethelgard: Oracle address cannot be zero");
        aiOracle = I_AIOracle(_oracleAddress);
    }

    function updateProtocolFee(uint256 _newFeePercent) public onlyGovernance {
        require(_newFeePercent <= 10000, "Aethelgard: Fee percent cannot exceed 100%");
        protocolFeePercent = _newFeePercent;
        emit ProtocolFeeUpdated(_newFeePercent);
    }

    // --- II. Creative Fragment Management (Contributions) (4 functions) ---

    function submitCreativeFragment(string calldata _contentHash, string calldata _description) public nonReentrant {
        require(bytes(_contentHash).length > 0, "Aethelgard: Content hash cannot be empty");

        // Fee for fragment submission
        uint256 submissionFee = 10 ether; // Example fee
        require(aethelToken.transferFrom(msg.sender, address(this), submissionFee), "Aethelgard: Token transfer failed for submission fee");
        totalProtocolFees += submissionFee;

        _fragmentIdCounter.increment();
        uint256 newFragmentId = _fragmentIdCounter.current();
        fragments[newFragmentId] = Fragment({
            id: newFragmentId,
            owner: msg.sender,
            contentHash: _contentHash,
            description: _description,
            aiScore: 0, // Will be set by AI oracle
            submittedTimestamp: block.timestamp,
            appraised: false,
            exists: true
        });

        emit FragmentSubmitted(newFragmentId, msg.sender, _contentHash, _description);
    }

    function requestAIAppraisal(uint256 _fragmentId) public onlyCurator { // Or onlyGovernance/trusted agent
        Fragment storage fragment = fragments[_fragmentId];
        require(fragment.exists, "Aethelgard: Fragment does not exist");
        require(!fragment.appraised, "Aethelgard: Fragment already appraised");

        // In a real system, this would trigger an external call to Chainlink or similar.
        // For this example, we assume the oracle itself calls `receiveAIAppraisal` later.
        aiOracle.requestFragmentAppraisal(_fragmentId, fragment.contentHash);
    }

    function receiveAIAppraisal(uint256 _fragmentId, uint256 _aiScore) public onlyAIOracle {
        Fragment storage fragment = fragments[_fragmentId];
        require(fragment.exists, "Aethelgard: Fragment does not exist");
        require(!fragment.appraised, "Aethelgard: Fragment already appraised");
        require(_aiScore <= 100, "Aethelgard: AI score must be <= 100");

        fragment.aiScore = _aiScore;
        fragment.appraised = true;

        // Reward contributor for high AI score
        if (_aiScore >= minFragmentAIScoreForNFT) {
            contributorReputation[fragment.owner] += _aiScore; // Add AI score to reputation
            rewards[fragment.owner] += _aiScore * 1 ether / 10; // Example reward: AI score * 0.1 AETHEL
        }

        emit FragmentAppraisalReceived(_fragmentId, _aiScore);
    }

    function getFragmentDetails(uint256 _fragmentId) public view returns (Fragment memory) {
        return fragments[_fragmentId];
    }

    // --- III. Curator Staking & AethelNFT Creation (5 functions) ---

    function stakeForCuration(uint256 _amount) public nonReentrant {
        require(_amount >= minCuratorStake, "Aethelgard: Amount must meet minimum curator stake");
        require(aethelToken.transferFrom(msg.sender, address(this), _amount), "Aethelgard: Token transfer failed for staking");

        curatorStakes[msg.sender] += _amount;
        totalStakedTokens += _amount;

        // If newly becoming a curator, grant some initial reputation
        if (curatorStakes[msg.sender] - _amount < minCuratorStake) {
            contributorReputation[msg.sender] += 100; // Initial boost
        }

        emit CuratorStaked(msg.sender, _amount);
    }

    function unstakeFromCuration(uint256 _amount) public nonReentrant {
        require(curatorStakes[msg.sender] >= _amount, "Aethelgard: Insufficient staked amount");
        
        // Ensure new stake meets minimum if still a curator
        if (curatorStakes[msg.sender] - _amount > 0 && curatorStakes[msg.sender] - _amount < minCuratorStake) {
            revert("Aethelgard: Unstaking would drop stake below minimum curator threshold. Unstake all or adjust amount.");
        }

        curatorStakes[msg.sender] -= _amount;
        totalStakedTokens -= _amount;

        pendingUnstakes[msg.sender] = (pendingUnstakes[msg.sender].amount + _amount, block.timestamp + unbondingPeriod);

        emit CuratorUnstakeRequested(msg.sender, _amount, block.timestamp + unbondingPeriod);
    }

    function claimUnstakedTokens() public nonReentrant {
        (uint256 amount, uint256 unlockTime) = pendingUnstakes[msg.sender];
        require(amount > 0, "Aethelgard: No pending unstake request");
        require(block.timestamp >= unlockTime, "Aethelgard: Unbonding period not over yet");

        delete pendingUnstakes[msg.sender]; // Clear the pending request
        require(aethelToken.transfer(msg.sender, amount), "Aethelgard: Failed to transfer unstaked tokens");

        emit CuratorUnstakeClaimed(msg.sender, amount);
    }

    function proposeAethelNFT(uint256[] calldata _fragmentIds, string calldata _metadataURI) public onlyCurator nonReentrant {
        require(_fragmentIds.length > 0, "Aethelgard: Must include at least one fragment");
        require(bytes(_metadataURI).length > 0, "Aethelgard: Metadata URI cannot be empty");

        uint256 totalFragmentAIScore = 0;
        for (uint256 i = 0; i < _fragmentIds.length; i++) {
            Fragment storage fragment = fragments[_fragmentIds[i]];
            require(fragment.exists && fragment.appraised, "Aethelgard: Fragment must exist and be appraised");
            require(fragment.aiScore >= minFragmentAIScoreForNFT, "Aethelgard: Fragment AI score too low");
            totalFragmentAIScore += fragment.aiScore;
        }

        _aethelNFTProposalIdCounter.increment();
        uint256 newProposalId = _aethelNFTProposalIdCounter.current();
        aethelNFTProposals[newProposalId] = AethelNFTProposal({
            id: newProposalId,
            proposer: msg.sender,
            fragmentIds: _fragmentIds,
            metadataURI: _metadataURI,
            totalYesVotes: 0,
            totalNoVotes: 0,
            createdTimestamp: block.timestamp,
            minterReward: 0, // Calculated upon minting
            status: ProposalStatus.Pending
        });

        emit AethelNFTProposalCreated(newProposalId, msg.sender, _fragmentIds, _metadataURI);
    }

    function voteOnAethelNFTProposal(uint256 _proposalId, bool _approve) public onlyCurator nonReentrant {
        AethelNFTProposal storage proposal = aethelNFTProposals[_proposalId];
        require(proposal.status == ProposalStatus.Pending, "Aethelgard: Proposal is not pending");
        require(!proposal.hasVoted[msg.sender], "Aethelgard: Already voted on this proposal");
        require(block.timestamp <= proposal.createdTimestamp + proposalVoteDuration, "Aethelgard: Voting period has ended");

        proposal.hasVoted[msg.sender] = true;
        uint256 voterStake = curatorStakes[msg.sender];

        if (_approve) {
            proposal.totalYesVotes += voterStake;
        } else {
            proposal.totalNoVotes += voterStake;
        }

        // Check if proposal can be moved to succeeded/failed early
        if (proposal.totalYesVotes >= (totalStakedTokens * proposalQuorumPercent / 10000)) {
             proposal.status = ProposalStatus.Succeeded;
        } else if (proposal.totalNoVotes >= (totalStakedTokens * (10000 - proposalQuorumPercent) / 10000)) {
            proposal.status = ProposalStatus.Failed;
        }

        emit AethelNFTProposalVoted(_proposalId, msg.sender, _approve);
    }

    function mintAethelNFT(uint256 _proposalId) public nonReentrant {
        AethelNFTProposal storage proposal = aethelNFTProposals[_proposalId];
        require(msg.sender == proposal.proposer, "Aethelgard: Only proposer can mint");
        require(proposal.status == ProposalStatus.Succeeded ||
                (proposal.status == ProposalStatus.Pending && block.timestamp > proposal.createdTimestamp + proposalVoteDuration && proposal.totalYesVotes > proposal.totalNoVotes),
                "Aethelgard: Proposal not approved or voting period not over/failed");
        require(proposal.status != ProposalStatus.Executed, "Aethelgard: NFT already minted for this proposal");
        
        // If pending, resolve status now
        if (proposal.status == ProposalStatus.Pending) {
            if (proposal.totalYesVotes > proposal.totalNoVotes) {
                proposal.status = ProposalStatus.Succeeded;
            } else {
                proposal.status = ProposalStatus.Failed;
            }
        }
        require(proposal.status == ProposalStatus.Succeeded, "Aethelgard: Proposal did not succeed");


        // Calculate average AI score for the NFT
        uint256 sumAIScores = 0;
        for (uint256 i = 0; i < proposal.fragmentIds.length; i++) {
            sumAIScores += fragments[proposal.fragmentIds[i]].aiScore;
        }
        uint256 avgAIScore = sumAIScores / proposal.fragmentIds.length;

        // Minting fee
        uint256 mintingFee = 20 ether; // Example fee
        require(aethelToken.transferFrom(msg.sender, address(this), mintingFee), "Aethelgard: Token transfer failed for minting fee");
        totalProtocolFees += mintingFee;

        // Distribute part of the fee as reward for proposer
        proposal.minterReward = mintingFee * (10000 - protocolFeePercent) / 10000;
        rewards[msg.sender] += proposal.minterReward;

        uint256 newTokenId = aethelNFT._mint(msg.sender, proposal.metadataURI, avgAIScore, 1); // Generation 1

        aethelNFTs[newTokenId] = AethelNFT({
            id: newTokenId,
            owner: msg.sender,
            fragmentIds: proposal.fragmentIds,
            metadataURI: proposal.metadataURI,
            currentAIScore: avgAIScore,
            generation: 1,
            lastEvolutionTimestamp: block.timestamp,
            exists: true
        });

        proposal.status = ProposalStatus.Executed; // Mark as minted
        contributorReputation[msg.sender] += avgAIScore; // Reward proposer reputation

        emit AethelNFTMinted(newTokenId, _proposalId, msg.sender, proposal.metadataURI);
    }


    // --- IV. AethelNFT Management & Evolution (4 functions) ---

    function getAethelNFTDetails(uint256 _tokenId) public view returns (AethelNFT memory) {
        return aethelNFTs[_tokenId];
    }

    function requestNFTEvolution(uint256 _tokenId, uint256 _newFragmentId, string calldata _newMetadataURI) public nonReentrant {
        AethelNFT storage existingNFT = aethelNFTs[_tokenId];
        require(existingNFT.exists, "Aethelgard: NFT does not exist");
        require(aethelNFT.ownerOf(_tokenId) == msg.sender, "Aethelgard: Only NFT owner can request evolution");

        Fragment storage newFragment = fragments[_newFragmentId];
        require(newFragment.exists && newFragment.appraised, "Aethelgard: New fragment must exist and be appraised");
        require(newFragment.aiScore >= minFragmentAIScoreForNFT, "Aethelgard: New fragment AI score too low for evolution");
        
        // Fee for evolution request
        uint256 evolutionFee = 5 ether; // Example fee
        require(aethelToken.transferFrom(msg.sender, address(this), evolutionFee), "Aethelgard: Token transfer failed for evolution fee");
        totalProtocolFees += evolutionFee;

        _nftEvolutionProposalIdCounter.increment();
        uint256 newEvolutionId = _nftEvolutionProposalIdCounter.current();

        nftEvolutionProposals[newEvolutionId] = NFTEvolutionProposal({
            id: newEvolutionId,
            tokenId: _tokenId,
            newFragmentId: _newFragmentId,
            newMetadataURI: _newMetadataURI,
            aiScore: 0, // To be set by AI oracle
            proposer: msg.sender,
            requestedTimestamp: block.timestamp,
            status: ProposalStatus.Pending
        });

        // Request AI appraisal for the combined NFT (existing + new fragment)
        aiOracle.requestNFTEvolutionAppraisal(newEvolutionId, _newMetadataURI); // Oracle would analyze both current and new
        emit NFTEvolutionRequested(newEvolutionId, _tokenId, _newFragmentId, _newMetadataURI);
    }

    function submitEvolutionAppraisal(uint256 _evolutionId, uint256 _newAIScore) public onlyAIOracle {
        NFTEvolutionProposal storage evolution = nftEvolutionProposals[_evolutionId];
        require(evolution.status == ProposalStatus.Pending, "Aethelgard: Evolution proposal not pending");
        require(_newAIScore <= 100, "Aethelgard: AI score must be <= 100");

        evolution.aiScore = _newAIScore;
        evolution.status = ProposalStatus.Succeeded; // Mark as appraised and potentially ready for approval

        emit NFTEvolutionAppraisalReceived(_evolutionId, _newAIScore);
    }

    function approveNFTEvolution(uint256 _evolutionId) public onlyGovernance { // Could be voted on by curators as well
        NFTEvolutionProposal storage evolution = nftEvolutionProposals[_evolutionId];
        require(evolution.status == ProposalStatus.Succeeded, "Aethelgard: Evolution not appraised or already executed/failed");
        require(evolution.aiScore >= minEvolutionAIScore, "Aethelgard: New AI score too low for evolution");

        AethelNFT storage nftToEvolve = aethelNFTs[evolution.tokenId];
        require(nftToEvolve.exists, "Aethelgard: NFT for evolution does not exist");

        // Update NFT details
        nftToEvolve.fragmentIds.push(evolution.newFragmentId);
        nftToEvolve.metadataURI = evolution.newMetadataURI;
        nftToEvolve.currentAIScore = evolution.aiScore;
        nftToEvolve.generation++;
        nftToEvolve.lastEvolutionTimestamp = block.timestamp;

        // Update tokenURI in the ERC721 contract
        aethelNFT.setTokenURI(evolution.tokenId, evolution.newMetadataURI);

        evolution.status = ProposalStatus.Executed;
        contributorReputation[evolution.proposer] += evolution.aiScore; // Reward reputation

        emit NFTEvolutionApproved(_evolutionId, evolution.tokenId, evolution.aiScore);
    }

    // --- V. Reputation & Rewards (2 functions) ---

    function getContributorReputation(address _contributor) public view returns (uint256) {
        return contributorReputation[_contributor];
    }

    function claimRewards() public nonReentrant {
        uint256 rewardAmount = rewards[msg.sender];
        require(rewardAmount > 0, "Aethelgard: No rewards to claim");

        rewards[msg.sender] = 0; // Reset rewards before transfer

        require(aethelToken.transfer(msg.sender, rewardAmount), "Aethelgard: Failed to transfer rewards");

        emit RewardsClaimed(msg.sender, rewardAmount);
    }

    // --- VI. Governance & Treasury (4 functions) ---

    function proposeProtocolParameterChange(bytes32 _paramName, uint256 _newValue) public onlyCurator {
        _govProposalIdCounter.increment();
        uint256 newProposalId = _govProposalIdCounter.current();

        governanceProposals[newProposalId] = GovernanceProposal({
            id: newProposalId,
            paramName: _paramName,
            newValue: _newValue,
            proposer: msg.sender,
            createdTimestamp: block.timestamp,
            totalYesVotes: 0,
            totalNoVotes: 0,
            status: ProposalStatus.Pending
        });

        emit GovernanceProposalCreated(newProposalId, msg.sender, _paramName, _newValue);
    }

    function voteOnProposal(uint256 _proposalId, bool _support) public onlyCurator {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.status == ProposalStatus.Pending, "Aethelgard: Proposal is not pending");
        require(!proposal.hasVoted[msg.sender], "Aethelgard: Already voted on this proposal");
        require(block.timestamp <= proposal.createdTimestamp + proposalVoteDuration, "Aethelgard: Voting period has ended");

        proposal.hasVoted[msg.sender] = true;
        uint256 voterStake = curatorStakes[msg.sender];

        if (_support) {
            proposal.totalYesVotes += voterStake;
        } else {
            proposal.totalNoVotes += voterStake;
        }

        // Check for early resolution
        if (proposal.totalYesVotes >= (totalStakedTokens * proposalQuorumPercent / 10000)) {
            proposal.status = ProposalStatus.Succeeded;
        } else if (proposal.totalNoVotes >= (totalStakedTokens * (10000 - proposalQuorumPercent) / 10000)) {
            proposal.status = ProposalStatus.Failed;
        }
        
        emit GovernanceProposalVoted(_proposalId, msg.sender, _support);
    }

    function executeProposal(uint256 _proposalId) public onlyGovernance { // Can also be called by anyone after a delay
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.status != ProposalStatus.Executed, "Aethelgard: Proposal already executed");
        require(block.timestamp > proposal.createdTimestamp + proposalVoteDuration, "Aethelgard: Voting period not over");

        // Resolve status if still pending
        if (proposal.status == ProposalStatus.Pending) {
            if (proposal.totalYesVotes >= (totalStakedTokens * proposalQuorumPercent / 10000) && proposal.totalYesVotes > proposal.totalNoVotes) {
                proposal.status = ProposalStatus.Succeeded;
            } else {
                proposal.status = ProposalStatus.Failed;
            }
        }
        require(proposal.status == ProposalStatus.Succeeded, "Aethelgard: Proposal did not succeed or quorum not met");

        // Execute the parameter change
        if (proposal.paramName == "protocolFeePercent") {
            protocolFeePercent = proposal.newValue;
            emit ProtocolFeeUpdated(proposal.newValue);
        } else if (proposal.paramName == "minFragmentAIScoreForNFT") {
            minFragmentAIScoreForNFT = proposal.newValue;
        } else if (proposal.paramName == "minCuratorStake") {
            minCuratorStake = proposal.newValue;
        } else if (proposal.paramName == "unbondingPeriod") {
            unbondingPeriod = proposal.newValue;
        } else if (proposal.paramName == "proposalQuorumPercent") {
            proposalQuorumPercent = proposal.newValue;
        } else if (proposal.paramName == "proposalVoteDuration") {
            proposalVoteDuration = proposal.newValue;
        } else if (proposal.paramName == "minEvolutionAIScore") {
            minEvolutionAIScore = proposal.newValue;
        } else {
            revert("Aethelgard: Unknown parameter name");
        }

        proposal.status = ProposalStatus.Executed;
        emit GovernanceProposalExecuted(_proposalId);
    }

    function withdrawTreasuryFunds(address _recipient, uint256 _amount) public onlyGovernance nonReentrant {
        require(_recipient != address(0), "Aethelgard: Recipient cannot be zero address");
        require(_amount > 0, "Aethelgard: Amount must be greater than zero");
        require(totalProtocolFees >= _amount, "Aethelgard: Insufficient funds in treasury");

        totalProtocolFees -= _amount;
        require(aethelToken.transfer(_recipient, _amount), "Aethelgard: Failed to withdraw treasury funds");

        emit TreasuryFundsWithdrawn(_recipient, _amount);
    }

    // --- Utility Functions ---

    function getProtocolTreasuryBalance() public view returns (uint256) {
        return totalProtocolFees;
    }

    function getNFTCurrentTokenId() public view returns (uint256) {
        return aethelNFT._getCurrentTokenId();
    }
}
```