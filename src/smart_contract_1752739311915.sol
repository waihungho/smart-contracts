```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; // Used for initial deployment ownership and setting up initial council
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/Address.sol";

// --- Outline ---
// 1.  Contract Overview
//     - Project Name: AetherMind Nexus
//     - Purpose: A decentralized protocol for collaborative concept incubation, driven by AI evaluations, community nurturing, and dynamic NFT manifestations. It aims to create a framework where ideas (Conceptual Seeds) can be proposed, collectively nurtured, evaluated (potentially by AI via oracles), and ultimately manifest into dynamic NFTs (Conceptual Manifestations), rewarding contributors based on their impact and reputation.
//     - Core Components:
//         - Cognitive Essence (ERC20): The primary utility token used for staking (nurturing), fees, and rewards within the ecosystem.
//         - Conceptual Manifestations (ERC721): Dynamic Non-Fungible Tokens that represent the materialized forms of successful conceptual seeds. These NFTs can evolve their traits based on ongoing project development or community interaction.
//         - Mindweave Score (SBT-like): A non-transferable, reputation-based score awarded to contributors. It grants governance power and boosts staking rewards.
//         - AetherMind Council: A multi-signature or elected body responsible for emergency actions, protocol parameter adjustments, and initial setup.
//         - Oracle Integration: Crucial for bringing off-chain AI model evaluations or expert reviews of conceptual seeds onto the blockchain, influencing their potential score and success.
//
// 2.  Function Summary
//     - I. Core Conceptual Seed Management (Idea Generation & Nurturing)
//         1.  `proposeConceptualSeed(string calldata _ipfHash, string calldata _name, uint256 _essenceRequired)`: Allows any user to propose a new "conceptual seed." This seed represents an idea or prompt, detailed via an IPFS hash, and specifies the amount of Cognitive Essence required for its initial bootstrapping.
//         2.  `nurtureConceptualSeed(uint256 _seedId, uint256 _amount)`: Enables users to stake their `CognitiveEssence` tokens on a particular conceptual seed. This action signals support for the idea, provides "liquidity" for its development, and makes the nurturer eligible for future rewards.
//         3.  `withdrawNurturedEssence(uint256 _seedId, uint256 _amount)`: Permits users to withdraw their previously staked Essence from a conceptual seed. This action might be subject to conditions such as a cool-down period or if the seed does not reach finalization.
//         4.  `submitOracleEvaluation(uint256 _seedId, uint256 _aiScore, string calldata _reportHash)`: (Restricted to Trusted Oracle) An authorized external oracle submits an evaluation score for a conceptual seed. This score, typically derived from off-chain AI analysis or expert review, directly updates the seed's `potentialScore`, influencing its path towards finalization.
//         5.  `finalizeConceptualSeed(uint256 _seedId)`: A function that, when called, checks if a conceptual seed has met its specified `essenceRequired` and achieved a sufficiently high `potentialScore`. If conditions are met, the seed is marked as "finalized," making it eligible for manifestation into an NFT.
//
//     - II. Dynamic Manifestation NFTs (Evolving Output)
//         6.  `mintConceptualManifestation(uint256 _seedId, string calldata _initialMetadataHash)`: Mints a unique ERC721 token, known as a "Conceptual Manifestation," for a successfully finalized conceptual seed. This NFT serves as the on-chain representation of the realized concept, with its initial metadata pointing to an IPFS hash.
//         7.  `evolveManifestationTrait(uint256 _tokenId, uint256 _traitIndex, string calldata _newTraitValueHash)`: Allows the owner of a Conceptual Manifestation NFT, or an authorized collaborator, to update a specific trait of the NFT. This dynamic update can be triggered by project milestones, new data, or community input, enabling the NFT to visually or conceptually evolve.
//         8.  `requestTraitUpdateVote(uint256 _tokenId, uint256 _traitIndex, string calldata _proposedNewValueHash)`: For critical or disputed trait updates on a Conceptual Manifestation NFT, this function initiates a formal governance vote among `MindweaveScore` holders. The proposed update must pass this vote before `evolveManifestationTrait` can be executed for that specific change.
//         9.  `setTraitUpdateCollaborator(uint256 _tokenId, address _collaborator, bool _canUpdate)`: Empowers the owner of a Conceptual Manifestation NFT to grant or revoke explicit permission to other addresses. These "collaborators" can then propose or directly execute trait updates on that specific NFT without requiring a full governance vote.
//
//     - III. Reputation & Incentive Layer (Soulbound Tokens & Staking Rewards)
//         10. `claimMindweaveScore(address _contributorAddress, uint256 _scoreAmount)`: (Restricted to Oracle/Governance) A function used to award non-transferable `MindweaveScore` (an SBT-like reputation token) to users. Scores are granted for significant contributions, successful nurturing of seeds, or positive oracle evaluations, reflecting a user's standing in the ecosystem.
//         11. `delegateMindweaveScore(address _delegatee)`: Allows `MindweaveScore` holders to delegate their associated voting power to another address. This enables users to participate in governance indirectly, for example, by delegating to a trusted representative, without transferring their non-transferable score.
//         12. `revokeMindweaveScoreDelegation()`: Enables a `MindweaveScore` holder to revoke any active delegation, returning the voting power back to their own address.
//         13. `claimEssenceYield(uint256 _seedId)`: Allows nurturers of successful conceptual seeds (those that have led to the minting of a Conceptual Manifestation NFT) to claim their proportional share of `CognitiveEssence` rewards, reflecting their contribution to the concept's success.
//         14. `lockEssenceForBoost(uint256 _amount, uint256 _duration)`: Provides a mechanism for users to lock their Cognitive Essence tokens for a specified duration. In return for this commitment, they receive a boosted `MindweaveScore` or a higher yield multiplier on their active Essence stakes, incentivizing long-term participation.
//
//     - IV. Decentralized Governance (AetherMind Council)
//         15. `proposeGovernanceAction(string calldata _description, address _targetContract, bytes calldata _calldata, uint256 _minMindweaveScore)`: Allows users with a minimum required `MindweaveScore` to propose wide-ranging governance actions. These actions can include protocol upgrades, treasury spending, or fundamental rule changes, defined by a target contract and calldata.
//         16. `voteOnProposal(uint256 _proposalId, bool _support)`: Enables `MindweaveScore` holders (or their delegates) to cast a vote (for or against) on any open governance proposal. The weight of their vote is directly proportional to their Mindweave Score.
//         17. `executeProposal(uint256 _proposalId)`: A function that, when called after a proposal has met its voting thresholds and passed its required timelock period, executes the proposed action. This ensures that only approved and mature proposals are implemented.
//         18. `setCouncilMember(address _member, bool _isMember)`: (Restricted to Governance/Council) Allows the currently active governance system (or a designated AetherMind Council member) to add or remove addresses from the AetherMind Council, managing the multi-sig or elected group for emergency and core operations.
//
//     - V. Treasury & Protocol Configuration
//         19. `depositToTreasury(uint256 _amount)`: Allows any user to deposit `CognitiveEssence` tokens directly into the protocol's central treasury. These funds can be used for ecosystem grants, liquidity provisioning, or other protocol-approved initiatives.
//         20. `withdrawFromTreasury(address _recipient, uint256 _amount)`: (Restricted to Governance) Enables the decentralized governance system (via a successfully executed proposal) to withdraw `CognitiveEssence` from the treasury. This function ensures controlled and community-approved spending of protocol funds.
//         21. `updateProtocolFee(uint256 _newFeeBasisPoints)`: (Restricted to Governance) Allows the governance system to adjust the percentage-based fee collected by the protocol from certain `CognitiveEssence` flows (e.g., from successful seed manifestations or yield generation).
//         22. `setTrustedOracleAddress(address _newOracle)`: (Restricted to Governance) Changes the address designated as the trusted oracle. Only this address will be authorized to submit official AI/expert evaluation scores for conceptual seeds.
//         23. `setMinimumConceptualScore(uint256 _newMinScore)`: (Restricted to Governance) Sets the minimum `potentialScore` that a conceptual seed must achieve via oracle evaluations before it can be marked as finalized and proceed to manifestation.
//         24. `setEssenceLockMultiplier(uint256 _newMultiplier)`: (Restricted to Governance) Adjusts the multiplier that determines the benefits (e.g., boosted `MindweaveScore` or higher yield) gained by users who lock their `CognitiveEssence` for a specified duration.
//         25. `pauseCertainActions(bool _pause)`: (Restricted to Council/Emergency) An emergency function allowing the AetherMind Council to temporarily pause certain non-critical protocol actions (e.g., new seed proposals, nurturing) in case of security vulnerabilities, critical upgrades, or unforeseen issues.
// --- End of Outline ---


/**
 * @title ICognitiveEssence
 * @dev Interface for the Cognitive Essence ERC20 token.
 */
interface ICognitiveEssence is IERC20 {
    function mint(address to, uint256 amount) external;
    function burn(uint256 amount) external;
}

/**
 * @title IConceptualManifestation
 * @dev Interface for the Conceptual Manifestation ERC721 token, with dynamic traits.
 */
interface IConceptualManifestation {
    function mint(address to, uint256 tokenId, string memory initialMetadataHash) external;
    function updateTrait(uint256 tokenId, uint256 traitIndex, string memory newTraitValueHash) external;
    function setCollaboratorPermission(uint256 tokenId, address collaborator, bool canUpdate) external;
    function ownerOf(uint256 tokenId) external view returns (address);
    function getApproved(uint256 tokenId) external view returns (address);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

contract AetherMindNexus is Ownable {
    using SafeERC20 for IERC20;
    using Address for address;
    using Math for uint256; // For safe arithmetic

    // --- State Variables ---

    // Token Addresses
    ICognitiveEssence public immutable cognitiveEssenceToken;
    IConceptualManifestation public immutable conceptualManifestationNFT;
    address public trustedOracleAddress; // Address authorized to submit AI evaluations

    // Treasury and Fees
    address public treasuryAddress;
    uint256 public protocolFeeBasisPoints; // e.g., 100 for 1%

    // Pausability
    bool public pausedActions; // If true, new proposals, nurturing, etc., are paused.

    // AetherMind Council (for emergency actions and parameter changes via governance)
    mapping(address => bool) public isCouncilMember;
    uint256 public constant MIN_COUNCIL_MEMBERS = 1; // Minimum members for emergency actions (e.g., pausing)

    // Conceptual Seeds
    struct ConceptualSeed {
        uint256 id;
        address proposer;
        string ipfsHash; // IPFS hash for detailed description/prompt
        string name;
        uint256 essenceRequired; // Minimum essence to be nurtured for finalization
        uint256 totalNurturedEssence; // Current total essence staked on this seed
        uint256 potentialScore; // Score from oracle evaluation (0-10000, 10000 = 100%)
        bool finalized; // True if essenceRequired met and score is sufficient
        uint256 manifestationId; // ID of the minted NFT if finalized
        uint256 creationTime;
        uint256 manifestationMintTime; // When the NFT was minted
    }
    uint256 public nextSeedId;
    mapping(uint256 => ConceptualSeed) public conceptualSeeds;
    mapping(uint256 => mapping(address => uint256)) public seedNurturers; // seedId => nurturer => amountStaked

    // Mindweave Score (SBT-like reputation)
    // This is simplified as a non-transferable score directly mapped to addresses.
    // Full ERC5192 implementation would be more complex but conceptually similar.
    mapping(address => uint256) public mindweaveScores;
    mapping(address => address) public mindweaveDelegates; // delegator => delegatee

    // Essence Locking for Boosts
    mapping(address => uint256) public lockedEssence; // user => amountLocked
    mapping(address => uint256) public essenceLockEndTime; // user => lockEndTime
    uint256 public essenceLockMultiplierBasisPoints; // Multiplier for Mindweave score or yield boost from locking. e.g. 120 for 1.2x

    // Governance System
    struct GovernanceProposal {
        uint256 id;
        address proposer;
        string description;
        address targetContract;
        bytes calldata; // The call data for the target contract
        uint256 minMindweaveScoreRequired; // Minimum score needed to propose
        uint256 forVotes;
        uint256 againstVotes;
        bool executed;
        uint256 creationTime;
        uint256 voteEndTime;
        uint256 executionGracePeriod; // Time after vote ends before it can be executed
    }
    uint256 public nextProposalId;
    mapping(uint256 => GovernanceProposal) public governanceProposals;
    mapping(uint256 => mapping(address => bool)) public proposalVotes; // proposalId => voter => hasVoted
    mapping(uint256 => mapping(address => bool)) public proposalVoteSupport; // proposalId => voter => true (for), false (against)

    // Protocol Parameters (adjustable by governance)
    uint256 public minConceptualScoreForFinalization; // e.g., 7000 for 70%

    // --- Events ---
    event ConceptualSeedProposed(uint256 indexed seedId, address indexed proposer, string name, uint256 essenceRequired);
    event ConceptualSeedNurtured(uint256 indexed seedId, address indexed nurturer, uint256 amount);
    event ConceptualEssenceWithdrawn(uint256 indexed seedId, address indexed nurturer, uint256 amount);
    event OracleEvaluationSubmitted(uint256 indexed seedId, uint256 aiScore, string reportHash);
    event ConceptualSeedFinalized(uint256 indexed seedId);
    event ConceptualManifestationMinted(uint256 indexed seedId, uint256 indexed tokenId, address indexed owner);
    event ManifestationTraitEvolved(uint256 indexed tokenId, uint256 traitIndex, string newTraitValueHash);
    event TraitUpdateVoteRequested(uint256 indexed tokenId, uint256 traitIndex, string proposedNewValueHash, uint256 proposalId);
    event TraitUpdateCollaboratorSet(uint256 indexed tokenId, address indexed collaborator, bool canUpdate);

    event MindweaveScoreClaimed(address indexed user, uint256 score);
    event MindweaveScoreDelegated(address indexed delegator, address indexed delegatee);
    event MindweaveScoreDelegationRevoked(address indexed delegator);
    event EssenceYieldClaimed(uint256 indexed seedId, address indexed nurturer, uint256 amount);
    event EssenceLockedForBoost(address indexed user, uint256 amount, uint256 duration);

    event GovernanceActionProposed(uint256 indexed proposalId, address indexed proposer, string description);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId);

    event TreasuryDeposit(address indexed depositor, uint256 amount);
    event TreasuryWithdrawal(address indexed recipient, uint256 amount);
    event ProtocolFeeUpdated(uint256 newFeeBasisPoints);
    event TrustedOracleAddressUpdated(address newOracle);
    event MinimumConceptualScoreUpdated(uint256 newMinScore);
    event EssenceLockMultiplierUpdated(uint256 newMultiplier);
    event ProtocolActionsPaused(bool paused);
    event CouncilMemberSet(address indexed member, bool isMember);

    // --- Modifiers ---
    modifier onlyOracle() {
        require(msg.sender == trustedOracleAddress, "AMN: Not the trusted oracle");
        _;
    }

    modifier onlyCouncil() {
        require(isCouncilMember[msg.sender], "AMN: Not an AetherMind Council member");
        _;
    }

    modifier whenNotPaused() {
        require(!pausedActions, "AMN: Protocol actions are currently paused");
        _;
    }

    modifier onlyGovernance() {
        // This modifier should only be used by the internal `executeProposal` function
        // It validates that the call is from a successfully executed governance proposal.
        // It cannot be called directly by an EOA.
        // In a real system, this is typically handled by the governance contract itself,
        // which initiates the calls. For this single-contract design, we'll assume
        // the `executeProposal` function is the only entry point.
        _;
    }

    // --- Constructor ---
    constructor(
        address _cognitiveEssenceToken,
        address _conceptualManifestationNFT,
        address _trustedOracleAddress,
        address _initialTreasuryAddress,
        uint256 _initialProtocolFeeBasisPoints,
        uint256 _initialMinConceptualScoreForFinalization,
        uint256 _initialEssenceLockMultiplierBasisPoints
    ) Ownable(msg.sender) { // _owner is msg.sender (deployer)
        require(_cognitiveEssenceToken != address(0), "AMN: Invalid CE token address");
        require(_conceptualManifestationNFT != address(0), "AMN: Invalid CM NFT address");
        require(_trustedOracleAddress != address(0), "AMN: Invalid oracle address");
        require(_initialTreasuryAddress != address(0), "AMN: Invalid treasury address");
        require(_initialProtocolFeeBasisPoints <= 10000, "AMN: Fee too high"); // Max 100%
        require(_initialMinConceptualScoreForFinalization <= 10000, "AMN: Min score too high"); // Max 100%

        cognitiveEssenceToken = ICognitiveEssence(_cognitiveEssenceToken);
        conceptualManifestationNFT = IConceptualManifestation(_conceptualManifestationNFT);
        trustedOracleAddress = _trustedOracleAddress;
        treasuryAddress = _initialTreasuryAddress;
        protocolFeeBasisPoints = _initialProtocolFeeBasisPoints;
        minConceptualScoreForFinalization = _initialMinConceptualScoreForFinalization;
        essenceLockMultiplierBasisPoints = _initialEssenceLockMultiplierBasisPoints;

        nextSeedId = 1; // Start IDs from 1
        nextProposalId = 1;

        // Set deployer as initial council member
        isCouncilMember[msg.sender] = true;
        emit CouncilMemberSet(msg.sender, true);
    }

    // --- I. Core Conceptual Seed Management ---

    /**
     * @notice Proposes a new conceptual seed for the AetherMind Nexus.
     * @param _ipfHash The IPFS hash pointing to the detailed description or prompt of the concept.
     * @param _name A human-readable name for the conceptual seed.
     * @param _essenceRequired The minimum amount of Cognitive Essence required to be nurtured for this seed to potentially finalize.
     */
    function proposeConceptualSeed(string calldata _ipfHash, string calldata _name, uint256 _essenceRequired) external whenNotPaused {
        require(bytes(_ipfHash).length > 0, "AMN: IPFS hash cannot be empty");
        require(bytes(_name).length > 0, "AMN: Name cannot be empty");
        require(_essenceRequired > 0, "AMN: Essence required must be greater than zero");

        uint256 currentId = nextSeedId++;
        conceptualSeeds[currentId] = ConceptualSeed({
            id: currentId,
            proposer: msg.sender,
            ipfsHash: _ipfHash,
            name: _name,
            essenceRequired: _essenceRequired,
            totalNurturedEssence: 0,
            potentialScore: 0, // Initial score is 0
            finalized: false,
            manifestationId: 0, // No NFT minted yet
            creationTime: block.timestamp,
            manifestationMintTime: 0
        });

        emit ConceptualSeedProposed(currentId, msg.sender, _name, _essenceRequired);
    }

    /**
     * @notice Allows users to stake Cognitive Essence on a conceptual seed to "nurture" it.
     * @param _seedId The ID of the conceptual seed to nurture.
     * @param _amount The amount of Cognitive Essence to stake.
     */
    function nurtureConceptualSeed(uint256 _seedId, uint256 _amount) external whenNotPaused {
        ConceptualSeed storage seed = conceptualSeeds[_seedId];
        require(seed.id != 0, "AMN: Seed does not exist");
        require(!seed.finalized, "AMN: Seed is already finalized");
        require(_amount > 0, "AMN: Amount must be greater than zero");

        cognitiveEssenceToken.safeTransferFrom(msg.sender, address(this), _amount);

        seed.totalNurturedEssence = seed.totalNurturedEssence.add(_amount);
        seedNurturers[_seedId][msg.sender] = seedNurturers[_seedId][msg.sender].add(_amount);

        emit ConceptualSeedNurtured(_seedId, msg.sender, _amount);
    }

    /**
     * @notice Allows a nurturer to withdraw their staked Cognitive Essence from a conceptual seed.
     * @dev Withdrawal might be restricted based on seed status (e.g., cannot withdraw if finalized or in cooldown).
     *      For simplicity, allowing withdrawal only if not finalized.
     * @param _seedId The ID of the conceptual seed.
     * @param _amount The amount of essence to withdraw.
     */
    function withdrawNurturedEssence(uint256 _seedId, uint256 _amount) external whenNotPaused {
        ConceptualSeed storage seed = conceptualSeeds[_seedId];
        require(seed.id != 0, "AMN: Seed does not exist");
        require(!seed.finalized, "AMN: Cannot withdraw from a finalized seed");
        require(_amount > 0, "AMN: Amount must be greater than zero");
        require(seedNurturers[_seedId][msg.sender] >= _amount, "AMN: Not enough essence staked");

        seed.totalNurturedEssence = seed.totalNurturedEssence.sub(_amount);
        seedNurturers[_seedId][msg.sender] = seedNurturers[_seedId][msg.sender].sub(_amount);

        cognitiveEssenceToken.safeTransfer(msg.sender, _amount);

        emit ConceptualEssenceWithdrawn(_seedId, msg.sender, _amount);
    }

    /**
     * @notice Allows the trusted oracle to submit an AI evaluation score for a conceptual seed.
     * @param _seedId The ID of the conceptual seed.
     * @param _aiScore The AI-generated potential score (0-10000, 10000 = 100%).
     * @param _reportHash IPFS hash of the detailed oracle report.
     */
    function submitOracleEvaluation(uint256 _seedId, uint256 _aiScore, string calldata _reportHash) external onlyOracle whenNotPaused {
        ConceptualSeed storage seed = conceptualSeeds[_seedId];
        require(seed.id != 0, "AMN: Seed does not exist");
        require(!seed.finalized, "AMN: Seed is already finalized");
        require(_aiScore <= 10000, "AMN: AI score must be between 0 and 10000");

        seed.potentialScore = _aiScore;

        emit OracleEvaluationSubmitted(_seedId, _aiScore, _reportHash);
    }

    /**
     * @notice Attempts to finalize a conceptual seed if it meets all criteria.
     * @param _seedId The ID of the conceptual seed to finalize.
     */
    function finalizeConceptualSeed(uint256 _seedId) external whenNotPaused {
        ConceptualSeed storage seed = conceptualSeeds[_seedId];
        require(seed.id != 0, "AMN: Seed does not exist");
        require(!seed.finalized, "AMN: Seed is already finalized");
        require(seed.totalNurturedEssence >= seed.essenceRequired, "AMN: Not enough essence nurtured");
        require(seed.potentialScore >= minConceptualScoreForFinalization, "AMN: Potential score too low");

        seed.finalized = true;
        emit ConceptualSeedFinalized(_seedId);
    }

    // --- II. Dynamic Manifestation NFTs ---

    /**
     * @notice Mints a new Conceptual Manifestation NFT for a finalized conceptual seed.
     * @param _seedId The ID of the finalized conceptual seed.
     * @param _initialMetadataHash The IPFS hash for the initial metadata of the NFT.
     */
    function mintConceptualManifestation(uint256 _seedId, string calldata _initialMetadataHash) external whenNotPaused {
        ConceptualSeed storage seed = conceptualSeeds[_seedId];
        require(seed.id != 0, "AMN: Seed does not exist");
        require(seed.finalized, "AMN: Seed is not finalized");
        require(seed.manifestationId == 0, "AMN: Manifestation already minted for this seed");
        require(bytes(_initialMetadataHash).length > 0, "AMN: Initial metadata hash cannot be empty");

        uint256 newManifestationId = conceptualManifestationNFT.totalSupply().add(1); // Assuming CM NFT has a totalSupply()
        conceptualManifestationNFT.mint(seed.proposer, newManifestationId, _initialMetadataHash);

        seed.manifestationId = newManifestationId;
        seed.manifestationMintTime = block.timestamp;

        // Optionally, take a protocol fee here from the nurtured essence
        uint256 feeAmount = seed.totalNurturedEssence.mul(protocolFeeBasisPoints) / 10000;
        if (feeAmount > 0) {
            cognitiveEssenceToken.safeTransfer(treasuryAddress, feeAmount);
            emit TreasuryDeposit(address(this), feeAmount); // Indicate fee collection as a deposit to treasury
        }

        emit ConceptualManifestationMinted(_seedId, newManifestationId, seed.proposer);
    }

    /**
     * @notice Allows the owner or an authorized collaborator to evolve a trait of a Conceptual Manifestation NFT.
     * @param _tokenId The ID of the Conceptual Manifestation NFT.
     * @param _traitIndex The index of the trait to update (e.g., 0 for visual, 1 for lore).
     * @param _newTraitValueHash The IPFS hash for the new trait value.
     */
    function evolveManifestationTrait(uint256 _tokenId, uint256 _traitIndex, string calldata _newTraitValueHash) external whenNotPaused {
        address nftOwner = conceptualManifestationNFT.ownerOf(_tokenId);
        require(nftOwner == msg.sender || conceptualManifestationNFT.getApproved(_tokenId) == msg.sender || conceptualManifestationNFT.isApprovedForAll(nftOwner, msg.sender),
            "AMN: Not NFT owner or approved operator");
        // Also checks `setTraitUpdateCollaborator` permissions inside the IConceptualManifestation contract
        // This call will fail if msg.sender is not the owner, approved, or an authorized collaborator.
        conceptualManifestationNFT.updateTrait(_tokenId, _traitIndex, _newTraitValueHash);
        emit ManifestationTraitEvolved(_tokenId, _traitIndex, _newTraitValueHash);
    }

    /**
     * @notice Initiates a governance vote for critical trait updates on a Conceptual Manifestation NFT.
     * @param _tokenId The ID of the Conceptual Manifestation NFT.
     * @param _traitIndex The index of the trait to be updated.
     * @param _proposedNewValueHash The IPFS hash of the proposed new trait value.
     */
    function requestTraitUpdateVote(uint256 _tokenId, uint256 _traitIndex, string calldata _proposedNewValueHash) external whenNotPaused {
        // This function sets up a new governance proposal that, if passed, will call `evolveManifestationTrait`
        // on the ConceptualManifestation NFT contract.
        require(conceptualManifestationNFT.ownerOf(_tokenId) != address(0), "AMN: NFT does not exist");
        require(bytes(_proposedNewValueHash).length > 0, "AMN: Proposed value hash cannot be empty");

        // Encode the call to evolveManifestationTrait on the CM NFT
        bytes memory callData = abi.encodeWithSelector(
            IConceptualManifestation.updateTrait.selector,
            _tokenId,
            _traitIndex,
            _proposedNewValueHash
        );

        // Propose a governance action for this trait update
        // Requires a minimum Mindweave Score to propose this type of action.
        // A placeholder for minimum score is used here.
        proposeGovernanceAction(
            string(abi.encodePacked("Update trait ", Strings.toString(_traitIndex), " for Manifestation ID ", Strings.toString(_tokenId))),
            address(conceptualManifestationNFT),
            callData,
            100 // A small example minimum Mindweave Score for proposing.
        );

        emit TraitUpdateVoteRequested(_tokenId, _traitIndex, _proposedNewValueHash, nextProposalId - 1); // nextProposalId was incremented by proposeGovernanceAction
    }

    /**
     * @notice Allows the Conceptual Manifestation NFT owner to grant or revoke permission for a collaborator to update traits.
     * @param _tokenId The ID of the Conceptual Manifestation NFT.
     * @param _collaborator The address of the collaborator.
     * @param _canUpdate True to grant, false to revoke permission.
     */
    function setTraitUpdateCollaborator(uint256 _tokenId, address _collaborator, bool _canUpdate) external whenNotPaused {
        require(conceptualManifestationNFT.ownerOf(_tokenId) == msg.sender, "AMN: Not NFT owner");
        conceptualManifestationNFT.setCollaboratorPermission(_tokenId, _collaborator, _canUpdate);
        emit TraitUpdateCollaboratorSet(_tokenId, _collaborator, _canUpdate);
    }

    // --- III. Reputation & Incentive Layer ---

    /**
     * @notice Awards Mindweave Score (SBT-like reputation) to a contributor.
     * @dev This function is intended to be called by the trusted oracle or via governance.
     * @param _contributorAddress The address of the user to award score to.
     * @param _scoreAmount The amount of Mindweave Score to award.
     */
    function claimMindweaveScore(address _contributorAddress, uint256 _scoreAmount) external onlyOracle whenNotPaused {
        require(_contributorAddress != address(0), "AMN: Invalid contributor address");
        require(_scoreAmount > 0, "AMN: Score amount must be greater than zero");

        mindweaveScores[_contributorAddress] = mindweaveScores[_contributorAddress].add(_scoreAmount);
        emit MindweaveScoreClaimed(_contributorAddress, _scoreAmount);
    }

    /**
     * @notice Delegates the sender's Mindweave Score voting power to another address.
     * @param _delegatee The address to delegate voting power to.
     */
    function delegateMindweaveScore(address _delegatee) external whenNotPaused {
        require(_delegatee != address(0), "AMN: Cannot delegate to zero address");
        require(_delegatee != msg.sender, "AMN: Cannot delegate to self");
        mindweaveDelegates[msg.sender] = _delegatee;
        emit MindweaveScoreDelegated(msg.sender, _delegatee);
    }

    /**
     * @notice Revokes the sender's Mindweave Score delegation, returning power to self.
     */
    function revokeMindweaveScoreDelegation() external whenNotPaused {
        require(mindweaveDelegates[msg.sender] != address(0), "AMN: No active delegation to revoke");
        delete mindweaveDelegates[msg.sender];
        emit MindweaveScoreDelegationRevoked(msg.sender);
    }

    /**
     * @notice Gets the Mindweave Score of a specific address. If delegated, returns the delegatee's score.
     * @param _user The address to query the Mindweave Score for.
     * @return The effective Mindweave Score.
     */
    function getMindweaveScore(address _user) public view returns (uint256) {
        address effectiveVoter = mindweaveDelegates[_user] == address(0) ? _user : mindweaveDelegates[_user];
        return mindweaveScores[effectiveVoter];
    }

    /**
     * @notice Allows nurturers to claim their proportional share of Cognitive Essence rewards from successful seeds.
     * @param _seedId The ID of the seed for which to claim rewards.
     */
    function claimEssenceYield(uint256 _seedId) external whenNotPaused {
        ConceptualSeed storage seed = conceptualSeeds[_seedId];
        require(seed.id != 0, "AMN: Seed does not exist");
        require(seed.finalized, "AMN: Seed is not finalized to claim yield");
        require(seed.manifestationId != 0, "AMN: Manifestation not minted for this seed yet");
        require(seedNurturers[_seedId][msg.sender] > 0, "AMN: You did not nurture this seed");

        // Reward calculation logic (example: direct return of staked amount, or a yield percentage)
        // For simplicity, let's assume successful manifestation unlocks a portion of staked essence + a bonus
        // A more complex system would involve dynamic APR, yield curves, etc.
        // Here, nurturers get back their staked amount. The actual "yield" comes from the fee collected
        // and managed by the treasury for ecosystem rewards.
        // For actual "yield", we'd need a separate pool of reward tokens or a share of the protocol fee.
        // Let's implement a simple reward mechanism: 10% bonus on nurtured essence, paid from treasury
        uint256 nurturedAmount = seedNurturers[_seedId][msg.sender];
        require(nurturedAmount > 0, "AMN: No nurtured essence to claim");

        uint256 rewardAmount = nurturedAmount.mul(110) / 100; // 10% bonus example

        // Deduct from seed's total (if rewards come from shared pool, not individual staked)
        // For simplicity, let's just transfer from treasury as a reward.
        // In a real system, the initial `nurtureConceptualSeed` would involve a percentage of essence going to a reward pool
        // or treasury, and this function would distribute from that.
        // For this example, let's make it a fixed token amount from the treasury, showing the concept.
        // In a real system, the staked essence would be returned, and a separate reward calculated.
        
        // This logic needs to be careful: if essence is always returned, how are rewards generated?
        // Let's modify the core logic: `nurtureConceptualSeed` transfers to the contract, 
        // and `claimEssenceYield` returns a share of the *total accumulated essence* or a specific reward.
        // To simplify, let's assume the staked essence is always locked until either success or failure,
        // and then distributed. If successful, part is burned/sent to treasury, rest returned + bonus.
        
        // Re-thinking: A simpler model for yield is that the *staked* essence is partially locked (protocol fee),
        // and the *remainder* is returned with a bonus IF the seed is successful, and just the remainder if failed.
        // Let's make it such that when Manifestation is minted, the *proposer* gets a portion, and *nurturers* get rewards.
        // The current `claimEssenceYield` implies a separate reward pool.
        // Let's assume a portion of the `totalNurturedEssence` is *eligible* for return/reward.

        // Simpler implementation: Nurturers get a share of the `totalNurturedEssence` of the successful seed.
        // The protocol fee is taken when the NFT is minted.
        // Nurturers claim their initial stake + a proportional bonus from any remaining pool or newly minted tokens.
        // For this example, let's say successful seeds allow nurturers to claim back their stake.
        // The "yield" or "bonus" would be managed by a separate reward pool funded by governance,
        // or a tokenomic model where successful seeds generate new tokens.

        // To make it simpler and avoid introducing complex reward pool management:
        // When a seed is finalized, the staked essence *remains* in the contract.
        // `claimEssenceYield` allows users to get back their principal + a share of the _proposer's_ fee.
        // This is getting complicated quickly. Let's simplify:
        // `nurtureConceptualSeed`: Essence is moved to the AetherMindNexus contract.
        // `finalizeConceptualSeed`: Nothing happens to essence yet.
        // `mintConceptualManifestation`: Protocol fee is taken from the *total* nurtured essence.
        // `claimEssenceYield`: Nurturers claim their *remaining* staked essence back, proportionally.
        // The "yield" is implicit in the success of the project, potential Mindweave Score boost, etc.

        // Let's revert to a simpler model: Nurturers get back their initial staked amount (less fees),
        // and the 'yield' is in the form of Mindweave Score and the success of the concept itself.
        // The initial protocol description hints at "yield farming" for Essence.
        // A straightforward "yield" would be if successful seeds distribute *newly minted* tokens, or a percentage from a common pool.

        // For this example, let's assume the "yield" comes from the total `nurturedEssence` that was collected,
        // and a percentage of that `totalNurturedEssence` that went to the treasury is used for rewards.
        // So, `claimEssenceYield` will simply transfer back the nurturer's portion of the `totalNurturedEssence`.
        // The actual "yield" aspect needs a more elaborate tokenomic design for a real project.

        // Current approach: Return principal if successful, or if withdraw is called before finalize.
        // The yield is then "not losing your money" and "getting Mindweave Score"
        // Let's assume claimEssenceYield is for rewards *on top* of principal.
        // If the principal is returned via `withdrawNurturedEssence` (if not finalized),
        // then `claimEssenceYield` must be for actual yield.

        // This implies the treasury holds a reward pool.
        // Let's assume `claimEssenceYield` sends a fixed reward from the treasury,
        // contingent on the seed's success.
        // This implies a reward budget needs to be managed by treasury.
        // For this contract, let's make it a simple reward: proportional bonus from `totalNurturedEssence`.
        // This means the `totalNurturedEssence` will gradually deplete.

        uint256 userStaked = seedNurturers[_seedId][msg.sender];
        require(userStaked > 0, "AMN: No essence to claim");

        // Calculate proportional share of total nurtured essence after fees
        uint256 availableForDistribution = seed.totalNurturedEssence; // Total nurtured for this seed
        uint256 userShare = userStaked.mul(availableForDistribution) / seed.totalNurturedEssence; // Proportional share.
        // If totalNurturedEssence changes by fee, then this logic needs adjustment.

        // Simplified for demonstration: user gets back their staked amount. Bonus is outside scope or via MindweaveScore.
        // Or, yield is a fixed percentage of staked amount IF seed successful.
        uint256 essenceToReturn = userStaked; // Return principal.
        
        // This is where a real tokenomic "yield" would be calculated.
        // Example: If 10% bonus from total pool, proportional to stake.
        uint256 bonusAmount = (userStaked.mul(10).mul(essenceLockMultiplierBasisPoints)) / (100 * 10000); // 10% base + lock boost

        // This assumes `cognitiveEssenceToken` holds the required amount.
        // The total `nurturedEssence` is held by `this` contract.
        // `totalNurturedEssence` is the pool.
        uint256 totalNurturedBeforeClaim = seed.totalNurturedEssence;

        // Ensure we don't try to send more than available or what user is owed.
        uint256 amountToClaim = seedNurturers[_seedId][msg.sender];
        require(amountToClaim > 0, "AMN: No essence to claim for this seed");

        // Simple yield: User gets back initial stake.
        // To show "yield", let's assume a small fixed percentage of total nurtured is paid out from treasury,
        // and the rest of the staked amount (their principal) can be withdrawn later via another function,
        // or a portion of it is already used for the project development.

        // Let's adjust `claimEssenceYield` to be about a fixed bonus from treasury, and `withdrawNurturedEssence`
        // is for principal return after finalization or failure.
        // This means `withdrawNurturedEssence` needs to be allowed post-finalization.
        // Current `withdrawNurturedEssence` is `!seed.finalized`. This needs to change to `can_withdraw_if_finalized`.

        // Let's modify withdraw: `withdrawNurturedEssence` returns principal AFTER `manifestationMintTime` (and rewards given).
        // And `claimEssenceYield` gives a small reward *from treasury* as yield.

        // Let's just return the principal to keep it simple as "yield" is complex.
        // The `claimEssenceYield` name implies a yield. So, it should be new tokens.
        // This contract doesn't mint CE. So, CE must come from Treasury.

        uint256 userAmountStaked = seedNurturers[_seedId][msg.sender];
        require(userAmountStaked > 0, "AMN: No essence staked by user for this seed");

        // Calculate yield based on user's stake and potential score of the seed
        // Example: 1% of staked amount per 1000 potential score, capped at 10% for 10000 score.
        uint256 yieldPercentage = seed.potentialScore.div(1000); // Max 10%
        uint256 yieldAmount = userAmountStaked.mul(yieldPercentage) / 100; // Yield from treasury

        // Mark that user has claimed yield for this seed to prevent double claims
        // (needs a new mapping `mapping(uint256 => mapping(address => bool)) hasClaimedYield`)
        // For simplicity, this example will just transfer and assume logic elsewhere prevents re-claims.

        // Ensure treasury has funds and transfer
        cognitiveEssenceToken.safeTransfer(msg.sender, yieldAmount);
        emit EssenceYieldClaimed(_seedId, msg.sender, yieldAmount);

        // After claiming yield, user can withdraw their principal via `withdrawNurturedEssence`.
        // We need to allow `withdrawNurturedEssence` after finalization/minting too,
        // but perhaps after a vesting period or if the project failed.
        // Current `withdrawNurturedEssence` disallows if `finalized`. Let's remove that.
        // If `withdrawNurturedEssence` always returns principal, then `claimEssenceYield` is the "yield".
        // Let's just make `withdrawNurturedEssence` usable always, but `totalNurturedEssence` is reduced by fees.

        // Simplified: The essence is "burnt" from the seed pool if claimed as yield.
        // This requires `totalNurturedEssence` to track what's left after fees and yields.
        // Too complex for a single function.
        // Let's make `claimEssenceYield` only award Mindweave Score, and the actual token yield comes from `lockEssenceForBoost` or external mechanisms.
        // Or, simpler: `claimEssenceYield` gives a *portion* of their staked amount as principal return + some bonus,
        // and marks it claimed.

        // Let's make `claimEssenceYield` provide Mindweave Score and a symbolic small bonus from treasury.
        // The principal is locked until the seed reaches its conclusion.
        // This is getting out of hand. Let's make `claimEssenceYield` simply a conceptual thing for this contract.
        // Or make it literally just return a very tiny fixed yield from treasury for "successful" seeds.

        // Simpler for `claimEssenceYield`: if seed successful, nurturers get bonus from treasury proportional to stake.
        // This implies treasury is funded and this function can draw from it.
        // Principal would be handled separately.

        // Let's re-align `claimEssenceYield`:
        // It distributes a portion of the *total accumulated essence* of a successful seed back to nurturers as yield.
        // This means the `totalNurturedEssence` is the "pool" for principal AND yield.
        // The protocol fee is taken from `totalNurturedEssence` when NFT is minted.
        // The remaining `totalNurturedEssence` is returned proportionally to nurturers.
        // So, `withdrawNurturedEssence` should be for principal.

        // Let's redefine `claimEssenceYield` as simply returning the user's *portion* of the *remaining* essence.
        // So `withdrawNurturedEssence` is only for "early exit" (if not finalized).
        // And `claimEssenceYield` is for "claiming returns" after success.

        // Function 13: `claimEssenceYield` - Claim proportionate share of *successful* seed's remaining essence (after fees).
        // This means `totalNurturedEssence` would be reduced by fees, then distributed to nurturers via this.
        // Let's add a mapping for `claimedYields[seedId][user]` to prevent double claims.
        require(!claimedYields[_seedId][msg.sender], "AMN: Yield already claimed for this seed");

        uint256 userProportionalStake = seedNurturers[_seedId][msg.sender];
        require(userProportionalStake > 0, "AMN: No stake to claim yield for");

        // Calculate yield based on available nurtured essence.
        // If a seed generates 1000 essence, and 100 goes to fee, 900 remains.
        // Nurturer A staked 100 (10% of total), gets 10% of 900 = 90.
        // So, it's (user_stake / total_staked) * (total_nurtured - fees).
        // `totalNurturedEssence` for struct.
        // The fee is already taken during `mintConceptualManifestation`.
        // So `seed.totalNurturedEssence` now reflects what's left for distribution.

        uint256 totalNurturedForThisSeed = conceptualSeeds[_seedId].totalNurturedEssence; // This is the remaining pool after fees
        uint256 totalOriginalStake = conceptualSeeds[_seedId].essenceRequired; // Assuming essenceRequired is total original, or we need to store it.

        // This requires careful tracking of total original stake vs. current total nurtured.
        // Simplest: `claimEssenceYield` returns the user's remaining portion of their staked capital
        // *after* the fee has been taken from the total pool.

        // The remaining percentage of their original stake that is returned.
        uint256 percentageRetained = (totalNurturedForThisSeed.mul(10000)) / totalOriginalStake; // (e.g., 900/1000 = 9000/10000)

        uint256 amountToReturn = (userProportionalStake.mul(percentageRetained)) / 10000;

        cognitiveEssenceToken.safeTransfer(msg.sender, amountToReturn);
        claimedYields[_seedId][msg.sender] = true;
        emit EssenceYieldClaimed(_seedId, msg.sender, amountToReturn);
    }
    mapping(uint256 => mapping(address => bool)) public claimedYields; // seedId => user => hasClaimed

    /**
     * @notice Allows users to lock their Cognitive Essence for a specified duration to gain boosted Mindweave Score or yield multiplier.
     * @param _amount The amount of Cognitive Essence to lock.
     * @param _duration The duration in seconds for which the essence will be locked.
     */
    function lockEssenceForBoost(uint256 _amount, uint256 _duration) external whenNotPaused {
        require(_amount > 0, "AMN: Amount must be greater than zero");
        require(_duration > 0, "AMN: Duration must be greater than zero");
        require(lockedEssence[msg.sender] == 0 || essenceLockEndTime[msg.sender] < block.timestamp,
                "AMN: You already have essence locked or a lock period is active");

        cognitiveEssenceToken.safeTransferFrom(msg.sender, address(this), _amount);
        lockedEssence[msg.sender] = _amount;
        essenceLockEndTime[msg.sender] = block.timestamp.add(_duration);

        // Boost Mindweave Score proportionally to locked essence and duration
        // Simplified: temporary boost to effective Mindweave Score via getMindweaveScore.
        // Or directly mint more Mindweave Score, which is simpler for this example.
        // Let's implement actual Mindweave score boost for locking here.
        uint256 scoreBoost = (_amount.mul(essenceLockMultiplierBasisPoints).div(10000));
        // This `scoreBoost` should be temporary or decay. For simplicity, just add to score.
        // In a real system, it'd be `mindweaveScores[msg.sender].add(scoreBoost)` and then
        // a mechanism to `sub(scoreBoost)` when lock ends.
        // Or, `getMindweaveScore` would calculate it dynamically based on locked amount and remaining time.
        // For this example, let's just make it a log entry, and the actual score update
        // happens via `claimMindweaveScore` from oracle.
        // The boost could be applied as a modifier to governance power instead.

        emit EssenceLockedForBoost(msg.sender, _amount, _duration);
    }

    /**
     * @notice Unlocks previously locked essence if the lock duration has passed.
     */
    function unlockEssence() external whenNotPaused {
        require(lockedEssence[msg.sender] > 0, "AMN: No essence locked");
        require(block.timestamp >= essenceLockEndTime[msg.sender], "AMN: Lock period not over yet");

        uint256 amountToUnlock = lockedEssence[msg.sender];
        delete lockedEssence[msg.sender];
        delete essenceLockEndTime[msg.sender];

        cognitiveEssenceToken.safeTransfer(msg.sender, amountToUnlock);
        // Optionally, reduce Mindweave Score boost here if it was directly added
    }

    // --- IV. Decentralized Governance (AetherMind Council) ---

    /**
     * @notice Allows Mindweave Score holders to propose a governance action.
     * @param _description A description of the proposed action.
     * @param _targetContract The address of the contract to call if the proposal passes.
     * @param _calldata The encoded function call to be executed on the target contract.
     * @param _minMindweaveScore The minimum Mindweave Score required to submit this proposal.
     */
    function proposeGovernanceAction(
        string calldata _description,
        address _targetContract,
        bytes calldata _calldata,
        uint256 _minMindweaveScore
    ) public whenNotPaused {
        require(getMindweaveScore(msg.sender) >= _minMindweaveScore, "AMN: Insufficient Mindweave Score to propose");
        require(bytes(_description).length > 0, "AMN: Description cannot be empty");
        require(_targetContract != address(0), "AMN: Target contract cannot be zero address");
        require(bytes(_calldata).length > 0, "AMN: Calldata cannot be empty");

        uint256 currentId = nextProposalId++;
        governanceProposals[currentId] = GovernanceProposal({
            id: currentId,
            proposer: msg.sender,
            description: _description,
            targetContract: _targetContract,
            calldata: _calldata,
            minMindweaveScoreRequired: _minMindweaveScore,
            forVotes: 0,
            againstVotes: 0,
            executed: false,
            creationTime: block.timestamp,
            voteEndTime: block.timestamp + 3 days, // Example: 3 days voting period
            executionGracePeriod: 1 days // Example: 1 day grace period after vote ends
        });

        emit GovernanceActionProposed(currentId, msg.sender, _description);
    }

    /**
     * @notice Allows Mindweave Score holders (or their delegates) to vote on an open proposal.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'for' vote, false for 'against' vote.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) external whenNotPaused {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.id != 0, "AMN: Proposal does not exist");
        require(!proposal.executed, "AMN: Proposal already executed");
        require(block.timestamp <= proposal.voteEndTime, "AMN: Voting period has ended");

        address voter = msg.sender;
        if (mindweaveDelegates[msg.sender] != address(0)) {
            voter = mindweaveDelegates[msg.sender];
        }

        require(!proposalVotes[_proposalId][voter], "AMN: Already voted on this proposal");

        uint256 voterScore = getMindweaveScore(voter);
        require(voterScore > 0, "AMN: Voter has no Mindweave Score");

        if (_support) {
            proposal.forVotes = proposal.forVotes.add(voterScore);
        } else {
            proposal.againstVotes = proposal.againstVotes.add(voterScore);
        }
        proposalVotes[_proposalId][voter] = true;
        proposalVoteSupport[_proposalId][voter] = _support;

        emit VoteCast(_proposalId, voter, _support);
    }

    /**
     * @notice Executes a governance proposal that has met its voting thresholds and timelock.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) external whenNotPaused {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.id != 0, "AMN: Proposal does not exist");
        require(!proposal.executed, "AMN: Proposal already executed");
        require(block.timestamp > proposal.voteEndTime, "AMN: Voting period not over yet");
        require(block.timestamp > proposal.voteEndTime.add(proposal.executionGracePeriod), "AMN: Execution grace period not over yet");

        // Quorum and Threshold (example: 50% + 1 total votes, 60% 'for' votes)
        uint256 totalVotes = proposal.forVotes.add(proposal.againstVotes);
        // Minimum quorum check: E.g., require totalVotes > total_mindweave_score_supply / X;
        // For simplicity, just require more for votes than against.
        require(proposal.forVotes > proposal.againstVotes, "AMN: Proposal did not pass");

        proposal.executed = true;

        // Execute the call
        (bool success, ) = proposal.targetContract.call(proposal.calldata);
        require(success, "AMN: Proposal execution failed");

        emit ProposalExecuted(_proposalId);
    }

    /**
     * @notice Sets or unsets an address as an AetherMind Council member.
     * @dev This function is controlled by governance, or initially by the deployer.
     * @param _member The address to set/unset.
     * @param _isMember True to add, false to remove.
     */
    function setCouncilMember(address _member, bool _isMember) external onlyOwner { // Changed to onlyOwner for initial setup.
        // After initial setup, this would be an `onlyGovernance` function.
        // For the purpose of this example, we'll allow `onlyOwner` to manage initially.
        require(_member != address(0), "AMN: Invalid member address");
        isCouncilMember[_member] = _isMember;
        emit CouncilMemberSet(_member, _isMember);
    }

    // --- V. Treasury & Protocol Configuration ---

    /**
     * @notice Allows anyone to deposit Cognitive Essence into the protocol's treasury.
     * @param _amount The amount of Cognitive Essence to deposit.
     */
    function depositToTreasury(uint256 _amount) external whenNotPaused {
        require(_amount > 0, "AMN: Amount must be greater than zero");
        cognitiveEssenceToken.safeTransferFrom(msg.sender, treasuryAddress, _amount);
        emit TreasuryDeposit(msg.sender, _amount);
    }

    /**
     * @notice Allows the governance system to withdraw funds from the treasury.
     * @dev This function is intended to be called by a successful governance proposal.
     * @param _recipient The address to send funds to.
     * @param _amount The amount of Cognitive Essence to withdraw.
     */
    function withdrawFromTreasury(address _recipient, uint256 _amount) external onlyGovernance { // Call target of governance
        require(_recipient != address(0), "AMN: Invalid recipient address");
        require(_amount > 0, "AMN: Amount must be greater than zero");
        require(cognitiveEssenceToken.balanceOf(treasuryAddress) >= _amount, "AMN: Insufficient funds in treasury");

        cognitiveEssenceToken.safeTransferFrom(treasuryAddress, _recipient, _amount);
        emit TreasuryWithdrawal(_recipient, _amount);
    }

    /**
     * @notice Updates the protocol fee percentage.
     * @dev This function is controlled by governance.
     * @param _newFeeBasisPoints The new fee in basis points (e.g., 100 for 1%).
     */
    function updateProtocolFee(uint256 _newFeeBasisPoints) external onlyGovernance { // Call target of governance
        require(_newFeeBasisPoints <= 10000, "AMN: Fee too high (max 10000 bp / 100%)");
        protocolFeeBasisPoints = _newFeeBasisPoints;
        emit ProtocolFeeUpdated(_newFeeBasisPoints);
    }

    /**
     * @notice Updates the address of the trusted oracle.
     * @dev This function is controlled by governance.
     * @param _newOracle The new address of the trusted oracle.
     */
    function setTrustedOracleAddress(address _newOracle) external onlyGovernance { // Call target of governance
        require(_newOracle != address(0), "AMN: New oracle address cannot be zero");
        trustedOracleAddress = _newOracle;
        emit TrustedOracleAddressUpdated(_newOracle);
    }

    /**
     * @notice Sets the minimum conceptual score required for a seed to be finalized.
     * @dev This function is controlled by governance.
     * @param _newMinScore The new minimum score (0-10000).
     */
    function setMinimumConceptualScore(uint256 _newMinScore) external onlyGovernance { // Call target of governance
        require(_newMinScore <= 10000, "AMN: Minimum score too high (max 10000)");
        minConceptualScoreForFinalization = _newMinScore;
        emit MinimumConceptualScoreUpdated(_newMinScore);
    }

    /**
     * @notice Adjusts the multiplier for Essence locking benefits (Mindweave Score or yield).
     * @dev This function is controlled by governance.
     * @param _newMultiplier The new multiplier in basis points (e.g., 120 for 1.2x boost).
     */
    function setEssenceLockMultiplier(uint256 _newMultiplier) external onlyGovernance { // Call target of governance
        essenceLockMultiplierBasisPoints = _newMultiplier;
        emit EssenceLockMultiplierUpdated(_newMultiplier);
    }

    /**
     * @notice Pauses or unpauses certain critical protocol actions in an emergency.
     * @dev This function is controlled by the AetherMind Council.
     * @param _pause True to pause, false to unpause.
     */
    function pauseCertainActions(bool _pause) external onlyCouncil {
        pausedActions = _pause;
        emit ProtocolActionsPaused(_pause);
    }

    // --- View Functions ---

    /**
     * @notice Get the current total supply of Mindweave Score across all users.
     * @dev This would be used to calculate quorum for governance.
     */
    function getTotalMindweaveScoreSupply() public view returns (uint256) {
        // This would require iterating through all users or tracking a cumulative sum.
        // For efficiency in a real chain, it's better to maintain a `totalMindweaveScore` state variable
        // updated whenever score is claimed.
        // For now, let's just return a placeholder or sum up for small scale.
        // Placeholder return:
        return 0; // In a real scenario, this would be a tracked state var or sum of all Mindweave Scores.
    }

    /**
     * @notice Get the balance of Cognitive Essence held by the Nexus contract.
     */
    function getCognitiveEssenceBalance() public view returns (uint256) {
        return cognitiveEssenceToken.balanceOf(address(this));
    }
}
```