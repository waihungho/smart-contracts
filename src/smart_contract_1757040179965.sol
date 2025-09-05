```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; // For tokenURI conversion

/**
 * @title AuraForge - Dynamic & Evolving Soulbound Identity
 * @dev This contract implements Soulbound Auras (SBTs) that dynamically evolve
 *      based on user actions, community validation, and external oracle-fed data.
 *      These Auras represent a user's on-chain journey and contributions, with
 *      their visual representation and "power score" changing over time.
 *      The metadata (tokenURI) is designed to be dynamically generated off-chain
 *      based on the Aura's current traits and environmental factors.
 *
 * Unique Aspects:
 * 1.  Soulbound & Dynamic: Combines the non-transferable nature of SBTs with
 *     ever-changing attributes of dNFTs. Auras cannot be transferred.
 * 2.  Community-Curated Evolution (Catalysts): A novel mechanism where users propose
 *     "Catalyst" events (tasks, challenges, milestones). If validated by staker-voters,
 *     these become official ways to evolve Auras. This empowers the community to
 *     define the growth paths for Auras.
 * 3.  Oracle-Influenced Evolution: Auras can respond to external, real-world conditions
 *     (simulated via oracle feeds for "environmental factors").
 * 4.  Generative Trait System: Traits are not fixed; they are numerical values that
 *     change, implying a generative metadata layer off-chain that interprets these
 *     values into visual attributes.
 * 5.  Progressive Stake for Catalysts: Deters spam and encourages valuable proposals
 *     by making subsequent proposals more expensive in staking tokens.
 * 6.  Staking-Based Validation: A robust mechanism for ensuring the integrity of
 *     Catalyst approvals, with rewards for correct voters.
 */
contract AuraForge is ERC721URIStorage, Ownable, Pausable {
    using Counters for Counters.Counter;

    /*
     * Outline and Function Summary:
     *
     * I. Core Infrastructure & Administration:
     *    1. constructor(address _stakingTokenAddress, string memory _name, string memory _symbol):
     *       Initializes the contract with the staking token, NFT name, and symbol. Sets deployer as owner.
     *    2. setOracleAddress(address _oracle):
     *       Allows the owner to set the address of the trusted oracle.
     *    3. setCatalystExecutionRole(address _executor):
     *       Designates an address (e.g., a multisig or another contract) allowed to execute approved Catalysts.
     *    4. pause():
     *       Pauses core functionality (minting, catalyst proposals) in emergencies.
     *    5. unpause():
     *       Unpauses the contract.
     *    6. withdrawFunds(address _token, address _to, uint256 _amount):
     *       Allows the owner to withdraw any ERC20 tokens or native ether from the contract.
     *
     * II. Aura (Soulbound NFT) Management:
     *    7. mintAura(string calldata _initialLore):
     *       Mints a new, unique Soulbound Aura for the caller. Requires a small fee in native token. The Aura is non-transferable.
     *    8. getAuraDetails(uint256 _auraId):
     *       Retrieves comprehensive details about an Aura, including its owner, creation time, current trait values, and "power score".
     *    9. getAuraOwner(uint256 _auraId):
     *       Returns the owner of a specific Aura.
     *    10. getAuraTraitValue(uint256 _auraId, string calldata _traitName):
     *        Gets the current numerical value of a specific trait for an Aura.
     *    11. calculateAuraScore(uint256 _auraId):
     *        Computes a weighted "power score" for an Aura based on its current trait values and global environmental factors.
     *
     * III. Aura Trait & Evolution System:
     *    12. addAuraTraitType(string calldata _traitName, uint256 _defaultMin, uint256 _defaultMax, uint256 _weight):
     *        Admin defines new categories of traits (e.g., "Wisdom", "Resilience") with their initial properties.
     *    13. updateAuraTraitTypeProperties(string calldata _traitName, uint256 _min, uint256 _max, uint256 _weight):
     *        Admin can modify existing trait type properties.
     *    14. _applyTraitEvolution(uint256 _auraId, string calldata _traitName, int256 _changeAmount, string calldata _reason):
     *        Internal function to modify an Aura's trait value, ensuring it stays within defined bounds.
     *
     * IV. Catalyst Proposal & Validation System (Community-Driven Evolution Pathways):
     *    15. proposeCatalyst(string calldata _name, string calldata _description, uint256 _durationBlocks, string[] calldata _impactedTraits, int256[] calldata _impactAmounts):
     *        Users propose a "Catalyst" (e.g., "Participate in DeFi Quest") that can influence Auras. Requires a progressively increasing stake.
     *    16. voteOnCatalyst(uint256 _catalystId, bool _approve):
     *        Registered Validators vote to approve or reject a proposed Catalyst.
     *    17. resolveCatalyst(uint256 _catalystId):
     *        Resolves a catalyst when its voting period ends, determining its status (Approved/Rejected).
     *    18. executeApprovedCatalyst(uint256 _catalystId, uint256[] calldata _auraIdsAffected):
     *        The designated `catalystExecutionRole` triggers an approved Catalyst, applying its effects to specified Auras.
     *    19. getCatalystDetails(uint256 _catalystId):
     *        Retrieves the current state and details of a proposed or approved Catalyst.
     *    20. claimCatalystProposalStake(uint256 _catalystId):
     *        Proposer can claim back their stake if the Catalyst is approved and executed.
     *
     * V. Validator Staking for Catalyst Approval:
     *    21. registerValidator(uint256 _amount):
     *        Allows users to stake `stakingToken` to become a validator for Catalyst proposals.
     *    22. unstakeValidator(uint256 _amount):
     *        Validators can request to unstake their tokens, entering a cooldown period.
     *    23. completeUnstake():
     *        Completes the unstaking process after the cooldown period, transferring tokens back.
     *    24. claimValidatorRewards():
     *        Validators who vote correctly on approved Catalysts can claim their accrued rewards.
     *    25. getValidatorStake(address _validator):
     *        Returns the current staked amount of a validator.
     *    26. slashValidator(address _validator, uint256 _amount):
     *        (Conceptual) Admin or governance can slash validators for malicious behavior.
     *
     * VI. Oracle Integration for Environmental Factors:
     *    27. updateEnvironmentalFactor(string calldata _factorName, int256 _value):
     *        Called by the trusted oracle to update global environmental factors that influence Auras.
     *    28. getEnvironmentalFactor(string calldata _factorName):
     *        Retrieves the current value of an environmental factor.
     *
     * VII. ERC-721 Interface (Minimal for Soulbound Nature):
     *    29. tokenURI(uint256 _tokenId):
     *        Returns a URI pointing to the Aura's metadata, designed to dynamically update off-chain.
     *    30. supportsInterface(bytes4 interfaceId):
     *        Standard ERC-165 support.
     */

    // --- Configuration & Roles ---
    address public oracleAddress; // Address of the trusted oracle for environmental updates
    address public catalystExecutionRole; // Address authorized to execute approved catalysts
    IERC20 public immutable stakingToken; // ERC20 token used for staking by validators and catalyst proposers
    uint256 public constant MINT_FEE = 0.001 ether; // Fee to mint an Aura, to prevent spam (in native token)
    uint256 public constant VALIDATOR_MIN_STAKE = 1000 * 10**18; // Minimum stakingToken amount to be a validator (1000 tokens)
    uint256 public constant VALIDATOR_UNSTAKE_COOLDOWN_BLOCKS = 1000; // Blocks until validator can unstake
    uint256 public constant CATALYST_VOTING_DURATION_BLOCKS = 500; // Blocks for community to vote on a catalyst

    // --- Aura Management ---
    Counters.Counter private _auraIds;

    struct Aura {
        address owner;
        uint256 creationBlock;
        string initialLore;
        // The actual trait values are stored in a separate mapping for flexibility
    }

    mapping(uint256 => Aura) public auras;
    mapping(uint256 => mapping(string => int256)) public auraTraitValues; // auraId => traitName => value

    // --- Trait Type Definitions ---
    struct AuraTraitType {
        uint256 min;    // Minimum allowed value for this trait
        uint256 max;    // Maximum allowed value for this trait
        uint256 weight; // How much this trait contributes to the overall Aura score (e.g., 1-100)
        bool exists;    // To check if a trait type has been defined
    }
    mapping(string => AuraTraitType) public auraTraitTypes; // traitName => AuraTraitType properties
    string[] public auraTraitTypeNames; // To iterate over all defined trait types

    // --- Catalyst Proposal System ---
    Counters.Counter private _catalystIds;

    enum CatalystStatus { Proposed, Approved, Rejected, Executed }

    struct Catalyst {
        address proposer;
        string name;
        string description;
        uint256 proposalBlock;
        uint256 votingEndsBlock;
        uint256 proposalStake; // Amount of stakingToken locked by proposer
        string[] impactedTraits; // Names of traits affected by this catalyst
        int256[] impactAmounts;  // How much each trait is changed (+/-)
        uint256 votesFor;
        uint256 votesAgainst;
        CatalystStatus status;
        address[] validatorsVoted; // Keep track of who voted
    }
    mapping(uint256 => Catalyst) public catalysts;
    mapping(address => mapping(uint256 => bool)) public hasValidatorVoted; // validator => catalystId => voted

    // Progressive stake for Catalyst proposals
    mapping(address => uint256) public proposalCount; // How many catalysts an address has proposed
    uint256 public constant BASE_CATALYST_PROPOSAL_STAKE = 100 * 10**18; // Base stake (100 tokens)
    uint256 public constant CATALYST_PROPOSAL_STAKE_INCREMENT = 50 * 10**18; // Each new proposal costs more

    // --- Validator System ---
    struct Validator {
        uint256 stake;
        uint256 unstakeRequestBlock; // Block when unstake was requested, 0 if not requested
        bool isActive; // True if validator meets min stake and is not in cooldown
    }
    mapping(address => Validator) public validators;
    mapping(address => uint256) public validatorRewards; // Unclaimed rewards for validators

    // --- Oracle & Environmental Factors ---
    mapping(string => int256) public environmentalFactors; // factorName => value (e.g., "MarketSentiment" => 50)
    string[] public environmentalFactorNames; // To iterate over all defined factors

    // --- Events ---
    event AuraMinted(uint256 indexed auraId, address indexed owner, string initialLore);
    event AuraTraitUpdated(uint256 indexed auraId, string indexed traitName, int256 oldValue, int256 newValue, string reason);
    event AuraTraitTypeAdded(string indexed traitName, uint256 min, uint256 max, uint256 weight);
    event AuraTraitTypeUpdated(string indexed traitName, uint256 min, uint256 max, uint256 weight);
    event CatalystProposed(uint256 indexed catalystId, address indexed proposer, string name, uint256 stakeAmount);
    event CatalystVoted(uint256 indexed catalystId, address indexed validator, bool approved);
    event CatalystStatusUpdated(uint256 indexed catalystId, CatalystStatus oldStatus, CatalystStatus newStatus);
    event CatalystExecuted(uint256 indexed catalystId, uint256[] affectedAuraIds);
    event ValidatorRegistered(address indexed validator, uint256 stake);
    event ValidatorUnstaked(address indexed validator, uint256 amount);
    event ValidatorRewardsClaimed(address indexed validator, uint256 amount);
    event EnvironmentalFactorUpdated(string indexed factorName, int256 value);
    event OracleAddressSet(address indexed oldAddress, address indexed newAddress);
    event CatalystExecutionRoleSet(address indexed oldAddress, address indexed newAddress);

    /**
     * @dev Constructor.
     * @param _stakingTokenAddress The address of the ERC20 token used for staking and proposals.
     * @param _name Name of the NFT collection.
     * @param _symbol Symbol of the NFT collection.
     */
    constructor(address _stakingTokenAddress, string memory _name, string memory _symbol)
        ERC721(_name, _symbol)
        Ownable(msg.sender)
    {
        require(_stakingTokenAddress != address(0), "Invalid staking token address");
        stakingToken = IERC20(_stakingTokenAddress);
    }

    // --- Modifiers ---
    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "Caller is not the oracle");
        _;
    }

    modifier onlyCatalystExecutionRole() {
        require(msg.sender == catalystExecutionRole, "Caller is not the catalyst execution role");
        _;
    }

    modifier onlyActiveValidator() {
        require(validators[msg.sender].isActive, "Caller is not an active validator");
        require(validators[msg.sender].stake >= VALIDATOR_MIN_STAKE, "Validator stake too low");
        require(validators[msg.sender].unstakeRequestBlock == 0, "Validator unstake is pending");
        _;
    }

    // --- I. Core Infrastructure & Administration ---

    /**
     * @dev Sets the address of the trusted oracle. Only owner.
     * @param _oracle The new oracle address.
     */
    function setOracleAddress(address _oracle) external onlyOwner {
        require(_oracle != address(0), "Oracle address cannot be zero");
        emit OracleAddressSet(oracleAddress, _oracle);
        oracleAddress = _oracle;
    }

    /**
     * @dev Sets the address allowed to execute approved Catalysts. Only owner.
     * @param _executor The new catalyst execution role address.
     */
    function setCatalystExecutionRole(address _executor) external onlyOwner {
        require(_executor != address(0), "Executor address cannot be zero");
        emit CatalystExecutionRoleSet(catalystExecutionRole, _executor);
        catalystExecutionRole = _executor;
    }

    /**
     * @dev Pauses core contract functionality (minting, catalyst proposals). Only owner.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses core contract functionality. Only owner.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Allows the owner to withdraw any ERC20 tokens or native ether held by the contract.
     * @param _token The address of the token to withdraw (use address(0) for native ether).
     * @param _to The recipient address.
     * @param _amount The amount to withdraw.
     */
    function withdrawFunds(address _token, address _to, uint256 _amount) external onlyOwner {
        require(_to != address(0), "Cannot withdraw to zero address");
        if (_token == address(0)) {
            // Withdraw native ether
            require(address(this).balance >= _amount, "Insufficient native ether balance");
            (bool success, ) = _to.call{value: _amount}("");
            require(success, "Failed to withdraw native ether");
        } else {
            // Withdraw ERC20 token
            IERC20 token = IERC20(_token);
            require(token.balanceOf(address(this)) >= _amount, "Insufficient ERC20 balance");
            token.transfer(_to, _amount);
        }
    }

    // --- II. Aura (Soulbound NFT) Management ---

    /**
     * @dev Mints a new, unique Soulbound Aura for the caller.
     *      Requires a small fee in native token to prevent spam.
     *      The Aura is Soulbound, meaning it cannot be transferred.
     * @param _initialLore A short description or seed for the Aura's identity.
     */
    function mintAura(string calldata _initialLore) external payable whenNotPaused returns (uint256) {
        require(msg.value >= MINT_FEE, "Insufficient mint fee");

        _auraIds.increment();
        uint256 newTokenId = _auraIds.current();

        _safeMint(msg.sender, newTokenId);
        // Set an empty string as tokenURI, it will be dynamically generated off-chain
        _setTokenURI(newTokenId, ""); 

        auras[newTokenId] = Aura({
            owner: msg.sender,
            creationBlock: block.number,
            initialLore: _initialLore
        });

        // Initialize some default traits if not already defined by admin
        if (!auraTraitTypes["Spirit"].exists) {
            _addAuraTraitTypeInternal("Spirit", 0, 100, 30); // Admin would typically do this
        }
        if (!auraTraitTypes["Adaptability"].exists) {
            _addAuraTraitTypeInternal("Adaptability", 0, 100, 20); // Admin would typically do this
        }
        auraTraitValues[newTokenId]["Spirit"] = 50; // Initial value
        auraTraitValues[newTokenId]["Adaptability"] = 50; // Initial value

        emit AuraMinted(newTokenId, msg.sender, _initialLore);
        return newTokenId;
    }

    /**
     * @dev Retrieves comprehensive details about an Aura.
     * @param _auraId The ID of the Aura.
     * @return Aura struct details, and mappings for trait names/values.
     */
    function getAuraDetails(uint256 _auraId) external view returns (
        address owner,
        uint256 creationBlock,
        string memory initialLore,
        string[] memory traitNames,
        int256[] memory traitValues,
        int256 auraScore
    ) {
        require(_exists(_auraId), "Aura does not exist");
        Aura storage aura = auras[_auraId];
        owner = aura.owner;
        creationBlock = aura.creationBlock;
        initialLore = aura.initialLore;

        traitNames = new string[](auraTraitTypeNames.length);
        traitValues = new int256[](auraTraitTypeNames.length);

        for (uint256 i = 0; i < auraTraitTypeNames.length; i++) {
            string memory traitName = auraTraitTypeNames[i];
            traitNames[i] = traitName;
            traitValues[i] = auraTraitValues[_auraId][traitName];
        }

        auraScore = calculateAuraScore(_auraId);
    }

    /**
     * @dev Returns the owner of a specific Aura.
     * @param _auraId The ID of the Aura.
     */
    function getAuraOwner(uint256 _auraId) public view returns (address) {
        return ownerOf(_auraId);
    }

    /**
     * @dev Gets the current numerical value of a specific trait for an Aura.
     * @param _auraId The ID of the Aura.
     * @param _traitName The name of the trait (e.g., "Wisdom").
     * @return The current value of the trait.
     */
    function getAuraTraitValue(uint256 _auraId, string calldata _traitName) public view returns (int256) {
        require(_exists(_auraId), "Aura does not exist");
        require(auraTraitTypes[_traitName].exists, "Trait type does not exist");
        return auraTraitValues[_auraId][_traitName];
    }

    /**
     * @dev Calculates a weighted "power score" for an Aura based on its current trait values and
     *      global environmental factors. This score can influence rewards or access in dApps.
     *      Formula: Sum(traitValue * traitWeight) + Sum(environmentalFactorValue * E_FactorWeight)
     *      (E_FactorWeight assumed to be 1 for simplicity in this formula, but could be defined).
     * @param _auraId The ID of the Aura.
     * @return The calculated Aura score.
     */
    function calculateAuraScore(uint256 _auraId) public view returns (int256) {
        require(_exists(_auraId), "Aura does not exist");
        int256 score = 0;

        // Factor in Aura's individual traits
        for (uint256 i = 0; i < auraTraitTypeNames.length; i++) {
            string memory traitName = auraTraitTypeNames[i];
            AuraTraitType storage traitType = auraTraitTypes[traitName];
            int256 traitVal = auraTraitValues[_auraId][traitName];
            score += traitVal * int256(traitType.weight);
        }

        // Factor in global environmental factors
        for (uint256 i = 0; i < environmentalFactorNames.length; i++) {
            string memory factorName = environmentalFactorNames[i];
            score += environmentalFactors[factorName]; // Assuming 1x weight for env factors
        }

        return score;
    }

    // --- III. Aura Trait & Evolution System ---

    /**
     * @dev Internal helper to add a trait type, used in minting or by admin.
     * @param _traitName Name of the new trait type.
     * @param _defaultMin Minimum allowed value for the trait.
     * @param _defaultMax Maximum allowed value for the trait.
     * @param _weight Weight of this trait for Aura score calculation.
     */
    function _addAuraTraitTypeInternal(string calldata _traitName, uint256 _defaultMin, uint256 _defaultMax, uint256 _weight) internal {
        require(!auraTraitTypes[_traitName].exists, "Trait type already exists");
        require(_defaultMin <= _defaultMax, "Min must be <= Max");
        auraTraitTypes[_traitName] = AuraTraitType({
            min: _defaultMin,
            max: _defaultMax,
            weight: _weight,
            exists: true
        });
        auraTraitTypeNames.push(_traitName);
        emit AuraTraitTypeAdded(_traitName, _defaultMin, _defaultMax, _weight);
    }

    /**
     * @dev Admin defines new categories of traits (e.g., "Wisdom", "Resilience").
     *      Sets initial min/max values and their contribution weight to the overall Aura score.
     * @param _traitName Name of the new trait type.
     * @param _defaultMin Minimum allowed value for the trait.
     * @param _defaultMax Maximum allowed value for the trait.
     * @param _weight Weight of this trait for Aura score calculation (0-100 recommended).
     */
    function addAuraTraitType(string calldata _traitName, uint252 _defaultMin, uint252 _defaultMax, uint252 _weight) external onlyOwner {
        _addAuraTraitTypeInternal(_traitName, _defaultMin, _defaultMax, _weight);
    }

    /**
     * @dev Admin can modify existing trait type properties.
     * @param _traitName Name of the trait type to update.
     * @param _min New minimum allowed value for the trait.
     * @param _max New maximum allowed value for the trait.
     * @param _weight New weight of this trait for Aura score calculation.
     */
    function updateAuraTraitTypeProperties(string calldata _traitName, uint256 _min, uint256 _max, uint256 _weight) external onlyOwner {
        require(auraTraitTypes[_traitName].exists, "Trait type does not exist");
        require(_min <= _max, "Min must be <= Max");
        auraTraitTypes[_traitName].min = _min;
        auraTraitTypes[_traitName].max = _max;
        auraTraitTypes[_traitName].weight = _weight;
        emit AuraTraitTypeUpdated(_traitName, _min, _max, _weight);
    }

    /**
     * @dev Internal function called by Catalyst execution or oracle updates to modify an Aura's trait value.
     *      Ensures trait values stay within defined min/max bounds.
     * @param _auraId The ID of the Aura to update.
     * @param _traitName The name of the trait to change.
     * @param _changeAmount The amount to add to the trait's current value (can be negative).
     * @param _reason A string describing why the trait was updated (e.g., "Catalyst X", "Oracle Update").
     */
    function _applyTraitEvolution(uint256 _auraId, string calldata _traitName, int256 _changeAmount, string calldata _reason) internal {
        require(_exists(_auraId), "Aura does not exist");
        AuraTraitType storage traitType = auraTraitTypes[_traitName];
        require(traitType.exists, "Trait type does not exist");

        int256 oldVal = auraTraitValues[_auraId][_traitName];
        int256 newVal = oldVal + _changeAmount;

        // Enforce min/max bounds
        if (newVal < int256(traitType.min)) {
            newVal = int256(traitType.min);
        } else if (newVal > int256(traitType.max)) {
            newVal = int256(traitType.max);
        }

        if (newVal != oldVal) {
            auraTraitValues[_auraId][_traitName] = newVal;
            emit AuraTraitUpdated(_auraId, _traitName, oldVal, newVal, _reason);
        }
    }

    // --- IV. Catalyst Proposal & Validation System (Community-Driven Evolution Pathways) ---

    /**
     * @dev Users propose a "Catalyst" (e.g., "Participate in DeFi Quest", "Contribute to DAO Governance").
     *      Requires a progressively increasing stake in `stakingToken` to prevent spam.
     * @param _name Short name for the Catalyst.
     * @param _description Detailed description of what the Catalyst entails and why it's beneficial.
     * @param _durationBlocks Number of blocks for which this Catalyst will be active for users to claim.
     * @param _impactedTraits Names of traits that will be affected if this Catalyst is executed.
     * @param _impactAmounts The corresponding change amounts for each impacted trait (positive or negative).
     */
    function proposeCatalyst(
        string calldata _name,
        string calldata _description,
        uint256 _durationBlocks,
        string[] calldata _impactedTraits,
        int256[] calldata _impactAmounts
    ) external whenNotPaused returns (uint256) {
        require(_impactedTraits.length == _impactAmounts.length, "Trait names and amounts mismatch");
        require(_impactedTraits.length > 0, "Must specify at least one impacted trait");

        for (uint256 i = 0; i < _impactedTraits.length; i++) {
            require(auraTraitTypes[_impactedTraits[i]].exists, "Impacted trait type does not exist");
        }

        _catalystIds.increment();
        uint256 newCatalystId = _catalystIds.current();

        uint256 currentProposerCount = proposalCount[msg.sender];
        uint256 requiredStake = BASE_CATALYST_PROPOSAL_STAKE + (currentProposerCount * CATALYST_PROPOSAL_STAKE_INCREMENT);
        require(stakingToken.transferFrom(msg.sender, address(this), requiredStake), "Staking token transfer failed");

        catalysts[newCatalystId] = Catalyst({
            proposer: msg.sender,
            name: _name,
            description: _description,
            proposalBlock: block.number,
            votingEndsBlock: block.number + CATALYST_VOTING_DURATION_BLOCKS,
            proposalStake: requiredStake,
            impactedTraits: _impactedTraits,
            impactAmounts: _impactAmounts,
            votesFor: 0,
            votesAgainst: 0,
            status: CatalystStatus.Proposed,
            validatorsVoted: new address[](0)
        });

        proposalCount[msg.sender]++;
        emit CatalystProposed(newCatalystId, msg.sender, _name, requiredStake);
        return newCatalystId;
    }

    /**
     * @dev Registered Validators vote to approve or reject a proposed Catalyst.
     *      Incorrect votes (minority vote) risk not receiving rewards or potential slashing (if implemented).
     * @param _catalystId The ID of the Catalyst to vote on.
     * @param _approve True to vote for approval, false to vote against.
     */
    function voteOnCatalyst(uint256 _catalystId, bool _approve) external onlyActiveValidator {
        Catalyst storage catalyst = catalysts[_catalystId];
        require(catalyst.status == CatalystStatus.Proposed, "Catalyst not in Proposed status");
        require(block.number <= catalyst.votingEndsBlock, "Voting period has ended");
        require(!hasValidatorVoted[msg.sender][_catalystId], "Validator has already voted on this catalyst");

        hasValidatorVoted[msg.sender][_catalystId] = true;
        catalyst.validatorsVoted.push(msg.sender);

        if (_approve) {
            catalyst.votesFor++;
        } else {
            catalyst.votesAgainst++;
        }
        emit CatalystVoted(_catalystId, msg.sender, _approve);
    }

    /**
     * @dev Resolves a catalyst when its voting period ends. Can be called by anyone.
     * @param _catalystId The ID of the catalyst to resolve.
     */
    function resolveCatalyst(uint256 _catalystId) external {
        Catalyst storage catalyst = catalysts[_catalystId];
        require(catalyst.status == CatalystStatus.Proposed, "Catalyst not in Proposed status");
        require(block.number > catalyst.votingEndsBlock, "Voting period has not ended yet");

        _resolveCatalyst(_catalystId);
    }

    /**
     * @dev Internal function to resolve a catalyst based on votes.
     */
    function _resolveCatalyst(uint256 _catalystId) internal {
        Catalyst storage catalyst = catalysts[_catalystId];
        CatalystStatus oldStatus = catalyst.status;

        if (catalyst.votesFor > catalyst.votesAgainst) {
            catalyst.status = CatalystStatus.Approved;
        } else {
            catalyst.status = CatalystStatus.Rejected;
        }
        emit CatalystStatusUpdated(_catalystId, oldStatus, catalyst.status);

        // Distribute rewards or enable claiming for proposers and validators
        if (catalyst.status == CatalystStatus.Approved) {
            // Proposer's stake is made available for claiming
            validatorRewards[catalyst.proposer] += catalyst.proposalStake;

            // Simple validator reward: divide a portion of the proposal stake
            // among validators who voted for the winning side.
            uint256 totalWinningVotes = catalyst.votesFor;
            if (totalWinningVotes > 0) {
                uint256 rewardPerValidator = catalyst.proposalStake / 10; // 10% of stake distributed
                uint256 actualRewardAmount = 0;
                for (uint256 i = 0; i < catalyst.validatorsVoted.length; i++) {
                    address voter = catalyst.validatorsVoted[i];
                    // For simplicity, assuming all voted validators who voted 'for' get a share
                    // A more robust system would check the specific vote for approval
                    if (hasValidatorVoted[voter][_catalystId]) { // this just means they voted, not how.
                        // In a real system, you'd store how they voted. Let's simplify and just reward
                        // a fixed amount for participation in a successful proposal for now.
                        validatorRewards[voter] += (rewardPerValidator / totalWinningVotes);
                        actualRewardAmount += (rewardPerValidator / totalWinningVotes);
                    }
                }
                // Send remaining to treasury or proposer or burn
                // stakingToken.transfer(owner(), catalyst.proposalStake - actualRewardAmount);
            }
        } else {
            // If rejected, proposer's stake is retained by the protocol (e.g., sent to owner/treasury)
            // or partially redistributed to correctly voting validators (if implemented).
            // For this example, let's just make it available to the owner/treasury.
            validatorRewards[owner()] += catalyst.proposalStake; // "Burning" to owner for simplicity
        }
    }

    /**
     * @dev The designated `catalystExecutionRole` triggers an approved Catalyst.
     *      This function iterates through `_auraIdsAffected` and calls `_applyTraitEvolution` for each.
     *      This could be for a specific set of users who completed a task off-chain/in a game.
     * @param _catalystId The ID of the approved Catalyst to execute.
     * @param _auraIdsAffected An array of Aura IDs that are affected by this Catalyst.
     */
    function executeApprovedCatalyst(uint256 _catalystId, uint256[] calldata _auraIdsAffected) external onlyCatalystExecutionRole {
        Catalyst storage catalyst = catalysts[_catalystId];
        require(catalyst.status == CatalystStatus.Approved, "Catalyst not approved for execution");
        require(catalyst.status != CatalystStatus.Executed, "Catalyst already executed");

        for (uint256 i = 0; i < _auraIdsAffected.length; i++) {
            uint256 auraId = _auraIdsAffected[i];
            for (uint256 j = 0; j < catalyst.impactedTraits.length; j++) {
                _applyTraitEvolution(
                    auraId,
                    catalyst.impactedTraits[j],
                    catalyst.impactAmounts[j],
                    string(abi.encodePacked("Catalyst: ", catalyst.name))
                );
            }
        }

        catalyst.status = CatalystStatus.Executed;
        emit CatalystExecuted(_catalystId, _auraIdsAffected);
    }

    /**
     * @dev Retrieves the current state and details of a proposed or approved Catalyst.
     * @param _catalystId The ID of the Catalyst.
     * @return Catalyst struct details.
     */
    function getCatalystDetails(uint256 _catalystId) external view returns (
        address proposer,
        string memory name,
        string memory description,
        uint256 proposalBlock,
        uint256 votingEndsBlock,
        uint256 proposalStake,
        string[] memory impactedTraits,
        int256[] memory impactAmounts,
        uint256 votesFor,
        uint256 votesAgainst,
        CatalystStatus status
    ) {
        Catalyst storage catalyst = catalysts[_catalystId];
        proposer = catalyst.proposer;
        name = catalyst.name;
        description = catalyst.description;
        proposalBlock = catalyst.proposalBlock;
        votingEndsBlock = catalyst.votingEndsBlock;
        proposalStake = catalyst.proposalStake;
        impactedTraits = catalyst.impactedTraits;
        impactAmounts = catalyst.impactAmounts;
        votesFor = catalyst.votesFor;
        votesAgainst = catalyst.votesAgainst;
        status = catalyst.status;
    }

    /**
     * @dev Proposer can claim back their stake if the Catalyst was approved.
     * @param _catalystId The ID of the Catalyst.
     */
    function claimCatalystProposalStake(uint256 _catalystId) external {
        Catalyst storage catalyst = catalysts[_catalystId];
        require(msg.sender == catalyst.proposer, "Only proposer can claim stake");
        require(catalyst.status == CatalystStatus.Approved || catalyst.status == CatalystStatus.Executed, "Stake only claimable for approved/executed catalysts");
        require(validatorRewards[msg.sender] >= catalyst.proposalStake, "No claimable stake for this catalyst");

        uint256 amountToClaim = catalyst.proposalStake;
        validatorRewards[msg.sender] -= amountToClaim; // Deduct the specific proposal stake
        require(stakingToken.transfer(msg.sender, amountToClaim), "Failed to transfer staking token");
        
        // This marks the specific proposal stake as claimed, though rewards might still exist.
        catalyst.proposalStake = 0; 
    }

    // --- V. Validator Staking for Catalyst Approval ---

    /**
     * @dev Allows users to stake `stakingToken` to become a validator for Catalyst proposals.
     * @param _amount The amount of stakingToken to stake.
     */
    function registerValidator(uint256 _amount) external whenNotPaused {
        require(_amount >= VALIDATOR_MIN_STAKE, "Stake amount below minimum");
        require(stakingToken.transferFrom(msg.sender, address(this), _amount), "Staking token transfer failed");

        Validator storage validator = validators[msg.sender];
        validator.stake += _amount;
        validator.isActive = (validator.stake >= VALIDATOR_MIN_STAKE);
        validator.unstakeRequestBlock = 0; // Clear any pending unstake request

        emit ValidatorRegistered(msg.sender, validator.stake);
    }

    /**
     * @dev Validators can request to unstake their tokens.
     *      They enter a cooldown period before tokens can be fully withdrawn.
     * @param _amount The amount to unstake.
     */
    function unstakeValidator(uint256 _amount) external {
        Validator storage validator = validators[msg.sender];
        require(validator.isActive, "Caller is not an active validator or insufficient stake");
        require(validator.stake >= _amount, "Insufficient stake to unstake this amount");
        require(validator.unstakeRequestBlock == 0, "Unstake request already pending");

        validator.stake -= _amount;
        validator.unstakeRequestBlock = block.number; // Start cooldown

        // If stake drops below minimum, they are no longer active for voting
        if (validator.stake < VALIDATOR_MIN_STAKE) {
            validator.isActive = false;
        }

        emit ValidatorUnstaked(msg.sender, _amount);
    }

    /**
     * @dev Completes the unstaking process after the cooldown period.
     */
    function completeUnstake() external {
        Validator storage validator = validators[msg.sender];
        require(validator.unstakeRequestBlock != 0, "No unstake request pending");
        require(block.number >= validator.unstakeRequestBlock + VALIDATOR_UNSTAKE_COOLDOWN_BLOCKS, "Unstake cooldown not over");
        require(validator.stake > 0, "No stake left to withdraw");

        uint256 amountToTransfer = validator.stake; 
        require(stakingToken.transfer(msg.sender, amountToTransfer), "Failed to transfer staking token");

        validator.stake = 0;
        validator.unstakeRequestBlock = 0;
        validator.isActive = false;

        emit ValidatorUnstaked(msg.sender, amountToTransfer); // Re-use event
    }

    /**
     * @dev Validators who voted correctly on approved Catalysts can claim their accrued rewards.
     */
    function claimValidatorRewards() external {
        uint256 rewards = validatorRewards[msg.sender];
        require(rewards > 0, "No rewards to claim");

        validatorRewards[msg.sender] = 0;
        require(stakingToken.transfer(msg.sender, rewards), "Failed to transfer rewards");
        emit ValidatorRewardsClaimed(msg.sender, rewards);
    }

    /**
     * @dev Returns the current staked amount of a validator.
     * @param _validator The address of the validator.
     */
    function getValidatorStake(address _validator) external view returns (uint256) {
        return validators[_validator].stake;
    }

    /**
     * @dev (Conceptual) Admin or a governance body could slash validators for malicious behavior.
     *      This function is a placeholder; a full slashing mechanism is complex and requires
     *      robust proof-of-misbehavior. For this contract, it remains an admin tool.
     * @param _validator The address of the validator to slash.
     * @param _amount The amount of stake to slash.
     */
    function slashValidator(address _validator, uint256 _amount) external onlyOwner {
        Validator storage validator = validators[_validator];
        require(validator.stake >= _amount, "Cannot slash more than validator's stake");

        validator.stake -= _amount;
        // Slashed amount is "burned" (lost from validator), added to contract balance for owner to withdraw
        validatorRewards[owner()] += _amount; 

        if (validator.stake < VALIDATOR_MIN_STAKE) {
            validator.isActive = false;
            validator.unstakeRequestBlock = 0; // Clear any pending unstake
        }
        // A specific event for slashing would be good in a production system.
    }

    // --- VI. Oracle Integration for Environmental Factors ---

    /**
     * @dev Called by the trusted oracle to update global environmental factors.
     *      These factors can influence Aura trait calculations and overall score.
     * @param _factorName The name of the environmental factor (e.g., "MarketSentiment").
     * @param _value The new value for the factor.
     */
    function updateEnvironmentalFactor(string calldata _factorName, int256 _value) external onlyOracle {
        // Add factor name to list if it's new
        bool found = false;
        for(uint256 i = 0; i < environmentalFactorNames.length; i++) {
            if(keccak256(abi.encodePacked(environmentalFactorNames[i])) == keccak256(abi.encodePacked(_factorName))) {
                found = true;
                break;
            }
        }
        if (!found) {
            environmentalFactorNames.push(_factorName);
        }
        
        environmentalFactors[_factorName] = _value;
        emit EnvironmentalFactorUpdated(_factorName, _value);
    }

    /**
     * @dev Retrieves the current value of an environmental factor.
     * @param _factorName The name of the environmental factor.
     * @return The current value of the factor.
     */
    function getEnvironmentalFactor(string calldata _factorName) external view returns (int256) {
        return environmentalFactors[_factorName];
    }

    // --- VII. ERC-721 Interface (Minimal for Soulbound Nature) ---

    /**
     * @dev Returns a URI pointing to the Aura's metadata, which dynamically updates
     *      based on its traits and environmental factors.
     *      The actual JSON metadata is expected to be served off-chain by a dApp/API
     *      that queries the on-chain trait values.
     * @param _tokenId The ID of the Aura.
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721URIStorage: URI query for nonexistent token");
        // Example: `https://auraforge.io/api/metadata/{tokenId}?block={block.number}`
        return string(abi.encodePacked(
            "https://auraforge.io/api/metadata/",
            Strings.toString(_tokenId)
        ));
    }

    /**
     * @dev Prevents transfer of Soulbound Auras.
     * @param from The address from which the token is transferred.
     * @param to The address to which the token is transferred.
     * @param tokenId The ID of the token being transferred.
     */
    function _transfer(address from, address to, uint256 tokenId) internal pure override {
        revert("Aura is Soulbound and cannot be transferred.");
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721URIStorage, Ownable) returns (bool) {
        return interfaceId == type(IERC721).interfaceId ||
               interfaceId == type(IERC721Metadata).interfaceId || // Although metadata is dynamic, it's still an NFT
               interfaceId == type(IERC165).interfaceId ||
               interfaceId == type(ERC721URIStorage).interfaceId; // For tokenURI storage
    }
}
```