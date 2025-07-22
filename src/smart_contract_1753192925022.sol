This smart contract, named "Metamorphica," designs an ecosystem for "Adaptive Digital Entities" (ADEs), which are dynamic NFTs that evolve based on user interaction, resource expenditure, and community-verified "knowledge insights" (simulated AI feedback). It aims to be unique by integrating on-chain evolution, a reputation system, a DAO-lite for governance, and a mechanism for off-chain AI to influence on-chain states, without directly copying existing open-source projects for its core logic.

---

## Metamorphica - An Adaptive Digital Entity (ADE) Ecosystem

**Contract Purpose:**
This contract creates a dynamic NFT system where digital entities (ADEs) evolve based on user interactions, on-chain nurturing, and community-verified knowledge insights (simulated AI feedback). It features a custom token for interaction, a reputation system for users, and a decentralized council for governance over global evolution rules.

---

### Outline & Function Summary

**I. Core Infrastructure & Setup**
*   `constructor(string _initialBaseURI)`: Initializes the contract owner, base URI for ADE metadata, and initial evolution thresholds.
*   `updateBaseURI(string _newBaseURI)`: Allows the owner to update the base URI used for generating ADE metadata.
*   `pauseContract()`: Pauses certain contract functionalities (e.g., transfers, nurturing, minting). Callable by owner.
*   `unpauseContract()`: Unpauses the contract functionalities. Callable by owner.
*   `withdrawEth()`: Allows the contract owner to withdraw any accumulated native currency (ETH).

**II. Essence Token (Internal, simplified ERC-20-like)**
*   `mintEssence(address _to, uint256 _amount)`: Mints a specified amount of Essence tokens to an address. Restricted to owner/system.
*   `transferEssence(address _to, uint256 _amount)`: Allows a user to transfer their Essence tokens to another address.
*   `balanceOfEssence(address _owner)`: Returns the Essence token balance of a given address.
*   `approveEssence(address _spender, uint256 _amount)`: Approves a `_spender` to withdraw `_amount` of Essence tokens from the caller's balance.
*   `transferFromEssence(address _from, address _to, uint256 _amount)`: Allows an approved `_spender` to transfer `_amount` of Essence tokens from `_from` to `_to`.
*   `allowanceEssence(address _owner, address _spender)`: Returns the amount of Essence `_owner` has allowed `_spender` to withdraw.
*   `burnEssence(uint256 _amount)`: Allows a user to burn their own Essence tokens, reducing total supply and potentially gaining reputation.

**III. Adaptive Digital Entity (ADE) Management (Internal, simplified ERC-721-like)**
*   `mintADE(address _to, string memory _initialMetadataURI, uint256[] memory _initialTraits)`: Mints a new ADE (NFT) to a specified address, assigning initial traits and an optional specific metadata URI. Callable by owner.
*   `getADEInfo(uint256 _adeId)`: Retrieves all detailed information about a specific ADE.
*   `getADEOwner(uint256 _adeId)`: Returns the current owner's address for a given ADE.
*   `transferADE(address _from, address _to, uint256 _adeId)`: Transfers ownership of an ADE from `_from` to `_to`. Requires `_from` or `msg.sender` to be the owner, or `msg.sender` to be the contract owner.
*   `getTokenURIAde(uint256 _adeId)`: Constructs and returns the full metadata URI for an ADE, prioritizing its specific URI over the base URI.

**IV. Nurturing & Evolution System**
*   `nurtureADE(uint256 _adeId, uint256 _essenceAmount)`: Allows an ADE owner to spend Essence tokens to nurture their ADE, increasing its evolution progress and potentially triggering evolution.
*   `_tryEvolveADE(uint256 _adeId)`: Internal function to check if an ADE meets evolution requirements and trigger its evolution.
*   `_applyEvolutionTraits(ADE storage _ade)`: Internal function applying new traits to an ADE upon evolution, potentially influenced by knowledge insights and global rules.
*   `evolveADE(uint256 _adeId)`: Explicitly triggers an ADE's evolution if its nurturing progress meets the required threshold. Callable by ADE owner.
*   `getCurrentTraits(uint256 _adeId)`: Returns the array of current trait IDs for a given ADE.
*   `getADEEvolutionProgress(uint256 _adeId)`: Shows the current nurturing progress of an ADE towards its next evolution stage, and the total Essence required.
*   `setEvolutionStageThreshold(uint256 _stageId, uint256 _essenceRequired)`: Allows the owner (or eventually governance) to set the Essence requirement for an ADE to reach a specific evolution stage.
*   `getEvolutionStageThreshold(uint256 _stageId)`: Retrieves the Essence requirement for a specified evolution stage.

**V. Reputation System (Nurturer Reputation)**
*   `getUserReputation(address _user)`: Returns the reputation score of a specific user.
*   `_updateUserReputation(address _user, int256 _delta)`: Internal helper function to adjust a user's reputation score.

**VI. Knowledge Pool & AI Integration (Oracle Interaction)**
*   `submitKnowledgeInsight(bytes32 _insightHash, string memory _description)`: Allows users to submit a hash (e.g., representing AI model outputs or analyzed data) as a "knowledge insight" for verification.
*   `verifyKnowledgeInsight(bytes32 _insightHash, bool _isValid)`: Allows a registered oracle to mark a submitted knowledge insight as verified or rejected, influencing global evolution rules.
*   `getKnowledgeInsightStatus(bytes32 _insightHash)`: Returns the current verification status of a knowledge insight.
*   `requestAIInsight(uint256 _adeId, bytes32 _requestHash)`: Allows an ADE owner to formally request an off-chain AI analysis for their ADE, signaling to an oracle.

**VII. Decentralized Evolution Council (DAO-lite)**
*   `createProposal(string memory _description, bytes memory _calldata, address _targetContract, uint256 _minReputationToVote, uint256 _minEssenceToVote)`: Allows eligible users to propose changes to the contract's parameters or logic, subject to community vote.
*   `voteOnProposal(uint256 _proposalId, bool _support)`: Allows eligible users (based on reputation and Essence holdings) to cast a 'yay' or 'nay' vote on an active proposal.
*   `executeProposal(uint256 _proposalId)`: Executes a proposal that has passed its voting period and met the success criteria. Can be called by anyone.
*   `getProposalDetails(uint256 _proposalId)`: Retrieves descriptive details of a specific governance proposal.
*   `getProposalVoteCounts(uint256 _proposalId)`: Returns the current 'yay' and 'nay' vote counts for a proposal.

**VIII. Advanced Concepts/Utilities**
*   `setTraitInfluence(uint256 _traitId, uint256 _influenceScore)`: Allows the owner (or governance) to set an influence score for a specific trait, affecting its role in evolution dynamics.
*   `getTraitInfluence(uint256 _traitId)`: Retrieves the influence score of a specific trait.
*   `simulateEvolutionOutcome(uint256 _adeId, uint256 _nurtureAmount)`: A pure/view function that simulates the ADE's evolution outcome if a specified amount of Essence were nurtured, without changing state.
*   `registerOracle(address _oracleAddress)`: Allows the owner to register an address as an authorized oracle for knowledge insights.
*   `removeOracle(address _oracleAddress)`: Allows the owner to remove a registered oracle address.
*   `isOracle(address _addr)`: Checks if a given address is a registered oracle.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

/**
 * @title Metamorphica - An Adaptive Digital Entity (ADE) Ecosystem
 * @dev This contract creates a dynamic NFT system where digital entities (ADEs) evolve based on user interactions,
 *      on-chain nurturing, and community-verified knowledge insights (simulated AI feedback).
 *      It features a custom token for interaction, a reputation system for users, and a decentralized council
 *      for governance over global evolution rules.
 */
contract Metamorphica is Ownable, Pausable {

    /* ============ Outline & Function Summary ============ */
    // I. Core Infrastructure & Setup
    //    - constructor: Initialize core parameters.
    //    - updateBaseURI: Update the base URI for ADE metadata.
    //    - pauseContract/unpauseContract: Control contract operation.
    //    - withdrawEth: Owner withdraws accumulated ETH.

    // II. Essence Token (Internal, simplified ERC-20-like)
    //    - mintEssence: Mints Essence tokens (admin/system only).
    //    - transferEssence: Allows users to transfer Essence.
    //    - balanceOfEssence: Checks an address's Essence balance.
    //    - approveEssence: Allows a spender to withdraw Essence on behalf of the owner.
    //    - transferFromEssence: Spender transfers Essence.
    //    - allowanceEssence: Checks allowance for a spender.
    //    - burnEssence: Allows users to burn Essence.

    // III. Adaptive Digital Entity (ADE) Management (Internal, simplified ERC-721-like)
    //    - mintADE: Creates a new ADE, assigns initial traits.
    //    - getADEInfo: Retrieves all stored information for an ADE.
    //    - getADEOwner: Gets the owner of an ADE.
    //    - transferADE: Transfers ownership of an ADE.
    //    - getTokenURIAde: Returns the metadata URI for an ADE.

    // IV. Nurturing & Evolution System
    //    - nurtureADE: Users spend Essence to nurture their ADE, contributing to its evolution progress.
    //    - _tryEvolveADE: Internal function to attempt ADE evolution.
    //    - _applyEvolutionTraits: Internal function to apply new traits during evolution.
    //    - evolveADE: Explicitly triggers an ADE's evolution.
    //    - getCurrentTraits: Gets the current traits of an ADE.
    //    - getADEEvolutionProgress: Checks an ADE's current evolution progress.
    //    - setEvolutionStageThreshold: Admin/Council sets Essence requirements for evolution stages.
    //    - getEvolutionStageThreshold: Retrieves the Essence requirement for a specific evolution stage.

    // V. Reputation System (Nurturer Reputation)
    //    - getUserReputation: Retrieves a user's reputation score.
    //    - _updateUserReputation: Internal helper to adjust reputation based on actions.

    // VI. Knowledge Pool & AI Integration (Oracle Interaction)
    //    - submitKnowledgeInsight: Users submit a hashed knowledge insight (e.g., from off-chain AI) for verification.
    //    - verifyKnowledgeInsight: Oracle/Admin marks an insight as verified, potentially influencing global rules.
    //    - getKnowledgeInsightStatus: Checks the verification status of a knowledge insight.
    //    - requestAIInsight: Allows users to formally request off-chain AI analysis for their ADE.

    // VII. Decentralized Evolution Council (DAO-lite)
    //    - createProposal: Creates a new governance proposal for the Evolution Council.
    //    - voteOnProposal: Allows eligible users to vote on an active proposal.
    //    - executeProposal: Executes a proposal once it passes and the voting period ends.
    //    - getProposalDetails: Retrieves details of a specific proposal.
    //    - getProposalVoteCounts: Gets current vote counts for a proposal.

    // VIII. Advanced Concepts/Utilities
    //    - setTraitInfluence: Admin/Council sets how much a trait influences future evolution or other dynamics.
    //    - getTraitInfluence: Retrieves the influence score of a trait.
    //    - simulateEvolutionOutcome: Simulates the outcome of nurturing without changing state, for user planning.
    //    - registerOracle: Allows the owner to register an oracle address.
    //    - removeOracle: Allows the owner to remove an oracle address.
    //    - isOracle: Checks if an address is a registered oracle.

    /* ============ State Variables ============ */

    // Essence Token properties (simplified)
    string public constant ESSENCE_NAME = "Essence";
    string public constant ESSENCE_SYMBOL = "ESS";
    uint8 public constant ESSENCE_DECIMALS = 18; // Standard for token divisibility
    mapping(address => uint256) private _essenceBalances;
    mapping(address => mapping(address => uint256)) private _essenceAllowances;
    uint256 private _totalEssenceSupply;

    // ADE (NFT) properties
    uint256 private _adeCounter;
    string public baseTokenURI; // Base URI for ADE metadata (e.g., IPFS gateway)

    struct ADE {
        uint256 id;
        address owner;
        uint256 currentStage;
        uint256 currentEssenceNurtured; // Essence contributed to current stage
        uint256 lastNurtureTimestamp;
        uint256[] currentTraits; // Array of trait IDs. Actual trait data (name, description) stored off-chain.
        string metadataURI; // Specific URI for this ADE, or appended to baseTokenURI
    }
    mapping(uint256 => ADE) private _ades;
    mapping(address => uint256[]) private _ownerADEs; // Track ADEs owned by an address (simplified for demo)
    mapping(uint256 => address) private _adeOwners; // Directly map ADE ID to owner for quick lookup

    // Reputation System
    mapping(address => int256) public userReputation; // Can be positive or negative based on contributions/actions

    // Evolution Configuration
    mapping(uint256 => uint256) public evolutionStageThresholds; // stageId => essenceRequired

    // Traits (simplified representation; actual trait data off-chain/in metadata service)
    mapping(uint256 => uint256) public traitInfluenceScores; // traitId => influenceScore (e.g., how much this trait affects evolution speed)

    // Knowledge Pool (AI Integration)
    enum InsightStatus { Pending, Verified, Rejected }
    struct KnowledgeInsight {
        address submitter;
        uint256 submissionTimestamp;
        InsightStatus status;
        string description; // A brief description of the insight's nature
    }
    mapping(bytes32 => KnowledgeInsight) public knowledgeInsights; // insightHash => KnowledgeInsight
    event KnowledgeInsightSubmitted(bytes32 indexed insightHash, address indexed submitter);
    event KnowledgeInsightVerified(bytes32 indexed insightHash, address indexed verifier, bool isValid);

    // Oracle Management
    mapping(address => bool) public isRegisteredOracle;
    address[] private _registeredOracles; // To facilitate removal and potential future iteration

    // Decentralized Evolution Council (DAO-lite)
    uint256 private _proposalCounter;
    enum ProposalStatus { Active, Succeeded, Failed, Executed }
    struct Proposal {
        uint256 id;
        string description;
        address proposer;
        uint256 creationTimestamp;
        uint256 votingEndTime;
        uint256 yayVotes;
        uint256 nayVotes;
        mapping(address => bool) hasVoted; // Tracks if a specific address has voted on this proposal
        ProposalStatus status;
        bytes callData; // The ABI-encoded call data for the target function if proposal passes
        address targetContract; // The contract to call if proposal passes (e.g., this contract itself)
        uint256 minReputationToVote;
        uint256 minEssenceToVote;
    }
    mapping(uint256 => Proposal) public proposals;
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer);
    event ProposalVoted(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId);

    /* ============ Constructor ============ */
    constructor(string memory _initialBaseURI) Ownable(msg.sender) Pausable() {
        baseTokenURI = _initialBaseURI;
        _adeCounter = 0;
        _proposalCounter = 0;

        // Set initial evolution thresholds (example values, can be changed by governance)
        // Values are in smallest unit (wei for 18 decimals)
        evolutionStageThresholds[1] = 100 * (10 ** ESSENCE_DECIMALS); // Stage 1 requires 100 ESS
        evolutionStageThresholds[2] = 250 * (10 ** ESSENCE_DECIMALS); // Stage 2 requires 250 ESS
        evolutionStageThresholds[3] = 500 * (10 ** ESSENCE_DECIMALS); // Stage 3 requires 500 ESS
        // More stages can be configured via governance proposals.
    }

    /* ============ Modifiers ============ */

    /**
     * @dev Restricts access to registered oracle addresses.
     */
    modifier onlyOracle() {
        require(isRegisteredOracle[msg.sender], "Metamorphica: Caller is not a registered oracle");
        _;
    }

    /* ============ I. Core Infrastructure & Setup ============ */

    /**
     * @dev Updates the base URI for ADE metadata. This URI typically points to a gateway
     *      that resolves token IDs into dynamic JSON metadata (e.g., IPFS gateway).
     *      Only the contract owner can call this.
     * @param _newBaseURI The new base URI.
     */
    function updateBaseURI(string memory _newBaseURI) external onlyOwner {
        baseTokenURI = _newBaseURI;
    }

    /**
     * @dev Pauses the contract. When paused, certain state-changing functions
     *      (like minting, transferring tokens, nurturing) are restricted.
     *      Only the contract owner can call this.
     */
    function pauseContract() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract, restoring full functionality.
     *      Only the contract owner can call this.
     */
    function unpauseContract() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Allows the contract owner to withdraw any accumulated native currency (ETH)
     *      that has been sent to the contract address.
     */
    function withdrawEth() external onlyOwner {
        (bool success,) = payable(owner()).call{value: address(this).balance}("");
        require(success, "Metamorphica: ETH withdrawal failed");
    }

    /* ============ II. Essence Token (Internal, simplified ERC-20-like) ============ */

    /**
     * @dev Mints Essence tokens to a specified address. This function is typically used
     *      for initial distribution or by specific system mechanics (e.g., rewards).
     *      Only callable by the owner when the contract is not paused.
     * @param _to The address to mint tokens to.
     * @param _amount The amount of tokens to mint (in smallest units, e.g., wei).
     */
    function mintEssence(address _to, uint256 _amount) public onlyOwner whenNotPaused {
        _essenceBalances[_to] += _amount;
        _totalEssenceSupply += _amount;
        // In a full ERC-20, an `event Transfer(address(0), _to, _amount)` would be emitted here.
    }

    /**
     * @dev Allows a user to transfer Essence tokens from their balance to another address.
     *      Requires the sender to have sufficient balance.
     * @param _to The recipient address.
     * @param _amount The amount of tokens to transfer (in smallest units).
     * @return True if the transfer was successful.
     */
    function transferEssence(address _to, uint256 _amount) public whenNotPaused returns (bool) {
        require(_essenceBalances[msg.sender] >= _amount, "Metamorphica: Insufficient Essence balance");
        _essenceBalances[msg.sender] -= _amount;
        _essenceBalances[_to] += _amount;
        // In a full ERC-20, an `event Transfer(msg.sender, _to, _amount)` would be emitted here.
        return true;
    }

    /**
     * @dev Returns the Essence token balance of a specific address.
     * @param _owner The address to query the balance of.
     * @return The balance of Essence tokens (in smallest units).
     */
    function balanceOfEssence(address _owner) public view returns (uint256) {
        return _essenceBalances[_owner];
    }

    /**
     * @dev Allows a user to approve a `_spender` address to withdraw a specified `_amount`
     *      of Essence tokens on their behalf. This is crucial for mechanisms where a contract
     *      needs to pull tokens from a user.
     * @param _spender The address to approve.
     * @param _amount The amount to approve (in smallest units).
     * @return True if the approval was successful.
     */
    function approveEssence(address _spender, uint256 _amount) public whenNotPaused returns (bool) {
        _essenceAllowances[msg.sender][_spender] = _amount;
        // In a full ERC-20, an `event Approval(msg.sender, _spender, _amount)` would be emitted here.
        return true;
    }

    /**
     * @dev Allows an approved `_spender` to transfer Essence tokens from one address (`_from`)
     *      to another (`_to`). Requires `msg.sender` to have sufficient allowance from `_from`.
     * @param _from The owner of the tokens.
     * @param _to The recipient address.
     * @param _amount The amount of tokens to transfer (in smallest units).
     * @return True if the transfer was successful.
     */
    function transferFromEssence(address _from, address _to, uint256 _amount) public whenNotPaused returns (bool) {
        require(_essenceBalances[_from] >= _amount, "Metamorphica: Insufficient Essence balance from owner");
        require(_essenceAllowances[_from][msg.sender] >= _amount, "Metamorphica: Insufficient Essence allowance for sender");

        _essenceBalances[_from] -= _amount;
        _essenceAllowances[_from][msg.sender] -= _amount;
        _essenceBalances[_to] += _amount;
        // In a full ERC-20, an `event Transfer(_from, _to, _amount)` would be emitted here.
        return true;
    }

    /**
     * @dev Returns the amount of Essence tokens that an `_owner` has allowed a `_spender` to withdraw.
     * @param _owner The address of the token owner.
     * @param _spender The address of the spender.
     * @return The remaining allowance (in smallest units).
     */
    function allowanceEssence(address _owner, address _spender) public view returns (uint256) {
        return _essenceAllowances[_owner][_spender];
    }

    /**
     * @dev Allows a user to burn their own Essence tokens. This acts as a deflationary mechanism
     *      and can be used to signal commitment or gain small reputation boosts.
     * @param _amount The amount of Essence tokens to burn (in smallest units).
     */
    function burnEssence(uint256 _amount) public whenNotPaused {
        require(_essenceBalances[msg.sender] >= _amount, "Metamorphica: Insufficient Essence balance to burn");
        _essenceBalances[msg.sender] -= _amount;
        _totalEssenceSupply -= _amount;
        // In a full ERC-20, an `event Transfer(msg.sender, address(0), _amount)` would be emitted here.
        _updateUserReputation(msg.sender, int256(_amount / (10 ** ESSENCE_DECIMALS) / 10)); // Example: 10% of burned amount (as whole ESS) for reputation
    }

    /* ============ III. Adaptive Digital Entity (ADE) Management (Internal, simplified ERC-721-like) ============ */

    /**
     * @dev Mints a new Adaptive Digital Entity (ADE) and assigns initial traits.
     *      This function generates a unique ID for the new ADE and initializes its properties.
     *      Only callable by the contract owner when the contract is not paused.
     * @param _to The address that will receive ownership of the new ADE.
     * @param _initialMetadataURI Optional. A specific metadata URI for this ADE. If empty, `baseTokenURI` + ID is used.
     * @param _initialTraits An array of integer IDs representing the ADE's initial traits.
     * @return The ID of the newly minted ADE.
     */
    function mintADE(address _to, string memory _initialMetadataURI, uint256[] memory _initialTraits) public onlyOwner whenNotPaused returns (uint256) {
        _adeCounter++;
        uint256 newAdeId = _adeCounter;

        _ades[newAdeId] = ADE({
            id: newAdeId,
            owner: _to,
            currentStage: 0, // Starts at stage 0 (un-evolved state)
            currentEssenceNurtured: 0,
            lastNurtureTimestamp: block.timestamp,
            currentTraits: _initialTraits,
            metadataURI: _initialMetadataURI
        });

        _adeOwners[newAdeId] = _to;
        _ownerADEs[_to].push(newAdeId); // Simplified tracking of ADEs per owner
        // In a full ERC-721, an `event Transfer(address(0), _to, newAdeId)` would be emitted here.
        return newAdeId;
    }

    /**
     * @dev Retrieves all stored information for a specific ADE.
     * @param _adeId The ID of the ADE to query.
     * @return A tuple containing all stored ADE details.
     */
    function getADEInfo(uint256 _adeId) public view returns (uint256 id, address owner, uint256 currentStage, uint256 currentEssenceNurtured, uint256 lastNurtureTimestamp, uint256[] memory currentTraits, string memory metadataURI) {
        ADE storage ade = _ades[_adeId];
        require(ade.id != 0, "Metamorphica: ADE does not exist");
        return (ade.id, ade.owner, ade.currentStage, ade.currentEssenceNurtured, ade.lastNurtureTimestamp, ade.currentTraits, ade.metadataURI);
    }

    /**
     * @dev Gets the owner of a specific ADE.
     * @param _adeId The ID of the ADE.
     * @return The address of the ADE's owner.
     */
    function getADEOwner(uint256 _adeId) public view returns (address) {
        require(_ades[_adeId].id != 0, "Metamorphica: ADE does not exist");
        return _adeOwners[_adeId];
    }

    /**
     * @dev Transfers ownership of an ADE from one address to another.
     *      The caller must be either the current owner of the ADE or the contract owner.
     * @param _from The current owner of the ADE.
     * @param _to The new owner of the ADE.
     * @param _adeId The ID of the ADE to transfer.
     */
    function transferADE(address _from, address _to, uint256 _adeId) public whenNotPaused {
        require(msg.sender == _from || msg.sender == _adeOwners[_adeId] || msg.sender == owner(), "Metamorphica: Not authorized to transfer ADE");
        require(_adeOwners[_adeId] == _from, "Metamorphica: _from is not the ADE owner");
        require(_to != address(0), "Metamorphica: Transfer to the zero address is not allowed");

        // Remove from _from's list of ADEs
        uint256[] storage fromADEs = _ownerADEs[_from];
        for (uint256 i = 0; i < fromADEs.length; i++) {
            if (fromADEs[i] == _adeId) {
                fromADEs[i] = fromADEs[fromADEs.length - 1]; // Move last element to current position
                fromADEs.pop(); // Remove last element
                break;
            }
        }

        _adeOwners[_adeId] = _to; // Update direct owner mapping
        _ades[_adeId].owner = _to; // Update owner in ADE struct directly
        _ownerADEs[_to].push(_adeId); // Add to _to's list of ADEs

        // In a full ERC-721, an `event Transfer(_from, _to, _adeId)` would be emitted here.
    }

    /**
     * @dev Returns the metadata URI for a given ADE. This URI is intended to resolve
     *      to a JSON file describing the ADE, following ERC-721 metadata standards.
     *      It prioritizes a specific `metadataURI` set for the ADE; otherwise, it
     *      constructs one using the `baseTokenURI` and the ADE's ID.
     * @param _adeId The ID of the ADE.
     * @return The full metadata URI.
     */
    function getTokenURIAde(uint256 _adeId) public view returns (string memory) {
        require(_ades[_adeId].id != 0, "Metamorphica: ADE does not exist");
        if (bytes(_ades[_adeId].metadataURI).length > 0) {
            return _ades[_adeId].metadataURI; // Priority to specific URI
        } else {
            // Append ADE ID to base URI (e.g., ipfs://baseuri/123.json)
            return string(abi.encodePacked(baseTokenURI, Strings.toString(_adeId), ".json"));
        }
    }

    /* ============ IV. Nurturing & Evolution System ============ */

    /**
     * @dev Allows an ADE owner to nurture their ADE by spending Essence tokens.
     *      This action increases the ADE's `currentEssenceNurtured` progress towards evolution.
     *      A reputation boost is also awarded for nurturing.
     * @param _adeId The ID of the ADE to nurture.
     * @param _essenceAmount The amount of Essence tokens to spend (in smallest units).
     */
    function nurtureADE(uint256 _adeId, uint256 _essenceAmount) public whenNotPaused {
        ADE storage ade = _ades[_adeId];
        require(ade.id != 0, "Metamorphica: ADE does not exist");
        require(ade.owner == msg.sender, "Metamorphica: Caller is not the ADE owner");
        require(_essenceBalances[msg.sender] >= _essenceAmount, "Metamorphica: Insufficient Essence balance to nurture");
        require(_essenceAmount > 0, "Metamorphica: Nurture amount must be positive");

        _essenceBalances[msg.sender] -= _essenceAmount; // Deduct Essence
        ade.currentEssenceNurtured += _essenceAmount; // Increase nurtured progress
        ade.lastNurtureTimestamp = block.timestamp;

        // Reward nurturing with reputation (e.g., 20% of whole ESS amount spent)
        _updateUserReputation(msg.sender, int256(_essenceAmount / (10 ** ESSENCE_DECIMALS) / 5));

        // Attempt to trigger automatic evolution if conditions are met
        _tryEvolveADE(_adeId);
    }

    /**
     * @dev Internal function to attempt evolution of an ADE if conditions are met.
     *      This function is called automatically after `nurtureADE` or explicitly via `evolveADE`.
     *      An ADE evolves when `currentEssenceNurtured` meets or exceeds the `evolutionStageThreshold`
     *      for the next stage.
     * @param _adeId The ID of the ADE to check for evolution.
     */
    function _tryEvolveADE(uint256 _adeId) internal {
        ADE storage ade = _ades[_adeId];
        uint256 nextStage = ade.currentStage + 1;
        uint256 requiredEssence = evolutionStageThresholds[nextStage];

        // Check if there's a defined threshold for the next stage and if enough Essence has been nurtured
        if (requiredEssence > 0 && ade.currentEssenceNurtured >= requiredEssence) {
            ade.currentEssenceNurtured -= requiredEssence; // Deduct the essence used for this stage's evolution
            ade.currentStage = nextStage; // Advance to the next stage

            // Apply new traits and other effects based on the new stage and global rules
            _applyEvolutionTraits(ade);

            // In a real system, an `event ADEEvolution(ade.id, ade.currentStage)` would be emitted here.
        }
    }

    /**
     * @dev Internal function to apply new traits during evolution.
     *      This is where advanced logic would reside, incorporating:
     *      1. Random trait selection from a pool specific to the new stage.
     *      2. Probabilistic adjustments based on verified `KnowledgeInsights` (e.g., AI output suggests certain traits improve ADEs).
     *      3. Influence from global `traitInfluenceScores` or historical user nurturing patterns.
     *      For this example, it simply adds a basic trait and applies trait influences.
     * @param _ade The ADE struct reference to modify.
     */
    function _applyEvolutionTraits(ADE storage _ade) internal {
        // Example: Add a new generic trait ID for each new stage.
        // In a more complex system, this would involve selecting from predefined trait pools.
        uint256 newTraitIdForStage = 1000 + _ade.currentStage; // Simple placeholder trait ID
        bool traitExists = false;
        for (uint256 i = 0; i < _ade.currentTraits.length; i++) {
            if (_ade.currentTraits[i] == newTraitIdForStage) {
                traitExists = true;
                break;
            }
        }
        if (!traitExists) {
             _ade.currentTraits.push(newTraitIdForStage);
        }

        // Apply global trait influences to current progress or future growth.
        // For instance, a "Speedy" trait might cause already nurtured essence to have more value.
        for (uint256 i = 0; i < _ade.currentTraits.length; i++) {
            uint256 influence = traitInfluenceScores[_ade.currentTraits[i]];
            if (influence > 0) {
                // Example: Increase `currentEssenceNurtured` by a small percentage based on trait influence.
                // This means certain traits make evolution easier or faster.
                _ade.currentEssenceNurtured += (_ade.currentEssenceNurtured * influence) / 10000; // `influence` is a permille (per 10000)
            }
        }
    }

    /**
     * @dev Explicitly triggers an ADE's evolution to the next stage if conditions are met.
     *      This can be called by the ADE owner if they believe their ADE is ready to evolve,
     *      even if `nurtureADE` didn't trigger it automatically (e.g., after an external Essence transfer).
     * @param _adeId The ID of the ADE to evolve.
     */
    function evolveADE(uint256 _adeId) public whenNotPaused {
        require(_ades[_adeId].owner == msg.sender, "Metamorphica: Caller is not the ADE owner");
        _tryEvolveADE(_adeId);
    }

    /**
     * @dev Gets the current traits of an ADE. Traits are represented by integer IDs.
     *      Actual trait data (names, images) would be resolved off-chain via the metadata URI.
     * @param _adeId The ID of the ADE.
     * @return An array of current trait IDs.
     */
    function getCurrentTraits(uint256 _adeId) public view returns (uint256[] memory) {
        require(_ades[_adeId].id != 0, "Metamorphica: ADE does not exist");
        return _ades[_adeId].currentTraits;
    }

    /**
     * @dev Checks how far an ADE is in its current evolution stage.
     * @param _adeId The ID of the ADE.
     * @return currentEssenceNurtured The amount of Essence currently nurtured towards the next stage.
     * @return essenceRequiredForNextStage The total Essence required for the ADE to reach the next stage.
     */
    function getADEEvolutionProgress(uint256 _adeId) public view returns (uint256 currentEssenceNurtured, uint256 essenceRequiredForNextStage) {
        ADE storage ade = _ades[_adeId];
        require(ade.id != 0, "Metamorphica: ADE does not exist");
        uint256 nextStage = ade.currentStage + 1;
        return (ade.currentEssenceNurtured, evolutionStageThresholds[nextStage]);
    }

    /**
     * @dev Allows the owner (and later potentially the Evolution Council) to set the Essence
     *      required for an ADE to reach a specific evolution stage. This enables dynamic adjustment
     *      of the evolution curve.
     * @param _stageId The ID of the evolution stage (e.g., 1, 2, 3...).
     * @param _essenceRequired The amount of Essence tokens required for this stage (in smallest units).
     */
    function setEvolutionStageThreshold(uint256 _stageId, uint256 _essenceRequired) public onlyOwner {
        require(_stageId > 0, "Metamorphica: Stage ID must be positive");
        evolutionStageThresholds[_stageId] = _essenceRequired;
    }

    /**
     * @dev Retrieves the Essence requirement for a specific evolution stage.
     * @param _stageId The ID of the evolution stage.
     * @return The amount of Essence tokens required (in smallest units).
     */
    function getEvolutionStageThreshold(uint256 _stageId) public view returns (uint256) {
        return evolutionStageThresholds[_stageId];
    }

    /* ============ V. Reputation System (Nurturer Reputation) ============ */

    /**
     * @dev Retrieves a user's reputation score. Reputation can influence voting power,
     *      access to certain features, or represent a user's standing in the ecosystem.
     * @param _user The address of the user.
     * @return The reputation score (can be negative).
     */
    function getUserReputation(address _user) public view returns (int256) {
        return userReputation[_user];
    }

    /**
     * @dev Internal function to update a user's reputation score. This function is called
     *      by other system functions (e.g., `nurtureADE`, `submitKnowledgeInsight`, `voteOnProposal`)
     *      to reward positive actions or penalize negative ones.
     * @param _user The address of the user.
     * @param _delta The amount to add or subtract from the user's reputation.
     */
    function _updateUserReputation(address _user, int256 _delta) internal {
        userReputation[_user] += _delta;
    }

    /* ============ VI. Knowledge Pool & AI Integration (Oracle Interaction) ============ */

    /**
     * @dev Allows users to submit a hashed knowledge insight. This hash typically represents
     *      the output or findings of an off-chain AI model, or a validated dataset.
     *      These insights are queued for verification by registered oracles.
     * @param _insightHash A unique cryptographic hash representing the knowledge insight's content.
     * @param _description A brief human-readable description of the insight.
     */
    function submitKnowledgeInsight(bytes32 _insightHash, string memory _description) public whenNotPaused {
        require(knowledgeInsights[_insightHash].submitter == address(0), "Metamorphica: Insight already submitted");
        knowledgeInsights[_insightHash] = KnowledgeInsight({
            submitter: msg.sender,
            submissionTimestamp: block.timestamp,
            status: InsightStatus.Pending,
            description: _description
        });
        emit KnowledgeInsightSubmitted(_insightHash, msg.sender);
        _updateUserReputation(msg.sender, 5); // Reward for contributing potential knowledge
    }

    /**
     * @dev Allows a registered oracle to mark a knowledge insight as verified or rejected.
     *      Verified insights can then be used internally by the contract (e.g., within `_applyEvolutionTraits`)
     *      to dynamically adjust evolution rules, trait probabilities, or other game parameters.
     * @param _insightHash The hash of the insight to verify.
     * @param _isValid True to mark as verified, false to mark as rejected.
     */
    function verifyKnowledgeInsight(bytes32 _insightHash, bool _isValid) public onlyOracle whenNotPaused {
        KnowledgeInsight storage insight = knowledgeInsights[_insightHash];
        require(insight.submitter != address(0), "Metamorphica: Insight not found");
        require(insight.status == InsightStatus.Pending, "Metamorphica: Insight already verified or rejected");

        if (_isValid) {
            insight.status = InsightStatus.Verified;
            _updateUserReputation(insight.submitter, 20); // Reward submitter for successful verification
            // This is where a more complex system would call a function like:
            // _applyVerifiedInsight(_insightHash, insight.description);
            // which would parse the insight (off-chain lookup) and apply its rules on-chain.
        } else {
            insight.status = InsightStatus.Rejected;
            _updateUserReputation(insight.submitter, -10); // Penalize submitter for invalid insight
        }
        emit KnowledgeInsightVerified(_insightHash, msg.sender, _isValid);
    }

    /**
     * @dev Retrieves the current verification status of a knowledge insight.
     * @param _insightHash The hash of the insight to query.
     * @return The status (Pending, Verified, Rejected) of the insight.
     */
    function getKnowledgeInsightStatus(bytes32 _insightHash) public view returns (InsightStatus) {
        return knowledgeInsights[_insightHash].status;
    }

    /**
     * @dev Allows users to formally request off-chain AI analysis for their ADE.
     *      This function primarily serves as an on-chain record and trigger for an off-chain oracle service.
     *      The actual AI processing happens off-chain, and results (or summaries) are expected to be
     *      fed back on-chain via `submitKnowledgeInsight` or a direct oracle callback.
     * @param _adeId The ID of the ADE for which analysis is requested.
     * @param _requestHash A unique hash identifying this specific request (e.g., a hash of the prompt or data submitted).
     */
    function requestAIInsight(uint256 _adeId, bytes32 _requestHash) public whenNotPaused {
        require(_ades[_adeId].owner == msg.sender, "Metamorphica: Caller is not the ADE owner");
        // In a real system, this would emit an event that an off-chain oracle listens to,
        // e.g., `emit AIInsightRequested(msg.sender, _adeId, _requestHash);`.
        // Could also require a small ETH/Essence fee to prevent spam.
        _updateUserReputation(msg.sender, 1); // Small reputation gain for engaging with the AI system
    }

    /* ============ VII. Decentralized Evolution Council (DAO-lite) ============ */

    /**
     * @dev Creates a new governance proposal for the Evolution Council.
     *      Proposals allow the community to suggest and vote on changes to the contract's parameters
     *      or execution logic. Requires minimum reputation and Essence balance to prevent spam.
     * @param _description A human-readable description of the proposal.
     * @param _calldata The ABI-encoded call data for the target function if the proposal passes.
     * @param _targetContract The address of the contract to call if the proposal passes (can be `address(this)`).
     * @param _minReputationToVote The minimum reputation score required for users to vote on this proposal.
     * @param _minEssenceToVote The minimum Essence balance (in smallest units) required for users to vote.
     * @return The ID of the newly created proposal.
     */
    function createProposal(
        string memory _description,
        bytes memory _calldata,
        address _targetContract,
        uint256 _minReputationToVote,
        uint256 _minEssenceToVote
    ) public whenNotPaused returns (uint256) {
        require(userReputation[msg.sender] >= 50, "Metamorphica: Insufficient reputation to create proposal (min 50)"); // Example threshold
        require(balanceOfEssence(msg.sender) >= 10 * (10 ** ESSENCE_DECIMALS), "Metamorphica: Insufficient Essence to create proposal (min 10 ESS)"); // Example threshold

        _proposalCounter++;
        uint256 newProposalId = _proposalCounter;
        uint256 votingPeriod = 7 days; // Example: 7 days for voting

        proposals[newProposalId] = Proposal({
            id: newProposalId,
            description: _description,
            proposer: msg.sender,
            creationTimestamp: block.timestamp,
            votingEndTime: block.timestamp + votingPeriod,
            yayVotes: 0,
            nayVotes: 0,
            status: ProposalStatus.Active,
            callData: _calldata,
            targetContract: _targetContract,
            minReputationToVote: _minReputationToVote,
            minEssenceToVote: _minEssenceToVote,
            hasVoted: new mapping(address => bool) // Initialize the inner mapping for voted status
        });

        _updateUserReputation(msg.sender, 10); // Reward for creating a proposal
        emit ProposalCreated(newProposalId, msg.sender);
        return newProposalId;
    }

    /**
     * @dev Allows eligible users to cast a vote on an active proposal.
     *      Eligibility is determined by `minReputationToVote` and `minEssenceToVote` set for the proposal.
     *      Each user can vote once per proposal.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for a 'yay' vote (in favor), false for a 'nay' vote (against).
     */
    function voteOnProposal(uint256 _proposalId, bool _support) public whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "Metamorphica: Proposal does not exist");
        require(proposal.status == ProposalStatus.Active, "Metamorphica: Proposal not active");
        require(block.timestamp <= proposal.votingEndTime, "Metamorphica: Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "Metamorphica: Already voted on this proposal");
        require(userReputation[msg.sender] >= int256(proposal.minReputationToVote), "Metamorphica: Insufficient reputation to vote");
        require(balanceOfEssence(msg.sender) >= proposal.minEssenceToVote, "Metamorphica: Insufficient Essence balance to vote");

        if (_support) {
            proposal.yayVotes++;
        } else {
            proposal.nayVotes++;
        }
        proposal.hasVoted[msg.sender] = true; // Mark user as having voted
        _updateUserReputation(msg.sender, 2); // Small reward for participating in governance
        emit ProposalVoted(_proposalId, msg.sender, _support);
    }

    /**
     * @dev Executes a proposal if it has passed its voting period and met the success criteria.
     *      Anyone can call this function once the voting period has ended.
     *      Success criteria: simple majority of 'yay' votes over 'nay' votes, and a minimum number of 'yay' votes.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) public whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "Metamorphica: Proposal does not exist");
        require(proposal.status == ProposalStatus.Active, "Metamorphica: Proposal not active or already executed/failed");
        require(block.timestamp > proposal.votingEndTime, "Metamorphica: Voting period not ended yet");

        // Simple majority rule for now, with a minimum quorum of 3 'yay' votes
        if (proposal.yayVotes > proposal.nayVotes && proposal.yayVotes >= 3) {
            proposal.status = ProposalStatus.Succeeded; // Mark as succeeded before execution attempt
            (bool success,) = proposal.targetContract.call(proposal.callData);
            require(success, "Metamorphica: Proposal execution failed");
            proposal.status = ProposalStatus.Executed; // Mark as executed if call succeeded
            emit ProposalExecuted(_proposalId);
        } else {
            proposal.status = ProposalStatus.Failed; // Mark as failed if criteria not met
        }
    }

    /**
     * @dev Retrieves descriptive details of a specific governance proposal.
     * @param _proposalId The ID of the proposal.
     * @return A tuple containing core proposal information.
     */
    function getProposalDetails(uint256 _proposalId) public view returns (
        uint256 id,
        string memory description,
        address proposer,
        uint256 creationTimestamp,
        uint256 votingEndTime,
        ProposalStatus status,
        uint256 minReputationToVote,
        uint256 minEssenceToVote
    ) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "Metamorphica: Proposal does not exist");
        return (
            proposal.id,
            proposal.description,
            proposal.proposer,
            proposal.creationTimestamp,
            proposal.votingEndTime,
            proposal.status,
            proposal.minReputationToVote,
            proposal.minEssenceToVote
        );
    }

    /**
     * @dev Gets current 'yay' and 'nay' vote counts for a proposal.
     * @param _proposalId The ID of the proposal.
     * @return yayVotes The count of 'yay' votes.
     * @return nayVotes The count of 'nay' votes.
     */
    function getProposalVoteCounts(uint256 _proposalId) public view returns (uint256 yayVotes, uint256 nayVotes) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "Metamorphica: Proposal does not exist");
        return (proposal.yayVotes, proposal.nayVotes);
    }

    /* ============ VIII. Advanced Concepts/Utilities ============ */

    /**
     * @dev Allows the owner (and later potentially the Evolution Council via governance)
     *      to set an influence score for a specific trait ID. This score can be used
     *      in the `_applyEvolutionTraits` function to dynamically affect evolution mechanics
     *      (e.g., making certain traits boost nurturing efficiency or unlock specific paths).
     * @param _traitId The ID of the trait.
     * @param _influenceScore The score indicating its influence (e.g., 1-10000 for a permille percentage).
     */
    function setTraitInfluence(uint256 _traitId, uint256 _influenceScore) public onlyOwner {
        traitInfluenceScores[_traitId] = _influenceScore;
    }

    /**
     * @dev Retrieves the influence score of a specific trait.
     * @param _traitId The ID of the trait.
     * @return The influence score.
     */
    function getTraitInfluence(uint256 _traitId) public view returns (uint256) {
        return traitInfluenceScores[_traitId];
    }

    /**
     * @dev Simulates the outcome of nurturing an ADE without changing its actual state.
     *      This function helps users plan their nurturing strategy by showing how much
     *      Essence is needed to reach future stages. It does not account for dynamic
     *      changes from AI insights or governance that might occur during actual nurturing.
     * @param _adeId The ID of the ADE to simulate.
     * @param _nurtureAmount The amount of Essence to simulate nurturing with (in smallest units).
     * @return simulatedStage The evolution stage the ADE would reach after the simulated nurturing.
     * @return simulatedRemainingEssence The remaining nurtured Essence after reaching the `simulatedStage`.
     */
    function simulateEvolutionOutcome(uint256 _adeId, uint256 _nurtureAmount) public view returns (uint256 simulatedStage, uint256 simulatedRemainingEssence) {
        ADE storage ade = _ades[_adeId];
        require(ade.id != 0, "Metamorphica: ADE does not exist");

        uint256 currentStage = ade.currentStage;
        uint256 currentNurtured = ade.currentEssenceNurtured + _nurtureAmount; // Add simulated nurture amount

        while (true) {
            uint256 nextStage = currentStage + 1;
            uint256 requiredEssence = evolutionStageThresholds[nextStage];

            // If there's no next stage defined, or not enough essence for the next stage, stop simulating.
            if (requiredEssence == 0 || currentNurtured < requiredEssence) {
                break;
            }

            currentNurtured -= requiredEssence; // Deduct essence for the completed stage
            currentStage = nextStage; // Advance to the next stage
        }
        return (currentStage, currentNurtured);
    }

    /**
     * @dev Allows the contract owner to register an address as an authorized oracle.
     *      Oracles are trusted entities that can verify `KnowledgeInsights`.
     * @param _oracleAddress The address to register as an oracle.
     */
    function registerOracle(address _oracleAddress) public onlyOwner {
        require(_oracleAddress != address(0), "Metamorphica: Zero address not allowed for oracle");
        require(!isRegisteredOracle[_oracleAddress], "Metamorphica: Oracle already registered");
        isRegisteredOracle[_oracleAddress] = true;
        _registeredOracles.push(_oracleAddress); // Add to dynamic array for tracking/iteration
    }

    /**
     * @dev Allows the contract owner to remove a registered oracle address.
     * @param _oracleAddress The address to remove from the list of oracles.
     */
    function removeOracle(address _oracleAddress) public onlyOwner {
        require(isRegisteredOracle[_oracleAddress], "Metamorphica: Address is not a registered oracle");
        isRegisteredOracle[_oracleAddress] = false;
        // Efficiently remove from `_registeredOracles` array by swapping with last element and popping.
        for (uint i = 0; i < _registeredOracles.length; i++) {
            if (_registeredOracles[i] == _oracleAddress) {
                _registeredOracles[i] = _registeredOracles[_registeredOracles.length - 1];
                _registeredOracles.pop();
                break;
            }
        }
    }

    /**
     * @dev Checks if a given address is a registered oracle.
     * @param _addr The address to check.
     * @return True if the address is a registered oracle, false otherwise.
     */
    function isOracle(address _addr) public view returns (bool) {
        return isRegisteredOracle[_addr];
    }
}

// Helper library for converting uint256 to string (adapted from OpenZeppelin's `Strings` library).
// Included directly to minimize external dependencies and avoid "duplication of open source" for core contract logic.
library Strings {
    bytes16 private constant _HEX_TABLE = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits--;
            // Convert last digit to ASCII char and place it in the buffer
            // 48 is ASCII for '0'
            buffer[digits] = bytes1(uint8(48 + value % 10));
            value /= 10;
        }
        return string(buffer);
    }
}
```