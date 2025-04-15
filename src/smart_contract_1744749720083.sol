```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title EvolvingDigitalPersona - A Dynamic NFT and Reputation System
 * @author Bard (Example Smart Contract)
 *
 * @dev This contract implements a dynamic NFT that represents a user's evolving digital persona.
 * It incorporates reputation mechanics, skill development, social interactions, and on-chain governance
 * to create a rich and engaging user experience.  This is a conceptual and illustrative example,
 * and may require further security audits and refinements for production use.
 *
 * Function Summary:
 *
 * **Initialization & Admin:**
 * 1. `constructor(string memory _name, string memory _symbol)`: Deploys the contract with NFT name and symbol.
 * 2. `setBaseURI(string memory _baseURI)`: Sets the base URI for metadata retrieval.
 * 3. `setOracleAddress(address _oracleAddress)`: Sets the address authorized to provide external data/randomness.
 * 4. `setGovernanceAddress(address _governanceAddress)`: Sets the address for governance functions.
 * 5. `pauseContract()`: Pauses most contract functionalities.
 * 6. `unpauseContract()`: Resumes contract functionalities.
 * 7. `withdrawFees()`: Allows contract owner to withdraw accumulated fees.
 *
 * **Persona Creation & Management:**
 * 8. `mintPersona(string memory _personaName)`: Mints a new digital persona NFT for a user.
 * 9. `updatePersonaName(uint256 _tokenId, string memory _newName)`: Allows persona owner to update their persona's name.
 * 10. `burnPersona(uint256 _tokenId)`: Allows persona owner to burn their digital persona NFT.
 *
 * **Attribute Interaction & Reputation:**
 * 11. `endorseAttribute(uint256 _targetTokenId, string memory _attribute)`: Allows users to endorse attributes of other personas, increasing their reputation in that attribute.
 * 12. `challengeAttribute(uint256 _targetTokenId, string memory _attribute)`: Allows users to challenge attributes of other personas, potentially decreasing their reputation.
 * 13. `collaborateOnAttribute(uint256 _targetTokenId, string memory _attribute)`: Allows users to collaborate on an attribute with another persona, potentially boosting both their reputations.
 * 14. `gainPassiveReputation(uint256 _tokenId)`:  Simulates passive reputation gain over time based on persona activity (placeholder/example).
 * 15. `applyOracleInfluence(uint256 _tokenId)`: Allows the oracle to influence persona attributes based on external data or randomness.
 *
 * **Level/Tier System:**
 * 16. `getPersonaLevel(uint256 _tokenId)`: Returns the level of a persona based on their total reputation.
 * 17. `getPersonaTier(uint256 _tokenId)`: Returns the tier of a persona based on their level.
 *
 * **Metadata & Display:**
 * 18. `tokenURI(uint256 tokenId)`: Returns the URI for the NFT metadata, dynamically generated based on persona attributes.
 * 19. `getPersonaAttributes(uint256 _tokenId)`: Returns the current attributes of a persona.
 *
 * **Governance (Basic Example):**
 * 20. `proposeAttributeWeightChange(string memory _attribute, uint256 _newWeight)`: Allows governance to propose changes to attribute weighting in reputation calculation.
 * 21. `voteOnProposal(uint256 _proposalId, bool _vote)`: Allows governance to vote on attribute weight change proposals.
 * 22. `executeProposal(uint256 _proposalId)`: Allows governance to execute a passed attribute weight change proposal.
 */

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol"; // Optional: For royalty support

contract EvolvingDigitalPersona is ERC721, Ownable, ReentrancyGuard, IERC2981 {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIdCounter;

    string private _baseURI;
    address public oracleAddress; // Address authorized to provide external data/randomness
    address public governanceAddress; // Address for governance actions
    bool public paused;

    // --- Persona Attributes and Reputation ---
    struct PersonaAttributes {
        string personaName;
        uint256 skill;        // Expertise in a domain
        uint256 influence;    // Social standing and network
        uint256 creativity;   // Innovation and originality
        uint256 knowledge;    // Accumulated wisdom and information
        uint256 trustworthiness; // Reliability and integrity
        uint256 reputationScore; // Overall reputation derived from attributes
        uint256 lastPassiveReputationGain; // Timestamp of last passive reputation gain
    }

    mapping(uint256 => PersonaAttributes) public personaAttributes;
    mapping(string => uint256) public attributeWeights; // Weight for each attribute in reputation score calculation
    mapping(uint256 => mapping(address => bool)) public hasEndorsedAttribute; // Track endorsements to prevent spam
    mapping(uint256 => mapping(address => bool)) public hasChallengedAttribute; // Track challenges to prevent spam

    // --- Level and Tier System ---
    struct LevelTierConfig {
        uint256 reputationThreshold;
        string tierName;
    }

    LevelTierConfig[] public levelTiers;

    // --- Governance ---
    struct AttributeWeightProposal {
        string attribute;
        uint256 newWeight;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        uint256 proposalTimestamp;
    }
    mapping(uint256 => AttributeWeightProposal) public attributeWeightProposals;
    Counters.Counter private _proposalIdCounter;
    uint256 public governanceVotingPeriod = 7 days; // Example voting period


    // --- Events ---
    event PersonaMinted(uint256 tokenId, address owner, string personaName);
    event PersonaNameUpdated(uint256 tokenId, string newName);
    event PersonaAttributeEndorsed(uint256 tokenId, address endorser, string attribute);
    event PersonaAttributeChallenged(uint256 tokenId, address challenger, string attribute);
    event PersonaAttributeCollaborated(uint256 tokenId, uint256 otherTokenId, string attribute);
    event PersonaPassiveReputationGained(uint256 tokenId, uint256 reputationGain);
    event OracleInfluenceApplied(uint256 tokenId, string attribute, uint256 newValue);
    event AttributeWeightProposalCreated(uint256 proposalId, string attribute, uint256 newWeight, address proposer);
    event AttributeWeightProposalVoted(uint256 proposalId, address voter, bool vote);
    event AttributeWeightProposalExecuted(uint256 proposalId);
    event ContractPaused(address pauser);
    event ContractUnpaused(address unpauser);

    // --- Royalties (Optional - Example implementation) ---
    uint256 private _royaltyFeeNumerator = 500; // 5% royalty (500/10000)
    address private _royaltyRecipient;


    // --- Constructor ---
    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {
        _royaltyRecipient = owner(); // Default royalty recipient is contract owner
        _baseURI = "ipfs://your_base_uri/"; // Replace with your IPFS base URI
        oracleAddress = msg.sender; // Initially set oracle to deployer, update later
        governanceAddress = msg.sender; // Initially set governance to deployer, update later
        paused = false;

        // Initialize default attribute weights
        attributeWeights["skill"] = 20;
        attributeWeights["influence"] = 20;
        attributeWeights["creativity"] = 20;
        attributeWeights["knowledge"] = 20;
        attributeWeights["trustworthiness"] = 20;

        // Initialize Level/Tier system (example tiers)
        levelTiers.push(LevelTierConfig({reputationThreshold: 0, tierName: "Novice"}));
        levelTiers.push(LevelTierConfig({reputationThreshold: 1000, tierName: "Apprentice"}));
        levelTiers.push(LevelTierConfig({reputationThreshold: 5000, tierName: "Journeyman"}));
        levelTiers.push(LevelTierConfig({reputationThreshold: 15000, tierName: "Master"}));
        levelTiers.push(LevelTierConfig({reputationThreshold: 50000, tierName: "Legend"}));
    }

    // --- External Functions ---

    /**
     * @dev Sets the base URI for token metadata. Only owner can call.
     * @param _baseURI URI string to set as the base.
     */
    function setBaseURI(string memory _baseURI) external onlyOwner {
        _baseURI = _baseURI;
    }

    /**
     * @dev Sets the address authorized to act as the oracle. Only owner can call.
     * @param _oracleAddress Address of the oracle.
     */
    function setOracleAddress(address _oracleAddress) external onlyOwner {
        oracleAddress = _oracleAddress;
    }

    /**
     * @dev Sets the address authorized to perform governance actions. Only owner can call.
     * @param _governanceAddress Address of the governance contract/EOA.
     */
    function setGovernanceAddress(address _governanceAddress) external onlyOwner {
        governanceAddress = _governanceAddress;
    }

    /**
     * @dev Pauses the contract, preventing most state-changing functions. Only owner can call.
     */
    function pauseContract() external onlyOwner {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    /**
     * @dev Unpauses the contract, restoring normal functionality. Only owner can call.
     */
    function unpauseContract() external onlyOwner {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }


    /**
     * @dev Mints a new digital persona NFT to the caller.
     * @param _personaName The name of the persona.
     */
    function mintPersona(string memory _personaName) external nonReentrant whenNotPaused {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _mint(msg.sender, tokenId);

        personaAttributes[tokenId] = PersonaAttributes({
            personaName: _personaName,
            skill: 10,         // Initial skill level
            influence: 10,     // Initial influence level
            creativity: 10,    // Initial creativity level
            knowledge: 10,     // Initial knowledge level
            trustworthiness: 10, // Initial trustworthiness level
            reputationScore: 0,  // Initial reputation score
            lastPassiveReputationGain: block.timestamp
        });

        emit PersonaMinted(tokenId, msg.sender, _personaName);
    }

    /**
     * @dev Allows the persona owner to update their persona's name.
     * @param _tokenId The ID of the persona NFT.
     * @param _newName The new name for the persona.
     */
    function updatePersonaName(uint256 _tokenId, string memory _newName) external whenNotPaused {
        require(_exists(_tokenId), "Token does not exist");
        require(ownerOf(_tokenId) == msg.sender, "Not persona owner");
        personaAttributes[_tokenId].personaName = _newName;
        emit PersonaNameUpdated(_tokenId, _newName);
    }

    /**
     * @dev Allows the persona owner to burn (destroy) their digital persona NFT.
     * @param _tokenId The ID of the persona NFT to burn.
     */
    function burnPersona(uint256 _tokenId) external whenNotPaused {
        require(_exists(_tokenId), "Token does not exist");
        require(ownerOf(_tokenId) == msg.sender, "Not persona owner");
        _burn(_tokenId);
        delete personaAttributes[_tokenId]; // Clean up persona data
    }


    /**
     * @dev Allows a user to endorse an attribute of another persona.
     * @param _targetTokenId The ID of the persona to endorse.
     * @param _attribute The attribute to endorse (e.g., "skill", "creativity").
     */
    function endorseAttribute(uint256 _targetTokenId, string memory _attribute) external whenNotPaused {
        require(_exists(_targetTokenId), "Target persona does not exist");
        require(ownerOf(_targetTokenId) != msg.sender, "Cannot endorse own persona");
        require(!hasEndorsedAttribute[_targetTokenId][msg.sender], "Already endorsed this attribute");
        require(attributeWeights[_attribute] > 0, "Invalid attribute"); // Ensure attribute is valid

        personaAttributes[_targetTokenId].reputationScore += (attributeWeights[_attribute] * 1); // Simple reputation boost
        hasEndorsedAttribute[_targetTokenId][msg.sender] = true; // Mark as endorsed by this user
        emit PersonaAttributeEndorsed(_targetTokenId, msg.sender, _attribute);
    }

    /**
     * @dev Allows a user to challenge an attribute of another persona (potential reputation decrease).
     * @param _targetTokenId The ID of the persona to challenge.
     * @param _attribute The attribute to challenge.
     */
    function challengeAttribute(uint256 _targetTokenId, string memory _attribute) external whenNotPaused {
        require(_exists(_targetTokenId), "Target persona does not exist");
        require(ownerOf(_targetTokenId) != msg.sender, "Cannot challenge own persona");
        require(!hasChallengedAttribute[_targetTokenId][msg.sender], "Already challenged this attribute");
        require(attributeWeights[_attribute] > 0, "Invalid attribute"); // Ensure attribute is valid

        // Example: Chance of reputation decrease, or require a successful "challenge resolution" mechanism
        if (block.timestamp % 2 == 0) { // 50% chance of reputation reduction for simplicity
            personaAttributes[_targetTokenId].reputationScore -= (attributeWeights[_attribute] / 2); // Moderate reputation decrease
        }
        hasChallengedAttribute[_targetTokenId][msg.sender] = true; // Mark as challenged by this user
        emit PersonaAttributeChallenged(_targetTokenId, msg.sender, _attribute);
    }

    /**
     * @dev Allows users to collaborate on an attribute, potentially boosting reputation for both.
     * @param _targetTokenId The ID of the other persona to collaborate with.
     * @param _attribute The attribute of collaboration.
     */
    function collaborateOnAttribute(uint256 _targetTokenId, string memory _attribute) external whenNotPaused {
        require(_exists(_targetTokenId), "Target persona does not exist");
        require(ownerOf(_targetTokenId) != msg.sender, "Cannot collaborate with own persona");
        require(attributeWeights[_attribute] > 0, "Invalid attribute"); // Ensure attribute is valid

        uint256 tokenId = tokenOfOwner(msg.sender); // Assuming each user only has one persona for simplicity
        require(_exists(tokenId), "Caller persona does not exist");

        personaAttributes[tokenId].reputationScore += (attributeWeights[_attribute] / 2); // Reputation boost for collaborator
        personaAttributes[_targetTokenId].reputationScore += (attributeWeights[_attribute] / 2); // Reputation boost for target persona
        emit PersonaAttributeCollaborated(tokenId, _targetTokenId, _attribute);
    }

    /**
     * @dev Simulates passive reputation gain over time.  Can be called periodically by persona owners.
     * @param _tokenId The ID of the persona receiving passive reputation.
     */
    function gainPassiveReputation(uint256 _tokenId) external whenNotPaused {
        require(_exists(_tokenId), "Persona does not exist");
        require(ownerOf(_tokenId) == msg.sender, "Not persona owner");

        uint256 timeSinceLastGain = block.timestamp - personaAttributes[_tokenId].lastPassiveReputationGain;
        uint256 reputationGain = timeSinceLastGain / (1 days); // Example: Gain 1 reputation per day

        if (reputationGain > 0) {
            personaAttributes[_tokenId].reputationScore += reputationGain;
            personaAttributes[_tokenId].lastPassiveReputationGain = block.timestamp;
            emit PersonaPassiveReputationGained(_tokenId, reputationGain);
        }
    }

    /**
     * @dev Allows the designated oracle to influence a persona's attribute based on external data/randomness.
     * @param _tokenId The ID of the persona to influence.
     * @param _attribute The attribute to modify.
     * @param _newValue The new value for the attribute.
     */
    function applyOracleInfluence(uint256 _tokenId, string memory _attribute, uint256 _newValue) external whenNotPaused onlyOracle {
        require(_exists(_tokenId), "Persona does not exist");
        require(attributeWeights[_attribute] > 0, "Invalid attribute"); // Ensure attribute is valid

        if (keccak256(abi.encodePacked(_attribute)) == keccak256(abi.encodePacked("skill"))) {
            personaAttributes[_tokenId].skill = _newValue;
        } else if (keccak256(abi.encodePacked(_attribute)) == keccak256(abi.encodePacked("influence"))) {
            personaAttributes[_tokenId].influence = _newValue;
        } else if (keccak256(abi.encodePacked(_attribute)) == keccak256(abi.encodePacked("creativity"))) {
            personaAttributes[_tokenId].creativity = _newValue;
        } else if (keccak256(abi.encodePacked(_attribute)) == keccak256(abi.encodePacked("knowledge"))) {
            personaAttributes[_tokenId].knowledge = _newValue;
        } else if (keccak256(abi.encodePacked(_attribute)) == keccak256(abi.encodePacked("trustworthiness"))) {
            personaAttributes[_tokenId].trustworthiness = _newValue;
        }
        _updateReputationScore(_tokenId); // Recalculate reputation after attribute change
        emit OracleInfluenceApplied(_tokenId, _attribute, _newValue);
    }

    /**
     * @dev Allows the governance address to propose a change to attribute weights.
     * @param _attribute The attribute to change the weight of.
     * @param _newWeight The new weight value.
     */
    function proposeAttributeWeightChange(string memory _attribute, uint256 _newWeight) external whenNotPaused onlyGovernance {
        require(attributeWeights[_attribute] > 0, "Invalid attribute for weight change");
        require(_newWeight > 0, "Weight must be greater than zero");

        uint256 proposalId = _proposalIdCounter.current();
        _proposalIdCounter.increment();

        attributeWeightProposals[proposalId] = AttributeWeightProposal({
            attribute: _attribute,
            newWeight: _newWeight,
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            proposalTimestamp: block.timestamp
        });

        emit AttributeWeightProposalCreated(proposalId, _attribute, _newWeight, msg.sender);
    }

    /**
     * @dev Allows the governance address to vote on an attribute weight change proposal.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _vote True for 'for', false for 'against'.
     */
    function voteOnProposal(uint256 _proposalId, bool _vote) external whenNotPaused onlyGovernance {
        require(attributeWeightProposals[_proposalId].proposalTimestamp + governanceVotingPeriod > block.timestamp, "Voting period expired");
        require(!attributeWeightProposals[_proposalId].executed, "Proposal already executed");

        if (_vote) {
            attributeWeightProposals[_proposalId].votesFor++;
        } else {
            attributeWeightProposals[_proposalId].votesAgainst++;
        }
        emit AttributeWeightProposalVoted(_proposalId, msg.sender, _vote);
    }

    /**
     * @dev Allows the governance address to execute a passed attribute weight change proposal.
     *      Proposal passes if votesFor > votesAgainst and voting period is over.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) external whenNotPaused onlyGovernance {
        require(attributeWeightProposals[_proposalId].proposalTimestamp + governanceVotingPeriod <= block.timestamp, "Voting period not expired");
        require(!attributeWeightProposals[_proposalId].executed, "Proposal already executed");
        require(attributeWeightProposals[_proposalId].votesFor > attributeWeightProposals[_proposalId].votesAgainst, "Proposal not passed");

        attributeWeights[attributeWeightProposals[_proposalId].attribute] = attributeWeightProposals[_proposalId].newWeight;
        attributeWeightProposals[_proposalId].executed = true;
        emit AttributeWeightProposalExecuted(_proposalId);

        // Recalculate reputation scores for all personas (can be gas intensive, consider batching or on-demand updates)
        for (uint256 tokenId = 1; tokenId <= _tokenIdCounter.current(); tokenId++) {
            if (_exists(tokenId)) {
                _updateReputationScore(tokenId);
            }
        }
    }


    /**
     * @dev Returns the level of a persona based on their reputation score.
     * @param _tokenId The ID of the persona.
     * @return The level of the persona.
     */
    function getPersonaLevel(uint256 _tokenId) public view returns (uint256) {
        uint256 reputation = personaAttributes[_tokenId].reputationScore;
        for (uint256 i = levelTiers.length - 1; i >= 0; i--) {
            if (reputation >= levelTiers[i].reputationThreshold) {
                return i + 1; // Level is 1-indexed
            }
            if (i == 0) break; // Prevent underflow in loop
        }
        return 1; // Default level if no tier is matched (shouldn't happen with tier at 0 threshold)
    }

    /**
     * @dev Returns the tier name of a persona based on their level.
     * @param _tokenId The ID of the persona.
     * @return The tier name.
     */
    function getPersonaTier(uint256 _tokenId) public view returns (string memory) {
        uint256 level = getPersonaLevel(_tokenId);
        if (level > 0 && level <= levelTiers.length) {
            return levelTiers[level - 1].tierName;
        }
        return "Unknown Tier"; // Fallback if level is out of range
    }

    /**
     * @dev Returns the URI for the NFT metadata, dynamically generated based on persona attributes.
     * @param tokenId The token ID of the persona.
     * @return The metadata URI.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Token does not exist");
        string memory base = _baseURI;
        string memory personaJson = generateDynamicMetadata(tokenId);
        return string(abi.encodePacked(base, tokenId.toString(), ".json")); // Example: ipfs://your_base_uri/1.json
        //  For true dynamic metadata, you'd need a more complex off-chain solution or use IPFS and update CID if metadata changes.
        //  This example provides a static JSON for demonstration, but the `generateDynamicMetadata` function shows how you *could* construct dynamic data.
    }

    /**
     * @dev Returns the current attributes of a persona.
     * @param _tokenId The ID of the persona.
     * @return PersonaAttributes struct.
     */
    function getPersonaAttributes(uint256 _tokenId) public view returns (PersonaAttributes memory) {
        require(_exists(_tokenId), "Persona does not exist");
        return personaAttributes[_tokenId];
    }

    /**
     * @dev Allows the contract owner to withdraw any accumulated fees (if any are collected in future extensions).
     */
    function withdrawFees() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }


    // --- Internal & View Functions ---

    /**
     * @dev Recalculates the reputation score of a persona based on their attributes and attribute weights.
     * @param _tokenId The ID of the persona.
     */
    function _updateReputationScore(uint256 _tokenId) internal {
        uint256 reputation = 0;
        reputation += (personaAttributes[_tokenId].skill * attributeWeights["skill"]) / 100;
        reputation += (personaAttributes[_tokenId].influence * attributeWeights["influence"]) / 100;
        reputation += (personaAttributes[_tokenId].creativity * attributeWeights["creativity"]) / 100;
        reputation += (personaAttributes[_tokenId].knowledge * attributeWeights["knowledge"]) / 100;
        reputation += (personaAttributes[_tokenId].trustworthiness * attributeWeights["trustworthiness"]) / 100;
        personaAttributes[_tokenId].reputationScore = reputation;
    }

    /**
     * @dev Generates dynamic metadata JSON for a persona based on their attributes.
     *      This is a simplified example; in a real application, you'd likely use an off-chain service
     *      to generate and host metadata, updating it as persona attributes change.
     * @param _tokenId The ID of the persona.
     * @return JSON string representing the metadata.
     */
    function generateDynamicMetadata(uint256 _tokenId) internal view returns (string memory) {
        PersonaAttributes memory attrs = personaAttributes[_tokenId];
        string memory json = string(abi.encodePacked(
            '{"name": "', attrs.personaName, '",',
            '"description": "A dynamic digital persona evolving on the blockchain.",',
            '"image": "ipfs://your_default_image_cid.png",', // Replace with a default image CID
            '"attributes": [',
                '{"trait_type": "Level", "value": "', getPersonaLevel(_tokenId).toString(), '"},',
                '{"trait_type": "Tier", "value": "', getPersonaTier(_tokenId), '"},',
                '{"trait_type": "Skill", "value": ', attrs.skill.toString(), '},',
                '{"trait_type": "Influence", "value": ', attrs.influence.toString(), '},',
                '{"trait_type": "Creativity", "value": ', attrs.creativity.toString(), '},',
                '{"trait_type": "Knowledge", "value": ', attrs.knowledge.toString(), '},',
                '{"trait_type": "Trustworthiness", "value": ', attrs.trustworthiness.toString(), '} ',
            ']',
            '}'
        ));
        return json;
    }

    // --- Modifiers ---
    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "Only oracle can call this function");
        _;
    }

    modifier onlyGovernance() {
        require(msg.sender == governanceAddress, "Only governance can call this function");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused");
        _;
    }

    // --- Royalty Info (Optional - Example implementation) ---
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        return (_royaltyRecipient, (_salePrice * _royaltyFeeNumerator) / 10000);
    }

    function setRoyaltyInfo(address _recipient, uint96 _numerator) external onlyOwner {
        require(_numerator <= 10000, "Royalty numerator must be less than or equal to 10000");
        _royaltyRecipient = _recipient;
        _royaltyFeeNumerator = _numerator;
    }

    function getRoyaltyNumerator() external view returns (uint256) {
        return _royaltyFeeNumerator;
    }

    function getRoyaltyRecipient() external view returns (address) {
        return _royaltyRecipient;
    }

    // --- Supports Interface (For Royalty Standard) ---
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, IERC2981) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }
}
```