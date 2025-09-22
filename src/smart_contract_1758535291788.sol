Here's a smart contract for `EvolveVerse`, incorporating advanced concepts like dynamic NFTs, gamified evolution, simulated decentralized AI integration via oracles, and a robust DAO governance system, all designed to be unique in its combination and specific mechanics.

---

**Contract Name:** `EvolveVerse`

**Concept:** `EvolveVerse` is a decentralized autonomous ecosystem for digital life forms. Users can mint "Digital Seeds" as NFTs, which can then be nurtured through a complex, multi-stage evolution process. This evolution is influenced by user contributions (data, resources), community governance decisions, and guidance from registered AI oracles. Evolved "Digital Organisms" possess unique traits, an "AI Prowess" score, and can engage in advanced interactions like "Digital Fusion" or "AI Challenges" with other organisms. The ecosystem's parameters are managed through a robust DAO governance system, enabling adaptive and community-driven development.

---

**Function Summary:**

**I. Core NFT & Evolution Mechanics (ERC721 Compliant)**
1.  `constructor(string memory name_, string memory symbol_)`: Initializes the ERC721 contract with a name and symbol.
2.  `mintDigitalSeed()`: Allows a user to mint a new `DigitalSeed` NFT, marking its genesis in the ecosystem.
3.  `initiateEvolution(uint256 tokenId)`: Owner begins the evolution process for their `DigitalSeed`, transitioning it to an `Evolving` state.
4.  `contributeEvolutionData(uint256 tokenId, bytes calldata data)`: Users can submit data or resources to influence an `Evolving` seed's development, impacting its future traits.
5.  `requestEvolutionGuidance(uint256 tokenId)`: Triggers a request to a registered AI oracle for specific guidance on a seed's evolutionary path.
6.  `fulfillEvolutionGuidance(uint256 tokenId, bytes32 guidanceHash, uint8 dnaInfluence)`: Only a registered AI oracle can submit the requested guidance, influencing the organism's DNA traits.
7.  `finalizeEvolution(uint256 tokenId)`: Concludes the evolution process, transforming an `Evolving` seed into a fully-fledged `DigitalOrganism` with determined traits.
8.  `burnOrganism(uint256 tokenId)`: Allows the owner to permanently remove their `DigitalOrganism` from existence.
9.  `getOrganismDetails(uint256 tokenId)`: Retrieves comprehensive details (traits, state, AI Prowess) of a specific organism.
10. `tokenURI(uint256 tokenId)`: Returns the URI for the NFT metadata, compliant with ERC721 standards, reflecting dynamic traits.
11. `setBaseURI(string memory newBaseURI)`: Allows the owner (or DAO) to update the base URI for NFT metadata.

**II. Economic & Resource Management**
12. `depositNurtureFunds()`: Users deposit native tokens to a shared pool, supporting the ecosystem's development and rewarding contributors.
13. `withdrawNurtureFunds(address recipient, uint256 amount)`: Allows the DAO to withdraw funds from the nurture pool for ecosystem management or approved initiatives.
14. `stakeForGrowth(uint256 tokenId, uint256 amount)`: Users can stake tokens on a specific organism to accelerate its evolution progress or enhance its capabilities.
15. `unstakeFromGrowth(uint256 tokenId)`: Allows a user to retrieve their staked tokens from an organism.
16. `claimStakingRewards(uint256 tokenId)`: Enables stakers to claim rewards accrued from their staked organisms (if any).
17. `setEvolutionFee(uint256 fee)`: DAO governance function to adjust the fee required to initiate an organism's evolution.
18. `distributeNurtureRewards(address[] calldata contributors, uint256[] calldata amounts)`: DAO function to distribute funds from the nurture pool to active ecosystem contributors.

**III. Oracle & AI Integration (Simulated)**
19. `registerAIOracle(address oracleAddress, string calldata description)`: Registers a new address as a trusted AI oracle, granting it permission to fulfill guidance requests.
20. `deactivateAIOracle(address oracleAddress)`: Removes an address from the list of active AI oracles.
21. `setAIModelParameters(uint256 guidanceWeight, uint256 dataInfluenceWeight)`: DAO function to adjust the influence weight of AI oracle guidance versus user-contributed data in evolution outcomes.

**IV. DAO & Governance**
22. `proposeEvolutionPolicy(string calldata proposalDescription, bytes calldata callData, address targetContract)`: Allows eligible users to propose changes to contract parameters or evolution policies.
23. `voteOnProposal(uint256 proposalId, bool support)`: Enables users to cast their votes on active proposals, influencing ecosystem direction.
24. `executeProposal(uint256 proposalId)`: Executes a proposal that has met its voting quorum and passed within its timeframe.
25. `delegateVotingPower(address delegatee)`: Allows users to delegate their voting power to another address.
26. `undelegateVotingPower()`: Revokes a previously set voting power delegation.

**V. Inter-Organism Dynamics & Advanced Features**
27. `initiateDigitalFusion(uint256 tokenIdA, uint256 tokenIdB)`: Owner of two organisms initiates a complex fusion process, potentially yielding a new, more powerful organism.
28. `resolveDigitalFusion(uint256 fusionId, uint256 newTraitSeed, bool success, uint256 destructionRisk)`: An oracle or specific resolver finalizes the fusion outcome, determining success, new traits, or destruction.
29. `challengeOrganismAI(uint256 challengerTokenId, uint256 targetTokenId, bytes32 challengeData)`: An organism can challenge another in a simulated AI task, impacting "AI Prowess" or ownership.
30. `resolveAIChallenge(uint256 challengeId, bool challengerWon, string calldata resolutionData)`: An oracle or designated resolver determines the winner of an AI challenge, applying effects.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Using SafeMath implicitly for clarity, but 0.8+ has built-in checks.
import "@openzeppelin/contracts/utils/Strings.sol";

contract EvolveVerse is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- Enums ---
    enum OrganismState { Seed, Evolving, Organism, Fusing, Challenged, Destroyed }
    enum ProposalState { Pending, Active, Succeeded, Failed, Executed }
    enum ChallengeState { Pending, Resolved }
    enum FusionState { Pending, Resolved }

    // --- Structs ---

    // Represents a Digital Organism or Seed NFT
    struct Organism {
        uint256 tokenId;
        address owner;
        OrganismState state;
        uint8[5] traits; // E.g., [Strength, Intelligence, Agility, Resilience, Rarity] (0-100)
        uint256 aiProwess; // Score representing AI capabilities
        uint256 evolutionProgress; // Progress towards next stage/trait enhancement
        uint256 lastInteractionTime; // Timestamp of last significant interaction
        uint256 stakedAmount; // Tokens staked on this organism
        address staker; // Address that staked on this organism
    }

    // Details for an active evolution process
    struct EvolutionProcess {
        uint256 tokenId;
        address initiator;
        uint256 startTime;
        uint256 endTime; // When guidance/data collection phase ends
        mapping(address => bytes[]) contributions; // Data submitted by addresses
        bytes32 oracleGuidanceHash; // Hash of guidance from AI oracle
        uint8 dnaInfluence; // Influence value from oracle guidance
        bool guidanceReceived;
        mapping(address => bool) contributorAddresses; // To track unique contributors
        uint256 totalContributions;
    }

    // Details for a DAO proposal
    struct Proposal {
        uint256 proposalId;
        address proposer;
        string description;
        bytes callData; // Encoded function call for execution
        address targetContract; // Contract to call (e.g., this contract)
        uint256 voteCountYes;
        uint256 voteCountNo;
        mapping(address => bool) hasVoted; // Tracks if an address voted
        uint256 creationTime;
        uint256 expirationTime;
        ProposalState state;
        uint256 totalVotingPowerAtCreation; // Snapshot of total voting power
    }

    // Details for an AI challenge between organisms
    struct Challenge {
        uint256 challengeId;
        uint256 challengerTokenId;
        uint256 targetTokenId;
        address challengerOwner;
        address targetOwner;
        bytes32 challengeData; // Data representing the challenge parameters
        address resolver; // Oracle or community-appointed resolver
        ChallengeState state;
        bool challengerWon;
        string resolutionData;
        uint256 creationTime;
    }

    // Details for a Digital Fusion attempt
    struct FusionAttempt {
        uint256 fusionId;
        uint256 tokenIdA;
        uint256 tokenIdB;
        address ownerA;
        address ownerB;
        FusionState state;
        uint256 creationTime;
        uint256 resolutionTime;
        bool success;
        uint256 destructionRisk; // Percentage chance of both being destroyed
        uint256 newTraitSeed; // Seed for new organism's traits if successful
    }

    // --- State Variables ---

    Counters.Counter private _tokenIdTracker;
    Counters.Counter private _proposalIdTracker;
    Counters.Counter private _challengeIdTracker;
    Counters.Counter private _fusionIdTracker;

    string private _baseTokenURI;

    mapping(uint256 => Organism) public organisms;
    mapping(uint256 => EvolutionProcess) public activeEvolutions;
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => Challenge) public activeChallenges;
    mapping(uint256 => FusionAttempt) public activeFusions;

    mapping(address => bool) public registeredAIOracles;
    mapping(address => string) public aiOracleDescriptions;

    // DAO related
    uint256 public constant PROPOSAL_VOTING_PERIOD = 3 days;
    uint256 public constant PROPOSAL_QUORUM_PERCENT = 40; // 40% of total voting power needed for quorum
    uint256 public minVotingPowerForProposal = 1 ether; // Example: 1 token for voting power

    mapping(address => uint256) public votingPower; // Direct voting power (e.g., based on special tokens or organism count)
    mapping(address => address) public delegates; // For vote delegation

    uint256 public nurturePoolFunds;
    uint256 public evolutionFee = 0.01 ether; // Default evolution fee

    uint256 public aiGuidanceWeight = 50; // Influence of AI guidance (out of 100)
    uint256 public userDataInfluenceWeight = 50; // Influence of user data (out of 100)

    // --- Events ---
    event DigitalSeedMinted(uint256 indexed tokenId, address indexed owner);
    event EvolutionInitiated(uint256 indexed tokenId, address indexed initiator);
    event EvolutionDataContributed(uint252 indexed tokenId, address indexed contributor, bytes dataHash);
    event EvolutionGuidanceRequested(uint256 indexed tokenId);
    event EvolutionGuidanceFulfilled(uint256 indexed tokenId, address indexed oracle, bytes32 guidanceHash, uint8 dnaInfluence);
    event EvolutionFinalized(uint256 indexed tokenId, OrganismState newState, uint8[5] newTraits);
    event OrganismBurned(uint256 indexed tokenId);

    event NurtureFundsDeposited(address indexed depositor, uint256 amount);
    event NurtureFundsWithdrawn(address indexed recipient, uint256 amount);
    event StakedForGrowth(uint256 indexed tokenId, address indexed staker, uint256 amount);
    event UnstakedFromGrowth(uint256 indexed tokenId, address indexed staker, uint256 amount);
    event StakingRewardsClaimed(uint256 indexed tokenId, address indexed staker, uint256 amount);
    event EvolutionFeeUpdated(uint256 newFee);
    event NurtureRewardsDistributed(address[] indexed contributors, uint256[] amounts);

    event AIOracleRegistered(address indexed oracleAddress, string description);
    event AIOracleDeactivated(address indexed oracleAddress);
    event AIModelParametersUpdated(uint256 newGuidanceWeight, uint256 newDataInfluenceWeight);

    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId);
    event DelegateSet(address indexed delegator, address indexed delegatee);
    event DelegateRemoved(address indexed delegator);

    event DigitalFusionInitiated(uint256 indexed fusionId, uint256 indexed tokenIdA, uint256 indexed tokenIdB);
    event DigitalFusionResolved(uint256 indexed fusionId, bool success, uint256 newTokenId);
    event OrganismAIChallengeInitiated(uint256 indexed challengeId, uint256 indexed challengerTokenId, uint256 indexed targetTokenId);
    event OrganismAIChallengeResolved(uint256 indexed challengeId, bool challengerWon);

    // --- Modifiers ---
    modifier onlyAIOracle() {
        require(registeredAIOracles[msg.sender], "EvolveVerse: Not a registered AI Oracle");
        _;
    }

    modifier onlyOrganismOwner(uint256 tokenId) {
        require(_isApprovedOrOwner(msg.sender, tokenId), "EvolveVerse: Not organism owner or approved");
        _;
    }

    modifier onlyEvolving(uint256 tokenId) {
        require(organisms[tokenId].state == OrganismState.Evolving, "EvolveVerse: Organism not in Evolving state");
        require(activeEvolutions[tokenId].tokenId == tokenId, "EvolveVerse: No active evolution for this tokenId");
        _;
    }

    modifier onlyDAO() {
        // In a real DAO, this would check if the call comes from an executed proposal.
        // For simplicity, we'll allow owner to act as DAO initially, or use a separate DAO contract.
        // For this example, we'll implement proposal execution logic.
        revert("EvolveVerse: This function can only be called via a DAO proposal execution.");
        _;
    }

    // --- Constructor ---
    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) Ownable(msg.sender) {
        _baseTokenURI = "https://evolveverse.io/metadata/"; // Base URI for metadata
        // Owner gets initial voting power (e.g., by owning a special governance token, or just directly assigned)
        votingPower[msg.sender] = 1000 ether; // Example: initial high voting power for owner
    }

    // --- I. Core NFT & Evolution Mechanics ---

    /**
     * @notice Mints a new Digital Seed NFT.
     */
    function mintDigitalSeed() public payable returns (uint256) {
        _tokenIdTracker.increment();
        uint256 newTokenId = _tokenIdTracker.current();

        Organism storage newOrganism = organisms[newTokenId];
        newOrganism.tokenId = newTokenId;
        newOrganism.owner = msg.sender;
        newOrganism.state = OrganismState.Seed;
        newOrganism.traits = [uint8(0), 0, 0, 0, 0]; // Initialize with base traits
        newOrganism.aiProwess = 0;
        newOrganism.evolutionProgress = 0;
        newOrganism.lastInteractionTime = block.timestamp;

        _safeMint(msg.sender, newTokenId);
        emit DigitalSeedMinted(newTokenId, msg.sender);
        return newTokenId;
    }

    /**
     * @notice Initiates the evolution process for a Digital Seed.
     * @param tokenId The ID of the Digital Seed.
     */
    function initiateEvolution(uint256 tokenId) public payable onlyOrganismOwner(tokenId) {
        require(organisms[tokenId].state == OrganismState.Seed, "EvolveVerse: Organism must be a Seed to evolve.");
        require(msg.value >= evolutionFee, "EvolveVerse: Insufficient evolution fee.");

        organisms[tokenId].state = OrganismState.Evolving;
        organisms[tokenId].lastInteractionTime = block.timestamp;
        nurturePoolFunds += msg.value; // Add fee to nurture pool

        EvolutionProcess storage newEvolution = activeEvolutions[tokenId];
        newEvolution.tokenId = tokenId;
        newEvolution.initiator = msg.sender;
        newEvolution.startTime = block.timestamp;
        newEvolution.endTime = block.timestamp + 1 days; // Evolution data collection phase lasts 1 day

        emit EvolutionInitiated(tokenId, msg.sender);
    }

    /**
     * @notice Allows users to contribute data to an evolving seed.
     * @param tokenId The ID of the evolving Digital Seed.
     * @param data Arbitrary data influencing evolution (e.g., hash of off-chain dataset, specific values).
     */
    function contributeEvolutionData(uint256 tokenId, bytes calldata data) public onlyEvolving(tokenId) {
        require(block.timestamp < activeEvolutions[tokenId].endTime, "EvolveVerse: Evolution data collection period ended.");

        activeEvolutions[tokenId].contributions[msg.sender].push(data);
        activeEvolutions[tokenId].contributorAddresses[msg.sender] = true;
        activeEvolutions[tokenId].totalContributions++;
        organisms[tokenId].evolutionProgress += 1; // Each contribution adds minor progress
        organisms[tokenId].lastInteractionTime = block.timestamp;

        emit EvolutionDataContributed(tokenId, msg.sender, keccak256(data));
    }

    /**
     * @notice Requests AI oracle guidance for an evolving seed.
     * Callable only once per evolution.
     * @param tokenId The ID of the evolving Digital Seed.
     */
    function requestEvolutionGuidance(uint256 tokenId) public onlyOrganismOwner(tokenId) onlyEvolving(tokenId) {
        require(!activeEvolutions[tokenId].guidanceReceived, "EvolveVerse: Guidance already requested/received for this evolution.");
        // In a real scenario, this would trigger a Chainlink or similar oracle request.
        // Here, we simply mark it as requested.
        emit EvolutionGuidanceRequested(tokenId);
    }

    /**
     * @notice Fulfills an AI oracle guidance request for an evolving seed.
     * @param tokenId The ID of the evolving Digital Seed.
     * @param guidanceHash A hash representing the AI's complex guidance (e.g., predicted trait modifications).
     * @param dnaInfluence A direct numeric influence value (0-100) on overall trait boost.
     */
    function fulfillEvolutionGuidance(uint256 tokenId, bytes32 guidanceHash, uint8 dnaInfluence) public onlyAIOracle onlyEvolving(tokenId) {
        require(dnaInfluence <= 100, "EvolveVerse: DNA influence must be between 0-100.");
        require(!activeEvolutions[tokenId].guidanceReceived, "EvolveVerse: Guidance already fulfilled for this evolution.");

        activeEvolutions[tokenId].oracleGuidanceHash = guidanceHash;
        activeEvolutions[tokenId].dnaInfluence = dnaInfluence;
        activeEvolutions[tokenId].guidanceReceived = true;
        organisms[tokenId].evolutionProgress += dnaInfluence; // AI guidance significantly boosts progress
        organisms[tokenId].lastInteractionTime = block.timestamp;

        emit EvolutionGuidanceFulfilled(tokenId, msg.sender, guidanceHash, dnaInfluence);
    }

    /**
     * @notice Finalizes the evolution process for a seed, transforming it into a Digital Organism.
     * @param tokenId The ID of the evolving Digital Seed.
     */
    function finalizeEvolution(uint256 tokenId) public onlyOrganismOwner(tokenId) onlyEvolving(tokenId) {
        // Require data collection period to be over and optionally guidance received
        require(block.timestamp >= activeEvolutions[tokenId].endTime, "EvolveVerse: Data collection period is still active.");
        require(activeEvolutions[tokenId].guidanceReceived, "EvolveVerse: AI Guidance is required for finalization.");

        Organism storage organism = organisms[tokenId];
        EvolutionProcess storage evolution = activeEvolutions[tokenId];

        // Simulate trait generation based on accumulated influences
        uint256 seedValue = uint256(keccak256(abi.encodePacked(
            tokenId,
            evolution.initiator,
            block.timestamp,
            evolution.oracleGuidanceHash,
            evolution.totalContributions
        )));

        // Apply AI guidance and user data influence
        // This is a simplified example. Real logic could be much more complex.
        for (uint8 i = 0; i < 5; i++) {
            uint256 traitModifier = (seedValue >> (i * 8)) % 20; // Some base randomness
            traitModifier += (evolution.dnaInfluence * aiGuidanceWeight) / 10000; // AI influence
            traitModifier += (evolution.totalContributions * userDataInfluenceWeight) / 10000; // User data influence
            traitModifier += organism.evolutionProgress / 100; // General progress influence

            organism.traits[i] = uint8(SafeMath.min(100, organism.traits[i] + traitModifier));
        }

        organism.aiProwess = (organism.aiProwess + evolution.dnaInfluence + (evolution.totalContributions * 5)) / 2; // Average and add

        organism.state = OrganismState.Organism;
        organism.evolutionProgress = 0; // Reset after evolution
        organisms[tokenId].lastInteractionTime = block.timestamp;

        delete activeEvolutions[tokenId]; // Clear active evolution process

        emit EvolutionFinalized(tokenId, OrganismState.Organism, organism.traits);
    }

    /**
     * @notice Allows the owner to permanently burn their Digital Organism.
     * @param tokenId The ID of the Digital Organism to burn.
     */
    function burnOrganism(uint256 tokenId) public onlyOrganismOwner(tokenId) {
        require(organisms[tokenId].state != OrganismState.Destroyed, "EvolveVerse: Organism already destroyed.");
        require(organisms[tokenId].stakedAmount == 0, "EvolveVerse: Cannot burn organism with staked funds.");

        _burn(tokenId);
        organisms[tokenId].state = OrganismState.Destroyed;
        delete organisms[tokenId]; // Remove from storage
        emit OrganismBurned(tokenId);
    }

    /**
     * @notice Retrieves detailed information about a specific organism.
     * @param tokenId The ID of the organism.
     * @return owner_ The owner's address.
     * @return state_ The current state of the organism.
     * @return traits_ An array of 5 trait values.
     * @return aiProwess_ The organism's AI prowess score.
     * @return evolutionProgress_ Current evolution progress.
     * @return lastInteractionTime_ Timestamp of last interaction.
     * @return stakedAmount_ Amount of tokens staked on this organism.
     */
    function getOrganismDetails(uint256 tokenId)
        public
        view
        returns (
            address owner_,
            OrganismState state_,
            uint8[5] memory traits_,
            uint256 aiProwess_,
            uint256 evolutionProgress_,
            uint256 lastInteractionTime_,
            uint256 stakedAmount_
        )
    {
        Organism storage organism = organisms[tokenId];
        require(organism.tokenId != 0, "EvolveVerse: Organism does not exist.");

        owner_ = organism.owner;
        state_ = organism.state;
        traits_ = organism.traits;
        aiProwess_ = organism.aiProwess;
        evolutionProgress_ = organism.evolutionProgress;
        lastInteractionTime_ = organism.lastInteractionTime;
        stakedAmount_ = organism.stakedAmount;
    }

    /**
     * @notice Returns the URI for a given token ID's metadata.
     * @param tokenId The ID of the token.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        // Dynamically generate metadata based on organism state and traits
        Organism storage organism = organisms[tokenId];
        string memory stateString;
        if (organism.state == OrganismState.Seed) stateString = "Seed";
        else if (organism.state == OrganismState.Evolving) stateString = "Evolving";
        else if (organism.state == OrganismState.Organism) stateString = "Organism";
        else if (organism.state == OrganismState.Fusing) stateString = "Fusing";
        else if (organism.state == OrganismState.Challenged) stateString = "Challenged";
        else stateString = "Destroyed";

        string memory traitsString = string(abi.encodePacked(
            "[", organism.traits[0].toString(), ",", organism.traits[1].toString(), ",",
            organism.traits[2].toString(), ",", organism.traits[3].toString(), ",",
            organism.traits[4].toString(), "]"
        ));

        // Simplified JSON for example, in real dApp this would point to IPFS/Arweave with full metadata
        string memory json = string(abi.encodePacked(
            '{"name": "Digital Organism #', tokenId.toString(), '",',
            '"description": "A dynamic entity in the EvolveVerse.",',
            '"image": "', _baseTokenURI, tokenId.toString(), '.png",', // Placeholder image
            '"attributes": [',
                '{"trait_type": "State", "value": "', stateString, '"},',
                '{"trait_type": "AI Prowess", "value": ', organism.aiProwess.toString(), '},',
                '{"trait_type": "Strength", "value": ', organism.traits[0].toString(), '},',
                '{"trait_type": "Intelligence", "value": ', organism.traits[1].toString(), '},',
                '{"trait_type": "Agility", "value": ', organism.traits[2].toString(), '},',
                '{"trait_type": "Resilience", "value": ', organism.traits[3].toString(), '},',
                '{"trait_type": "Rarity", "value": ', organism.traits[4].toString(), '}',
            ']}'
        ));

        // Base64 encode the JSON for on-chain metadata (common practice for dynamic NFTs)
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
    }

    /**
     * @notice Sets the base URI for token metadata.
     * @param newBaseURI The new base URI.
     */
    function setBaseURI(string memory newBaseURI) public onlyOwner { // Can be changed to onlyDAO later
        _baseTokenURI = newBaseURI;
        // In a full DAO setup, this would be a DAO proposal.
    }

    // --- II. Economic & Resource Management ---

    /**
     * @notice Allows users to deposit native tokens into the nurture pool.
     */
    function depositNurtureFunds() public payable {
        require(msg.value > 0, "EvolveVerse: Deposit amount must be greater than zero.");
        nurturePoolFunds += msg.value;
        emit NurtureFundsDeposited(msg.sender, msg.value);
    }

    /**
     * @notice Allows the DAO to withdraw funds from the nurture pool.
     * @param recipient The address to send funds to.
     * @param amount The amount to withdraw.
     */
    function withdrawNurtureFunds(address recipient, uint256 amount) public onlyOwner { // Placeholder for DAO call
        require(amount > 0, "EvolveVerse: Withdraw amount must be greater than zero.");
        require(nurturePoolFunds >= amount, "EvolveVerse: Insufficient funds in nurture pool.");
        nurturePoolFunds -= amount;
        payable(recipient).transfer(amount);
        emit NurtureFundsWithdrawn(recipient, amount);
    }

    /**
     * @notice Allows a user to stake tokens on a specific organism to accelerate its growth/evolution.
     * @param tokenId The ID of the organism.
     * @param amount The amount of tokens to stake.
     */
    function stakeForGrowth(uint256 tokenId, uint256 amount) public payable {
        require(organisms[tokenId].tokenId != 0, "EvolveVerse: Organism does not exist.");
        require(amount > 0, "EvolveVerse: Staking amount must be greater than zero.");
        require(msg.value >= amount, "EvolveVerse: Insufficient funds sent for staking.");

        organisms[tokenId].stakedAmount += amount;
        organisms[tokenId].staker = msg.sender; // Only one staker per organism for simplicity
        organisms[tokenId].evolutionProgress += (amount / 1 ether); // 1 token staked = 1 progress point
        organisms[tokenId].lastInteractionTime = block.timestamp;
        nurturePoolFunds += amount; // Staked funds also contribute to nurture pool

        emit StakedForGrowth(tokenId, msg.sender, amount);
    }

    /**
     * @notice Allows a user to unstake tokens from an organism.
     * @param tokenId The ID of the organism.
     */
    function unstakeFromGrowth(uint256 tokenId) public {
        require(organisms[tokenId].tokenId != 0, "EvolveVerse: Organism does not exist.");
        require(organisms[tokenId].staker == msg.sender, "EvolveVerse: Only the original staker can unstake.");
        require(organisms[tokenId].stakedAmount > 0, "EvolveVerse: No funds staked on this organism by you.");

        uint256 amountToUnstake = organisms[tokenId].stakedAmount;
        organisms[tokenId].stakedAmount = 0;
        organisms[tokenId].staker = address(0);
        nurturePoolFunds -= amountToUnstake; // Remove from nurture pool
        payable(msg.sender).transfer(amountToUnstake);

        emit UnstakedFromGrowth(tokenId, msg.sender, amountToUnstake);
    }

    /**
     * @notice Placeholder for claiming staking rewards.
     * In a real system, this would calculate rewards based on time staked, organism performance, etc.
     * @param tokenId The ID of the organism.
     */
    function claimStakingRewards(uint256 tokenId) public {
        require(organisms[tokenId].tokenId != 0, "EvolveVerse: Organism does not exist.");
        // Implement reward calculation logic here.
        // For simplicity, this is a placeholder.
        uint256 rewards = 0; // Calculate based on some logic (e.g., organism.evolutionProgress * a factor)
        if (rewards > 0) {
            // Transfer rewards from nurturePoolFunds
            // nurturePoolFunds -= rewards;
            // payable(msg.sender).transfer(rewards);
            emit StakingRewardsClaimed(tokenId, msg.sender, rewards);
        } else {
            revert("EvolveVerse: No rewards to claim or not yet implemented.");
        }
    }

    /**
     * @notice Allows the DAO to set the fee for initiating an organism's evolution.
     * @param fee The new evolution fee.
     */
    function setEvolutionFee(uint256 fee) public onlyOwner { // Placeholder for DAO call
        evolutionFee = fee;
        emit EvolutionFeeUpdated(fee);
    }

    /**
     * @notice Allows the DAO to distribute pooled funds to active ecosystem contributors.
     * @param contributors Array of contributor addresses.
     * @param amounts Array of corresponding amounts to distribute.
     */
    function distributeNurtureRewards(address[] calldata contributors, uint256[] calldata amounts) public onlyOwner { // Placeholder for DAO call
        require(contributors.length == amounts.length, "EvolveVerse: Mismatch in contributors and amounts arrays.");
        uint256 totalDistribution = 0;
        for (uint256 i = 0; i < contributors.length; i++) {
            totalDistribution += amounts[i];
        }
        require(nurturePoolFunds >= totalDistribution, "EvolveVerse: Insufficient funds in nurture pool for distribution.");

        nurturePoolFunds -= totalDistribution;
        for (uint256 i = 0; i < contributors.length; i++) {
            payable(contributors[i]).transfer(amounts[i]);
        }
        emit NurtureRewardsDistributed(contributors, amounts);
    }

    // --- III. Oracle & AI Integration (Simulated) ---

    /**
     * @notice Registers a new address as a trusted AI oracle.
     * @param oracleAddress The address of the new AI oracle.
     * @param description A description of the oracle.
     */
    function registerAIOracle(address oracleAddress, string calldata description) public onlyOwner { // Should be DAO approved
        require(!registeredAIOracles[oracleAddress], "EvolveVerse: Address is already an AI Oracle.");
        registeredAIOracles[oracleAddress] = true;
        aiOracleDescriptions[oracleAddress] = description;
        emit AIOracleRegistered(oracleAddress, description);
    }

    /**
     * @notice Deactivates an address from the list of active AI oracles.
     * @param oracleAddress The address of the AI oracle to deactivate.
     */
    function deactivateAIOracle(address oracleAddress) public onlyOwner { // Should be DAO approved
        require(registeredAIOracles[oracleAddress], "EvolveVerse: Address is not a registered AI Oracle.");
        registeredAIOracles[oracleAddress] = false;
        delete aiOracleDescriptions[oracleAddress];
        emit AIOracleDeactivated(oracleAddress);
    }

    /**
     * @notice Allows the DAO to adjust the influence weight of AI oracle guidance vs. user data in evolution outcomes.
     * @param guidanceWeight The new weight for AI guidance (0-100).
     * @param dataInfluenceWeight The new weight for user data influence (0-100).
     */
    function setAIModelParameters(uint256 guidanceWeight, uint256 dataInfluenceWeight) public onlyOwner { // Placeholder for DAO call
        require(guidanceWeight + dataInfluenceWeight == 100, "EvolveVerse: Weights must sum to 100.");
        aiGuidanceWeight = guidanceWeight;
        userDataInfluenceWeight = dataInfluenceWeight;
        emit AIModelParametersUpdated(guidanceWeight, dataInfluenceWeight);
    }

    // --- IV. DAO & Governance ---

    /**
     * @notice Allows eligible users to propose changes to contract parameters or evolution policies.
     * @param proposalDescription A textual description of the proposal.
     * @param callData Encoded function call to be executed if the proposal passes.
     * @param targetContract The address of the contract to call (e.g., `this` for EvolveVerse).
     */
    function proposeEvolutionPolicy(string calldata proposalDescription, bytes calldata callData, address targetContract) public {
        require(votingPower[msg.sender] >= minVotingPowerForProposal, "EvolveVerse: Insufficient voting power to propose.");

        _proposalIdTracker.increment();
        uint256 proposalId = _proposalIdTracker.current();

        Proposal storage newProposal = proposals[proposalId];
        newProposal.proposalId = proposalId;
        newProposal.proposer = msg.sender;
        newProposal.description = proposalDescription;
        newProposal.callData = callData;
        newProposal.targetContract = targetContract;
        newProposal.creationTime = block.timestamp;
        newProposal.expirationTime = block.timestamp + PROPOSAL_VOTING_PERIOD;
        newProposal.state = ProposalState.Active;
        // Snapshot total voting power. For simplicity, we use current sum of all votingPower values
        // In a real system, you'd have a token balance snapshot at proposal creation.
        // Here, we simulate by iterating, but for large scale, this needs a governance token with checkpoints.
        uint256 totalVP = 0;
        // This is highly inefficient for a real chain. A dedicated governance token with snapshot logic is needed.
        // For example, iterate over all token IDs, sum owner's voting power.
        // For now, let's assume `votingPower` is only for delegates and proposer, and actual voting is weighted.
        // For simplicity, we'll make a more realistic assumption here:
        // totalVotingPowerAtCreation is hard to calculate efficiently without a specific governance token.
        // Let's assume a fixed max voting power or sum of special governance tokens for this example.
        // A better approach would be to have a separate governance token and snapshot its total supply.
        // For now, let's just make it a placeholder.
        newProposal.totalVotingPowerAtCreation = 1000 ether; // Placeholder: Assume a fixed maximum or a known total.

        emit ProposalCreated(proposalId, msg.sender, proposalDescription);
    }

    /**
     * @notice Allows users to cast their votes on active proposals.
     * @param proposalId The ID of the proposal.
     * @param support True for 'yes', false for 'no'.
     */
    function voteOnProposal(uint256 proposalId, bool support) public {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.state == ProposalState.Active, "EvolveVerse: Proposal is not active.");
        require(block.timestamp <= proposal.expirationTime, "EvolveVerse: Voting period has ended.");
        
        address voter = delegates[msg.sender] == address(0) ? msg.sender : delegates[msg.sender];
        require(!proposal.hasVoted[voter], "EvolveVerse: Already voted on this proposal.");
        require(votingPower[voter] > 0, "EvolveVerse: You have no voting power.");

        proposal.hasVoted[voter] = true;
        if (support) {
            proposal.voteCountYes += votingPower[voter];
        } else {
            proposal.voteCountNo += votingPower[voter];
        }
        emit VoteCast(proposalId, voter, support);
    }

    /**
     * @notice Executes a proposal that has met its voting quorum and passed.
     * @param proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 proposalId) public onlyOwner { // Can be called by anyone after a DAO proposal passes
        Proposal storage proposal = proposals[proposalId];
        require(proposal.state == ProposalState.Active, "EvolveVerse: Proposal is not active or already executed.");
        require(block.timestamp > proposal.expirationTime, "EvolveVerse: Voting period is still active.");

        // Check quorum and outcome
        uint256 totalVotesCast = proposal.voteCountYes + proposal.voteCountNo;
        require(totalVotesCast * 100 >= proposal.totalVotingPowerAtCreation * PROPOSAL_QUORUM_PERCENT, "EvolveVerse: Quorum not met.");
        require(proposal.voteCountYes > proposal.voteCountNo, "EvolveVerse: Proposal did not pass.");

        proposal.state = ProposalState.Succeeded;

        // Execute the call
        (bool success, ) = proposal.targetContract.call(proposal.callData);
        require(success, "EvolveVerse: Proposal execution failed.");

        proposal.state = ProposalState.Executed;
        emit ProposalExecuted(proposalId);
    }

    /**
     * @notice Allows users to delegate their voting power to another address.
     * @param delegatee The address to delegate voting power to.
     */
    function delegateVotingPower(address delegatee) public {
        require(delegatee != address(0), "EvolveVerse: Cannot delegate to zero address.");
        require(delegatee != msg.sender, "EvolveVerse: Cannot delegate to self.");
        delegates[msg.sender] = delegatee;
        emit DelegateSet(msg.sender, delegatee);
    }

    /**
     * @notice Revokes a previously set voting power delegation.
     */
    function undelegateVotingPower() public {
        require(delegates[msg.sender] != address(0), "EvolveVerse: No active delegation to remove.");
        delete delegates[msg.sender];
        emit DelegateRemoved(msg.sender);
    }

    // --- V. Inter-Organism Dynamics & Advanced Features ---

    /**
     * @notice Allows the owner of two organisms to initiate a complex fusion process.
     * @param tokenIdA The ID of the first organism.
     * @param tokenIdB The ID of the second organism.
     */
    function initiateDigitalFusion(uint256 tokenIdA, uint256 tokenIdB) public {
        require(tokenIdA != tokenIdB, "EvolveVerse: Cannot fuse an organism with itself.");
        require(_isApprovedOrOwner(msg.sender, tokenIdA) && _isApprovedOrOwner(msg.sender, tokenIdB), "EvolveVerse: Caller must own both organisms.");
        require(organisms[tokenIdA].state == OrganismState.Organism && organisms[tokenIdB].state == OrganismState.Organism, "EvolveVerse: Both must be fully evolved organisms.");
        require(organisms[tokenIdA].stakedAmount == 0 && organisms[tokenIdB].stakedAmount == 0, "EvolveVerse: Cannot fuse organisms with staked funds.");

        organisms[tokenIdA].state = OrganismState.Fusing;
        organisms[tokenIdB].state = OrganismState.Fusing;

        _fusionIdTracker.increment();
        uint256 fusionId = _fusionIdTracker.current();

        FusionAttempt storage newFusion = activeFusions[fusionId];
        newFusion.fusionId = fusionId;
        newFusion.tokenIdA = tokenIdA;
        newFusion.tokenIdB = tokenIdB;
        newFusion.ownerA = ownerOf(tokenIdA);
        newFusion.ownerB = ownerOf(tokenIdB);
        newFusion.state = FusionState.Pending;
        newFusion.creationTime = block.timestamp;
        // Simplified destruction risk. Could be based on organism traits.
        newFusion.destructionRisk = 20; // 20% base risk of both being destroyed

        emit DigitalFusionInitiated(fusionId, tokenIdA, tokenIdB);
    }

    /**
     * @notice An oracle or designated resolver finalizes the fusion outcome.
     * @param fusionId The ID of the fusion attempt.
     * @param newTraitSeed A seed for generating new organism's traits if successful.
     * @param success Boolean indicating if fusion was successful.
     * @param destructionRoll A value (0-99) to check against destructionRisk.
     */
    function resolveDigitalFusion(uint256 fusionId, uint256 newTraitSeed, bool success, uint256 destructionRoll) public onlyAIOracle { // Only AI oracle can resolve for now
        FusionAttempt storage fusion = activeFusions[fusionId];
        require(fusion.state == FusionState.Pending, "EvolveVerse: Fusion not pending.");
        require(destructionRoll < 100, "EvolveVerse: Destruction roll must be 0-99.");

        fusion.resolutionTime = block.timestamp;
        fusion.state = FusionState.Resolved;
        fusion.success = success;

        if (success && destructionRoll >= fusion.destructionRisk) {
            // Fusion successful, mint new organism, burn originals
            _tokenIdTracker.increment();
            uint256 newOrganismId = _tokenIdTracker.current();

            Organism storage newOrganism = organisms[newOrganismId];
            newOrganism.tokenId = newOrganismId;
            newOrganism.owner = fusion.ownerA; // Owner is initiator of fusion
            newOrganism.state = OrganismState.Organism;
            newOrganism.evolutionProgress = 0;
            newOrganism.lastInteractionTime = block.timestamp;

            // Generate new traits based on newTraitSeed and parent traits
            for (uint8 i = 0; i < 5; i++) {
                uint8 traitA = organisms[fusion.tokenIdA].traits[i];
                uint8 traitB = organisms[fusion.tokenIdB].traits[i];
                uint8 avgTrait = (traitA + traitB) / 2;
                uint8 randomModifier = uint8((newTraitSeed >> (i * 8)) % 20); // Add randomness
                newOrganism.traits[i] = uint8(SafeMath.min(100, avgTrait + randomModifier));
            }
            newOrganism.aiProwess = (organisms[fusion.tokenIdA].aiProwess + organisms[fusion.tokenIdB].aiProwess) / 2 + (newTraitSeed % 50);

            _safeMint(fusion.ownerA, newOrganismId); // Mint new NFT to initiator

            // Burn original organisms
            _burn(fusion.tokenIdA);
            organisms[fusion.tokenIdA].state = OrganismState.Destroyed;
            delete organisms[fusion.tokenIdA];
            _burn(fusion.tokenIdB);
            organisms[fusion.tokenIdB].state = OrganismState.Destroyed;
            delete organisms[fusion.tokenIdB];

            emit DigitalFusionResolved(fusionId, true, newOrganismId);
        } else {
            // Fusion failed or destroyed
            _burn(fusion.tokenIdA);
            organisms[fusion.tokenIdA].state = OrganismState.Destroyed;
            delete organisms[fusion.tokenIdA];
            _burn(fusion.tokenIdB);
            organisms[fusion.tokenIdB].state = OrganismState.Destroyed;
            delete organisms[fusion.tokenIdB];
            emit DigitalFusionResolved(fusionId, false, 0);
        }
        delete activeFusions[fusionId];
    }

    /**
     * @notice An organism can challenge another in a simulated AI task.
     * This impacts "AI Prowess" or ownership.
     * @param challengerTokenId The ID of the challenging organism.
     * @param targetTokenId The ID of the challenged organism.
     * @param challengeData Data representing the challenge parameters (e.g., a prediction hash).
     */
    function challengeOrganismAI(uint256 challengerTokenId, uint256 targetTokenId, bytes32 challengeData) public {
        require(challengerTokenId != targetTokenId, "EvolveVerse: Cannot challenge self.");
        require(organisms[challengerTokenId].state == OrganismState.Organism && organisms[targetTokenId].state == OrganismState.Organism, "EvolveVerse: Both must be fully evolved organisms.");
        require(_isApprovedOrOwner(msg.sender, challengerTokenId), "EvolveVerse: Not challenger owner.");

        organisms[challengerTokenId].state = OrganismState.Challenged;
        organisms[targetTokenId].state = OrganismState.Challenged;

        _challengeIdTracker.increment();
        uint256 challengeId = _challengeIdTracker.current();

        Challenge storage newChallenge = activeChallenges[challengeId];
        newChallenge.challengeId = challengeId;
        newChallenge.challengerTokenId = challengerTokenId;
        newChallenge.targetTokenId = targetTokenId;
        newChallenge.challengerOwner = ownerOf(challengerTokenId);
        newChallenge.targetOwner = ownerOf(targetTokenId);
        newChallenge.challengeData = challengeData;
        newChallenge.resolver = address(0); // Resolver to be assigned or determined by DAO
        newChallenge.state = ChallengeState.Pending;
        newChallenge.creationTime = block.timestamp;

        emit OrganismAIChallengeInitiated(challengeId, challengerTokenId, targetTokenId);
    }

    /**
     * @notice An oracle or designated resolver determines the winner of an AI challenge.
     * @param challengeId The ID of the challenge.
     * @param challengerWon True if the challenger won, false otherwise.
     * @param resolutionData Data explaining the resolution outcome.
     */
    function resolveAIChallenge(uint256 challengeId, bool challengerWon, string calldata resolutionData) public onlyAIOracle { // Only AI oracle can resolve for now
        Challenge storage challenge = activeChallenges[challengeId];
        require(challenge.state == ChallengeState.Pending, "EvolveVerse: Challenge not pending.");

        challenge.resolver = msg.sender;
        challenge.state = ChallengeState.Resolved;
        challenge.challengerWon = challengerWon;
        challenge.resolutionData = resolutionData;

        Organism storage challenger = organisms[challenge.challengerTokenId];
        Organism storage target = organisms[challenge.targetTokenId];

        challenger.state = OrganismState.Organism; // Restore state
        target.state = OrganismState.Organism;

        if (challengerWon) {
            // Challenger gains AI prowess, target loses
            challenger.aiProwess += 50;
            if (target.aiProwess >= 25) target.aiProwess -= 25;
            else target.aiProwess = 0;
            // Potentially transfer ownership of target to challenger if stakes were high
            // _transfer(target.owner, challenger.owner, challenge.targetTokenId);
        } else {
            // Target gains AI prowess, challenger loses
            target.aiProwess += 50;
            if (challenger.aiProwess >= 25) challenger.aiProwess -= 25;
            else challenger.aiProwess = 0;
        }

        emit OrganismAIChallengeResolved(challengeId, challengerWon);
        delete activeChallenges[challengeId];
    }
}


// --- OpenZeppelin Base64 Library (for tokenURI) ---
// This is included directly as it's a small utility and avoids an extra import for this specific case.
// If you're building a larger project, consider using a dedicated Base64 library contract or just storing metadata off-chain.
library Base64 {
    string internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = TABLE;

        // calculate output length, ~4/3 of input length
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // allocate output buffer with space for base64 string
        bytes memory buf = new bytes(encodedLen);

        uint256 i;
        uint256 j = 0;
        while (i < data.length) {
            uint256 byte1 = data[i];
            i++;
            uint256 byte2 = i < data.length ? data[i] : 0;
            i++;
            uint256 byte3 = i < data.length ? data[i] : 0;
            i++;

            uint256 triplet = (byte1 << 16) | (byte2 << 8) | byte3;

            buf[j] = bytes1(table[(triplet >> 18) & 0x3F]);
            j++;
            buf[j] = bytes1(table[(triplet >> 12) & 0x3F]);
            j++;
            buf[j] = bytes1(table[(triplet >> 6) & 0x3F]);
            j++;
            buf[j] = bytes1(table[triplet & 0x3F]);
            j++;
        }

        // Add padding
        if (data.length % 3 == 1) {
            buf[buf.length - 1] = "=";
            buf[buf.length - 2] = "=";
        } else if (data.length % 3 == 2) {
            buf[buf.length - 1] = "=";
        }

        return string(buf);
    }
}

```