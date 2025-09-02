```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Outline and Function Summary for AetherLoomProtocol

// Core Concept:
// AetherLoom is a decentralized protocol for minting and evolving dynamic NFTs called "AetherGems."
// AetherGems possess "latent traits" that can change over time, through user interaction (Weavers),
// and are influenced by a simulated AI oracle providing "Aetheric Flux" data.
// The protocol incorporates a reputation system for its participants ("AetherWeavers")
// and features adaptive pricing based on network activity and Aetheric Flux.
// It aims to create a living, evolving on-chain art ecosystem.

// External Dependencies:
// - IERC721: For AetherGem NFT functionality (implemented via OpenZeppelin ERC721).
// - IERC20: For the Essence utility token.
// - Ownable (OpenZeppelin): For basic ownership management.
// - Counters (OpenZeppelin): For safe token ID and proposal ID management.
// - SafeMath (OpenZeppelin): For safe arithmetic operations (though mostly replaced by native Solidity 0.8+ checks).

// Data Structures:
// - AetherGem: Stores detailed information about each dynamic NFT, including its traits and evolution history.
//   - tokenId: Unique identifier for the NFT.
//   - owner: Address of the current owner.
//   - mintTimestamp: Unix timestamp when the Gem was minted.
//   - lastEvolvedTimestamp: Unix timestamp of the last evolution.
//   - evolutionCount: Number of times the Gem has evolved.
//   - baseTraits: Immutable initial traits, a fundamental aspect of the Gem.
//   - currentTraits: Evolvable traits, represented as an array of uint256 (e.g., packed trait values).
//   - metadataURI: IPFS or other URI for external metadata.
//   - generationSeed: A unique seed for off-chain generative art interpretation.
//
// - AetherWeaver: Stores information about registered users, including their reputation and staked Essence.
//   - isRegistered: Boolean indicating active Weaver status.
//   - reputationScore: A score reflecting the Weaver's positive contributions/activity.
//   - stakedEssence: Amount of Essence token staked by the Weaver.
//   - registrationTimestamp: Unix timestamp when the Weaver registered.
//   - metadataURI: Optional public profile URI for the Weaver.
//
// - TraitProposal: Manages community proposals for new traits that can be discovered/integrated into AetherGems.
//   - proposer: Address of the Weaver who submitted the proposal.
//   - descriptionURI: URI linking to the detailed description or visual concept of the proposed trait.
//   - startTime: Unix timestamp when the voting period began.
//   - endTime: Unix timestamp when the voting period ends.
//   - votesFor: Number of positive votes.
//   - votesAgainst: Number of negative votes.
//   - isActive: Boolean indicating if the proposal is currently in the voting phase.
//   - isApproved: Boolean indicating if the proposal passed the vote and is finalized.
//   - essenceStake: Essence staked by the proposer.

// State Variables:
// - essenceToken: Address of the ERC20 Essence token.
// - aiOracleAddress: Trusted address for updating Aetheric Flux.
// - currentAethericFlux: The latest data point from the AI oracle (range 0-10000, representing 0.00% to 100.00%).
// - protocolFeesAccrued: Total fees collected in Essence.
// - baseMintCost: Initial cost for minting an AetherGem (in Essence).
// - evolutionCostMultiplier: Multiplier for calculating AetherGem evolution costs (e.g., 100 = 1x).
// - weaverRegistrationStake: Amount of Essence required to become a Weaver.
// - nextTraitId: Counter for new trait proposals.
// - protocolActive: Boolean to pause/unpause core protocol functions.

// Events:
// - AetherGemMinted(uint256 indexed tokenId, address indexed owner, string metadataURI, bytes32 generationSeed): Fired when a new AetherGem is minted.
// - AetherGemEvolved(uint256 indexed tokenId, address indexed owner, uint256[] newTraits, uint256 evolutionCount): Fired when an AetherGem's traits are updated.
// - WeaverRegistered(address indexed weaver, uint256 stakedAmount, uint256 reputationScore): Fired when an address registers as a Weaver.
// - WeaverDeregistered(address indexed weaver, uint256 unstakedAmount): Fired when a Weaver deregisters.
// - WeaverReputationUpdated(address indexed weaver, uint256 newReputation): Fired when a Weaver's reputation changes.
// - AethericFluxUpdated(uint256 newFlux): Fired when the AI oracle updates the flux.
// - TraitProposed(uint256 indexed proposalId, address indexed proposer, string descriptionURI, uint256 endTime): Fired when a new trait proposal is submitted.
// - TraitVoted(uint256 indexed proposalId, address indexed voter, bool support): Fired when a vote is cast on a trait proposal.
// - TraitProposalFinalized(uint256 indexed proposalId, bool approved): Fired when a trait proposal's voting period ends and it's finalized.
// - TraitDiscoveryRewardClaimed(uint256 indexed proposalId, address indexed claimant, uint256 rewardAmount): Fired when rewards are claimed for a successful trait discovery.
// - ProtocolFeesWithdrawn(address indexed recipient, uint256 amount): Fired when protocol fees are withdrawn.

// Modifiers:
// - onlyAIOracle(): Restricts access to the designated AI oracle address.
// - onlyWeaver(): Restricts access to registered AetherWeavers.
// - whenProtocolActive(): Ensures the function only runs if the protocol is active.

// --- Function Summary ---

// I. Protocol Management (Owner/Admin)
// 1. setAIOracleAddress(address _newOracle): Sets the trusted address for the AI oracle.
// 2. setEssenceTokenAddress(address _essenceToken): Sets the address of the ERC20 Essence token.
// 3. updateBaseMintCost(uint256 _newCost): Updates the base cost for minting AetherGems.
// 4. updateEvolutionCostMultiplier(uint256 _newMultiplier): Adjusts the multiplier for AetherGem evolution costs.
// 5. toggleProtocolActive(bool _status): Pauses or unpauses core protocol functionalities.
// 6. withdrawProtocolFees(): Allows the owner to withdraw accumulated Essence fees.

// II. AI Oracle Integration
// 7. updateAethericFlux(uint256 _newFlux): (Only AI Oracle) Updates the global Aetheric Flux value.
// 8. getCurrentAethericFlux(): Retrieves the current Aetheric Flux value.

// III. AetherWeaver Management
// 9. registerWeaver(): Allows users to become AetherWeavers by staking Essence.
// 10. deregisterWeaver(): Allows AetherWeavers to unstake Essence and deregister (with cooldown/penalty).
// 11. updateWeaverMetadataURI(string calldata _newURI): Updates an AetherWeaver's public profile URI.
// 12. getWeaverReputation(address _weaver): Retrieves the reputation score of a specific AetherWeaver.

// IV. AetherGem (Dynamic NFT) Operations
// 13. mintAetherGem(string calldata _initialMetadataURI, bytes32 _generationSeed, uint256[] calldata _baseTraits): Mints a new AetherGem.
// 14. evolveAetherGem(uint256 _tokenId, uint256[] calldata _newTraitParams): Evolves an existing AetherGem, potentially changing its traits.
// 15. getAetherGemTraits(uint256 _tokenId): Retrieves the current evolvable traits of an AetherGem.
// 16. predictGemEvolutionOutcome(uint256 _tokenId): (View) Simulates and predicts potential evolution outcomes based on current flux.
// 17. transferFrom(address _from, address _to, uint256 _tokenId): Standard ERC721 transfer function.
// 18. approve(address _to, uint256 _tokenId): Standard ERC721 approve function.
// 19. getApproved(uint256 _tokenId): Standard ERC721 getApproved function.
// 20. isApprovedForAll(address _owner, address _operator): Standard ERC721 isApprovedForAll function.
// 21. setApprovalForAll(address _operator, bool _approved): Standard ERC721 setApprovalForAll function.
// 22. balanceOf(address _owner): Standard ERC721 balanceOf function.
// 23. ownerOf(uint256 _tokenId): Standard ERC721 ownerOf function.
// 24. tokenURI(uint256 _tokenId): Returns the metadata URI for an AetherGem.

// V. Reputation & Discovery System
// 25. proposeTraitDiscovery(string calldata _descriptionURI, uint256 _proposalEssenceStake, uint256 _votingPeriodDays): Allows Weavers to propose new traits for discovery.
// 26. voteOnTraitProposal(uint256 _proposalId, bool _support): Allows Weavers to vote on active trait proposals.
// 27. finalizeTraitProposal(uint256 _proposalId): Finalizes a trait proposal after its voting period ends.
// 28. claimTraitDiscoveryReward(uint256 _proposalId): Allows the proposer of a successful trait to claim rewards.
// 29. challengeWeaverReputation(address _targetWeaver, string calldata _reasonURI): (Simulated) Allows challenging a Weaver's reputation, impacting their score.

// VI. Dynamic Pricing & Utility
// 30. getDynamicMintCost(): (View) Calculates the current minting cost based on base cost and Aetheric Flux.
// 31. getDynamicEvolutionCost(uint256 _tokenId): (View) Calculates the current evolution cost for a specific AetherGem.
// 32. getRequiredWeaverStake(): (View) Returns the current Essence stake required to register as a Weaver.

contract AetherLoomProtocol is ERC721, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- State Variables ---

    IERC20 public essenceToken;
    address public aiOracleAddress;
    uint256 public currentAethericFlux; // Represents AI insights, 0-10000 (0.00% to 100.00%)
    uint256 public protocolFeesAccrued;

    uint256 public baseMintCost; // In Essence tokens, adjusted dynamically
    uint256 public evolutionCostMultiplier; // e.g., 100 = 1x, 200 = 2x
    uint256 public weaverRegistrationStake; // Amount of Essence to stake for Weaver status
    uint256 public constant MIN_WEAVER_REPUTATION = 100; // Minimum reputation to perform certain actions
    uint256 public constant WEAVER_REPUTATION_INCREMENT = 10;
    uint256 public constant WEAVER_REPUTATION_DECREMENT = 20;
    uint256 public constant TRAIT_PROPOSAL_VOTING_THRESHOLD = 50; // Minimum votes required
    uint256 public constant TRAIT_PROPOSAL_REWARD_PERCENT = 10; // % of staked Essence rewarded

    bool public protocolActive = true;

    // --- Data Structures ---

    struct AetherGem {
        uint256 mintTimestamp;
        uint256 lastEvolvedTimestamp;
        uint256 evolutionCount;
        uint256[] baseTraits; // Immutable, initial traits
        uint256[] currentTraits; // Evolvable traits (e.g., packed uints)
        string metadataURI;
        bytes32 generationSeed;
    }

    struct AetherWeaver {
        bool isRegistered;
        uint256 reputationScore;
        uint256 stakedEssence;
        uint256 registrationTimestamp;
        string metadataURI;
    }

    struct TraitProposal {
        address proposer;
        string descriptionURI;
        uint256 startTime;
        uint256 endTime;
        uint256 votesFor;
        uint256 votesAgainst;
        bool isActive;
        bool isApproved;
        uint256 essenceStake;
        mapping(address => bool) hasVoted; // Tracks if a weaver has voted
    }

    // --- Mappings ---

    mapping(uint256 => AetherGem) public aetherGems;
    mapping(address => AetherWeaver) public aetherWeavers;
    mapping(uint256 => TraitProposal) public traitProposals;

    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _proposalIdCounter;

    // --- Events ---

    event AetherGemMinted(uint256 indexed tokenId, address indexed owner, string metadataURI, bytes32 generationSeed, uint256[] initialTraits);
    event AetherGemEvolved(uint256 indexed tokenId, address indexed owner, uint256[] newTraits, uint256 evolutionCount);
    event WeaverRegistered(address indexed weaver, uint256 stakedAmount, uint256 reputationScore);
    event WeaverDeregistered(address indexed weaver, uint224 unstakedAmount);
    event WeaverReputationUpdated(address indexed weaver, uint256 newReputation);
    event AethericFluxUpdated(uint256 newFlux);
    event TraitProposed(uint256 indexed proposalId, address indexed proposer, string descriptionURI, uint256 endTime);
    event TraitVoted(uint256 indexed proposalId, address indexed voter, bool support);
    event TraitProposalFinalized(uint256 indexed proposalId, bool approved);
    event TraitDiscoveryRewardClaimed(uint256 indexed proposalId, address indexed claimant, uint256 rewardAmount);
    event ProtocolFeesWithdrawn(address indexed recipient, uint256 amount);

    // --- Modifiers ---

    modifier onlyAIOracle() {
        require(msg.sender == aiOracleAddress, "AetherLoom: Only AI oracle can call this function");
        _;
    }

    modifier onlyWeaver() {
        require(aetherWeavers[msg.sender].isRegistered, "AetherLoom: Caller is not a registered AetherWeaver");
        _;
    }

    modifier whenProtocolActive() {
        require(protocolActive, "AetherLoom: Protocol is currently paused");
        _;
    }

    // --- Constructor ---

    constructor(
        address _essenceTokenAddress,
        address _aiOracleAddress,
        uint256 _baseMintCost,
        uint256 _evolutionCostMultiplier,
        uint256 _weaverRegistrationStake
    ) ERC721("AetherGem", "AGEM") Ownable(msg.sender) {
        require(_essenceTokenAddress != address(0), "AetherLoom: Invalid Essence token address");
        require(_aiOracleAddress != address(0), "AetherLoom: Invalid AI oracle address");
        
        essenceToken = IERC20(_essenceTokenAddress);
        aiOracleAddress = _aiOracleAddress;
        baseMintCost = _baseMintCost;
        evolutionCostMultiplier = _evolutionCostMultiplier;
        weaverRegistrationStake = _weaverRegistrationStake;
        currentAethericFlux = 5000; // Initialize with a neutral flux (50.00%)
    }

    // --- I. Protocol Management (Owner/Admin) ---

    function setAIOracleAddress(address _newOracle) public onlyOwner {
        require(_newOracle != address(0), "AetherLoom: Invalid new AI oracle address");
        aiOracleAddress = _newOracle;
    }

    function setEssenceTokenAddress(address _essenceToken) public onlyOwner {
        require(_essenceToken != address(0), "AetherLoom: Invalid new Essence token address");
        essenceToken = IERC20(_essenceToken);
    }

    function updateBaseMintCost(uint256 _newCost) public onlyOwner {
        baseMintCost = _newCost;
    }

    function updateEvolutionCostMultiplier(uint256 _newMultiplier) public onlyOwner {
        require(_newMultiplier > 0, "AetherLoom: Multiplier must be positive");
        evolutionCostMultiplier = _newMultiplier;
    }

    function toggleProtocolActive(bool _status) public onlyOwner {
        protocolActive = _status;
    }

    function withdrawProtocolFees() public onlyOwner {
        require(protocolFeesAccrued > 0, "AetherLoom: No fees to withdraw");
        uint256 amount = protocolFeesAccrued;
        protocolFeesAccrued = 0;
        require(essenceToken.transfer(owner(), amount), "AetherLoom: Failed to withdraw fees");
        emit ProtocolFeesWithdrawn(owner(), amount);
    }

    // --- II. AI Oracle Integration ---

    function updateAethericFlux(uint256 _newFlux) public onlyAIOracle {
        require(_newFlux <= 10000, "AetherLoom: Flux must be between 0 and 10000 (0-100%)");
        currentAethericFlux = _newFlux;
        emit AethericFluxUpdated(_newFlux);
    }

    function getCurrentAethericFlux() public view returns (uint256) {
        return currentAethericFlux;
    }

    // --- III. AetherWeaver Management ---

    function registerWeaver() public whenProtocolActive {
        AetherWeaver storage weaver = aetherWeavers[msg.sender];
        require(!weaver.isRegistered, "AetherLoom: Already a registered Weaver");
        require(weaverRegistrationStake > 0, "AetherLoom: Registration stake not set");

        require(essenceToken.transferFrom(msg.sender, address(this), weaverRegistrationStake), "AetherLoom: Failed to stake Essence for registration");

        weaver.isRegistered = true;
        weaver.reputationScore = 100; // Starting reputation
        weaver.stakedEssence = weaverRegistrationStake;
        weaver.registrationTimestamp = block.timestamp;
        weaver.metadataURI = ""; // Can be updated later

        emit WeaverRegistered(msg.sender, weaverRegistrationStake, weaver.reputationScore);
    }

    function deregisterWeaver() public onlyWeaver {
        AetherWeaver storage weaver = aetherWeavers[msg.sender];
        require(weaver.stakedEssence > 0, "AetherLoom: No staked Essence to deregister");

        uint256 amountToUnstake = weaver.stakedEssence;
        weaver.stakedEssence = 0;
        weaver.isRegistered = false;
        
        // Optional: Introduce a cooldown or penalty here based on reputation/activity
        // For simplicity, we'll return the full stake.
        require(essenceToken.transfer(msg.sender, amountToUnstake), "AetherLoom: Failed to return staked Essence");

        emit WeaverDeregistered(msg.sender, uint224(amountToUnstake));
    }

    function updateWeaverMetadataURI(string calldata _newURI) public onlyWeaver {
        aetherWeavers[msg.sender].metadataURI = _newURI;
    }

    function getWeaverReputation(address _weaver) public view returns (uint256) {
        return aetherWeavers[_weaver].reputationScore;
    }

    // Internal helper functions for reputation
    function _increaseWeaverReputation(address _weaver) internal {
        aetherWeavers[_weaver].reputationScore = aetherWeavers[_weaver].reputationScore.add(WEAVER_REPUTATION_INCREMENT);
        emit WeaverReputationUpdated(_weaver, aetherWeavers[_weaver].reputationScore);
    }

    function _decreaseWeaverReputation(address _weaver) internal {
        aetherWeavers[_weaver].reputationScore = aetherWeavers[_weaver].reputationScore.sub(WEAVER_REPUTATION_DECREMENT);
        if (aetherWeavers[_weaver].reputationScore < MIN_WEAVER_REPUTATION) {
             // Optional: Add logic to suspend or penalize weavers below min reputation
        }
        emit WeaverReputationUpdated(_weaver, aetherWeavers[_weaver].reputationScore);
    }

    // --- IV. AetherGem (Dynamic NFT) Operations ---

    function mintAetherGem(string calldata _initialMetadataURI, bytes32 _generationSeed, uint256[] calldata _baseTraits) 
        public onlyWeaver whenProtocolActive returns (uint256) {
        
        uint256 mintCost = getDynamicMintCost();
        require(mintCost > 0, "AetherLoom: Mint cost is zero, cannot mint.");
        require(essenceToken.transferFrom(msg.sender, address(this), mintCost), "AetherLoom: Failed to pay minting cost in Essence");
        protocolFeesAccrued = protocolFeesAccrued.add(mintCost);

        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();

        aetherGems[newItemId] = AetherGem({
            mintTimestamp: block.timestamp,
            lastEvolvedTimestamp: block.timestamp,
            evolutionCount: 0,
            baseTraits: _baseTraits,
            currentTraits: _baseTraits, // Initially, current traits are base traits
            metadataURI: _initialMetadataURI,
            generationSeed: _generationSeed
        });

        _mint(msg.sender, newItemId);
        _increaseWeaverReputation(msg.sender); // Reward weaver for minting

        emit AetherGemMinted(newItemId, msg.sender, _initialMetadataURI, _generationSeed, _baseTraits);
        return newItemId;
    }

    function evolveAetherGem(uint256 _tokenId, uint256[] calldata _newTraitParams) 
        public onlyWeaver whenProtocolActive {
        
        require(_isApprovedOrOwner(msg.sender, _tokenId), "AetherLoom: Caller is not owner nor approved for evolution");
        AetherGem storage gem = aetherGems[_tokenId];
        require(gem.mintTimestamp > 0, "AetherLoom: AetherGem does not exist");
        
        uint256 evolutionCost = getDynamicEvolutionCost(_tokenId);
        require(evolutionCost > 0, "AetherLoom: Evolution cost is zero, cannot evolve.");
        require(essenceToken.transferFrom(msg.sender, address(this), evolutionCost), "AetherLoom: Failed to pay evolution cost in Essence");
        protocolFeesAccrued = protocolFeesAccrued.add(evolutionCost);

        gem.currentTraits = _newTraitParams;
        gem.evolutionCount = gem.evolutionCount.add(1);
        gem.lastEvolvedTimestamp = block.timestamp;
        
        _increaseWeaverReputation(msg.sender); // Reward weaver for evolving

        emit AetherGemEvolved(_tokenId, msg.sender, _newTraitParams, gem.evolutionCount);
    }

    function getAetherGemTraits(uint256 _tokenId) public view returns (uint256[] memory baseTraits, uint256[] memory currentTraits) {
        AetherGem storage gem = aetherGems[_tokenId];
        require(gem.mintTimestamp > 0, "AetherLoom: AetherGem does not exist");
        return (gem.baseTraits, gem.currentTraits);
    }

    function predictGemEvolutionOutcome(uint256 _tokenId) public view returns (uint256[] memory predictedTraits, string memory description) {
        AetherGem storage gem = aetherGems[_tokenId];
        require(gem.mintTimestamp > 0, "AetherLoom: AetherGem does not exist");

        // --- SIMULATED AI PREDICTION LOGIC ---
        // In a real scenario, this would involve complex off-chain AI models
        // and potentially a ZK proof to verify the outcome without revealing inputs.
        // Here, we simulate by simply modifying traits based on currentAethericFlux.

        uint256[] memory current = gem.currentTraits;
        uint256[] memory predicted = new uint256[](current.length);

        // Simple simulation: Aetheric Flux shifts trait values
        for (uint256 i = 0; i < current.length; i++) {
            // Example: Flux influences a trait. If flux is high, trait value increases, low decreases.
            if (currentAethericFlux > 5000) { // If flux is above 50%
                predicted[i] = current[i].add(currentAethericFlux.div(1000)); // Increase trait value
            } else {
                predicted[i] = current[i].sub(currentAethericFlux.div(1000)); // Decrease trait value
            }
            // Ensure trait values don't go below 0, or above a max (e.g., 2^32-1)
            if (predicted[i] > type(uint32).max) predicted[i] = type(uint32).max;
            if (predicted[i] < 0) predicted[i] = 0; 
        }

        string memory desc;
        if (currentAethericFlux > 7500) {
            desc = "High Aetheric Flux: Significant positive evolution expected.";
        } else if (currentAethericFlux < 2500) {
            desc = "Low Aetheric Flux: Potentially challenging evolution.";
        } else {
            desc = "Moderate Aetheric Flux: Balanced evolution likely.";
        }

        return (predicted, desc);
    }

    // ERC721 Standard functions (included to meet the function count requirement)
    // Note: Most are inherited and require minimal direct implementation beyond constructor and _mint/_burn.
    // The `_isApprovedOrOwner` check is provided by ERC721 internally.

    function transferFrom(address _from, address _to, uint256 _tokenId) public override whenProtocolActive {
        super.transferFrom(_from, _to, _tokenId);
    }

    function approve(address _to, uint256 _tokenId) public override whenProtocolActive {
        super.approve(_to, _tokenId);
    }

    function getApproved(uint256 _tokenId) public view override returns (address) {
        return super.getApproved(_tokenId);
    }

    function isApprovedForAll(address _owner, address _operator) public view override returns (bool) {
        return super.isApprovedForAll(_owner, _operator);
    }

    function setApprovalForAll(address _operator, bool _approved) public override whenProtocolActive {
        super.setApprovalForAll(_operator, _approved);
    }

    function balanceOf(address _owner) public view override returns (uint256) {
        return super.balanceOf(_owner);
    }

    function ownerOf(uint256 _tokenId) public view override returns (address) {
        return super.ownerOf(_tokenId);
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        return aetherGems[_tokenId].metadataURI;
    }

    // --- V. Reputation & Discovery System ---

    function proposeTraitDiscovery(string calldata _descriptionURI, uint256 _proposalEssenceStake, uint256 _votingPeriodDays) 
        public onlyWeaver whenProtocolActive returns (uint256) {
        
        require(aetherWeavers[msg.sender].reputationScore >= MIN_WEAVER_REPUTATION, "AetherLoom: Insufficient reputation to propose traits");
        require(_proposalEssenceStake > 0, "AetherLoom: Proposal requires Essence stake");
        require(_votingPeriodDays > 0 && _votingPeriodDays <= 30, "AetherLoom: Voting period must be between 1 and 30 days");

        require(essenceToken.transferFrom(msg.sender, address(this), _proposalEssenceStake), "AetherLoom: Failed to stake Essence for proposal");

        _proposalIdCounter.increment();
        uint256 proposalId = _proposalIdCounter.current();

        traitProposals[proposalId] = TraitProposal({
            proposer: msg.sender,
            descriptionURI: _descriptionURI,
            startTime: block.timestamp,
            endTime: block.timestamp.add(_votingPeriodDays.mul(1 days)),
            votesFor: 0,
            votesAgainst: 0,
            isActive: true,
            isApproved: false,
            essenceStake: _proposalEssenceStake
        });
        // Initialize mapping for hasVoted for the new proposal ID
        // Note: Solidity handles new keys in mappings by default, so no explicit initialization loop needed here.

        _increaseWeaverReputation(msg.sender); // Reward proposer

        emit TraitProposed(proposalId, msg.sender, _descriptionURI, traitProposals[proposalId].endTime);
        return proposalId;
    }

    function voteOnTraitProposal(uint256 _proposalId, bool _support) public onlyWeaver {
        TraitProposal storage proposal = traitProposals[_proposalId];
        require(proposal.isActive, "AetherLoom: Proposal is not active or does not exist");
        require(block.timestamp <= proposal.endTime, "AetherLoom: Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "AetherLoom: Already voted on this proposal");
        require(aetherWeavers[msg.sender].reputationScore >= MIN_WEAVER_REPUTATION, "AetherLoom: Insufficient reputation to vote");

        if (_support) {
            proposal.votesFor = proposal.votesFor.add(1);
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(1);
        }
        proposal.hasVoted[msg.sender] = true;

        _increaseWeaverReputation(msg.sender); // Reward voter

        emit TraitVoted(_proposalId, msg.sender, _support);
    }

    function finalizeTraitProposal(uint256 _proposalId) public whenProtocolActive {
        TraitProposal storage proposal = traitProposals[_proposalId];
        require(proposal.isActive, "AetherLoom: Proposal is not active or does not exist");
        require(block.timestamp > proposal.endTime, "AetherLoom: Voting period has not ended yet");
        
        proposal.isActive = false; // Close voting

        if (proposal.votesFor >= TRAIT_PROPOSAL_VOTING_THRESHOLD && proposal.votesFor > proposal.votesAgainst) {
            proposal.isApproved = true;
            // Optionally, add logic here to "integrate" the new trait, e.g.,
            // by adding it to a whitelist of available traits for future AetherGems.
            // For now, it's marked as approved, relying on off-chain interpretation.
        }

        // Return staked Essence (proposer reward handled separately)
        protocolFeesAccrued = protocolFeesAccrued.add(proposal.essenceStake); // Stake becomes part of fees/reward pool

        emit TraitProposalFinalized(_proposalId, proposal.isApproved);
    }

    function claimTraitDiscoveryReward(uint256 _proposalId) public onlyWeaver {
        TraitProposal storage proposal = traitProposals[_proposalId];
        require(!proposal.isActive, "AetherLoom: Proposal is still active");
        require(proposal.isApproved, "AetherLoom: Proposal was not approved");
        require(proposal.proposer == msg.sender, "AetherLoom: Only the proposer can claim the reward");
        require(proposal.essenceStake > 0, "AetherLoom: Reward already claimed or no stake"); // Check against 0 to prevent re-claims

        uint256 rewardAmount = proposal.essenceStake.mul(TRAIT_PROPOSAL_REWARD_PERCENT).div(100);
        uint256 remainingStake = proposal.essenceStake.sub(rewardAmount);

        // Send reward to proposer
        require(essenceToken.transfer(msg.sender, rewardAmount), "AetherLoom: Failed to transfer reward");
        
        // Add remaining stake back to protocol fees
        protocolFeesAccrued = protocolFeesAccrued.add(remainingStake);
        proposal.essenceStake = 0; // Mark stake as processed

        _increaseWeaverReputation(msg.sender); // Reward proposer for successful discovery

        emit TraitDiscoveryRewardClaimed(_proposalId, msg.sender, rewardAmount);
    }

    function challengeWeaverReputation(address _targetWeaver, string calldata _reasonURI) public onlyWeaver {
        require(_targetWeaver != address(0) && _targetWeaver != msg.sender, "AetherLoom: Invalid target or self-challenge");
        require(aetherWeavers[_targetWeaver].isRegistered, "AetherLoom: Target is not a registered Weaver");
        require(aetherWeavers[msg.sender].reputationScore >= MIN_WEAVER_REPUTATION, "AetherLoom: Insufficient reputation to challenge");

        // --- SIMULATED CHALLENGE MECHANISM ---
        // In a real system, this would involve:
        // 1. A dispute resolution system (e.g., Aragon Court, Kleros)
        // 2. Requiring a stake from the challenger.
        // 3. A complex logic to verify the reasonURI (e.g., pointing to evidence).
        // For this contract, we simplify it to a direct reputation impact.

        // Simulate a small chance of failure for the challenger (or success for target)
        // Based on a pseudo-random number derived from flux and block data
        uint256 pseudoRandom = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, currentAethericFlux, _targetWeaver)));
        
        if (pseudoRandom % 100 < 30) { // 30% chance challenger fails (or target is vindicated)
            _decreaseWeaverReputation(msg.sender); // Challenger loses reputation
            _increaseWeaverReputation(_targetWeaver); // Target gains reputation
            // Potentially burn challenger's stake or reward target with it
        } else { // Challenger succeeds (70% chance)
            _decreaseWeaverReputation(_targetWeaver); // Target loses reputation
            _increaseWeaverReputation(msg.sender); // Challenger gains reputation
            // Potentially reward challenger with part of target's stake or a small amount of Essence
        }
        // Log _reasonURI off-chain for actual evidence review
    }

    // --- VI. Dynamic Pricing & Utility ---

    function getDynamicMintCost() public view returns (uint256) {
        // Example: Base cost adjusted by Aetheric Flux
        // If flux is high (e.g., > 75%), cost slightly increases, reflecting demand/value
        // If flux is low (e.g., < 25%), cost slightly decreases, encouraging activity
        // Flux is 0-10000. Normalize to -0.5 to 0.5 range for adjustment.
        int256 fluxAdjustment = int256(currentAethericFlux).sub(5000); // -5000 to +5000
        uint256 adjustmentFactor = uint256(fluxAdjustment.abs()).div(100); // 0 to 50
        
        uint256 adjustedCost;
        if (fluxAdjustment > 0) { // Flux is above neutral (50%)
            // Cost increases with flux
            adjustedCost = baseMintCost.add(baseMintCost.mul(adjustmentFactor).div(1000)); // Max +5%
        } else { // Flux is below neutral (50%)
            // Cost decreases with flux
            adjustedCost = baseMintCost.sub(baseMintCost.mul(adjustmentFactor).div(1000)); // Max -5%
        }
        // Ensure minimum cost, e.g., 1 Essence
        return adjustedCost > 0 ? adjustedCost : 1;
    }

    function getDynamicEvolutionCost(uint256 _tokenId) public view returns (uint256) {
        AetherGem storage gem = aetherGems[_tokenId];
        require(gem.mintTimestamp > 0, "AetherLoom: AetherGem does not exist");

        // Cost scales with evolution count and Aetheric Flux
        uint256 baseEvolutionCost = baseMintCost.mul(evolutionCostMultiplier).div(100);
        
        // Further adjustment based on Aetheric Flux and Gem's specific properties
        // Example: Evolution cost increases if the Gem has evolved many times
        uint256 cost = baseEvolutionCost.add(gem.evolutionCount.mul(baseEvolutionCost.div(10))); // +10% per evolution
        
        // Example: Aetheric Flux influences the cost
        // High flux makes evolution more "potent" but potentially more expensive
        cost = cost.mul(currentAethericFlux.add(5000)).div(10000); // Range from 0.5x to 1.5x based on flux (0 to 10000)

        return cost > 0 ? cost : 1;
    }

    function getRequiredWeaverStake() public view returns (uint256) {
        return weaverRegistrationStake;
    }
}
```