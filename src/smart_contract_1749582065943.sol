Okay, here is a Solidity smart contract implementing a "Generative Art Engine" concept. It combines NFTs, decentralized parameter curation (via voting), staking, and on-chain data influencing the generative seed, aiming for interesting and advanced concepts beyond a standard NFT drop.

It focuses on:
1.  **Generative Parameters:** Storing adjustable parameters on-chain that influence the generated art.
2.  **Decentralized Curation:** Allowing token holders (or stakers) to propose and vote on parameter changes/additions.
3.  **Dynamic State:** Parameter weights can evolve based on voting outcomes, affecting future generations.
4.  **On-Chain Seed:** The random seed for each art piece is derived from block data, token ID, and *weighted* parameters. (Rendering happens off-chain based on this seed and parameters).
5.  **Staking:** Users stake ETH (or a token) to gain voting rights.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title GenerativeArtEngine
 * @dev A smart contract for a dynamic generative art collection where parameters
 *      influencing the art can be curated and voted on by the community.
 *      NFTs are minted with a seed derived from block data and community-weighted parameters.
 *      Rendering of the art happens off-chain based on the on-chain seed and parameters.
 */

// --- OUTLINE ---
// 1.  Imports (none needed for this custom implementation)
// 2.  Error Definitions
// 3.  Event Definitions
// 4.  Struct Definitions (Param)
// 5.  State Variables (ERC721 data, Minting state, Parameters, Voting, Staking, Admin)
// 6.  Access Control Modifiers (Owner, Pausable)
// 7.  Constructor
// 8.  ERC721 Standard Functions (Basic implementation)
// 9.  Minting Logic
// 10. Generative Seed Logic
// 11. Parameter Management (Add, Remove, Update, Get)
// 12. Decentralized Curation / Voting Logic (Propose, Vote, Process Vote Results)
// 13. Staking Logic (Stake ETH for voting rights, Withdraw Stake)
// 14. Metadata Logic (tokenURI)
// 15. Admin / Owner Functions
// 16. View Functions (Getters for state variables)

// --- FUNCTION SUMMARY ---
// ERC721 Standard Functions (Basic Implementation):
// - ownerOf(uint256 tokenId): Get the owner of a token.
// - balanceOf(address owner): Get the balance of an owner.
// - transferFrom(address from, address to, uint256 tokenId): Transfer token ownership.
// - safeTransferFrom(address from, address to, uint256 tokenId): Safe transfer.
// - safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data): Safe transfer with data.
// - approve(address to, uint256 tokenId): Approve an address to transfer a token.
// - setApprovalForAll(address operator, bool approved): Set approval for an operator for all tokens.
// - getApproved(uint256 tokenId): Get the approved address for a token.
// - isApprovedForAll(address owner, address operator): Check if an operator is approved for all tokens.
// - supportsInterface(bytes4 interfaceId): Standard ERC165 interface check (simplified).

// Core Engine Functions:
// - mint(): Mints a new generative art NFT, calculates and stores its unique seed.
// - calculateSeed(uint256 tokenId): Internal function to generate a unique seed based on block data, token ID, and weighted parameters.
// - getSeedForToken(uint256 tokenId): View function to retrieve the stored seed for a token.

// Parameter Management & Curation Functions:
// - proposeParameter(bytes memory paramData, string memory paramType, string memory name, uint256 stakeRequired): Propose a new parameter requiring stakeholder vote.
// - voteForParameter(uint256 paramId, bool support): Vote on a proposed parameter (requires stake).
// - processParameterVotes(uint256 paramId): Owner/Admin function to tally votes and potentially update param state/weight.
// - updateParameterWeight(uint256 paramId, int256 weightChange): Admin/Automated function to directly adjust a parameter's weight.
// - activateParameter(uint256 paramId): Admin/Automated function to mark a parameter as active for generation.
// - deactivateParameter(uint256 paramId): Admin/Automated function to mark a parameter as inactive.
// - addInitialParameter(bytes memory paramData, string memory paramType, string memory name, int256 initialWeight, bool isActive): Owner/Admin function to add parameters directly (e.g., for initial setup).
// - removeParameter(uint256 paramId): Owner/Admin function to remove a parameter entirely.

// Staking Functions:
// - stakeForVoting(): Stake Ether to gain voting rights on parameters.
// - withdrawStake(): Withdraw staked Ether (potentially with cooldown or conditions).

// Metadata Function:
// - tokenURI(uint256 tokenId): Generates the metadata URI for a token, including its seed and parameters.

// Admin & Owner Functions:
// - transferOwnership(address newOwner): Transfer contract ownership.
// - addAdmin(address admin): Grant admin role.
// - removeAdmin(address admin): Revoke admin role.
// - pauseMinting(): Pause the minting process.
// - unpauseMinting(): Unpause the minting process.
// - setBaseURI(string memory baseURI): Set the base URI for token metadata.
// - setStakeRequirement(uint256 requiredStake): Set the minimum stake needed to vote.
// - rescueFunds(address tokenAddress, uint256 amount): Rescue accidentally sent tokens (non-ETH).
// - rescueETH(uint256 amount): Rescue accidentally sent ETH.

// View Functions:
// - getCurrentTokenId(): Get the ID of the next token to be minted.
// - getParameter(uint256 paramId): Get details of a specific parameter.
// - getActiveParameterIds(): Get IDs of parameters currently used for generation.
// - getProposedParameterIds(): Get IDs of parameters awaiting vote/processing.
// - getUserStake(address voter): Get the stake amount of a user.
// - getUserVote(uint256 paramId, address voter): Check how a user voted on a parameter.
// - getStakeRequirement(): Get the minimum stake required to vote.
// - isPaused(): Check if minting is paused.
// - isOwner(): Check if an address is the owner.
// - isAdmin(address account): Check if an address is an admin.

// --- CONTRACT CODE ---

contract GenerativeArtEngine {

    // --- ERRORS ---
    error NotOwner();
    error NotAdmin();
    error Paused();
    error NotPaused();
    error InvalidTokenId();
    error ZeroAddress();
    error ApprovalQueryForNonexistentToken();
    error ApproveToOwner();
    error TransferToZeroAddress();
    error TransferFromIncorrectOwner();
    error TransferToSelf();
    error URIQueryForNonexistentToken();
    error VotingPeriodEnded(); // Placeholder for future time-based voting
    error ParameterNotProposed();
    error AlreadyVoted();
    error InsufficientStake();
    error AlreadyActive();
    error AlreadyInactive();
    error StakeTooLow();
    error NothingToWithdraw();
    error CannotWithdrawYet(); // Placeholder for cooldown
    error NothingToRescue();
    error InvalidStakeAmount();
    error ParameterAlreadyExists();

    // --- EVENTS ---
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event Minted(uint256 indexed tokenId, address indexed owner, bytes32 indexed seed);
    event ParameterProposed(uint256 indexed paramId, address indexed proposer, string name, string paramType);
    event Voted(uint256 indexed paramId, address indexed voter, bool support);
    event ParameterStateChanged(uint256 indexed paramId, bool isActive, int256 newWeight);
    event StakeDeposited(address indexed voter, uint256 amount);
    event StakeWithdrawn(address indexed voter, uint256 amount);
    event BaseURIUpdated(string baseURI);
    event MintingPaused();
    event MintingUnpaused();
    event AdminAdded(address indexed account);
    event AdminRemoved(address indexed account);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // --- STRUCTS ---
    struct Param {
        uint256 id;           // Unique ID for the parameter
        string name;          // Human-readable name (e.g., "Color Palette", "Shape Algorithm")
        string paramType;     // Type hint for off-chain rendering (e.g., "bytes", "string", "uint[]")
        bytes paramData;      // The actual parameter data (e.g., encoded array of colors, algorithm identifier)
        int256 weight;        // Influence weight for seed calculation (can be positive/negative)
        address proposer;     // Address that proposed the parameter
        bool isActive;        // Is this parameter currently influencing new generations?
        bool isProposed;      // Is this parameter currently in the voting phase?
        uint256 yesVotes;     // Count of 'support' votes
        uint256 noVotes;      // Count of 'against' votes
        uint256 stakeRequiredToVote; // Stake needed *at time of proposal* to vote on this param
    }

    // --- STATE VARIABLES ---

    // ERC721 Core
    mapping(uint256 => address) private _tokenOwners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    uint256 private _currentTokenId;

    // Minting State
    bool private _paused;

    // Generative Art Parameters
    mapping(uint256 => Param) private _parameters;
    uint256[] private _activeParameterIds;
    uint256[] private _proposedParameterIds; // Parameters currently in voting/pending state
    uint256 private _nextParamId; // Counter for parameter IDs

    // Voting State
    mapping(address => uint256) private _voterStake; // Maps voter address to their staked ETH amount
    mapping(uint256 => mapping(address => bool)) private _hasVoted; // paramId => voterAddress => bool (true if voted)
    uint256 private _stakeRequirement = 1 ether; // Default minimum stake to vote

    // Metadata
    string private _baseTokenURI;

    // Access Control
    address private _owner;
    mapping(address => bool) private _admins;

    // --- MODIFIERS ---
    modifier onlyOwner() {
        if (msg.sender != _owner) revert NotOwner();
        _;
    }

    modifier onlyAdmin() {
        if (msg.sender != _owner && !_admins[msg.sender]) revert NotAdmin();
        _;
    }

    modifier whenNotPaused() {
        if (_paused) revert Paused();
        _;
    }

    modifier whenPaused() {
        if (!_paused) revert NotPaused();
        _;
    }

    // --- CONSTRUCTOR ---
    constructor(string memory baseURI) {
        _owner = msg.sender;
        _paused = false;
        _currentTokenId = 0;
        _nextParamId = 0;
        _baseTokenURI = baseURI;
    }

    // --- ERC721 STANDARD FUNCTIONS (Basic Implementation) ---

    function ownerOf(uint256 tokenId) public view returns (address owner) {
        owner = _tokenOwners[tokenId];
        if (owner == address(0)) revert OwnerQueryForNonexistentToken(); // Standard ERC721 error
        return owner;
    }

    function balanceOf(address owner) public view returns (uint256) {
        if (owner == address(0)) revert ZeroAddress(); // Standard ERC721 error
        return _balances[owner];
    }

    function transferFrom(address from, address to, uint256 tokenId) public {
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        _safeTransfer(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) public {
        _safeTransfer(from, to, tokenId, data);
    }

    function approve(address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId); // Checks if token exists
        if (msg.sender != owner && !isApprovedForAll(owner, msg.sender)) revert ERC721IncorrectAllowance(); // Standard ERC721 error
        if (to == owner) revert ApproveToOwner();
        _approve(to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public {
        if (operator == msg.sender) revert ERC721InvalidOperator(); // Standard ERC721 error
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function getApproved(uint256 tokenId) public view returns (address) {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();
        return _tokenApprovals[tokenId];
    }

    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    // Helper to check if token exists
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _tokenOwners[tokenId] != address(0);
    }

    // Internal transfer logic
    function _transfer(address from, address to, uint256 tokenId) internal {
        if (_tokenOwners[tokenId] != from) revert TransferFromIncorrectOwner(); // Standard ERC721 error
        if (to == address(0)) revert TransferToZeroAddress();
        if (from == to) revert TransferToSelf(); // Added for clarity

        // Check permissions (approval or operator)
        if (msg.sender != from && getApproved(tokenId) != msg.sender && !isApprovedForAll(from, msg.sender)) {
            revert ERC721InsufficientApproval(); // Standard ERC721 error
        }

        // Clear approval for the token
        _approve(address(0), tokenId);

        // Update balances and ownership
        _balances[from]--;
        _balances[to]++;
        _tokenOwners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

     // Internal safe transfer logic (simplified external call check)
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal {
        _transfer(from, to, tokenId);

        if (to.code.length > 0) { // Check if recipient is a contract
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
                if (retval != IERC721Receiver.onERC721Received.selector) revert ERC721InvalidReceiver(); // Standard ERC721 error
            } catch (bytes memory reason) {
                 // Revert with the reason from the external call if possible, otherwise a default error
                if (reason.length > 0) {
                    // Using low-level call to get revert reason, but catching needs try/catch
                    // In pure Solidity 0.8, can't easily bubble up the exact reason bytes
                    // A simplified catchall revert or a specific error is common
                    revert ERC721InvalidReceiver(); // Use standard error or define custom
                } else {
                    revert ERC721InvalidReceiver(); // Default error
                }
            }
        }
    }

    // Internal approval logic
    function _approve(address to, uint256 tokenId) internal {
        _tokenApprovals[tokenId] = to;
        emit Approval(_tokenOwners[tokenId], to, tokenId); // Emit with current owner
    }

    // ERC165 Interface Support (Simplified)
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        // ERC721: 0x80ac58cd
        // ERC721Metadata: 0x5b5e139f
        // ERC165: 0x01ffc9a7
        return interfaceId == 0x80ac58cd || interfaceId == 0x5b5e139f || interfaceId == 0x01ffc9a7;
    }

    // IERC721Receiver interface (placeholder for _safeTransfer check)
    interface IERC721Receiver {
        function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
    }

    // Standard ERC721 Errors (Using standard names for clarity)
    error ERC721IncorrectAllowance();
    error ERC721InsufficientApproval();
    error ERC721InvalidApprover(address approver); // Custom error if needed, not strictly standard
    error ERC721InvalidOperator();
    error ERC721InvalidOwner(address owner); // Custom error if needed
    error ERC721InvalidReceiver();
    error ERC721InvalidSender(); // Custom error if needed
    error ERC721NonexistentToken(uint256 tokenId); // Custom error mapping Standard ERC721 error
    error OwnerQueryForNonexistentToken(); // Match OpenZeppelin's standard error

    // --- MINTING LOGIC ---

    /**
     * @dev Mints a new generative art token to the caller.
     * Requires minting to be unpaused.
     */
    function mint() public payable whenNotPaused returns (uint256) {
        uint256 newTokenId = _currentTokenId + 1;
        bytes32 seed = calculateSeed(newTokenId);

        // Basic ownership assignment (does not handle royalties, pricing etc.)
        _tokenOwners[newTokenId] = msg.sender;
        _balances[msg.sender]++;
        _currentTokenId = newTokenId;

        // Store the generated seed with the token
        _tokenSeeds[newTokenId] = seed;

        emit Transfer(address(0), msg.sender, newTokenId);
        emit Minted(newTokenId, msg.sender, seed);

        return newTokenId;
    }

    // --- GENERATIVE SEED LOGIC ---

    // Maps token ID to its generated seed
    mapping(uint256 => bytes32) private _tokenSeeds;

    /**
     * @dev Calculates a unique seed for a token based on current block data,
     * the token ID, and the data/weights of active parameters.
     * @param tokenId The ID of the token being minted.
     * @return A unique bytes32 seed.
     * @notice This method uses block data, which can be manipulated by miners/validators
     *         to a limited extent within a block. For high-security randomness,
     *         consider Chainlink VRF or similar. This is suitable for generative art
     *         where the reveal happens post-mint.
     */
    function calculateSeed(uint256 tokenId) internal view returns (bytes32) {
        bytes32 initialSeed = keccak256(abi.encodePacked(
            block.timestamp,
            block.difficulty, // block.basefee on PoS, block.difficulty on PoW
            msg.sender,
            tokenId
        ));

        bytes32 weightedSeed = initialSeed;

        // Incorporate active parameter data and weights into the seed
        for (uint256 i = 0; i < _activeParameterIds.length; i++) {
            uint256 paramId = _activeParameterIds[i];
            Param storage param = _parameters[paramId];

            // Simple influence based on weight: XORing hash of param data * weight
            // This is a simplified example; complex weighting needs careful design
            bytes32 paramHash = keccak256(param.paramData);

            // Use weight to determine influence - positive weights increase influence, negative decrease/reverse
            // A simple approach: repeat hashing or XORing based on weight magnitude,
            // or mix weight directly into the hashed value.
            // Let's mix weight directly into the hash calculation before XORing.
            bytes32 influentialParamHash = keccak256(abi.encodePacked(paramHash, param.weight, block.number, i)); // Add block/index for uniqueness per param

            // XOR the influential hash with the current seed
            weightedSeed = weightedSeed ^ influentialParamHash;
        }

        return weightedSeed;
    }

    /**
     * @dev Get the stored generative seed for a specific token.
     * @param tokenId The ID of the token.
     * @return The bytes32 seed.
     */
    function getSeedForToken(uint256 tokenId) public view returns (bytes32) {
        if (!_exists(tokenId)) revert InvalidTokenId(); // Or ERC721NonexistentToken()
        return _tokenSeeds[tokenId];
    }

    // --- PARAMETER MANAGEMENT & CURATION ---

    /**
     * @dev Allows a staked user to propose a new generative parameter for voting.
     * Requires the proposer to have the minimum stake.
     * @param paramData The data bytes for the new parameter.
     * @param paramType A string indicating how to interpret paramData (e.g., "color_array", "shape_algorithm").
     * @param name A human-readable name for the parameter.
     */
    function proposeParameter(bytes memory paramData, string memory paramType, string memory name) public {
        if (_voterStake[msg.sender] < _stakeRequirement) revert InsufficientStake();

        uint256 newParamId = _nextParamId++;
        _parameters[newParamId] = Param({
            id: newParamId,
            name: name,
            paramType: paramType,
            paramData: paramData,
            weight: 0, // Starts at 0 weight
            proposer: msg.sender,
            isActive: false, // Not active initially
            isProposed: true, // In proposed state
            yesVotes: 0,
            noVotes: 0,
            stakeRequiredToVote: _stakeRequirement // Snapshot stake requirement at time of proposal
        });

        _proposedParameterIds.push(newParamId);

        emit ParameterProposed(newParamId, msg.sender, name, paramType);
    }

     /**
      * @dev Allows a staked user to vote on a proposed parameter.
      * Requires the user to meet the stake requirement and not have voted already.
      * @param paramId The ID of the parameter to vote on.
      * @param support True for a 'yes' vote, false for a 'no' vote.
      */
    function voteForParameter(uint256 paramId, bool support) public {
        Param storage param = _parameters[paramId];
        if (!param.isProposed) revert ParameterNotProposed(); // Can only vote on proposed params
        if (_voterStake[msg.sender] < param.stakeRequiredToVote) revert InsufficientStake();
        if (_hasVoted[paramId][msg.sender]) revert AlreadyVoted();

        if (support) {
            param.yesVotes++;
        } else {
            param.noVotes++;
        }
        _hasVoted[paramId][msg.sender] = true;

        emit Voted(paramId, msg.sender, support);

        // Optional: Automatically process votes if a certain threshold or time passes
        // For this example, we'll leave processParameterVotes as a manual/admin call
    }

    /**
     * @dev Processes the votes for a proposed parameter.
     * Can be called by Admin/Owner (or potentially anyone after a voting period).
     * Moves parameter from proposed to active/inactive state and adjusts weight.
     * @param paramId The ID of the parameter to process.
     */
    function processParameterVotes(uint256 paramId) public onlyAdmin { // Make this callable based on governance logic later
        Param storage param = _parameters[paramId];
        if (!param.isProposed) revert ParameterNotProposed();
        // Add checks for minimum votes or voting period end here in a real system

        // Simple processing logic: If yes votes > no votes, activate and give initial weight based on net votes.
        // Otherwise, discard or mark as failed.
        int256 netVotes = int256(param.yesVotes) - int256(param.noVotes);

        if (netVotes > 0) {
            // Parameter is accepted
            param.isActive = true;
            param.weight = netVotes; // Initial weight based on net votes
            _activeParameterIds.push(paramId);
            emit ParameterStateChanged(paramId, true, param.weight);
        } else {
            // Parameter is rejected or tied
            param.isActive = false; // Explicitly set to inactive
             emit ParameterStateChanged(paramId, false, param.weight);
        }

        param.isProposed = false; // Mark as processed

        // Remove from proposed list (inefficient, but simple for example)
        for (uint256 i = 0; i < _proposedParameterIds.length; i++) {
            if (_proposedParameterIds[i] == paramId) {
                _proposedParameterIds[i] = _proposedParameterIds[_proposedParameterIds.length - 1];
                _proposedParameterIds.pop();
                break;
            }
        }

        // Clear voting data for this param (optional, could keep for history)
        // delete _hasVoted[paramId]; // This would clear all votes for this param
    }

    /**
     * @dev Allows Admin/Owner to directly update a parameter's weight.
     * Can be used to refine influence based on off-chain analysis or further governance.
     * @param paramId The ID of the parameter.
     * @param weightChange The amount to add to the current weight (can be negative).
     */
    function updateParameterWeight(uint256 paramId, int256 weightChange) public onlyAdmin {
        Param storage param = _parameters[paramId];
        // Add checks if paramId is valid
        param.weight += weightChange;
        emit ParameterStateChanged(paramId, param.isActive, param.weight);
    }

    /**
     * @dev Owner/Admin function to forcefully activate a parameter.
     * Useful for initial setup or overriding vote outcomes.
     * @param paramId The ID of the parameter.
     */
    function activateParameter(uint256 paramId) public onlyAdmin {
        Param storage param = _parameters[paramId];
         // Add checks if paramId is valid
        if (param.isActive) revert AlreadyActive();
        param.isActive = true;

        // Add to active list if not already there (check needed)
        bool found = false;
        for (uint256 i = 0; i < _activeParameterIds.length; i++) {
            if (_activeParameterIds[i] == paramId) {
                found = true;
                break;
            }
        }
        if (!found) {
             _activeParameterIds.push(paramId);
        }

        // Ensure it's not marked as proposed anymore
        if (param.isProposed) {
            param.isProposed = false;
             for (uint256 i = 0; i < _proposedParameterIds.length; i++) {
                if (_proposedParameterIds[i] == paramId) {
                    _proposedParameterIds[i] = _proposedParameterIds[_proposedParameterIds.length - 1];
                    _proposedParameterIds.pop();
                    break;
                }
            }
        }

        emit ParameterStateChanged(paramId, true, param.weight);
    }

    /**
     * @dev Owner/Admin function to forcefully deactivate a parameter.
     * Useful for removing undesirable parameters.
     * @param paramId The ID of the parameter.
     */
    function deactivateParameter(uint256 paramId) public onlyAdmin {
        Param storage param = _parameters[paramId];
         // Add checks if paramId is valid
        if (!param.isActive) revert AlreadyInactive();
        param.isActive = false;

         // Remove from active list (inefficient, but simple for example)
        for (uint256 i = 0; i < _activeParameterIds.length; i++) {
            if (_activeParameterIds[i] == paramId) {
                _activeParameterIds[i] = _activeParameterIds[_activeParameterIds.length - 1];
                _activeParameterIds.pop();
                break;
            }
        }

        emit ParameterStateChanged(paramId, false, param.weight);
    }

    /**
     * @dev Owner/Admin function to add a parameter directly without the proposal/voting process.
     * Useful for initial setup or adding core parameters.
     * @param paramData The data bytes for the new parameter.
     * @param paramType A string indicating how to interpret paramData.
     * @param name A human-readable name.
     * @param initialWeight The initial influence weight.
     * @param isActive Whether the parameter should be active immediately.
     */
    function addInitialParameter(bytes memory paramData, string memory paramType, string memory name, int256 initialWeight, bool isActive) public onlyOwner {
         // Basic check for potential duplicates (based on name and type maybe? Or just add unique ID)
        // For simplicity, we rely on unique auto-generated ID.
        uint256 newParamId = _nextParamId++;
         _parameters[newParamId] = Param({
            id: newParamId,
            name: name,
            paramType: paramType,
            paramData: paramData,
            weight: initialWeight,
            proposer: msg.sender, // Owner adds it
            isActive: isActive,
            isProposed: false, // Not proposed
            yesVotes: 0,
            noVotes: 0,
            stakeRequiredToVote: 0 // Not applicable
        });

        if (isActive) {
            _activeParameterIds.push(newParamId);
        }

        emit ParameterStateChanged(newParamId, isActive, initialWeight);
    }

     /**
      * @dev Owner/Admin function to remove a parameter entirely.
      * Use with caution, as it affects future generations.
      * @param paramId The ID of the parameter to remove.
      */
    function removeParameter(uint256 paramId) public onlyAdmin {
        Param storage param = _parameters[paramId];
        // Check if paramId exists
        // This is inefficient and should be used sparingly.
        if (param.isActive) {
             for (uint256 i = 0; i < _activeParameterIds.length; i++) {
                if (_activeParameterIds[i] == paramId) {
                    _activeParameterIds[i] = _activeParameterIds[_activeParameterIds.length - 1];
                    _activeParameterIds.pop();
                    break;
                }
            }
        }
         if (param.isProposed) {
             for (uint256 i = 0; i < _proposedParameterIds.length; i++) {
                if (_proposedParameterIds[i] == paramId) {
                    _proposedParameterIds[i] = _proposedParameterIds[_proposedParameterIds.length - 1];
                    _proposedParameterIds.pop();
                    break;
                }
            }
        }

        delete _parameters[paramId];
        // Also need to clear _hasVoted[paramId] if keeping historical votes
        // For simplicity, delete it here.
        delete _hasVoted[paramId];
         // No specific event for removal, ParameterStateChanged could signal deactivation first.
         // Could add ParameterRemoved event.
    }

    // --- STAKING LOGIC ---

    /**
     * @dev Allows users to stake ETH to gain voting rights.
     */
    function stakeForVoting() public payable {
        if (msg.value == 0) revert InvalidStakeAmount();
        _voterStake[msg.sender] += msg.value;
        emit StakeDeposited(msg.sender, msg.value);
    }

    /**
     * @dev Allows users to withdraw their staked ETH.
     * Placeholder for potential cooldowns or voting period restrictions.
     */
    function withdrawStake() public {
        uint256 amount = _voterStake[msg.sender];
        if (amount == 0) revert NothingToWithdraw();

        // Add cooldown or voting period checks here:
        // if (lastVoteTimestamp[msg.sender] + cooldown > block.timestamp) revert CannotWithdrawYet();

        _voterStake[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) {
            // Revert or handle failure, potentially returning stake
            _voterStake[msg.sender] = amount; // Return stake on failure
            // Could add an event for failed withdrawal attempt
             revert(); // Revert the transaction
        }
        emit StakeWithdrawn(msg.sender, amount);
    }

    // --- METADATA LOGIC ---

    /**
     * @dev Returns the metadata URI for a given token ID.
     * The URI structure is baseURI + tokenId.json.
     * Off-chain metadata server needs to retrieve the seed and parameters
     * for the token and generate JSON containing this data.
     * @param tokenId The ID of the token.
     * @return The metadata URI string.
     */
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        // Standard practice is baseURI + tokenId string
        // The metadata *at* this URI should include the token's seed and references to the parameter data.
        // Off-chain renderer uses seed + parameters to generate art.
        return string(abi.encodePacked(_baseTokenURI, Strings.toString(tokenId))); // Uses a simple toString helper
    }

    // Simple internal toString helper (simplified)
    library Strings {
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
                digits -= 1;
                buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
                value /= 10;
            }
            return string(buffer);
        }
    }

    /**
     * @dev Get the current base URI for metadata.
     */
    function getBaseURI() public view returns (string memory) {
        return _baseTokenURI;
    }


    // --- ADMIN & OWNER FUNCTIONS ---

    /**
     * @dev Transfers ownership of the contract.
     * Only the current owner can transfer ownership.
     * @param newOwner The address of the new owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner == address(0)) revert ZeroAddress();
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev Adds an address to the list of admins.
     * Admins have privileges like pausing or processing votes.
     * Only owner can add admins.
     * @param account The address to add as admin.
     */
    function addAdmin(address account) public onlyOwner {
         if (account == address(0)) revert ZeroAddress();
         _admins[account] = true;
         emit AdminAdded(account);
    }

     /**
      * @dev Removes an address from the list of admins.
      * Only owner can remove admins.
      * @param account The address to remove as admin.
      */
    function removeAdmin(address account) public onlyOwner {
         _admins[account] = false;
         emit AdminRemoved(account);
    }

    /**
     * @dev Pauses the minting process.
     * Only owner or admin can pause.
     */
    function pauseMinting() public onlyAdmin whenNotPaused {
        _paused = true;
        emit MintingPaused();
    }

    /**
     * @dev Unpauses the minting process.
     * Only owner or admin can unpause.
     */
    function unpauseMinting() public onlyAdmin whenPaused {
        _paused = false;
        emit MintingUnpaused();
    }

     /**
      * @dev Sets the base URI for token metadata.
      * Only owner or admin can set.
      * @param baseURI The new base URI.
      */
    function setBaseURI(string memory baseURI) public onlyAdmin {
        _baseTokenURI = baseURI;
        emit BaseURIUpdated(baseURI);
    }

    /**
     * @dev Sets the minimum stake required for users to vote on parameters.
     * Only owner or admin can set.
     * @param requiredStake The new minimum stake amount (in Wei).
     */
    function setStakeRequirement(uint256 requiredStake) public onlyAdmin {
        _stakeRequirement = requiredStake;
        // Consider adding an event for this
    }

    /**
     * @dev Allows the owner to rescue any ETH accidentally sent to the contract.
     * @param amount The amount of ETH to rescue.
     */
    function rescueETH(uint256 amount) public onlyOwner {
        if (amount == 0 || amount > address(this).balance) revert NothingToRescue();
        (bool success, ) = payable(_owner).call{value: amount}("");
        if (!success) revert(); // Revert on failure
        // Could add an event
    }

     /**
      * @dev Allows the owner to rescue any ERC20 tokens accidentally sent to the contract.
      * Needs the ERC20 interface (simplified here).
      * @param tokenAddress The address of the ERC20 token.
      * @param amount The amount of tokens to rescue.
      */
    function rescueFunds(address tokenAddress, uint256 amount) public onlyOwner {
        // Simplified ERC20 interface
        // interface IERC20 {
        //     function transfer(address to, uint256 amount) external returns (bool);
        //     function balanceOf(address account) external view returns (uint256);
        // }
        // require(tokenAddress != address(0), "Invalid token address"); // Or use ZeroAddress error
        // IERC20 token = IERC20(tokenAddress);
        // if (amount == 0 || amount > token.balanceOf(address(this))) revert NothingToRescue();
        // if (!token.transfer(_owner, amount)) revert(); // Revert on failure
        // Could add an event

        // Placeholder as the prompt asks not to duplicate Open Source; real implementation needs interface
        revert("Rescue not implemented (requires ERC20 interface)");
    }


    // --- VIEW FUNCTIONS ---

    /**
     * @dev Get the ID of the next token that will be minted.
     */
    function getCurrentTokenId() public view returns (uint256) {
        return _currentTokenId;
    }

     /**
      * @dev Get details of a specific parameter.
      * @param paramId The ID of the parameter.
      * @return Param struct details.
      */
    function getParameter(uint256 paramId) public view returns (Param memory) {
        // Could add a check if paramId exists: if (_parameters[paramId].id == 0 && paramId != 0) ...
        return _parameters[paramId];
    }

    /**
     * @dev Get the list of IDs for parameters currently influencing generation.
     */
    function getActiveParameterIds() public view returns (uint256[] memory) {
        return _activeParameterIds;
    }

     /**
      * @dev Get the list of IDs for parameters currently proposed and awaiting vote/processing.
      */
    function getProposedParameterIds() public view returns (uint256[] memory) {
        return _proposedParameterIds;
    }

     /**
      * @dev Get the stake amount of a user.
      * @param voter The address of the voter.
      */
    function getUserStake(address voter) public view returns (uint256) {
        return _voterStake[voter];
    }

     /**
      * @dev Check if a user has voted on a specific parameter.
      * @param paramId The ID of the parameter.
      * @param voter The address of the user.
      * @return True if the user has voted, false otherwise. (Note: does not return *how* they voted, just *if* they voted).
      */
    function getUserVote(uint256 paramId, address voter) public view returns (bool) {
        return _hasVoted[paramId][voter];
    }

     /**
      * @dev Get the current minimum stake required to vote.
      */
    function getStakeRequirement() public view returns (uint256) {
        return _stakeRequirement;
    }

    /**
     * @dev Check if minting is currently paused.
     */
    function isPaused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Check if an address is the contract owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

     /**
      * @dev Check if an address is an admin.
      * @param account The address to check.
      */
    function isAdmin(address account) public view returns (bool) {
        return _admins[account];
    }
}
```