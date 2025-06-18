Okay, here is a Solidity smart contract for a concept I'll call "Ethereal Echoes". This contract aims to be interesting by combining elements of dynamic NFTs, interaction with a simulated AI oracle, community-driven trait evolution through funding and resonance, time-based decay, a unique "Awakening" state, and simple on-chain governance tied to token ownership.

It avoids directly using standard libraries like OpenZeppelin for core components (like full ERC721, Ownable, Pausable) to focus on the unique logic and adhere to the "don't duplicate open source" instruction, although basic, common patterns like ownership transfer or pausing logic are implemented manually. The complexity lies in the state management of the Echoes and the interactions between different mechanisms.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @custom:outline
/// 1. Contract Information & License
/// 2. State Variables (Ownership, Pausing, AI Feed, Echoes, Governance, Parameters)
/// 3. Events
/// 4. Modifiers
/// 5. Structs (EtherealEcho, Proposal)
/// 6. Core Logic (Ownership, Pausing)
/// 7. Ethereal Echo Management (Minting, Transfer, Getters, Base URI)
/// 8. Dynamic Trait & Evolution (AI Interaction, Resonance, Resilience Funding, Decay, Awakening)
/// 9. Governance (Proposals, Voting, Execution, Parameter Setting, Treasury)
/// 10. Utility & Getters
/// 11. Internal/Helper Functions

/// @custom:summary
/// This contract implements a Decentralized AI-Augmented Digital Collectible Platform for "Ethereal Echoes".
/// Each Echo is a unique digital asset (NFT-like, simplified implementation) with dynamic traits
/// (Intelligence, Harmony, Resilience) that can evolve based on interactions, community funding,
/// and input from an external AI oracle feed. The platform includes a simple on-chain governance
/// mechanism where Echo owners can propose and vote on parameter changes and treasury withdrawals,
/// linking ownership to participation and shaping the collective evolution of the Echoes.

/// @custom:functions
/// --- Ownership ---
/// - constructor: Initializes contract owner and AI feed address.
/// - transferOwnership: Transfers contract ownership.
/// - renounceOwnership: Renounces contract ownership (cannot be reclaimed).
/// --- Pausing ---
/// - pauseContract: Pauses key contract functionalities (owner only).
/// - unpauseContract: Unpauses the contract (owner only).
/// - isPaused: Checks pause status.
/// --- Ethereal Echo Management ---
/// - mintEcho: Mints a new Ethereal Echo with initial traits (owner only).
/// - transferEcho: Transfers an Ethereal Echo (basic transfer, requires owner permission or is owner).
/// - getEchoOwner: Gets the owner of an Echo.
/// - getEchoMetadataURI: Gets the metadata URI for an Echo.
/// - balanceOf: Gets the number of Echoes owned by an address.
/// - totalEchoes: Gets the total number of minted Echoes.
/// - getEcho: Gets the full details of an Ethereal Echo.
/// - setBaseMetadataURI: Sets the base URI for token metadata (owner only).
/// --- Dynamic Trait & Evolution ---
/// - setAIFeedAddress: Sets the trusted AI oracle feed address (owner only).
/// - requestAIAnalysis: Owner of an Echo requests an AI analysis via the oracle (requires payment).
/// - fulfillAIAnalysis: Called by the AI feed to update an Echo's Intelligence trait.
/// - resonateWithEcho: Allows an Echo owner to resonate two of their Echoes to increase Harmony.
/// - fundResilienceHardening: Allows an Echo owner to pay Ether to increase an Echo's Resilience.
/// - decayTraits: Applies time-based decay to Echo traits if not recently updated.
/// - calculateAwakeningReadiness: Calculates a score indicating how close an Echo is to Awakening.
/// - triggerAwakening: Triggers the Awakening state if an Echo meets readiness criteria.
/// - getEchoTraits: Convenience getter for just the dynamic trait values.
/// --- Governance ---
/// - proposeParameterChange: Allows Echo owners to propose changing a contract parameter or withdrawing treasury funds.
/// - voteOnProposal: Allows Echo owners to vote on an open proposal.
/// - executeProposal: Executes a successful proposal to change parameters or withdraw treasury funds.
/// - getProposalState: Gets the current state of a proposal.
/// - getProposal: Gets the full details of a proposal.
/// - hasVoted: Checks if an address has voted on a proposal.
/// --- Treasury ---
/// - depositToTreasury: Allows anyone to send Ether to the contract's treasury.
/// - getTreasuryBalance: Gets the current treasury balance.
/// --- Internal/Helper Functions (Not exposed as public functions, but crucial for logic) ---
/// - _isEchoOwner: Checks if an address owns an Echo.
/// - _transfer: Internal transfer logic (simplified).
/// - _updateEchoIntelligence: Internal trait update with capping.
/// - _updateEchoHarmony: Internal trait update with capping.
/// - _updateEchoResilience: Internal trait update with capping.
/// - _setParameter: Internal governance function to set parameters.
/// - _withdrawFromTreasury: Internal governance function for withdrawals.
/// --- Public Getters for Parameters ---
/// - getParameter: Gets the value of a specific configurable parameter.

contract EtherealEchoes {

    // --- State Variables ---

    address private _owner; // Contract owner for critical operations
    bool private _paused; // Pause state for sensitive actions
    address private _aiFeedAddress; // Address of the trusted AI oracle feed

    // ERC721-like storage (simplified - NOT a full ERC721 implementation)
    uint256 private _nextTokenId; // Counter for minting new tokens
    mapping(uint256 => address) private _tokenOwner; // Mapping token ID to owner address
    mapping(address => uint256) private _ownedTokensCount; // Mapping owner address to token count
    mapping(uint256 => EtherealEcho) private _echoes; // Mapping token ID to Echo struct
    string private _baseMetadataURI; // Base URI for token metadata

    // --- Ethereal Echo Struct ---
    struct EtherealEcho {
        uint256 id;
        uint64 creationTime;
        uint16 intelligenceScore; // Influenced by AI feed (0-100)
        uint16 harmonyLevel;      // Influenced by interactions (0-100)
        uint16 resilience;        // Influenced by funding (0-100)
        uint64 lastAIUpdateTime; // Timestamp of last AI update
        uint64 lastInteractionTime; // Timestamp of last interaction (for decay)
        bool isAwakened;          // Major state change triggered by high traits
    }

    // --- Governance State ---
    enum ProposalState { Pending, Active, Succeeded, Failed, Executed }

    struct Proposal {
        uint256 id; // Proposal identifier
        address proposer; // Address that created the proposal
        uint64 proposalTime; // Timestamp when the proposal was created
        uint256 parameterId; // Identifier for the parameter to change (see constants below)
        uint256 newValue;    // New value for the parameter OR withdrawal amount if parameterId is treasury
        address withdrawalRecipient; // Recipient for treasury withdrawal proposals (address(0) for parameter changes)
        uint256 voteCountYes; // Total voting power (Echoes) that voted 'Yes'
        uint256 voteCountNo; // Total voting power (Echoes) that voted 'No'
        uint256 totalVotingSupply; // Total number of Echoes (voting power) at the time of proposal creation
        ProposalState state; // Current state of the proposal
        mapping(address => bool) hasVoted; // Mapping to track which addresses have voted on this proposal
    }

    uint256 private _nextProposalId; // Counter for new proposals
    mapping(uint256 => Proposal) private _proposals; // Mapping proposal ID to Proposal struct

    // Mappings for adjustable parameters via governance
    mapping(uint256 => uint256) private _parameters; // e.g., _parameters[1] = decayRate, _parameters[2] = aiRequestCost

    // Parameter IDs (for governance) - Using constants for clarity
    uint256 constant private PARAM_DECAY_RATE = 1; // Time in seconds per decay unit (e.g., 86400 for 1 day)
    uint256 constant private PARAM_AI_REQUEST_COST = 2; // Cost in Wei to request AI analysis
    uint256 constant private PARAM_RESILIENCE_FUND_AMOUNT = 3; // Resilience increase per fund call (needs payment)
    uint256 constant private PARAM_PROPOSAL_QUORUM = 4; // Percentage of total supply needed for quorum (e.g., 5000 for 50.00%)
    uint256 constant private PARAM_PROPOSAL_VOTING_PERIOD = 5; // Duration of voting period in seconds
    uint256 constant private PARAM_MIN_INTELLIGENCE_AWAKEN = 6; // Minimum Intelligence score required for Awakening
    uint256 constant private PARAM_MIN_HARMONY_AWAKEN = 7;    // Minimum Harmony score required for Awakening
    uint256 constant private PARAM_MIN_RESILIENCE_AWAKEN = 8; // Minimum Resilience score required for Awakening
    uint256 constant private PARAM_TREASURY_WITHDRAW = 9; // Special ID for treasury withdrawal proposals

    // --- Events ---

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Paused(address account);
    event Unpaused(address account);
    event AIFeedAddressSet(address indexed newAddress);
    event EchoMinted(address indexed owner, uint256 indexed tokenId, string metadataURI);
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId); // Basic Transfer event (simplified)
    event TraitUpdated(uint256 indexed tokenId, string traitName, uint16 newValue); // Using uint16 as traits are capped
    event AIAnalysisRequested(uint256 indexed tokenId, address indexed requester, string query);
    event AIAnalysisFulfilled(uint256 indexed tokenId, string query, uint16 newIntelligenceScore);
    event EchoResonated(uint256 indexed tokenId1, uint256 indexed tokenId2, uint16 newHarmonyLevel1, uint16 newHarmonyLevel2);
    event ResilienceFunded(uint256 indexed tokenId, address indexed funder, uint256 amountPaid, uint16 newResilience);
    event TraitsDecayed(uint256 indexed tokenId, uint16 intelligenceDecay, uint16 harmonyDecay, uint16 resilienceDecay); // Reporting decay *amount* or new value? New value is clearer. Let's change event.
    event TraitsDecayedNewValues(uint256 indexed tokenId, uint16 newIntelligence, uint16 newHarmony, uint16 newResilience);
    event EchoAwakened(uint256 indexed tokenId);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, uint256 parameterId, uint256 newValue, address withdrawalRecipient, uint256 totalVotingSupply);
    event Voted(uint256 indexed proposalId, address indexed voter, bool vote, uint256 votingPower); // Added voting power
    event ProposalStateChanged(uint256 indexed proposalId, ProposalState newState);
    event ParameterSet(uint256 indexed parameterId, uint256 newValue);
    event TreasuryDeposited(address indexed depositor, uint256 amount);
    event TreasuryWithdrawn(address indexed recipient, uint256 amount);

    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == _owner, "Only owner can call");
        _;
    }

    modifier onlyAIFeed() {
        require(msg.sender == _aiFeedAddress, "Only AI feed can call");
        _;
    }

    modifier whenNotPaused() {
        require(!_paused, "Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(_paused, "Contract is not paused");
        _;
    }

    // Modifier to check if caller owns the specified Echo
    modifier onlyEchoOwner(uint256 tokenId) {
         require(_isEchoOwner(tokenId, msg.sender), "Caller is not Echo owner");
        _;
    }

    // --- Constructor ---

    constructor(address initialAIFeed) {
        require(initialAIFeed != address(0), "Initial AI feed address cannot be zero");
        _owner = msg.sender;
        _aiFeedAddress = initialAIFeed;
        _nextTokenId = 1; // Token IDs start from 1

        // Set initial default parameters - can be changed via governance
        _parameters[PARAM_DECAY_RATE] = 86400; // Decay roughly every 1 day of inactivity
        _parameters[PARAM_AI_REQUEST_COST] = 0.01 ether; // Example cost to request AI analysis
        _parameters[PARAM_RESILIENCE_FUND_AMOUNT] = 5; // +5 resilience per fund call
        _parameters[PARAM_PROPOSAL_QUORUM] = 5000; // 50.00% of total supply
        _parameters[PARAM_PROPOSAL_VOTING_PERIOD] = 3 days; // Voting lasts for 3 days
        _parameters[PARAM_MIN_INTELLIGENCE_AWAKEN] = 80; // Need 80 Intelligence
        _parameters[PARAM_MIN_HARMONY_AWAKEN] = 80;    // Need 80 Harmony
        _parameters[PARAM_MIN_RESILIENCE_AWAKEN] = 80; // Need 80 Resilience

         emit OwnershipTransferred(address(0), _owner);
         emit AIFeedAddressSet(_aiFeedAddress);
    }

    // --- Core Logic (Ownership) ---

    /// @notice Transfers ownership of the contract to a new account.
    /// Can only be called by the current owner.
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        _transferOwnership(newOwner);
    }

    /// @notice Renounces contract ownership.
    /// Flips ownership to the zero address. May leave the contract without an owner.
    /// Can only be called by the current owner.
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /// @dev Internal function to transfer ownership.
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    // --- Core Logic (Pausing) ---

    /// @notice Pauses the contract, preventing core functions from being called.
    /// Can only be called by the owner when the contract is not paused.
    function pauseContract() public virtual onlyOwner whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    /// @notice Unpauses the contract, allowing core functions to resume.
    /// Can only be called by the owner when the contract is paused.
    function unpauseContract() public virtual onlyOwner whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }

    /// @notice Returns the current pause status of the contract.
    function isPaused() public view returns (bool) {
        return _paused;
    }

    // --- Ethereal Echo Management ---

    /// @notice Mints a new Ethereal Echo and assigns it to a recipient.
    /// Can only be called by the contract owner.
    /// @param recipient The address that will receive the new Echo.
    /// @param metadataURI The base metadata URI for the new Echo.
    /// @return The ID of the newly minted Echo.
    function mintEcho(address recipient, string memory metadataURI) public onlyOwner whenNotPaused returns (uint256) {
        require(recipient != address(0), "Recipient is zero address");

        uint256 tokenId = _nextTokenId++;

        _echoes[tokenId] = EtherealEcho({
            id: tokenId,
            creationTime: uint64(block.timestamp),
            intelligenceScore: 1, // Start low
            harmonyLevel: 1,      // Start low
            resilience: 1,        // Start low
            lastAIUpdateTime: uint64(block.timestamp),
            lastInteractionTime: uint64(block.timestamp),
            isAwakened: false
        });

        // Simplified transfer logic: sets owner and updates counts
        _transfer(address(0), recipient, tokenId);

        // Set base URI - applies to all tokens using this contract's metadata getter
        // Consider if you want a global base URI or per-mint URI
        // Sticking to global base URI for simplicity based on first mint for now, but a separate setter is added.
        // _baseMetadataURI = metadataURI; // Let's use the explicit setter instead.

        emit EchoMinted(recipient, tokenId, metadataURI);
        // Emitting a basic Transfer event for potential compatibility (though not fully ERC721)
        emit Transfer(address(0), recipient, tokenId);

        return tokenId;
    }

    /// @notice Transfers an Ethereal Echo from one address to another.
    /// Can be called by the current owner of the Echo or the contract owner.
    /// @param from The current owner of the Echo.
    /// @param to The address to transfer the Echo to.
    /// @param tokenId The ID of the Echo to transfer.
    function transferEcho(address from, address to, uint256 tokenId) public whenNotPaused {
        require(_isEchoOwner(tokenId, from), "From address is not Echo owner");
        // Simplified authorization: must be the owner initiating transfer OR the contract owner
        require(msg.sender == from || msg.sender == _owner, "Caller not authorized for transfer");
        require(to != address(0), "Transfer to the zero address");
        require(tokenId > 0 && tokenId < _nextTokenId, "Invalid token ID");
        require(_tokenOwner[tokenId] != address(0), "Token does not exist"); // Ensure token exists

        _transfer(from, to, tokenId);

         emit Transfer(from, to, tokenId);
    }

    /// @notice Gets the owner of the specified Echo.
    /// @param tokenId The ID of the Echo.
    /// @return The address of the Echo's owner.
    function getEchoOwner(uint256 tokenId) public view returns (address) {
         require(tokenId > 0 && tokenId < _nextTokenId && _tokenOwner[tokenId] != address(0), "Token does not exist");
        return _tokenOwner[tokenId];
    }

    /// @notice Gets the metadata URI for the specified Echo.
    /// Note: This is a simplified example returning a base URI.
    /// A full implementation might append token ID, resolve dynamic traits, etc.
    /// @param tokenId The ID of the Echo.
    /// @return The metadata URI string.
    function getEchoMetadataURI(uint256 tokenId) public view returns (string memory) {
         require(tokenId > 0 && tokenId < _nextTokenId && _tokenOwner[tokenId] != address(0), "Token does not exist");
        // In a real NFT, you'd combine baseURI with token ID specifics and possibly dynamic data.
        return _baseMetadataURI;
    }

    /// @notice Sets the base metadata URI for all tokens.
    /// Can only be called by the contract owner.
    /// @param _newURI The new base URI.
    function setBaseMetadataURI(string memory _newURI) public onlyOwner {
        _baseMetadataURI = _newURI;
    }


    /// @notice Gets the number of Echoes owned by a specific address.
    /// @param owner The address to check.
    /// @return The number of Echoes owned.
    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "Owner address is zero address");
        return _ownedTokensCount[owner];
    }

    /// @notice Gets the total number of Echoes that have been minted.
    /// @return The total supply of Echoes.
    function totalEchoes() public view returns (uint256) {
        return _nextTokenId - 1; // Assuming tokenIds start at 1
    }

    /// @notice Gets the full details of a specific Ethereal Echo.
    /// Note: Calling this function does NOT implicitly trigger trait decay.
    /// Decay must be triggered manually via `decayTraits`.
    /// @param tokenId The ID of the Echo.
    /// @return The EtherealEcho struct.
    function getEcho(uint256 tokenId) public view returns (EtherealEcho memory) {
         require(tokenId > 0 && tokenId < _nextTokenId && _tokenOwner[tokenId] != address(0), "Token does not exist");
        return _echoes[tokenId];
    }


    // --- Dynamic Trait & Evolution ---

    /// @notice Sets the address of the trusted AI oracle feed.
    /// This address is authorized to call `fulfillAIAnalysis`.
    /// Can only be called by the contract owner.
    /// @param _aiFeed The address of the AI oracle feed.
    function setAIFeedAddress(address _aiFeed) public onlyOwner {
        require(_aiFeed != address(0), "AI feed address is zero");
        _aiFeedAddress = _aiFeed;
        emit AIFeedAddressSet(_aiFeed);
    }

    /// @notice Requests an AI analysis for a specific Echo via the oracle feed.
    /// Requires payment, which goes into the contract's treasury.
    /// Can only be called by the owner of the Echo.
    /// @param tokenId The ID of the Echo to analyze.
    /// @param query A string representing the query or context for the AI analysis.
    function requestAIAnalysis(uint256 tokenId, string memory query) public payable onlyEchoOwner(tokenId) whenNotPaused {
         require(_aiFeedAddress != address(0), "AI feed not set");
         uint256 requestCost = _parameters[PARAM_AI_REQUEST_COST];
         require(msg.value >= requestCost, "Insufficient payment for AI analysis");

        // Funds sent are deposited into the treasury. Excess is not refunded here for simplicity.
         emit TreasuryDeposited(msg.sender, msg.value);

        // In a real system, this event signals an off-chain process (the AI feed)
        // to perform the analysis and call `fulfillAIAnalysis` later.
        emit AIAnalysisRequested(tokenId, msg.sender, query);
    }

    /// @notice Called by the trusted AI oracle feed to fulfill an analysis request.
    /// Updates the Intelligence trait of the specified Echo.
    /// Can only be called by the configured AI feed address.
    /// @param tokenId The ID of the Echo that was analyzed.
    /// @param query The original query (for context/verification, though not strictly verified here).
    /// @param newIntelligenceScore The new Intelligence score provided by the AI feed (0-100).
    function fulfillAIAnalysis(uint256 tokenId, string memory query, uint16 newIntelligenceScore) public onlyAIFeed whenNotPaused {
         require(tokenId > 0 && tokenId < _nextTokenId && _tokenOwner[tokenId] != address(0), "Token does not exist");

         _updateEchoIntelligence(tokenId, newIntelligenceScore);
         _echoes[tokenId].lastAIUpdateTime = uint64(block.timestamp); // Record update time
         _echoes[tokenId].lastInteractionTime = uint64(block.timestamp); // Any update counts as interaction

         emit AIAnalysisFulfilled(tokenId, query, newIntelligenceScore);
    }

    /// @notice Allows an owner to "resonate" two of their Echoes.
    /// This interaction increases the Harmony trait of both Echoes.
    /// Can only be called by an address that owns both specified Echoes.
    /// @param tokenId1 The ID of the first Echo.
    /// @param tokenId2 The ID of the second Echo.
    function resonateWithEcho(uint256 tokenId1, uint256 tokenId2) public whenNotPaused {
        require(tokenId1 != tokenId2, "Cannot resonate an Echo with itself");
        require(tokenId1 > 0 && tokenId1 < _nextTokenId && _tokenOwner[tokenId1] != address(0), "Token 1 does not exist");
        require(tokenId2 > 0 && tokenId2 < _nextTokenId && _tokenOwner[tokenId2] != address(0), "Token 2 does not exist");
        require(_isEchoOwner(tokenId1, msg.sender), "Caller is not owner of Token 1");
        require(_isEchoOwner(tokenId2, msg.sender), "Caller is not owner of Token 2");

        // Simple harmony increase logic - trait updates handle the 0-100 cap
        uint16 harmonyIncrease = 5; // Example fixed increase per resonance

        _updateEchoHarmony(tokenId1, _echoes[tokenId1].harmonyLevel + harmonyIncrease);
        _updateEchoHarmony(tokenId2, _echoes[tokenId2].harmonyLevel + harmonyIncrease);

        // Update interaction time for both for decay calculation
        _echoes[tokenId1].lastInteractionTime = uint64(block.timestamp);
        _echoes[tokenId2].lastInteractionTime = uint64(block.timestamp);

        emit EchoResonated(tokenId1, tokenId2, _echoes[tokenId1].harmonyLevel, _echoes[tokenId2].harmonyLevel);
    }

    /// @notice Allows an Echo owner to send Ether to fund resilience hardening.
    /// The Ether goes to the contract treasury, and the Echo's Resilience trait increases.
    /// Can only be called by the owner of the Echo.
    /// @param tokenId The ID of the Echo to harden.
    function fundResilienceHardening(uint256 tokenId) public payable onlyEchoOwner(tokenId) whenNotPaused {
         require(msg.value > 0, "Must send Ether to fund resilience");
         require(tokenId > 0 && tokenId < _nextTokenId && _tokenOwner[tokenId] != address(0), "Token does not exist");

         // Funds sent are deposited into the treasury.
         emit TreasuryDeposited(msg.sender, msg.value);

         // Resilience increases by a fixed amount based on parameter, regardless of specific Ether amount
         uint16 resilienceIncrease = uint16(_parameters[PARAM_RESILIENCE_FUND_AMOUNT]);
         _updateEchoResilience(tokenId, _echoes[tokenId].resilience + resilienceIncrease);

         _echoes[tokenId].lastInteractionTime = uint64(block.timestamp); // Funding counts as interaction

         emit ResilienceFunded(tokenId, msg.sender, msg.value, _echoes[tokenId].resilience);
    }

    /// @notice Applies time-based decay to an Echo's traits if it has been inactive.
    /// Can be called by anyone for any Echo that is not yet Awakened and is due for decay.
    /// Traits decay if `block.timestamp` is significantly past `lastInteractionTime` based on `PARAM_DECAY_RATE`.
    /// Awakened Echoes do not decay.
    /// @param tokenId The ID of the Echo to decay.
    function decayTraits(uint256 tokenId) public whenNotPaused {
         require(tokenId > 0 && tokenId < _nextTokenId && _tokenOwner[tokenId] != address(0), "Token does not exist");

         EtherealEcho storage echo = _echoes[tokenId];
         require(!echo.isAwakened, "Awakened Echoes do not decay");

         uint64 lastUpdate = echo.lastInteractionTime;
         uint64 decayRate = uint64(_parameters[PARAM_DECAY_RATE]);
         uint64 currentTime = uint64(block.timestamp);

         // Only decay if enough time has passed
         if (currentTime > lastUpdate + decayRate) {
             uint64 decayUnits = (currentTime - lastUpdate) / decayRate; // Number of decay periods passed

             // Simple linear decay: lose 1 trait point per decay unit (capped at current value - 1)
             uint16 decayAmount = uint16(decayUnits); // Convert decay units to a decay amount

             uint16 oldIntelligence = echo.intelligenceScore;
             uint16 oldHarmony = echo.harmonyLevel;
             uint16 oldResilience = echo.resilience;

             // Apply decay, ensuring minimum score is 1
             uint16 newIntelligence = oldIntelligence > decayAmount ? oldIntelligence - decayAmount : 1;
             uint16 newHarmony = oldHarmony > decayAmount ? oldHarmony - decayAmount : 1;
             uint16 newResilience = oldResilience > decayAmount ? oldResilience - decayAmount : 1;

             _updateEchoIntelligence(tokenId, newIntelligence);
             _updateEchoHarmony(tokenId, newHarmony);
             _updateEchoResilience(tokenId, newResilience);

             // Update lastInteractionTime by the time that caused decay
             // This prevents double-decaying the same period
             echo.lastInteractionTime = lastUpdate + decayUnits * decayRate;

             emit TraitsDecayedNewValues(tokenId, newIntelligence, newHarmony, newResilience);
         }
    }

    /// @notice Calculates a score (0-100) indicating how close an Echo is to achieving Awakening.
    /// Readiness is based on meeting minimum thresholds for Intelligence, Harmony, and Resilience.
    /// @param tokenId The ID of the Echo.
    /// @return A score between 0 and 100, where 100 means ready for Awakening.
    function calculateAwakeningReadiness(uint256 tokenId) public view returns (uint256) {
         require(tokenId > 0 && tokenId < _nextTokenId && _tokenOwner[tokenId] != address(0), "Token does not exist");

         EtherealEcho memory echo = _echoes[tokenId];
         if (echo.isAwakened) {
             return 100; // Already awakened
         }

         // Fetch minimum required values from parameters
         uint256 minInt = _parameters[PARAM_MIN_INTELLIGENCE_AWAKEN];
         uint256 minHarm = _parameters[PARAM_MIN_HARMONY_AWAKEN];
         uint256 minRes = _parameters[PARAM_MIN_RESILIENCE_AWAKEN];

         // If any minimum requirement is 0, treat it as always met.
         // Calculate percentage achievement for each trait, capped at 100%.
         uint256 intScore = minInt > 0 ? (uint256(echo.intelligenceScore) * 100 / minInt) : 100;
         uint256 harmScore = minHarm > 0 ? (uint256(echo.harmonyLevel) * 100 / minHarm) : 100;
         uint256 resScore = minRes > 0 ? (uint256(echo.resilience) * 100 / minRes) : 100;

         // Cap scores at 100
         intScore = intScore > 100 ? 100 : intScore;
         harmScore = harmScore > 100 ? 100 : harmScore;
         resScore = resScore > 100 ? 100 : resScore;

         // Ensure strict minimums are met - if any trait is below its minimum, readiness is 0
         if (echo.intelligenceScore < minInt || echo.harmonyLevel < minHarm || echo.resilience < minRes) {
             return 0;
         }

         // Simple average readiness across the three traits after ensuring minimums are met
         uint256 readiness = (intScore + harmScore + resScore) / 3;

         return readiness; // Returns the averaged score if minimums met, otherwise 0
    }


    /// @notice Attempts to trigger the Awakening state for an Echo.
    /// Can only be called by the owner of the Echo if it meets the Awakening readiness criteria (readiness >= 100).
    /// An Awakened Echo may have different properties (e.g., no decay).
    /// @param tokenId The ID of the Echo to attempt to awaken.
    function triggerAwakening(uint256 tokenId) public onlyEchoOwner(tokenId) whenNotPaused {
         require(tokenId > 0 && tokenId < _nextTokenId && _tokenOwner[tokenId] != address(0), "Token does not exist");

         EtherealEcho storage echo = _echoes[tokenId];
         require(!echo.isAwakened, "Echo is already awakened");

         uint256 readiness = calculateAwakeningReadiness(tokenId);
         require(readiness >= 100, "Echo is not ready for awakening");

         echo.isAwakened = true;
         // Add logic here for Awakened Echoes (e.g., maybe their traits are now immutable, or they gain new abilities)
         // Currently, decayTraits checks the isAwakened flag.

         emit EchoAwakened(tokenId);
    }

    /// @notice Convenience getter to retrieve just the dynamic trait values and awakened status.
    /// @param tokenId The ID of the Echo.
    /// @return intelligence, harmony, resilience, isAwakened
    function getEchoTraits(uint256 tokenId) public view returns (uint16 intelligence, uint16 harmony, uint16 resilience, bool isAwakened) {
        require(tokenId > 0 && tokenId < _nextTokenId && _tokenOwner[tokenId] != address(0), "Token does not exist");
        EtherealEcho memory echo = _echoes[tokenId];
        return (echo.intelligenceScore, echo.harmonyLevel, echo.resilience, echo.isAwakened);
    }


    // --- Governance ---

    /// @notice Allows Echo owners to propose changes to contract parameters or withdraw treasury funds.
    /// Proposer must own at least one Echo.
    /// @param parameterId Identifier for the parameter to change (see PARAM_ constants). Use PARAM_TREASURY_WITHDRAW (9) for withdrawals.
    /// @param newValue The new value for the parameter or the withdrawal amount for treasury proposals.
    /// @param withdrawalRecipient The recipient address for treasury withdrawal proposals (address(0) for parameter changes).
    function proposeParameterChange(uint256 parameterId, uint256 newValue, address withdrawalRecipient) public whenNotPaused {
        // Basic voting power check: must own at least one Echo
        require(_ownedTokensCount[msg.sender] > 0, "Caller must own at least one Echo to propose");
        require(parameterId >= 1 && parameterId <= 9, "Invalid parameter ID");

        uint256 currentTotalSupply = totalEchoes();
        require(currentTotalSupply > 0, "Cannot create proposal with zero total Echoes"); // Need voters

        if (parameterId != PARAM_TREASURY_WITHDRAW) {
            // Parameter change proposal
            require(withdrawalRecipient == address(0), "Withdrawal recipient must be zero for parameter change proposals");
            require(newValue > 0, "New parameter value must be greater than zero"); // Basic sanity check
        } else {
            // Treasury withdrawal proposal
            require(withdrawalRecipient != address(0), "Withdrawal recipient required for treasury proposals");
            require(newValue > 0, "Withdrawal amount must be greater than zero");
            require(newValue <= address(this).balance, "Withdrawal amount exceeds treasury balance");
        }

        uint256 proposalId = _nextProposalId++;

        Proposal storage newProposal = _proposals[proposalId];
        newProposal.id = proposalId;
        newProposal.proposer = msg.sender;
        newProposal.proposalTime = uint64(block.timestamp);
        newProposal.parameterId = parameterId;
        newProposal.newValue = newValue;
        newProposal.withdrawalRecipient = withdrawalRecipient;
        newProposal.totalVotingSupply = currentTotalSupply; // Snapshot supply at proposal time
        newProposal.state = ProposalState.Active;

        emit ProposalCreated(proposalId, msg.sender, parameterId, newValue, withdrawalRecipient, currentTotalSupply);
        emit ProposalStateChanged(proposalId, ProposalState.Active);
    }

    /// @notice Allows Echo owners to vote on an active proposal.
    /// Voting power is proportional to the number of Echoes owned at the time of voting.
    /// Cannot vote more than once per address per proposal.
    /// @param proposalId The ID of the proposal to vote on.
    /// @param vote True for 'Yes', False for 'No'.
    function voteOnProposal(uint256 proposalId, bool vote) public whenNotPaused {
         require(proposalId < _nextProposalId, "Invalid proposal ID");
         Proposal storage proposal = _proposals[proposalId];
         require(proposal.state == ProposalState.Active, "Proposal is not active");
         uint256 votingPower = _ownedTokensCount[msg.sender];
         require(votingPower > 0, "Caller must own at least one Echo to vote"); // Need voting power
         require(!proposal.hasVoted[msg.sender], "Already voted on this proposal");
         require(uint64(block.timestamp) < proposal.proposalTime + _parameters[PARAM_PROPOSAL_VOTING_PERIOD], "Voting period has ended"); // Check if voting is still open


         proposal.hasVoted[msg.sender] = true;

         if (vote) {
             proposal.voteCountYes += votingPower; // Voting power is number of Echoes owned
         } else {
             proposal.voteCountNo += votingPower;
         }

         emit Voted(proposalId, msg.sender, vote, votingPower);
    }

    /// @notice Attempts to execute a proposal.
    /// Can be called by anyone once the voting period has ended.
    /// Checks if the proposal succeeded based on quorum and majority rules, and applies the changes or withdrawal.
    /// A proposal can only be executed once.
    /// @param proposalId The ID of the proposal to execute.
    function executeProposal(uint256 proposalId) public whenNotPaused {
         require(proposalId < _nextProposalId, "Invalid proposal ID");
         Proposal storage proposal = _proposals[proposalId];
         require(proposal.state != ProposalState.Executed, "Proposal already executed");
         require(uint64(block.timestamp) >= proposal.proposalTime + _parameters[PARAM_PROPOSAL_VOTING_PERIOD], "Voting period not ended");

         // Determine final outcome if still in Active state
         if (proposal.state == ProposalState.Active) {
             uint256 totalVotes = proposal.voteCountYes + proposal.voteCountNo;
             // Calculate quorum threshold based on snapshot supply at proposal creation
             uint256 quorumThreshold = (proposal.totalVotingSupply * _parameters[PARAM_PROPOSAL_QUORUM]) / 10000; // Quorum is % * 100

             if (totalVotes >= quorumThreshold && proposal.voteCountYes > proposal.voteCountNo) {
                 proposal.state = ProposalState.Succeeded;
                 emit ProposalStateChanged(proposalId, ProposalState.Succeeded);
             } else {
                 proposal.state = ProposalState.Failed;
                 emit ProposalStateChanged(proposalId, ProposalState.Failed);
             }
         }

         // Proceed with execution only if the proposal succeeded
         require(proposal.state == ProposalState.Succeeded, "Proposal did not succeed or failed");

         // Apply the change based on parameterId
         if (proposal.parameterId == PARAM_TREASURY_WITHDRAW) {
             // Special case for treasury withdrawal
             _withdrawFromTreasury(proposal.withdrawalRecipient, proposal.newValue);
             emit TreasuryWithdrawn(proposal.withdrawalRecipient, proposal.newValue);
         } else {
             // Standard parameter change
             _setParameter(proposal.parameterId, proposal.newValue);
             emit ParameterSet(proposal.parameterId, proposal.newValue);
         }

         // Mark proposal as executed
         proposal.state = ProposalState.Executed;
         emit ProposalStateChanged(proposalId, ProposalState.Executed);
    }

    /// @notice Gets the current state of a proposal.
    /// @param proposalId The ID of the proposal.
    /// @return The current state of the proposal (Pending, Active, Succeeded, Failed, Executed).
    function getProposalState(uint256 proposalId) public view returns (ProposalState) {
        require(proposalId < _nextProposalId, "Invalid proposal ID");
        // Automatically transition state if voting period ended but execute was not called
        // This is helpful for getters, although execution logic handles the final state setting.
        Proposal storage proposal = _proposals[proposalId];
         if (proposal.state == ProposalState.Active && uint64(block.timestamp) >= proposal.proposalTime + _parameters[PARAM_PROPOSAL_VOTING_PERIOD]) {
             // Voting period ended - determine outcome for getter
             uint256 totalVotes = proposal.voteCountYes + proposal.voteCountNo;
             uint256 quorumThreshold = (proposal.totalVotingSupply * _parameters[PARAM_PROPOSAL_QUORUM]) / 10000;
             if (totalVotes >= quorumThreshold && proposal.voteCountYes > proposal.voteCountNo) {
                 return ProposalState.Succeeded; // Succeeded if quorum met and majority yes
             } else {
                 return ProposalState.Failed; // Failed otherwise
             }
         }
        return proposal.state;
    }

    /// @notice Gets the full details of a specific proposal.
    /// @param proposalId The ID of the proposal.
    /// @return All fields of the Proposal struct.
     function getProposal(uint256 proposalId) public view returns (
         uint256 id,
         address proposer,
         uint64 proposalTime,
         uint256 parameterId,
         uint256 newValue,
         address withdrawalRecipient,
         uint256 voteCountYes,
         uint256 voteCountNo,
         uint256 totalVotingSupply,
         ProposalState state
     ) {
         require(proposalId < _nextProposalId, "Invalid proposal ID");
         Proposal storage p = _proposals[proposalId];
         // Call getProposalState to return the potentially updated state based on time
         return (
             p.id,
             p.proposer,
             p.proposalTime,
             p.parameterId,
             p.newValue,
             p.withdrawalRecipient,
             p.voteCountYes,
             p.voteCountNo,
             p.totalVotingSupply,
             getProposalState(proposalId) // Use the state getter to check time validity
         );
     }

    /// @notice Checks if a specific address has already voted on a proposal.
    /// @param proposalId The ID of the proposal.
    /// @param voter The address to check.
    /// @return True if the address has voted, false otherwise.
    function hasVoted(uint256 proposalId, address voter) public view returns (bool) {
        require(proposalId < _nextProposalId, "Invalid proposal ID");
        return _proposals[proposalId].hasVoted[voter];
    }


    // --- Treasury ---

    /// @notice Allows anyone to deposit Ether into the contract's treasury.
    /// This Ether can be used to fund AI analysis requests or be withdrawn via governance proposals.
    function depositToTreasury() public payable whenNotPaused {
        require(msg.value > 0, "Must send Ether");
        emit TreasuryDeposited(msg.sender, msg.value);
        // Ether is automatically added to the contract's balance
    }

    /// @notice Gets the current balance of Ether held in the contract's treasury.
    /// @return The treasury balance in Wei.
    function getTreasuryBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // --- Public Getters for Parameters ---

     /// @notice Gets the value of a specific configurable parameter.
     /// @param parameterId Identifier of the parameter.
     /// @return The current value of the parameter.
     function getParameter(uint256 parameterId) public view returns (uint256) {
          require(parameterId >= 1 && parameterId <= 8, "Invalid parameter ID"); // Exclude Treasury Withdraw ID from direct getter
          return _parameters[parameterId];
     }


    // --- Internal/Helper Functions ---

    /// @dev Internal check to see if an account is the owner of a specific Echo.
    function _isEchoOwner(uint256 tokenId, address account) internal view returns (bool) {
         if (tokenId == 0 || tokenId >= _nextTokenId || _tokenOwner[tokenId] == address(0)) {
             return false; // Token doesn't exist or hasn't been minted
         }
        return _tokenOwner[tokenId] == account;
    }

    /// @dev Internal simplified transfer logic. Does not handle ERC721 approvals or operator checks.
    function _transfer(address from, address to, uint256 tokenId) internal {
         // Assumes checks for tokenId, from, and to validity are done by the caller
        require(_tokenOwner[tokenId] == from, "Internal Transfer: From address is not token owner");
        require(to != address(0), "Internal Transfer: To address is zero");

        if (from != address(0)) {
            _ownedTokensCount[from]--;
        }
        _tokenOwner[tokenId] = to;
        _ownedTokensCount[to]++;

        // Note: Does not include ERC721 `onERC721Received` check for contract recipients.
        // This simplifies the implementation but makes it non-standard compliant.
    }

    /// @dev Internal helper to update intelligence score, applying 0-100 cap.
    function _updateEchoIntelligence(uint256 tokenId, uint16 newScore) internal {
        EtherealEcho storage echo = _echoes[tokenId];
        uint16 cappedScore = newScore > 100 ? 100 : newScore; // Cap at 100
        if (echo.intelligenceScore != cappedScore) {
            echo.intelligenceScore = cappedScore;
            emit TraitUpdated(tokenId, "Intelligence", cappedScore);
        }
    }

     /// @dev Internal helper to update harmony level, applying 0-100 cap.
    function _updateEchoHarmony(uint256 tokenId, uint16 newLevel) internal {
        EtherealEcho storage echo = _echoes[tokenId];
        uint16 cappedLevel = newLevel > 100 ? 100 : newLevel; // Cap at 100
         if (echo.harmonyLevel != cappedLevel) {
            echo.harmonyLevel = cappedLevel;
            emit TraitUpdated(tokenId, "Harmony", cappedLevel);
        }
    }

     /// @dev Internal helper to update resilience, applying 0-100 cap.
    function _updateEchoResilience(uint256 tokenId, uint16 newResilience) internal {
        EtherealEcho storage echo = _echoes[tokenId];
        uint16 cappedResilience = newResilience > 100 ? 100 : newResilience; // Cap at 100
         if (echo.resilience != cappedResilience) {
            echo.resilience = cappedResilience;
            emit TraitUpdated(tokenId, "Resilience", cappedResilience);
        }
    }

    /// @dev Internal function to set a contract parameter. Callable ONLY by `executeProposal`.
    function _setParameter(uint256 parameterId, uint256 value) internal {
         // Add checks here if certain parameters have specific constraints (e.g., quorum can't be >10000)
         require(parameterId >= 1 && parameterId <= 8, "Internal: Invalid parameter ID for setting"); // Exclude Treasury Withdraw ID
         _parameters[parameterId] = value;
         // ParameterSet event is emitted in executeProposal
    }

     /// @dev Internal function to withdraw from the treasury. Callable ONLY by `executeProposal`.
    function _withdrawFromTreasury(address recipient, uint256 amount) internal {
         require(recipient != address(0), "Internal: Withdrawal recipient is zero");
         require(amount > 0, "Internal: Withdrawal amount must be greater than zero");
         require(amount <= address(this).balance, "Internal: Insufficient treasury balance for withdrawal");

         // Use a low-level call for sending Ether
         (bool success, ) = payable(recipient).call{value: amount}("");
         require(success, "Internal: Treasury withdrawal failed");
         // TreasuryWithdrawn event is emitted in executeProposal
    }

    // Fallback/Receive function to allow receiving Ether into the treasury directly
    receive() external payable {
        depositToTreasury(); // Direct Ether sends also go to treasury, trigger event
    }

    // Fallback function for calls without data
    fallback() external payable {
        depositToTreasury(); // Calls with Ether but no data also go to treasury
    }

}
```