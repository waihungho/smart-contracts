Okay, let's design a smart contract that combines several advanced and trendy concepts: **Dynamic Reputation, Time-Based Mechanics, NFT Attribute Derivation, and Reputation-Weighted Governance.**

The core idea is a system where users stake tokens (`IERC20`) to earn reputation points. This reputation is dynamic, decaying over time if not maintained by active staking. The user's reputation directly influences the characteristics (simulated attributes) of a linked Non-Fungible Token (`IERC721`). Furthermore, reputation points grant voting power in a decentralized governance system that controls core contract parameters. Users can also spend staked tokens or reputation on "enhancements" that boost their reputation or influence NFT attributes.

This avoids directly copying standard ERCs or common DeFi/DAO templates while integrating elements from those domains in a novel way.

---

## Contract Outline: `ReputationForge`

This contract implements a system for earning dynamic reputation through token staking, linking that reputation to NFT attributes, and enabling reputation-weighted governance.

1.  **State Variables:** Stores contract parameters, user data (stake info, reputation, linked NFT), governance proposals, and enhancement types.
2.  **Events:** Logs key actions like staking, unstaking, reputation updates, NFT minting/linking, enhancement application, and governance actions.
3.  **Errors:** Custom errors for clearer failure reasons.
4.  **Structs:** Define structures for `UserInfo`, `Proposal`, and `EnhancementType`.
5.  **Libraries/Interfaces:** Imports for ERC20, ERC721, SafeMath (via Solidity 0.8+ built-in overflow checks), and Ownable.
6.  **Constructor:** Initializes contract owner, required token/NFT addresses, and initial parameters.
7.  **Admin/Parameter Management:** Functions for the owner (initially) or successful governance proposals to set contract parameters.
8.  **Staking & Reputation:**
    *   Stake tokens for a minimum duration.
    *   Unstake tokens, calculating earned reputation and applying decay.
    *   Claim earned reputation without unstaking.
    *   Internal function to calculate and update user reputation, applying time-based decay.
9.  **NFT Integration:**
    *   Mint or link a profile NFT to a user address (requires initial stake/reputation).
    *   Internal function to trigger NFT attribute update based on reputation changes (simulated).
    *   View function to get derived NFT attributes based on current reputation.
10. **Enhancements:**
    *   Apply different types of enhancements by spending staked tokens or reputation.
11. **Governance:**
    *   Propose changes to contract parameters (requires minimum reputation).
    *   Vote on active proposals (vote weight based on reputation).
    *   Execute successful proposals.
12. **View Functions:** Provide information about user status, contract parameters, proposals, etc.
13. **Utility:** Function to rescue erroneously sent tokens.

---

## Function Summary:

1.  `constructor(address _stakingToken, address _profileNFT, ...)`: Initializes the contract.
2.  `setMinStakingDuration(uint64 _duration)`: Sets the minimum duration required for staking.
3.  `setReputationDecayRate(uint32 _rate)`: Sets the decay rate for reputation points (e.g., points lost per second).
4.  `setReputationStakeMultiplier(uint32 _multiplier)`: Sets the multiplier for reputation earned per token per unit of time.
5.  `addEnhancementType(uint8 _typeId, uint256 _tokenCost, uint256 _reputationCost, uint256 _reputationBoost, uint64 _duration)`: Defines a new enhancement type and its effects/costs.
6.  `updateEnhancementType(uint8 _typeId, ...)`: Modifies an existing enhancement type.
7.  `removeEnhancementType(uint8 _typeId)`: Removes an enhancement type.
8.  `stake(uint256 amount)`: Stakes `amount` of the staking token.
9.  `unstake()`: Unstakes tokens, calculates and updates reputation, and withdraws tokens.
10. `claimReputationRewards()`: Calculates and updates reputation earned from current stake without unstaking.
11. `_updateReputation(address user)`: Internal function to calculate decay and earned reputation, updating user state.
12. `mintProfileNFT()`: Mints or links a profile NFT to the calling address (requires minimum stake/reputation).
13. `_triggerNFTAttributeUpdate(uint256 tokenId, uint256 currentReputation)`: Internal (simulated) function to notify the NFT contract or log event for attribute updates.
14. `applyEnhancement(uint8 _typeId)`: Applies an enhancement using staked tokens or reputation.
15. `proposeParameterChange(uint8 _paramType, uint256 _newValue, string memory _description)`: Creates a new governance proposal to change a contract parameter.
16. `voteOnProposal(uint256 _proposalId, bool _support)`: Votes on a proposal using reputation weight.
17. `executeProposal(uint256 _proposalId)`: Executes a successful proposal.
18. `getUserInfo(address user)`: Views staking and reputation information for a user.
19. `getReputation(address user)`: Views the user's *current* reputation (calculated with decay).
20. `getDerivedNFTAttributes(uint256 tokenId)`: Views the derived attributes for an NFT based on the linked user's current reputation.
21. `getContractParameters()`: Views all current governance-controlled parameters.
22. `getEnhancementType(uint8 _typeId)`: Views details of a specific enhancement type.
23. `getProposalInfo(uint256 _proposalId)`: Views details of a governance proposal.
24. `getProposalVoteCount(uint256 _proposalId)`: Views current vote counts for a proposal.
25. `rescueTokens(address _token, uint256 _amount)`: Allows owner to rescue erroneously sent tokens.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Metadata.sol"; // To simulate metadata updates
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol"; // Good practice

// --- Contract Outline: ReputationForge ---
// This contract implements a system for earning dynamic reputation through token staking,
// linking that reputation to NFT attributes, and enabling reputation-weighted governance.
//
// 1. State Variables: Stores contract parameters, user data, governance proposals, enhancement types.
// 2. Events: Logs key actions.
// 3. Errors: Custom errors for clearer failure reasons.
// 4. Structs: Define UserInfo, Proposal, and EnhancementType structures.
// 5. Libraries/Interfaces: Imports for ERC20, ERC721, SafeMath (built-in), Ownable, ReentrancyGuard.
// 6. Constructor: Initializes owner, token/NFT addresses, and initial parameters.
// 7. Admin/Parameter Management: Functions to set contract parameters (initially owner, later via governance).
// 8. Staking & Reputation: Functions for staking, unstaking, claiming reputation, and internal reputation updates.
// 9. NFT Integration: Functions to mint/link NFT and trigger attribute updates.
// 10. Enhancements: Functions to apply enhancements.
// 11. Governance: Functions to propose, vote, and execute parameter changes.
// 12. View Functions: Provide information about state, users, proposals.
// 13. Utility: Function to rescue erroneously sent tokens.

// --- Function Summary: ---
// 1.  constructor(...): Initializes the contract.
// 2.  setMinStakingDuration(...): Sets min staking duration.
// 3.  setReputationDecayRate(...): Sets reputation decay rate.
// 4.  setReputationStakeMultiplier(...): Sets reputation earning multiplier.
// 5.  addEnhancementType(...): Defines a new enhancement type.
// 6.  updateEnhancementType(...): Modifies an existing enhancement type.
// 7.  removeEnhancementType(...): Removes an enhancement type.
// 8.  stake(...): Stakes tokens.
// 9.  unstake(): Unstakes tokens, updates reputation.
// 10. claimReputationRewards(): Claims earned reputation from stake.
// 11. _updateReputation(...): Internal reputation calculation and update.
// 12. mintProfileNFT(): Mints/links user profile NFT.
// 13. _triggerNFTAttributeUpdate(...): Internal (simulated) NFT update trigger.
// 14. applyEnhancement(...): Applies an enhancement.
// 15. proposeParameterChange(...): Creates a governance proposal.
// 16. voteOnProposal(...): Votes on a proposal.
// 17. executeProposal(...): Executes a successful proposal.
// 18. getUserInfo(...): Views user staking and reputation info.
// 19. getReputation(...): Views user's current reputation (with decay).
// 20. getDerivedNFTAttributes(...): Views NFT attributes based on reputation.
// 21. getContractParameters(): Views all current parameters.
// 22. getEnhancementType(...): Views enhancement type details.
// 23. getProposalInfo(...): Views proposal details.
// 24. getProposalVoteCount(...): Views current vote counts for a proposal.
// 25. rescueTokens(...): Rescues erroneously sent tokens.

contract ReputationForge is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;

    // --- State Variables ---

    IERC20 public immutable stakingToken;
    IERC721 public immutable profileNFT; // Assumes this is the NFT contract we interact with

    // Contract Parameters (governable)
    uint64 public minStakingDuration = 7 days; // Minimum duration required to unstake and earn reputation
    uint32 public reputationDecayRate = 1; // Reputation points lost per second if not staking (simplified)
    uint32 public reputationStakeMultiplier = 100; // Reputation points earned per token staked per second (scaled)
    uint256 public minReputationForNFTMint = 1000; // Reputation needed to mint/link NFT
    uint256 public minReputationForProposal = 5000; // Reputation needed to create a proposal
    uint64 public constant VOTING_PERIOD_DURATION = 3 days; // How long voting is open for a proposal
    uint256 public constant QUORUM_REPUTATION_PERCENTAGE = 5; // % of total reputation needed to vote

    // User Data
    struct UserInfo {
        uint256 stakedAmount;
        uint66 lastStakeStartTime; // Using uint66 for timestamp (seconds since epoch)
        uint256 reputationPoints;
        uint66 lastReputationUpdate; // Timestamp of last reputation calculation
        uint256 linkedNFTId; // 0 if no NFT linked
        mapping(uint8 => uint66) activeEnhancements; // enhancementTypeId => expiryTimestamp
    }
    mapping(address => UserInfo) public users;

    // Enhancements
    struct EnhancementType {
        uint256 tokenCost;
        uint256 reputationCost;
        uint256 reputationBoost; // Instant reputation gain upon application
        uint64 duration; // Duration of effect (e.g., multiplier boost), 0 for instant
        bool exists; // To check if typeId is valid
    }
    mapping(uint8 => EnhancementType) public enhancementTypes;
    uint8[] public availableEnhancementTypeIds;

    // Governance
    struct Proposal {
        address proposer;
        uint8 paramType; // e.g., 0: minStakingDuration, 1: decayRate, 2: stakeMultiplier, 3: minRepForNFT, 4: minRepForProposal
        uint256 newValue;
        string description;
        uint256 totalReputationSupplyAtProposal; // Snapshot of total reputation
        uint256 supportReputation; // Total reputation points voting 'yes'
        uint256 againstReputation; // Total reputation points voting 'no'
        uint66 votingDeadline; // Timestamp when voting ends
        bool executed;
        mapping(address => bool) hasVoted;
    }
    Counters.Counter private _proposalIds;
    mapping(uint256 => Proposal) public proposals;

    uint256 private _totalReputationSupply; // Keep track of total reputation for quorum calculation

    // --- Events ---

    event Staked(address indexed user, uint256 amount, uint66 startTime);
    event Unstaked(address indexed user, uint256 amount, uint256 earnedReputation);
    event ReputationClaimed(address indexed user, uint256 earnedReputation);
    event ReputationUpdated(address indexed user, uint256 newReputation, uint256 decayApplied);
    event NFTMintedOrLinked(address indexed user, uint256 tokenId);
    event EnhancementApplied(address indexed user, uint8 typeId, uint256 reputationCost, uint256 tokenCost);
    event ParameterChanged(uint8 paramType, uint256 oldValue, uint256 newValue);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, uint8 paramType, uint256 newValue, string description, uint66 votingDeadline);
    event Voted(uint256 indexed proposalId, address indexed voter, uint256 voteWeight, bool support);
    event ProposalExecuted(uint256 indexed proposalId);
    event NFTAttributeUpdateTriggered(uint256 indexed tokenId, uint256 currentReputation); // Simulate trigger

    // --- Errors ---

    error NotEnoughStaked(address user, uint256 required, uint256 available);
    error NotEnoughReputation(address user, uint256 required, uint256 available);
    error MinStakingDurationNotMet(address user, uint66 startTime, uint66 minDuration);
    error AlreadyStaking(address user);
    error NoActiveStake(address user);
    error NFTAlreadyLinked(address user, uint256 tokenId);
    error NoNFTLinked(address user);
    error InvalidEnhancementType(uint8 typeId);
    error EnhancementStillActive(address user, uint8 typeId);
    error ProposalDoesNotExist(uint256 proposalId);
    error ProposalVotingPeriodInactive(uint256 proposalId);
    error ProposalAlreadyExecuted(uint256 proposalId);
    error UserAlreadyVoted(address user, uint256 proposalId);
    error InsufficientReputationToVote(address user, uint256 required);
    error ProposalNotPassed(uint256 proposalId);
    error InsufficientQuorum(uint256 proposalId, uint256 quorumRequired, uint256 currentSupport + uint256 currentAgainst);
    error InvalidParameterType(uint8 paramType);
    error ZeroAddress(address addr);

    // --- Structs ---
    // UserInfo struct defined above

    // Proposal struct defined above

    // EnhancementType struct defined above

    // --- Constructor ---

    constructor(address _stakingToken, address _profileNFT) Ownable(msg.sender) {
        if (_stakingToken == address(0)) revert ZeroAddress(address(0));
        if (_profileNFT == address(0)) revert ZeroAddress(address(0));
        stakingToken = IERC20(_stakingToken);
        profileNFT = IERC721(_profileNFT);
    }

    // --- Admin / Parameter Management ---
    // Initial setters by owner. These can later be changed via governance proposals.

    function setMinStakingDuration(uint64 _duration) external onlyOwner {
        emit ParameterChanged(0, minStakingDuration, _duration);
        minStakingDuration = _duration;
    }

    function setReputationDecayRate(uint32 _rate) external onlyOwner {
        emit ParameterChanged(1, reputationDecayRate, _rate);
        reputationDecayRate = _rate;
    }

    function setReputationStakeMultiplier(uint32 _multiplier) external onlyOwner {
         emit ParameterChanged(2, reputationStakeMultiplier, _multiplier);
        reputationStakeMultiplier = _multiplier;
    }

    function setMinReputationForNFTMint(uint256 _reputation) external onlyOwner {
        emit ParameterChanged(3, minReputationForNFTMint, _reputation);
        minReputationForNFTMint = _reputation;
    }

     function setMinReputationForProposal(uint256 _reputation) external onlyOwner {
        emit ParameterChanged(4, minReputationForProposal, _reputation);
        minReputationForProposal = _reputation;
    }

    function addEnhancementType(uint8 _typeId, uint256 _tokenCost, uint256 _reputationCost, uint256 _reputationBoost, uint64 _duration) external onlyOwner {
        if (enhancementTypes[_typeId].exists) revert InvalidEnhancementType(_typeId); // Type ID already exists
        enhancementTypes[_typeId] = EnhancementType(_tokenCost, _reputationCost, _reputationBoost, _duration, true);
        availableEnhancementTypeIds.push(_typeId);
    }

    function updateEnhancementType(uint8 _typeId, uint256 _tokenCost, uint256 _reputationCost, uint256 _reputationBoost, uint64 _duration) external onlyOwner {
        if (!enhancementTypes[_typeId].exists) revert InvalidEnhancementType(_typeId);
        enhancementTypes[_typeId] = EnhancementType(_tokenCost, _reputationCost, _reputationBoost, _duration, true);
    }

    function removeEnhancementType(uint8 _typeId) external onlyOwner {
         if (!enhancementTypes[_typeId].exists) revert InvalidEnhancementType(_typeId);
         delete enhancementTypes[_typeId];
         // Simple removal from array (inefficient for large arrays, better to swap and pop)
         for (uint i = 0; i < availableEnhancementTypeIds.length; i++) {
             if (availableEnhancementTypeIds[i] == _typeId) {
                 availableEnhancementTypeIds[i] = availableEnhancementTypeIds[availableEnhancementTypeIds.length - 1];
                 availableEnhancementTypeIds.pop();
                 break;
             }
         }
    }

    // --- Staking & Reputation ---

    function stake(uint256 amount) external nonReentrant {
        UserInfo storage user = users[msg.sender];
        if (user.stakedAmount > 0) revert AlreadyStaking(msg.sender);
        if (amount == 0) revert NotEnoughStaked(msg.sender, 1, 0); // Amount must be positive

        // Ensure enough tokens are approved/sent before transferFrom
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);

        user.stakedAmount = amount;
        user.lastStakeStartTime = uint66(block.timestamp);
        // Initialize last reputation update time if first stake or after unstake
        if (user.lastReputationUpdate == 0) {
            user.lastReputationUpdate = uint66(block.timestamp);
        }

        emit Staked(msg.sender, amount, user.lastStakeStartTime);
    }

    function unstake() external nonReentrant {
        UserInfo storage user = users[msg.sender];
        if (user.stakedAmount == 0) revert NoActiveStake(msg.sender);
        if (block.timestamp < user.lastStakeStartTime + minStakingDuration) {
             revert MinStakingDurationNotMet(msg.sender, user.lastStakeStartTime, minStakingDuration);
        }

        uint256 stakedAmount = user.stakedAmount;
        user.stakedAmount = 0; // Reset staked amount first
        user.lastStakeStartTime = 0; // Reset start time

        // Calculate and update reputation before transferring tokens
        _updateReputation(msg.sender);

        // Transfer tokens back
        stakingToken.safeTransfer(msg.sender, stakedAmount);

        emit Unstaked(msg.sender, stakedAmount, user.reputationPoints - getUserReputationWithoutDecay(msg.sender) + getReputation(msg.sender)); // Approximate earned reputation
    }

    function claimReputationRewards() external {
        UserInfo storage user = users[msg.sender];
        if (user.stakedAmount == 0) revert NoActiveStake(msg.sender);

        // Calculate and update reputation
        _updateReputation(msg.sender);

        emit ReputationClaimed(msg.sender, user.reputationPoints); // Emitting new total reputation, not just earned this claim
    }

    /// @notice Internal function to calculate and update user reputation, applying decay and earning rewards.
    /// @param user The address of the user whose reputation to update.
    function _updateReputation(address user) internal {
        UserInfo storage userInfo = users[user];
        uint66 currentTime = uint66(block.timestamp);
        uint66 lastUpdate = userInfo.lastReputationUpdate;
        uint256 currentReputation = userInfo.reputationPoints;

        if (currentTime > lastUpdate) {
            uint64 timePassed = currentTime - lastUpdate;

            // Apply decay
            if (userInfo.stakedAmount == 0) { // Decay only applies when not staking
                uint256 decayAmount = uint256(timePassed) * reputationDecayRate;
                if (currentReputation > decayAmount) {
                    currentReputation -= decayAmount;
                } else {
                    currentReputation = 0;
                }
            }

            // Apply earned reputation if staking
            if (userInfo.stakedAmount > 0) {
                 // Earned reputation based on staked amount and time since last update
                uint256 earned = userInfo.stakedAmount * uint256(timePassed) * reputationStakeMultiplier;
                currentReputation += earned / 1e18; // Assume multiplier is scaled or use appropriate division
                 // Note: This simple formula might need refinement based on desired tokenomics
            }

            uint256 decayApplied = userInfo.reputationPoints > currentReputation ? userInfo.reputationPoints - currentReputation : 0;
            userInfo.reputationPoints = currentReputation;
            userInfo.lastReputationUpdate = currentTime;
             _totalReputationSupply = _totalReputationSupply - userInfo.reputationPoints + currentReputation; // Simple update, assumes no overflow/underflow complexities

            emit ReputationUpdated(user, currentReputation, decayApplied);

             // Trigger NFT update simulation if NFT exists
            if (userInfo.linkedNFTId != 0) {
                _triggerNFTAttributeUpdate(userInfo.linkedNFTId, currentReputation);
            }
        }
    }

    // --- NFT Integration ---

    function mintProfileNFT() external nonReentrant {
        UserInfo storage user = users[msg.sender];
        if (user.linkedNFTId != 0) revert NFTAlreadyLinked(msg.sender, user.linkedNFTId);

        // Ensure reputation is updated before checking threshold
        _updateReputation(msg.sender);

        if (user.reputationPoints < minReputationForNFTMint) {
            revert NotEnoughReputation(msg.sender, minReputationForNFTMint, user.reputationPoints);
        }

        // Simulate minting/linking: The actual mint must happen on the profileNFT contract.
        // This function would typically *call* the mint function on the profileNFT contract.
        // For this example, we'll just store the *expected* NFT ID (e.g., based on total minted on that contract)
        // and rely on the NFT contract's logic to handle the actual minting and metadata.

        // *** SIMULATION ***
        // In a real scenario, this would be a cross-contract call:
        // uint256 newTokenId = profileNFT.safeMint(msg.sender); // Example function call
        // user.linkedNFTId = newTokenId;

        // For this example, let's assume the profileNFT contract has a `linkNFT(address user)`
        // function that mints/assigns an NFT and returns its ID, and only this contract can call it.
        // Or, the user could mint it themselves and *then* link it here via a separate function
        // like `linkExistingNFT(uint256 tokenId)`. Let's go with the latter for simplicity,
        // modifying this function to check if the user owns the NFT they are trying to link.

        revert("Use linkExistingNFT function instead"); // Placeholder to force use of link function

        // *** END SIMULATION ***
    }

    function linkExistingNFT(uint256 _tokenId) external nonReentrant {
         UserInfo storage user = users[msg.sender];
         if (user.linkedNFTId != 0) revert NFTAlreadyLinked(msg.sender, user.linkedNFTId);

         // Verify user owns the NFT
         if (IERC721(profileNFT).ownerOf(_tokenId) != msg.sender) {
             revert("Must own the NFT to link it"); // More specific error
         }

         // Ensure reputation is updated before checking threshold
         _updateReputation(msg.sender);

         if (user.reputationPoints < minReputationForNFTMint) {
            revert NotEnoughReputation(msg.sender, minReputationForNFTMint, user.reputationPoints);
         }

         user.linkedNFTId = _tokenId;
         emit NFTMintedOrLinked(msg.sender, _tokenId);

         // Trigger initial attribute update simulation
         _triggerNFTAttributeUpdate(_tokenId, user.reputationPoints);
    }


    /// @notice Internal (simulated) function to trigger an update on the linked NFT contract.
    /// @param tokenId The ID of the NFT to update.
    /// @param currentReputation The user's current reputation influencing attributes.
    function _triggerNFTAttributeUpdate(uint256 tokenId, uint256 currentReputation) internal {
        // This function simulates triggering a metadata update on the linked NFT contract.
        // A real implementation would involve:
        // 1. The profileNFT contract implementing a function like `updateAttributes(uint256 tokenId, uint256 reputation)`.
        // 2. This contract calling that function: `IERC721Metadata(profileNFT).updateAttributes(tokenId, currentReputation);` (Assuming the NFT contract uses ERC721Metadata interface or a custom one).
        // 3. The NFT contract's `tokenURI` function would then read this updated state to return the correct metadata JSON.

        // For this example, we just emit an event. The off-chain metadata service
        // watching these events would then update the NFT's metadata.
        emit NFTAttributeUpdateTriggered(tokenId, currentReputation);
    }

    // --- Enhancements ---

    function applyEnhancement(uint8 _typeId) external nonReentrant {
        UserInfo storage user = users[msg.sender];
        EnhancementType storage enh = enhancementTypes[_typeId];

        if (!enh.exists) revert InvalidEnhancementType(_typeId);
        if (user.activeEnhancements[_typeId] > block.timestamp) revert EnhancementStillActive(msg.sender, _typeId);

        // Ensure reputation is updated before spending it
        _updateReputation(msg.sender);

        if (user.reputationPoints < enh.reputationCost) {
            revert NotEnoughReputation(msg.sender, enh.reputationCost, user.reputationPoints);
        }
        if (user.stakedAmount < enh.tokenCost) {
             revert NotEnoughStaked(msg.sender, enh.tokenCost, user.stakedAmount);
        }

        // Deduct costs
        user.reputationPoints -= enh.reputationCost;
        user.stakedAmount -= enh.tokenCost; // Deduct from staked balance

        // Apply effects
        if (enh.reputationBoost > 0) {
             user.reputationPoints += enh.reputationBoost;
        }
        if (enh.duration > 0) {
            user.activeEnhancements[_typeId] = uint66(block.timestamp + enh.duration);
        }

        user.lastReputationUpdate = uint66(block.timestamp); // Update timestamp as reputation changed
        _totalReputationSupply -= enh.reputationCost; // Deduct from total supply
        _totalReputationSupply += enh.reputationBoost; // Add boost to total supply

        emit EnhancementApplied(msg.sender, _typeId, enh.reputationCost, enh.tokenCost);

         // Trigger NFT update simulation
        if (user.linkedNFTId != 0) {
            _triggerNFTAttributeUpdate(user.linkedNFTId, user.reputationPoints);
        }
    }

    // --- Governance ---

    function proposeParameterChange(uint8 _paramType, uint256 _newValue, string memory _description) external nonReentrant {
        UserInfo storage user = users[msg.sender];
        _updateReputation(msg.sender); // Update reputation before checking proposal threshold

        if (user.reputationPoints < minReputationForProposal) {
            revert NotEnoughReputation(msg.sender, minReputationForProposal, user.reputationPoints);
        }

        // Basic validation for paramType
        if (_paramType > 4) revert InvalidParameterType(_paramType);

        _proposalIds.increment();
        uint256 proposalId = _proposalIds.current();

        proposals[proposalId] = Proposal({
            proposer: msg.sender,
            paramType: _paramType,
            newValue: _newValue,
            description: _description,
            totalReputationSupplyAtProposal: _totalReputationSupply, // Snapshot total supply
            supportReputation: 0,
            againstReputation: 0,
            votingDeadline: uint66(block.timestamp + VOTING_PERIOD_DURATION),
            executed: false,
            hasVoted: new mapping(address => bool) // Initialize the mapping
        });

        emit ProposalCreated(proposalId, msg.sender, _paramType, _newValue, _description, proposals[proposalId].votingDeadline);
    }

    function voteOnProposal(uint256 _proposalId, bool _support) external {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.proposer == address(0)) revert ProposalDoesNotExist(_proposalId); // Check if proposal exists
        if (block.timestamp > proposal.votingDeadline) revert ProposalVotingPeriodInactive(_proposalId);
        if (proposal.executed) revert ProposalAlreadyExecuted(_proposalId);
        if (proposal.hasVoted[msg.sender]) revert UserAlreadyVoted(msg.sender, _proposalId);

        // Update reputation before getting vote weight
        _updateReputation(msg.sender);
        UserInfo storage user = users[msg.sender];
        uint256 voteWeight = user.reputationPoints;

        if (voteWeight == 0) revert InsufficientReputationToVote(msg.sender, 1); // Need at least some reputation to vote

        if (_support) {
            proposal.supportReputation += voteWeight;
        } else {
            proposal.againstReputation += voteWeight;
        }

        proposal.hasVoted[msg.sender] = true;

        emit Voted(_proposalId, msg.sender, voteWeight, _support);
    }

    function executeProposal(uint256 _proposalId) external nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.proposer == address(0)) revert ProposalDoesNotExist(_proposalId);
        if (block.timestamp <= proposal.votingDeadline) revert ProposalVotingPeriodInactive(_proposalId);
        if (proposal.executed) revert ProposalAlreadyExecuted(_proposalId);

        // Check if proposal passed (simple majority by reputation)
        if (proposal.supportReputation <= proposal.againstReputation) revert ProposalNotPassed(_proposalId);

        // Check quorum: Total reputation voting must be > a percentage of the total reputation supply at proposal creation
        uint256 totalVotesReputation = proposal.supportReputation + proposal.againstReputation;
        uint256 quorumRequired = (proposal.totalReputationSupplyAtProposal * QUORUM_REPUTATION_PERCENTAGE) / 100; // Simple %
        if (totalVotesReputation < quorumRequired) {
             revert InsufficientQuorum(_proposalId, quorumRequired, totalVotesReputation);
        }

        // Execute the parameter change
        uint8 paramType = proposal.paramType;
        uint256 newValue = proposal.newValue;

        if (paramType == 0) { // minStakingDuration
            emit ParameterChanged(paramType, minStakingDuration, newValue);
            minStakingDuration = uint64(newValue);
        } else if (paramType == 1) { // reputationDecayRate
            emit ParameterChanged(paramType, reputationDecayRate, newValue);
            reputationDecayRate = uint32(newValue);
        } else if (paramType == 2) { // reputationStakeMultiplier
             emit ParameterChanged(paramType, reputationStakeMultiplier, newValue);
            reputationStakeMultiplier = uint32(newValue);
        } else if (paramType == 3) { // minReputationForNFTMint
             emit ParameterChanged(paramType, minReputationForNFTMint, newValue);
            minReputationForNFTMint = newValue;
        } else if (paramType == 4) { // minReputationForProposal
             emit ParameterChanged(paramType, minReputationForProposal, newValue);
            minReputationForProposal = newValue;
        } else {
             revert InvalidParameterType(paramType); // Should not happen due to propose validation
        }

        proposal.executed = true;
        emit ProposalExecuted(_proposalId);
    }

    // --- View Functions ---

    /// @notice Gets user staking and reputation information. Automatically updates reputation first.
    /// @param user The address of the user.
    /// @return stakedAmount, lastStakeStartTime, reputationPoints, lastReputationUpdate, linkedNFTId
    function getUserInfo(address user) external returns (uint256, uint66, uint256, uint66, uint256) {
         _updateReputation(user); // Ensure reputation is fresh
         UserInfo storage userInfo = users[user];
         return (userInfo.stakedAmount, userInfo.lastStakeStartTime, userInfo.reputationPoints, userInfo.lastReputationUpdate, userInfo.linkedNFTId);
    }

    /// @notice Gets the user's current reputation points, calculated with decay.
    /// @param user The address of the user.
    /// @return The current calculated reputation points.
    function getReputation(address user) public returns (uint256) {
        UserInfo storage userInfo = users[user];
        uint256 currentRep = userInfo.reputationPoints;
        uint66 lastUpdate = userInfo.lastReputationUpdate;

        if (currentRep == 0 || lastUpdate == 0 || userInfo.stakedAmount > 0) {
            // No decay if 0 reputation, never updated, or currently staking
             return currentRep;
        }

        uint66 currentTime = uint66(block.timestamp);
        if (currentTime > lastUpdate) {
             uint64 timePassed = currentTime - lastUpdate;
             uint256 decayAmount = uint256(timePassed) * reputationDecayRate;
             if (currentRep > decayAmount) {
                currentRep -= decayAmount;
             } else {
                currentRep = 0;
             }
        }
        return currentRep;
    }

     /// @notice Gets the user's reputation points *without* applying decay. Useful for calculating earned amount.
    /// @param user The address of the user.
    /// @return The reputation points before decay calculation.
    function getUserReputationWithoutDecay(address user) public view returns (uint256) {
        return users[user].reputationPoints;
    }


    /// @notice Gets the derived attributes for an NFT based on the linked user's current reputation.
    /// @param tokenId The ID of the NFT.
    /// @return An array of simulated attribute values (e.g., [level, color_trait, power_stat]).
    function getDerivedNFTAttributes(uint256 tokenId) external returns (uint256[] memory) {
        address owner = profileNFT.ownerOf(tokenId); // Get current owner from the NFT contract
        UserInfo storage user = users[owner];

        if (user.linkedNFTId != tokenId) {
            revert("NFT not linked to this user in this contract");
        }

        // Ensure user's reputation is updated first
        _updateReputation(owner);
        uint256 userReputation = user.reputationPoints;

        // --- Simulate Attribute Derivation Logic ---
        // This is where you define how reputation maps to NFT traits.
        // Example:
        // - Level is reputation / 1000
        // - Color trait based on reputation range
        // - Power stat = sqrt(reputation) * 10
        // - Etc.

        uint256 level = userReputation / 1000;
        uint256 colorTrait = userReputation % 5; // Simple mapping to 5 colors
        uint256 powerStat = uint256(Math.sqrt(userReputation)) * 10;

        // Add more derived attributes as needed based on your NFT design
        uint256[] memory attributes = new uint256[](3); // Adjust size based on number of attributes
        attributes[0] = level;
        attributes[1] = colorTrait;
        attributes[2] = powerStat;

        return attributes;
    }

    /// @notice Gets all current governance-controlled contract parameters.
    /// @return An array of parameter values (order corresponds to paramType in proposals).
    function getContractParameters() external view returns (uint256[] memory) {
        uint256[] memory params = new uint256[](5);
        params[0] = minStakingDuration;
        params[1] = reputationDecayRate;
        params[2] = reputationStakeMultiplier;
        params[3] = minReputationForNFTMint;
        params[4] = minReputationForProposal;
        return params;
    }

     /// @notice Gets details of a specific enhancement type.
    /// @param _typeId The ID of the enhancement type.
    /// @return tokenCost, reputationCost, reputationBoost, duration, exists
    function getEnhancementType(uint8 _typeId) external view returns (uint256, uint256, uint256, uint64, bool) {
         EnhancementType storage enh = enhancementTypes[_typeId];
         return (enh.tokenCost, enh.reputationCost, enh.reputationBoost, enh.duration, enh.exists);
    }

     /// @notice Gets details of a governance proposal.
    /// @param _proposalId The ID of the proposal.
    /// @return proposer, paramType, newValue, description, totalReputationSupplyAtProposal, supportReputation, againstReputation, votingDeadline, executed
    function getProposalInfo(uint256 _proposalId) external view returns (address, uint8, uint256, string memory, uint256, uint256, uint256, uint66, bool) {
         Proposal storage proposal = proposals[_proposalId];
         return (proposal.proposer, proposal.paramType, proposal.newValue, proposal.description, proposal.totalReputationSupplyAtProposal, proposal.supportReputation, proposal.againstReputation, proposal.votingDeadline, proposal.executed);
    }

     /// @notice Gets the current support and against reputation vote counts for a proposal.
    /// @param _proposalId The ID of the proposal.
    /// @return supportReputation, againstReputation
    function getProposalVoteCount(uint256 _proposalId) external view returns (uint256, uint256) {
         Proposal storage proposal = proposals[_proposalId];
         return (proposal.supportReputation, proposal.againstReputation);
    }

     /// @notice Gets the total reputation supply across all users.
     /// @dev This value is updated approximately on reputation changes and is used for governance quorum.
    function getTotalReputationSupply() external view returns (uint256) {
        return _totalReputationSupply;
    }


    // --- Utility ---

    /// @notice Allows the owner to rescue accidentally sent tokens (excluding the staking token held for users).
    /// @param _token The address of the token contract to rescue.
    /// @param _amount The amount of tokens to rescue.
    function rescueTokens(address _token, uint256 _amount) external onlyOwner {
        // Prevent rescuing the staking token that belongs to users
        if (_token == address(stakingToken)) {
            revert("Cannot rescue the staking token held for users");
        }
        IERC20(_token).safeTransfer(msg.sender, _amount);
    }

    // --- Helper Function (for Math.sqrt) ---
    // This is a basic integer square root function. More robust versions exist.
    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        uint256 z = (x + 1) / 2;
        uint256 y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
        return y;
    }
}
```

**Explanation of Concepts:**

1.  **Dynamic Reputation & Decay:** Reputation isn't static. It's earned through staking time/amount (`reputationStakeMultiplier`) but also decays (`reputationDecayRate`) if a user stops staking. The `_updateReputation` function is key to managing this time-based state change.
2.  **Time-Based Mechanics:** Staking requires a minimum duration (`minStakingDuration`) before rewards can be claimed or unstaked. Reputation decay is based on time passed since the last update. Enhancements can also have durations.
3.  **NFT Attribute Derivation:** The `getDerivedNFTAttributes` function shows how an NFT's properties can be calculated *on-chain* based on the linked user's current reputation. The actual NFT contract would likely implement `tokenURI` to call this function and return the metadata JSON dynamically. The `_triggerNFTAttributeUpdate` event simulates notifying an off-chain service or the NFT contract itself to refresh metadata.
4.  **Reputation-Weighted Governance:** Instead of token weighting (common in DAOs), voting power in `voteOnProposal` is based on the user's current reputation points. Proposals require a minimum reputation to be created, and a quorum based on the *total reputation supply* is needed for execution.
5.  **Enhancements:** Adds a way for users to spend resources (staked tokens or reputation) for specific benefits (like an instant reputation boost or perhaps future timed multipliers, though only boost is implemented simply here). This introduces a utility sink for tokens/reputation.
6.  **Internal Calculations & State:** Reputation updates, decay, earned reputation, and derived NFT attributes are calculated and stored/derived within the contract, relying on timestamps (`block.timestamp`).

**Advanced & Creative Aspects:**

*   **Combined Mechanics:** Integrates staking, dynamic stats (reputation), NFTs, and governance in a single, interconnected system.
*   **Time-Dependent State:** Reputation actively changes based on time and user action (staking/not staking).
*   **On-Chain Attribute Logic:** While the NFT metadata itself might be off-chain, the *logic* for *deriving* attributes from user state (reputation) is intended to be callable and verifiable on-chain.
*   **Reputation as Governance Power:** Uses a dynamic, earned metric (reputation) rather than raw token balance for governance weight.
*   **Enhancement Utility:** Creates defined ways to utilize staked tokens or reputation points.

This contract provides a framework for a complex on-chain system. A production version would require careful consideration of scaling, gas costs for computations (especially reputation updates on read/write), edge cases, and potentially more sophisticated math for decay/earnings and attribute derivation. The interaction with the `profileNFT` contract is simulated; in reality, you'd need a corresponding NFT contract designed to receive calls/events from `ReputationForge` to update metadata.