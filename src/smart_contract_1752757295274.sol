This smart contract, `PrognosysNexus`, introduces a unique decentralized application concept that intertwines **dynamic NFTs**, **verifiable prediction markets**, and a **gamified collective intelligence model** aimed at simulating decentralized AI training. It addresses the prompt's request for advanced, creative, and trendy functions by moving beyond simple token standards to create an ecosystem where user participation directly influences both their unique digital assets (Prognosticator NFTs) and a communal predictive intelligence.

The contract does not duplicate existing open-source libraries by re-implementing core ERC721 functionalities and access control mechanisms tailored to its specific needs, rather than importing large external dependencies.

---

## `PrognosysNexus` Smart Contract

### Outline:

*   **I. Contract Management & Security:** Core functionalities for contract ownership, pausing, and emergency recovery, along with oracle and fee recipient management.
*   **II. Prognosticator NFTs (pNFTs) - ERC721 Core & Dynamics:** Implementation of a custom ERC721 token (`PrognosticatorNFT`) that features dynamic metadata based on user performance and contributions.
*   **III. Prediction Market Lifecycle:** Functions for creating, participating in, resolving, and claiming winnings from decentralized prediction markets.
*   **IV. Collective Intelligence & Model Refinement:** A unique mechanism for users to contribute data ("signals") and validate them, simulating a decentralized machine learning feedback loop that influences an abstract "collective model".
*   **V. Gamification, Leaderboards & Achievements:** Functions to retrieve performance metrics, reflecting the gamified aspects of the protocol.
*   **VI. Decentralized Governance (Simulated):** Basic functions demonstrating how key parameters might be changed via a governance process.
*   **VII. View & Query Functions:** Public methods to inspect the state of NFTs, markets, and user data.

### Function Summary:

1.  **`constructor()`**: Initializes the contract upon deployment, setting the initial owner and other default parameters.
2.  **`setMarketOracle(address _oracle, bool _isAuthorized)`**: Authorizes or de-authorizes an address to act as a trusted oracle for resolving prediction markets. Only callable by the contract owner.
3.  **`setFeeRecipient(address _newRecipient)`**: Allows the contract owner to change the address designated to receive protocol fees.
4.  **`setBaseURI(string memory _newBaseURI)`**: Updates the base URI for Prognosticator NFT metadata, enabling dynamic and off-chain metadata management.
5.  **`pauseContract()`**: An emergency function allowing the owner to pause critical contract operations (e.g., market creation, predictions) to mitigate risks.
6.  **`unpauseContract()`**: Resumes contract operations after a pause.
7.  **`emergencyWithdraw(address _tokenAddress)`**: Provides a mechanism for the owner to withdraw any accidentally sent ERC20 tokens from the contract.

8.  **`mintPrognosticatorNFT(uint256 _initialAccuracy)`**: Mints a new unique Prognosticator NFT (pNFT) for the caller, initializing its dynamic attributes like accuracy and contribution scores.
9.  **`upgradePrognosticatorNFT(uint256 _tokenId, uint256 _traitIndex)`**: Allows pNFT owners to enhance specific dynamic visual or numerical traits of their NFT, potentially requiring a fee or certain achievements.
10. **`burnPrognosticatorNFT(uint256 _tokenId)`**: Enables a pNFT owner to permanently destroy their NFT, removing it from circulation.

11. **`createPredictionMarket(string calldata _question, string[] calldata _outcomes, address _resolverOracle, uint256 _resolutionTimestamp, uint256 _minStakeAmount)`**: Initiates a new verifiable prediction market, defining its question, possible outcomes, and resolution details.
12. **`submitPrediction(uint256 _marketId, uint256 _pNFTId, uint256 _outcomeIndex, uint256 _amount)`**: Allows users to stake ERC20 tokens on a chosen outcome within a prediction market, leveraging the influence and potential rewards tied to their pNFT.
13. **`resolvePredictionMarket(uint256 _marketId, uint256 _winningOutcomeIndex)`**: Called by an authorized oracle to declare the winning outcome of a market and trigger the distribution of the prize pool.
14. **`claimPredictionWinnings(uint256 _marketId, uint256 _pNFTId)`**: Enables successful predictors (those who staked on the winning outcome) to claim their proportional share of the market's prize pool.
15. **`cancelPredictionMarket(uint256 _marketId)`**: Allows the contract owner or authorized governance to cancel a market (e.g., due to invalid oracle data), refunding all staked amounts.

16. **`submitCollectiveSignal(uint256 _pNFTId, bytes32 _signalHash, uint256 _signalType)`**: Users submit a cryptographic hash of off-chain data ("signals") to contribute to the collective intelligence model, potentially for a fee. This is a crucial step for the decentralized AI training aspect.
17. **`validateCollectiveSignal(uint256 _signalId, bool _isValid)`**: A gamified and decentralized process where other pNFT holders can stake and vote on the validity/accuracy of submitted signals. Successful validation/invalidation earns rewards and influences the signal's weight.
18. **`updateModelParameters(uint256[] calldata _validatedSignalIds, bytes32 _newModelHash)`**: A governance-approved function (or triggered by highly accurate pNFTs) to formally update the abstract "collective prediction model" based on aggregated and validated signals, reflecting a "learning" process.
19. **`claimContributionRewards(uint256[] calldata _signalIds)`**: Rewards users for submitting and/or successfully validating signals that are deemed valuable to the collective intelligence model.

20. **`getPNFTAccuracyScore(uint256 _tokenId)`**: Retrieves the current accuracy score of a specific Prognosticator NFT, reflecting its owner's past prediction success.
21. **`getPNFTContributionScore(uint256 _tokenId)`**: Retrieves the total contribution score of a pNFT, based on its owner's engagement in submitting and validating signals.
22. **`getMarketStatus(uint256 _marketId)`**: Returns the current status of a prediction market (e.g., Open, Closed, Resolved, Cancelled).
23. **`getUserMarketPrediction(uint256 _marketId, uint256 _pNFTId)`**: Fetches the details of a specific pNFT's prediction within a given market.
24. **`tokenURI(uint256 _tokenId)`**: Generates and returns the dynamic metadata URI for a Prognosticator NFT, allowing its appearance to change based on its scores and achievements.
25. **`getTopPrognosticators(uint256 _limit)`**: Returns a list of the top Prognosticator NFTs based on their accuracy scores, demonstrating a leaderboard feature. (Note: On-chain sorting for large lists is gas-intensive, this would be for smaller subsets or an off-chain indexed feature).

*(The following functions are standard ERC721 implementations, provided to ensure compliance without duplicating OpenZeppelin libraries directly)*
26. **`balanceOf(address owner) view returns (uint256)`**: Returns the number of tokens in an owner's account.
27. **`ownerOf(uint256 tokenId) view returns (address)`**: Returns the owner of the given token ID.
28. **`approve(address to, uint256 tokenId)`**: Approves another address to transfer a specific token.
29. **`getApproved(uint256 tokenId) view returns (address)`**: Returns the approved address for a single token.
30. **`setApprovalForAll(address operator, bool approved)`**: Approves or disapproves an operator to manage all of the owner's tokens.
31. **`isApprovedForAll(address owner, address operator) view returns (bool)`**: Checks if an operator is approved for all of the owner's tokens.
32. **`transferFrom(address from, address to, uint256 tokenId)`**: Transfers ownership of a token from one address to another (unconditional).
33. **`safeTransferFrom(address from, address to, uint256 tokenId)`**: Transfers ownership safely, checking if the recipient is a contract that can handle ERC721 tokens.
34. **`safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data)`**: Extended safe transfer with additional data.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title PrognosysNexus
 * @author YourNameHere
 * @dev A cutting-edge smart contract combining dynamic NFTs, verifiable prediction markets,
 *      and a gamified collective intelligence model.
 *      Users mint "Prognosticator NFTs" (pNFTs) which evolve based on their prediction
 *      accuracy and contributions to a "collective intelligence model" via submitting
 *      and validating "signals". This contract simulates a decentralized AI training loop
 *      where off-chain AI model parameters are influenced by on-chain validated data.
 *
 * Outline:
 *   I. Contract Management & Security
 *   II. Prognosticator NFTs (pNFTs) - ERC721 Core & Dynamics
 *   III. Prediction Market Lifecycle
 *   IV. Collective Intelligence & Model Refinement
 *   V. Gamification, Leaderboards & Achievements
 *   VI. Decentralized Governance (Simulated)
 *   VII. View & Query Functions
 *
 * Function Summary:
 *   1. constructor()
 *   2. setMarketOracle(address _oracle, bool _isAuthorized)
 *   3. setFeeRecipient(address _newRecipient)
 *   4. setBaseURI(string memory _newBaseURI)
 *   5. pauseContract()
 *   6. unpauseContract()
 *   7. emergencyWithdraw(address _tokenAddress)
 *   8. mintPrognosticatorNFT(uint256 _initialAccuracy)
 *   9. upgradePrognosticatorNFT(uint256 _tokenId, uint256 _traitIndex)
 *   10. burnPrognosticatorNFT(uint256 _tokenId)
 *   11. createPredictionMarket(string calldata _question, string[] calldata _outcomes, address _resolverOracle, uint256 _resolutionTimestamp, uint256 _minStakeAmount)
 *   12. submitPrediction(uint256 _marketId, uint256 _pNFTId, uint256 _outcomeIndex, uint256 _amount)
 *   13. resolvePredictionMarket(uint256 _marketId, uint256 _winningOutcomeIndex)
 *   14. claimPredictionWinnings(uint256 _marketId, uint256 _pNFTId)
 *   15. cancelPredictionMarket(uint256 _marketId)
 *   16. submitCollectiveSignal(uint256 _pNFTId, bytes32 _signalHash, uint256 _signalType)
 *   17. validateCollectiveSignal(uint256 _signalId, bool _isValid)
 *   18. updateModelParameters(uint256[] calldata _validatedSignalIds, bytes32 _newModelHash)
 *   19. claimContributionRewards(uint256[] calldata _signalIds)
 *   20. getPNFTAccuracyScore(uint256 _tokenId)
 *   21. getPNFTContributionScore(uint256 _tokenId)
 *   22. getMarketStatus(uint256 _marketId)
 *   23. getUserMarketPrediction(uint256 _marketId, uint256 _pNFTId)
 *   24. tokenURI(uint256 _tokenId)
 *   25. getTopPrognosticators(uint256 _limit)
 *   26. balanceOf(address owner)
 *   27. ownerOf(uint256 tokenId)
 *   28. approve(address to, uint256 tokenId)
 *   29. getApproved(uint256 tokenId)
 *   30. setApprovalForAll(address operator, bool approved)
 *   31. isApprovedForAll(address owner, address operator)
 *   32. transferFrom(address from, address to, uint256 tokenId)
 *   33. safeTransferFrom(address from, address to, uint256 tokenId)
 *   34. safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data)
*/

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint255);
}

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

contract PrognosysNexus {
    // --- Custom Errors ---
    error NotOwner();
    error Paused();
    error NotPaused();
    error InvalidPNFTId();
    error NotPNFTOwner();
    error UnauthorizedOracle();
    error MarketNotFound();
    error MarketNotOpen();
    error MarketAlreadyResolved();
    error MarketNotResolved();
    error InvalidOutcomeIndex();
    error InsufficientStake();
    error PredictionAlreadyMade();
    error MarketResolutionTimeNotReached();
    error MarketActive();
    error SignalNotFound();
    error SignalAlreadyValidated();
    error InsufficientBalance();
    error TransferFailed();
    error ApprovalFailed();
    error CannotSelfApprove();
    error NotApprovedOrOwner();
    error InvalidRecipient();
    error CannotTransferToZeroAddress();
    error NotPNFTMinter();

    // --- State Variables: Contract Management ---
    address public owner;
    bool public paused;
    address public feeRecipient;
    uint256 public constant MARKET_CREATION_FEE = 0.01 ether; // Example fee
    uint256 public constant SIGNAL_SUBMISSION_FEE = 0.001 ether; // Example fee
    uint256 public constant PROTOCOL_FEE_PERCENT = 5; // 5% of winnings

    mapping(address => bool) public authorizedMarketOracles;
    mapping(address => bool) public authorizedPNFTMinters; // Addresses allowed to mint new pNFTs

    // --- State Variables: Prognosticator NFTs (pNFTs) - ERC721 Core ---
    string private _name;
    string private _symbol;
    string private _baseURI;
    uint256 private _nextTokenId;

    // ERC721 mappings
    mapping(uint256 => address) private _owners; // Token ID to owner address
    mapping(address => uint256) private _balances; // Owner address to token count
    mapping(uint256 => address) private _tokenApprovals; // Token ID to approved address
    mapping(address => mapping(address => bool)) private _operatorApprovals; // Owner to (operator to approved)

    // --- State Variables: Prognosticator NFT (pNFT) Dynamics ---
    struct PrognosticatorNFT {
        address owner;
        uint256 accuracyScore;      // Reflects successful predictions (e.g., points for correct outcomes)
        uint256 contributionScore;  // Reflects validated signal contributions
        uint256 totalPredictions;   // Total predictions made by this pNFT
        uint256 successfulPredictions; // Total successful predictions
        uint256 lastActivityTimestamp;
        // Future: `TraitSet` mapping for dynamic visual attributes
    }
    mapping(uint256 => PrognosticatorNFT) public pNFTs;
    mapping(address => uint256[]) public ownerPNFTs; // For convenience to list a user's pNFTs

    // --- State Variables: Prediction Markets ---
    enum MarketStatus { Open, Closed, Resolved, Cancelled }
    struct PredictionMarket {
        uint256 id;
        string question;
        string[] outcomes;
        address resolverOracle;
        uint256 resolutionTimestamp;
        uint256 winningOutcomeIndex; // Index of the winning outcome, MAX_UINT256 if not resolved
        uint256 totalStaked;
        MarketStatus status;
        uint256 minStakeAmount;
        mapping(uint256 => uint256) totalStakedByOutcome; // outcomeIndex => total amount staked
    }
    mapping(uint256 => PredictionMarket) public predictionMarkets;
    uint256 private _nextMarketId;

    struct Prediction {
        uint256 pNFTId;
        uint256 stakedAmount;
        uint256 chosenOutcomeIndex;
        bool claimed;
    }
    mapping(uint256 => mapping(uint256 => Prediction)) public marketPNFTPredictions; // marketId => pNFTId => Prediction

    // --- State Variables: Collective Intelligence & Signals ---
    enum SignalValidationStatus { Pending, Validated, Invalidated }
    struct SignalContribution {
        uint256 id;
        uint256 pNFTId;
        bytes32 signalHash; // Cryptographic hash of the off-chain data signal
        uint256 signalType; // Categorization of the signal (e.g., 0 for market data, 1 for sentiment)
        uint256 timestamp;
        SignalValidationStatus status;
        uint256 validationStakeAmount; // Stake required to validate/invalidate
        mapping(uint256 => bool) validators; // pNFTId => voted (true if validated, false if invalidated)
        uint256 positiveValidations; // Count of pNFTs that validated this signal
        uint256 negativeValidations; // Count of pNFTs that invalidated this signal
    }
    mapping(uint256 => SignalContribution) public collectiveSignals;
    uint256 private _nextSignalId;

    // --- Events ---
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Paused(address account);
    event Unpaused(address account);
    event FeeRecipientChanged(address indexed oldRecipient, address indexed newRecipient);
    event BaseURIUpdated(string newBaseURI);
    event OracleAuthorized(address indexed oracle, bool isAuthorized);

    // ERC721 Events
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    // pNFT Events
    event PNFTMinted(uint256 indexed tokenId, address indexed owner, uint256 initialAccuracy);
    event PNFTUpgraded(uint256 indexed tokenId, uint256 traitIndex);
    event PNFTBurned(uint256 indexed tokenId, address indexed owner);
    event PNFTAccuracyUpdated(uint256 indexed tokenId, uint256 newAccuracy);
    event PNFTContributionUpdated(uint256 indexed tokenId, uint256 newContribution);

    // Prediction Market Events
    event MarketCreated(uint256 indexed marketId, string question, uint256 resolutionTimestamp);
    event PredictionSubmitted(uint256 indexed marketId, uint256 indexed pNFTId, uint256 outcomeIndex, uint256 amount);
    event MarketResolved(uint256 indexed marketId, uint256 winningOutcomeIndex);
    event WinningsClaimed(uint256 indexed marketId, uint256 indexed pNFTId, uint256 amount);
    event MarketCancelled(uint256 indexed marketId);

    // Collective Intelligence Events
    event SignalSubmitted(uint256 indexed signalId, uint256 indexed pNFTId, bytes32 signalHash, uint256 signalType);
    event SignalValidated(uint256 indexed signalId, uint256 indexed pNFTId, bool isValid);
    event ModelParametersUpdated(bytes32 newModelHash, uint256[] validatedSignalIds);
    event ContributionRewardsClaimed(uint256 indexed pNFTId, uint256 amount);

    // --- Constructor ---
    constructor() {
        owner = msg.sender;
        feeRecipient = msg.sender;
        paused = false;
        _name = "Prognosys Nexus NFT";
        _symbol = "PNXN";
        _baseURI = "ipfs://QmbXyZ123PNXN/"; // Example base URI
        _nextTokenId = 1;
        _nextMarketId = 1;
        _nextSignalId = 1;
        authorizedPNFTMinters[msg.sender] = true; // Owner can mint pNFTs by default
        emit OwnershipTransferred(address(0), msg.sender);
    }

    // --- I. Contract Management & Security ---
    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    modifier whenNotPaused() {
        if (paused) revert Paused();
        _;
    }

    modifier whenPaused() {
        if (!paused) revert NotPaused();
        _;
    }

    modifier onlyAuthorizedOracle(uint256 _marketId) {
        if (!authorizedMarketOracles[msg.sender] || predictionMarkets[_marketId].resolverOracle != msg.sender) {
            revert UnauthorizedOracle();
        }
        _;
    }

    modifier onlyPNFTMinter() {
        if (!authorizedPNFTMinters[msg.sender]) revert NotPNFTMinter();
        _;
    }

    /**
     * @dev Authorizes or de-authorizes an address to act as a trusted oracle for resolving prediction markets.
     * @param _oracle The address to authorize/de-authorize.
     * @param _isAuthorized True to authorize, false to de-authorize.
     */
    function setMarketOracle(address _oracle, bool _isAuthorized) external onlyOwner {
        authorizedMarketOracles[_oracle] = _isAuthorized;
        emit OracleAuthorized(_oracle, _isAuthorized);
    }

    /**
     * @dev Allows the contract owner to change the address designated to receive protocol fees.
     * @param _newRecipient The new address for fee collection.
     */
    function setFeeRecipient(address _newRecipient) external onlyOwner {
        address oldRecipient = feeRecipient;
        feeRecipient = _newRecipient;
        emit FeeRecipientChanged(oldRecipient, _newRecipient);
    }

    /**
     * @dev Updates the base URI for Prognosticator NFT metadata.
     * @param _newBaseURI The new base URI for metadata.
     */
    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        _baseURI = _newBaseURI;
        emit BaseURIUpdated(_newBaseURI);
    }

    /**
     * @dev Pauses critical contract operations in emergencies.
     */
    function pauseContract() external onlyOwner whenNotPaused {
        paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Resumes contract operations from a paused state.
     */
    function unpauseContract() external onlyOwner whenPaused {
        paused = false;
        emit Unpaused(msg.sender);
    }

    /**
     * @dev Allows owner to withdraw stuck ERC20 tokens.
     * @param _tokenAddress The address of the ERC20 token to withdraw.
     */
    function emergencyWithdraw(address _tokenAddress) external onlyOwner {
        IERC20 token = IERC20(_tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        if (balance == 0) return;
        if (!token.transfer(owner, balance)) revert TransferFailed();
    }

    // --- II. Prognosticator NFTs (pNFTs) - ERC721 Core & Dynamics ---

    // ERC721 Metadata
    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the count of tokens owned by an account.
     * @param _owner The address to query the balance of.
     * @return The number of tokens owned by the given address.
     */
    function balanceOf(address _owner) public view returns (uint256) {
        return _balances[_owner];
    }

    /**
     * @dev Returns the owner of the `tokenId` token.
     * @param _tokenId The ID of the token to query.
     * @return The address of the token owner.
     */
    function ownerOf(uint256 _tokenId) public view returns (address) {
        address ownerAddress = _owners[_tokenId];
        if (ownerAddress == address(0)) revert InvalidPNFTId(); // Token does not exist
        return ownerAddress;
    }

    /**
     * @dev Approves `to` to operate on `tokenId`
     * @param _to The address to approve.
     * @param _tokenId The ID of the token to approve.
     */
    function approve(address _to, uint256 _tokenId) public {
        address ownerAddress = ownerOf(_tokenId); // Also checks if tokenId exists
        if (msg.sender != ownerAddress && !isApprovedForAll(ownerAddress, msg.sender)) {
            revert NotPNFTOwner();
        }
        if (_to == ownerAddress) revert CannotSelfApprove();

        _tokenApprovals[_tokenId] = _to;
        emit Approval(ownerAddress, _to, _tokenId);
    }

    /**
     * @dev Get the approved address for a single token ID.
     * @param _tokenId The ID of the token to query.
     * @return The approved address for the token.
     */
    function getApproved(uint256 _tokenId) public view returns (address) {
        ownerOf(_tokenId); // Check if tokenId exists
        return _tokenApprovals[_tokenId];
    }

    /**
     * @dev Sets or unsets the approval for an operator to manage all tokens of `msg.sender`.
     * @param _operator The address of the operator.
     * @param _approved True to approve, false to unapprove.
     */
    function setApprovalForAll(address _operator, bool _approved) public {
        if (_operator == msg.sender) revert CannotSelfApprove();
        _operatorApprovals[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    /**
     * @dev Checks if an operator is approved by a given owner.
     * @param _owner The address of the token owner.
     * @param _operator The address of the operator.
     * @return True if the operator is approved, false otherwise.
     */
    function isApprovedForAll(address _owner, address _operator) public view returns (bool) {
        return _operatorApprovals[_owner][_operator];
    }

    /**
     * @dev Transfers a token from one address to another.
     * @param _from The current owner of the token.
     * @param _to The address to transfer the token to.
     * @param _tokenId The ID of the token to transfer.
     */
    function transferFrom(address _from, address _to, uint256 _tokenId) public {
        _transfer(_from, _to, _tokenId);
    }

    /**
     * @dev Safely transfers a token from one address to another.
     * @param _from The current owner of the token.
     * @param _to The address to transfer the token to.
     * @param _tokenId The ID of the token to transfer.
     */
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public {
        safeTransferFrom(_from, _to, _tokenId, "");
    }

    /**
     * @dev Safely transfers a token from one address to another, with additional data.
     * @param _from The current owner of the token.
     * @param _to The address to transfer the token to.
     * @param _tokenId The ID of the token to transfer.
     * @param _data Additional data to send to the recipient.
     */
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata _data) public {
        _transfer(_from, _to, _tokenId);
        if (_to.code.length > 0 && IERC721Receiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data) != IERC721Receiver.onERC721Received.selector) {
            revert InvalidRecipient();
        }
    }

    /**
     * @dev Internal function to mint a new token.
     * @param _to The address of the new token owner.
     * @param _tokenId The ID of the token to mint.
     */
    function _mint(address _to, uint256 _tokenId) internal {
        if (_to == address(0)) revert InvalidRecipient();
        if (_owners[_tokenId] != address(0)) revert InvalidPNFTId(); // Token already exists

        _owners[_tokenId] = _to;
        _balances[_to]++;
        ownerPNFTs[_to].push(_tokenId); // Add to owner's list
        emit Transfer(address(0), _to, _tokenId);
    }

    /**
     * @dev Internal function to transfer token ownership.
     * @param _from The current owner of the token.
     * @param _to The address to transfer the token to.
     * @param _tokenId The ID of the token to transfer.
     */
    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        address currentOwner = ownerOf(_tokenId); // Also checks if tokenId exists
        if (currentOwner != _from) revert NotPNFTOwner();
        if (_to == address(0)) revert CannotTransferToZeroAddress();

        if (currentOwner != msg.sender && !getApproved(_tokenId).equals(msg.sender) && !isApprovedForAll(currentOwner, msg.sender)) {
            revert NotApprovedOrOwner();
        }

        // Clear approval for the transferred token
        _tokenApprovals[_tokenId] = address(0);

        _balances[_from]--;
        _owners[_tokenId] = _to;
        _balances[_to]++;

        // Update ownerPNFTs list (simple approach, more complex for large lists if needed to remove precisely)
        _removePNFTFromOwnerList(_from, _tokenId);
        ownerPNFTs[_to].push(_tokenId);

        emit Transfer(_from, _to, _tokenId);
    }

    /**
     * @dev Internal helper to remove a token from a user's `ownerPNFTs` array.
     *      Note: This is an O(N) operation. For very large collections, consider a different data structure
     *      or manage ownerPNFTs array off-chain.
     */
    function _removePNFTFromOwnerList(address _owner, uint256 _tokenId) internal {
        uint256 length = ownerPNFTs[_owner].length;
        for (uint256 i = 0; i < length; i++) {
            if (ownerPNFTs[_owner][i] == _tokenId) {
                ownerPNFTs[_owner][i] = ownerPNFTs[_owner][length - 1]; // Replace with last element
                ownerPNFTs[_owner].pop(); // Remove last element
                break;
            }
        }
    }


    /**
     * @dev Mints a new Prognosticator NFT (pNFT) to the caller.
     *      Requires the caller to be an authorized pNFT minter.
     * @param _initialAccuracy The initial accuracy score for the new pNFT.
     */
    function mintPrognosticatorNFT(uint256 _initialAccuracy) external whenNotPaused onlyPNFTMinter {
        uint256 tokenId = _nextTokenId++;
        _mint(msg.sender, tokenId);

        pNFTs[tokenId] = PrognosticatorNFT({
            owner: msg.sender,
            accuracyScore: _initialAccuracy,
            contributionScore: 0,
            totalPredictions: 0,
            successfulPredictions: 0,
            lastActivityTimestamp: block.timestamp
        });
        emit PNFTMinted(tokenId, msg.sender, _initialAccuracy);
    }

    /**
     * @dev Allows pNFT owners to enhance specific dynamic traits of their NFT.
     *      This could involve spending tokens, or simply reflecting achievements.
     * @param _tokenId The ID of the pNFT to upgrade.
     * @param _traitIndex An index representing the specific trait to upgrade (e.g., 0 for visual, 1 for underlying influence).
     */
    function upgradePrognosticatorNFT(uint256 _tokenId, uint256 _traitIndex) external whenNotPaused {
        if (pNFTs[_tokenId].owner != msg.sender) revert NotPNFTOwner();
        if (_traitIndex > 10) revert("Invalid trait index"); // Example validation

        // This function would implement logic to spend tokens or check for achievements
        // For demonstration, let's say it increases contributionScore for trait 0
        if (_traitIndex == 0) {
            pNFTs[_tokenId].contributionScore += 10; // Example
            emit PNFTContributionUpdated(_tokenId, pNFTs[_tokenId].contributionScore);
        }
        emit PNFTUpgraded(_tokenId, _traitIndex);
    }

    /**
     * @dev Enables a pNFT owner to permanently destroy their NFT.
     * @param _tokenId The ID of the pNFT to burn.
     */
    function burnPrognosticatorNFT(uint256 _tokenId) external whenNotPaused {
        address tokenOwner = ownerOf(_tokenId); // Check existence & get owner
        if (tokenOwner != msg.sender) revert NotPNFTOwner();

        // Clear mappings
        delete _tokenApprovals[_tokenId];
        delete _owners[_tokenId];
        _balances[tokenOwner]--;
        delete pNFTs[_tokenId];

        // Remove from owner's list
        _removePNFTFromOwnerList(tokenOwner, _tokenId);

        emit PNFTBurned(_tokenId, tokenOwner);
        emit Transfer(tokenOwner, address(0), _tokenId);
    }

    // --- III. Prediction Market Lifecycle ---

    /**
     * @dev Creates a new verifiable prediction market.
     *      Requires payment of a market creation fee.
     * @param _question The question for the prediction market.
     * @param _outcomes An array of possible outcomes.
     * @param _resolverOracle The authorized oracle address responsible for resolving this market.
     * @param _resolutionTimestamp The timestamp at which the market can be resolved.
     * @param _minStakeAmount The minimum amount of tokens required to submit a prediction.
     */
    function createPredictionMarket(
        string calldata _question,
        string[] calldata _outcomes,
        address _resolverOracle,
        uint256 _resolutionTimestamp,
        uint256 _minStakeAmount
    ) external payable whenNotPaused {
        if (msg.value < MARKET_CREATION_FEE) revert InsufficientStake();
        if (_outcomes.length < 2) revert("At least two outcomes required");
        if (_resolutionTimestamp <= block.timestamp) revert("Resolution time must be in the future");
        if (!authorizedMarketOracles[_resolverOracle]) revert("Resolver oracle not authorized");

        uint256 marketId = _nextMarketId++;
        predictionMarkets[marketId] = PredictionMarket({
            id: marketId,
            question: _question,
            outcomes: _outcomes,
            resolverOracle: _resolverOracle,
            resolutionTimestamp: _resolutionTimestamp,
            winningOutcomeIndex: type(uint256).max, // Indicates not resolved
            totalStaked: 0,
            status: MarketStatus.Open,
            minStakeAmount: _minStakeAmount
        });

        // Transfer fee to recipient
        (bool success, ) = feeRecipient.call{value: MARKET_CREATION_FEE}("");
        if (!success) revert TransferFailed();

        emit MarketCreated(marketId, _question, _resolutionTimestamp);
    }

    /**
     * @dev Allows users to stake tokens on a chosen outcome in a prediction market, leveraging their pNFT.
     * @param _marketId The ID of the prediction market.
     * @param _pNFTId The ID of the Prognosticator NFT used for this prediction.
     * @param _outcomeIndex The index of the chosen outcome.
     * @param _amount The amount of tokens to stake.
     */
    function submitPrediction(
        uint256 _marketId,
        uint256 _pNFTId,
        uint256 _outcomeIndex,
        uint256 _amount
    ) external whenNotPaused {
        PredictionMarket storage market = predictionMarkets[_marketId];
        if (market.status != MarketStatus.Open) revert MarketNotOpen();
        if (_amount < market.minStakeAmount) revert InsufficientStake();
        if (_outcomeIndex >= market.outcomes.length) revert InvalidOutcomeIndex();
        if (marketPNFTPredictions[_marketId][_pNFTId].stakedAmount > 0) revert PredictionAlreadyMade();

        if (pNFTs[_pNFTId].owner != msg.sender) revert NotPNFTOwner();

        // Transfer stake from user
        IERC20 token = IERC20(address(this)); // Assuming native token or a specific ERC20
        if (!token.transferFrom(msg.sender, address(this), _amount)) revert TransferFailed();

        market.totalStaked += _amount;
        market.totalStakedByOutcome[_outcomeIndex] += _amount;

        marketPNFTPredictions[_marketId][_pNFTId] = Prediction({
            pNFTId: _pNFTId,
            stakedAmount: _amount,
            chosenOutcomeIndex: _outcomeIndex,
            claimed: false
        });

        pNFTs[_pNFTId].totalPredictions++;
        pNFTs[_pNFTId].lastActivityTimestamp = block.timestamp;

        emit PredictionSubmitted(_marketId, _pNFTId, _outcomeIndex, _amount);
    }

    /**
     * @dev Called by an authorized oracle to declare the winning outcome of a market and trigger prize distribution.
     * @param _marketId The ID of the prediction market to resolve.
     * @param _winningOutcomeIndex The index of the winning outcome.
     */
    function resolvePredictionMarket(uint256 _marketId, uint256 _winningOutcomeIndex) external onlyAuthorizedOracle(_marketId) {
        PredictionMarket storage market = predictionMarkets[_marketId];
        if (market.status != MarketStatus.Open) revert MarketNotOpen();
        if (block.timestamp < market.resolutionTimestamp) revert MarketResolutionTimeNotReached();
        if (_winningOutcomeIndex >= market.outcomes.length) revert InvalidOutcomeIndex();

        market.winningOutcomeIndex = _winningOutcomeIndex;
        market.status = MarketStatus.Resolved;

        emit MarketResolved(_marketId, _winningOutcomeIndex);
    }

    /**
     * @dev Allows successful predictors to claim their share of the prize pool.
     * @param _marketId The ID of the market to claim winnings from.
     * @param _pNFTId The ID of the pNFT used for the prediction.
     */
    function claimPredictionWinnings(uint256 _marketId, uint256 _pNFTId) external whenNotPaused {
        PredictionMarket storage market = predictionMarkets[_marketId];
        Prediction storage prediction = marketPNFTPredictions[_marketId][_pNFTId];

        if (market.status != MarketStatus.Resolved) revert MarketNotResolved();
        if (prediction.stakedAmount == 0) revert("No prediction made with this pNFT");
        if (prediction.claimed) revert("Winnings already claimed");
        if (pNFTs[_pNFTId].owner != msg.sender) revert NotPNFTOwner();

        // Check if this pNFT predicted the winning outcome
        if (prediction.chosenOutcomeIndex == market.winningOutcomeIndex) {
            uint256 totalStakedOnWinning = market.totalStakedByOutcome[market.winningOutcomeIndex];
            if (totalStakedOnWinning == 0) revert("No stakes on winning outcome");

            uint256 grossWinnings = (prediction.stakedAmount * market.totalStaked) / totalStakedOnWinning; // Proportional share
            uint256 feeAmount = (grossWinnings * PROTOCOL_FEE_PERCENT) / 100;
            uint256 netWinnings = grossWinnings - feeAmount;

            IERC20 token = IERC20(address(this)); // Assuming native token or a specific ERC20
            if (!token.transfer(msg.sender, netWinnings)) revert TransferFailed();
            if (!token.transfer(feeRecipient, feeAmount)) revert TransferFailed();

            prediction.claimed = true;
            pNFTs[_pNFTId].accuracyScore += 1; // Increment accuracy for correct prediction
            pNFTs[_pNFTId].successfulPredictions++;
            emit WinningsClaimed(_marketId, _pNFTId, netWinnings);
            emit PNFTAccuracyUpdated(_pNFTId, pNFTs[_pNFTId].accuracyScore);
        } else {
            prediction.claimed = true; // Mark as claimed even if lost, to prevent re-attempts
            // No accuracy update for incorrect prediction
        }
    }

    /**
     * @dev Cancels a market, typically due to unforeseen circumstances, and refunds all stakes.
     *      Only callable by owner, or potentially by a DAO in future versions.
     * @param _marketId The ID of the market to cancel.
     */
    function cancelPredictionMarket(uint256 _marketId) external onlyOwner whenNotPaused {
        PredictionMarket storage market = predictionMarkets[_marketId];
        if (market.status != MarketStatus.Open) revert MarketNotOpen(); // Only open markets can be cancelled
        if (market.resolutionTimestamp < block.timestamp) revert("Market cannot be cancelled after resolution time");

        market.status = MarketStatus.Cancelled;

        // Note: For actual refunds, iterate through all predictions for this market and transfer back.
        // This is complex on-chain for large markets. Off-chain indexing would be needed for claiming refunds.
        // For this example, we simply mark as cancelled. A separate `claimRefund` function would be needed.
        // The funds remain in the contract for now.

        emit MarketCancelled(_marketId);
    }

    // --- IV. Collective Intelligence & Model Refinement (AI-Adjacent) ---

    /**
     * @dev Users submit a cryptographic hash of off-chain data ("signals") to contribute
     *      to the collective intelligence model. Requires a pNFT and a submission fee.
     * @param _pNFTId The ID of the pNFT submitting the signal.
     * @param _signalHash The hash of the off-chain data/signal.
     * @param _signalType Categorization of the signal.
     */
    function submitCollectiveSignal(
        uint256 _pNFTId,
        bytes32 _signalHash,
        uint256 _signalType
    ) external payable whenNotPaused {
        if (pNFTs[_pNFTId].owner != msg.sender) revert NotPNFTOwner();
        if (msg.value < SIGNAL_SUBMISSION_FEE) revert InsufficientStake();

        uint256 signalId = _nextSignalId++;
        collectiveSignals[signalId] = SignalContribution({
            id: signalId,
            pNFTId: _pNFTId,
            signalHash: _signalHash,
            signalType: _signalType,
            timestamp: block.timestamp,
            status: SignalValidationStatus.Pending,
            validationStakeAmount: 0, // Stake set by validation
            positiveValidations: 0,
            negativeValidations: 0
        });

        // Transfer fee to recipient
        (bool success, ) = feeRecipient.call{value: SIGNAL_SUBMISSION_FEE}("");
        if (!success) revert TransferFailed();

        emit SignalSubmitted(signalId, _pNFTId, _signalHash, _signalType);
    }

    /**
     * @dev A gamified process where other pNFT holders can validate or invalidate a signal.
     *      This influences the signal's trustworthiness and potentially rewards validators.
     * @param _signalId The ID of the signal to validate.
     * @param _isValid True if validating as correct, false if invalidating.
     */
    function validateCollectiveSignal(uint256 _signalId, bool _isValid) external whenNotPaused {
        SignalContribution storage signal = collectiveSignals[_signalId];
        if (signal.status != SignalValidationStatus.Pending) revert SignalAlreadyValidated();
        if (signal.pNFTId == 0) revert SignalNotFound();
        if (signal.pNFTId == msg.sender) revert("Cannot validate your own signal"); // Prevent self-validation
        if (pNFTs[_signalId].owner == address(0)) revert InvalidPNFTId(); // Signal must come from a valid pNFT

        // A small stake might be required for validation, to be part of a reward pool.
        // For simplicity, let's just count votes for now.
        if (signal.validators[msg.sender]) revert("Already validated this signal");

        signal.validators[msg.sender] = true;
        if (_isValid) {
            signal.positiveValidations++;
        } else {
            signal.negativeValidations++;
        }

        // Logic for auto-setting status based on validation threshold could go here
        // E.g., if (signal.positiveValidations >= 5) signal.status = SignalValidationStatus.Validated;
        // Or if (signal.negativeValidations >= 3) signal.status = SignalValidationStatus.Invalidated;

        pNFTs[msg.sender].contributionScore++; // Increment contribution for validation
        emit SignalValidated(_signalId, msg.sender, _isValid);
        emit PNFTContributionUpdated(msg.sender, pNFTs[msg.sender].contributionScore);
    }

    /**
     * @dev A governance-approved function to formally update the collective prediction model's parameters.
     *      This would typically be called by a DAO or a trusted entity after aggregating validated signals off-chain.
     * @param _validatedSignalIds An array of signal IDs that have been validated and incorporated.
     * @param _newModelHash A hash representing the new version of the collective prediction model.
     */
    function updateModelParameters(
        uint256[] calldata _validatedSignalIds,
        bytes32 _newModelHash
    ) external onlyOwner whenNotPaused {
        // Here, the contract assumes off-chain computation updates the model based on validated signals.
        // The contract then records the new model hash and attributes contribution.

        for (uint256 i = 0; i < _validatedSignalIds.length; i++) {
            SignalContribution storage signal = collectiveSignals[_validatedSignalIds[i]];
            if (signal.status == SignalValidationStatus.Pending) {
                // For simplicity, any signal included here becomes validated.
                // In a real system, there would be strict validation thresholds.
                signal.status = SignalValidationStatus.Validated;
                // Reward the original submitter of the signal and its validators later.
            }
        }
        // In a more complex system, this would trigger distribution of rewards for successful inclusion.
        // For now, we only update the model hash.
        // currentCollectiveModelHash = _newModelHash; // Could store this
        emit ModelParametersUpdated(_newModelHash, _validatedSignalIds);
    }

    /**
     * @dev Rewards users for submitting and/or validating signals that are deemed valuable to the collective model.
     *      This could be called periodically or after `updateModelParameters`.
     * @param _signalIds An array of signal IDs for which rewards are being claimed.
     */
    function claimContributionRewards(uint256[] calldata _signalIds) external whenNotPaused {
        uint256 totalRewardAmount = 0;
        IERC20 token = IERC20(address(this)); // Assuming rewards are paid in the staking token

        for (uint256 i = 0; i < _signalIds.length; i++) {
            SignalContribution storage signal = collectiveSignals[_signalIds[i]];
            if (signal.status == SignalValidationStatus.Validated && !signal.validators[msg.sender]) {
                 // For submitter reward:
                if (signal.pNFTId == _getPNFTIdOwnedBy(msg.sender) && msg.sender == pNFTs[signal.pNFTId].owner) {
                    // Logic to calculate submitter reward based on signal importance/impact
                    totalRewardAmount += 1 ether; // Example static reward
                    // Mark signal as rewarded for submitter to prevent double claims
                }

                // For validator reward:
                if (signal.validators[msg.sender] && msg.sender != pNFTs[signal.pNFTId].owner) {
                     // Logic to calculate validator reward
                    totalRewardAmount += 0.5 ether; // Example static reward
                    // Mark signal as rewarded for validator
                }
            }
        }

        if (totalRewardAmount == 0) revert("No unclaimed rewards for specified signals");
        if (!token.transfer(msg.sender, totalRewardAmount)) revert TransferFailed();
        emit ContributionRewardsClaimed(_getPNFTIdOwnedBy(msg.sender), totalRewardAmount); // Assuming one main pNFT
    }


    // --- V. Gamification, Leaderboards & Achievements ---

    /**
     * @dev Retrieves the current accuracy score of a specific Prognosticator NFT.
     * @param _tokenId The ID of the pNFT.
     * @return The accuracy score.
     */
    function getPNFTAccuracyScore(uint256 _tokenId) public view returns (uint256) {
        if (pNFTs[_tokenId].owner == address(0)) revert InvalidPNFTId();
        return pNFTs[_tokenId].accuracyScore;
    }

    /**
     * @dev Retrieves the total contribution score of a pNFT.
     * @param _tokenId The ID of the pNFT.
     * @return The contribution score.
     */
    function getPNFTContributionScore(uint256 _tokenId) public view returns (uint256) {
        if (pNFTs[_tokenId].owner == address(0)) revert InvalidPNFTId();
        return pNFTs[_tokenId].contributionScore;
    }

    /**
     * @dev Returns the current status of a prediction market.
     * @param _marketId The ID of the market.
     * @return The MarketStatus enum value.
     */
    function getMarketStatus(uint256 _marketId) public view returns (MarketStatus) {
        if (predictionMarkets[_marketId].id == 0) revert MarketNotFound();
        return predictionMarkets[_marketId].status;
    }

    /**
     * @dev Fetches details of a specific pNFT's prediction in a given market.
     * @param _marketId The ID of the market.
     * @param _pNFTId The ID of the pNFT.
     * @return Prediction struct details.
     */
    function getUserMarketPrediction(uint256 _marketId, uint256 _pNFTId)
        public view
        returns (uint256 stakedAmount, uint256 chosenOutcomeIndex, bool claimed)
    {
        if (predictionMarkets[_marketId].id == 0) revert MarketNotFound();
        Prediction storage prediction = marketPNFTPredictions[_marketId][_pNFTId];
        return (prediction.stakedAmount, prediction.chosenOutcomeIndex, prediction.claimed);
    }

    /**
     * @dev Generates and returns the dynamic metadata URI for a Prognosticator NFT.
     *      The metadata would be off-chain (e.g., IPFS) and generated based on pNFT attributes.
     * @param _tokenId The ID of the pNFT.
     * @return The URI pointing to the JSON metadata.
     */
    function tokenURI(uint256 _tokenId) public view returns (string memory) {
        ownerOf(_tokenId); // Check if tokenId exists
        PrognosticatorNFT storage pnft = pNFTs[_tokenId];
        // Example dynamic URI construction based on scores
        string memory base = _baseURI;
        string memory tokenStr = _toString(_tokenId);
        string memory accStr = _toString(pnft.accuracyScore);
        string memory contStr = _toString(pnft.contributionScore);

        // This is a simplified example. A real dynamic NFT would have a more robust
        // off-chain service generating the JSON based on scores, then returning its IPFS hash.
        return string(abi.encodePacked(base, tokenStr, "/metadata?accuracy=", accStr, "&contribution=", contStr));
    }

    /**
     * @dev Returns a list of the top Prognosticator NFTs based on their accuracy scores.
     *      Note: On-chain sorting is highly gas-intensive for large datasets. This function
     *      is illustrative and suitable only for very small `_limit` values or if
     *      an off-chain indexer handles leaderboard generation.
     * @param _limit The maximum number of pNFTs to return.
     * @return An array of pNFT IDs sorted by accuracy (descending).
     */
    function getTopPrognosticators(uint256 _limit) public view returns (uint256[] memory) {
        uint256[] memory topPNFTs = new uint256[](_limit);
        uint256 currentTopCount = 0;

        // This is a very inefficient way to get top N on-chain.
        // It iterates through ALL tokens. Only for illustrative purposes or very small datasets.
        // A better approach involves an off-chain indexer or a complex on-chain data structure (e.g., a skip list).
        for (uint256 i = 1; i < _nextTokenId; i++) {
            if (pNFTs[i].owner == address(0)) continue; // Skip burned tokens

            if (currentTopCount < _limit) {
                topPNFTs[currentTopCount] = i;
                currentTopCount++;
            } else {
                // Find smallest accuracy in current topPNFTs
                uint256 minAccuracy = type(uint256).max;
                uint256 minIndex = 0;
                for (uint256 j = 0; j < _limit; j++) {
                    if (pNFTs[topPNFTs[j]].accuracyScore < minAccuracy) {
                        minAccuracy = pNFTs[topPNFTs[j]].accuracyScore;
                        minIndex = j;
                    }
                }

                // If current token is better, replace the smallest
                if (pNFTs[i].accuracyScore > minAccuracy) {
                    topPNFTs[minIndex] = i;
                }
            }
        }

        // Sort the currentTopCount elements (Bubble Sort for simplicity, still inefficient)
        for (uint256 i = 0; i < currentTopCount; i++) {
            for (uint256 j = i + 1; j < currentTopCount; j++) {
                if (pNFTs[topPNFTs[i]].accuracyScore < pNFTs[topPNFTs[j]].accuracyScore) {
                    uint256 temp = topPNFTs[i];
                    topPNFTs[i] = topPNFTs[j];
                    topPNFTs[j] = temp;
                }
            }
        }

        // Resize array to actual count if _limit was larger than total pNFTs
        if (currentTopCount < _limit) {
            uint256[] memory actualTopPNFTs = new uint256[](currentTopCount);
            for (uint256 i = 0; i < currentTopCount; i++) {
                actualTopPNFTs[i] = topPNFTs[i];
            }
            return actualTopPNFTs;
        }
        return topPNFTs;
    }


    // --- VI. Decentralized Governance (Simulated) ---
    // These functions represent a simplified governance mechanism.
    // A full DAO implementation would involve complex voting, timelocks, etc.

    struct Proposal {
        bytes32 proposalHash; // Hash of the proposed changes
        uint256 voteCount;
        uint256 threshold; // Example: min votes needed
        mapping(address => bool) hasVoted;
        bool executed;
    }
    mapping(uint256 => Proposal) public proposals;
    uint256 private _nextProposalId;

    /**
     * @dev Allows the owner (or eventually a more decentralized mechanism) to propose a system parameter change.
     * @param _proposalHash A hash representing the details of the proposed change.
     * @param _threshold The minimum votes required for the proposal to pass.
     */
    function proposeParameterChange(bytes32 _proposalHash, uint256 _threshold) external onlyOwner whenNotPaused {
        uint256 proposalId = _nextProposalId++;
        proposals[proposalId] = Proposal({
            proposalHash: _proposalHash,
            voteCount: 0,
            threshold: _threshold,
            executed: false
        });
        // Emit ProposalCreated event
    }

    /**
     * @dev Allows users (or pNFTs weighted by influence) to vote on a proposal.
     *      For simplicity, `msg.sender` gets one vote. In a real DAO, pNFT influence or token stake would determine vote weight.
     * @param _proposalId The ID of the proposal to vote on.
     */
    function voteOnProposal(uint256 _proposalId) external whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.proposalHash == bytes32(0)) revert("Proposal not found");
        if (proposal.hasVoted[msg.sender]) revert("Already voted on this proposal");
        if (proposal.executed) revert("Proposal already executed");

        proposal.hasVoted[msg.sender] = true;
        proposal.voteCount++;
        // Emit VoteCast event
    }

    /**
     * @dev Executes a proposal if it has met its voting threshold.
     *      This would typically trigger specific admin functions to apply the changes.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) external onlyOwner whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.proposalHash == bytes32(0)) revert("Proposal not found");
        if (proposal.executed) revert("Proposal already executed");
        if (proposal.voteCount < proposal.threshold) revert("Proposal has not met vote threshold");

        proposal.executed = true;
        // Here, logic would be added to apply the actual changes based on _proposalHash.
        // This could involve updating fees, min stakes, adding new oracle roles, etc.
        // For demonstration, it just marks as executed.
        // Emit ProposalExecuted event
    }

    // --- VII. View & Query Functions ---

    /**
     * @dev Internal helper to find the first pNFT ID owned by an address.
     *      Only for convenience in single-pNFT-per-user scenarios.
     *      For multiple pNFTs, a user would specify which pNFT they want to use.
     */
    function _getPNFTIdOwnedBy(address _addr) internal view returns (uint256) {
        if (ownerPNFTs[_addr].length > 0) {
            return ownerPNFTs[_addr][0];
        }
        return 0;
    }

    // --- Internal Helpers ---
    function _toString(uint256 value) internal pure returns (string memory) {
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
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
```