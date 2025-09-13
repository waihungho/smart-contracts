This smart contract, **AetherID**, introduces a decentralized, AI-driven identity and reputation network. It aims to provide users with a unique, evolving digital identity (a Soulbound Dynamic Profile NFT) that reflects their on-chain activities, reputation, and acquired skills. Crucially, it integrates a personal AI Agent module, allowing users to configure deterministic on-chain logic that can propose or execute actions based on their identity and preferences, all governed by a decentralized autonomous organization (DAO).

---

## **AetherID: Decentralized AI-Driven Identity & Reputation Network**

### **Contract Outline:**

The `AetherID` contract is a multifaceted system built on several interconnected modules:

1.  **Soulbound Identity & Dynamic Profile NFT (DPN):** An ERC721 token that serves as a user's unique, non-transferable digital identity. Its metadata (visuals) dynamically evolve based on the user's reputation, skills, and chosen traits, rendered directly on-chain using Base64-encoded SVG/JSON.
2.  **Reputation System:** Users accumulate a reputation score based on verifiable contributions (via a trusted oracle) and on-chain activity. This score influences voting power in the DAO, unlocks access to features (like deploying an AI agent), and impacts the DPN's appearance. A decay mechanism encourages active participation.
3.  **Personal AI Agent Module:** Users can deploy and configure a personalized, on-chain "AI agent." This agent, driven by deterministic logic and user-defined parameters (e.g., focus areas, risk tolerance), can suggest actions, manage micro-transactions (if pre-authorized), or curate opportunities. The agent's "intelligence" is external (off-chain) but its actions are executed securely on-chain based on user's authorization and contract state.
4.  **Skill/Trait Token System:** Non-transferable "Skill Tokens" (conceptually similar to Soulbound Tokens or badges) represent achievements, expertise, or verified attributes. These can be prerequisites for agent capabilities or higher reputation tiers, and can be visually represented on the DPN.
5.  **DAO Governance:** The entire AetherID protocol, including critical parameter changes, upgrades, and administrative actions (e.g., revoking an ID, granting high-value skills), is governed by a decentralized autonomous organization where voting power is weighted by a user's reputation score.
6.  **Oracle Integration:** A mechanism for a trusted oracle to submit verifiable proofs for off-chain contributions or data, feeding into the reputation system.

### **Function Summary:**

Here's a summary of the key external/public functions:

**Section 1: Soulbound Identity Token (SIT) & Dynamic Profile NFT (DPN) Management**
*   `createAetherID()`: Mints a new soulbound Dynamic Profile NFT (DPN) for the caller, establishing their unique AetherID. Each user can only mint one.
*   `revokeAetherID(address _user)`: (Admin/DAO-controlled) Revokes a user's AetherID, burning their DPN and resetting associated data.
*   `tokenURI(uint256 _tokenId)`: (ERC721 Override) Generates a dynamic, on-chain base64 encoded JSON metadata URI for the DPN, reflecting reputation, skills, and selected traits.
*   `customizeProfileNFT(uint256 _tokenId, uint256[] calldata _traitIndices)`: Allows DPN owners to select which owned traits are displayed on their profile.
*   `setBaseTokenURI(string memory _newBaseURI)`: (Owner-only) Sets a fallback base URI for DPN metadata, if needed for complex off-chain rendering.

**Section 2: Reputation System**
*   `getReputation(address _user)`: Retrieves the current reputation score of a user.
*   `submitVerifiedContribution(address _user, bytes32 _proofHash, uint256 _contributionScore)`: (Oracle-only) Adds reputation points to a user based on a verifiable off-chain contribution.
*   `triggerReputationDecay(address _user)`: (Public/Keeper) Triggers reputation decay for a specific user if their decay period has passed.
*   `setReputationDecayParameters(uint256 _rate, uint256 _period)`: (Owner/DAO-only) Configures the rate and period for reputation decay.

**Section 3: AI Agent (Personalized Logic Module)**
*   `deployPersonalAIAgent()`: Deploys (activates) a personal AI agent for the caller, provided they meet the minimum reputation threshold.
*   `setAgentParameters(bytes32 _focusArea, uint256 _riskTolerance)`: Allows users to configure their agent's operational parameters (e.g., focus, risk appetite).
*   `requestAgentRecommendation(bytes32 _context)`: Users can request recommendations from their agent; this emits an event for off-chain processing.
*   `authorizeAgentAction(address _targetContract, bytes calldata _callData, uint256 _value, uint256 _authorizedUntil)`: Users pre-authorize specific actions their agent can execute on their behalf for a defined period.
*   `executeAgentAction(address _user, uint256 _actionId)`: Executes a pre-authorized agent action. Typically triggered by an off-chain keeper service, verifying on-chain authorization.

**Section 4: Skill/Trait Tokens (STT) Management**
*   `grantSkillToken(address _user, uint256 _skillId)`: (Owner/DAO/Oracle-only) Grants a specific skill token to a user, potentially boosting reputation.
*   `revokeSkillToken(address _user, uint256 _skillId)`: (Owner/DAO/Oracle-only) Revokes a skill token from a user, potentially incurring a reputation penalty.
*   `hasSkill(address _user, uint256 _skillId)`: Checks if a user possesses a specific skill.
*   `registerNewSkill(string memory _metadataURI)`: (Owner/DAO-only) Registers a new type of skill token with its metadata.

**Section 5: DAO Governance**
*   `createProposal(string calldata _description, address _target, bytes calldata _callData)`: Allows reputable users to create new governance proposals.
*   `voteOnProposal(uint256 _proposalId, bool _support)`: Users vote on proposals, with their voting power weighted by their reputation.
*   `executeProposal(uint256 _proposalId)`: Executes a successfully passed proposal after the voting period ends.
*   `setMinReputationToPropose(uint256 _minRep)`: (Owner/DAO-only) Sets the minimum reputation required to create proposals.
*   `setVotingPeriodDuration(uint256 _duration)`: (Owner/DAO-only) Sets the length of the voting period for proposals.

**Section 6: Oracle & Admin**
*   `setOracleAddress(address _oracle)`: (Owner-only) Sets the address of the trusted oracle for reputation contributions.
*   `withdrawFunds(address _to, uint256 _amount)`: (Owner/DAO-only) Allows withdrawal of funds from the contract.

---
**Smart Contract Source Code:**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

/**
 * @title AetherID: Decentralized AI-Driven Identity & Reputation Network
 * @dev This contract implements a unique identity system combining Soulbound Dynamic NFTs,
 *      a reputation score, on-chain configurable (but off-chain logic driven) AI agents,
 *      skill/trait tokens, and DAO governance.
 *
 * Concepts:
 * - Soulbound Identity Token (SIT) / Dynamic Profile NFT (DPN): An ERC721 token representing
 *   a user's identity, which cannot be transferred and whose metadata dynamically updates.
 * - Reputation System: Tracks user standing based on contributions and activity, influencing access
 *   and voting power, with a decay mechanism.
 * - Personal AI Agent: A configurable module that enables a user's on-chain persona to make
 *   suggestions or execute pre-authorized actions based on identity data and user parameters.
 * - Skill/Trait Tokens (STT): Non-transferable tokens signifying achievements or expertise.
 * - DAO Governance: The entire protocol is governed by reputation-weighted voting.
 * - On-chain Metadata: DPN metadata is generated directly on-chain using Base64-encoded SVG/JSON.
 */
contract AetherID is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;
    using Strings for address;

    // --- State Variables ---

    // DPN (Dynamic Profile NFT) - The core identity token
    Counters.Counter private _tokenIdCounter;
    mapping(address => uint256) public userAetherIdTokenId; // Maps user address to their DPN Token ID
    mapping(uint256 => bool) public isSoulbound; // Marks a token as soulbound (non-transferable)
    string[] public availableTraits; // List of trait identifiers users can apply to their DPN
    mapping(uint256 => uint256[]) public tokenAppliedTraits; // tokenId => array of trait indices applied

    // Reputation System
    mapping(address => int256) public userReputation;
    uint256 public constant MIN_REPUTATION_FOR_AGENT = 100; // Minimum reputation to deploy an AI Agent
    uint256 public reputationDecayRatePerPeriod; // How much reputation decays per period
    uint256 public reputationDecayPeriod;        // Time in seconds for one decay period
    mapping(address => uint256) public lastReputationUpdateTimestamp; // To track decay for each user

    // AI Agent (Personalized Logic Module)
    struct AgentParameters {
        bool isActive;
        bytes32 focusArea; // e.g., "defi", "gaming", "social" (hash of string)
        uint256 riskTolerance; // 0-100
        uint256 lastRecommendationTime; // Timestamp of last recommendation request
    }
    mapping(address => AgentParameters) public agentConfigurations;

    // For agent actions, we need a way to pre-authorize them
    struct AgentAction {
        address targetContract;
        bytes callData;
        uint256 value;
        uint256 authorizedUntil; // Timestamp until which this action is valid
        bool executed;
    }
    mapping(address => mapping(uint256 => AgentAction)) public authorizedAgentActions;
    Counters.Counter private _actionIdCounter; // Per user counter for agent actions

    // Skill/Trait Tokens (STT) - Non-transferable badges/achievements
    mapping(address => mapping(uint256 => bool)) public userSkills; // user => skillId => hasSkill
    uint256 private _nextSkillId = 1; // Counter for new skill IDs
    mapping(uint256 => string) public skillMetadataURI; // skillId => URI to skill metadata

    // DAO Governance
    struct Proposal {
        uint256 id;
        string description;
        address target;
        bytes callData;
        uint256 creationTime;
        uint256 votingEndTime;
        uint256 totalVotesFor;
        uint256 totalVotesAgainst;
        mapping(address => bool) hasVoted; // User has voted on this proposal
        bool executed; // True if execution attempted (successful or not)
        bool passed;   // True if votes passed, regardless of execution success
    }
    mapping(uint256 => Proposal) public proposals;
    Counters.Counter public proposalCounter;
    uint256 public minReputationToPropose = 500; // Min reputation to create a proposal
    uint256 public votingPeriodDuration = 3 days; // Default voting period

    // Oracle Integration
    address public trustedOracle; // Address of the trusted oracle for reputation updates

    // --- Events ---
    event AetherIDCreated(address indexed owner, uint256 tokenId);
    event ReputationUpdated(address indexed user, int256 newReputation, int256 delta);
    event ContributionVerified(address indexed user, bytes32 proofHash, uint256 scoreAdded);
    event ProfileNFTMetadataUpdated(uint256 indexed tokenId, string newURI);
    event AgentDeployed(address indexed user);
    event AgentParametersUpdated(address indexed user, bytes32 paramKey, uint256 paramValue);
    event AgentRecommendationRequested(address indexed user, bytes32 context);
    event AgentActionAuthorized(address indexed user, uint256 actionId, address target, bytes callData);
    event AgentActionExecuted(address indexed user, uint256 actionId);
    event SkillGranted(address indexed user, uint256 indexed skillId);
    event SkillRevoked(address indexed user, uint256 indexed skillId);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer);
    event ProposalVoted(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId, bool success);

    // --- Modifiers ---
    modifier onlyAetherIDOwner(uint256 _tokenId) {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "AetherID: Caller is not NFT owner");
        _;
    }

    modifier onlyReputable(uint256 _minRep) {
        require(userReputation[msg.sender] >= int256(_minRep), "AetherID: Insufficient reputation");
        _;
    }

    modifier onlyOracle() {
        require(msg.sender == trustedOracle, "AetherID: Caller is not the trusted oracle");
        _;
    }

    // --- Constructor ---
    constructor() ERC721("AetherID Dynamic Profile", "AETHERID_DP") Ownable(msg.sender) {
        reputationDecayRatePerPeriod = 5; // Decay 5 points per period
        reputationDecayPeriod = 7 days;   // Every 7 days
    }

    // --- Section 1: Soulbound Identity Token (SIT) & Dynamic Profile NFT (DPN) Management ---

    /// @notice Creates a new AetherID (Dynamic Profile NFT) for the caller. Each user can only have one.
    /// @dev This mints a new ERC721 token that acts as the user's soulbound identity.
    function createAetherID() external {
        require(userAetherIdTokenId[msg.sender] == 0, "AetherID: Already exists for this address");

        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        _safeMint(msg.sender, newTokenId);
        isSoulbound[newTokenId] = true; // Mark as soulbound
        userAetherIdTokenId[msg.sender] = newTokenId;
        lastReputationUpdateTimestamp[msg.sender] = block.timestamp; // Initialize for decay tracking

        emit AetherIDCreated(msg.sender, newTokenId);
    }

    /// @notice Revokes an AetherID and its associated Dynamic Profile NFT.
    /// @dev This is a powerful, administrative function and should be used with extreme caution, likely via DAO governance.
    /// It burns the NFT and resets the user's identity data, including reputation, agent config, and skills.
    /// @param _user The address of the user whose AetherID is to be revoked.
    function revokeAetherID(address _user) external onlyOwner { // In a full DAO, this would be a DAO-governed proposal.
        uint256 tokenId = userAetherIdTokenId[_user];
        require(tokenId != 0, "AetherID: No AetherID found for this address");

        _burn(tokenId);
        delete userAetherIdTokenId[_user];
        delete isSoulbound[tokenId];
        delete userReputation[_user];
        delete agentConfigurations[_user]; // Clear agent config
        delete lastReputationUpdateTimestamp[_user];
        // TODO: iterate and clear all userSkills[_user] if gas allows, or mark them as invalid.

        emit AetherIDCreated(_user, 0); // Emit 0 to signify revocation
    }

    /// @notice Custom `transferFrom` override to enforce soulbound nature.
    function _transfer(address from, address to, uint256 tokenId) internal override {
        require(!isSoulbound[tokenId], "AetherID: Tokens are soulbound and cannot be transferred.");
        super._transfer(from, to, tokenId);
    }

    /// @notice Custom `approve` override to restrict approvals for soulbound tokens.
    function approve(address to, uint256 tokenId) public override {
        require(!isSoulbound[tokenId], "AetherID: Cannot approve soulbound tokens.");
        super.approve(to, tokenId);
    }

    /// @notice Custom `setApprovalForAll` override to restrict approvals for soulbound tokens.
    function setApprovalForAll(address operator, bool approved) public override {
        uint256 tokenId = userAetherIdTokenId[msg.sender];
        if (tokenId != 0 && isSoulbound[tokenId]) {
            require(!approved, "AetherID: Cannot set approval for all for soulbound tokens.");
        }
        super.setApprovalForAll(operator, approved);
    }

    /// @notice Returns the URI for the Dynamic Profile NFT metadata.
    /// @dev This function dynamically generates a base64 encoded JSON, making it "on-chain" metadata.
    /// It includes the user's reputation, skills, and selected traits, and a basic SVG image.
    /// @param _tokenId The token ID of the AetherID (DPN).
    /// @return string The base64 encoded JSON metadata URI.
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        address owner = ownerOf(_tokenId);

        string memory reputationStr = userReputation[owner].toString();
        string memory name = string(abi.encodePacked("AetherID Profile #", _tokenId.toString()));
        string memory description = string(abi.encodePacked("Dynamic identity profile for ", owner.toHexString()));

        string memory attributesList = "";
        // Add reputation as an attribute
        attributesList = string(abi.encodePacked('{"trait_type": "Reputation Score", "value": ', reputationStr, '}'));

        // Add selected traits
        for (uint256 i = 0; i < tokenAppliedTraits[_tokenId].length; i++) {
            uint256 traitIndex = tokenAppliedTraits[_tokenId][i];
            if (traitIndex < availableTraits.length) {
                attributesList = string(abi.encodePacked(attributesList, ',{"trait_type": "Selected Trait", "value": "', availableTraits[traitIndex], '"}'));
            }
        }
        // Add owned skills as attributes
        uint256 tempSkillId = 1;
        while(tempSkillId < _nextSkillId) {
            if (userSkills[owner][tempSkillId]) {
                 attributesList = string(abi.encodePacked(attributesList, ',{"trait_type": "Skill", "value": "', skillMetadataURI[tempSkillId], '"}'));
            }
            tempSkillId++;
        }


        // Basic on-chain SVG placeholder for an image
        string memory imageSVG = string(abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" width="300" height="300" viewBox="0 0 300 300">',
            '<rect width="100%" height="100%" fill="#', uintToHex(uint256(uint160(owner)) % 16777215), '"/>', // Unique background color
            '<circle cx="150" cy="120" r="80" fill="#ffffff" stroke="#000000" stroke-width="2"/>',
            '<text x="150" y="150" font-family="monospace" font-size="20" fill="#000000" text-anchor="middle">ID: ', _tokenId.toString(), '</text>',
            '<text x="150" y="180" font-family="monospace" font-size="15" fill="#000000" text-anchor="middle">Rep: ', reputationStr, '</text>',
            // Add more dynamic elements based on skills or traits here (e.g., small icons for skills)
            '</svg>'
        ));

        string memory json = string(abi.encodePacked(
            'data:application/json;base64,',
            Base64.encode(
                bytes(
                    abi.encodePacked(
                        '{"name": "', name, '",',
                        '"description": "', description, '",',
                        '"image": "data:image/svg+xml;base64,', Base64.encode(bytes(imageSVG)), '",',
                        '"attributes": [', attributesList, ']}'
                    )
                )
            )
        ));
        return json;
    }

    /// @notice Allows the owner of an AetherID (DPN) to select traits to display on their profile.
    /// @dev Selected traits must be available in `availableTraits`. This triggers a metadata update.
    /// @param _tokenId The token ID of the DPN.
    /// @param _traitIndices An array of indices corresponding to `availableTraits`.
    function customizeProfileNFT(uint256 _tokenId, uint256[] calldata _traitIndices) external onlyAetherIDOwner(_tokenId) {
        require(_tokenId == userAetherIdTokenId[msg.sender], "AetherID: Not your AetherID token.");
        for (uint256 i = 0; i < _traitIndices.length; i++) {
            require(_traitIndices[i] < availableTraits.length, "AetherID: Invalid trait index.");
            // Future: Add a check here if user "owns" a trait via SkillToken
        }
        tokenAppliedTraits[_tokenId] = _traitIndices;
        emit ProfileNFTMetadataUpdated(_tokenId, tokenURI(_tokenId)); // Signal metadata change
    }

    /// @notice Sets the base URI for fallback or external metadata.
    /// @dev Used if the on-chain metadata generation becomes too complex or large.
    /// @param _newBaseURI The new base URI.
    function addAvailableTrait(string memory _traitIdentifier) external onlyOwner {
        availableTraits.push(_traitIdentifier);
    }

    // --- Section 2: Reputation System ---

    /// @notice Retrieves the current reputation score for a given user.
    /// @param _user The address of the user.
    /// @return int256 The current reputation score.
    function getReputation(address _user) public view returns (int256) {
        return userReputation[_user];
    }

    /// @notice Allows a trusted oracle to submit verifiable proofs for user contributions, increasing reputation.
    /// @dev The `_proofHash` could be an IPFS hash of a ZK-proof or a signed message from an off-chain verifier.
    /// @param _user The user who made the contribution.
    /// @param _proofHash A hash representing the verifiable proof of contribution.
    /// @param _contributionScore The reputation points to add.
    function submitVerifiedContribution(address _user, bytes32 _proofHash, uint256 _contributionScore) external onlyOracle {
        require(userAetherIdTokenId[_user] != 0, "AetherID: User must have an AetherID to receive reputation.");
        _updateReputation(_user, int256(_contributionScore));
        emit ContributionVerified(_user, _proofHash, _contributionScore);
    }

    /// @notice Triggers a global reputation decay for a specific AetherID.
    /// @dev This function should be called periodically by a keeper or a decentralized cron service.
    /// For a full system, this would need to handle batch processing or be called for all active users.
    /// @param _user The user for whom to trigger reputation decay.
    function triggerReputationDecay(address _user) external {
        require(userAetherIdTokenId[_user] != 0, "AetherID: User does not have an AetherID.");
        uint256 lastUpdate = lastReputationUpdateTimestamp[_user];
        if (block.timestamp >= lastUpdate + reputationDecayPeriod) {
            uint256 periodsPassed = (block.timestamp - lastUpdate) / reputationDecayPeriod;
            int256 decayAmount = int256(periodsPassed) * int256(reputationDecayRatePerPeriod);
            if (userReputation[_user] > 0) {
                 int256 newRep = userReputation[_user] - decayAmount;
                 _updateReputation(_user, newRep - userReputation[_user]); // Pass delta
            }
            lastReputationUpdateTimestamp[_user] = block.timestamp; // Update timestamp
        }
    }

    /// @notice Sets the reputation decay rate and period.
    /// @param _rate The amount of reputation to decay per period.
    /// @param _period The duration of the decay period in seconds.
    function setReputationDecayParameters(uint256 _rate, uint256 _period) external onlyOwner { // Or DAO
        reputationDecayRatePerPeriod = _rate;
        reputationDecayPeriod = _period;
    }

    /// @dev Internal function to update a user's reputation and trigger DPN metadata update.
    /// @param _user The address of the user.
    /// @param _delta The amount to change reputation by (can be positive or negative).
    function _updateReputation(address _user, int252 _delta) internal {
        userReputation[_user] += _delta;
        // Ensure reputation doesn't go negative
        if (userReputation[_user] < 0) {
            userReputation[_user] = 0;
        }
        // Emit event and potentially update DPN metadata
        uint256 tokenId = userAetherIdTokenId[_user];
        if (tokenId != 0) {
            emit ProfileNFTMetadataUpdated(tokenId, tokenURI(tokenId));
        }
        emit ReputationUpdated(_user, userReputation[_user], _delta);
    }

    // --- Section 3: AI Agent (Personalized Logic Module) ---

    /// @notice Deploys a personal AI agent for the caller.
    /// @dev Requires a minimum reputation score. Each user can only deploy one agent.
    function deployPersonalAIAgent() external onlyReputable(MIN_REPUTATION_FOR_AGENT) {
        require(userAetherIdTokenId[msg.sender] != 0, "AetherID: Must have an AetherID to deploy agent.");
        require(!agentConfigurations[msg.sender].isActive, "AetherID: Agent already deployed for this address.");

        agentConfigurations[msg.sender].isActive = true;
        // Set default parameters
        agentConfigurations[msg.sender].focusArea = bytes32(abi.encodePacked("general"));
        agentConfigurations[msg.sender].riskTolerance = 50; // default 50%
        emit AgentDeployed(msg.sender);
    }

    /// @notice Allows the user to configure parameters for their AI agent.
    /// @param _focusArea The primary focus area for the agent (e.g., hash of "defi", "gaming").
    /// @param _riskTolerance A value from 0 to 100 representing risk appetite.
    function setAgentParameters(bytes32 _focusArea, uint256 _riskTolerance) external {
        require(agentConfigurations[msg.sender].isActive, "AetherID: Agent not deployed.");
        require(_riskTolerance <= 100, "AetherID: Risk tolerance must be between 0 and 100.");

        agentConfigurations[msg.sender].focusArea = _focusArea;
        agentConfigurations[msg.sender].riskTolerance = _riskTolerance;
        emit AgentParametersUpdated(msg.sender, _focusArea, _riskTolerance);
    }

    /// @notice User requests a recommendation from their AI agent.
    /// @dev This function emits an event. The actual recommendation logic (off-chain)
    /// would listen to this event, process data, and potentially update an off-chain profile or push a notification.
    /// @param _context An arbitrary context (hash of string) for the recommendation request.
    function requestAgentRecommendation(bytes32 _context) external {
        require(agentConfigurations[msg.sender].isActive, "AetherID: Agent not deployed.");
        agentConfigurations[msg.sender].lastRecommendationTime = block.timestamp; // Update last request time
        emit AgentRecommendationRequested(msg.sender, _context);
    }

    /// @notice User pre-authorizes their agent to perform a specific action.
    /// @dev The agent can then call `executeAgentAction` for the user within the `authorizedUntil` period.
    /// @param _targetContract The address of the contract the agent will interact with.
    /// @param _callData The encoded function call data for the target contract.
    /// @param _value The amount of ETH (if any) to send with the transaction.
    /// @param _authorizedUntil Timestamp until which this authorization is valid.
    function authorizeAgentAction(address _targetContract, bytes calldata _callData, uint256 _value, uint256 _authorizedUntil) external {
        require(agentConfigurations[msg.sender].isActive, "AetherID: Agent not deployed.");
        require(_authorizedUntil > block.timestamp, "AetherID: Authorization must be for a future time.");

        _actionIdCounter.increment();
        uint256 newActionId = _actionIdCounter.current();

        AgentAction storage newAction = authorizedAgentActions[msg.sender][newActionId];
        newAction.targetContract = _targetContract;
        newAction.callData = _callData;
        newAction.value = _value;
        newAction.authorizedUntil = _authorizedUntil;
        newAction.executed = false;

        emit AgentActionAuthorized(msg.sender, newActionId, _targetContract, _callData);
    }

    /// @notice Executes a pre-authorized action via the AI agent.
    /// @dev This function can be called by a trusted relayer or the DAO, verifying agent authorization.
    /// It's designed to be invoked by an external keeper service that runs the agent's logic off-chain
    /// and then triggers the on-chain execution if conditions are met and authorized.
    /// @param _user The user whose agent is executing the action.
    /// @param _actionId The ID of the pre-authorized action.
    function executeAgentAction(address _user, uint256 _actionId) external {
        // For enhanced security, this function could be restricted to a whitelisted keeper,
        // or require DAO approval for high-value transactions.
        AgentAction storage action = authorizedAgentActions[_user][_actionId];
        require(action.targetContract != address(0), "AetherID: Action does not exist.");
        require(!action.executed, "AetherID: Action already executed.");
        require(block.timestamp <= action.authorizedUntil, "AetherID: Authorization expired.");

        // The 'AI agent's' decision logic (e.g., whether to execute based on market conditions,
        // user's risk tolerance, focus area, etc.) happens off-chain. This on-chain function
        // merely validates the user's prior authorization and executes.

        (bool success, ) = action.targetContract.call{value: action.value}(action.callData);
        require(success, "AetherID: Agent action execution failed.");

        action.executed = true;
        emit AgentActionExecuted(_user, _actionId);
    }

    // --- Section 4: Skill/Trait Tokens (STT) Management ---

    /// @notice Grants a specific skill token to a user.
    /// @dev This is typically called by an admin, oracle, or DAO after verification of a skill.
    /// @param _user The address of the user to grant the skill to.
    /// @param _skillId The ID of the skill token.
    function grantSkillToken(address _user, uint256 _skillId) external onlyOwner { // Or only DAO/Oracle
        require(userAetherIdTokenId[_user] != 0, "AetherID: User must have an AetherID to receive skills.");
        require(!userSkills[_user][_skillId], "AetherID: User already has this skill.");
        userSkills[_user][_skillId] = true;

        // Optionally, update reputation or DPN metadata
        _updateReputation(_user, 10); // Small reputation boost for a new skill
        emit SkillGranted(_user, _skillId);
    }

    /// @notice Revokes a skill token from a user.
    /// @dev Administrative function.
    /// @param _user The user whose skill is to be revoked.
    /// @param _skillId The ID of the skill token.
    function revokeSkillToken(address _user, uint256 _skillId) external onlyOwner { // Or only DAO/Oracle
        require(userSkills[_user][_skillId], "AetherID: User does not have this skill.");
        userSkills[_user][_skillId] = false;

        _updateReputation(_user, -5); // Small reputation penalty
        emit SkillRevoked(_user, _skillId);
    }

    /// @notice Checks if a user possesses a specific skill.
    /// @param _user The address of the user.
    /// @param _skillId The ID of the skill.
    /// @return bool True if the user has the skill, false otherwise.
    function hasSkill(address _user, uint256 _skillId) public view returns (bool) {
        return userSkills[_user][_skillId];
    }

    /// @notice Registers a new skill and its metadata URI.
    /// @dev Only callable by the contract owner or DAO.
    /// @param _metadataURI The URI pointing to the metadata of the new skill.
    /// @return uint256 The ID of the newly registered skill.
    function registerNewSkill(string memory _metadataURI) external onlyOwner returns (uint256) {
        uint256 newSkillId = _nextSkillId++;
        skillMetadataURI[newSkillId] = _metadataURI;
        return newSkillId;
    }

    // --- Section 5: DAO Governance ---

    /// @notice Creates a new governance proposal.
    /// @dev Requires a minimum reputation score to propose.
    /// @param _description A detailed description of the proposal.
    /// @param _target The target contract address for the proposal's execution.
    /// @param _callData The encoded function call data for the target contract.
    function createProposal(string calldata _description, address _target, bytes calldata _callData) external onlyReputable(minReputationToPropose) {
        proposalCounter.increment();
        uint256 newProposalId = proposalCounter.current();

        Proposal storage p = proposals[newProposalId];
        p.id = newProposalId;
        p.description = _description;
        p.target = _target;
        p.callData = _callData;
        p.creationTime = block.timestamp;
        p.votingEndTime = block.timestamp + votingPeriodDuration;

        emit ProposalCreated(newProposalId, msg.sender);
    }

    /// @notice Allows users to vote on an active proposal.
    /// @dev Voting power is determined by reputation. One address, one vote.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _support True for "for" vote, false for "against" vote.
    function voteOnProposal(uint256 _proposalId, bool _support) external {
        Proposal storage p = proposals[_proposalId];
        require(p.creationTime != 0, "AetherID: Proposal does not exist.");
        require(block.timestamp <= p.votingEndTime, "AetherID: Voting period has ended.");
        require(!p.hasVoted[msg.sender], "AetherID: Already voted on this proposal.");
        require(userReputation[msg.sender] > 0, "AetherID: Must have reputation to vote.");

        p.hasVoted[msg.sender] = true;
        if (_support) {
            p.totalVotesFor += uint256(userReputation[msg.sender]); // Reputation-weighted vote
        } else {
            p.totalVotesAgainst += uint256(userReputation[msg.sender]);
        }
        emit ProposalVoted(_proposalId, msg.sender, _support);
    }

    /// @notice Executes a successfully passed proposal.
    /// @dev Can be called by anyone after the voting period ends and if the proposal passed.
    /// @param _proposalId The ID of the proposal to execute.
    function executeProposal(uint256 _proposalId) external {
        Proposal storage p = proposals[_proposalId];
        require(p.creationTime != 0, "AetherID: Proposal does not exist.");
        require(block.timestamp > p.votingEndTime, "AetherID: Voting period has not ended.");
        require(!p.executed, "AetherID: Proposal already executed.");

        bool success = false;
        if (p.totalVotesFor > p.totalVotesAgainst) {
            p.passed = true;
            (success, ) = p.target.call(p.callData);
            p.executed = true; // Mark as executed even if call fails to prevent re-execution attempts
        } else {
            p.passed = false; // Failed to pass
            p.executed = true; // Mark as executed (failed)
        }
        emit ProposalExecuted(_proposalId, success);
        require(success, "AetherID: Proposal execution failed."); // Revert if call failed
    }

    /// @notice Sets the minimum reputation required to create a proposal.
    /// @param _minRep The new minimum reputation.
    function setMinReputationToPropose(uint256 _minRep) external onlyOwner { // Or DAO
        minReputationToPropose = _minRep;
    }

    /// @notice Sets the duration of the voting period for proposals.
    /// @param _duration The new duration in seconds.
    function setVotingPeriodDuration(uint256 _duration) external onlyOwner { // Or DAO
        votingPeriodDuration = _duration;
    }

    // --- Section 6: Oracle & Admin ---

    /// @notice Sets the address of the trusted oracle.
    /// @param _oracle The address of the new oracle.
    function setOracleAddress(address _oracle) external onlyOwner {
        require(_oracle != address(0), "AetherID: Oracle address cannot be zero.");
        trustedOracle = _oracle;
    }

    /// @notice Allows the owner or DAO to withdraw funds from the contract.
    /// @param _to The address to send the funds to.
    /// @param _amount The amount of funds to withdraw.
    function withdrawFunds(address _to, uint256 _amount) external onlyOwner { // Or DAO control
        require(address(this).balance >= _amount, "AetherID: Insufficient balance.");
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "AetherID: Failed to withdraw funds.");
    }

    // --- Internal Helpers ---
    /// @dev Converts a uint256 to its hexadecimal representation (for SVG color generation).
    function uintToHex(uint256 value) internal pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(6); // Max 6 chars for a 24-bit color (FFFFFF)
        for (uint256 i = 0; i < 6; i++) {
            str[5 - i] = alphabet[value % 16];
            value /= 16;
        }
        return string(str);
    }

    // Allows the contract to receive ETH
    receive() external payable {}
    fallback() external payable {}
}
```