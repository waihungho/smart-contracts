This smart contract, named "AdaptiveDigitalCompanion (ADC) Manager," introduces a novel concept for dynamic Non-Fungible Tokens (NFTs). These ADCs are digital companions that evolve and adapt based on on-chain interactions, off-chain data (via a trusted oracle), and community-driven trait proposals. The ecosystem leverages a native token ($CTK, assumed to be an external ERC20) for staking, governance, and transactional fees, creating a self-sustaining and interactive digital pet/companion experience.

The core idea is to move beyond static NFTs by allowing ADCs to change their attributes, appearance (via dynamic metadata), and behavior pathways over time. This evolution is influenced by a combination of explicit user actions (feeding, evolving), ambient external factors (simulated "AI-driven" influence via oracle data), and a decentralized governance mechanism where the community can propose and vote on new potential traits for ADCs.

---

## **Smart Contract: AdaptiveDigitalCompanion (ADC) Manager**

**Outline & Function Summary:**

**I. Core ADC NFT Management (ERC721 Compliant & Dynamic)**
*   **`mintADC(uint256 dnaSeed)`**: Mints a new Adaptive Digital Companion (ADC) NFT for the caller, initializing it with a given DNA seed for unique initial traits.
*   **`tokenURI(uint256 tokenId)`**: Returns the URI for a given ADC's metadata. This URI points to an off-chain server that dynamically generates JSON metadata based on the ADC's current on-chain state (traits, level, etc.).
*   **`getADCTraits(uint256 tokenId)`**: Retrieves all current dynamic traits and their values for a specific ADC.

**II. Evolution & Oracle System**
*   **`evolveADC(uint256 tokenId)`**: Triggers the evolution process for an ADC, consuming resources (CTK tokens). Evolution is based on accumulated experience, feeding status, and current external factors.
*   **`feedADC(uint256 tokenId, uint256 amount)`**: Allows an ADC owner to provide "fuel" or "experience" to their ADC by depositing CTK tokens, which contributes to its well-being and evolution.
*   **`setOracleAddress(address _oracle)`**: Sets the address of the trusted oracle contract authorized to provide external data.
*   **`updateExternalFactor(bytes32 key, int256 value, uint256 timestamp)`**: (Oracle-Only) Allows the designated oracle to update an external factor that influences ADC evolution.
*   **`getExternalFactor(bytes32 key)`**: Retrieves the current value of a specific external factor.
*   **`queryEvolutionPreview(uint256 tokenId)`**: (View) Provides a read-only preview of potential evolution outcomes for an ADC based on its current state and external factors, without triggering actual evolution.

**III. Trait/DNA Curation & Voting (Decentralized Governance)**
*   **`submitTraitProposal(string memory traitName, string memory description, bytes memory metadataHash, uint256 submissionFee)`**: Allows any user to propose a new trait or evolutionary pathway for ADCs, paying a submission fee in CTK.
*   **`voteOnTraitProposal(uint256 proposalId, bool approve, uint256 voteWeight)`**: Enables CTK stakers to vote on open trait proposals. Vote weight is proportional to staked CTK.
*   **`finalizeTraitProposal(uint256 proposalId)`**: (Admin/DAO) Finalizes a trait proposal if it meets the voting quorum and approval threshold, making it an "Approved Trait."
*   **`getTraitProposal(uint256 proposalId)`**: Retrieves detailed information about a specific trait proposal.
*   **`getApprovedTraits()`**: (View) Returns a list of all traits that have been successfully approved by the community and can be incorporated into ADCs.

**IV. Companion Token ($CTK) Integration & Staking**
*   **`setCTKTokenAddress(address _ctkToken)`**: Sets the address of the external ERC20 Companion Token ($CTK) contract.
*   **`stakeCTK(uint256 amount)`**: Allows users to stake their CTK tokens to gain voting power for trait proposals and earn staking rewards.
*   **`unstakeCTK(uint256 amount)`**: Allows users to unstake their CTK tokens. A cooldown period might be implemented for security (not explicitly shown for brevity, but a common practice).
*   **`withdrawStakingRewards()`**: Allows stakers to claim their accumulated rewards, which can come from proposal submission fees or evolution fees.
*   **`getCTKStakedBalance(address staker)`**: (View) Returns the amount of CTK staked by a specific address.

**V. Maintenance & Administration**
*   **`setBaseEvolutionFee(uint256 _fee)`**: (Owner-Only) Sets the base fee (in CTK) required to initiate an ADC evolution.
*   **`pauseContract()`**: (Owner-Only) Pauses most contract functionalities in case of emergency or critical maintenance.
*   **`unpauseContract()`**: (Owner-Only) Unpauses the contract, restoring full functionality.
*   **`withdrawFees(address _tokenAddress, uint256 _amount)`**: (Owner-Only) Allows the owner to withdraw collected fees (e.g., proposal fees, evolution fees) in specified tokens.
*   **`setRoyaltyInfo(address _receiver, uint96 _feeNumerator)`**: (Owner-Only) Sets the ERC2981 royalty information for secondary sales of ADCs.
*   **`updateADCBaseURI(string memory _newURI)`**: (Owner-Only) Updates the base URI used for constructing dynamic `tokenURI`s.
*   **`renounceOwnership()`**: (Owner-Only) Relinquishes contract ownership.
*   **`transferOwnership(address newOwner)`**: (Owner-Only) Transfers contract ownership to a new address.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

/**
 * @title AdaptiveDigitalCompanion (ADC) Manager
 * @dev This contract manages a dynamic NFT ecosystem where digital companions (ADCs) evolve
 *      based on on-chain interactions, off-chain oracle data, and community-driven trait proposals.
 *      It integrates with an external ERC20 token ($CTK) for staking, fees, and governance.
 */
contract ADCManager is ERC721URIStorage, Ownable, Pausable, IERC2981 {
    using Counters for Counters.Counter;

    // --- State Variables ---

    // ADC NFT counter
    Counters.Counter private _adcIds;

    // Oracle address authorized to submit external factors
    address public oracleAddress;

    // Address of the external Companion Token (CTK) ERC20 contract
    IERC20 public ctkToken;

    // Base URI for ADC metadata, concatenated with tokenId for dynamic data
    string private _baseTokenURI;

    // Fees & Rewards
    uint256 public baseEvolutionFee; // Fee in CTK for evolving an ADC
    uint256 public proposalSubmissionFee; // Fee in CTK for submitting a trait proposal
    uint256 public constant MIN_VOTE_THRESHOLD_PERCENT = 51; // Minimum percentage of votes to pass
    uint256 public constant MIN_QUORUM_PERCENT = 10; // Minimum percentage of total staked CTK to vote

    // Staking for voting power
    mapping(address => uint256) public stakedCTK;
    uint256 public totalStakedCTK;
    mapping(address => uint256) public stakingRewards; // Rewards accrued for stakers

    // ERC2981 Royalties
    address public royaltyReceiver;
    uint96 public royaltyFeeNumerator; // Example: 250 for 2.5% (250/10000)

    // --- Enums ---

    enum TraitType {
        MOOD,
        VITALITY,
        INTELLIGENCE,
        CREATIVITY,
        ADAPTABILITY,
        LUCK,
        AURA // New custom traits can be added here
    }

    enum ProposalStatus {
        PENDING,
        APPROVED,
        REJECTED,
        FINALIZED
    }

    // --- Structs ---

    struct ADC {
        uint256 level;
        uint256 experience;
        uint256 lastFedTime; // Timestamp of last feeding
        mapping(TraitType => uint256) traits; // Dynamic traits
        uint256 dnaSeed; // Immutable initial seed
        uint256 lastEvolutionTime; // Timestamp of last evolution
    }

    struct TraitProposal {
        address proposer;
        string name;
        string description;
        bytes metadataHash; // IPFS hash or similar for external media/info
        uint256 upvotes;
        uint256 downvotes;
        uint256 totalVoteWeight; // Sum of staked CTK from all voters
        ProposalStatus status;
        uint256 submissionTime;
        mapping(address => bool) hasVoted; // Tracks if an address has voted on this proposal
    }

    struct ApprovedTrait {
        uint256 traitId;
        string name;
        bytes metadataHash;
        TraitType traitType; // The type of trait this approved trait modifies
        uint256 valueMin; // Min value for this trait if applied
        uint256 valueMax; // Max value for this trait if applied
        uint256 creationTime;
    }

    // --- Mappings ---

    // Mapping of tokenId to ADC struct
    mapping(uint256 => ADC) public adcs;

    // Mapping of external factor key to its value and last update timestamp
    mapping(bytes32 => int256) public externalFactors;
    mapping(bytes32 => uint256) public externalFactorLastUpdate;

    // Trait Proposals
    Counters.Counter public nextProposalId;
    mapping(uint256 => TraitProposal) public traitProposals;

    // Approved Traits
    Counters.Counter public nextApprovedTraitId;
    mapping(uint256 => ApprovedTrait) public approvedTraits;
    uint256[] public approvedTraitIds; // To iterate over approved traits

    // --- Events ---

    event ADCMinteed(uint256 indexed tokenId, address indexed owner, uint256 dnaSeed);
    event ADCChanged(uint256 indexed tokenId, uint256 newLevel, uint256 newXP);
    event ADCFeed(uint256 indexed tokenId, address indexed feeder, uint256 amount);
    event ADCEvolved(uint256 indexed tokenId, uint256 newLevel, uint256 time);
    event ExternalFactorUpdated(bytes32 indexed key, int256 value, uint256 timestamp);
    event TraitProposalSubmitted(uint256 indexed proposalId, address indexed proposer, string name);
    event TraitProposalVoted(uint256 indexed proposalId, address indexed voter, bool approved, uint256 voteWeight);
    event TraitProposalFinalized(uint256 indexed proposalId, ProposalStatus newStatus);
    event CTKStaked(address indexed staker, uint256 amount);
    event CTKUnstaked(address indexed staker, uint256 amount);
    event StakingRewardsWithdrawn(address indexed staker, uint256 amount);
    event RoyaltyInfoUpdated(address indexed receiver, uint96 feeNumerator);

    // --- Modifiers ---

    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "Caller is not the oracle");
        _;
    }

    // --- Constructor ---

    constructor(address _ctkTokenAddress, address _oracleAddress, string memory _name, string memory _symbol)
        ERC721(_name, _symbol)
        ERC721URIStorage()
        Ownable(msg.sender)
    {
        require(_ctkTokenAddress != address(0), "CTK Token address cannot be zero");
        require(_oracleAddress != address(0), "Oracle address cannot be zero");

        ctkToken = IERC20(_ctkTokenAddress);
        oracleAddress = _oracleAddress;
        _baseTokenURI = "https://adcs.xyz/metadata/"; // Example base URI
        baseEvolutionFee = 10 ether; // Example: 10 CTK
        proposalSubmissionFee = 1 ether; // Example: 1 CTK
        royaltyFeeNumerator = 250; // 2.5%
        royaltyReceiver = msg.sender;
    }

    // --- I. Core ADC NFT Management ---

    /**
     * @dev Mints a new Adaptive Digital Companion (ADC) NFT.
     * @param dnaSeed An initial seed for pseudo-random trait generation.
     */
    function mintADC(uint256 dnaSeed) public whenNotPaused returns (uint256) {
        _adcIds.increment();
        uint256 newItemId = _adcIds.current();

        _mint(msg.sender, newItemId);
        _setTokenURI(newItemId, string(abi.encodePacked(_baseTokenURI, Strings.toString(newItemId))));

        ADC storage newADC = adcs[newItemId];
        newADC.dnaSeed = dnaSeed;
        newADC.level = 1;
        newADC.experience = 0;
        newADC.lastFedTime = block.timestamp;
        newADC.lastEvolutionTime = block.timestamp;

        // Initialize some base traits based on dnaSeed (simplified)
        newADC.traits[TraitType.MOOD] = (dnaSeed % 100) + 1; // 1-100
        newADC.traits[TraitType.VITALITY] = ((dnaSeed / 100) % 100) + 50; // 50-150

        emit ADCMinteed(newItemId, msg.sender, dnaSeed);
        return newItemId;
    }

    /**
     * @dev Returns the URI for a given ADC's metadata.
     *      This URI points to an off-chain server that dynamically generates JSON metadata.
     *      The server queries `getADCTraits` and other on-chain data to construct the metadata.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return _tokenURIs[tokenId];
    }

    /**
     * @dev Retrieves all current dynamic traits and their values for a specific ADC.
     * @param tokenId The ID of the ADC.
     * @return An array of trait types and an array of their corresponding values.
     */
    function getADCTraits(uint256 tokenId) public view returns (TraitType[] memory, uint256[] memory) {
        require(_exists(tokenId), "ADCManager: Token does not exist");
        ADC storage adc = adcs[tokenId];

        TraitType[] memory traitTypes = new TraitType[](7); // Assuming 7 trait types
        uint256[] memory traitValues = new uint256[](7);

        traitTypes[0] = TraitType.MOOD; traitValues[0] = adc.traits[TraitType.MOOD];
        traitTypes[1] = TraitType.VITALITY; traitValues[1] = adc.traits[TraitType.VITALITY];
        traitTypes[2] = TraitType.INTELLIGENCE; traitValues[2] = adc.traits[TraitType.INTELLIGENCE];
        traitTypes[3] = TraitType.CREATIVITY; traitValues[3] = adc.traits[TraitType.CREATIVITY];
        traitTypes[4] = TraitType.ADAPTABILITY; traitValues[4] = adc.traits[TraitType.ADAPTABILITY];
        traitTypes[5] = TraitType.LUCK; traitValues[5] = adc.traits[TraitType.LUCK];
        traitTypes[6] = TraitType.AURA; traitValues[6] = adc.traits[TraitType.AURA];

        return (traitTypes, traitValues);
    }

    // --- II. Evolution & Oracle System ---

    /**
     * @dev Triggers the evolution process for an ADC.
     *      Evolution consumes CTK tokens and is influenced by accumulated experience,
     *      feeding status, and external factors.
     * @param tokenId The ID of the ADC to evolve.
     */
    function evolveADC(uint256 tokenId) public whenNotPaused {
        require(_exists(tokenId), "ADCManager: Token does not exist");
        require(ownerOf(tokenId) == msg.sender, "ADCManager: Only owner can evolve ADC");
        require(ctkToken.balanceOf(msg.sender) >= baseEvolutionFee, "ADCManager: Insufficient CTK for evolution");

        ADC storage adc = adcs[tokenId];
        require(adc.experience >= adc.level * 100, "ADCManager: Not enough experience for evolution"); // Example XP logic
        require(block.timestamp - adc.lastFedTime < 7 days, "ADCManager: ADC needs to be fed recently to evolve"); // Example feeding logic
        require(block.timestamp - adc.lastEvolutionTime >= 30 days, "ADCManager: ADC can only evolve every 30 days"); // Cooldown

        // Transfer evolution fee to contract
        require(ctkToken.transferFrom(msg.sender, address(this), baseEvolutionFee), "CTK transfer failed");

        // Simulate evolution logic
        // This is where 'AI-driven' influence comes in, by using externalFactors
        int256 marketSentiment = externalFactors[keccak256(abi.encodePacked("MARKET_SENTIMENT"))];
        uint256 evolutionBoost = 0;
        if (marketSentiment > 50) { // Example: positive sentiment gives a boost
            evolutionBoost = 10;
        } else if (marketSentiment < -50) { // Example: negative sentiment can hinder
            evolutionBoost = 0; // or even reduce stats
        }

        adc.level += 1;
        adc.experience = 0; // Reset XP for new level

        // Apply a random approved trait if available and influenced by external factor
        if (approvedTraitIds.length > 0 && evolutionBoost > 5) {
            uint256 randomIndex = (adc.dnaSeed + adc.level + block.timestamp) % approvedTraitIds.length;
            ApprovedTrait storage approvedTrait = approvedTraits[approvedTraitIds[randomIndex]];
            uint256 traitIncrease = (approvedTrait.valueMax - approvedTrait.valueMin) / 2; // Simple avg increase
            adc.traits[approvedTrait.traitType] += traitIncrease;
        } else {
             // Default trait increase if no approved trait is applied
             adc.traits[TraitType.VITALITY] += 5;
             adc.traits[TraitType.MOOD] += 2;
        }

        adc.lastEvolutionTime = block.timestamp;

        emit ADCEvolved(tokenId, adc.level, block.timestamp);
        emit ADCChanged(tokenId, adc.level, adc.experience);
    }

    /**
     * @dev Allows an ADC owner to provide "fuel" or "experience" to their ADC by depositing CTK tokens.
     *      This contributes to its well-being and evolution.
     * @param tokenId The ID of the ADC to feed.
     * @param amount The amount of CTK tokens to feed.
     */
    function feedADC(uint256 tokenId, uint256 amount) public whenNotPaused {
        require(_exists(tokenId), "ADCManager: Token does not exist");
        require(ownerOf(tokenId) == msg.sender, "ADCManager: Only owner can feed ADC");
        require(amount > 0, "ADCManager: Feed amount must be greater than zero");
        require(ctkToken.balanceOf(msg.sender) >= amount, "ADCManager: Insufficient CTK to feed ADC");

        // Transfer CTK to contract
        require(ctkToken.transferFrom(msg.sender, address(this), amount), "CTK transfer failed");

        ADC storage adc = adcs[tokenId];
        adc.experience += amount / (1 ether); // Example: 1 CTK = 1 XP
        adc.lastFedTime = block.timestamp;
        adc.traits[TraitType.MOOD] += 1; // Slight mood boost for feeding

        emit ADCFeed(tokenId, msg.sender, amount);
        emit ADCChanged(tokenId, adc.level, adc.experience);
    }

    /**
     * @dev Sets the address of the trusted oracle contract.
     * @param _oracle The new oracle address.
     */
    function setOracleAddress(address _oracle) public onlyOwner {
        require(_oracle != address(0), "ADCManager: Oracle address cannot be zero");
        oracleAddress = _oracle;
    }

    /**
     * @dev (Oracle-Only) Allows the designated oracle to update an external factor
     *      that influences ADC evolution.
     * @param key A unique identifier for the external factor (e.g., hash of "MARKET_SENTIMENT").
     * @param value The new integer value of the external factor.
     * @param timestamp The timestamp of when this factor was updated.
     */
    function updateExternalFactor(bytes32 key, int256 value, uint256 timestamp) public onlyOracle whenNotPaused {
        externalFactors[key] = value;
        externalFactorLastUpdate[key] = timestamp;
        emit ExternalFactorUpdated(key, value, timestamp);
    }

    /**
     * @dev Retrieves the current value of a specific external factor.
     * @param key The unique identifier for the external factor.
     * @return The integer value of the factor.
     */
    function getExternalFactor(bytes32 key) public view returns (int256) {
        return externalFactors[key];
    }

    /**
     * @dev (View) Provides a read-only preview of potential evolution outcomes for an ADC
     *      based on its current state and external factors, without triggering actual evolution.
     * @param tokenId The ID of the ADC.
     * @return A string describing the potential evolution.
     */
    function queryEvolutionPreview(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "ADCManager: Token does not exist");
        ADC storage adc = adcs[tokenId];

        if (adc.experience < adc.level * 100) {
            return "More experience needed.";
        }
        if (block.timestamp - adc.lastFedTime >= 7 days) {
            return "ADC needs to be fed recently.";
        }
        if (block.timestamp - adc.lastEvolutionTime < 30 days) {
            return string(abi.encodePacked("Evolution cooldown active. Next evolution possible in ", Strings.toString(30 days - (block.timestamp - adc.lastEvolutionTime)), " seconds."));
        }

        int256 marketSentiment = externalFactors[keccak256(abi.encodePacked("MARKET_SENTIMENT"))];
        string memory sentimentDesc;
        if (marketSentiment > 50) {
            sentimentDesc = "Positive market sentiment: Likely to gain a new trait.";
        } else if (marketSentiment < -50) {
            sentimentDesc = "Negative market sentiment: Evolution might be more challenging.";
        } else {
            sentimentDesc = "Neutral market sentiment: Standard evolution expected.";
        }

        return string(abi.encodePacked("Ready for evolution! Next level: ", Strings.toString(adc.level + 1), ". ", sentimentDesc));
    }


    // --- III. Trait/DNA Curation & Voting ---

    /**
     * @dev Allows any user to propose a new trait or evolutionary pathway for ADCs.
     *      Requires a submission fee in CTK.
     * @param traitName The name of the proposed trait.
     * @param description A detailed description of the trait.
     * @param metadataHash IPFS hash or similar for external media/info related to the trait.
     * @param submissionFee The CTK fee for submitting this proposal.
     */
    function submitTraitProposal(
        string memory traitName,
        string memory description,
        bytes memory metadataHash,
        uint256 submissionFee
    ) public whenNotPaused {
        require(submissionFee >= proposalSubmissionFee, "ADCManager: Submission fee too low");
        require(ctkToken.transferFrom(msg.sender, address(this), submissionFee), "CTK transfer failed for proposal");

        nextProposalId.increment();
        uint256 proposalId = nextProposalId.current();

        TraitProposal storage proposal = traitProposals[proposalId];
        proposal.proposer = msg.sender;
        proposal.name = traitName;
        proposal.description = description;
        proposal.metadataHash = metadataHash;
        proposal.status = ProposalStatus.PENDING;
        proposal.submissionTime = block.timestamp;

        // Reward the proposer with a small amount of XP for a specific ADC if they own one? (Future enhancement)

        emit TraitProposalSubmitted(proposalId, msg.sender, traitName);
    }

    /**
     * @dev Enables CTK stakers to vote on open trait proposals.
     *      Vote weight is proportional to staked CTK.
     * @param proposalId The ID of the proposal to vote on.
     * @param approve True for an 'upvote', false for a 'downvote'.
     * @param voteWeight The amount of CTK the staker wants to use as vote weight.
     */
    function voteOnTraitProposal(uint256 proposalId, bool approve, uint256 voteWeight) public whenNotPaused {
        require(traitProposals[proposalId].proposer != address(0), "ADCManager: Proposal does not exist");
        TraitProposal storage proposal = traitProposals[proposalId];
        require(proposal.status == ProposalStatus.PENDING, "ADCManager: Proposal is not open for voting");
        require(!proposal.hasVoted[msg.sender], "ADCManager: Already voted on this proposal");
        require(stakedCTK[msg.sender] >= voteWeight, "ADCManager: Insufficient staked CTK for vote weight");
        require(totalStakedCTK > 0, "ADCManager: No CTK staked to form quorum");
        require((voteWeight * 100) / totalStakedCTK >= MIN_QUORUM_PERCENT, "ADCManager: Vote weight too low for quorum");

        if (approve) {
            proposal.upvotes += voteWeight;
        } else {
            proposal.downvotes += voteWeight;
        }
        proposal.totalVoteWeight += voteWeight;
        proposal.hasVoted[msg.sender] = true;

        // Accrue a small reward for voting (e.g., from submission fees)
        stakingRewards[msg.sender] += voteWeight / 1000; // Example: 0.1% of vote weight as reward

        emit TraitProposalVoted(proposalId, msg.sender, approve, voteWeight);
    }

    /**
     * @dev (Owner-Only) Finalizes a trait proposal if it meets the voting quorum and approval threshold,
     *      making it an "Approved Trait."
     * @param proposalId The ID of the proposal to finalize.
     */
    function finalizeTraitProposal(uint256 proposalId) public onlyOwner whenNotPaused {
        require(traitProposals[proposalId].proposer != address(0), "ADCManager: Proposal does not exist");
        TraitProposal storage proposal = traitProposals[proposalId];
        require(proposal.status == ProposalStatus.PENDING, "ADCManager: Proposal already finalized or not pending");
        require(proposal.totalVoteWeight > 0, "ADCManager: No votes cast for this proposal");
        require((proposal.totalVoteWeight * 100) / totalStakedCTK >= MIN_QUORUM_PERCENT, "ADCManager: Quorum not met");

        if ((proposal.upvotes * 100) / proposal.totalVoteWeight >= MIN_VOTE_THRESHOLD_PERCENT) {
            // Proposal approved
            proposal.status = ProposalStatus.APPROVED;
            nextApprovedTraitId.increment();
            uint256 approvedId = nextApprovedTraitId.current();

            // Create a new ApprovedTrait (simplified, in a real scenario this would have more specific data)
            approvedTraits[approvedId] = ApprovedTrait({
                traitId: approvedId,
                name: proposal.name,
                metadataHash: proposal.metadataHash,
                traitType: TraitType.ADAPTABILITY, // Example: All approved traits might boost adaptability or a specific type
                valueMin: 10,
                valueMax: 50,
                creationTime: block.timestamp
            });
            approvedTraitIds.push(approvedId); // Add to dynamic array for iteration
        } else {
            proposal.status = ProposalStatus.REJECTED;
        }

        emit TraitProposalFinalized(proposalId, proposal.status);
    }

    /**
     * @dev Retrieves detailed information about a specific trait proposal.
     * @param proposalId The ID of the proposal.
     * @return A tuple containing proposal details.
     */
    function getTraitProposal(uint256 proposalId)
        public
        view
        returns (
            address proposer,
            string memory name,
            string memory description,
            bytes memory metadataHash,
            uint256 upvotes,
            uint256 downvotes,
            uint256 totalVoteWeight,
            ProposalStatus status,
            uint256 submissionTime
        )
    {
        TraitProposal storage proposal = traitProposals[proposalId];
        return (
            proposal.proposer,
            proposal.name,
            proposal.description,
            proposal.metadataHash,
            proposal.upvotes,
            proposal.downvotes,
            proposal.totalVoteWeight,
            proposal.status,
            proposal.submissionTime
        );
    }

    /**
     * @dev (View) Returns a list of all traits that have been successfully approved by the community
     *      and can be incorporated into ADCs.
     * @return An array of ApprovedTrait structs.
     */
    function getApprovedTraits() public view returns (ApprovedTrait[] memory) {
        ApprovedTrait[] memory _approvedTraits = new ApprovedTrait[](approvedTraitIds.length);
        for (uint256 i = 0; i < approvedTraitIds.length; i++) {
            _approvedTraits[i] = approvedTraits[approvedTraitIds[i]];
        }
        return _approvedTraits;
    }

    // --- IV. Companion Token ($CTK) Integration & Staking ---

    /**
     * @dev Sets the address of the external ERC20 Companion Token ($CTK) contract.
     * @param _ctkToken The address of the CTK token.
     */
    function setCTKTokenAddress(address _ctkToken) public onlyOwner {
        require(_ctkToken != address(0), "ADCManager: CTK Token address cannot be zero");
        ctkToken = IERC20(_ctkToken);
    }

    /**
     * @dev Allows users to stake their CTK tokens to gain voting power for trait proposals
     *      and earn potential staking rewards.
     * @param amount The amount of CTK to stake.
     */
    function stakeCTK(uint256 amount) public whenNotPaused {
        require(amount > 0, "ADCManager: Stake amount must be greater than zero");
        require(ctkToken.transferFrom(msg.sender, address(this), amount), "CTK transfer failed for staking");

        stakedCTK[msg.sender] += amount;
        totalStakedCTK += amount;

        emit CTKStaked(msg.sender, amount);
    }

    /**
     * @dev Allows users to unstake their CTK tokens.
     *      A cooldown period could be implemented for security (not implemented for brevity).
     * @param amount The amount of CTK to unstake.
     */
    function unstakeCTK(uint256 amount) public whenNotPaused {
        require(amount > 0, "ADCManager: Unstake amount must be greater than zero");
        require(stakedCTK[msg.sender] >= amount, "ADCManager: Insufficient staked CTK");

        stakedCTK[msg.sender] -= amount;
        totalStakedCTK -= amount;

        require(ctkToken.transfer(msg.sender, amount), "CTK transfer failed for unstaking");

        emit CTKUnstaked(msg.sender, amount);
    }

    /**
     * @dev Allows stakers to claim their accumulated rewards, which can come from
     *      proposal submission fees or evolution fees.
     */
    function withdrawStakingRewards() public whenNotPaused {
        uint256 rewards = stakingRewards[msg.sender];
        require(rewards > 0, "ADCManager: No rewards to withdraw");
        stakingRewards[msg.sender] = 0; // Reset rewards before transfer

        require(ctkToken.transfer(msg.sender, rewards), "CTK reward transfer failed");

        emit StakingRewardsWithdrawn(msg.sender, rewards);
    }

    /**
     * @dev (View) Returns the amount of CTK staked by a specific address.
     * @param staker The address of the staker.
     * @return The staked amount.
     */
    function getCTKStakedBalance(address staker) public view returns (uint256) {
        return stakedCTK[staker];
    }

    // --- V. Maintenance & Administration ---

    /**
     * @dev (Owner-Only) Sets the base fee (in CTK) required to initiate an ADC evolution.
     * @param _fee The new base evolution fee.
     */
    function setBaseEvolutionFee(uint256 _fee) public onlyOwner {
        baseEvolutionFee = _fee;
    }

    /**
     * @dev (Owner-Only) Pauses most contract functionalities in case of emergency or critical maintenance.
     */
    function pauseContract() public onlyOwner {
        _pause();
    }

    /**
     * @dev (Owner-Only) Unpauses the contract, restoring full functionality.
     */
    function unpauseContract() public onlyOwner {
        _unpause();
    }

    /**
     * @dev (Owner-Only) Allows the owner to withdraw collected fees (e.g., proposal fees, evolution fees)
     *      in specified tokens.
     * @param _tokenAddress The address of the token to withdraw (e.g., CTK token address).
     * @param _amount The amount of tokens to withdraw.
     */
    function withdrawFees(address _tokenAddress, uint256 _amount) public onlyOwner {
        require(_tokenAddress != address(0), "ADCManager: Token address cannot be zero");
        IERC20 token = IERC20(_tokenAddress);
        require(token.balanceOf(address(this)) >= _amount, "ADCManager: Insufficient balance in contract");
        require(token.transfer(msg.sender, _amount), "Token transfer failed");
    }

    /**
     * @dev (Owner-Only) Sets the ERC2981 royalty information for secondary sales of ADCs.
     * @param _receiver The address to receive royalties.
     * @param _feeNumerator The numerator for the royalty fee (e.g., 250 for 2.5%). Denominator is 10000.
     */
    function setRoyaltyInfo(address _receiver, uint96 _feeNumerator) public onlyOwner {
        require(_receiver != address(0), "ADCManager: Royalty receiver cannot be zero");
        royaltyReceiver = _receiver;
        royaltyFeeNumerator = _feeNumerator;
        emit RoyaltyInfoUpdated(_receiver, _feeNumerator);
    }

    /**
     * @dev Implementation of ERC2981 `royaltyInfo` function.
     *      Returns royalty payment information for a given tokenId and sale price.
     * @param _tokenId The ID of the NFT.
     * @param _salePrice The sale price of the NFT.
     * @return receiver The address to send royalty payments to.
     * @return royaltyAmount The amount of royalty payment.
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        // Require _tokenId to exist if specific per-token royalties were implemented.
        // For contract-wide royalties, this check isn't strictly necessary.
        if (royaltyReceiver == address(0) || royaltyFeeNumerator == 0) {
            return (address(0), 0);
        }
        return (royaltyReceiver, (_salePrice * royaltyFeeNumerator) / 10000);
    }


    /**
     * @dev (Owner-Only) Updates the base URI used for constructing dynamic `tokenURI`s.
     * @param _newURI The new base URI.
     */
    function updateADCBaseURI(string memory _newURI) public onlyOwner {
        _baseTokenURI = _newURI;
    }

    /**
     * @dev See {ERC721-supportsInterface}.
     *      Adds support for ERC2981 (Royalties).
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, IERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    // The following functions are inherited from OpenZeppelin contracts:
    // Ownable: `renounceOwnership()`, `transferOwnership(address newOwner)`
    // Pausable: `paused()`
    // ERC721: `balanceOf()`, `ownerOf()`, `approve()`, `getApproved()`, `setApprovalForAll()`, `isApprovedForAll()`, `transferFrom()`, `safeTransferFrom()`
    // ERC721URIStorage: `_setTokenURI()` (internal), `_burn()` (internal)
}
```