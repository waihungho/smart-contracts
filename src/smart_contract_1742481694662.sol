```solidity
pragma solidity ^0.8.0;

/**
 * @title Decentralized Reputation and Influence Oracle
 * @author Gemini AI
 * @dev A smart contract implementing a sophisticated reputation and influence system.
 * It allows for decentralized identity, reputation score tracking based on various on-chain and potentially off-chain verifiable actions,
 * and influence calculation within a defined community or platform. This contract aims to be highly flexible and extensible,
 * offering a wide range of functionalities for reputation management in decentralized applications.
 *
 * Function Outline and Summary:
 *
 * 1.  `initializeContract(string _contractName, string _version)`: Initializes the contract with a name and version. Only callable once by the deployer.
 * 2.  `registerIdentity(address _identityAddress, string _identityName, string _metadataURI)`: Registers a new identity with a name and metadata URI.
 * 3.  `updateIdentityMetadata(address _identityAddress, string _newMetadataURI)`: Allows an identity owner to update their metadata URI.
 * 4.  `getIdentityMetadata(address _identityAddress)`: Retrieves the metadata URI associated with an identity.
 * 5.  `recordAction(address _identityAddress, bytes32 _actionType, uint256 _actionValue, bytes _actionData)`: Records an action performed by an identity, contributing to their reputation.
 * 6.  `getActionCount(address _identityAddress, bytes32 _actionType)`: Retrieves the count of a specific action type performed by an identity.
 * 7.  `getActionSum(address _identityAddress, bytes32 _actionType)`: Retrieves the sum of values for a specific action type performed by an identity.
 * 8.  `calculateReputationScore(address _identityAddress)`: Calculates a dynamic reputation score for an identity based on accumulated actions and a configurable scoring system.
 * 9.  `defineReputationActionType(bytes32 _actionType, string _actionDescription, uint256 _baseReputationPoints, bool _isCumulative)`: Defines a new action type for reputation tracking, including its description and base reputation points.
 * 10. `getActionTypeDetails(bytes32 _actionType)`: Retrieves details about a specific action type, including its description and base reputation points.
 * 11. `endorseIdentity(address _endorserIdentity, address _endorsedIdentity, string _endorsementReason)`: Allows one identity to endorse another, potentially impacting reputation (configurable weight).
 * 12. `getEndorsementsCount(address _identityAddress)`: Retrieves the number of endorsements received by an identity.
 * 13. `setReputationWeight(bytes32 _actionType, uint256 _weight)`: Allows the contract owner to adjust the reputation weight for a specific action type.
 * 14. `getReputationWeight(bytes32 _actionType)`: Retrieves the reputation weight for a specific action type.
 * 15. `setEndorsementWeight(uint256 _weight)`: Allows the contract owner to adjust the reputation weight for endorsements.
 * 16. `getEndorsementWeight()`: Retrieves the current endorsement weight.
 * 17. `setInfluenceThreshold(uint256 _threshold)`: Sets a reputation threshold to be considered "influential."
 * 18. `getInfluenceThreshold()`: Retrieves the current influence threshold.
 * 19. `isInfluential(address _identityAddress)`: Checks if an identity's reputation score is above the influence threshold.
 * 20. `transferOwnership(address _newOwner)`: Allows the contract owner to transfer ownership to a new address.
 * 21. `getContractName()`: Returns the name of the contract.
 * 22. `getContractVersion()`: Returns the version of the contract.
 * 23. `pauseContract()`: Pauses the contract, preventing most state-changing operations. Only callable by the owner.
 * 24. `unpauseContract()`: Unpauses the contract, restoring normal functionality. Only callable by the owner.
 * 25. `isContractPaused()`: Checks if the contract is currently paused.
 */

contract AdvancedReputationSystem {
    // --- State Variables ---
    string public contractName;
    string public contractVersion;
    address public owner;
    bool public paused;

    mapping(address => string) public identityMetadata; // Metadata URI for each identity
    mapping(address => string) public identityNames; // Name for each identity
    mapping(address => mapping(bytes32 => uint256)) public actionCounts; // Count of each action type per identity
    mapping(address => mapping(bytes32 => uint256)) public actionSums;   // Sum of action values for each action type per identity
    mapping(bytes32 => ActionTypeDetails) public actionTypeDetails; // Details for each action type
    mapping(address => uint256) public endorsementCounts; // Count of endorsements received by each identity
    mapping(bytes32 => uint256) public reputationWeights; // Weight for each action type in reputation calculation
    uint256 public endorsementWeight = 10; // Default endorsement weight
    uint256 public influenceThreshold = 1000; // Default influence threshold

    struct ActionTypeDetails {
        string description;
        uint256 baseReputationPoints;
        bool isCumulative; // Whether actions of this type contribute cumulatively
    }

    // --- Events ---
    event ContractInitialized(string contractName, string contractVersion, address owner);
    event IdentityRegistered(address identityAddress, string identityName, string metadataURI);
    event IdentityMetadataUpdated(address identityAddress, string newMetadataURI);
    event ActionRecorded(address identityAddress, bytes32 actionType, uint256 actionValue, bytes actionData);
    event ReputationActionTypeDefined(bytes32 actionType, string description, uint256 baseReputationPoints, bool isCumulative);
    event IdentityEndorsed(address endorserIdentity, address endorsedIdentity, string reason);
    event ReputationWeightUpdated(bytes32 actionType, uint256 newWeight);
    event EndorsementWeightUpdated(uint256 newWeight);
    event InfluenceThresholdUpdated(uint256 newThreshold);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event ContractPaused(address owner);
    event ContractUnpaused(address owner);

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused.");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused.");
        _;
    }

    // --- Constructor ---
    constructor() {
        owner = msg.sender;
        paused = false; // Contract starts unpaused
    }

    // --- Initialization Function ---
    function initializeContract(string memory _contractName, string memory _version) public onlyOwner {
        require(bytes(contractName).length == 0, "Contract already initialized.");
        contractName = _contractName;
        contractVersion = _version;
        emit ContractInitialized(_contractName, _version, owner);
    }

    // --- Identity Management Functions ---
    function registerIdentity(address _identityAddress, string memory _identityName, string memory _metadataURI) public whenNotPaused {
        require(bytes(identityNames[_identityAddress]).length == 0, "Identity already registered.");
        identityNames[_identityAddress] = _identityName;
        identityMetadata[_identityAddress] = _metadataURI;
        emit IdentityRegistered(_identityAddress, _identityName, _metadataURI);
    }

    function updateIdentityMetadata(address _identityAddress, string memory _newMetadataURI) public whenNotPaused {
        require(msg.sender == _identityAddress, "Only identity owner can update metadata.");
        identityMetadata[_identityAddress] = _newMetadataURI;
        emit IdentityMetadataUpdated(_identityAddress, _newMetadataURI);
    }

    function getIdentityMetadata(address _identityAddress) public view returns (string memory) {
        return identityMetadata[_identityAddress];
    }

    // --- Action Recording and Tracking Functions ---
    function recordAction(address _identityAddress, bytes32 _actionType, uint256 _actionValue, bytes memory _actionData) public whenNotPaused {
        actionCounts[_identityAddress][_actionType]++;
        actionSums[_identityAddress][_actionType] += _actionValue;
        emit ActionRecorded(_identityAddress, _actionType, _actionValue, _actionData);
    }

    function getActionCount(address _identityAddress, bytes32 _actionType) public view returns (uint256) {
        return actionCounts[_identityAddress][_actionType];
    }

    function getActionSum(address _identityAddress, bytes32 _actionType) public view returns (uint256) {
        return actionSums[_identityAddress][_actionType];
    }

    // --- Reputation Scoring Function ---
    function calculateReputationScore(address _identityAddress) public view returns (uint256) {
        uint256 reputationScore = 0;
        for (uint256 i = 0; i < 256; i++) { // Iterate through possible bytes32 values (inefficient, but illustrative for concept)
            bytes32 actionType = bytes32(uint256(i)); // In a real application, manage a list of action types
            if (actionTypeDetails[actionType].baseReputationPoints > 0) { // Check if action type is defined
                uint256 weight = reputationWeights[actionType] > 0 ? reputationWeights[actionType] : 1; // Default weight 1 if not set
                if (actionTypeDetails[actionType].isCumulative) {
                    reputationScore += actionSums[_identityAddress][actionType] * weight;
                } else {
                    reputationScore += actionCounts[_identityAddress][actionType] * actionTypeDetails[actionType].baseReputationPoints * weight;
                }
            }
        }
        reputationScore += endorsementCounts[_identityAddress] * endorsementWeight; // Add endorsement score
        return reputationScore;
    }

    // --- Reputation Action Type Definition Functions ---
    function defineReputationActionType(
        bytes32 _actionType,
        string memory _actionDescription,
        uint256 _baseReputationPoints,
        bool _isCumulative
    ) public onlyOwner whenNotPaused {
        require(actionTypeDetails[_actionType].baseReputationPoints == 0, "Action type already defined.");
        actionTypeDetails[_actionType] = ActionTypeDetails({
            description: _actionDescription,
            baseReputationPoints: _baseReputationPoints,
            isCumulative: _isCumulative
        });
        reputationWeights[_actionType] = 1; // Default weight to 1 upon definition
        emit ReputationActionTypeDefined(_actionType, _actionDescription, _baseReputationPoints, _isCumulative);
    }

    function getActionTypeDetails(bytes32 _actionType) public view returns (ActionTypeDetails memory) {
        return actionTypeDetails[_actionType];
    }

    // --- Endorsement Functions ---
    function endorseIdentity(address _endorserIdentity, address _endorsedIdentity, string memory _endorsementReason) public whenNotPaused {
        require(_endorserIdentity != _endorsedIdentity, "Cannot endorse self.");
        endorsementCounts[_endorsedIdentity]++;
        emit IdentityEndorsed(_endorserIdentity, _endorsedIdentity, _endorsementReason);
    }

    function getEndorsementsCount(address _identityAddress) public view returns (uint256) {
        return endorsementCounts[_identityAddress];
    }

    // --- Reputation Weight Management Functions ---
    function setReputationWeight(bytes32 _actionType, uint256 _weight) public onlyOwner whenNotPaused {
        reputationWeights[_actionType] = _weight;
        emit ReputationWeightUpdated(_actionType, _weight);
    }

    function getReputationWeight(bytes32 _actionType) public view returns (uint256) {
        return reputationWeights[_actionType];
    }

    function setEndorsementWeight(uint256 _weight) public onlyOwner whenNotPaused {
        endorsementWeight = _weight;
        emit EndorsementWeightUpdated(_weight);
    }

    function getEndorsementWeight() public view returns (uint256) {
        return endorsementWeight;
    }

    // --- Influence Threshold Functions ---
    function setInfluenceThreshold(uint256 _threshold) public onlyOwner whenNotPaused {
        influenceThreshold = _threshold;
        emit InfluenceThresholdUpdated(_threshold);
    }

    function getInfluenceThreshold() public view returns (uint256) {
        return influenceThreshold;
    }

    function isInfluential(address _identityAddress) public view returns (bool) {
        return calculateReputationScore(_identityAddress) >= influenceThreshold;
    }

    // --- Ownership Functions ---
    function transferOwnership(address _newOwner) public onlyOwner whenNotPaused {
        require(_newOwner != address(0), "New owner cannot be the zero address.");
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }

    // --- Contract Info Functions ---
    function getContractName() public view returns (string memory) {
        return contractName;
    }

    function getContractVersion() public view returns (string memory) {
        return contractVersion;
    }

    // --- Pause/Unpause Functionality ---
    function pauseContract() public onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused(owner);
    }

    function unpauseContract() public onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused(owner);
    }

    function isContractPaused() public view returns (bool) {
        return paused;
    }
}
```

**Outline and Function Summary:**

```
/**
 * @title Decentralized Reputation and Influence Oracle
 * @author Gemini AI
 * @dev A smart contract implementing a sophisticated reputation and influence system.
 * It allows for decentralized identity, reputation score tracking based on various on-chain and potentially off-chain verifiable actions,
 * and influence calculation within a defined community or platform. This contract aims to be highly flexible and extensible,
 * offering a wide range of functionalities for reputation management in decentralized applications.
 *
 * Function Outline and Summary:
 *
 * 1.  `initializeContract(string _contractName, string _version)`: Initializes the contract with a name and version. Only callable once by the deployer.
 * 2.  `registerIdentity(address _identityAddress, string _identityName, string _metadataURI)`: Registers a new identity with a name and metadata URI.
 * 3.  `updateIdentityMetadata(address _identityAddress, string _newMetadataURI)`: Allows an identity owner to update their metadata URI.
 * 4.  `getIdentityMetadata(address _identityAddress)`: Retrieves the metadata URI associated with an identity.
 * 5.  `recordAction(address _identityAddress, bytes32 _actionType, uint256 _actionValue, bytes _actionData)`: Records an action performed by an identity, contributing to their reputation.
 * 6.  `getActionCount(address _identityAddress, bytes32 _actionType)`: Retrieves the count of a specific action type performed by an identity.
 * 7.  `getActionSum(address _identityAddress, bytes32 _actionType)`: Retrieves the sum of values for a specific action type performed by an identity.
 * 8.  `calculateReputationScore(address _identityAddress)`: Calculates a dynamic reputation score for an identity based on accumulated actions and a configurable scoring system.
 * 9.  `defineReputationActionType(bytes32 _actionType, string _actionDescription, uint256 _baseReputationPoints, bool _isCumulative)`: Defines a new action type for reputation tracking, including its description and base reputation points.
 * 10. `getActionTypeDetails(bytes32 _actionType)`: Retrieves details about a specific action type, including its description and base reputation points.
 * 11. `endorseIdentity(address _endorserIdentity, address _endorsedIdentity, string _endorsementReason)`: Allows one identity to endorse another, potentially impacting reputation (configurable weight).
 * 12. `getEndorsementsCount(address _identityAddress)`: Retrieves the number of endorsements received by an identity.
 * 13. `setReputationWeight(bytes32 _actionType, uint256 _weight)`: Allows the contract owner to adjust the reputation weight for a specific action type.
 * 14. `getReputationWeight(bytes32 _actionType)`: Retrieves the reputation weight for a specific action type.
 * 15. `setEndorsementWeight(uint256 _weight)`: Allows the contract owner to adjust the reputation weight for endorsements.
 * 16. `getEndorsementWeight()`: Retrieves the current endorsement weight.
 * 17. `setInfluenceThreshold(uint256 _threshold)`: Sets a reputation threshold to be considered "influential."
 * 18. `getInfluenceThreshold()`: Retrieves the current influence threshold.
 * 19. `isInfluential(address _identityAddress)`: Checks if an identity's reputation score is above the influence threshold.
 * 20. `transferOwnership(address _newOwner)`: Allows the contract owner to transfer ownership to a new address.
 * 21. `getContractName()`: Returns the name of the contract.
 * 22. `getContractVersion()`: Returns the version of the contract.
 * 23. `pauseContract()`: Pauses the contract, preventing most state-changing operations. Only callable by the owner.
 * 24. `unpauseContract()`: Unpauses the contract, restoring normal functionality. Only callable by the owner.
 * 25. `isContractPaused()`: Checks if the contract is currently paused.
 */
```

**Explanation of Concepts and Functionality:**

This smart contract implements a **Decentralized Reputation and Influence Oracle**. Here's a breakdown of its key features and why they are advanced and creative:

1.  **Decentralized Identity Registration:** Users can register their Ethereum addresses as identities within the system, associating a name and metadata URI (e.g., IPFS link to a profile). This lays the foundation for on-chain reputation linked to specific addresses, acting as decentralized identifiers within the context of this contract.

2.  **Action-Based Reputation System:**  The core of the contract is its ability to track and reward various actions performed by identities.
    *   **`recordAction()`**: This is a highly flexible function. It allows recording arbitrary actions (`_actionType` - a `bytes32` identifier), with a numerical value (`_actionValue`) and associated data (`_actionData`). This data could represent anything meaningful in your application context (e.g., number of tasks completed, votes cast, content created, etc.).
    *   **Action Type Definitions (`defineReputationActionType`)**:  The owner can define different types of actions, assigning:
        *   **Description**: For clarity and off-chain interpretation.
        *   **Base Reputation Points**:  Points awarded per action.
        *   **`isCumulative` Flag**:  Determines if the reputation is based on the *sum* of `_actionValue` (e.g., total value contributed) or the *count* of actions (e.g., number of contributions). This adds a layer of sophistication to reputation calculation.

3.  **Dynamic Reputation Scoring (`calculateReputationScore`)**:
    *   The contract calculates a reputation score for each identity based on the actions they've performed and the defined action types.
    *   **Configurable Weights (`setReputationWeight`)**: The contract owner can dynamically adjust the weight (importance) of different action types in the reputation calculation. This allows for fine-tuning the reputation system over time as the platform or community evolves.
    *   **Endorsements (`endorseIdentity`)**: Identities can endorse each other, adding a social/community aspect to reputation. Endorsements contribute to the reputation score with a configurable weight (`setEndorsementWeight`).

4.  **Influence Tracking (`isInfluential`, `influenceThreshold`)**:
    *   The contract defines an "influence threshold." Identities with a reputation score above this threshold are considered "influential."
    *   This can be used to grant special privileges, roles, or recognition to influential members within a decentralized application. The threshold is also configurable by the contract owner (`setInfluenceThreshold`).

5.  **Advanced and Creative Aspects:**
    *   **Flexibility:** The `recordAction` function with `bytes32 _actionType` and `bytes _actionData` makes the contract highly adaptable to various use cases. You can define your own action types and data structures to represent different activities within your application.
    *   **Dynamic Configuration:** The ability to adjust reputation weights, endorsement weights, and influence thresholds allows the contract to evolve and adapt to changing community dynamics or platform goals.
    *   **Potential for Off-Chain Integration:** While the contract is on-chain, the `metadataURI` for identities and `_actionData` in `recordAction` open possibilities for integrating with off-chain data sources and verification mechanisms. For example, you could record actions based on verifiable credentials or data from external APIs.
    *   **Beyond Simple Scores:** The `isCumulative` flag and the concept of different action types with weights move beyond a simple, single-dimensional reputation score. It allows for a more nuanced and multifaceted reputation system.

6.  **Trendy Concepts:**
    *   **Decentralized Identity (DID):**  The `registerIdentity` and `identityMetadata` features align with the growing trend of decentralized identity and user-controlled data.
    *   **Reputation Systems:** Reputation is crucial in decentralized environments to build trust, incentivize positive behavior, and manage communities without central authorities.
    *   **Influence Metrics:** In decentralized governance and social platforms, understanding and tracking influence is becoming increasingly important.

**How to Use and Extend:**

1.  **Deploy the Contract:** Deploy this Solidity contract to a blockchain network.
2.  **Initialize the Contract:** Call `initializeContract` with a name and version.
3.  **Define Action Types (Owner Function):** Use `defineReputationActionType` to define the actions you want to track (e.g., "CodeContribution," "BugReport," "ContentCreation," "VotingParticipation"). Set descriptions, base points, and `isCumulative` as needed.
4.  **Register Identities:** Users can call `registerIdentity` to register their addresses and set their metadata URI.
5.  **Record Actions:**  Your application (or other smart contracts) would call `recordAction` to log actions performed by registered identities. You would need to decide on the specific `_actionType`, `_actionValue`, and `_actionData` to pass based on the action being recorded.
6.  **Calculate Reputation:** Call `calculateReputationScore` to get the reputation score of an identity.
7.  **Check Influence:** Call `isInfluential` to see if an identity is considered influential.
8.  **Manage Weights and Thresholds (Owner Functions):** The contract owner can adjust reputation weights, endorsement weights, and the influence threshold as required to fine-tune the system.

**Important Considerations:**

*   **Gas Optimization:** The `calculateReputationScore` function iterates through a fixed range of `bytes32` which is inefficient. In a real-world application, you would need to optimize this. You could maintain a list of defined action types and iterate only through that list.
*   **Data Storage Costs:** Storing action counts and sums for many identities and action types can consume gas for storage. Consider data pruning or archiving strategies if necessary for long-term usage.
*   **Security:**  Ensure proper access control and validation in your application logic when calling `recordAction` to prevent malicious or incorrect data from being recorded.
*   **Off-Chain Integration Complexity:**  Integrating with off-chain data sources for action verification will add complexity to your overall system architecture.

This contract provides a strong foundation for building a sophisticated decentralized reputation system. You can customize and extend it further to meet the specific needs of your decentralized application or platform.