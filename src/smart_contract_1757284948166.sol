Here's a Solidity smart contract named `SyntropicNexus` that incorporates advanced concepts like a decentralized AI-augmented creative and curation platform, dynamic reputation (AuraScore), programmable NFTs (NexusFragments), and advanced DAO governance. It aims to be distinct from common open-source patterns by integrating these features into a cohesive system.

---

## SyntropicNexus Smart Contract

### Contract Overview

The `SyntropicNexus` contract establishes a decentralized platform for fostering AI-augmented creativity and community-driven curation. It empowers "Artificers" to submit "Creative Directives" (e.g., prompts for AI art, parameters for generative models, or hashes of AI models), which are then evaluated by a decentralized AI oracle. Successful directives can lead to the minting of "NexusFragments," which are Programmable NFTs (PNFTs) representing AI-generated artifacts or curated collections.

The core mechanisms include:
*   **AI Oracle Integration:** Leverages an off-chain oracle (e.g., Chainlink Functions, custom decentralized network) to evaluate the quality or output of Creative Directives, feeding objective data back on-chain.
*   **Dynamic Reputation (AuraScore):** A non-transferable, internal score that reflects an Artificer's contribution quality. It's dynamic, decaying over time, and crucial for governance power and feature access.
*   **Programmable NFTs (NexusFragments):** ERC721 tokens whose metadata can evolve and update on-chain based on ongoing evaluations, curation activity, or the Artificer's AuraScore. These PNFTs can also be staked for boosted governance power.
*   **Decentralized Curation Market:** Users stake tokens on Creative Directives they believe will be successful. Successful curators earn rewards, incentivizing quality discovery.
*   **Advanced DAO Governance:** A robust governance model where voting power is derived from both an Artificer's AuraScore and their staked NexusFragments, allowing for a multifaceted representation of contribution and ownership.

### Function Summary

**I. Core Infrastructure & Access Control**
1.  `constructor`: Initializes the contract, sets the initial owner, oracle address, and governance parameters.
2.  `updateNexusOracleAddress`: Allows the DAO to update the address of the authorized AI evaluation oracle.
3.  `pauseSystem`: Emergency function to pause critical contract operations, callable by the DAO.
4.  `unpauseSystem`: Unpauses the system, callable by the DAO.

**II. Artificer (Contributor) Functions**
5.  `submitCreativeDirective`: Artificers submit a hash representing their creative input (e.g., AI prompt, model hash). Requires a stake.
6.  `updateCreativeDirective`: Allows an Artificer to modify their directive if it hasn't been evaluated yet.
7.  `retractCreativeDirective`: Allows an Artificer to withdraw their directive and reclaim their stake if it hasn't been evaluated.

**III. Oracle & Evaluation Functions**
8.  `reportDirectiveEvaluation`: Called by the authorized `nexusOracle` to report a quality score for a submitted directive. This triggers `AuraScore` updates and potential `NexusFragment` minting.

**IV. NexusFragment (Programmable NFT) Functions**
9.  `updateFragmentMetadata`: Allows the owner of a `NexusFragment` to trigger an update of its dynamic metadata based on its associated directive's status or the owner's `AuraScore`.
10. `lockFragmentForStaking`: Stakes a `NexusFragment` to gain boosted voting power in the DAO.
11. `unlockFragmentFromStaking`: Unstakes a `NexusFragment`.
12. `tokenURI`: ERC721 standard function to retrieve the current metadata URI for a `NexusFragment`. (Overridden for dynamic metadata)

**V. AuraScore (Reputation System) Functions**
13. `getAuraScore`: Retrieves the `AuraScore` for a specific address.
14. `decayAuraScore`: (Callable via DAO proposal) Initiates a decay of a user's `AuraScore` to reflect recent activity, keeping the score dynamic and relevant.
15. `burnAuraScore`: (Callable via DAO proposal) Allows the DAO to penalize malicious actors by burning a portion of their `AuraScore`.

**VI. Curation & Staking Functions**
16. `stakeForDirectiveCuration`: Users stake tokens to support and curate a Creative Directive they believe is promising.
17. `unstakeFromDirectiveCuration`: Users unstake their tokens from a Creative Directive.
18. `claimCurationRewards`: Allows successful curators (those who staked on highly-rated directives) to claim their share of rewards.
19. `getDirectiveCurationStake`: View function to get the amount an address has staked on a directive.

**VII. Governance (NexusDAO) Functions**
20. `proposeGovernanceAction`: Allows qualified participants to submit new governance proposals.
21. `voteOnProposal`: Participants cast their votes on active proposals, with voting power derived from `AuraScore` and staked `NexusFragments`.
22. `executeProposal`: Executes a passed governance proposal.
23. `setProposalThresholds`: (Callable via DAO proposal) Changes the minimum `AuraScore` and/or staked fragments required to create a proposal.
24. `setVotingPeriod`: (Callable via DAO proposal) Changes the duration for which proposals are open for voting.
25. `withdrawTreasuryFunds`: (Callable via DAO proposal) Allows the DAO to withdraw funds from the contract's treasury for ecosystem development, oracle payments, or grants.

**VIII. Utility / View Functions**
26. `getDirectiveDetails`: Retrieves all details of a specific Creative Directive.
27. `getFragmentOwner`: Returns the owner of a `NexusFragment` (inherited from ERC721).
28. `getTopDirectives`: Returns a paginated list of top-rated directives.
29. `getProposalDetails`: Retrieves details of a specific governance proposal.
30. `getProposalVoteCount`: Returns the current vote counts for a proposal.
31. `getVoterWeight`: Calculates the effective voting weight for a given address.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Interfaces for external contracts (e.g., a hypothetical WETH for curation stakes)
interface IWETH {
    function deposit() external payable;
    function withdraw(uint256 wad) external;
    function transfer(address dst, uint256 wad) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

/**
 * @title SyntropicNexus
 * @dev A decentralized AI-augmented creative and curation platform with dynamic reputation,
 *      programmable NFTs, and advanced DAO governance.
 *
 * This contract enables Artificers to submit 'Creative Directives' (e.g., AI prompts,
 * model hashes). An authorized AI Oracle evaluates these directives. Successful directives
 * contribute to the Artificer's 'AuraScore' (dynamic reputation) and can result in the
 * minting of 'NexusFragments' (Programmable NFTs with evolving metadata).
 *
 * A curation market allows users to stake tokens on promising directives, earning rewards
 * for successful predictions. Governance is managed by a DAO where voting power is a
 * combination of an Artificer's AuraScore and their staked NexusFragments.
 */
contract SyntropicNexus is ERC721, Ownable, Pausable {
    using Strings for uint256;
    using SafeMath for uint256;

    // --- Error Definitions ---
    error Nexus__NotOracle();
    error Nexus__DirectiveNotFound();
    error Nexus__DirectiveAlreadyEvaluated();
    error Nexus__DirectiveAlreadyMinted();
    error Nexus__DirectiveNotEvaluated();
    error Nexus__StakeTooLow();
    error Nexus__InsufficientFunds();
    error Nexus__InvalidProposalId();
    error Nexus__ProposalExpired();
    error Nexus__ProposalNotExpired();
    error Nexus__ProposalAlreadyExecuted();
    error Nexus__AlreadyVoted();
    error Nexus__InsufficientVotingPower();
    error Nexus__CannotUpdateEvaluatedDirective();
    error Nexus__CurationStakeNotFound();
    error Nexus__NoRewardsToClaim();
    error Nexus__FragmentNotStaked();
    error Nexus__FragmentAlreadyStaked();
    error Nexus__ZeroAddress();
    error Nexus__InvalidScore();
    error Nexus__CannotRetractEvaluatedDirective();

    // --- Event Definitions ---
    event DirectiveSubmitted(uint256 indexed directiveId, address indexed submitter, string contentHash, uint256 timestamp);
    event DirectiveEvaluated(uint256 indexed directiveId, address indexed submitter, uint256 score, uint256 newAuraScore);
    event NexusFragmentMinted(uint256 indexed fragmentId, uint256 indexed directiveId, address indexed owner, string initialURI);
    event NexusFragmentMetadataUpdated(uint256 indexed fragmentId, string newURI);
    event AuraScoreUpdated(address indexed user, uint256 newScore);
    event DirectiveCurationStaked(uint256 indexed directiveId, address indexed staker, uint256 amount);
    event DirectiveCurationUnstaked(uint256 indexed directiveId, address indexed staker, uint256 amount);
    event CurationRewardsClaimed(address indexed staker, uint256 amount);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description, bytes callData, address target, uint256 votingPeriodEnd);
    event Voted(uint256 indexed proposalId, address indexed voter, uint256 weight, bool support);
    event ProposalExecuted(uint256 indexed proposalId);
    event NexusOracleUpdated(address indexed oldOracle, address indexed newOracle);

    // --- Struct Definitions ---

    struct CreativeDirective {
        address submitter;
        string contentHash; // IPFS hash or similar for the creative input/parameters
        uint256 submittedAt;
        uint256 evaluationScore; // Score from the oracle (0-100)
        bool isEvaluated;
        bool isMinted; // Whether a NexusFragment has been minted from this directive
        uint256 curationRewardPool; // Accumulated rewards for this directive's curators
        uint256 totalCurationStake; // Total stake on this directive
    }

    struct NexusFragmentData {
        uint256 associatedDirectiveId;
        uint256 lastMetadataUpdate;
        bool isStakedForGovernance; // True if staked, influencing voting power
    }

    enum ProposalState { Pending, Active, Succeeded, Failed, Executed }

    struct Proposal {
        address proposer;
        string description;
        bytes callData; // The function call to execute if proposal passes
        address target; // The contract to call if proposal passes (SyntropicNexus itself for internal changes)
        uint256 startBlock;
        uint256 endBlock;
        uint256 yesVotes;
        uint256 noVotes;
        mapping(address => bool) hasVoted; // Tracks who has voted
        ProposalState state;
        bool executed;
    }

    // --- State Variables ---

    address public nexusOracle; // Address authorized to report AI evaluations
    address public immutable curationToken; // Address of the token used for curation staking (e.g., WETH)

    uint256 private _directiveIdCounter;
    mapping(uint256 => CreativeDirective) public directives;

    uint256 private _fragmentIdCounter;
    mapping(uint252 => NexusFragmentData) public nexusFragmentsData; // Using uint252 to save a tiny bit of gas, as fragmentId will likely not exceed 2^252-1

    mapping(address => uint256) public auraScores; // Artificer's reputation score (non-transferable)

    mapping(uint256 => mapping(address => uint256)) public curationStakes; // directiveId => stakerAddress => amount
    uint256 public constant DIRECTIVE_SUBMISSION_STAKE = 0.01 ether; // Fee/stake for submitting a directive
    uint256 public constant MIN_CURATION_STAKE = 0.001 ether; // Minimum stake for curation
    uint256 public constant CURATION_REWARD_PERCENTAGE = 10; // 10% of submission stake goes to curation pool

    uint256 private _proposalIdCounter;
    mapping(uint256 => Proposal) public proposals;
    uint256 public minAuraScoreForProposal; // Min AuraScore to create a proposal
    uint256 public minStakedFragmentsForProposal; // Min staked NexusFragments to create a proposal
    uint256 public votingPeriodBlocks; // Duration of voting in blocks
    uint256 public proposalQuorumPercentage; // Percentage of total voting power required for a proposal to pass (e.g., 20% of max possible active power)
    uint256 public fragmentVotingBoost; // Multiplier for staked fragments' voting power

    uint256 public constant MIN_EVALUATION_SCORE_FOR_MINT = 75; // Min score required to mint a NexusFragment

    // --- Modifiers ---
    modifier onlyNexusOracle() {
        if (msg.sender != nexusOracle) revert Nexus__NotOracle();
        _;
    }

    // --- Constructor ---
    constructor(
        address initialOracle,
        address _curationToken,
        uint256 _minAuraScoreForProposal,
        uint256 _minStakedFragmentsForProposal,
        uint256 _votingPeriodBlocks,
        uint256 _proposalQuorumPercentage,
        uint256 _fragmentVotingBoost
    ) ERC721("NexusFragment", "NXF") Ownable(msg.sender) Pausable() {
        if (initialOracle == address(0) || _curationToken == address(0)) revert Nexus__ZeroAddress();
        
        nexusOracle = initialOracle;
        curationToken = _curationToken;

        minAuraScoreForProposal = _minAuraScoreForProposal;
        minStakedFragmentsForProposal = _minStakedFragmentsForProposal;
        votingPeriodBlocks = _votingPeriodBlocks;
        proposalQuorumPercentage = _proposalQuorumPercentage;
        fragmentVotingBoost = _fragmentVotingBoost;

        _directiveIdCounter = 0;
        _fragmentIdCounter = 0;
        _proposalIdCounter = 0;
    }

    // --- I. Core Infrastructure & Access Control ---

    /**
     * @dev Allows the DAO (via proposal) to update the address of the authorized AI evaluation oracle.
     * @param _newOracle The address of the new oracle.
     */
    function updateNexusOracleAddress(address _newOracle) external payable onlyAuthoredByDao {
        if (_newOracle == address(0)) revert Nexus__ZeroAddress();
        emit NexusOracleUpdated(nexusOracle, _newOracle);
        nexusOracle = _newOracle;
    }

    /**
     * @dev Pauses the system in case of emergencies. Callable by the DAO.
     */
    function pauseSystem() external payable onlyAuthoredByDao {
        _pause();
    }

    /**
     * @dev Unpauses the system. Callable by the DAO.
     */
    function unpauseSystem() external payable onlyAuthoredByDao {
        _unpause();
    }

    // --- II. Artificer (Contributor) Functions ---

    /**
     * @dev Allows an Artificer to submit a Creative Directive.
     * @param _contentHash IPFS hash or similar identifier for the creative input.
     */
    function submitCreativeDirective(string calldata _contentHash) external payable whenNotPaused {
        if (msg.value < DIRECTIVE_SUBMISSION_STAKE) revert Nexus__InsufficientFunds();

        uint256 directiveId = ++_directiveIdCounter;
        directives[directiveId] = CreativeDirective({
            submitter: msg.sender,
            contentHash: _contentHash,
            submittedAt: block.timestamp,
            evaluationScore: 0,
            isEvaluated: false,
            isMinted: false,
            curationRewardPool: 0,
            totalCurationStake: 0
        });

        // Add a portion of the submission stake to the general curation reward pool
        // This ETH can later be converted to curationToken if needed, or directly used if curationToken is ETH/WETH
        // The rest goes to the contract treasury
        uint256 curationPoolContribution = msg.value.mul(CURATION_REWARD_PERCENTAGE).div(100);
        directives[directiveId].curationRewardPool = curationPoolContribution;
        
        emit DirectiveSubmitted(directiveId, msg.sender, _contentHash, block.timestamp);
    }

    /**
     * @dev Allows an Artificer to update their directive if it hasn't been evaluated yet.
     * @param _directiveId The ID of the directive to update.
     * @param _newContentHash The new IPFS hash or content identifier.
     */
    function updateCreativeDirective(uint256 _directiveId, string calldata _newContentHash) external whenNotPaused {
        CreativeDirective storage directive = directives[_directiveId];
        if (directive.submitter == address(0)) revert Nexus__DirectiveNotFound();
        if (directive.submitter != msg.sender) revert OwnableUnauthorizedAccount(msg.sender); // Only submitter can update
        if (directive.isEvaluated) revert Nexus__CannotUpdateEvaluatedDirective();

        directive.contentHash = _newContentHash;
        // No event for update, as it's a minor change before evaluation.
    }

    /**
     * @dev Allows an Artificer to retract their directive if it hasn't been evaluated, refunding their stake.
     * @param _directiveId The ID of the directive to retract.
     */
    function retractCreativeDirective(uint256 _directiveId) external whenNotPaused {
        CreativeDirective storage directive = directives[_directiveId];
        if (directive.submitter == address(0)) revert Nexus__DirectiveNotFound();
        if (directive.submitter != msg.sender) revert OwnableUnauthorizedAccount(msg.sender);
        if (directive.isEvaluated) revert Nexus__CannotRetractEvaluatedDirective();

        // Refund the submission stake (excluding curation pool contribution)
        // Note: The curation pool portion is lost if not claimed by DAO
        uint256 refundAmount = DIRECTIVE_SUBMISSION_STAKE - directive.curationRewardPool;
        (bool success, ) = payable(msg.sender).call{value: refundAmount}("");
        require(success, "Refund failed");

        // Clear the directive data
        delete directives[_directiveId];
        // Also clear any curation stakes
        // This is important to free up storage and avoid misleading data
        delete curationStakes[_directiveId]; // This deletes the inner mapping for this directive

        emit DirectiveSubmitted(_directiveId, msg.sender, "Retracted", block.timestamp); // Reusing event with "Retracted" in contentHash
    }

    // --- III. Oracle & Evaluation Functions ---

    /**
     * @dev Called by the authorized Nexus Oracle to report an evaluation score for a directive.
     *      Updates Artificer's AuraScore and potentially mints a NexusFragment.
     * @param _directiveId The ID of the directive being evaluated.
     * @param _score The evaluation score (0-100).
     */
    function reportDirectiveEvaluation(uint256 _directiveId, uint256 _score) external onlyNexusOracle whenNotPaused {
        CreativeDirective storage directive = directives[_directiveId];
        if (directive.submitter == address(0)) revert Nexus__DirectiveNotFound();
        if (directive.isEvaluated) revert Nexus__DirectiveAlreadyEvaluated();
        if (_score > 100) revert Nexus__InvalidScore();

        directive.evaluationScore = _score;
        directive.isEvaluated = true;

        // Update Artificer's AuraScore based on evaluation
        _updateAuraScore(directive.submitter, _score);

        // If score is high enough, mint a NexusFragment
        if (_score >= MIN_EVALUATION_SCORE_FOR_MINT) {
            _mintNexusFragment(directive.submitter, _directiveId);
            directive.isMinted = true;
        }

        emit DirectiveEvaluated(_directiveId, directive.submitter, _score, auraScores[directive.submitter]);
    }

    // --- IV. NexusFragment (Programmable NFT) Functions ---

    /**
     * @dev Internal function to mint a new NexusFragment.
     * @param _to The recipient of the NFT.
     * @param _associatedDirectiveId The ID of the directive this NFT represents.
     */
    function _mintNexusFragment(address _to, uint256 _associatedDirectiveId) internal {
        uint256 newFragmentId = ++_fragmentIdCounter;
        _safeMint(_to, newFragmentId);

        nexusFragmentsData[uint252(newFragmentId)] = NexusFragmentData({
            associatedDirectiveId: _associatedDirectiveId,
            lastMetadataUpdate: block.timestamp,
            isStakedForGovernance: false
        });

        // Initial metadata URI is dynamically generated
        string memory initialURI = _generateFragmentMetadataURI(newFragmentId, _associatedDirectiveId);
        _setTokenURI(newFragmentId, initialURI); // Update tokenURI directly
        emit NexusFragmentMinted(newFragmentId, _associatedDirectiveId, _to, initialURI);
    }

    /**
     * @dev Allows the owner of a NexusFragment to trigger an update of its dynamic metadata.
     *      Metadata could reflect current AuraScore, associated directive's status, etc.
     * @param _fragmentId The ID of the NexusFragment to update.
     */
    function updateFragmentMetadata(uint256 _fragmentId) external whenNotPaused {
        if (_ownerOf(_fragmentId) != msg.sender) revert OwnableUnauthorizedAccount(msg.sender);

        NexusFragmentData storage fragmentData = nexusFragmentsData[uint252(_fragmentId)];
        if (fragmentData.associatedDirectiveId == 0) revert Nexus__DirectiveNotFound(); // Fragment data not found or invalid

        string memory newURI = _generateFragmentMetadataURI(_fragmentId, fragmentData.associatedDirectiveId);
        _setTokenURI(_fragmentId, newURI);
        fragmentData.lastMetadataUpdate = block.timestamp;

        emit NexusFragmentMetadataUpdated(_fragmentId, newURI);
    }

    /**
     * @dev Stakes a NexusFragment for boosted voting power in the DAO.
     * @param _fragmentId The ID of the NexusFragment to stake.
     */
    function lockFragmentForStaking(uint256 _fragmentId) external whenNotPaused {
        if (_ownerOf(_fragmentId) != msg.sender) revert OwnableUnauthorizedAccount(msg.sender);
        NexusFragmentData storage fragmentData = nexusFragmentsData[uint252(_fragmentId)];
        if (fragmentData.isStakedForGovernance) revert Nexus__FragmentAlreadyStaked();

        fragmentData.isStakedForGovernance = true;
        emit NexusFragmentMetadataUpdated(_fragmentId, _generateFragmentMetadataURI(_fragmentId, fragmentData.associatedDirectiveId)); // Metadata update for staked status
    }

    /**
     * @dev Unstakes a NexusFragment, revoking its voting power boost.
     * @param _fragmentId The ID of the NexusFragment to unstake.
     */
    function unlockFragmentFromStaking(uint256 _fragmentId) external whenNotPaused {
        if (_ownerOf(_fragmentId) != msg.sender) revert OwnableUnauthorizedAccount(msg.sender);
        NexusFragmentData storage fragmentData = nexusFragmentsData[uint252(_fragmentId)];
        if (!fragmentData.isStakedForGovernance) revert Nexus__FragmentNotStaked();

        fragmentData.isStakedForGovernance = false;
        emit NexusFragmentMetadataUpdated(_fragmentId, _generateFragmentMetadataURI(_fragmentId, fragmentData.associatedDirectiveId)); // Metadata update for unstaked status
    }

    /**
     * @dev Overridden ERC721 tokenURI to provide dynamic metadata.
     *      In a real-world scenario, this would point to an IPFS JSON file
     *      generated off-chain or by a dedicated API, incorporating on-chain data.
     */
    function tokenURI(uint256 _fragmentId) public view override returns (string memory) {
        NexusFragmentData storage fragmentData = nexusFragmentsData[uint252(_fragmentId)];
        if (fragmentData.associatedDirectiveId == 0) {
            return super.tokenURI(_fragmentId); // Fallback for non-NexusFragment ERC721 tokens
        }
        return _generateFragmentMetadataURI(_fragmentId, fragmentData.associatedDirectiveId);
    }

    /**
     * @dev Generates a placeholder metadata URI for a NexusFragment.
     *      In a full implementation, this would point to a JSON file on IPFS
     *      which contains the image, description, and dynamic attributes.
     */
    function _generateFragmentMetadataURI(uint256 _fragmentId, uint256 _directiveId) internal view returns (string memory) {
        CreativeDirective storage directive = directives[_directiveId];
        NexusFragmentData storage fragmentData = nexusFragmentsData[uint252(_fragmentId)];

        string memory uri = string(abi.encodePacked(
            "ipfs://", // Placeholder IPFS gateway/hash
            "nexus_fragment_metadata/",
            _fragmentId.toString(),
            "?",
            "directiveId=", _directiveId.toString(),
            "&owner=", Ownable(_ownerOf(_fragmentId)).owner().toString(), // Using Ownable().owner() for example
            "&score=", directive.evaluationScore.toString(),
            "&aura=", auraScores[_ownerOf(_fragmentId)].toString(),
            "&staked=", fragmentData.isStakedForGovernance ? "true" : "false",
            "&lastUpdate=", fragmentData.lastMetadataUpdate.toString()
            // In reality, this would be a single IPFS hash to a JSON file.
            // This is just a conceptual dynamic URI demonstrating the changing data.
        ));
        return uri;
    }

    // --- V. AuraScore (Reputation System) Functions ---

    /**
     * @dev Internal function to update an Artificer's AuraScore.
     * @param _user The address of the Artificer.
     * @param _scoreChange The amount to change the score by. Can be positive or negative.
     */
    function _updateAuraScore(address _user, int256 _scoreChange) internal {
        uint256 currentScore = auraScores[_user];
        if (_scoreChange > 0) {
            auraScores[_user] = currentScore.add(uint256(_scoreChange));
        } else {
            uint256 absScoreChange = uint256(-_scoreChange);
            if (currentScore <= absScoreChange) {
                auraScores[_user] = 0;
            } else {
                auraScores[_user] = currentScore.sub(absScoreChange);
            }
        }
        emit AuraScoreUpdated(_user, auraScores[_user]);
    }

    /**
     * @dev Returns the current AuraScore for a specific address.
     * @param _user The address to query.
     * @return The AuraScore of the user.
     */
    function getAuraScore(address _user) public view returns (uint256) {
        return auraScores[_user];
    }

    /**
     * @dev Callable via DAO proposal to decay a user's AuraScore.
     *      This keeps the reputation system dynamic and encourages continued participation.
     * @param _user The address whose AuraScore will decay.
     * @param _decayPercentage The percentage (0-100) by which to decay the score.
     */
    function decayAuraScore(address _user, uint256 _decayPercentage) external payable onlyAuthoredByDao {
        if (_user == address(0)) revert Nexus__ZeroAddress();
        if (_decayPercentage > 100) _decayPercentage = 100; // Cap at 100%
        
        uint256 currentScore = auraScores[_user];
        uint256 decayedAmount = currentScore.mul(_decayPercentage).div(100);
        _updateAuraScore(_user, -int256(decayedAmount));
    }

    /**
     * @dev Callable via DAO proposal to burn a user's AuraScore, e.g., for malicious behavior.
     * @param _user The address whose AuraScore will be burned.
     * @param _burnAmount The amount of AuraScore to burn.
     */
    function burnAuraScore(address _user, uint256 _burnAmount) external payable onlyAuthoredByDao {
        if (_user == address(0)) revert Nexus__ZeroAddress();
        _updateAuraScore(_user, -int256(_burnAmount));
    }

    // --- VI. Curation & Staking Functions ---

    /**
     * @dev Allows users to stake tokens on a Creative Directive, curating it.
     *      Curators of highly-rated directives earn rewards.
     * @param _directiveId The ID of the directive to stake on.
     * @param _amount The amount of `curationToken` to stake.
     */
    function stakeForDirectiveCuration(uint256 _directiveId, uint256 _amount) external whenNotPaused {
        CreativeDirective storage directive = directives[_directiveId];
        if (directive.submitter == address(0)) revert Nexus__DirectiveNotFound();
        if (directive.isEvaluated) revert Nexus__DirectiveAlreadyEvaluated();
        if (_amount < MIN_CURATION_STAKE) revert Nexus__StakeTooLow();

        // Transfer curation tokens to this contract
        IWETH(curationToken).transferFrom(msg.sender, address(this), _amount);

        curationStakes[_directiveId][msg.sender] = curationStakes[_directiveId][msg.sender].add(_amount);
        directive.totalCurationStake = directive.totalCurationStake.add(_amount);

        emit DirectiveCurationStaked(_directiveId, msg.sender, _amount);
    }

    /**
     * @dev Allows users to unstake their tokens from a Creative Directive.
     * @param _directiveId The ID of the directive to unstake from.
     * @param _amount The amount to unstake.
     */
    function unstakeFromDirectiveCuration(uint256 _directiveId, uint256 _amount) external whenNotPaused {
        CreativeDirective storage directive = directives[_directiveId];
        if (directive.submitter == address(0)) revert Nexus__DirectiveNotFound();
        if (directive.isEvaluated) revert Nexus__DirectiveAlreadyEvaluated(); // Cannot unstake after evaluation (must claim rewards/loss)

        uint256 currentStake = curationStakes[_directiveId][msg.sender];
        if (currentStake < _amount) revert Nexus__InsufficientFunds();

        curationStakes[_directiveId][msg.sender] = currentStake.sub(_amount);
        directive.totalCurationStake = directive.totalCurationStake.sub(_amount);

        // Transfer curation tokens back to the staker
        IWETH(curationToken).transfer(msg.sender, _amount);

        emit DirectiveCurationUnstaked(_directiveId, msg.sender, _amount);
    }

    /**
     * @dev Allows stakers on evaluated directives to claim their rewards or incur loss.
     *      Rewards are proportional to their stake on successful directives.
     * @param _directiveId The ID of the directive to claim rewards for.
     */
    function claimCurationRewards(uint256 _directiveId) external whenNotPaused {
        CreativeDirective storage directive = directives[_directiveId];
        if (directive.submitter == address(0)) revert Nexus__DirectiveNotFound();
        if (!directive.isEvaluated) revert Nexus__DirectiveNotEvaluated();

        uint256 stakerStake = curationStakes[_directiveId][msg.sender];
        if (stakerStake == 0) revert Nexus__CurationStakeNotFound();

        // Calculate reward/loss
        uint256 payoutAmount = 0;
        if (directive.evaluationScore >= MIN_EVALUATION_SCORE_FOR_MINT) {
            // Successful curation: Payout from the directive's reward pool proportional to stake
            if (directive.totalCurationStake > 0) {
                 payoutAmount = directive.curationRewardPool.mul(stakerStake).div(directive.totalCurationStake).add(stakerStake); // Stake + proportional reward
            } else {
                payoutAmount = stakerStake; // Should not happen if totalCurationStake > 0
            }
        } else {
            // Unsuccessful curation: Staker loses their initial stake, or a portion if we want partial refunds.
            // For simplicity, here it implies the stake is lost.
            // Or, if payoutAmount is 0, the stake remains in the contract's custody (treasury).
            // For this contract, losing the stake means it effectively stays in the contract.
            payoutAmount = 0; // Staker gets nothing back if directive fails to mint
        }

        delete curationStakes[_directiveId][msg.sender]; // Clear stake after claiming/resolving

        if (payoutAmount > 0) {
            IWETH(curationToken).transfer(msg.sender, payoutAmount);
            emit CurationRewardsClaimed(msg.sender, payoutAmount);
        } else {
            revert Nexus__NoRewardsToClaim(); // Or, just don't transfer and consider the stake lost
        }
    }

    // --- VII. Governance (NexusDAO) Functions ---

    /**
     * @dev Modifier to ensure only DAO-approved proposals can call restricted functions.
     *      This prevents direct calls to sensitive functions like `updateNexusOracleAddress`.
     */
    modifier onlyAuthoredByDao() {
        // In a fully decentralized DAO, `msg.sender` would be the governance executor contract.
        // For simplicity in this example, it's assumed that this modifier is checked within `executeProposal`.
        // If this function is called directly, it will revert because `_proposalId` would not be set.
        // A more robust DAO setup would involve an `ERC20Votes` token or similar, and a timelock.
        // For this example, we assume `executeProposal` is the only path to these functions.
        require(msg.sender == address(this), "Only contract itself via proposal can call this function");
        _;
    }

    /**
     * @dev Allows qualified participants to submit new governance proposals.
     * @param _description A description of the proposal.
     * @param _callData The encoded function call (target, function signature, args).
     * @param _target The address of the contract to call (e.g., this contract for internal changes).
     */
    function proposeGovernanceAction(string calldata _description, bytes calldata _callData, address _target) external whenNotPaused returns (uint256) {
        if (_target == address(0)) revert Nexus__ZeroAddress();
        
        uint256 voterWeight = getVoterWeight(msg.sender);
        if (voterWeight < minAuraScoreForProposal + (getNexusFragmentsStakedCount(msg.sender) * fragmentVotingBoost)) {
             revert Nexus__InsufficientVotingPower();
        }

        uint256 proposalId = ++_proposalIdCounter;
        proposals[proposalId] = Proposal({
            proposer: msg.sender,
            description: _description,
            callData: _callData,
            target: _target,
            startBlock: block.number,
            endBlock: block.number.add(votingPeriodBlocks),
            yesVotes: 0,
            noVotes: 0,
            state: ProposalState.Active,
            executed: false
        });

        emit ProposalCreated(proposalId, msg.sender, _description, _callData, _target, block.number.add(votingPeriodBlocks));
        return proposalId;
    }

    /**
     * @dev Participants cast their votes on active proposals.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'yes', false for 'no'.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) external whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.proposer == address(0)) revert Nexus__InvalidProposalId();
        if (proposal.state != ProposalState.Active) revert Nexus__ProposalExpired();
        if (proposal.endBlock < block.number) revert Nexus__ProposalExpired();
        if (proposal.hasVoted[msg.sender]) revert Nexus__AlreadyVoted();

        uint256 voterWeight = getVoterWeight(msg.sender);
        if (voterWeight == 0) revert Nexus__InsufficientVotingPower();

        if (_support) {
            proposal.yesVotes = proposal.yesVotes.add(voterWeight);
        } else {
            proposal.noVotes = proposal.noVotes.add(voterWeight);
        }
        proposal.hasVoted[msg.sender] = true;

        emit Voted(_proposalId, msg.sender, voterWeight, _support);
    }

    /**
     * @dev Executes a passed governance proposal.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) external whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.proposer == address(0)) revert Nexus__InvalidProposalId();
        if (proposal.executed) revert Nexus__ProposalAlreadyExecuted();
        if (block.number <= proposal.endBlock) revert Nexus__ProposalNotExpired();

        // Check if proposal passed
        uint256 totalVotes = proposal.yesVotes.add(proposal.noVotes);
        uint256 requiredQuorum = _getTotalActiveVotingPower().mul(proposalQuorumPercentage).div(100);

        if (totalVotes < requiredQuorum || proposal.yesVotes <= proposal.noVotes) {
            proposal.state = ProposalState.Failed;
            return;
        }

        // Execute the proposal
        (bool success, ) = proposal.target.call(proposal.callData);
        if (!success) {
            proposal.state = ProposalState.Failed;
            revert("Proposal execution failed"); // Revert with more details if possible
        }

        proposal.state = ProposalState.Executed;
        proposal.executed = true;
        emit ProposalExecuted(_proposalId);
    }

    /**
     * @dev Calculates total active voting power from all Artificers and staked fragments.
     *      This is a simplification; a real DAO might snapshot power or use delegates.
     * @return totalPower The sum of all active AuraScores and staked fragment boosts.
     */
    function _getTotalActiveVotingPower() internal view returns (uint256 totalPower) {
        // This is a highly gas-intensive operation if iterated over all users/fragments.
        // For a production system, this would involve a snapshot mechanism or a more
        // sophisticated voting power calculation stored/updated incrementally.
        // For this example, it's illustrative.
        // Assuming a maximum reasonable number of Artificers/Fragments.
        // In reality, you'd likely sum `auraScores` of active users and
        // iterate through minted fragments to find staked ones.
        // For this example, we'll return a placeholder or sum up from known data.
        return _directiveIdCounter.mul(100).add(_fragmentIdCounter.mul(fragmentVotingBoost)); // Placeholder: rough estimate
    }


    /**
     * @dev Callable via DAO proposal to set the minimum AuraScore and/or staked fragments required to create a proposal.
     * @param _newMinAuraScore The new minimum AuraScore.
     * @param _newMinStakedFragments The new minimum number of staked NexusFragments.
     */
    function setProposalThresholds(uint256 _newMinAuraScore, uint256 _newMinStakedFragments) external payable onlyAuthoredByDao {
        minAuraScoreForProposal = _newMinAuraScore;
        minStakedFragmentsForProposal = _newMinStakedFragments;
    }

    /**
     * @dev Callable via DAO proposal to set the duration for which proposals are open for voting (in blocks).
     * @param _newVotingPeriodBlocks The new voting period in blocks.
     */
    function setVotingPeriod(uint256 _newVotingPeriodBlocks) external payable onlyAuthoredByDao {
        votingPeriodBlocks = _newVotingPeriodBlocks;
    }

    /**
     * @dev Callable via DAO proposal to withdraw funds from the contract's treasury.
     *      Funds could be used for oracle payments, community grants, ecosystem development, etc.
     * @param _amount The amount of ETH to withdraw.
     * @param _to The recipient address.
     */
    function withdrawTreasuryFunds(uint256 _amount, address _to) external payable onlyAuthoredByDao {
        if (_to == address(0)) revert Nexus__ZeroAddress();
        if (address(this).balance < _amount) revert Nexus__InsufficientFunds();

        (bool success, ) = payable(_to).call{value: _amount}("");
        require(success, "Withdrawal failed");
    }

    // --- VIII. Utility / View Functions ---

    /**
     * @dev Returns details of a specific Creative Directive.
     * @param _directiveId The ID of the directive.
     * @return A tuple containing all directive fields.
     */
    function getDirectiveDetails(uint256 _directiveId) public view returns (
        address submitter,
        string memory contentHash,
        uint256 submittedAt,
        uint256 evaluationScore,
        bool isEvaluated,
        bool isMinted,
        uint256 curationRewardPool,
        uint256 totalCurationStake
    ) {
        CreativeDirective storage directive = directives[_directiveId];
        if (directive.submitter == address(0)) revert Nexus__DirectiveNotFound();
        return (
            directive.submitter,
            directive.contentHash,
            directive.submittedAt,
            directive.evaluationScore,
            directive.isEvaluated,
            directive.isMinted,
            directive.curationRewardPool,
            directive.totalCurationStake
        );
    }

    /**
     * @dev Returns the owner of a NexusFragment (inherited from ERC721).
     * @param _fragmentId The ID of the NexusFragment.
     * @return The owner's address.
     */
    function getFragmentOwner(uint256 _fragmentId) public view returns (address) {
        return ownerOf(_fragmentId);
    }

    /**
     * @dev Returns a paginated list of top-rated directives.
     *      (Simplified: returns all directives for demonstration, actual pagination logic needed for production)
     * @param _startIndex The starting index for the list.
     * @param _count The number of directives to return.
     * @return An array of directive IDs.
     */
    function getTopDirectives(uint256 _startIndex, uint256 _count) public view returns (uint252[] memory) {
        // In a real scenario, this would involve a complex sorting mechanism (e.g., by evaluationScore,
        // recent activity, or curation stake) and potentially a data structure optimized for this.
        // For demonstration, we'll return a simple list of available directives.
        uint256 total = _directiveIdCounter;
        uint256 actualCount = _count;
        if (_startIndex + _count > total) {
            actualCount = total.sub(_startIndex);
        }
        if (_startIndex >= total || actualCount == 0) {
            return new uint252[](0);
        }

        uint252[] memory result = new uint252[](actualCount);
        for (uint256 i = 0; i < actualCount; i++) {
            result[i] = uint252(_startIndex.add(i).add(1)); // Adjust for 1-based indexing
        }
        return result;
    }

    /**
     * @dev Retrieves details of a specific governance proposal.
     * @param _proposalId The ID of the proposal.
     * @return A tuple containing proposal details.
     */
    function getProposalDetails(uint256 _proposalId) public view returns (
        address proposer,
        string memory description,
        address target,
        uint256 startBlock,
        uint256 endBlock,
        ProposalState state,
        bool executed
    ) {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.proposer == address(0)) revert Nexus__InvalidProposalId();
        return (
            proposal.proposer,
            proposal.description,
            proposal.target,
            proposal.startBlock,
            proposal.endBlock,
            proposal.state,
            proposal.executed
        );
    }

    /**
     * @dev Returns the current vote counts for a proposal.
     * @param _proposalId The ID of the proposal.
     * @return yesVotes The total 'yes' votes.
     * @return noVotes The total 'no' votes.
     */
    function getProposalVoteCount(uint256 _proposalId) public view returns (uint256 yesVotes, uint256 noVotes) {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.proposer == address(0)) revert Nexus__InvalidProposalId();
        return (proposal.yesVotes, proposal.noVotes);
    }

    /**
     * @dev Returns the amount an address has staked on a particular directive.
     * @param _directiveId The ID of the directive.
     * @param _staker The address of the staker.
     * @return The amount staked.
     */
    function getDirectiveCurationStake(uint256 _directiveId, address _staker) public view returns (uint256) {
        return curationStakes[_directiveId][_staker];
    }

    /**
     * @dev Calculates the effective voting weight for a given address.
     *      Based on AuraScore and staked NexusFragments.
     * @param _voter The address whose voting weight is to be calculated.
     * @return The total voting weight.
     */
    function getVoterWeight(address _voter) public view returns (uint256) {
        uint256 aura = auraScores[_voter];
        uint256 stakedFragments = getNexusFragmentsStakedCount(_voter);
        return aura.add(stakedFragments.mul(fragmentVotingBoost));
    }

    /**
     * @dev Helper function to count the number of NexusFragments staked by an address.
     *      (This iterates through all fragments for simplicity; for large scale, optimize or track with a mapping).
     * @param _owner The address to check.
     * @return The count of staked fragments.
     */
    function getNexusFragmentsStakedCount(address _owner) public view returns (uint256) {
        uint256 count = 0;
        // This is highly inefficient for many NFTs. A real-world solution would track this with a mapping
        // e.g., mapping(address => uint256) public stakedFragmentCounts; updated on lock/unlock.
        for (uint256 i = 1; i <= _fragmentIdCounter; i++) {
            if (_ownerOf(i) == _owner && nexusFragmentsData[uint252(i)].isStakedForGovernance) {
                count++;
            }
        }
        return count;
    }

    // --- Fallback & Receive ---
    receive() external payable {
        // Allow direct ETH deposits to the contract treasury
    }

    fallback() external payable {
        // Allow direct ETH deposits, potentially for submission stakes or treasury.
    }
}
```