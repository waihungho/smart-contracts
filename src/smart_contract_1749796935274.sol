Okay, here is a Solidity smart contract incorporating several advanced concepts, aiming for creativity and avoiding direct copies of standard open-source implementations while using common interfaces like ERC721 and ERC20.

The core concept is a "Quantum Treasure Box" NFT (`ERC721`) whose contents are not fixed upon creation but revealed probabilistically upon meeting complex unlock conditions. The box itself can evolve, and certain parameters are governed by stakers of an associated token.

**Concepts Included:**

1.  **ERC721 Standard:** Core NFT functionality.
2.  **Dynamic State:** Box properties (like unlock conditions, potential contents) can change *after* minting.
3.  **Multi-Conditional Unlock:** Opening requires fulfilling several criteria simultaneously (time, staked tokens, owning another specific NFT, providing validated external data).
4.  **Probabilistic Revelation:** Contents are determined upon opening using a (pseudo)random process influenced by probabilities defined for the box. Simulates a "quantum state collapse".
5.  **Mixed Content Types:** Boxes can reveal ERC721 NFTs *and* ERC20 tokens.
6.  **Staking for Utility:** Users must stake tokens (`QBT`) to meet an unlock condition for a specific box.
7.  **Oracle Integration (Simulated):** A mechanism to require verification of external data via a trusted oracle address before unlocking.
8.  **NFT Evolution/Merging:** Functionality to "merge" two boxes into a new, potentially higher-rarity box.
9.  **Dynamic Content Pools:** Ability to add new potential contents to a box *after* it's minted.
10. **Lite On-Chain Governance:** A simple proposal and voting system based on staked `QBT` to adjust contract parameters (like oracle address, base probabilities, fees).
11. **Time-Based Mechanics:** Unlock delays.
12. **Randomness (Pseudo):** Using block data and user input for determining revealed contents (acknowledging limitations).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol"; // For potential oracle signature verification (simplified here)

// Outline:
// 1. Contract Definition: Inherits ERC721 and Ownable.
// 2. Interfaces: Define necessary interfaces for ERC20 and potentially Oracle verification.
// 3. Data Structures: Structs for BoxState, RevealedContents, Governance Proposals.
// 4. State Variables: Mappings to store box data, staked QBT, revealed contents, proposal data, governance parameters.
// 5. Events: For key actions like minting, setting conditions, opening, revealing, staking, governance.
// 6. Modifiers: Access control for governance and ownership.
// 7. Constructor: Initialize ERC721, Ownable, and set initial governance parameters.
// 8. ERC721 Functions: Standard transfer, approval, etc. (Delegated to OpenZeppelin).
// 9. Core Box Logic:
//    - Minting (initial & evolved/merged)
//    - Setting/Updating Unlock Conditions dynamically
//    - Adding potential contents dynamically
//    - Staking/Withdrawing QBT for a specific box
//    - Providing Oracle Proof
//    - Attempting to Open the box (main complex function)
//    - Claiming Revealed Contents
//    - Upgrading Box Rarity
//    - Merging Boxes (burns originals, mints new)
// 10. Governance Logic:
//    - Proposing parameter changes
//    - Voting on proposals (weighted by staked QBT)
//    - Executing successful proposals
// 11. Utility/View Functions: Get box state, conditions, potential contents, revealed contents, governance state, etc.

// Function Summary:
// --- Standard ERC721 (7 functions) ---
// balanceOf(address owner): Get number of boxes owned by an address.
// ownerOf(uint256 tokenId): Get owner of a specific box.
// transferFrom(address from, address to, uint256 tokenId): Transfer box ownership.
// safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data): Safe transfer with receiver hook.
// safeTransferFrom(address from, address to, uint256 tokenId): Safe transfer without data.
// approve(address to, uint256 tokenId): Approve another address to transfer a specific box.
// getApproved(uint256 tokenId): Get the approved address for a specific box.
// setApprovalForAll(address operator, bool approved): Set approval for an operator for all boxes.
// isApprovedForAll(address owner, address operator): Check if an operator is approved for all boxes.

// --- Core Box Logic (11+ functions) ---
// mintInitialBox(address recipient, uint256 initialRaritySeed): Owner/Governance function to mint a base box.
// mintEvolvedBox(address recipient, uint256 tokenId1, uint256 tokenId2): Merge/burn two boxes to mint a new, potentially better one. Requires ownership of both.
// setUnlockConditions(uint256 tokenId, uint256 requiredQBTStake, address requiredNFTCollection, uint256 requiredNFTId, bytes32 requiredOracleDataHash): Set/update dynamic unlock requirements for a box. Owner/Approved only.
// addPotentialContent(uint256 tokenId, address erc721Address, uint256 erc20Amount, uint256 probabilityWeight): Add a potential content item and its probability weight to a box's pool. Owner/Governance only. erc20Amount is 0 if adding ERC721, erc721Address is address(0) if adding ERC20.
// stakeQBT(uint256 tokenId, uint256 amount): Stake QBT tokens on a specific box to help meet its unlock condition.
// withdrawStakedQBT(uint256 tokenId, uint256 amount): Withdraw *available* staked QBT from a box (only if box not open or amount exceeds requirement).
// provideOracleProof(uint256 tokenId, bytes memory oracleData, bytes memory proof): Provides external data and proof (simulated) for oracle condition check.
// attemptOpen(uint256 tokenId, uint256 userProvidedEntropy): The main function to attempt opening the box. Checks ALL conditions, consumes resources (like staked QBT meeting threshold), and probabilistically determines contents based on randomness.
// claimRevealedContents(uint256 tokenId): Allows the box owner to claim the contents revealed upon opening.
// upgradeRarity(uint256 tokenId, uint256 cost): Increases the rarity level of a box, potentially requiring QBT burn/payment. Owner/Approved only.
// _getRandomness(uint256 tokenId, uint256 userEntropy): Internal helper for pseudo-randomness generation.

// --- Governance Logic (4 functions) ---
// proposeOracleAddressChange(address newOracle): Propose changing the trusted oracle address. Requires minimum staked QBT.
// proposeParameterChange(uint8 paramType, uint256 value): Propose changing a generic governance parameter. Requires minimum staked QBT.
// voteOnProposal(uint256 proposalId, bool support): Cast a vote on an active proposal. Voting power based on staked QBT (total staked by voter across all boxes?). Let's use total staked by voter on *this contract*.
// executeProposal(uint256 proposalId): Execute a successful proposal after voting period ends.

// --- Utility / View Functions (10+ functions) ---
// getBoxState(uint256 tokenId): Get current state details of a box.
// getBoxUnlockConditions(uint256 tokenId): Get the specific unlock requirements for a box.
// getPotentialContents(uint256 tokenId): Get the list of potential contents for a box before it's opened.
// getRevealedContents(uint256 tokenId): Get the actual contents revealed after the box has been opened.
// isBoxOpen(uint56 tokenId): Check if a box is open.
// getQBTStakedForBox(uint256 tokenId): Get the amount of QBT staked *on* a specific box.
// getTotalQBTStaked(address voter): Get total QBT staked by a user across all boxes they've staked on. (Helper for voting).
// getTotalBoxesMinted(): Get the total number of boxes created.
// getGovernanceProposalState(uint256 proposalId): Get the current state of a governance proposal.
// getGovernanceParameters(): Get the current values of governed parameters.
// getOracleAddress(): Get the currently set oracle address.
// getStakedQBTForVoter(address voter): Get total QBT staked by a specific voter on this contract (useful for governance weight).

contract QuantumTreasureBox is ERC721, Ownable, IERC721Receiver {

    // --- Interfaces ---
    // Assuming a simplified QBT token exists implementing IERC20
    IERC20 public immutable qbtToken;

    // --- Data Structures ---

    struct PotentialContent {
        address erc721Address; // address(0) for ERC20
        uint256 erc20Amount;   // 0 for ERC721
        uint256 probabilityWeight; // Relative weight, not percentage
    }

    struct BoxState {
        bool isOpen;
        uint256 creationTime;
        uint256 requiredOpenTime; // seconds from creationTime
        uint256 rarityLevel;      // Affects potential contents, unlock costs etc.
        uint256 requiredQBTStake; // Min QBT required to be staked on this box
        address requiredNFTCollection; // Required NFT collection owner must hold
        uint256 requiredNFTId;    // Specific NFT ID owner must hold (0 for any in collection)
        bytes32 requiredOracleDataHash; // Hash of data expected from oracle
        bool oracleDataChecked;   // True if provideOracleProof was called with correct hash (mocked check)
        PotentialContent[] potentialContents; // List of possible contents and their weights
        uint256 totalWeight;      // Sum of all probabilityWeights
    }

    struct RevealedContents {
        bool claimed;
        address[] revealedERC721;
        uint256 revealedERC20Amount; // Sum of all revealed ERC20
    }

    enum ProposalState { Pending, Active, Succeeded, Failed, Executed }

    struct GovernanceProposal {
        uint256 proposalId;
        address proposer;
        uint8 paramType;         // e.g., 0: Oracle, 1: Fee, 2: MinStakeForProposal
        uint256 uintValue;       // Value for uint parameters
        address addressValue;    // Value for address parameters
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 votesFor;        // Weighted votes
        uint256 votesAgainst;    // Weighted votes
        ProposalState state;
        bool executed;
    }

    // --- State Variables ---

    uint256 private _nextTokenId;
    mapping(uint256 => BoxState) private _boxStates;
    mapping(uint256 => uint256) private _stakedQBT; // QBT staked *on* a specific box
    mapping(address => uint256) private _totalStakedQBT; // Total QBT staked by an address across all boxes (for voting)
    mapping(uint256 => RevealedContents) private _revealedContents;

    address public oracleAddress;

    // Governance Parameters (governed by proposals)
    uint256 public minStakeForProposal;
    uint256 public proposalVotingPeriod; // seconds
    uint256 public proposalExecutionDelay; // seconds after voting ends before executable
    uint256 public minVoteSupportNumerator; // Numerator for required vote support (e.g., 51)
    uint256 public minVoteSupportDenominator; // Denominator (e.g., 100)
    uint256 public qbtUpgradeRarityCost; // QBT cost to upgrade rarity

    uint256 private _nextProposalId;
    mapping(uint256 => GovernanceProposal) public governanceProposals;
    mapping(uint256 => mapping(address => bool)) private _proposalVoted; // proposalId => voter => voted

    // --- Events ---

    event BoxMinted(uint256 indexed tokenId, address indexed owner, uint256 rarityLevel);
    event UnlockConditionsSet(uint256 indexed tokenId, uint256 requiredQBTStake, address indexed requiredNFTCollection, uint256 requiredNFTId, bytes32 requiredOracleDataHash);
    event PotentialContentAdded(uint256 indexed tokenId, address erc721Address, uint256 erc20Amount, uint256 probabilityWeight);
    event QBTStaked(uint256 indexed tokenId, address indexed staker, uint256 amount);
    event QBTUnstaked(uint256 indexed tokenId, address indexed staker, uint256 amount);
    event OracleProofProvided(uint256 indexed tokenId, bytes32 indexed dataHash, bool success);
    event BoxOpened(uint256 indexed tokenId, address indexed opener, uint256 randomnessSeed);
    event ContentsRevealed(uint256 indexed tokenId, address indexed owner, address[] revealedERC721, uint256 revealedERC20Amount);
    event ContentsClaimed(uint256 indexed tokenId, address indexed owner);
    event RarityUpgraded(uint256 indexed tokenId, uint256 newRarityLevel);
    event BoxesMerged(uint256 indexed tokenId1, uint256 indexed tokenId2, uint256 indexed newTokenId);

    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, uint8 paramType, uint256 uintValue, address addressValue);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support, uint256 weight);
    event ProposalStateChanged(uint256 indexed proposalId, ProposalState newState);
    event ProposalExecuted(uint256 indexed proposalId);

    // --- Modifiers ---

    modifier onlyBoxOwnerOrApproved(uint256 tokenId) {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Not box owner or approved");
        _;
    }

    modifier onlyGovernance() {
        // In this lite governance, the contract owner initially sets governance params,
        // and then governance takes over. We'll allow owner OR successful governance execution.
        // A more robust system would involve a separate Governance contract.
        // For simplicity here, functions meant for governance execution will have internal access.
        // The public execution functions are handled by anyone calling executeProposal.
        require(false, "Governance modifier is internal execution trigger"); // Should not be called directly as a modifier on public fns
        _;
    }

    // --- Constructor ---

    constructor(address initialOwner, address qbtTokenAddress, address initialOracle)
        ERC721("QuantumTreasureBox", "QTB")
        Ownable(initialOwner)
    {
        qbtToken = IERC20(qbtTokenAddress);
        oracleAddress = initialOracle; // Can be changed via governance

        // Set initial governance parameters
        minStakeForProposal = 1000 ether; // Example: 1000 QBT
        proposalVotingPeriod = 3 days;
        proposalExecutionDelay = 1 days; // Time buffer after voting ends
        minVoteSupportNumerator = 51;
        minVoteSupportDenominator = 100; // 51% support required
        qbtUpgradeRarityCost = 500 ether; // Example: 500 QBT
    }

    // --- Standard ERC721 Functions (Implemented by OpenZeppelin) ---
    // balanceOf, ownerOf, transferFrom, safeTransferFrom, approve, getApproved, setApprovalForAll, isApprovedForAll

    // Need to support receiving ERC721 for merge function
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external override returns (bytes4) {
        // This contract expects NFTs to be sent via transferFrom for merging.
        // It does not generically accept random NFTs.
        revert("Contract does not accept arbitrary ERC721 transfers");
        // return IERC721Receiver.onERC721Received.selector; // Or return this if we want to accept
    }

    // --- Core Box Logic ---

    function mintInitialBox(address recipient, uint256 initialRaritySeed, uint256 unlockDelay) external onlyOwner returns (uint256 tokenId) {
        tokenId = _nextTokenId++;
        _safeMint(recipient, tokenId);

        // Initialize box state
        _boxStates[tokenId] = BoxState({
            isOpen: false,
            creationTime: block.timestamp,
            requiredOpenTime: unlockDelay,
            rarityLevel: initialRaritySeed, // Seed or direct level based on input/policy
            requiredQBTStake: 0,
            requiredNFTCollection: address(0),
            requiredNFTId: 0,
            requiredOracleDataHash: bytes32(0),
            oracleDataChecked: false,
            potentialContents: new PotentialContent[](0),
            totalWeight: 0
        });

        emit BoxMinted(tokenId, recipient, initialRaritySeed);
        return tokenId;
    }

    function mintEvolvedBox(address recipient, uint256 tokenId1, uint256 tokenId2) external returns (uint256 newTokenId) {
        require(_msgSender() == ownerOf(tokenId1) && _msgSender() == ownerOf(tokenId2), "Caller must own both boxes");
        require(!_boxStates[tokenId1].isOpen && !_boxStates[tokenId2].isOpen, "Both boxes must be closed to merge");

        // Burn the old boxes
        _burn(tokenId1);
        _burn(tokenId2);

        // Determine parameters for the new box based on the old ones
        // This logic can be arbitrarily complex - combining rarities, contents etc.
        uint256 newRarity = Math.max(_boxStates[tokenId1].rarityLevel, _boxStates[tokenId2].rarityLevel) + 1; // Simple example
        uint256 newUnlockDelay = Math.max(_boxStates[tokenId1].requiredOpenTime, _boxStates[tokenId2].requiredOpenTime) / 2; // Example: Faster unlock
        // Inherit/combine potential contents? For simplicity, let's give it a standard set based on new rarity, or empty to be configured.
         // For a more complex example, could iterate and merge _boxStates[tokenId1].potentialContents and _boxStates[tokenId2].potentialContents

        newTokenId = _nextTokenId++;
         _safeMint(recipient, newTokenId);

         _boxStates[newTokenId] = BoxState({
            isOpen: false,
            creationTime: block.timestamp,
            requiredOpenTime: newUnlockDelay,
            rarityLevel: newRarity,
            requiredQBTStake: 0, // Reset or combine? Let's reset
            requiredNFTCollection: address(0),
            requiredNFTId: 0,
            requiredOracleDataHash: bytes32(0),
            oracleDataChecked: false,
            potentialContents: new PotentialContent[](0), // Starts empty, needs content added later
            totalWeight: 0
         });

         emit BoxesMerged(tokenId1, tokenId2, newTokenId);
         emit BoxMinted(newTokenId, recipient, newRarity);
         // Note: The contents of the new box need to be added via addPotentialContent later.

         return newTokenId;
    }

    // Allows owner or approved address to set/update unlock requirements
    function setUnlockConditions(
        uint256 tokenId,
        uint256 requiredQBTStake,
        address requiredNFTCollection,
        uint256 requiredNFTId,
        bytes32 requiredOracleDataHash
    ) external onlyBoxOwnerOrApproved(tokenId) {
        BoxState storage box = _boxStates[tokenId];
        require(!box.isOpen, "Box is already open");

        box.requiredQBTStake = requiredQBTStake;
        box.requiredNFTCollection = requiredNFTCollection;
        box.requiredNFTId = requiredNFTId;
        box.requiredOracleDataHash = requiredOracleDataHash;
        box.oracleDataChecked = (requiredOracleDataHash == bytes32(0)); // Auto-checked if no hash is required

        emit UnlockConditionsSet(tokenId, requiredQBTStake, requiredNFTCollection, requiredNFTId, requiredOracleDataHash);
    }

    // Allows owner or governance to add possible contents to a box's pool
    function addPotentialContent(
        uint256 tokenId,
        address erc721Address, // address(0) if ERC20
        uint256 erc20Amount,   // 0 if ERC721
        uint256 probabilityWeight
    ) external onlyBoxOwnerOrApproved(tokenId) {
         BoxState storage box = _boxStates[tokenId];
         require(!box.isOpen, "Box is already open");
         require(probabilityWeight > 0, "Weight must be positive");
         require(erc721Address != address(0) || erc20Amount > 0, "Must specify ERC721 address or ERC20 amount");
         require(!(erc721Address != address(0) && erc20Amount > 0), "Cannot specify both ERC721 and ERC20 for one item");

         box.potentialContents.push(PotentialContent(erc721Address, erc20Amount, probabilityWeight));
         box.totalWeight += probabilityWeight;

         emit PotentialContentAdded(tokenId, erc721Address, erc20Amount, probabilityWeight);
    }

    // Stake QBT tokens on a box to help meet its requirement
    function stakeQBT(uint256 tokenId, uint256 amount) external {
        require(_exists(tokenId), "Box does not exist");
        require(amount > 0, "Stake amount must be positive");
        require(!_boxStates[tokenId].isOpen, "Box is already open");

        // Ensure caller has approved this contract to spend their QBT
        require(qbtToken.transferFrom(_msgSender(), address(this), amount), "QBT transfer failed");

        _stakedQBT[tokenId] += amount;
        _totalStakedQBT[_msgSender()] += amount; // Track total staked by user for voting

        emit QBTStaked(tokenId, _msgSender(), amount);
    }

    // Withdraw staked QBT. Only possible if box not open OR amount is more than required.
    // If box is open, the required amount is consumed, only excess is available.
    function withdrawStakedQBT(uint256 tokenId, uint256 amount) external {
        require(_exists(tokenId), "Box does not exist");
        require(amount > 0, "Withdraw amount must be positive");

        BoxState storage box = _boxStates[tokenId];
        uint256 availableToWithdraw = _stakedQBT[tokenId];

        if (box.isOpen) {
            // If box is open, the required amount is consumed. Only excess can be withdrawn.
            // Note: This logic implies the requiredStake is 'locked' upon opening.
            // A different design might consume it immediately upon opening.
             uint256 consumedStake = box.requiredQBTStake;
             if (_stakedQBT[tokenId] >= consumedStake) {
                 availableToWithdraw = _stakedQBT[tokenId] - consumedStake;
             } else {
                 availableToWithdraw = 0; // Required stake was not met, nothing to withdraw
             }
        }
        // If box is not open, all staked amount is available.

        require(amount <= availableToWithdraw, "Not enough QBT staked or available to withdraw");

        _stakedQBT[tokenId] -= amount;
        _totalStakedQBT[_msgSender()] -= amount; // Update voter stake count

        require(qbtToken.transfer(_msgSender(), amount), "QBT transfer failed");

        emit QBTUnstaked(tokenId, _msgSender(), amount);
    }


    // Simulate oracle data provision and check. In a real scenario, this would verify a signature
    // from the trusted oracleAddress against the dataHash and potentially include a timestamp check.
    function provideOracleProof(uint256 tokenId, bytes memory oracleData, bytes memory proof) external {
        require(_exists(tokenId), "Box does not exist");
        BoxState storage box = _boxStates[tokenId];
        require(!box.isOpen, "Box is already open");
        require(box.requiredOracleDataHash != bytes32(0), "Box does not require oracle data");
        require(!box.oracleDataChecked, "Oracle data already provided");

        // --- Simulated Verification ---
        // In a real contract:
        // 1. Hash oracleData: keccak256(oracleData)
        // 2. Recover signer from hash and proof: ECDSA.recover(hashedData, proof)
        // 3. Check if recovered signer == oracleAddress
        // require(ECDSA.recover(keccak256(oracleData), proof) == oracleAddress, "Invalid oracle signature");
        // 4. (Optional) Verify oracleData structure or timestamp to prevent replays

        // For demonstration, we just check if the hash matches the requirement
        bytes32 dataHash = keccak256(oracleData);
        bool success = (dataHash == box.requiredOracleDataHash); // Simple hash match

        box.oracleDataChecked = success;

        emit OracleProofProvided(tokenId, dataHash, success);
        require(success, "Oracle data verification failed");
    }


    // The main function to attempt opening the box
    function attemptOpen(uint256 tokenId, uint256 userProvidedEntropy) external onlyBoxOwnerOrApproved(tokenId) {
        BoxState storage box = _boxStates[tokenId];
        require(!box.isOpen, "Box is already open");

        // 1. Check Time Condition
        require(block.timestamp >= box.creationTime + box.requiredOpenTime, "Unlock time has not been reached");

        // 2. Check QBT Stake Condition
        require(_stakedQBT[tokenId] >= box.requiredQBTStake, "Insufficient QBT staked on this box");

        // 3. Check Required NFT Condition
        if (box.requiredNFTCollection != address(0)) {
            if (box.requiredNFTId != 0) {
                // Specific NFT required
                require(IERC721(box.requiredNFTCollection).ownerOf(box.requiredNFTId) == _msgSender(), "Required specific NFT not owned");
            } else {
                // Any NFT from collection required
                 require(IERC721(box.requiredNFTCollection).balanceOf(_msgSender()) > 0, "Required NFT collection not owned");
            }
        }

        // 4. Check Oracle Data Condition
        if (box.requiredOracleDataHash != bytes32(0)) {
             require(box.oracleDataChecked, "Oracle data not provided or verified");
        }

        // --- All conditions met. Proceed to open and reveal contents ---

        box.isOpen = true;

        // 5. Consume Required Stake (if applicable)
        // The QBT tokens equal to requiredQBTStake remain in the contract.
        // Excess QBT can be withdrawn via withdrawStakedQBT.
        // A portion of the consumed stake could be sent to a fee wallet, burned, or added to a reward pool.
        // For this example, we just mark it as 'consumed' by leaving it in the contract balance
        // and adjusting the withdrawable amount in withdrawStakedQBT logic.

        // 6. Determine Contents Probabilistically
        // Pseudo-randomness: Mix block data and user input. **Caution: This is NOT cryptographically secure**
        // For production, use Chainlink VRF or similar secure oracle.
        uint256 randomnessSeed = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.difficulty, // deprecated, use block.prevrandao for PoS
            block.number,
            tokenId,
            userProvidedEntropy,
            msg.sender
        )));

        _revealedContents[tokenId].claimed = false;
        _revealedContents[tokenId].revealedERC721 = new address[](0); // Store addresses of revealed ERC721 contracts
        _revealedContents[tokenId].revealedERC20Amount = 0;

        uint256 randomValue = randomnessSeed % box.totalWeight; // Get a value within the total weight range
        uint256 cumulativeWeight = 0;

        // Select one item based on weighted probability
        for (uint i = 0; i < box.potentialContents.length; i++) {
            cumulativeWeight += box.potentialContents[i].probabilityWeight;
            if (randomValue < cumulativeWeight) {
                // This item is selected
                if (box.potentialContents[i].erc721Address != address(0)) {
                    _revealedContents[tokenId].revealedERC721.push(box.potentialContents[i].erc777Address); // Store the contract address
                    // Note: A real system needs to mint/transfer a specific NFT *ID*.
                    // This requires interaction with the content NFT contract, which is complex.
                    // For this example, we just record *which collection* was won.
                    // A full implementation would need to handle minting/transferring the actual NFT instance here.
                    // Example: IERC721(contentAddress).safeTransferFrom(address(this), ownerOf(tokenId), newItemId);
                    // This requires the content NFT contract to support transferFrom by this contract or minting by this contract.
                    // Let's simplify and say it reveals *the right to claim* an NFT from that collection.
                } else {
                    _revealedContents[tokenId].revealedERC20Amount += box.potentialContents[i].erc20Amount;
                }
                // Only one item selected for simplicity. Could loop and select multiple based on more complex logic.
                break;
            }
        }

        // 7. Emit Events
        emit BoxOpened(tokenId, _msgSender(), randomnessSeed);
        emit ContentsRevealed(tokenId, ownerOf(tokenId), _revealedContents[tokenId].revealedERC721, _revealedContents[tokenId].revealedERC20Amount);

        // Box is now open, contents are determined but not yet claimed.
    }

    // Allows the box owner to claim the revealed contents
    function claimRevealedContents(uint256 tokenId) external {
        require(_exists(tokenId), "Box does not exist");
        require(_msgSender() == ownerOf(tokenId), "Only box owner can claim contents");

        RevealedContents storage contents = _revealedContents[tokenId];
        require(!contents.claimed, "Contents already claimed");
        require(_boxStates[tokenId].isOpen, "Box is not open yet");

        // Transfer ERC20
        if (contents.revealedERC20Amount > 0) {
            // Contract must hold enough ERC20
            require(qbtToken.transfer(_msgSender(), contents.revealedERC20Amount), "ERC20 transfer failed");
        }

        // Transfer ERC721s (Simulated)
        // In a real implementation, you would interact with the *actual* ERC721 contract addresses
        // stored in contents.revealedERC721 to transfer specific token IDs to the owner.
        // This requires the content NFT contracts to allow this contract to transfer tokens it might own,
        // or to mint new tokens directly to the user.
        // For this example, we just log that they were 'claimed'.
         for(uint i = 0; i < contents.revealedERC721.length; i++) {
             // Imagine interaction with IERC721(contents.revealedERC721[i]) here
         }


        contents.claimed = true;
        emit ContentsClaimed(tokenId, _msgSender());
    }

    // Increase the rarity level of a box, potentially requiring QBT payment/burn
    function upgradeRarity(uint256 tokenId, uint256 cost) external onlyBoxOwnerOrApproved(tokenId) {
        require(_exists(tokenId), "Box does not exist");
        require(!_boxStates[tokenId].isOpen, "Box is already open");
        require(cost == qbtUpgradeRarityCost, "Incorrect upgrade cost"); // Simple fixed cost

        // Transfer required QBT cost to the contract (can be burned or sent to treasury)
        require(qbtToken.transferFrom(_msgSender(), address(this), cost), "QBT transfer failed");

        _boxStates[tokenId].rarityLevel += 1; // Simple increment

        emit RarityUpgraded(tokenId, _boxStates[tokenId].rarityLevel);
    }


    // --- Governance Logic (Lite) ---

    // Governance parameter mapping:
    // 0: Oracle Address (addressValue)
    // 1: Min Stake For Proposal (uintValue)
    // 2: Proposal Voting Period (uintValue)
    // 3: Proposal Execution Delay (uintValue)
    // 4: Min Vote Support Numerator (uintValue)
    // 5: Min Vote Support Denominator (uintValue)
    // 6: QBT Upgrade Rarity Cost (uintValue)


    function proposeOracleAddressChange(address newOracle) external {
        // Requires a minimum amount of QBT staked *by the proposer* across all boxes
        require(_totalStakedQBT[_msgSender()] >= minStakeForProposal, "Not enough QBT staked to propose");
        require(newOracle != address(0), "New oracle address cannot be zero");

        uint256 proposalId = _nextProposalId++;
        governanceProposals[proposalId] = GovernanceProposal({
            proposalId: proposalId,
            proposer: _msgSender(),
            paramType: 0, // Oracle Address
            uintValue: 0, // Not used for address type
            addressValue: newOracle,
            voteStartTime: block.timestamp,
            voteEndTime: block.timestamp + proposalVotingPeriod,
            votesFor: 0,
            votesAgainst: 0,
            state: ProposalState.Active,
            executed: false
        });

        emit ProposalCreated(proposalId, _msgSender(), 0, 0, newOracle);
    }

     function proposeParameterChange(uint8 paramType, uint256 value) external {
        require(_totalStakedQBT[_msgSender()] >= minStakeForProposal, "Not enough QBT staked to propose");
        require(paramType > 0 && paramType <= 6, "Invalid parameter type"); // Only uint types here

        uint256 proposalId = _nextProposalId++;
        governanceProposals[proposalId] = GovernanceProposal({
            proposalId: proposalId,
            proposer: _msgSender(),
            paramType: paramType,
            uintValue: value,
            addressValue: address(0), // Not used for uint types
            voteStartTime: block.timestamp,
            voteEndTime: block.timestamp + proposalVotingPeriod,
            votesFor: 0,
            votesAgainst: 0,
            state: ProposalState.Active,
            executed: false
        });

        emit ProposalCreated(proposalId, _msgSender(), paramType, value, address(0));
    }


    // Vote on a proposal. Voting power = total QBT staked by the voter on this contract.
    function voteOnProposal(uint256 proposalId, bool support) external {
        GovernanceProposal storage proposal = governanceProposals[proposalId];
        require(proposal.state == ProposalState.Active, "Proposal is not active");
        require(block.timestamp <= proposal.voteEndTime, "Voting period has ended");
        require(!_proposalVoted[proposalId][_msgSender()], "Already voted on this proposal");

        uint256 voterWeight = _totalStakedQBT[_msgSender()];
        require(voterWeight > 0, "Voter must have staked QBT to vote");

        if (support) {
            proposal.votesFor += voterWeight;
        } else {
            proposal.votesAgainst += voterWeight;
        }

        _proposalVoted[proposalId][_msgSender()] = true;

        emit Voted(proposalId, _msgSender(), support, voterWeight);

        // Check if voting period ended right after this vote (unlikely but possible in edge cases)
        // A more robust system might have a separate function to transition state after voteEndTime
        _checkProposalState(proposalId);
    }

    // Anyone can call this to transition a proposal state or execute it if successful
    function executeProposal(uint256 proposalId) external {
        _checkProposalState(proposalId); // Ensure state is updated

        GovernanceProposal storage proposal = governanceProposals[proposalId];
        require(proposal.state == ProposalState.Succeeded, "Proposal is not in a successful state");
        require(!proposal.executed, "Proposal already executed");
        require(block.timestamp >= proposal.voteEndTime + proposalExecutionDelay, "Execution delay not passed");

        // Execute the proposed change
        if (proposal.paramType == 0) { // Oracle Address
            oracleAddress = proposal.addressValue;
        } else if (proposal.paramType == 1) { // Min Stake For Proposal
            minStakeForProposal = proposal.uintValue;
        } else if (proposal.paramType == 2) { // Proposal Voting Period
            proposalVotingPeriod = proposal.uintValue;
        } else if (proposal.paramType == 3) { // Proposal Execution Delay
            proposalExecutionDelay = proposal.uintValue;
        } else if (proposal.paramType == 4) { // Min Vote Support Numerator
            minVoteSupportNumerator = proposal.uintValue;
        } else if (proposal.paramType == 5) { // Min Vote Support Denominator
            minVoteSupportDenominator = proposal.uintValue;
        } else if (proposal.paramType == 6) { // QBT Upgrade Rarity Cost
            qbtUpgradeRarityCost = proposal.uintValue;
        }
        // Add more param types as needed

        proposal.executed = true;
        proposal.state = ProposalState.Executed; // Final state

        emit ProposalExecuted(proposalId);
        emit ProposalStateChanged(proposalId, ProposalState.Executed);
    }

    // Internal helper to update proposal state
    function _checkProposalState(uint256 proposalId) internal {
        GovernanceProposal storage proposal = governanceProposals[proposalId];
        if (proposal.state == ProposalState.Active && block.timestamp > proposal.voteEndTime) {
            // Voting period ended, determine outcome
            uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
            if (totalVotes == 0) {
                // No votes cast
                 proposal.state = ProposalState.Failed;
                 emit ProposalStateChanged(proposalId, ProposalState.Failed);
            } else {
                // Check support threshold
                if (proposal.votesFor * minVoteSupportDenominator >= totalVotes * minVoteSupportNumerator) {
                     proposal.state = ProposalState.Succeeded;
                     emit ProposalStateChanged(proposalId, ProposalState.Succeeded);
                } else {
                     proposal.state = ProposalState.Failed;
                     emit ProposalStateChanged(proposalId, ProposalState.Failed);
                }
            }
        }
    }

    // --- Utility / View Functions ---

    function getBoxState(uint256 tokenId) external view returns (BoxState memory) {
        require(_exists(tokenId), "Box does not exist");
        return _boxStates[tokenId];
    }

     function getBoxUnlockConditions(uint256 tokenId) external view returns (
        uint256 requiredQBTStake,
        address requiredNFTCollection,
        uint256 requiredNFTId,
        bytes32 requiredOracleDataHash,
        bool oracleDataChecked
     ) {
         require(_exists(tokenId), "Box does not exist");
         BoxState storage box = _boxStates[tokenId];
         return (
             box.requiredQBTStake,
             box.requiredNFTCollection,
             box.requiredNFTId,
             box.requiredOracleDataHash,
             box.oracleDataChecked
         );
     }


    function getPotentialContents(uint256 tokenId) external view returns (PotentialContent[] memory) {
         require(_exists(tokenId), "Box does not exist");
         return _boxStates[tokenId].potentialContents;
    }

    function getRevealedContents(uint256 tokenId) external view returns (RevealedContents memory) {
         require(_exists(tokenId), "Box does not exist");
         require(_boxStates[tokenId].isOpen, "Box is not open");
         return _revealedContents[tokenId];
    }

    function isBoxOpen(uint256 tokenId) public view returns (bool) {
         require(_exists(tokenId), "Box does not exist");
         return _boxStates[tokenId].isOpen;
    }

    function getQBTStakedForBox(uint256 tokenId) external view returns (uint256) {
        require(_exists(tokenId), "Box does not exist");
        return _stakedQBT[tokenId];
    }

     function getStakedQBTForVoter(address voter) external view returns (uint256) {
         return _totalStakedQBT[voter];
     }

    function getTotalBoxesMinted() external view returns (uint256) {
        return _nextTokenId; // _nextTokenId is the count of boxes minted (starting from 0)
    }

    function getGovernanceProposalState(uint256 proposalId) external view returns (ProposalState) {
        // Check proposal state. If active and time passed, show resolved state without needing to call execute
        if (governanceProposals[proposalId].state == ProposalState.Active && block.timestamp > governanceProposals[proposalId].voteEndTime) {
            // Calculate outcome without modifying state
             uint256 totalVotes = governanceProposals[proposalId].votesFor + governanceProposals[proposalId].votesAgainst;
             if (totalVotes == 0) return ProposalState.Failed; // No votes
             if (governanceProposals[proposalId].votesFor * minVoteSupportDenominator >= totalVotes * minVoteSupportNumerator) {
                 return ProposalState.Succeeded;
             } else {
                 return ProposalState.Failed;
             }
        }
        return governanceProposals[proposalId].state;
    }

    function getGovernanceParameters() external view returns (
        uint265 _minStakeForProposal,
        uint256 _proposalVotingPeriod,
        uint256 _proposalExecutionDelay,
        uint256 _minVoteSupportNumerator,
        uint256 _minVoteSupportDenominator,
        uint256 _qbtUpgradeRarityCost,
        address _oracleAddress
    ) {
        return (
            minStakeForProposal,
            proposalVotingPeriod,
            proposalExecutionDelay,
            minVoteSupportNumerator,
            minVoteSupportDenominator,
            qbtUpgradeRarityCost,
            oracleAddress
        );
    }

    function getOracleAddress() external view returns (address) {
        return oracleAddress;
    }

     function getBoxRarity(uint256 tokenId) external view returns (uint256) {
         require(_exists(tokenId), "Box does not exist");
         return _boxStates[tokenId].rarityLevel;
     }

    // Internal helper for pseudo-randomness
    function _getRandomness(uint256 tokenId, uint256 userEntropy) internal view returns (uint256) {
         // WARNING: block.difficulty is deprecated, use block.prevrandao in PoS Ethereum
         // This is for demonstration only. For production, use Chainlink VRF or similar.
        return uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.difficulty,
            block.number,
            tokenId,
            userEntropy,
            msg.sender // Include sender to make it harder for others to predict *their* outcome
        )));
    }

    // Fallback function to receive Ether (optional, remove if not needed)
    receive() external payable {}
    fallback() external payable {}
}
```

**Explanation of Advanced/Creative Aspects & Limitations:**

1.  **Dynamic State & Conditions:** Unlike many NFTs where metadata and properties are static, here, unlock conditions and potential contents can be added/changed after minting (`setUnlockConditions`, `addPotentialContent`). This adds a layer of dynamic interaction and potential for evolving game mechanics or collection strategies.
2.  **Probabilistic Revelation:** The `attemptOpen` function determines the contents at the moment of opening based on weights and randomness. This mimics observing a "superposition" that collapses into a definite state, giving the "Quantum" feel. The content pool can also grow (`addPotentialContent`).
3.  **Multi-Conditional Unlock:** Combining time locks, staking requirements, owning *other* NFTs, and requiring verified external data (`provideOracleProof`) creates complex and layered unlock mechanics beyond a simple key or time delay.
4.  **Simulated Oracle Integration:** The `provideOracleProof` function allows the contract to require external information (like weather data, game results, etc., represented by `oracleDataHash`). A real implementation would need robust signature verification and data source trust, but this provides the structural concept.
5.  **Staking for Utility & Governance:** `stakeQBT` provides utility to the QBT token by making it a key requirement for accessing box contents. Staked QBT is also used as voting weight in the simple governance system.
6.  **NFT Evolution/Merging:** `mintEvolvedBox` demonstrates burning existing NFTs to create a new one. This can be used for crafting mechanics, upgrades, or creating higher-tier assets. The logic for determining the new box's properties can be complex.
7.  **Lite Governance:** The proposal/voting system allows QBT stakers to collectively decide on certain contract parameters (`oracleAddress`, fees, voting rules). This adds a decentralized element to the contract's evolution.
8.  **Limitations of On-Chain Randomness:** The `_getRandomness` function uses block data and user entropy. This is **vulnerable** to miner/validator manipulation (they could choose not to include a block or transaction if it results in an unfavorable outcome). A production system **must** integrate with a secure, external randomness oracle like Chainlink VRF. The code includes a note about this.
9.  **Simplified ERC721/ERC20 Handling for Contents:** The `attemptOpen` function only records *which* ERC721 collection or ERC20 amount is revealed. The actual transfer/minting logic in `claimRevealedContents` is commented as simulated. A real implementation would require the `QuantumTreasureBox` contract to have the necessary permissions (like minter role on the content NFTs or approvals to transfer from its own balance if it pre-held NFTs) and the content NFT contracts to potentially implement `IERC721Receiver` if transferred *to* the box first. This is a significant complexity often handled by dedicated "Loot Box" or "Distribution" helper contracts.

This contract provides a framework demonstrating these interconnected concepts, going beyond basic NFT or token contracts. It combines elements of DeFi (staking), NFTs (dynamic, evolving), Gaming/Loot Boxes (probabilistic reveal, multiple conditions), and DAO (lite governance) in a single system.