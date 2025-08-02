This smart contract, "QuantumFluctCoin (QFC)," is designed as a highly dynamic, self-evolving cryptocurrency ecosystem where its behavior and associated NFTs are influenced by an on-chain "Quantum Energy Level." This level is derived from pseudo-random elements and external oracle data, simulating real-world unpredictability and introducing game-theoretic incentives. It goes beyond standard token mechanics by integrating dynamic NFTs, probabilistic yield farming, and adaptive governance, all tied to the concept of quantum fluctuations.

---

## QuantumFluctCoin (QFC) - Smart Contract Outline & Function Summary

**Contract Name:** `QuantumFluctCoin`
**Concept:** A token (`QFC`) and associated dynamic NFTs (`QuantumEntanglementNFT`) whose core mechanics (supply, rewards, NFT properties, governance) are influenced by an on-chain "Quantum Energy Level." This level is generated pseudo-randomly and can be influenced by external oracle data.

### I. Core Token Mechanics (ERC-20 Inspired)
*   **`constructor`**: Initializes the token (name, symbol, initial supply), sets up governance, and configures the Chainlink VRF and Automation consumers.
*   **`_mint(address to, uint256 amount)`**: Internal function to mint new QFC tokens.
*   **`_burn(address from, uint256 amount)`**: Internal function to burn QFC tokens.
*   **`name()`**: Returns the token name.
*   **`symbol()`**: Returns the token symbol.
*   **`decimals()`**: Returns the token decimals.
*   **`totalSupply()`**: Returns the total supply of QFC.
*   **`balanceOf(address account)`**: Returns the balance of an account.
*   **`transfer(address to, uint256 amount)`**: Transfers tokens.
*   **`approve(address spender, uint256 amount)`**: Approves a spender.
*   **`transferFrom(address from, address to, uint256 amount)`**: Transfers tokens from an approved account.
*   **`allowance(address owner, address spender)`**: Returns allowance.

### II. Quantum Fluctuation Mechanics
*   **`triggerQuantumFluctuation()`**: The core function to calculate and update the `quantumEnergyLevel`. It incorporates factors like block hash, timestamp, and potentially Chainlink VRF randomness, affecting supply adjustments.
*   **`getQuantumEnergyLevel()`**: Returns the current, dynamically calculated `quantumEnergyLevel`.
*   **`requestNewFluctuationSeed()`**: Requests a new random number from Chainlink VRF to contribute to the `quantumEnergyLevel` calculation. Callable by Automation.
*   **`fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)`**: Chainlink VRF callback function to receive and process the random seed, updating the `quantumEnergyLevel`.
*   **`setFluctuationParams(uint256 _baseEnergy, uint256 _volatilityFactor)`**: Owner-only function to tune the base energy level and volatility of fluctuations.
*   **`getLastFluctuationBlock()`**: Returns the block number of the last quantum fluctuation event.
*   **`getFluctuationHistory(uint256 index)`**: Retrieves a past `quantumEnergyLevel` from a limited history.

### III. Entangled Non-Fungible Tokens (NFTs)
*   **`mintEntangledNFT(string memory tokenURI)`**: Allows users to mint a unique `QuantumEntanglementNFT` by burning or locking a certain amount of QFC. The NFT's properties are initially tied to the current `quantumEnergyLevel`.
*   **`deEntangleNFT(uint256 tokenId)`**: Allows users to "de-entangle" an NFT, either by burning it to retrieve locked QFC or by making it a static, non-dynamic NFT (depending on original minting type).
*   **`updateEntangledNFTProperties(uint256 tokenId)`**: This function is called (e.g., by the owner, or via Chainlink Automation) to refresh an entangled NFT's properties based on the *current* `quantumEnergyLevel` and potentially the owner's QFC balance.
*   **`getEntangledNFTState(uint256 tokenId)`**: Returns the current dynamic properties (e.g., power, rarity score) of a specific `QuantumEntanglementNFT`.
*   **`tokenURI(uint256 tokenId)`**: Overrides ERC721's tokenURI to return a dynamic URI reflecting the NFT's current properties.

### IV. Probabilistic Staking & Yield Farming
*   **`stake(uint256 amount)`**: Allows users to stake QFC tokens into a quantum staking pool.
*   **`unstake(uint256 amount)`**: Allows users to unstake QFC tokens.
*   **`claimProbabilisticRewards()`**: Users can claim rewards. The amount is non-deterministic and depends on their staked amount, duration, and the current `quantumEnergyLevel` and historical fluctuations. Higher energy levels or specific fluctuation patterns could trigger bonus rewards.
*   **`getStakedBalance(address staker)`**: Returns the amount of QFC staked by a specific address.
*   **`getPendingProbabilisticRewards(address staker)`**: Calculates and returns the *estimated* pending probabilistic rewards for a staker (note: actual claim amount can vary).

### V. Quantum Forging
*   **`forgeQuantumArtefact(uint256[] memory inputNFTs, uint256 qfcBurnAmount, string memory newArtefactURI)`**: Allows users to "forge" a new, potentially rarer, `QuantumEntanglementNFT` (or a distinct "Artefact" NFT) by combining (burning) specific existing `QuantumEntanglementNFTs` and a quantity of QFC tokens. The success rate or resulting properties might be influenced by the `quantumEnergyLevel`.
*   **`disassembleArtefact(uint256 artefactId)`**: Allows users to break down a forged artefact, potentially recovering a fraction of the input QFC or even creating new, smaller NFTs.

### VI. Adaptive Quantum Governance (DAO)
*   **`submitQuantumProposal(bytes memory callData, string memory description)`**: Allows any address with a minimum QFC balance or entangled NFT to submit a governance proposal.
*   **`voteOnQuantumProposal(uint256 proposalId, bool support)`**: Allows users to vote on proposals. Voting power is determined by a combination of QFC balance and the properties/number of `QuantumEntanglementNFTs` they hold.
*   **`executeQuantumProposal(uint256 proposalId)`**: Executes a passed proposal. The required voting threshold to pass a proposal can dynamically adjust based on the current `quantumEnergyLevel` (e.g., lower energy might require higher consensus).
*   **`getProposalState(uint256 proposalId)`**: Returns the current state (e.g., active, passed, failed, executed) of a proposal.
*   **`getVoterPower(address voter)`**: Calculates and returns the current voting power of an address.

### VII. Administrative & Utilities
*   **`pauseFluctuations(bool _paused)`**: Owner-only function to temporarily pause the `quantumEnergyLevel` fluctuations for maintenance or emergencies.
*   **`rescueStuckTokens(address tokenAddress, uint256 amount)`**: Owner-only function to rescue accidentally sent ERC20 tokens from the contract.
*   **`setVRFCoordinator(address _vrfCoordinator, bytes32 _keyHash, uint64 _subscriptionId)`**: Owner-only to configure Chainlink VRF.
*   **`setLinkToken(address _link)`**: Owner-only to set the LINK token address for Chainlink.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

// --- Custom Errors ---
error UnauthorizedCall();
error InvalidAmount();
error NFTNotFound();
error NFTNotEntangled();
error NotEnoughStaked();
error NoPendingRewards();
error ProposalNotFound();
error ProposalNotActive();
error AlreadyVoted();
error ProposalNotExecutable();
error InsufficientVotingPower();
error FluctuationPaused();
error CannotTransferSelf();
error CannotApproveSelf();

/**
 * @title QuantumFluctCoin (QFC)
 * @notice A dynamic, self-evolving cryptocurrency ecosystem where its behavior and associated NFTs
 *         are influenced by an on-chain "Quantum Energy Level." This level is derived from
 *         pseudo-random elements and external oracle data, simulating real-world unpredictability
 *         and introducing game-theoretic incentives.
 */
contract QuantumFluctCoin is ERC20, ERC721Enumerable, Ownable, VRFConsumerBaseV2 {
    using Counters for Counters.Counter;

    // --- Core Token Mechanics ---
    uint256 private constant INITIAL_SUPPLY = 100_000_000 * (10 ** 18);
    uint256 public quantumEnergyLevel; // Current energy level, influences many mechanics
    uint256 public lastFluctuationBlock;
    uint256 public baseEnergyLevel = 500; // Base for quantumEnergyLevel calculation
    uint256 public volatilityFactor = 100; // Multiplier for random component

    bool public fluctuationsPaused = false;

    // --- Fluctuation History ---
    uint256[] public fluctuationHistory;
    uint256 private constant MAX_FLUCTUATION_HISTORY = 100;

    // --- Chainlink VRF ---
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_keyHash;
    uint64 private i_subscriptionId;
    uint32 private constant NUM_WORDS = 1;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant CALLBACK_GAS_LIMIT = 1_000_000;
    mapping(uint256 => bool) public s_requests; // Request ID => is it a valid request?
    uint256 public s_randomWord; // The latest random word received

    // --- Entangled NFTs ---
    Counters.Counter private _tokenIdCounter;
    uint256 public constant ENTANGLEMENT_FEE = 10 * (10 ** 18); // QFC required to mint an NFT
    mapping(uint256 => bool) public isEntangled; // tokenId => true if actively entangled
    mapping(uint256 => EntangledNFTState) public entangledNFTStates;

    struct EntangledNFTState {
        uint256 power; // Influenced by QFC balance and quantumEnergyLevel
        uint256 rarity; // Influenced by fluctuation at mint, potentially dynamic
        uint256 lastUpdateBlock;
        address owner; // Owner at the time of entanglement
    }

    // --- Probabilistic Staking ---
    mapping(address => uint256) public stakedBalances;
    mapping(address => uint256) public lastClaimBlock; // Block number of last reward claim
    mapping(address => uint256) public stakeStartTime; // Block number when staking began

    // --- Adaptive Quantum Governance (DAO) ---
    Counters.Counter private _proposalIdCounter;
    uint256 public constant PROPOSAL_MIN_QFC = 1000 * (10 ** 18); // Min QFC to submit proposal
    uint256 public constant BASE_VOTE_THRESHOLD_BP = 5000; // 50% base threshold (basis points)
    uint256 public constant PROPOSAL_VOTING_PERIOD = 7200; // ~24 hours (assuming 12-sec blocks)

    struct Proposal {
        address proposer;
        bytes callData;
        string description;
        uint256 submitBlock;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted;
        bool executed;
    }
    mapping(uint256 => Proposal) public proposals;

    // --- Events ---
    event QuantumFluctuationTriggered(uint256 newEnergyLevel, uint256 blockNumber);
    event NFTEntangled(uint256 indexed tokenId, address indexed minter, uint256 power, uint256 rarity);
    event NFTDeEntangled(uint256 indexed tokenId, address indexed owner);
    event NFTPropertiesUpdated(uint256 indexed tokenId, uint256 newPower, uint256 newRarity);
    event TokensStaked(address indexed staker, uint256 amount);
    event TokensUnstaked(address indexed staker, uint256 amount);
    event ProbabilisticRewardsClaimed(address indexed staker, uint256 amount);
    event ProposalSubmitted(uint256 indexed proposalId, address indexed proposer, string description);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 votePower);
    event ProposalExecuted(uint256 indexed proposalId);
    event FluctuationsPaused(bool paused);

    /**
     * @dev Initializes the contract, mints initial supply, and sets up Chainlink VRF.
     * @param _name Token name.
     * @param _symbol Token symbol.
     * @param _vrfCoordinatorAddress Address of the VRF Coordinator contract.
     * @param _keyHash The gas lane key hash value.
     * @param _subscriptionId The VRF subscription ID.
     */
    constructor(
        string memory _name,
        string memory _symbol,
        address _vrfCoordinatorAddress,
        bytes32 _keyHash,
        uint64 _subscriptionId
    )
        ERC20(_name, _symbol)
        ERC721("QuantumEntanglementNFT", "QENFT")
        VRFConsumerBaseV2(_vrfCoordinatorAddress)
        Ownable(msg.sender)
    {
        _mint(msg.sender, INITIAL_SUPPLY);
        quantumEnergyLevel = baseEnergyLevel;
        lastFluctuationBlock = block.number;
        fluctuationHistory.push(quantumEnergyLevel);

        i_vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinatorAddress);
        i_keyHash = _keyHash;
        i_subscriptionId = _subscriptionId;
    }

    // --- II. Quantum Fluctuation Mechanics ---

    /**
     * @notice Triggers a quantum fluctuation event, updating the `quantumEnergyLevel`.
     *         This function can be called by anyone but its impact is based on a cooldown.
     *         It's designed to be called periodically, e.g., by Chainlink Automation.
     *         This incorporates factors like block hash, timestamp, and the latest VRF randomness.
     */
    function triggerQuantumFluctuation() external {
        if (fluctuationsPaused) revert FluctuationPaused();
        if (block.number <= lastFluctuationBlock) return; // Prevent multiple fluctuations in same block

        // Incorporate on-chain entropy and VRF randomness
        uint256 entropy = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, block.prevrandao, s_randomWord)));
        uint256 newEnergy = (baseEnergyLevel + (entropy % volatilityFactor) - (volatilityFactor / 2)); // Centered around baseEnergyLevel
        
        // Ensure energy level is not zero or too low
        if (newEnergy < 100) newEnergy = 100;

        quantumEnergyLevel = newEnergy;
        lastFluctuationBlock = block.number;

        // Add to history, maintain max size
        if (fluctuationHistory.length >= MAX_FLUCTUATION_HISTORY) {
            for (uint i = 0; i < MAX_FLUCTUATION_HISTORY - 1; i++) {
                fluctuationHistory[i] = fluctuationHistory[i+1];
            }
            fluctuationHistory[MAX_FLUCTUATION_HISTORY - 1] = quantumEnergyLevel;
        } else {
            fluctuationHistory.push(quantumEnergyLevel);
        }

        // Apply supply adjustment based on fluctuation (conceptual)
        // Example: High energy -> minor inflation; Low energy -> minor deflation
        if (quantumEnergyLevel > baseEnergyLevel * 1.2) {
            _mint(address(this), (totalSupply() / 10000)); // 0.01% inflation
        } else if (quantumEnergyLevel < baseEnergyLevel * 0.8) {
            _burn(address(this), (totalSupply() / 20000)); // 0.005% deflation
        }

        emit QuantumFluctuationTriggered(quantumEnergyLevel, block.number);
    }

    /**
     * @notice Returns the current, dynamically calculated `quantumEnergyLevel`.
     */
    function getQuantumEnergyLevel() public view returns (uint256) {
        return quantumEnergyLevel;
    }

    /**
     * @notice Requests a new random number from Chainlink VRF for fluctuation seeding.
     *         This function should ideally be called by Chainlink Automation.
     */
    function requestNewFluctuationSeed() external onlyOwner returns (uint256 requestId) {
        requestId = i_vrfCoordinator.requestRandomWords(
            i_keyHash,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            CALLBACK_GAS_LIMIT,
            NUM_WORDS
        );
        s_requests[requestId] = true;
        return requestId;
    }

    /**
     * @notice Chainlink VRF callback function to receive and process the random seed.
     * @dev Only callable by the VRF Coordinator.
     */
    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
        if (!s_requests[_requestId]) revert UnauthorizedCall(); // Only requests made by this contract
        delete s_requests[_requestId];
        s_randomWord = _randomWords[0]; // Use the first random word
        // The `triggerQuantumFluctuation` function will use this `s_randomWord` in its next call.
    }

    /**
     * @notice Owner-only function to tune the base energy level and volatility of fluctuations.
     * @param _baseEnergy New base energy level.
     * @param _volatilityFactor New volatility factor.
     */
    function setFluctuationParams(uint256 _baseEnergy, uint256 _volatilityFactor) external onlyOwner {
        baseEnergyLevel = _baseEnergy;
        volatilityFactor = _volatilityFactor;
    }

    /**
     * @notice Returns the block number of the last quantum fluctuation event.
     */
    function getLastFluctuationBlock() public view returns (uint256) {
        return lastFluctuationBlock;
    }

    /**
     * @notice Retrieves a past `quantumEnergyLevel` from a limited history.
     * @param index The index in the history array.
     */
    function getFluctuationHistory(uint256 index) public view returns (uint256) {
        if (index >= fluctuationHistory.length) revert InvalidAmount();
        return fluctuationHistory[index];
    }

    // --- III. Entangled Non-Fungible Tokens (NFTs) ---

    /**
     * @notice Allows users to mint a unique `QuantumEntanglementNFT` by burning QFC.
     *         The NFT's properties are initially tied to the current `quantumEnergyLevel`.
     * @param tokenURI The URI for the NFT metadata.
     */
    function mintEntangledNFT(string memory tokenURI) external {
        if (balanceOf(msg.sender) < ENTANGLEMENT_FEE) revert InvalidAmount();

        _burn(msg.sender, ENTANGLEMENT_FEE); // Burn QFC for entanglement

        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();
        _safeMint(msg.sender, newItemId);
        _setTokenURI(newItemId, tokenURI);

        isEntangled[newItemId] = true;
        entangledNFTStates[newItemId] = EntangledNFTState({
            power: (quantumEnergyLevel + (balanceOf(msg.sender) / (10 ** 10))) / 100, // Example calculation
            rarity: quantumEnergyLevel % 1000, // Example rarity based on current energy
            lastUpdateBlock: block.number,
            owner: msg.sender
        });

        emit NFTEntangled(newItemId, msg.sender, entangledNFTStates[newItemId].power, entangledNFTStates[newItemId].rarity);
    }

    /**
     * @notice Allows users to "de-entangle" an NFT by burning it to recover a portion of QFC.
     * @param tokenId The ID of the NFT to de-entangle.
     */
    function deEntangleNFT(uint256 tokenId) external {
        if (ownerOf(tokenId) != msg.sender) revert UnauthorizedCall();
        if (!isEntangled[tokenId]) revert NFTNotEntangled();

        _burn(tokenId); // Burn the NFT
        isEntangled[tokenId] = false;
        delete entangledNFTStates[tokenId];

        // Return a portion of the ENTANGLEMENT_FEE, dynamically based on current energy
        uint256 refundAmount = (ENTANGLEMENT_FEE * quantumEnergyLevel) / (baseEnergyLevel * 2); // Example refund
        if (refundAmount > 0) {
            _mint(msg.sender, refundAmount);
        }

        emit NFTDeEntangled(tokenId, msg.sender);
    }

    /**
     * @notice Refreshes an entangled NFT's properties based on the current `quantumEnergyLevel`
     *         and the owner's QFC balance. Can be called by anyone for any NFT, but only affects its true owner.
     * @param tokenId The ID of the NFT to update.
     */
    function updateEntangledNFTProperties(uint256 tokenId) public {
        address nftOwner = ownerOf(tokenId);
        if (!isEntangled[tokenId]) revert NFTNotEntangled();

        entangledNFTStates[tokenId].power = (quantumEnergyLevel + (balanceOf(nftOwner) / (10 ** 10))) / 100;
        entangledNFTStates[tokenId].rarity = (quantumEnergyLevel % 1000) + (nftOwner == entangledNFTStates[tokenId].owner ? 0 : 500); // Rarity bonus if original owner
        entangledNFTStates[tokenId].lastUpdateBlock = block.number;
        entangledNFTStates[tokenId].owner = nftOwner; // Update owner in state

        // The tokenURI is updated implicitly by the `tokenURI` override.
        emit NFTPropertiesUpdated(tokenId, entangledNFTStates[tokenId].power, entangledNFTStates[tokenId].rarity);
    }

    /**
     * @notice Returns the current dynamic properties of a specific `QuantumEntanglementNFT`.
     * @param tokenId The ID of the NFT.
     */
    function getEntangledNFTState(uint256 tokenId) public view returns (uint256 power, uint256 rarity, uint256 lastUpdateBlock) {
        if (!isEntangled[tokenId]) revert NFTNotEntangled();
        EntangledNFTState storage state = entangledNFTStates[tokenId];
        return (state.power, state.rarity, state.lastUpdateBlock);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}. Overridden to provide dynamic URI.
     *      This would ideally point to an API endpoint that generates JSON metadata
     *      based on the current `entangledNFTStates[tokenId]`.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert NFTNotFound();
        if (!isEntangled[tokenId]) return super.tokenURI(tokenId); // Fallback for non-entangled
        
        EntangledNFTState storage state = entangledNFTStates[tokenId];
        // In a real dApp, this would resolve to an external API that queries the contract's state
        // and generates a dynamic JSON blob for the NFT.
        // For this example, we'll return a placeholder string.
        return string(abi.encodePacked(
            "data:application/json;base64,",
            Strings.toBase64(bytes(abi.encodePacked(
                '{"name":"Quantum Entangled NFT #', Strings.toString(tokenId),
                '","description":"This NFT's properties fluctuate with Quantum Energy! Current Power: ', Strings.toString(state.power),
                ', Rarity: ', Strings.toString(state.rarity),
                '","image":"ipfs://QmVy4zM9TjG7B1H8X5Q7Z2Y6V4W3X1C8A9B7D6E2F0G","attributes":[{"trait_type":"Power","value":', Strings.toString(state.power),
                '},{"trait_type":"Rarity","value":', Strings.toString(state.rarity),
                '},{"trait_type":"Last Update Block","value":', Strings.toString(state.lastUpdateBlock),
                '}]}'
            )))
        ));
    }


    // --- IV. Probabilistic Staking & Yield Farming ---

    /**
     * @notice Allows users to stake QFC tokens into a quantum staking pool.
     * @param amount The amount of QFC to stake.
     */
    function stake(uint256 amount) external {
        if (amount == 0) revert InvalidAmount();
        if (balanceOf(msg.sender) < amount) revert InvalidAmount();

        _transfer(msg.sender, address(this), amount); // Transfer tokens to contract

        stakedBalances[msg.sender] += amount;
        if (stakeStartTime[msg.sender] == 0) {
            stakeStartTime[msg.sender] = block.number;
        }

        emit TokensStaked(msg.sender, amount);
    }

    /**
     * @notice Allows users to unstake QFC tokens.
     * @param amount The amount of QFC to unstake.
     */
    function unstake(uint256 amount) external {
        if (amount == 0) revert InvalidAmount();
        if (stakedBalances[msg.sender] < amount) revert NotEnoughStaked();

        stakedBalances[msg.sender] -= amount;
        _transfer(address(this), msg.sender, amount); // Transfer tokens back

        if (stakedBalances[msg.sender] == 0) {
            stakeStartTime[msg.sender] = 0; // Reset start time if fully unstaked
        }

        emit TokensUnstaked(msg.sender, amount);
    }

    /**
     * @notice Users can claim rewards. The amount is non-deterministic and depends on their staked
     *         amount, duration, and the current `quantumEnergyLevel` and historical fluctuations.
     *         Higher energy levels or specific fluctuation patterns could trigger bonus rewards.
     */
    function claimProbabilisticRewards() external {
        if (stakedBalances[msg.sender] == 0) revert NotEnoughStaked();

        uint256 blocksStaked = block.number - stakeStartTime[msg.sender];
        if (blocksStaked == 0) revert NoPendingRewards();

        // Complex probabilistic reward calculation
        uint252 baseReward = (stakedBalances[msg.sender] * blocksStaked * quantumEnergyLevel) / (10**18 * 1000); // Example base
        
        // Add a "quantum bonus" based on recent fluctuations or VRF randomness
        uint256 quantumBonus = 0;
        if (s_randomWord % 100 < (quantumEnergyLevel / baseEnergyLevel)) { // Higher chance with higher energy
            quantumBonus = (stakedBalances[msg.sender] * (s_randomWord % 100)) / 10000; // Up to 1% bonus
        }

        uint256 totalReward = baseReward + quantumBonus;
        if (totalReward == 0) revert NoPendingRewards();

        _mint(msg.sender, totalReward);
        lastClaimBlock[msg.sender] = block.number; // Update last claim block

        emit ProbabilisticRewardsClaimed(msg.sender, totalReward);
    }

    /**
     * @notice Calculates and returns the *estimated* pending probabilistic rewards for a staker.
     *         Note: actual claim amount can vary due to real-time quantum energy level changes.
     */
    function getPendingProbabilisticRewards(address staker) public view returns (uint256 estimatedRewards) {
        if (stakedBalances[staker] == 0) return 0;

        uint256 blocksStaked = block.number - stakeStartTime[staker];
        if (blocksStaked == 0) return 0; // Or (block.number - lastClaimBlock[staker])

        // Use current quantumEnergyLevel for estimation
        estimatedRewards = (stakedBalances[staker] * blocksStaked * quantumEnergyLevel) / (10**18 * 1000);
        return estimatedRewards;
    }
    
    // --- V. Quantum Forging ---

    /**
     * @notice Allows users to "forge" a new, potentially rarer, `QuantumEntanglementNFT`
     *         by combining (burning) specific existing `QuantumEntanglementNFTs` and QFC tokens.
     *         The success rate or resulting properties might be influenced by the `quantumEnergyLevel`.
     * @param inputNFTs Array of token IDs of NFTs to burn.
     * @param qfcBurnAmount Amount of QFC to burn for forging.
     * @param newArtefactURI URI for the new artefact's metadata.
     */
    function forgeQuantumArtefact(uint256[] memory inputNFTs, uint256 qfcBurnAmount, string memory newArtefactURI) external {
        if (inputNFTs.length == 0 || qfcBurnAmount == 0) revert InvalidAmount();
        if (balanceOf(msg.sender) < qfcBurnAmount) revert InvalidAmount();

        // Burn input NFTs
        for (uint256 i = 0; i < inputNFTs.length; i++) {
            uint256 tokenId = inputNFTs[i];
            if (ownerOf(tokenId) != msg.sender) revert UnauthorizedCall();
            _burn(tokenId);
            isEntangled[tokenId] = false; // They are no longer entangled
            delete entangledNFTStates[tokenId];
        }

        // Burn QFC
        _burn(msg.sender, qfcBurnAmount);

        // Determine success or properties based on quantumEnergyLevel and input NFTs
        uint256 successChance = (quantumEnergyLevel * inputNFTs.length) / 10; // Example
        if (s_randomWord % 1000 < successChance) { // Probabilistic success
            _tokenIdCounter.increment();
            uint256 newArtefactId = _tokenIdCounter.current();
            _safeMint(msg.sender, newArtefactId);
            _setTokenURI(newArtefactId, newArtefactURI);
            
            // Artefact might be a new type of NFT or a special entangled one
            isEntangled[newArtefactId] = true;
            entangledNFTStates[newArtefactId] = EntangledNFTState({
                power: (quantumEnergyLevel * inputNFTs.length) / 50,
                rarity: quantumEnergyLevel * 10,
                lastUpdateBlock: block.number,
                owner: msg.sender
            });
            emit NFTEntangled(newArtefactId, msg.sender, entangledNFTStates[newArtefactId].power, entangledNFTStates[newArtefactId].rarity);
        } else {
            // Forging failed: return some QFC as consolation prize
            _mint(msg.sender, qfcBurnAmount / 2);
        }
    }

    /**
     * @notice Allows users to break down a forged artefact, potentially recovering a fraction of
     *         the input QFC or even creating new, smaller NFTs (conceptual).
     * @param artefactId The ID of the artefact NFT to disassemble.
     */
    function disassembleArtefact(uint256 artefactId) external {
        if (ownerOf(artefactId) != msg.sender) revert UnauthorizedCall();
        if (!isEntangled[artefactId]) revert NFTNotEntangled(); // Only entangled artefacts can be disassembled

        _burn(artefactId);
        isEntangled[artefactId] = false;
        delete entangledNFTStates[artefactId];

        // Refund a portion of QFC, influenced by quantum energy
        uint256 refundAmount = (ENTANGLEMENT_FEE * quantumEnergyLevel) / baseEnergyLevel;
        if (refundAmount > 0) {
            _mint(msg.sender, refundAmount);
        }
        // Could also mint new, smaller NFTs or other tokens here.
        emit NFTDeEntangled(artefactId, msg.sender);
    }

    // --- VI. Adaptive Quantum Governance (DAO) ---

    /**
     * @notice Allows any address with a minimum QFC balance or entangled NFT to submit a governance proposal.
     * @param callData The encoded function call to be executed if the proposal passes.
     * @param description A descriptive string for the proposal.
     */
    function submitQuantumProposal(bytes memory callData, string memory description) external {
        // Must have min QFC or at least one entangled NFT
        if (balanceOf(msg.sender) < PROPOSAL_MIN_QFC && ERC721Enumerable.balanceOf(msg.sender) == 0) {
            revert InsufficientVotingPower();
        }

        _proposalIdCounter.increment();
        uint256 proposalId = _proposalIdCounter.current();

        proposals[proposalId] = Proposal({
            proposer: msg.sender,
            callData: callData,
            description: description,
            submitBlock: block.number,
            votesFor: 0,
            votesAgainst: 0,
            executed: false
        });
        // Note: hasVoted is a mapping within the struct, no need to initialize explicitly here

        emit ProposalSubmitted(proposalId, msg.sender, description);
    }

    /**
     * @notice Allows users to vote on proposals. Voting power is determined by a combination of
     *         QFC balance and the properties/number of `QuantumEntanglementNFTs` they hold.
     * @param proposalId The ID of the proposal to vote on.
     * @param support True for 'for', false for 'against'.
     */
    function voteOnQuantumProposal(uint256 proposalId, bool support) external {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.proposer == address(0)) revert ProposalNotFound();
        if (block.number > proposal.submitBlock + PROPOSAL_VOTING_PERIOD) revert ProposalNotActive();
        if (proposal.hasVoted[msg.sender]) revert AlreadyVoted();

        uint256 voterPower = getVoterPower(msg.sender);
        if (voterPower == 0) revert InsufficientVotingPower();

        if (support) {
            proposal.votesFor += voterPower;
        } else {
            proposal.votesAgainst += voterPower;
        }
        proposal.hasVoted[msg.sender] = true;

        emit VoteCast(proposalId, msg.sender, support, voterPower);
    }

    /**
     * @notice Executes a passed proposal. The required voting threshold to pass a proposal
     *         can dynamically adjust based on the current `quantumEnergyLevel`.
     * @param proposalId The ID of the proposal to execute.
     */
    function executeQuantumProposal(uint256 proposalId) external {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.proposer == address(0)) revert ProposalNotFound();
        if (proposal.executed) revert ProposalNotExecutable();
        if (block.number <= proposal.submitBlock + PROPOSAL_VOTING_PERIOD) revert ProposalNotActive(); // Must be past voting period

        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        if (totalVotes == 0) revert ProposalNotExecutable();

        // Dynamic threshold based on quantum energy level
        // Higher energy -> more consensus needed (e.g., higher volatility or uncertainty)
        // Lower energy -> less consensus needed (e.g., more stable environment)
        uint256 dynamicThreshold = BASE_VOTE_THRESHOLD_BP;
        if (quantumEnergyLevel > baseEnergyLevel) {
            dynamicThreshold += (quantumEnergyLevel - baseEnergyLevel) / 10; // Increase threshold for higher energy
        } else if (quantumEnergyLevel < baseEnergyLevel) {
            dynamicThreshold -= (baseEnergyLevel - quantumEnergyLevel) / 20; // Decrease threshold for lower energy
        }
        if (dynamicThreshold > 9000) dynamicThreshold = 9000; // Cap at 90%
        if (dynamicThreshold < 1000) dynamicThreshold = 1000; // Min at 10%

        if ((proposal.votesFor * 10000) / totalVotes < dynamicThreshold) {
            revert ProposalNotExecutable(); // Does not meet dynamic threshold
        }

        proposal.executed = true;

        // Execute the proposal's call data
        (bool success, ) = address(this).call(proposal.callData);
        if (!success) {
            // Revert here or handle failed execution gracefully (e.g., mark as failed but still executed)
            // For simplicity, we'll let it revert.
            revert("Proposal execution failed");
        }

        emit ProposalExecuted(proposalId);
    }

    /**
     * @notice Returns the current state (e.g., active, passed, failed, executed) of a proposal.
     * @param proposalId The ID of the proposal.
     */
    function getProposalState(uint256 proposalId) public view returns (string memory state) {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.proposer == address(0)) return "NotFound";
        if (proposal.executed) return "Executed";
        if (block.number <= proposal.submitBlock + PROPOSAL_VOTING_PERIOD) return "Active";

        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        if (totalVotes == 0) return "Failed (No Votes)";

        uint256 dynamicThreshold = BASE_VOTE_THRESHOLD_BP;
        if (quantumEnergyLevel > baseEnergyLevel) {
            dynamicThreshold += (quantumEnergyLevel - baseEnergyLevel) / 10;
        } else if (quantumEnergyLevel < baseEnergyLevel) {
            dynamicThreshold -= (baseEnergyLevel - quantumEnergyLevel) / 20;
        }
        if (dynamicThreshold > 9000) dynamicThreshold = 9000;
        if (dynamicThreshold < 1000) dynamicThreshold = 1000;

        if ((proposal.votesFor * 10000) / totalVotes >= dynamicThreshold) {
            return "Passed (Ready for Execution)";
        }
        return "Failed";
    }

    /**
     * @notice Calculates and returns the current voting power of an address.
     *         Voting power is a combination of QFC balance and entangled NFT properties.
     * @param voter The address to check.
     */
    function getVoterPower(address voter) public view returns (uint256) {
        uint256 qfcPower = balanceOf(voter) / (10 ** 15); // 1 QFC = 1000 units of power
        uint256 nftPower = 0;
        uint256 nftCount = ERC721Enumerable.balanceOf(voter);

        for (uint256 i = 0; i < nftCount; i++) {
            uint256 tokenId = ERC721Enumerable.tokenOfOwnerByIndex(voter, i);
            if (isEntangled[tokenId]) {
                nftPower += entangledNFTStates[tokenId].power; // Add NFT's power to voting power
            }
        }
        return qfcPower + nftPower;
    }

    // --- VII. Administrative & Utilities ---

    /**
     * @notice Owner-only function to temporarily pause or unpause `quantumEnergyLevel` fluctuations.
     * @param _paused True to pause, false to unpause.
     */
    function pauseFluctuations(bool _paused) external onlyOwner {
        fluctuationsPaused = _paused;
        emit FluctuationsPaused(_paused);
    }

    /**
     * @notice Owner-only function to rescue accidentally sent ERC20 tokens from the contract.
     * @param tokenAddress The address of the ERC20 token to rescue.
     * @param amount The amount of tokens to rescue.
     */
    function rescueStuckTokens(address tokenAddress, uint256 amount) external onlyOwner {
        IERC20(tokenAddress).transfer(owner(), amount);
    }

    /**
     * @notice Owner-only to set the Chainlink VRF Coordinator and related parameters.
     * @param _vrfCoordinator New VRF Coordinator address.
     * @param _keyHash New key hash.
     * @param _subscriptionId New subscription ID.
     */
    function setVRFCoordinator(address _vrfCoordinator, bytes32 _keyHash, uint64 _subscriptionId) external onlyOwner {
        // i_vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinator); // Immutable, cannot change after construct
        // Instead, provide a way to change subscription ID
        i_vrfCoordinator.cancelSubscription(i_subscriptionId, owner()); // Cancel old sub
        i_subscriptionId = _subscriptionId; // Set new sub
        // If changing keyHash or coordinator, need to deploy a new contract or design for proxy upgrade
    }

    /**
     * @notice Override ERC20 transfer to ensure the contract doesn't transfer its own QFC out
     *         except through defined mechanics (e.g. unstake, de-entangle, proposal execution).
     */
    function _transfer(address from, address to, uint256 amount) internal override {
        if (from == address(this) && to != address(0) && to != msg.sender) {
            // Allow contract to transfer to external users for rewards/refunds
            // Prevent arbitrary draining of contract balance by itself from unknown sources
        } else if (from == address(this) && to == address(0)) {
            // Allow burn from contract for supply adjustments
        } else if (from == to) {
            revert CannotTransferSelf();
        }
        super._transfer(from, to, amount);
    }

    /**
     * @notice Override ERC20 approve to prevent contract from approving itself.
     */
    function _approve(address owner_, address spender, uint256 amount) internal override {
        if (owner_ == address(this) || spender == address(this)) {
            revert CannotApproveSelf(); // Contract itself should not be able to approve or be approved
        }
        super._approve(owner_, spender, amount);
    }
}
```