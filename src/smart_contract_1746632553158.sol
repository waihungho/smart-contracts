Okay, here is a Solidity smart contract proposal for a concept I'll call "Sybil-Resistant Protocol Persona" (SRPP).

This contract combines several advanced ideas:
1.  **Dynamic NFTs:** The NFT's traits and metadata change based on on-chain and potentially verified off-chain activity.
2.  **Cross-Protocol Activity Tracking:** It allows authorized protocols or oracles to report user activity, building a decentralized "persona" score.
3.  **Score-Based Staking & Yield:** Users can stake their Persona NFT to earn yield, where the yield rate is dynamically influenced by their persona score.
4.  **Verifiable Off-Chain Data Integration:** Includes a mechanism for trusted oracles to attest to off-chain data linked to a persona.
5.  **Persona-Based Roles/Permissions:** The contract can grant specific roles or flags to personas meeting certain criteria, potentially usable by integrated dApps.
6.  **Modularity/Extensibility (Conceptual):** Designed with distinct functions for score calculation, trait generation, etc., which in a more complex version could point to upgradeable logic contracts (though for this example, it's kept within one file).

It aims *not* to be a simple clone of ERC20/721/1155, or a direct copy of major DeFi/DAO protocols, but rather a building block focused on decentralized identity/reputation linked to dynamic digital assets and utility.

---

**Outline and Function Summary:**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
 * @title SybilResistantProtocolPersona (SRPP)
 * @author [Your Name/Alias]
 * @notice A dynamic NFT contract representing a decentralized protocol persona.
 * Its traits and utility (e.g., staking yield) are derived from verified
 * on-chain activity across registered protocols and attested off-chain data.
 * Aims to create a sybil-resistant reputation layer tied to a transferable asset.
 */

/*
 * SECTION 1: Core ERC721 Standard Functions (Inherited/Implemented)
 * These provide the standard NFT functionality.
 */
// - name(): Returns the contract name.
// - symbol(): Returns the contract symbol.
// - balanceOf(address owner): Returns the number of NFTs owned by an address.
// - ownerOf(uint256 tokenId): Returns the owner of a specific NFT.
// - approve(address to, uint256 tokenId): Approves another address to transfer an NFT.
// - getApproved(uint256 tokenId): Gets the approved address for a single NFT.
// - setApprovalForAll(address operator, bool _approved): Approves or disables global operator approval.
// - isApprovedForAll(address owner, address operator): Checks if an address is a global operator.
// - transferFrom(address from, address to, uint256 tokenId): Transfers an NFT from one address to another.
// - safeTransferFrom(address from, address to, uint256 tokenId, bytes data): Safe transfer with receiver checks.
// - safeTransferFrom(address from, address to, uint256 tokenId): Safe transfer without data.
// - tokenURI(uint256 tokenId): Returns the metadata URI for a token, dynamically generated based on persona state.
// - supportsInterface(bytes4 interfaceId): ERC165 interface support check.

/*
 * SECTION 2: Persona Core Logic (Minting, Scoring, Traits, Data)
 * Functions related to creating and managing the persona data linked to the NFT.
 */
// - mintPersonaNFT(): Allows a user to mint their unique persona NFT (usually 1 per address limit).
// - updateProtocolActivity(uint256 tokenId, bytes32 protocolId, uint256 activityType, uint256 value, bytes proof):
//   Called by a registered protocol or oracle to report user activity related to a persona. Includes proof verification placeholder.
// - verifyOffchainData(uint256 tokenId, bytes32 dataType, bytes data, bytes signature):
//   Called by a trusted oracle to submit verified off-chain data linked to a persona. Includes signature verification placeholder.
// - calculatePersonaScore(uint256 tokenId): Internal or public function to recalculate/update a persona's score based on stored data.
// - getPersonaScore(uint256 tokenId): View function to get the current persona score.
// - getPersonaTraits(uint256 tokenId): View function to get the current dynamic traits derived from the score and data.
// - getProtocolActivity(uint256 tokenId, bytes32 protocolId, uint256 activityType): View a specific reported activity value.
// - getOffchainData(uint256 tokenId, bytes32 dataType): View a specific piece of verified off-chain data.

/*
 * SECTION 3: Staking and Rewards
 * Functions enabling staking the NFT and earning yield based on persona score.
 */
// - stakePersonaNFT(uint256 tokenId): Stakes a persona NFT in the contract. Only owned tokens can be staked.
// - unstakePersonaNFT(uint256 tokenId): Unstakes a previously staked persona NFT.
// - claimStakingRewards(uint256 tokenId): Claims accumulated staking rewards for a staked or unstaked token.
// - viewStakingRewards(uint256 tokenId): View function to see pending staking rewards.
// - fundStakingPoolWithToken(uint256 amount): Allows anyone to deposit reward tokens into the staking pool.
// - receive() external payable: Allows contract to receive ETH (if ETH rewards are supported, not in this example).
// - fallback() external payable: Allows contract to receive ETH (if ETH rewards are supported, not in this example).

/*
 * SECTION 4: Persona Roles and Utility
 * Functions for managing dynamic roles or flags based on persona criteria.
 */
// - grantPersonaRole(uint256 tokenId, bytes32 roleId): Grants a specific role to a persona (e.g., based on score threshold, or admin action).
// - revokePersonaRole(uint256 tokenId, bytes32 roleId): Revokes a specific role.
// - checkPersonaRole(uint256 tokenId, bytes32 roleId): View function to check if a persona has a specific role.

/*
 * SECTION 5: Admin and Configuration
 * Functions for contract owner/admin to configure parameters.
 */
// - registerProtocol(address protocolAddress, bytes32 protocolId): Registers an address as an authorized protocol reporter.
// - unregisterProtocol(bytes32 protocolId): Unregisters a protocol.
// - setOracleAddress(address oracleAddress): Sets the trusted oracle address for off-chain data.
// - setScoreWeights(uint256[] memory activityWeights, uint256[] memory dataWeights): Sets weights for different activity/data types in score calculation.
// - setRewardToken(address tokenAddress): Sets the address of the ERC20 token used for staking rewards.
// - setBaseTokenURI(string memory baseURI): Sets the base URI for NFT metadata (points to external dynamic generator).
// - pauseContract(): Pauses core contract functionality (minting, staking, updates).
// - unpauseContract(): Unpauses the contract.
// - withdrawFunds(address tokenAddress, uint256 amount): Allows owner to withdraw mistakenly sent tokens (careful with reward pool).

```

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol"; // For potential on-chain metadata generation helper

// Placeholder interfaces for registered protocols and oracles
interface IProtocolReporter {
    // Example: function reportActivity(address user, uint256 activityType, uint256 value);
}

interface IOracle {
    // Example: function submitData(address user, bytes32 dataType, bytes data, bytes signature);
    // function verifySignature(bytes32 dataHash, bytes signature, address signer) external view returns (bool);
}

contract SybilResistantProtocolPersona is ERC721, Ownable, Pausable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIdCounter;

    // --- State Variables ---

    // Mapping user addresses to their minted token ID (only 1 persona per address)
    mapping(address => uint256) private _addressToTokenId;
    // Mapping token IDs back to user addresses (redundant but helpful)
    mapping(uint256 => address) private _tokenIdToAddress;

    // Persona Data Storage (linked to tokenId)
    // protocolId -> activityType -> value
    mapping(uint256 => mapping[bytes32][uint256]) private _protocolActivity;
    // dataType -> value (hashed/simplified representation)
    mapping(uint256 => mapping[bytes32][bytes32]) private _offchainData; // Storing hash or simplified data

    // Persona Score
    mapping(uint256 => uint256) private _personaScores;
    // Timestamps of last score calculation (for potential caching/recalculation logic)
    mapping(uint256 => uint48) private _lastScoreCalculation;

    // Persona Traits (can be derived from score/data, or stored)
    // traitType -> value (simplified)
    mapping(uint256 => mapping[bytes32][bytes32]) private _personaTraits; // Example: "rank" -> "gold", "status" -> "verified"

    // Staking
    mapping(uint256 => uint48) private _stakedTimestamp; // 0 if not staked
    mapping(uint256 => uint256) private _claimedRewards; // Total rewards claimed
    mapping(uint256 => uint256) private _unclaimedRewards; // Pending rewards

    IERC20 private _rewardToken;
    uint256 private _totalStakedScore; // Sum of scores of staked tokens

    // Configuration
    mapping(bytes32 => address) private _registeredProtocols; // protocolId -> address
    address private _trustedOracle;

    // Weights for score calculation (simplified)
    mapping(bytes32 => uint256) private _activityWeights; // protocolId/activityType combined hash -> weight
    mapping(bytes32 => uint256) private _dataWeights; // dataType -> weight

    // Persona Roles (dynamic flags based on criteria)
    mapping(uint256 => mapping[bytes32][bool]) private _personaRoles; // tokenId -> roleId -> hasRole

    // Metadata
    string private _baseTokenURI;

    // --- Events ---

    event PersonaMinted(address indexed owner, uint256 indexed tokenId);
    event ProtocolActivityUpdated(uint256 indexed tokenId, bytes32 protocolId, uint256 activityType, uint256 value);
    event OffchainDataVerified(uint256 indexed tokenId, bytes32 dataType, bytes32 dataHash);
    event PersonaScoreUpdated(uint256 indexed tokenId, uint256 newScore);
    event PersonaTraitsUpdated(uint256 indexed tokenId);
    event PersonaStaked(uint256 indexed tokenId, uint48 timestamp);
    event PersonaUnstaked(uint256 indexed tokenId, uint48 timestamp);
    event StakingRewardsClaimed(uint256 indexed tokenId, uint256 amount);
    event StakingPoolFunded(address indexed funder, address indexed token, uint256 amount);
    event ProtocolRegistered(bytes32 indexed protocolId, address indexed protocolAddress);
    event ProtocolUnregistered(bytes32 indexed protocolId);
    event OracleAddressSet(address indexed oracleAddress);
    event PersonaRoleGranted(uint256 indexed tokenId, bytes32 indexed roleId);
    event PersonaRoleRevoked(uint256 indexed tokenId, bytes32 indexed roleId);
    event BaseTokenURISet(string baseURI);


    // --- Constructor ---

    constructor(string memory name, string memory symbol)
        ERC721(name, symbol)
        Ownable(msg.sender)
        Pausable()
    {}

    // --- Modifier ---
    modifier onlyRegisteredProtocol(bytes32 protocolId) {
        require(_registeredProtocols[protocolId] == msg.sender, "SRPP: Not a registered protocol");
        _;
    }

     modifier onlyTrustedOracle() {
        require(_trustedOracle != address(0) && _trustedOracle == msg.sender, "SRPP: Not the trusted oracle");
        _;
    }

    modifier onlyPersonaOwner(uint256 tokenId) {
        require(_exists(tokenId), "SRPP: ERC721 token doesn't exist");
        require(_isApprovedOrOwner(msg.sender, tokenId), "SRPP: Caller is not the owner or approved");
        _;
    }

    // --- SECTION 1: Core ERC721 Standard Functions (Inherited/Implemented) ---
    // Inherited from ERC721: name, symbol, balanceOf, ownerOf, approve, getApproved, setApprovalForAll, isApprovedForAll, transferFrom, safeTransferFrom, supportsInterface

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId); // Ensure token exists and caller is authorized if needed

        // In a real dApp, this would typically return a URI pointing to an external service
        // that dynamically generates the JSON metadata based on the token's state
        // by querying the contract's public view functions (getPersonaScore, getPersonaTraits, etc.).
        // For demonstration, we'll return a base URI plus the token ID.
        // A more advanced version *could* generate base64 data URI on-chain if complexity/gas allows.

        require(bytes(_baseTokenURI).length > 0, "SRPP: Base token URI not set");
        return string(abi.encodePacked(_baseTokenURI, tokenId.toString()));

        // Example of potential on-chain dynamic generation (more complex and gas-intensive):
        /*
        uint256 score = _personaScores[tokenId];
        bytes memory json = abi.encodePacked(
            '{"name": "Persona #', tokenId.toString(),
            '", "description": "A dynamic representation of protocol activity and reputation.",',
            '"attributes": [',
                '{"trait_type": "Persona Score", "value": ', score.toString(), '}'
                // Add more traits based on _personaTraits mapping
                // Iterate through _personaTraits[tokenId] - requires knowing keys, tricky on-chain
            ']}'
        );
        string memory base64Json = Base64.encode(json);
        return string(abi.encodePacked('data:application/json;base64,', base64Json));
        */
    }


    // --- SECTION 2: Persona Core Logic ---

    /**
     * @notice Mints a new Persona NFT for the caller.
     * @dev Limited to one NFT per address.
     */
    function mintPersonaNFT() public whenNotPaused returns (uint256) {
        require(_addressToTokenId[msg.sender] == 0, "SRPP: You already have a Persona NFT");

        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        _safeMint(msg.sender, newTokenId);
        _addressToTokenId[msg.sender] = newTokenId;
        _tokenIdToAddress[newTokenId] = msg.sender;

        // Initialize score and traits (or they are calculated later)
        _personaScores[newTokenId] = 0; // Start with a base score

        emit PersonaMinted(msg.sender, newTokenId);
        return newTokenId;
    }

    /**
     * @notice Allows a registered protocol or oracle to report activity for a persona.
     * @param tokenId The ID of the persona NFT.
     * @param protocolId Identifier for the protocol reporting activity.
     * @param activityType Identifier for the type of activity (e.g., 1=Lent, 2=Traded, 3=Voted).
     * @param value The quantitative value of the activity (e.g., amount lent, volume traded).
     * @param proof Optional proof (e.g., signature, Merkle proof) for verification (placeholder).
     * @dev Includes a placeholder for verifying the proof if required by the implementation.
     * Only callable by registered protocols.
     */
    function updateProtocolActivity(
        uint256 tokenId,
        bytes32 protocolId,
        uint256 activityType,
        uint256 value,
        bytes memory proof
    ) public onlyRegisteredProtocol(protocolId) whenNotPaused {
        require(_exists(tokenId), "SRPP: Token does not exist");

        // --- Placeholder for Proof Verification ---
        // In a real system, 'proof' would be verified here.
        // This could involve checking a signature against a trusted oracle,
        // verifying a ZK proof, checking a Merkle proof against a root hash, etc.
        // Example (simplified): require(_verifyProof(tokenId, protocolId, activityType, value, proof), "SRPP: Invalid proof");
        // For this example, we trust the registered protocol calling the function.
        // --- End Placeholder ---

        _protocolActivity[tokenId][protocolId][activityType] = value;

        // Potentially trigger score recalculation
        _recalculateScore(tokenId);

        emit ProtocolActivityUpdated(tokenId, protocolId, activityType, value);
    }

    /**
     * @notice Allows the trusted oracle to verify and submit off-chain data for a persona.
     * @param tokenId The ID of the persona NFT.
     * @param dataType Identifier for the type of off-chain data (e.g., "kyc", "credentials").
     * @param data The data itself (could be a hash, a boolean flag, etc.).
     * @param signature A signature from the trusted oracle attesting to the data.
     * @dev Includes a placeholder for signature verification. Only callable by the trusted oracle.
     */
    function verifyOffchainData(
        uint256 tokenId,
        bytes32 dataType,
        bytes memory data, // Can be flexible, e.g., abi.encodePacked(bool), bytes32 hash
        bytes memory signature
    ) public onlyTrustedOracle whenNotPaused {
        require(_exists(tokenId), "SRPP: Token does not exist");

        // --- Placeholder for Signature Verification ---
        // Verify the signature against the trusted oracle's address and a hash of the data.
        // This is a critical security point.
        // Example: bytes32 dataHash = keccak256(abi.encodePacked(tokenId, dataType, data));
        //          require(IOracle(_trustedOracle).verifySignature(dataHash, signature, _trustedOracle), "SRPP: Invalid oracle signature");
        // For this example, we trust the oracle calling the function.
        // Store a hash of the data for integrity check, not the raw data usually.
        bytes32 dataHash = keccak256(data);
        // --- End Placeholder ---

        _offchainData[tokenId][dataType] = dataHash; // Store the hash

        // Potentially trigger score recalculation
        _recalculateScore(tokenId);

        emit OffchainDataVerified(tokenId, dataType, dataHash);
    }

    /**
     * @notice Internal function to recalculate the persona score based on current activity and data.
     * @param tokenId The ID of the persona NFT.
     * @dev This is where the core scoring logic resides. It should be deterministic.
     */
    function _recalculateScore(uint256 tokenId) internal {
        // This is a simplified example. Real logic would be more complex.
        uint256 currentScore = 0;

        // Score based on protocol activity
        // This loop structure (iterating mappings) is problematic on-chain
        // A better design passes specific relevant activities or uses fixed indices/types
        // For demonstration, let's assume we know specific activity types to check
        bytes32[] memory relevantProtocols = new bytes32[](1); // Example list
        relevantProtocols[0] = keccak256("exampleProtocol"); // Replace with actual ID

        uint256[] memory relevantActivities = new uint256[](2); // Example types
        relevantActivities[0] = 1; // e.g., Lent
        relevantActivities[1] = 2; // e.g., Traded

        for(uint i = 0; i < relevantProtocols.length; i++) {
            for(uint j = 0; j < relevantActivities.length; j++) {
                bytes32 protocolId = relevantProtocols[i];
                uint256 activityType = relevantActivities[j];
                uint256 value = _protocolActivity[tokenId][protocolId][activityType];
                bytes32 activityKey = keccak256(abi.encodePacked(protocolId, activityType));
                currentScore += (value * _activityWeights[activityKey]) / 1e18; // Use weights, handle fixed point if needed
            }
        }

        // Score based on off-chain data presence (simplified)
        bytes32[] memory relevantDataTypes = new bytes32[](1); // Example list
        relevantDataTypes[0] = keccak256("kyc"); // Replace with actual ID

         for(uint i = 0; i < relevantDataTypes.length; i++) {
             bytes32 dataType = relevantDataTypes[i];
             if (_offchainData[tokenId][dataType] != bytes32(0)) { // Check if data exists
                 currentScore += _dataWeights[dataType];
             }
         }

        _personaScores[tokenId] = currentScore;
        _lastScoreCalculation[tokenId] = uint48(block.timestamp); // Update timestamp

        // Also update traits based on the new score
        _updatePersonaTraits(tokenId, currentScore);

        emit PersonaScoreUpdated(tokenId, currentScore);
    }

    /**
     * @notice Internal function to update the persona traits based on the current score and data.
     * @param tokenId The ID of the persona NFT.
     * @param score The current score.
     * @dev This logic determines the visual representation/attributes of the NFT.
     */
    function _updatePersonaTraits(uint256 tokenId, uint256 score) internal {
        // Simplified example: map score ranges to traits
        if (score < 100) {
            _personaTraits[tokenId][keccak256("rank")] = keccak256("bronze");
        } else if (score < 500) {
            _personaTraits[tokenId][keccak256("rank")] = keccak256("silver");
        } else if (score < 2000) {
            _personaTraits[tokenId][keccak256("rank")] = keccak256("gold");
        } else {
            _personaTraits[tokenId][keccak256("rank")] = keccak256("platinum");
        }

        // Example: add a trait based on verified off-chain data
        if (_offchainData[tokenId][keccak256("kyc")] != bytes32(0)) {
             _personaTraits[tokenId][keccak256("status")] = keccak256("verified");
        } else {
             _personaTraits[tokenId][keccak256("status")] = bytes32(0); // Or some default value
        }


        // Emit event to signal traits changed, prompting metadata refresh
        emit PersonaTraitsUpdated(tokenId);
    }

    /**
     * @notice Gets the current persona score for a token.
     * @param tokenId The ID of the persona NFT.
     * @return The current score.
     */
    function getPersonaScore(uint256 tokenId) public view returns (uint256) {
        return _personaScores[tokenId];
    }

     /**
     * @notice Gets the current dynamic traits for a token.
     * @param tokenId The ID of the persona NFT.
     * @dev Note: Retrieving *all* traits from a mapping is impossible in Solidity.
     * This function returns a *specific* trait. A real implementation might require
     * pre-defined trait types or external metadata generation.
     * This version returns the 'rank' and 'status' traits for demonstration.
     * @return rankTrait The bytes32 representation of the 'rank' trait.
     * @return statusTrait The bytes32 representation of the 'status' trait.
     */
    function getPersonaTraits(uint256 tokenId) public view returns (bytes32 rankTrait, bytes32 statusTrait) {
         // Demonstrates fetching known trait types
         rankTrait = _personaTraits[tokenId][keccak256("rank")];
         statusTrait = _personaTraits[tokenId][keccak256("status")];
         // Expand this to return more if needed, or return a struct/array if types are fixed
    }


    /**
     * @notice Gets a specific reported protocol activity value for a token.
     * @param tokenId The ID of the persona NFT.
     * @param protocolId Identifier for the protocol.
     * @param activityType Identifier for the activity type.
     * @return The reported value.
     */
    function getProtocolActivity(uint256 tokenId, bytes32 protocolId, uint256 activityType) public view returns (uint256) {
        return _protocolActivity[tokenId][protocolId][activityType];
    }

    /**
     * @notice Gets a specific verified off-chain data hash for a token.
     * @param tokenId The ID of the persona NFT.
     * @param dataType Identifier for the data type.
     * @return The stored data hash.
     */
    function getOffchainData(uint256 tokenId, bytes32 dataType) public view returns (bytes32) {
        return _offchainData[tokenId][dataType];
    }


    // --- SECTION 3: Staking and Rewards ---

    /**
     * @notice Stakes a persona NFT.
     * @param tokenId The ID of the persona NFT to stake.
     */
    function stakePersonaNFT(uint256 tokenId) public nonReentrant whenNotPaused onlyPersonaOwner(tokenId) {
        require(_stakedTimestamp[tokenId] == 0, "SRPP: Token is already staked");
        require(_rewardToken != address(0), "SRPP: Reward token not set");

        address owner = ownerOf(tokenId);

        // Transfer the NFT to the contract
        _transfer(owner, address(this), tokenId);

        _stakedTimestamp[tokenId] = uint48(block.timestamp);
        _totalStakedScore += _personaScores[tokenId]; // Add score to total staked pool score

        emit PersonaStaked(tokenId, _stakedTimestamp[tokenId]);
    }

    /**
     * @notice Unstakes a persona NFT.
     * @param tokenId The ID of the persona NFT to unstake.
     */
    function unstakePersonaNFT(uint256 tokenId) public nonReentrant whenNotPaused {
        require(_stakedTimestamp[tokenId] != 0, "SRPP: Token is not staked");
        require(owner() == msg.sender || _isApprovedOrOwner(msg.sender, address(this)), "SRPP: Only owner or approved can unstake from contract"); // Allow original owner or approved to trigger unstake

        // Calculate and accrue pending rewards *before* unstaking and reducing staked score
        _accrueStakingRewards(tokenId);

        uint288 stakedScore = uint288(_personaScores[tokenId]); // Cast to avoid overflow in subtraction
        require(_totalStakedScore >= stakedScore, "SRPP: Total staked score calculation error"); // Should not happen
        _totalStakedScore -= stakedScore;

        uint256 initialTimestamp = _stakedTimestamp[tokenId];
        _stakedTimestamp[tokenId] = 0; // Mark as unstaked

        address originalOwner = _tokenIdToAddress[tokenId]; // Get original owner

        // Transfer the NFT back to the original owner
        _transfer(address(this), originalOwner, tokenId);

        emit PersonaUnstaked(tokenId, initialTimestamp);
    }

    /**
     * @notice Claims accumulated staking rewards for a persona NFT.
     * @param tokenId The ID of the persona NFT. Can be staked or unstaked.
     */
    function claimStakingRewards(uint256 tokenId) public nonReentrant whenNotPaused {
        require(_exists(tokenId), "SRPP: Token does not exist");
        require(ownerOf(tokenId) == msg.sender || _tokenIdToAddress[tokenId] == msg.sender, "SRPP: Not the owner or original minter"); // Allow original minter to claim if not owned

        // Accrue any rewards since last check/claim if currently staked
        if (_stakedTimestamp[tokenId] != 0) {
            _accrueStakingRewards(tokenId);
        }

        uint256 rewards = _unclaimedRewards[tokenId];
        require(rewards > 0, "SRPP: No rewards to claim");

        _unclaimedRewards[tokenId] = 0;
        _claimedRewards[tokenId] += rewards;

        // Transfer rewards to the token owner (could be msg.sender if owned, or original minter if transferred)
        address payable recipient = payable(ownerOf(tokenId));
        if (ownerOf(tokenId) == address(this)) {
             // If still staked, send to the original minter
             recipient = payable(_tokenIdToAddress[tokenId]);
        }

        IERC20(_rewardToken).transfer(recipient, rewards);

        emit StakingRewardsClaimed(tokenId, rewards);
    }

    /**
     * @notice Views pending staking rewards for a persona NFT.
     * @param tokenId The ID of the persona NFT.
     * @return The amount of unclaimed rewards.
     */
    function viewStakingRewards(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "SRPP: Token does not exist");

        uint256 pendingRewards = _unclaimedRewards[tokenId];
        if (_stakedTimestamp[tokenId] != 0) {
            // Calculate rewards accrued since last accrual/stake time
            uint256 elapsed = block.timestamp - _stakedTimestamp[tokenId];
            uint256 currentScore = _personaScores[tokenId];

            // Simplified reward calculation: rewards per second = (score / total_staked_score) * total_reward_rate_per_second
            // Assuming a constant total reward rate for simplicity. In reality, this would be more dynamic.
            // This calculation avoids floating point arithmetic by scaling.
            // (currentScore * elapsed * total_rewards_per_second) / _totalStakedScore
             if (_totalStakedScore > 0) {
                 // Placeholder for total rewards per second logic
                 uint256 totalRewardsPerSecond = 1e18; // Example: 1 token per second (scaled)

                unchecked { // Use unchecked for potential overflow in multiplication, but ensure logic prevents actual overflow with reasonable numbers
                    pendingRewards += (currentScore * elapsed * totalRewardsPerSecond) / _totalStakedScore;
                }
             }
        }
        return pendingRewards;
    }

    /**
     * @notice Internal function to accrue pending staking rewards up to the current time.
     * @param tokenId The ID of the persona NFT.
     * @dev Called before unstaking or claiming.
     */
    function _accrueStakingRewards(uint256 tokenId) internal {
         uint48 stakedTime = _stakedTimestamp[tokenId];
         if (stakedTime != 0) {
             uint256 elapsed = block.timestamp - stakedTime;
             uint256 currentScore = _personaScores[tokenId];

              if (_totalStakedScore > 0) {
                uint256 totalRewardsPerSecond = 1e18; // Example: 1 token per second (scaled)

                unchecked {
                    uint256 accrued = (currentScore * elapsed * totalRewardsPerSecond) / _totalStakedScore;
                     _unclaimedRewards[tokenId] += accrued;
                }
             }
             _stakedTimestamp[tokenId] = uint48(block.timestamp); // Reset timer
         }
    }


    /**
     * @notice Allows anyone to fund the staking reward pool with ERC20 tokens.
     * @param amount The amount of reward tokens to deposit.
     * @dev Requires prior approval of the tokens to the contract address.
     */
    function fundStakingPoolWithToken(uint256 amount) public whenNotPaused {
        require(_rewardToken != address(0), "SRPP: Reward token not set");
        require(amount > 0, "SRPP: Amount must be greater than 0");

        IERC20(_rewardToken).transferFrom(msg.sender, address(this), amount);

        emit StakingPoolFunded(msg.sender, address(_rewardToken), amount);
    }

    // Optional: Allow receiving ETH if ETH rewards are desired
    receive() external payable whenNotPaused {
        // Handle received ETH, e.g., add to an ETH reward pool
        emit StakingPoolFunded(msg.sender, address(0), msg.value); // Use address(0) for ETH
    }

    fallback() external payable whenNotPaused {
         // Handle received ETH if no function matches
         emit StakingPoolFunded(msg.sender, address(0), msg.value); // Use address(0) for ETH
    }


    // --- SECTION 4: Persona Roles and Utility ---

    /**
     * @notice Grants a specific role to a persona.
     * @param tokenId The ID of the persona NFT.
     * @param roleId Identifier for the role.
     * @dev Can be called by owner, or potentially based on automated criteria checks.
     */
    function grantPersonaRole(uint256 tokenId, bytes32 roleId) public onlyOwner whenNotPaused {
        require(_exists(tokenId), "SRPP: Token does not exist");
        require(!_personaRoles[tokenId][roleId], "SRPP: Persona already has this role");

        _personaRoles[tokenId][roleId] = true;
        emit PersonaRoleGranted(tokenId, roleId);
    }

    /**
     * @notice Revokes a specific role from a persona.
     * @param tokenId The ID of the persona NFT.
     * @param roleId Identifier for the role.
     * @dev Can be called by owner, or potentially based on automated criteria checks (e.g., score dropping).
     */
    function revokePersonaRole(uint256 tokenId, bytes32 roleId) public onlyOwner whenNotPaused {
        require(_exists(tokenId), "SRPP: Token does not exist");
        require(_personaRoles[tokenId][roleId], "SRPP: Persona does not have this role");

        _personaRoles[tokenId][roleId] = false;
        emit PersonaRoleRevoked(tokenId, roleId);
    }

    /**
     * @notice Checks if a persona has a specific role.
     * @param tokenId The ID of the persona NFT.
     * @param roleId Identifier for the role.
     * @return True if the persona has the role, false otherwise.
     */
    function checkPersonaRole(uint256 tokenId, bytes32 roleId) public view returns (bool) {
        require(_exists(tokenId), "SRPP: Token does not exist");
        return _personaRoles[tokenId][roleId];
    }


    // --- SECTION 5: Admin and Configuration ---

    /**
     * @notice Registers an address as an authorized protocol reporter.
     * @param protocolAddress The address of the protocol contract or reporter.
     * @param protocolId Unique identifier for the protocol.
     * @dev Only owner can call.
     */
    function registerProtocol(address protocolAddress, bytes32 protocolId) public onlyOwner {
        require(protocolAddress != address(0), "SRPP: Invalid address");
        require(_registeredProtocols[protocolId] == address(0), "SRPP: Protocol ID already registered");
        _registeredProtocols[protocolId] = protocolAddress;
        emit ProtocolRegistered(protocolId, protocolAddress);
    }

    /**
     * @notice Unregisters a protocol reporter.
     * @param protocolId Unique identifier for the protocol.
     * @dev Only owner can call.
     */
    function unregisterProtocol(bytes32 protocolId) public onlyOwner {
        require(_registeredProtocols[protocolId] != address(0), "SRPP: Protocol ID not registered");
        delete _registeredProtocols[protocolId];
         emit ProtocolUnregistered(protocolId);
    }

     /**
     * @notice Sets the trusted oracle address for off-chain data verification.
     * @param oracleAddress The address of the trusted oracle contract or account.
     * @dev Only owner can call. Setting to address(0) disables oracle verification.
     */
    function setOracleAddress(address oracleAddress) public onlyOwner {
        _trustedOracle = oracleAddress;
        emit OracleAddressSet(oracleAddress);
    }

    /**
     * @notice Sets weights for different activity types and data types for score calculation.
     * @param activityIds Array of activity/protocol combined hashes (e.g., keccak256(abi.encodePacked(protocolId, activityType))).
     * @param activityWeights Corresponding array of weights.
     * @param dataIds Array of data type hashes (e.g., keccak256("kyc")).
     * @param dataWeights Corresponding array of weights.
     * @dev Lengths of arrays must match. Weights are used in the _recalculateScore function.
     *      Consider using a fixed-point representation for weights (e.g., scaled by 1e18).
     *      This is a simplified example, real systems might use more complex configurations.
     */
    function setScoreWeights(
        bytes32[] memory activityIds,
        uint256[] memory activityWeights,
        bytes32[] memory dataIds,
        uint256[] memory dataWeights
    ) public onlyOwner {
        require(activityIds.length == activityWeights.length, "SRPP: Activity array length mismatch");
        require(dataIds.length == dataWeights.length, "SRPP: Data array length mismatch");

        for (uint i = 0; i < activityIds.length; i++) {
            _activityWeights[activityIds[i]] = activityWeights[i];
        }
         for (uint i = 0; i < dataIds.length; i++) {
            _dataWeights[dataIds[i]] = dataWeights[i];
        }
    }

     /**
     * @notice Sets the ERC20 token address used for staking rewards.
     * @param tokenAddress The address of the ERC20 reward token.
     * @dev Only owner can call.
     */
    function setRewardToken(address tokenAddress) public onlyOwner {
        require(tokenAddress != address(0), "SRPP: Invalid token address");
        _rewardToken = IERC20(tokenAddress);
    }

    /**
     * @notice Sets the base URI for token metadata.
     * @param baseURI The base string for token URI (e.g., "https://myawesomedapp.com/api/persona/").
     * @dev The full tokenURI will be baseURI + tokenId. Only owner can call.
     */
    function setBaseTokenURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
        emit BaseTokenURISet(baseURI);
    }

    /**
     * @notice Pauses the contract. Prevents core interactions like minting, updates, staking.
     * @dev Only owner can call. Inherited from Pausable.
     */
    function pauseContract() public onlyOwner {
        _pause();
    }

     /**
     * @notice Unpauses the contract.
     * @dev Only owner can call. Inherited from Pausable.
     */
    function unpauseContract() public onlyOwner {
        _unpause();
    }

     /**
     * @notice Allows the owner to withdraw stuck ERC20 tokens from the contract.
     * @dev Use with extreme caution, ensure not to withdraw reward tokens needed for staking.
     * @param tokenAddress Address of the ERC20 token to withdraw.
     * @param amount Amount of tokens to withdraw.
     */
    function withdrawFunds(address tokenAddress, uint256 amount) public onlyOwner {
        require(tokenAddress != address(_rewardToken), "SRPP: Cannot withdraw reward token using this function");
        IERC20 token = IERC20(tokenAddress);
        require(token.balanceOf(address(this)) >= amount, "SRPP: Insufficient balance");
        token.transfer(msg.sender, amount);
    }


    // --- Internal Helpers ---

    // Placeholder for proof verification logic (complex, depends on proof type)
    // function _verifyProof(uint256 tokenId, bytes32 protocolId, uint256 activityType, uint256 value, bytes memory proof) internal pure returns (bool) {
    //     // Implement specific verification logic here (e.g., signature check, ZK proof verification)
    //     return true; // DUMMY - REPLACE WITH REAL LOGIC
    // }

     // Placeholder for signature verification logic (complex, depends on oracle signature type)
    // function _verifySignature(bytes32 dataHash, bytes memory signature, address signer) internal view returns (bool) {
    //     // Implement specific verification logic here
    //     // Example for ECDSA signature: return ECDSA.recover(ECDSA.toEthSignedMessageHash(dataHash), signature) == signer;
    //     return true; // DUMMY - REPLACE WITH REAL LOGIC
    // }


     // ERC721 override to prevent transfers if staked
     function _transfer(address from, address to, uint256 tokenId) internal override {
         require(_stakedTimestamp[tokenId] == 0 || from == address(this) || to == address(this), "SRPP: Staked tokens cannot be transferred externally");
         super._transfer(from, to, tokenId);
     }

     // ERC721 override hooks (optional, but good practice)
     function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
         super._beforeTokenTransfer(from, to, tokenId, batchSize);
         // Any logic needed before transfer (e.g., calculating/accruing staking rewards if transferred while staked - handled in unstake/claim)
     }

     function _afterTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
         super._afterTokenTransfer(from, to, tokenId, batchSize);
          // Any logic needed after transfer (e.g., updating internal mappings if they weren't handled by _transfer override)
          if (from == address(0)) {
            // Token minted, mappings already set in mint function
          } else if (to == address(0)) {
             // Token burned - clean up mappings
             delete _addressToTokenId[from]; // Assumes 1 token per address
             delete _tokenIdToAddress[tokenId];
             // Also clean up persona data, score, staking data etc. for the burned token
             delete _protocolActivity[tokenId];
             delete _offchainData[tokenId];
             delete _personaScores[tokenId];
             delete _lastScoreCalculation[tokenId];
             delete _personaTraits[tokenId];
             delete _stakedTimestamp[tokenId];
             delete _claimedRewards[tokenId];
             delete _unclaimedRewards[tokenId];
             delete _personaRoles[tokenId];
          } else if (from != address(this) && to != address(this)) {
              // External transfer (not staking/unstaking)
              // If only 1 persona per address is enforced, this transfer would effectively
              // destroy the link for the 'from' address and set it for the 'to' address.
              // If multiple personas were allowed per address, this logic would change.
               delete _addressToTokenId[from]; // Old owner no longer has this token ID linked
              _addressToTokenId[to] = tokenId; // New owner now has this token ID linked (assuming 1/address)
              _tokenIdToAddress[tokenId] = to; // Update back-mapping

               // If the token was staked and transferred externally, this should not happen due to _transfer override.
               // If it somehow did, unstaking logic would break. The override prevents this.

          } else if (to == address(this)) {
             // Staked - handled in stakePersonaNFT
          } else if (from == address(this)) {
             // Unstaked - handled in unstakePersonaNFT
          }
     }

    // Function to get token ID for a given address
    function getTokenIdForAddress(address owner) public view returns (uint256) {
        return _addressToTokenId[owner];
    }

    // Function to get total number of minted tokens
    function getTotalSupply() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    // Getter for reward token address
    function getRewardToken() public view returns (address) {
        return address(_rewardToken);
    }

    // Getter for total staked score
    function getTotalStakedScore() public view returns (uint256) {
        return _totalStakedScore;
    }

    // Getter for oracle address
     function getTrustedOracle() public view returns (address) {
        return _trustedOracle;
    }

     // Check if an address is a registered protocol
     function isRegisteredProtocol(bytes32 protocolId, address protocolAddress) public view returns (bool) {
         return _registeredProtocols[protocolId] == protocolAddress;
     }

     // Count:
     // ERC721: 12 functions (name, symbol, balanceOf, ownerOf, approve, getApproved, setApprovalForAll, isApprovedForAll, transferFrom, safeTransferFrom x2, supportsInterface)
     // Persona Core: 7 functions (mintPersonaNFT, updateProtocolActivity, verifyOffchainData, getPersonaScore, getPersonaTraits, getProtocolActivity, getOffchainData)
     // Staking: 6 functions (stakePersonaNFT, unstakePersonaNFT, claimStakingRewards, viewStakingRewards, fundStakingPoolWithToken, receive/fallback)
     // Roles: 3 functions (grantPersonaRole, revokePersonaRole, checkPersonaRole)
     // Admin: 8 functions (registerProtocol, unregisterProtocol, setOracleAddress, setScoreWeights, setRewardToken, setBaseTokenURI, pauseContract, unpauseContract, withdrawFunds)
     // Utilities/Overrides: 5 functions (_transfer, _beforeTokenTransfer, _afterTokenTransfer, getTokenIdForAddress, getTotalSupply, getRewardToken, getTotalStakedScore, getTrustedOracle, isRegisteredProtocol)

     // Total Public/External/View Functions: 12 + 7 + 6 + 3 + 8 + 5 = 41 functions (including ERC721 and helpers).
     // Core *new* concept functions (Persona Core + Staking + Roles + Admin config): 7 + 6 + 3 + 8 = 24 functions.
     // This meets the >20 function requirement with unique logic beyond basic ERC721.

}
```

---

**Explanation of Advanced/Creative Concepts:**

1.  **Dynamic/Stateful NFT (`tokenURI`, `_recalculateScore`, `_updatePersonaTraits`):** The NFT's metadata isn't static. The `tokenURI` function *should* point to an external API (or generate base64 data on-chain if gas permits) that reads the NFT's state (`_personaScores`, `_personaTraits`) from the contract using view functions and generates the corresponding JSON metadata (image URL, attributes like "Persona Score", "Rank", "Status", etc.). This makes the NFT's visual representation and attributes directly tied to the holder's actions and verified data.
2.  **Cross-Protocol & Off-Chain Data Integration (`updateProtocolActivity`, `verifyOffchainData`, `_registeredProtocols`, `_trustedOracle`):** The contract defines specific entry points (`updateProtocolActivity` and `verifyOffchainData`) that are restricted to authorized callers (registered protocol addresses or a single trusted oracle). This allows building a profile based on interactions with *different* dApps (if they integrate and report activity) and incorporating data that cannot natively live on the blockchain (like KYC status, verified credentials) via a trusted attestation source. The `bytes proof` and `bytes signature` parameters are placeholders for the crucial verification logic needed in a real-world implementation (e.g., checking a ZK proof, verifying an ECDSA signature).
3.  **Score-Based Utility (`_personaScores`, Staking functions):** The `_recalculateScore` function (triggered by data updates) crunch numbers based on predefined weights for different activities and data types. This results in a single `_personaScores[tokenId]` value. This score then directly impacts the utility of the NFT when staked, influencing the `viewStakingRewards` and `_accrueStakingRewards` calculations. This creates a direct link between decentralized reputation/activity and financial yield.
4.  **Persona Roles (`_personaRoles`, `grantPersonaRole`, `revokePersonaRole`, `checkPersonaRole`):** Beyond a single score, the contract can assign specific boolean flags or "roles" to a persona. This could be triggered by achieving certain scores, completing specific verified tasks, or via admin action. Other dApps or contracts could then check `checkPersonaRole(tokenId, roleId)` to grant specific permissions or access based on these roles (e.g., "isEarlyAdopter", "isHighReputationTrader", "isVerifiedHuman").
5.  **Staking with Dynamic Yield (`stakePersonaNFT`, `unstakePersonaNFT`, `claimStakingRewards`, `viewStakingRewards`, `_accrueStakingRewards`, `_totalStakedScore`):** Users can lock their NFT in the contract (`stakePersonaNFT`). While staked, the NFT owner (or original minter if transferred externally) can earn reward tokens from a pool (`fundStakingPoolWithToken`). The rate of reward accumulation is based on the *individual persona score* relative to the *total score of all staked NFTs* (`_totalStakedScore`). This incentivizes building a high score and keeping the NFT staked. `nonReentrant` modifier is used on staking-related functions for safety.
6.  **Modular Design (Conceptual):** While the score calculation and trait logic are in this contract, the structure allows for potential upgrades. In a v2, `_recalculateScore` or `_updatePersonaTraits` could call out to a separate, upgradeable logic contract implementing a Strategy pattern or similar. This contract serves as the data layer and state manager for the persona.
7.  **Sybil Resistance Foundation:** By requiring data to come from *registered*, *trusted* sources (protocols/oracles), the contract provides a foundation for building a reputation system that is harder to fake than simple token holdings or address age. A user can't just call a function themselves to inflate their score; their activity must be attested by the platforms they interact with.

This contract provides a framework for a decentralized, dynamic identity layer linked to a valuable, yield-bearing NFT, offering a richer and potentially more sybil-resistant form of on-chain identity than simple token ownership. Note that a full implementation would require robust off-chain infrastructure (for the oracle, protocol integrations, and metadata hosting) and potentially more complex on-chain logic for scoring and verification proofs.