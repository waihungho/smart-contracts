This smart contract, `PersonaForge`, is designed to create a dynamic, evolving NFT ecosystem. It introduces "Persona" NFTs that gain "Skills" through on-chain attestations, mimicking a decentralized skill tree or reputation system. The contract integrates an internal "Essence" fungible token for economic incentives, skill acquisition costs, and a lightweight governance mechanism for skill approval.

## Outline:

1.  **Interfaces & Libraries:** Standard OpenZeppelin imports and custom error definitions for clarity and robustness.
2.  **Enums & Structs:** Defines `AttestationMethod` for varied skill verification, `SkillNode` for skill characteristics, `SkillProposal` for governance, and `PersonaAttestation` to track ongoing skill acquisition.
3.  **State Variables:** Manages ERC721 properties (token IDs, names, URIs), the Skill Registry (skill definitions, acquired skills), an internal Essence Token (balances, total supply, staking), Governance parameters (proposal thresholds, durations), and Attestation/Delegation data (active attestations, delegates, Guild Masters).
4.  **Events:** Emits events for all significant state changes, crucial for off-chain indexing and UI updates.
5.  **Modifiers:** Access control modifiers for Persona owners/delegates.
6.  **Constructor:** Initializes the contract with basic parameters.
7.  **Core Persona NFT Management:** Functions for minting, dynamic metadata generation, renaming, and retrieving acquired skills.
8.  **Internal Essence Token Management:** Functions for distributing, staking, and unstaking the utility token.
9.  **Skill Node Definition & Governance:** Mechanisms for proposing new skills, voting on them, finalizing proposals, and managing skill parameters.
10. **Skill Attestation & Forging Logic:** The core advanced concept, allowing flexible verification methods (staking, external claims, on-chain proofs) before a skill can be "forged" onto a Persona.
11. **Delegation Mechanisms:** Allows Persona owners to delegate attestation rights.
12. **System Parameter Management:** Functions for the owner/DAO to adjust governance and attestation parameters.
13. **View Functions (Getters):** Publicly accessible functions to query contract state without modifying it.

## Function Summary:

### I. Core Persona NFT Management
1.  `mintPersona(string _name)`: Mints a new unique Persona NFT for the caller, assigning an initial name.
2.  `tokenURI(uint256 _tokenId)`: Generates a dynamic JSON metadata URI for the Persona NFT. This includes an on-chain SVG image that reflects the Persona's name and acquired skills.
3.  `setPersonaBaseURI(uint256 _tokenId, string _newBaseURI)`: Allows a Persona owner to set a custom base URI prefix for their NFT's metadata, enabling personalized metadata hosting.
4.  `renamePersona(uint256 _tokenId, string _newName)`: Allows the owner to change their Persona's display name, reflecting identity evolution.
5.  `getPersonaSkills(uint256 _tokenId)`: Returns an array of skill IDs that a specific Persona has successfully acquired.

### II. Internal Essence Token Management
6.  `distributeEssence(address _to, uint256 _amount)`: Allows the contract owner (or DAO) to mint and distribute Essence tokens to an address, serving as a reward or initial allocation mechanism.
7.  `stakeEssence(uint256 _amount)`: Enables users to stake their Essence tokens, typically to gain voting power in governance or meet attestation requirements.
8.  `unstakeEssence(uint256 _amount)`: Allows users to retrieve their previously staked Essence tokens.
9.  `getEssenceBalance(address _owner)`: Returns the un-staked Essence token balance for a given address.
10. `getEssenceStaked(address _owner)`: Returns the staked Essence token balance for a given address.
11. `getTotalEssenceSupply()`: Returns the total outstanding supply of Essence tokens.

### III. Skill Node Definition & Governance
12. `proposeSkill(string _name, string _description, uint256[] _prerequisites, uint256 _essenceCost, AttestationMethod _attestationMethod)`: Proposes a new skill to be added to the registry, defining its name, description, required preceding skills, Essence cost for forging, and the method required for attestation.
13. `voteOnSkillProposal(uint256 _proposalId, bool _approve)`: Allows authorized DAO members (or accounts with staked Essence) to cast votes for or against a skill proposal.
14. `finalizeSkillProposal(uint256 _proposalId)`: Closes the voting period for a skill proposal. If it meets the voting threshold, the skill is activated and becomes acquirable.
15. `getSkillDetails(uint256 _skillId)`: Provides comprehensive details about a registered skill, including its name, description, costs, and attestation method.
16. `getSkillPrerequisites(uint256 _skillId)`: Returns the array of skill IDs that must be acquired before a specific skill can be attested.
17. `updateSkillEssenceCost(uint256 _skillId, uint256 _newCost)`: Allows the owner/DAO to adjust the Essence token cost associated with a specific skill.
18. `deactivateSkill(uint256 _skillId)`: Allows the owner/DAO to deactivate an active skill, preventing new Persona NFTs from acquiring it.

### IV. Skill Attestation & Forging (Advanced Core)
19. `attestSkill(uint256 _personaId, uint256 _skillId, bytes memory _attestationData)`: The primary function for initiating skill acquisition. It validates the user's claim based on the skill's defined `AttestationMethod`. This could involve burning Essence, verifying a signed message from a "Guild Master" (for off-chain proofs), or checking specific on-chain conditions (e.g., token holdings).
20. `forgeSkill(uint256 _personaId, uint256 _skillId)`: Finalizes the acquisition of a skill by a Persona, marking it as permanently acquired, after a successful `attestSkill` and within the grace period.
21. `delegateAttestation(uint256 _personaId, address _delegatee)`: Allows a Persona owner to grant permission to another address to perform `attestSkill` and `forgeSkill` on their Persona's behalf.
22. `revokeDelegation(uint256 _personaId, address _delegatee)`: Revokes a previously granted attestation delegation.
23. `registerGuildMaster(uint256 _skillId, address _guildMasterAddress)`: Allows the owner/DAO to designate a specific address as a "Guild Master" capable of providing signed attestations for a particular skill type.
24. `removeGuildMaster(uint256 _skillId, address _guildMasterAddress)`: Removes a designated Guild Master for a skill.

### V. Governance & System Control
25. `setVotingThreshold(uint256 _newThreshold)`: Allows the owner/DAO to adjust the percentage of 'for' votes required for a skill proposal to pass.
26. `setProposalDuration(uint256 _newDuration)`: Allows the owner/DAO to set the duration (in seconds) that skill proposals remain open for voting.
27. `setAttestationGracePeriod(uint256 _newPeriod)`: Allows the owner/DAO to set the time window (in seconds) after a successful attestation during which a skill can still be forged.

### View Functions (Getters) - (Already integrated into the function list, but good to highlight)
*   `getPersonaName(uint256 _tokenId)`: Returns the current name of a Persona NFT.
*   `getPersonaActiveAttestation(uint256 _personaId, uint256 _skillId)`: Retrieves details about an ongoing, un-forged attestation for a Persona and skill.
*   `getPersonaAttestationDelegate(uint256 _personaId)`: Returns the address currently delegated to act on behalf of a Persona for attestations.
*   `isGuildMaster(uint256 _skillId, address _guildMasterAddress)`: Checks if a given address is recognized as a Guild Master for a specific skill.
*   `getSkillProposalDetails(uint256 _proposalId)`: Provides comprehensive information about a skill proposal, including its status and voting results.
*   `getSkillProposalVoters(uint256 _proposalId)`: Returns a list of all addresses that have cast a vote on a specific skill proposal.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

// Custom Errors for enhanced clarity and debugging
error PersonaForge__NotOwner(uint256 tokenId, address caller);
error PersonaForge__NameTooShort(string name);
error PersonaForge__SkillNotFound(uint256 skillId);
error PersonaForge__SkillPrerequisitesNotMet(uint256 personaId, uint256 skillId);
error PersonaForge__SkillAlreadyAcquired(uint256 personaId, uint256 skillId);
error PersonaForge__InsufficientEssence(address account, uint256 required, uint256 available);
error PersonaForge__ProposalNotFound(uint256 proposalId);
error PersonaForge__ProposalNotActive(uint256 proposalId);
error PersonaForge__ProposalAlreadyVoted(uint256 proposalId, address voter);
error PersonaForge__NotEnoughVotes(uint256 proposalId);
error PersonaForge__NotGuildMaster(address signer, uint256 skillId);
error PersonaForge__InvalidSignature(address recoveredSigner, address expectedSigner);
error PersonaForge__AttestationAlreadyExists(uint256 personaId, uint256 skillId);
error PersonaForge__AttestationMethodNotSupported(bytes4 method);
error PersonaForge__NoActiveAttestationForSkill(uint256 personaId, uint256 skillId);
error PersonaForge__DelegationAlreadyExists(address delegatee);
error PersonaForge__NoActiveDelegation(address delegatee);
error PersonaForge__InvalidAttestationData();
error PersonaForge__SkillNotActive(uint256 skillId);
error PersonaForge__AttestationExpired(uint256 personaId, uint256 skillId, uint256 expiry);


/// @title PersonaForge - Evolving NFTs based on On-Chain Contributions
/// @author Your Name/Team
/// @notice This contract implements a dynamic ERC721 NFT system where "Persona" NFTs evolve
///         by acquiring "Skills" through on-chain attestations and contributions.
///         It features a decentralized skill registry, an internal fungible token ("Essence")
///         for costs and incentives, and a simplified governance mechanism for skill proposals.
///
/// Outline:
/// 1.  Interfaces & Libraries (OpenZeppelin imports, custom errors)
/// 2.  Main Contract: PersonaForge
///     a.  State Variables & Enums:
///         -   ERC721 related (token tracker, base URI)
///         -   Skill Registry (SkillNode struct, mappings for skills, proposals)
///         -   Essence Token (balances, staking, total supply)
///         -   Governance (proposal voting, thresholds)
///         -   Attestation & Delegation (tracking attestations, delegates)
///     b.  Events: For all significant state changes.
///     c.  Modifiers: Access control, state checks.
///     d.  Constructor: Initialize core parameters.
///     e.  ERC721 Overrides & Persona Management: Minting, URI generation, renaming.
///     f.  Internal Essence Token Management: Minting, burning, transfers, staking.
///     g.  Skill Node Definition & Governance: Proposing new skills, voting, finalization.
///     h.  Skill Attestation & Forging Logic: The core advanced concept of proving and acquiring skills.
///     i.  Delegation Mechanisms: Allowing others to attest on behalf of a Persona.
///     j.  System Parameter Management: Adjusting governance parameters, approved attestors.
///     k.  View Functions (Getters): For reading contract state.
///
/// Function Summary:
///
/// I. Core Persona NFT Management
/// 1.  `mintPersona(string _name)`: Mints a new unique Persona NFT for the caller.
/// 2.  `tokenURI(uint256 _tokenId)`: Generates a dynamic JSON metadata URI for the Persona NFT,
///                                using its acquired skills to influence the generated SVG image and attributes.
/// 3.  `setPersonaBaseURI(uint256 _tokenId, string _newBaseURI)`: Allows a Persona owner to set a custom base URI prefix for their NFT's metadata.
/// 4.  `renamePersona(uint256 _tokenId, string _newName)`: Allows the owner to change their Persona's display name.
/// 5.  `getPersonaSkills(uint256 _tokenId)`: Returns an array of skill IDs acquired by a specific Persona.
///
/// II. Internal Essence Token Management
/// 6.  `distributeEssence(address _to, uint256 _amount)`: Owner/DAO can mint and distribute Essence tokens to an address.
/// 7.  `stakeEssence(uint256 _amount)`: Allows users to stake their Essence tokens, typically for governance voting power or skill attestation.
/// 8.  `unstakeEssence(uint256 _amount)`: Allows users to unstake their previously staked Essence tokens.
/// 9.  `getEssenceBalance(address _owner)`: Returns the un-staked Essence token balance for an address.
/// 10. `getEssenceStaked(address _owner)`: Returns the staked Essence token balance for an address.
/// 11. `getTotalEssenceSupply()`: Returns the total supply of Essence tokens.
///
/// III. Skill Node Definition & Governance
/// 12. `proposeSkill(string _name, string _description, uint256[] _prerequisites, uint256 _essenceCost, AttestationMethod _attestationMethod)`:
///                                Proposes a new skill to be added to the registry, with prerequisites and an attestation method.
/// 13. `voteOnSkillProposal(uint256 _proposalId, bool _approve)`: Allows authorized DAO members (owners or delegates) to vote on a skill proposal, with voting power linked to staked Essence.
/// 14. `finalizeSkillProposal(uint256 _proposalId)`: Finalizes a skill proposal if it meets the voting threshold, activating the skill.
/// 15. `getSkillDetails(uint252 _skillId)`: Returns the full details of a registered skill.
/// 16. `getSkillPrerequisites(uint252 _skillId)`: Returns the array of skill IDs required as prerequisites for a given skill.
/// 17. `updateSkillEssenceCost(uint252 _skillId, uint252 _newCost)`: Owner/DAO can update the Essence cost for acquiring a skill.
/// 18. `deactivateSkill(uint252 _skillId)`: Owner/DAO can deactivate a skill, preventing further acquisition.
///
/// IV. Skill Attestation & Forging (Advanced Core)
/// 19. `attestSkill(uint256 _personaId, uint256 _skillId, bytes memory _attestationData)`:
///                                The core function to initiate skill acquisition. It processes `_attestationData`
///                                based on the skill's `AttestationMethod` (e.g., staking Essence, verifying signatures,
///                                checking on-chain actions). This sets a temporary attestation.
/// 20. `forgeSkill(uint256 _personaId, uint256 _skillId)`: Finalizes the skill acquisition for a Persona
///                                once an attestation is confirmed and requirements (like Essence cost) are met.
/// 21. `delegateAttestation(uint256 _personaId, address _delegatee)`: Allows a Persona owner to delegate the right
///                                to perform `attestSkill` for their Persona to another address.
/// 22. `revokeDelegation(uint256 _personaId, address _delegatee)`: Revokes a previously granted attestation delegation.
/// 23. `registerGuildMaster(uint256 _skillId, address _guildMasterAddress)`: Owner/DAO can designate addresses
///                                as "Guild Masters" who can sign off on `EXTERNAL_VERIFIED_CLAIM` attestations for specific skills.
/// 24. `removeGuildMaster(uint256 _skillId, address _guildMasterAddress)`: Removes a Guild Master.
///
/// V. Governance & System Control
/// 25. `setVotingThreshold(uint256 _newThreshold)`: Owner/DAO can adjust the percentage of votes required to pass a skill proposal.
/// 26. `setProposalDuration(uint256 _newDuration)`: Owner/DAO can set the duration for which skill proposals are open for voting.
/// 27. `setAttestationGracePeriod(uint256 _newPeriod)`: Owner/DAO can set the grace period for attestations to be forged.
///
contract PersonaForge is ERC721, Ownable {
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;
    using Strings for uint256;
    using ECDSA for bytes32;

    // --- Enums ---

    enum AttestationMethod {
        NONE,                     // Placeholder or simple acquisition, no special checks
        ESSENCE_BURN_COST,        // Requires user to burn Essence as a cost
        EXTERNAL_VERIFIED_CLAIM,  // Requires a signed message from an approved GuildMaster
        ONCHAIN_ACTION_PROOF      // Requires verification of a specific on-chain action or state
    }

    // --- Structs ---

    struct SkillNode {
        string name;
        string description;
        uint256[] prerequisites;
        uint256 essenceCost;
        AttestationMethod attestationMethod;
        bool isActive; // Can be deactivated by governance
    }

    struct SkillProposal {
        uint256 skillNodeId; // The ID of the skill node being proposed
        uint256 proposalId;
        uint256 createdAt;
        uint256 endTimestamp;
        uint256 totalVotesFor;
        uint256 totalVotesAgainst;
        EnumerableSet.AddressSet voters;
        bool finalized;
        bool approved;
    }

    struct PersonaAttestation {
        uint256 skillId;
        AttestationMethod methodUsed;
        uint256 attestationTimestamp;
        bool forged; // True if the skill has been successfully forged
    }

    // --- State Variables ---

    // ERC721
    uint256 private _nextTokenId;
    mapping(uint256 => string) private _personaNames;
    mapping(uint256 => string) private _personaBaseURIs; // Allows custom baseURI per persona

    // Skill Registry
    uint256 private _nextSkillId;
    mapping(uint256 => SkillNode) public skillNodes;
    mapping(uint256 => EnumerableSet.UintSet) private _personaSkills; // Persona ID => Set of Skill IDs

    // Skill Proposals
    uint256 private _nextProposalId;
    mapping(uint256 => SkillProposal) public skillProposals;
    uint256 public proposalVotingThreshold; // Percentage, e.g., 51 for 51%
    uint256 public proposalDuration;        // In seconds

    // Essence Token (Internal)
    string public constant ESSENCE_NAME = "Essence";
    string public constant ESSENCE_SYMBOL = "ESS";
    uint256 private _totalSupplyEssence;
    mapping(address => uint256) private _essenceBalances;
    mapping(address => uint256) private _essenceStakedBalances;

    // Attestation & Delegation
    mapping(uint256 => mapping(uint256 => PersonaAttestation)) private _activeAttestations; // personaId => skillId => attestation
    mapping(uint256 => address) private _personaAttestationDelegates; // personaId => delegate address
    mapping(uint256 => EnumerableSet.AddressSet) private _guildMasters; // skillId => Set of addresses that can attest for it
    uint256 public attestationGracePeriod; // Time in seconds after attestation until it expires

    // --- Events ---

    event PersonaMinted(uint256 indexed tokenId, address indexed owner, string name);
    event PersonaRenamed(uint256 indexed tokenId, string oldName, string newName);
    event PersonaBaseURIUpdated(uint256 indexed tokenId, string newURI);

    event SkillProposed(uint256 indexed proposalId, uint256 indexed skillNodeId, string name, address proposer);
    event SkillProposalVoted(uint256 indexed proposalId, address indexed voter, bool approved);
    event SkillProposalFinalized(uint256 indexed proposalId, bool approved, uint256 skillNodeId);
    event SkillActivated(uint256 indexed skillId, string name);
    event SkillDeactivated(uint256 indexed skillId);
    event SkillEssenceCostUpdated(uint256 indexed skillId, uint256 newCost);

    event SkillAttested(uint256 indexed personaId, uint256 indexed skillId, AttestationMethod method, address attestor);
    event SkillForged(uint256 indexed personaId, uint256 indexed skillId, address forger);
    event AttestationDelegated(uint256 indexed personaId, address indexed delegator, address indexed delegatee);
    event AttestationDelegationRevoked(uint256 indexed personaId, address indexed delegator, address indexed delegatee);
    event GuildMasterRegistered(uint256 indexed skillId, address indexed guildMaster);
    event GuildMasterRemoved(uint256 indexed skillId, address indexed guildMaster);

    event EssenceDistributed(address indexed to, uint256 amount);
    event EssenceStaked(address indexed staker, uint256 amount);
    event EssenceUnstaked(address indexed unstaker, uint256 amount);

    event VotingThresholdSet(uint256 oldThreshold, uint256 newThreshold);
    event ProposalDurationSet(uint256 oldDuration, uint256 newDuration);
    event AttestationGracePeriodSet(uint256 oldPeriod, uint256 newPeriod);


    // --- Modifiers ---

    modifier onlyPersonaOwnerOrDelegate(uint256 _personaId) {
        if (ownerOf(_personaId) != _msgSender() && _personaAttestationDelegates[_personaId] != _msgSender()) {
            revert PersonaForge__NotOwner(_personaId, _msgSender());
        }
        _;
    }

    // --- Constructor ---

    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) Ownable(_msgSender()) {
        _nextTokenId = 1;
        _nextSkillId = 1;
        _nextProposalId = 1;
        proposalVotingThreshold = 60; // 60% approval needed
        proposalDuration = 7 days; // 7 days for voting
        attestationGracePeriod = 3 days; // 3 days to forge after attestation
    }

    // --- I. Core Persona NFT Management ---

    /// @notice Mints a new unique Persona NFT for the caller.
    /// @param _name The desired name for the Persona.
    /// @return The ID of the newly minted Persona NFT.
    function mintPersona(string memory _name) public returns (uint256) {
        if (bytes(_name).length < 3) revert PersonaForge__NameTooShort(_name);

        uint256 tokenId = _nextTokenId++;
        _safeMint(msg.sender, tokenId);
        _personaNames[tokenId] = _name;
        // Default base URI can be customized or a generic IPFS gateway
        _personaBaseURIs[tokenId] = "data:application/json;base64,"; 
        emit PersonaMinted(tokenId, msg.sender, _name);
        return tokenId;
    }

    /// @notice Generates a dynamic JSON metadata URI for the Persona NFT, based on its acquired skills.
    /// @param _tokenId The ID of the Persona NFT.
    /// @return A data URI containing the base64 encoded JSON metadata.
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        if (!_exists(_tokenId)) revert ERC721NonexistentToken(_tokenId);

        string memory name = _personaNames[_tokenId];
        string memory description = string(abi.encodePacked("An evolving digital persona with acquired skills in the PersonaForge ecosystem."));
        
        // Generate a simple SVG for the image
        string memory svg = string(abi.encodePacked(
            "<svg xmlns='http://www.w3.org/2000/svg' preserveAspectRatio='xMinyMin meet' viewBox='0 0 350 350'>",
            "<style>.base { fill: white; font-family: sans-serif; font-size: 14px; }</style>",
            "<rect width='100%' height='100%' fill='#1a1a1a' />",
            "<text x='50%' y='40%' dominant-baseline='middle' text-anchor='middle' class='base' fill='#00ff99'>",
            name,
            "</text>"
        ));

        string memory skillsText = "";
        EnumerableSet.UintSet storage skills = _personaSkills[_tokenId];
        uint256 numSkills = skills.length();
        if (numSkills > 0) {
            skillsText = string(abi.encodePacked(skillsText, "<text x='50%' y='60%' dominant-baseline='middle' text-anchor='middle' class='base' fill='#00ccff'>Skills:</text>"));
            uint256 displayLimit = 3; // Limit number of skills displayed directly on SVG for readability
            for (uint256 i = 0; i < numSkills && i < displayLimit; i++) {
                uint256 skillId = skills.at(i);
                SkillNode storage skill = skillNodes[skillId];
                if (skill.isActive) {
                    skillsText = string(abi.encodePacked(
                        skillsText,
                        "<text x='50%' y='", (65 + i*5).toString(), "%' dominant-baseline='middle' text-anchor='middle' class='base' fill='#99ff00'>- ",
                        skill.name,
                        "</text>"
                    ));
                }
            }
            if (numSkills > displayLimit) {
                 skillsText = string(abi.encodePacked(
                    skillsText,
                    "<text x='50%' y='", (65 + displayLimit * 5).toString(), "%' dominant-baseline='middle' text-anchor='middle' class='base' fill='#99ff00'>(+",
                    (numSkills - displayLimit).toString(),
                    " more)</text>"
                ));
            }
        }
        svg = string(abi.encodePacked(svg, skillsText, "</svg>"));
        
        string memory imageURI = string(abi.encodePacked(
            "data:image/svg+xml;base64,",
            Base64.encode(bytes(svg))
        ));

        string memory attributes = "[";
        attributes = string(abi.encodePacked(attributes, '{"trait_type": "Skills Acquired", "value": ', numSkills.toString(), '}'));
        
        // Add each skill as an attribute
        for (uint256 i = 0; i < numSkills; i++) {
            uint256 skillId = skills.at(i);
            SkillNode storage skill = skillNodes[skillId];
            if (skill.isActive) {
                attributes = string(abi.encodePacked(attributes, ', {"trait_type": "Skill", "value": "', skill.name, '"}'));
            }
        }

        attributes = string(abi.encodePacked(attributes, "]"));

        string memory json = string(abi.encodePacked(
            '{"name": "', name,
            '", "description": "', description,
            '", "image": "', imageURI,
            '", "attributes": ', attributes,
            '}'
        ));

        return string(abi.encodePacked(
            _personaBaseURIs[_tokenId], // Use custom base URI if set
            Base64.encode(bytes(json))
        ));
    }

    /// @notice Allows a Persona owner to set a custom base URI prefix for their NFT's metadata.
    /// @param _tokenId The ID of the Persona NFT.
    /// @param _newBaseURI The new base URI.
    function setPersonaBaseURI(uint256 _tokenId, string memory _newBaseURI) public {
        if (ownerOf(_tokenId) != _msgSender()) revert PersonaForge__NotOwner(_tokenId, _msgSender());
        _personaBaseURIs[_tokenId] = _newBaseURI;
        emit PersonaBaseURIUpdated(_tokenId, _newBaseURI);
    }

    /// @notice Allows the owner to change their Persona's display name.
    /// @param _tokenId The ID of the Persona NFT.
    /// @param _newName The new name for the Persona.
    function renamePersona(uint256 _tokenId, string memory _newName) public {
        if (ownerOf(_tokenId) != _msgSender()) revert PersonaForge__NotOwner(_tokenId, _msgSender());
        if (bytes(_newName).length < 3) revert PersonaForge__NameTooShort(_newName);
        
        string memory oldName = _personaNames[_tokenId];
        _personaNames[_tokenId] = _newName;
        emit PersonaRenamed(_tokenId, oldName, _newName);
    }

    /// @notice Returns an array of skill IDs acquired by a specific Persona.
    /// @param _tokenId The ID of the Persona NFT.
    /// @return An array of skill IDs.
    function getPersonaSkills(uint256 _tokenId) public view returns (uint256[] memory) {
        if (!_exists(_tokenId)) revert ERC721NonexistentToken(_tokenId);
        return _personaSkills[_tokenId].values();
    }

    // --- II. Internal Essence Token Management ---

    /// @notice Internal function to mint and distribute Essence tokens. Callable by owner/DAO.
    /// @param _to The recipient address.
    /// @param _amount The amount of Essence to distribute.
    function distributeEssence(address _to, uint256 _amount) public onlyOwner {
        _essenceBalances[_to] += _amount;
        _totalSupplyEssence += _amount;
        emit EssenceDistributed(_to, _amount);
    }

    /// @notice Allows users to stake their Essence tokens.
    /// @param _amount The amount of Essence to stake.
    function stakeEssence(uint256 _amount) public {
        if (_essenceBalances[msg.sender] < _amount) {
            revert PersonaForge__InsufficientEssence(msg.sender, _amount, _essenceBalances[msg.sender]);
        }
        _essenceBalances[msg.sender] -= _amount;
        _essenceStakedBalances[msg.sender] += _amount;
        emit EssenceStaked(msg.sender, _amount);
    }

    /// @notice Allows users to unstake their previously staked Essence tokens.
    /// @param _amount The amount of Essence to unstake.
    function unstakeEssence(uint256 _amount) public {
        if (_essenceStakedBalances[msg.sender] < _amount) {
            revert PersonaForge__InsufficientEssence(msg.sender, _amount, _essenceStakedBalances[msg.sender]);
        }
        _essenceStakedBalances[msg.sender] -= _amount;
        _essenceBalances[msg.sender] += _amount;
        emit EssenceUnstaked(msg.sender, _amount);
    }

    /// @notice Returns the un-staked Essence token balance for an address.
    /// @param _owner The address to query.
    /// @return The un-staked Essence balance.
    function getEssenceBalance(address _owner) public view returns (uint256) {
        return _essenceBalances[_owner];
    }

    /// @notice Returns the staked Essence token balance for an address.
    /// @param _owner The address to query.
    /// @return The staked Essence balance.
    function getEssenceStaked(address _owner) public view returns (uint256) {
        return _essenceStakedBalances[_owner];
    }

    /// @notice Returns the total supply of Essence tokens.
    /// @return The total supply.
    function getTotalEssenceSupply() public view returns (uint256) {
        return _totalSupplyEssence;
    }

    // --- III. Skill Node Definition & Governance ---

    /// @notice Proposes a new skill to be added to the registry, with prerequisites and an attestation method.
    /// @param _name The name of the proposed skill.
    /// @param _description A description of the skill.
    /// @param _prerequisites An array of skill IDs that must be acquired first.
    /// @param _essenceCost The amount of Essence required to forge this skill (or stake if `ESSENCE_BURN_COST`).
    /// @param _attestationMethod The method by which this skill can be attested.
    /// @return The ID of the newly created skill proposal.
    function proposeSkill(
        string memory _name,
        string memory _description,
        uint256[] memory _prerequisites,
        uint256 _essenceCost,
        AttestationMethod _attestationMethod
    ) public onlyOwner returns (uint256) { // Currently onlyOwner, but ideally would be DAO
        uint256 currentSkillId = _nextSkillId++;
        skillNodes[currentSkillId] = SkillNode({
            name: _name,
            description: _description,
            prerequisites: _prerequisites,
            essenceCost: _essenceCost,
            attestationMethod: _attestationMethod,
            isActive: false // Starts inactive, needs to be finalized
        });
        
        uint256 proposalId = _nextProposalId++;
        skillProposals[proposalId] = SkillProposal({
            skillNodeId: currentSkillId,
            proposalId: proposalId,
            createdAt: block.timestamp,
            endTimestamp: block.timestamp + proposalDuration,
            totalVotesFor: 0,
            totalVotesAgainst: 0,
            voters: EnumerableSet.AddressSet(0),
            finalized: false,
            approved: false
        });
        
        emit SkillProposed(proposalId, currentSkillId, _name, msg.sender);
        return proposalId;
    }

    /// @notice Allows authorized DAO members (owners or accounts with staked Essence) to vote on a skill proposal.
    ///         Voting power is proportional to staked Essence.
    /// @param _proposalId The ID of the skill proposal.
    /// @param _approve True to vote for, false to vote against.
    function voteOnSkillProposal(uint256 _proposalId, bool _approve) public {
        // For simplicity, current 'DAO' means owner for skill creation, but voting
        // uses staked Essence. In a full DAO, voting would be managed by a separate contract
        // or a more complex governance module.
        SkillProposal storage proposal = skillProposals[_proposalId];
        if (proposal.proposalId == 0) revert PersonaForge__ProposalNotFound(_proposalId);
        if (proposal.finalized) revert PersonaForge__ProposalNotActive(_proposalId);
        if (block.timestamp > proposal.endTimestamp) revert PersonaForge__ProposalNotActive(_proposalId);
        if (proposal.voters.contains(msg.sender)) revert PersonaForge__ProposalAlreadyVoted(_proposalId, msg.sender);

        uint256 votingPower = _essenceStakedBalances[msg.sender];
        if (votingPower == 0) {
            revert PersonaForge__InsufficientEssence(msg.sender, 1, 0); // Requires some stake to vote
        }

        if (_approve) {
            proposal.totalVotesFor += votingPower;
        } else {
            proposal.totalVotesAgainst += votingPower;
        }
        proposal.voters.add(msg.sender);

        emit SkillProposalVoted(_proposalId, msg.sender, _approve);
    }

    /// @notice Finalizes a skill proposal if it meets the voting threshold, activating the skill.
    /// @param _proposalId The ID of the skill proposal.
    function finalizeSkillProposal(uint256 _proposalId) public onlyOwner {
        SkillProposal storage proposal = skillProposals[_proposalId];
        if (proposal.proposalId == 0) revert PersonaForge__ProposalNotFound(_proposalId);
        if (proposal.finalized) revert PersonaForge__ProposalNotActive(_proposalId);
        if (block.timestamp <= proposal.endTimestamp) revert PersonaForge__ProposalNotActive(_proposalId); // Must be past duration

        uint256 totalVotes = proposal.totalVotesFor + proposal.totalVotesAgainst;
        if (totalVotes == 0) {
            revert PersonaForge__NotEnoughVotes(_proposalId);
        }

        bool approved = (proposal.totalVotesFor * 100) / totalVotes >= proposalVotingThreshold;
        
        proposal.finalized = true;
        proposal.approved = approved;

        if (approved) {
            SkillNode storage activatedSkill = skillNodes[proposal.skillNodeId];
            activatedSkill.isActive = true;
            emit SkillActivated(proposal.skillNodeId, activatedSkill.name);
        } else {
            // If not approved, the skill remains inactive. Can be re-proposed.
        }

        emit SkillProposalFinalized(_proposalId, approved, proposal.skillNodeId);
    }

    /// @notice Returns the full details of a registered skill.
    /// @param _skillId The ID of the skill.
    /// @return A tuple containing skill details (name, description, prerequisites, essenceCost, attestationMethod, isActive).
    function getSkillDetails(uint256 _skillId) public view returns (
        string memory name,
        string memory description,
        uint256[] memory prerequisites,
        uint256 essenceCost,
        AttestationMethod attestationMethod,
        bool isActive
    ) {
        if (skillNodes[_skillId].name == "") revert PersonaForge__SkillNotFound(_skillId); // Check if skill exists
        SkillNode storage skill = skillNodes[_skillId];
        return (
            skill.name,
            skill.description,
            skill.prerequisites,
            skill.essenceCost,
            skill.attestationMethod,
            skill.isActive
        );
    }

    /// @notice Returns the array of skill IDs required as prerequisites for a given skill.
    /// @param _skillId The ID of the skill.
    /// @return An array of prerequisite skill IDs.
    function getSkillPrerequisites(uint256 _skillId) public view returns (uint256[] memory) {
        if (skillNodes[_skillId].name == "") revert PersonaForge__SkillNotFound(_skillId);
        return skillNodes[_skillId].prerequisites;
    }

    /// @notice Owner/DAO can update the Essence cost for acquiring a skill.
    /// @param _skillId The ID of the skill.
    /// @param _newCost The new Essence cost.
    function updateSkillEssenceCost(uint256 _skillId, uint256 _newCost) public onlyOwner {
        if (skillNodes[_skillId].name == "") revert PersonaForge__SkillNotFound(_skillId);
        skillNodes[_skillId].essenceCost = _newCost;
        emit SkillEssenceCostUpdated(_skillId, _newCost);
    }

    /// @notice Owner/DAO can deactivate a skill, preventing further acquisition.
    /// @param _skillId The ID of the skill.
    function deactivateSkill(uint256 _skillId) public onlyOwner {
        if (skillNodes[_skillId].name == "") revert PersonaForge__SkillNotFound(_skillId);
        skillNodes[_skillId].isActive = false;
        emit SkillDeactivated(_skillId);
    }

    // --- IV. Skill Attestation & Forging Logic ---

    /// @notice The core function to initiate skill acquisition. It processes `_attestationData`
    ///         based on the skill's `AttestationMethod`. This sets a temporary attestation.
    /// @param _personaId The ID of the Persona NFT.
    /// @param _skillId The ID of the skill to attest for.
    /// @param _attestationData Arbitrary data specific to the attestation method (e.g., signature, parameters).
    function attestSkill(
        uint256 _personaId,
        uint256 _skillId,
        bytes memory _attestationData
    ) public onlyPersonaOwnerOrDelegate(_personaId) {
        if (!_exists(_personaId)) revert ERC721NonexistentToken(_personaId);
        if (_personaSkills[_personaId].contains(_skillId)) revert PersonaForge__SkillAlreadyAcquired(_personaId, _skillId);
        
        SkillNode storage skill = skillNodes[_skillId];
        if (skill.name == "") revert PersonaForge__SkillNotFound(_skillId);
        if (!skill.isActive) revert PersonaForge__SkillNotActive(_skillId);

        // Check prerequisites
        for (uint256 i = 0; i < skill.prerequisites.length; i++) {
            if (!_personaSkills[_personaId].contains(skill.prerequisites[i])) {
                revert PersonaForge__SkillPrerequisitesNotMet(_personaId, _skillId);
            }
        }

        if (_activeAttestations[_personaId][_skillId].skillId != 0) {
            revert PersonaForge__AttestationAlreadyExists(_personaId, _skillId);
        }

        bool attestationSuccessful = false;
        if (skill.attestationMethod == AttestationMethod.NONE) {
            // No specific attestation required, simply needs to be forged.
            attestationSuccessful = true;
        } else if (skill.attestationMethod == AttestationMethod.ESSENCE_BURN_COST) {
            uint256 costAmount = skill.essenceCost;
            if (_essenceBalances[msg.sender] < costAmount) {
                revert PersonaForge__InsufficientEssence(msg.sender, costAmount, _essenceBalances[msg.sender]);
            }
            _essenceBalances[msg.sender] -= costAmount;
            _totalSupplyEssence -= costAmount; // Essence is burned as a cost
            attestationSuccessful = true;
        } else if (skill.attestationMethod == AttestationMethod.EXTERNAL_VERIFIED_CLAIM) {
            // _attestationData should be abi.encodePacked(signature, signerAddress, expiryTimestamp)
            if (_attestationData.length == 0) revert PersonaForge__InvalidAttestationData();
            
            // Decode the data: signature (65 bytes), signer address (20 bytes), expiry timestamp (32 bytes)
            (bytes memory sig, address signer, uint256 expiry) = abi.decode(_attestationData, (bytes, address, uint256));

            if (block.timestamp > expiry) revert PersonaForge__AttestationExpired(_personaId, _skillId, expiry);

            // Message includes unique identifiers to prevent replay attacks across different contexts
            bytes32 messageHash = keccak256(abi.encodePacked(
                _personaId, _skillId, block.chainid, address(this), msg.sender, expiry
            ));
            bytes32 signedHash = messageHash.toEthSignedMessageHash();

            address recoveredSigner = signedHash.recover(sig);
            if (recoveredSigner != signer) revert PersonaForge__InvalidSignature(recoveredSigner, signer);

            if (!_guildMasters[_skillId].contains(signer)) revert PersonaForge__NotGuildMaster(signer, _skillId);
            attestationSuccessful = true;
        } else if (skill.attestationMethod == AttestationMethod.ONCHAIN_ACTION_PROOF) {
            // Example: _attestationData = abi.encode(address targetContract, uint256 requiredBalance, address tokenAddress)
            // This example checks if the Persona's owner holds a certain balance of an ERC20 token.
            // A more complex system would involve specific helper contracts or oracle calls.
            if (_attestationData.length == 0) revert PersonaForge__InvalidAttestationData();

            (address targetContract, uint256 requiredBalance, address tokenAddress) = 
                abi.decode(_attestationData, (address, uint256, address));
            
            // This is a placeholder for actual external contract interaction.
            // In a real scenario, you'd use an interface like IERC20 and call `balanceOf`.
            // Example: IERC20(tokenAddress).balanceOf(ownerOf(_personaId)) >= requiredBalance
            // For simplicity and to keep the contract self-contained, we'll simulate a check:
            if (tokenAddress == address(0) || requiredBalance == 0) { // If no specific token/balance, it passes (e.g. general interaction proof)
                attestationSuccessful = true;
            } else {
                // Here, you would implement actual logic to verify an on-chain action or state.
                // For a simple demonstration, let's assume if targetContract is not address(0),
                // it represents an interaction that has occurred. This needs careful design.
                if (targetContract != address(0) && requiredBalance == 1337) { // Dummy check
                    attestationSuccessful = true;
                } else {
                    revert PersonaForge__InvalidAttestationData();
                }
            }
        } else {
            revert PersonaForge__AttestationMethodNotSupported(bytes4(uint32(skill.attestationMethod)));
        }

        if (attestationSuccessful) {
            _activeAttestations[_personaId][_skillId] = PersonaAttestation({
                skillId: _skillId,
                methodUsed: skill.attestationMethod,
                attestationTimestamp: block.timestamp,
                forged: false
            });
            emit SkillAttested(_personaId, _skillId, skill.attestationMethod, msg.sender);
        } else {
            revert PersonaForge__InvalidAttestationData(); // Generic catch-all
        }
    }

    /// @notice Finalizes the skill acquisition for a Persona once an attestation is confirmed
    ///         and requirements (like Essence cost for forging) are met.
    /// @param _personaId The ID of the Persona NFT.
    /// @param _skillId The ID of the skill to forge.
    function forgeSkill(uint256 _personaId, uint256 _skillId) public onlyPersonaOwnerOrDelegate(_personaId) {
        if (!_exists(_personaId)) revert ERC721NonexistentToken(_personaId);
        if (_personaSkills[_personaId].contains(_skillId)) revert PersonaForge__SkillAlreadyAcquired(_personaId, _skillId);

        PersonaAttestation storage attestation = _activeAttestations[_personaId][_skillId];
        if (attestation.skillId == 0 || attestation.forged) {
            revert PersonaForge__NoActiveAttestationForSkill(_personaId, _skillId);
        }
        if (block.timestamp > attestation.attestationTimestamp + attestationGracePeriod) {
            delete _activeAttestations[_personaId][_skillId]; // Clear expired attestation
            revert PersonaForge__AttestationExpired(_personaId, _skillId, attestation.attestationTimestamp + attestationGracePeriod);
        }

        SkillNode storage skill = skillNodes[_skillId];
        // Forging might have additional costs not covered by attestation method itself.
        // For ESSENCE_BURN_COST, the cost was already handled in attestSkill.
        // For NONE, EXTERNAL_VERIFIED_CLAIM, ONCHAIN_ACTION_PROOF, the `essenceCost` needs to be paid here.
        if (skill.attestationMethod != AttestationMethod.ESSENCE_BURN_COST && skill.essenceCost > 0) {
             if (_essenceBalances[msg.sender] < skill.essenceCost) {
                revert PersonaForge__InsufficientEssence(msg.sender, skill.essenceCost, _essenceBalances[msg.sender]);
            }
            _essenceBalances[msg.sender] -= skill.essenceCost;
            _totalSupplyEssence -= skill.essenceCost; // Burn or transfer to owner/DAO
        }

        _personaSkills[_personaId].add(_skillId);
        attestation.forged = true; // Mark attestation as forged
        delete _activeAttestations[_personaId][_skillId]; // Clean up after forging
        emit SkillForged(_personaId, _skillId, msg.sender);
    }

    /// @notice Allows a Persona owner to delegate the right to perform `attestSkill` for their Persona to another address.
    /// @param _personaId The ID of the Persona NFT.
    /// @param _delegatee The address to delegate attestation rights to.
    function delegateAttestation(uint256 _personaId, address _delegatee) public {
        if (ownerOf(_personaId) != _msgSender()) revert PersonaForge__NotOwner(_personaId, _msgSender());
        if (_delegatee == address(0)) revert PersonaForge__InvalidAttestationData();
        if (_personaAttestationDelegates[_personaId] == _delegatee) revert PersonaForge__DelegationAlreadyExists(_delegatee);
        
        _personaAttestationDelegates[_personaId] = _delegatee;
        emit AttestationDelegated(_personaId, _msgSender(), _delegatee);
    }

    /// @notice Revokes a previously granted attestation delegation.
    /// @param _personaId The ID of the Persona NFT.
    /// @param _delegatee The address whose delegation to revoke.
    function revokeDelegation(uint256 _personaId, address _delegatee) public {
        if (ownerOf(_personaId) != _msgSender()) revert PersonaForge__NotOwner(_personaId, _msgSender());
        if (_personaAttestationDelegates[_personaId] != _delegatee) revert PersonaForge__NoActiveDelegation(_delegatee);

        delete _personaAttestationDelegates[_personaId];
        emit AttestationDelegationRevoked(_personaId, _msgSender(), _delegatee);
    }

    /// @notice Owner/DAO can designate addresses as "Guild Masters" who can sign off on `EXTERNAL_VERIFIED_CLAIM` attestations for specific skills.
    /// @param _skillId The ID of the skill.
    /// @param _guildMasterAddress The address to register as a Guild Master.
    function registerGuildMaster(uint256 _skillId, address _guildMasterAddress) public onlyOwner {
        if (skillNodes[_skillId].name == "") revert PersonaForge__SkillNotFound(_skillId);
        _guildMasters[_skillId].add(_guildMasterAddress);
        emit GuildMasterRegistered(_skillId, _guildMasterAddress);
    }

    /// @notice Removes a Guild Master.
    /// @param _skillId The ID of the skill.
    /// @param _guildMasterAddress The address to remove.
    function removeGuildMaster(uint256 _skillId, address _guildMasterAddress) public onlyOwner {
        if (skillNodes[_skillId].name == "") revert PersonaForge__SkillNotFound(_skillId);
        _guildMasters[_skillId].remove(_guildMasterAddress);
        emit GuildMasterRemoved(_skillId, _guildMasterAddress);
    }

    // --- V. Governance & System Control ---

    /// @notice Owner/DAO can adjust the percentage of votes required to pass a skill proposal.
    /// @param _newThreshold The new threshold (e.g., 60 for 60%). Must be between 0 and 100.
    function setVotingThreshold(uint256 _newThreshold) public onlyOwner {
        require(_newThreshold <= 100, "Threshold must be <= 100");
        emit VotingThresholdSet(proposalVotingThreshold, _newThreshold);
        proposalVotingThreshold = _newThreshold;
    }

    /// @notice Owner/DAO can set the duration for which skill proposals are open for voting.
    /// @param _newDuration The new duration in seconds.
    function setProposalDuration(uint256 _newDuration) public onlyOwner {
        require(_newDuration > 0, "Duration must be positive");
        emit ProposalDurationSet(proposalDuration, _newDuration);
        proposalDuration = _newDuration;
    }

    /// @notice Owner/DAO can set the grace period for attestations to be forged.
    /// @param _newPeriod The new grace period in seconds.
    function setAttestationGracePeriod(uint256 _newPeriod) public onlyOwner {
        emit AttestationGracePeriodSet(attestationGracePeriod, _newPeriod);
        attestationGracePeriod = _newPeriod;
    }

    // --- View Functions (Getters) ---

    /// @notice Returns the name of a Persona.
    /// @param _tokenId The ID of the Persona NFT.
    /// @return The name of the Persona.
    function getPersonaName(uint256 _tokenId) public view returns (string memory) {
        if (!_exists(_tokenId)) revert ERC721NonexistentToken(_tokenId);
        return _personaNames[_tokenId];
    }

    /// @notice Returns the current active attestation for a Persona and skill.
    /// @param _personaId The ID of the Persona NFT.
    /// @param _skillId The ID of the skill.
    /// @return A tuple containing attestation details (skillId, methodUsed, attestationTimestamp, forged status).
    function getPersonaActiveAttestation(uint256 _personaId, uint256 _skillId) public view returns (
        uint256 skillId, AttestationMethod methodUsed, uint256 attestationTimestamp, bool forged
    ) {
        PersonaAttestation storage attestation = _activeAttestations[_personaId][_skillId];
        return (attestation.skillId, attestation.methodUsed, attestation.attestationTimestamp, attestation.forged);
    }

    /// @notice Returns the address delegated to attest for a Persona.
    /// @param _personaId The ID of the Persona NFT.
    /// @return The delegated address, or address(0) if none.
    function getPersonaAttestationDelegate(uint256 _personaId) public view returns (address) {
        return _personaAttestationDelegates[_personaId];
    }

    /// @notice Checks if an address is a Guild Master for a specific skill.
    /// @param _skillId The ID of the skill.
    /// @param _guildMasterAddress The address to check.
    /// @return True if the address is a Guild Master for the skill, false otherwise.
    function isGuildMaster(uint256 _skillId, address _guildMasterAddress) public view returns (bool) {
        return _guildMasters[_skillId].contains(_guildMasterAddress);
    }

    /// @notice Returns details of a skill proposal.
    /// @param _proposalId The ID of the proposal.
    /// @return A tuple containing proposal details (skillNodeId, name, createdAt, endTimestamp, totalVotesFor, totalVotesAgainst, finalized status, approved status).
    function getSkillProposalDetails(uint256 _proposalId) public view returns (
        uint256 skillNodeId, string memory name, uint256 createdAt, uint256 endTimestamp,
        uint256 totalVotesFor, uint256 totalVotesAgainst, bool finalized, bool approved
    ) {
        SkillProposal storage proposal = skillProposals[_proposalId];
        if (proposal.proposalId == 0) revert PersonaForge__ProposalNotFound(_proposalId);
        
        SkillNode storage skill = skillNodes[proposal.skillNodeId]; // Retrieve the associated skill details
        return (
            proposal.skillNodeId,
            skill.name, // Use the skill's name from skillNodes
            proposal.createdAt,
            proposal.endTimestamp,
            proposal.totalVotesFor,
            proposal.totalVotesAgainst,
            proposal.finalized,
            proposal.approved
        );
    }

    /// @notice Returns the list of addresses that have voted on a skill proposal.
    /// @param _proposalId The ID of the proposal.
    /// @return An array of voter addresses.
    function getSkillProposalVoters(uint256 _proposalId) public view returns (address[] memory) {
        SkillProposal storage proposal = skillProposals[_proposalId];
        if (proposal.proposalId == 0) revert PersonaForge__ProposalNotFound(_proposalId);
        return proposal.voters.values();
    }
}
```