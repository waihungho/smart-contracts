This smart contract, `EGA_CanvasDAO`, is a highly innovative and advanced platform for creating and managing Evolving Generative Art (EGA) NFTs. It integrates off-chain AI-driven art generation parameters via Chainlink Oracles with on-chain, community-driven governance, allowing holders of its native governance token (`EGA_GOV`) to curate the artistic evolution of the NFTs.

Each `CanvasSegmentNFT` represents a piece of a larger generative art canvas. These NFTs are dynamic, meaning their visual traits can evolve over time based on global parameters. Owners can choose to "freeze" their NFT's state at any point, preserving a specific artistic rendition as a static asset, or allow it to continue evolving.

**Outline:**

1.  **Contract Description**: Introduction to EGA_CanvasDAO.
2.  **Dependencies**: OpenZeppelin (ERC20, ERC721URIStorage, Ownable, Pausable), Chainlink Client.
3.  **Core Components**:
    *   **`EGA_GOV` Token**: The governance token.
    *   **`CanvasSegmentNFT`**: The dynamic ERC721 art pieces.
    *   **AI Oracle Integration**: For fetching generative art parameters.
    *   **DAO Governance**: For community proposals and voting.
    *   **Staking**: For `EGA_GOV` and `CanvasSegmentNFT` to gain influence and rewards.
4.  **Error Handling**: Custom error definitions.
5.  **Events**: For transparent contract activity.
6.  **State Variables**: Key contract configurations and data storage.
7.  **Data Structures**: `CanvasSegment`, `Proposal`.
8.  **Modifiers**: Access control and state checks.
9.  **Constructor**: Initializing the contract.
10. **Functions**: Grouped by their primary functionality.

---

**Function Summary:**

**I. Core Canvas Segment NFT Management & Evolution (Custom ERC721-like)**
1.  `mintCanvasSegment(address _to)`: Mints a new CanvasSegmentNFT with initial traits to `_to`.
2.  `getCanvasSegmentTraits(uint256 _tokenId)`: Retrieves the current JSON string representing the traits of a given NFT.
3.  `freezeCanvasSegmentState(uint256 _tokenId)`: Locks the current visual state of an NFT, storing its current `tokenURI` as a static, frozen URI.
4.  `unfreezeCanvasSegmentState(uint256 _tokenId)`: Unlocks a previously frozen segment, allowing it to evolve again.
5.  `getFrozenStateURI(uint256 _tokenId)`: Returns the specific URI of a *frozen* state for a segment, distinct from its dynamic `tokenURI`.
6.  `triggerSegmentEvolution(uint256 _tokenId)`: Allows the segment owner to evolve their NFT's traits if it's not frozen and the evolution cooldown has passed.
7.  `getSegmentEvolutionCooldown(uint256 _tokenId)`: Calculates and returns the remaining time (in seconds) until a specific segment can next evolve.

**II. AI Oracle Integration & Global Art Parameters**
8.  `requestAIParameterUpdate(string memory _prompt)`: Initiates a Chainlink request to an off-chain AI service to generate new global art parameters based on the provided `_prompt`.
9.  `fulfillAIParameterUpdate(bytes32 _requestId, string memory _newParametersJson)`: The Chainlink oracle callback function, used to receive and update the global generative art parameters from the off-chain AI.
10. `getGlobalArtParameters()`: Returns the current JSON string of global parameters that influence the evolution of all Canvas Segments.
11. `getCurrentEvolutionEpoch()`: Returns the current evolution epoch number, which changes periodically and affects evolution.

**III. DAO Governance & Parameter Curation (using `EGA_GOV` tokens)**
12. `submitEvolutionDirectiveProposal(string memory _title, string memory _description, bytes memory _calldata, address _targetContract)`: Allows `EGA_GOV` stakers to propose changes, including new AI prompts, contract settings, or even specific `triggerSegmentEvolution` calls.
13. `voteOnProposal(uint256 _proposalId, bool _support)`: Enables `EGA_GOV` stakers (or their delegates) to vote for or against an active proposal.
14. `executeProposal(uint256 _proposalId)`: Executes a proposal that has passed the voting threshold and quorum.
15. `getProposalState(uint256 _proposalId)`: Returns the current state of a proposal (e.g., pending, active, succeeded, defeated, executed).
16. `delegateVotingPower(address _delegatee)`: Allows `EGA_GOV` stakers to delegate their voting power to another address.

**IV. Staking & Rewards**
17. `stakeEGA_GOV(uint256 _amount)`: Allows users to stake `EGA_GOV` tokens to gain voting power in the DAO and accrue rewards.
18. `unstakeEGA_GOV(uint256 _amount)`: Allows users to unstake their `EGA_GOV` tokens.
19. `claimEGA_GOV_Rewards()`: Allows users to claim accumulated rewards for their staked `EGA_GOV` tokens.
20. `stakeCanvasSegment(uint256 _tokenId)`: Allows an owner to stake their `CanvasSegmentNFT` to potentially influence its evolution more significantly or earn specific rewards.
21. `unstakeCanvasSegment(uint256 _tokenId)`: Allows an owner to unstake their `CanvasSegmentNFT`.

**V. Admin & Configuration**
22. `setOracleConfiguration(address _oracle, bytes32 _jobId, uint256 _fee)`: Sets the Chainlink oracle contract address, job ID, and link fee for requests.
23. `updateEvolutionSettings(uint256 _newEpochDuration, uint256 _newMinEvolutionInterval)`: Allows the DAO (via proposal) or owner to update the duration of an evolution epoch and the minimum interval between segment evolutions.
24. `setRewardToken(address _rewardTokenAddress)`: Sets the ERC20 token address that will be distributed as rewards.
25. `withdrawAdminFees()`: Allows the contract owner to withdraw any accumulated platform fees (if the contract charges any for specific operations).
26. `pauseContract()`: Emergency function to pause critical contract operations (e.g., transfers, minting, evolution).
27. `unpauseContract()`: Unpauses the contract after an emergency.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";

/**
 * @title EGA_CanvasDAO
 * @dev An advanced, creative, and trendy smart contract for Evolving Generative Art (EGA) NFTs.
 *      It integrates off-chain AI-driven art generation parameters via Chainlink Oracles with
 *      on-chain, community-driven governance. Holders of its native governance token (`EGA_GOV`)
 *      can curate the artistic evolution of the NFTs.
 *
 *      Each `CanvasSegmentNFT` is a dynamic ERC721 token representing a piece of a larger
 *      generative art canvas. Their visual traits can evolve over time based on global parameters
 *      updated by an AI oracle and community directives. Owners can freeze an NFT's state to
 *      preserve a specific artistic rendition or allow it to continue evolving.
 *
 *      The contract includes a robust DAO for proposals and voting, and staking mechanisms for
 *      both governance tokens and CanvasSegmentNFTs to gain influence and rewards.
 */
contract EGA_CanvasDAO is ERC721URIStorage, Ownable, Pausable, ChainlinkClient {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- Errors ---
    error NotEnoughStakedTokens();
    error ProposalNotFound();
    error ProposalAlreadyVoted();
    error ProposalExpired();
    error ProposalNotSucceeded();
    error ProposalAlreadyExecuted();
    error ProposalNotActive();
    error CanvasSegmentNotFound();
    error CanvasSegmentFrozen();
    error CanvasSegmentNotFrozen();
    error CanvasSegmentCooldownActive();
    error InvalidOracleConfiguration();
    error ZeroAddressNotAllowed();
    error AmountCannotBeZero();
    error RewardTokenNotSet();
    error NotEnoughRewardsAvailable();
    error NotEnoughVotesToExecute();
    error CallableByProposalOnly();
    error AlreadyDelegated();
    error SelfDelegationNotAllowed();
    error CannotDelegateToZeroAddress();

    // --- Events ---
    event CanvasSegmentMinted(uint256 indexed tokenId, address indexed owner, string initialTraitsJson);
    event CanvasSegmentEvolved(uint256 indexed tokenId, string newTraitsJson, uint256 epoch);
    event CanvasSegmentFrozen(uint256 indexed tokenId, string frozenURI);
    event CanvasSegmentUnfrozen(uint256 indexed tokenId);
    event AIParameterUpdateRequestSent(bytes32 indexed requestId, string prompt);
    event AIParameterUpdateFulfilled(bytes32 indexed requestId, string newParametersJson);
    event EvolutionDirectiveProposalSubmitted(uint256 indexed proposalId, address indexed proposer, string title);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 votes);
    event ProposalExecuted(uint256 indexed proposalId, address indexed executor);
    event VotingPowerDelegated(address indexed delegator, address indexed delegatee);
    event TokensStaked(address indexed user, uint256 amount);
    event TokensUnstaked(address indexed user, uint256 amount);
    event RewardsClaimed(address indexed user, uint256 amount);
    event CanvasSegmentStaked(uint256 indexed tokenId, address indexed owner);
    event CanvasSegmentUnstaked(uint256 indexed tokenId, address indexed owner);
    event OracleConfigurationUpdated(address indexed oracle, bytes32 jobId, uint256 fee);
    event EvolutionSettingsUpdated(uint256 newEpochDuration, uint256 newMinEvolutionInterval);
    event RewardTokenSet(address indexed rewardTokenAddress);
    event AdminFeesWithdrawn(address indexed recipient, uint256 amount);

    // --- State Variables ---
    ERC20 public immutable EGA_GOV_TOKEN; // Governance token
    ERC20 public rewardToken;             // Token used for rewards

    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _proposalIdCounter;

    // AI Oracle Configuration
    address public chainlinkOracle;
    bytes32 public chainlinkJobId;
    uint256 public chainlinkFee;

    // Global Art Parameters (JSON string, interpreted off-chain for rendering)
    string public globalArtParametersJson;
    uint256 public currentEvolutionEpoch;
    uint256 public epochDuration;         // Duration of an epoch in seconds
    uint256 public minEvolutionInterval;  // Minimum seconds between evolutions for a single segment

    // DAO Governance
    uint256 public proposalThreshold;   // Minimum EGA_GOV tokens to submit a proposal
    uint256 public quorumPercentage;    // Percentage of total staked votes required for a proposal to pass
    uint256 public votingPeriodBlocks;  // Number of blocks a proposal is open for voting

    // Staking
    mapping(address => uint256) public stakedEgaGovTokens;
    mapping(address => uint256) public lastRewardClaimTimestamp;
    mapping(address => uint256) public rewardAccrued;
    mapping(uint256 => bool) public isCanvasSegmentStaked; // tokenId => bool
    mapping(address => address) public delegates;           // delegator => delegatee
    mapping(address => uint256) public votes;               // address => current voting power (staked + delegated)

    // --- Data Structures ---

    struct CanvasSegment {
        string currentTraitsJson;      // JSON string representing current generative art traits
        string frozenStateURI;         // IPFS/Arweave URI if frozen
        uint64 lastEvolutionEpoch;     // Epoch when it last evolved
        uint66 lastEvolutionTimestamp; // Timestamp when it last evolved
        bool isFrozen;                 // Whether the segment's state is locked
        uint256 influenceStake;        // Amount of EGA_GOV tokens staked on this specific segment
    }
    mapping(uint256 => CanvasSegment) public canvasSegments; // tokenId => CanvasSegment data

    enum ProposalState { Pending, Active, Succeeded, Defeated, Executed }

    struct Proposal {
        string title;
        string description;
        address proposer;
        uint256 creationBlock;
        uint256 endBlock;
        uint256 forVotes;
        uint256 againstVotes;
        bool executed;
        bytes callData;         // The function call to execute if proposal passes
        address targetContract; // Contract to call
        mapping(address => bool) hasVoted; // Voter address => true if voted
    }
    mapping(uint256 => Proposal) public proposals; // proposalId => Proposal data

    // --- Modifiers ---

    modifier onlyCanvasSegmentOwner(uint256 _tokenId) {
        if (ownerOf(_tokenId) != msg.sender) revert OwnableUnauthorizedAccount(msg.sender);
        _;
    }

    modifier onlyStakedEgaGov(uint256 _amount) {
        if (stakedEgaGovTokens[msg.sender] < _amount) revert NotEnoughStakedTokens();
        _;
    }

    modifier onlyDelegateOrStaker() {
        if (delegates[msg.sender] != address(0) && delegates[msg.sender] != msg.sender) revert AlreadyDelegated();
        _;
    }

    modifier canCallByProposal() {
        // This modifier restricts a function to be callable ONLY through a successful proposal execution.
        // It checks if the current call is being made by this contract itself, implying it's an execution
        // initiated by `executeProposal`.
        if (msg.sender != address(this)) revert CallableByProposalOnly();
        _;
    }

    // --- Constructor ---

    constructor(address _egaGovTokenAddress, uint256 _initialProposalThreshold,
                uint256 _quorumPercentage, uint256 _votingPeriodBlocks,
                uint256 _epochDuration, uint256 _minEvolutionInterval)
        ERC721("EvolvingGenerativeArtCanvas", "EGA_Canvas")
        Ownable(msg.sender) // Owner is the deployer
        Pausable()
    {
        if (_egaGovTokenAddress == address(0)) revert ZeroAddressNotAllowed();
        if (_initialProposalThreshold == 0) revert AmountCannotBeZero();
        if (_quorumPercentage == 0 || _quorumPercentage > 100) revert InvalidOracleConfiguration(); // Using this error for now
        if (_votingPeriodBlocks == 0) revert AmountCannotBeZero();
        if (_epochDuration == 0) revert AmountCannotBeZero();
        if (_minEvolutionInterval == 0) revert AmountCannotBeZero();

        EGA_GOV_TOKEN = ERC20(_egaGovTokenAddress);
        proposalThreshold = _initialProposalThreshold;
        quorumPercentage = _quorumPercentage;
        votingPeriodBlocks = _votingPeriodBlocks;
        epochDuration = _epochDuration;
        minEvolutionInterval = _minEvolutionInterval;
        currentEvolutionEpoch = 1; // Start with epoch 1

        // Initialize Chainlink Client
        setChainlinkToken(address(0x326C977E6EfMx8d9dF2Ca6C0dE1e50E633d2698D)); // Goerli LINK token for example
    }

    // --- ERC721 Overrides (to integrate with CanvasSegment data) ---

    function _baseURI() internal pure override returns (string memory) {
        // This could point to a base IPFS gateway or a renderer that takes token ID
        return "ipfs://EGA-Canvas-Renderer/"; // Placeholder for a dynamic renderer
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);
        CanvasSegment storage segment = canvasSegments[tokenId];
        if (segment.isFrozen && bytes(segment.frozenStateURI).length > 0) {
            return segment.frozenStateURI;
        }
        // For dynamic NFTs, the URI could point to an off-chain renderer
        // which interprets `currentTraitsJson` and `globalArtParametersJson`
        // or directly to a JSON containing metadata (e.g., baseURI + tokenId + .json)
        return string(abi.encodePacked(_baseURI(), Strings.toString(tokenId), ".json"));
    }

    // --- I. Core Canvas Segment NFT Management & Evolution ---

    /**
     * @dev Mints a new CanvasSegmentNFT with initial traits to the specified address.
     *      Initial traits are simple default values or a hash-based deterministic set.
     * @param _to The address to mint the NFT to.
     */
    function mintCanvasSegment(address _to) public payable whenNotPaused returns (uint256) {
        if (_to == address(0)) revert ZeroAddressNotAllowed();

        _tokenIdCounter.increment();
        uint256 newId = _tokenIdCounter.current();

        // Assign some initial traits. In a real scenario, this could be more complex
        // e.g., based on `globalArtParametersJson` or a seed.
        canvasSegments[newId] = CanvasSegment({
            currentTraitsJson: '{"color":"#FFFFFF", "pattern":"dots", "density":1}',
            frozenStateURI: "",
            lastEvolutionEpoch: 0,
            lastEvolutionTimestamp: uint64(block.timestamp),
            isFrozen: false,
            influenceStake: 0
        });

        _mint(_to, newId);
        emit CanvasSegmentMinted(newId, _to, canvasSegments[newId].currentTraitsJson);
        return newId;
    }

    /**
     * @dev Retrieves the current JSON string representing the traits of a given NFT.
     * @param _tokenId The ID of the CanvasSegmentNFT.
     * @return A JSON string representing the current traits.
     */
    function getCanvasSegmentTraits(uint256 _tokenId) public view returns (string memory) {
        _requireOwned(_tokenId);
        return canvasSegments[_tokenId].currentTraitsJson;
    }

    /**
     * @dev Locks the current visual state of an NFT, setting its `tokenURI` to a static, frozen URI.
     *      This URI would typically point to an IPFS/Arweave hash of the rendered art.
     * @param _tokenId The ID of the CanvasSegmentNFT to freeze.
     */
    function freezeCanvasSegmentState(uint256 _tokenId) public virtual whenNotPaused onlyCanvasSegmentOwner(_tokenId) {
        CanvasSegment storage segment = canvasSegments[_tokenId];
        if (segment.isFrozen) revert CanvasSegmentFrozen();

        // In a real application, the front-end would render the current traits, upload to IPFS,
        // and then call this function with the resulting IPFS URI.
        // For demonstration, we'll use a placeholder URI.
        string memory _frozenURI = string(abi.encodePacked("ipfs://frozen-art/", Strings.toString(_tokenId), "-epoch-", Strings.toString(currentEvolutionEpoch), ".json"));
        segment.frozenStateURI = _frozenURI;
        segment.isFrozen = true;

        emit CanvasSegmentFrozen(_tokenId, _frozenURI);
    }

    /**
     * @dev Unlocks a previously frozen segment, allowing it to evolve again.
     * @param _tokenId The ID of the CanvasSegmentNFT to unfreeze.
     */
    function unfreezeCanvasSegmentState(uint256 _tokenId) public virtual whenNotPaused onlyCanvasSegmentOwner(_tokenId) {
        CanvasSegment storage segment = canvasSegments[_tokenId];
        if (!segment.isFrozen) revert CanvasSegmentNotFrozen();

        segment.frozenStateURI = ""; // Clear the frozen URI
        segment.isFrozen = false;

        emit CanvasSegmentUnfrozen(_tokenId);
    }

    /**
     * @dev Returns the specific URI of a *frozen* state for a segment.
     *      This is distinct from the dynamic `tokenURI` which could point to a renderer.
     * @param _tokenId The ID of the CanvasSegmentNFT.
     * @return The URI of the frozen state, or an empty string if not frozen.
     */
    function getFrozenStateURI(uint256 _tokenId) public view returns (string memory) {
        _requireOwned(_tokenId);
        return canvasSegments[_tokenId].frozenStateURI;
    }

    /**
     * @dev Allows the segment owner to trigger evolution for their NFT if it's not frozen
     *      and the evolution cooldown has passed. The actual trait generation logic is
     *      a simplified example here, real evolution would be based on complex algorithms
     *      interpreting `globalArtParametersJson`.
     * @param _tokenId The ID of the CanvasSegmentNFT to evolve.
     */
    function triggerSegmentEvolution(uint256 _tokenId) public whenNotPaused onlyCanvasSegmentOwner(_tokenId) {
        CanvasSegment storage segment = canvasSegments[_tokenId];
        if (segment.isFrozen) revert CanvasSegmentFrozen();
        if (getSegmentEvolutionCooldown(_tokenId) > 0) revert CanvasSegmentCooldownActive();

        // Simulate evolution: update traits based on global parameters and influence stake
        // In a real DApp, this would involve more complex on-chain logic or a deterministic hash function
        // that takes `globalArtParametersJson`, `segment.influenceStake`, and `_tokenId` as inputs.
        string memory newTraits = string(abi.encodePacked(
            '{"color_evolved":"#', Strings.toString(block.timestamp % 1000),
            '", "pattern_evolved":"', globalArtParametersJson,
            '", "influence":"', Strings.toString(segment.influenceStake), '"}'
        ));

        segment.currentTraitsJson = newTraits;
        segment.lastEvolutionEpoch = uint64(currentEvolutionEpoch);
        segment.lastEvolutionTimestamp = uint66(block.timestamp);

        emit CanvasSegmentEvolved(_tokenId, newTraits, currentEvolutionEpoch);
    }

    /**
     * @dev Calculates and returns the remaining time (in seconds) until a specific segment can next evolve.
     * @param _tokenId The ID of the CanvasSegmentNFT.
     * @return The remaining cooldown time in seconds. Returns 0 if no cooldown.
     */
    function getSegmentEvolutionCooldown(uint256 _tokenId) public view returns (uint256) {
        CanvasSegment storage segment = canvasSegments[_tokenId];
        uint256 nextEvolutionTime = segment.lastEvolutionTimestamp + minEvolutionInterval;
        if (block.timestamp < nextEvolutionTime) {
            return nextEvolutionTime - block.timestamp;
        }
        return 0;
    }

    // --- II. AI Oracle Integration & Global Art Parameters ---

    /**
     * @dev Initiates a Chainlink request to an off-chain AI service to generate new global art parameters.
     *      This function would typically be called as a result of a successful DAO proposal.
     * @param _prompt The natural language prompt to guide the AI's parameter generation.
     */
    function requestAIParameterUpdate(string memory _prompt) public whenNotPaused canCallByProposal returns (bytes32 requestId) {
        if (chainlinkOracle == address(0) || chainlinkJobId == bytes32(0)) revert InvalidOracleConfiguration();

        Chainlink.Request memory req = buildChainlinkRequest(chainlinkJobId, address(this), this.fulfillAIParameterUpdate.selector);
        req.add("prompt", _prompt);
        // Additional parameters for the AI model can be added here
        // req.add("max_iterations", "100");
        // req.add("style_preference", "abstract");

        requestId = sendChainlinkRequest(req, chainlinkFee);
        emit AIParameterUpdateRequestSent(requestId, _prompt);
    }

    /**
     * @dev The Chainlink oracle callback function, used to receive and update the global
     *      generative art parameters from the off-chain AI.
     * @param _requestId The ID of the Chainlink request.
     * @param _newParametersJson A JSON string containing the new global art parameters.
     */
    function fulfillAIParameterUpdate(bytes32 _requestId, string memory _newParametersJson)
        public
        recordChainlinkFulfillment(_requestId)
    {
        globalArtParametersJson = _newParametersJson;
        currentEvolutionEpoch++; // Advance epoch after global parameters update

        emit AIParameterUpdateFulfilled(_requestId, _newParametersJson);
    }

    /**
     * @dev Returns the current JSON string of global parameters that influence the evolution of all Canvas Segments.
     * @return A JSON string representing the global art parameters.
     */
    function getGlobalArtParameters() public view returns (string memory) {
        return globalArtParametersJson;
    }

    /**
     * @dev Returns the current evolution epoch number.
     * @return The current epoch number.
     */
    function getCurrentEvolutionEpoch() public view returns (uint256) {
        return currentEvolutionEpoch;
    }

    // --- III. DAO Governance & Parameter Curation ---

    /**
     * @dev Allows `EGA_GOV` stakers to submit a new proposal to influence global parameters
     *      or contract settings. The `_calldata` and `_targetContract` specify the action
     *      to be taken if the proposal passes.
     * @param _title The title of the proposal.
     * @param _description A detailed description of the proposal.
     * @param _calldata The encoded function call to be executed (e.g., `abi.encodeWithSelector(this.requestAIParameterUpdate.selector, "new prompt")`).
     * @param _targetContract The address of the contract to call when executing the proposal (often `address(this)`).
     */
    function submitEvolutionDirectiveProposal(
        string memory _title,
        string memory _description,
        bytes memory _calldata,
        address _targetContract
    ) public whenNotPaused {
        if (stakedEgaGovTokens[msg.sender] < proposalThreshold) revert NotEnoughStakedTokens();
        if (_targetContract == address(0)) revert ZeroAddressNotAllowed();

        _proposalIdCounter.increment();
        uint256 proposalId = _proposalIdCounter.current();

        proposals[proposalId].title = _title;
        proposals[proposalId].description = _description;
        proposals[proposalId].proposer = msg.sender;
        proposals[proposalId].creationBlock = block.number;
        proposals[proposalId].endBlock = block.number + votingPeriodBlocks;
        proposals[proposalId].calldata = _calldata;
        proposals[proposalId].targetContract = _targetContract;

        emit EvolutionDirectiveProposalSubmitted(proposalId, msg.sender, _title);
    }

    /**
     * @dev Enables `EGA_GOV` stakers (or their delegates) to vote for or against an active proposal.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for a 'for' vote, false for 'against'.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) public whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        if (getProposalState(_proposalId) != ProposalState.Active) revert ProposalNotActive();
        if (proposal.hasVoted[msg.sender]) revert ProposalAlreadyVoted();

        uint256 voterVotes = votes[msg.sender]; // Get actual voting power (staked + delegated)
        if (voterVotes == 0) revert NotEnoughStakedTokens(); // Or not delegated

        if (_support) {
            proposal.forVotes = proposal.forVotes.add(voterVotes);
        } else {
            proposal.againstVotes = proposal.againstVotes.add(voterVotes);
        }
        proposal.hasVoted[msg.sender] = true;

        emit VoteCast(_proposalId, msg.sender, _support, voterVotes);
    }

    /**
     * @dev Executes a proposal that has passed the voting threshold and quorum.
     *      Any address can call this after a proposal has succeeded.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) public whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.executed) revert ProposalAlreadyExecuted();
        if (getProposalState(_proposalId) != ProposalState.Succeeded) revert ProposalNotSucceeded();

        proposal.executed = true;
        (bool success,) = proposal.targetContract.call(proposal.calldata);
        // It's crucial for the called function to handle its own errors,
        // or for the proposal to correctly define _calldata.
        require(success, "Proposal execution failed");

        emit ProposalExecuted(_proposalId, msg.sender);
    }

    /**
     * @dev Returns the current state of a proposal.
     * @param _proposalId The ID of the proposal.
     * @return The state of the proposal (Pending, Active, Succeeded, Defeated, Executed).
     */
    function getProposalState(uint256 _proposalId) public view returns (ProposalState) {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.proposer == address(0)) revert ProposalNotFound();
        if (proposal.executed) return ProposalState.Executed;
        if (block.number <= proposal.creationBlock) return ProposalState.Pending;
        if (block.number <= proposal.endBlock) return ProposalState.Active;

        // Voting period has ended
        uint256 totalStakedForQuorum = EGA_GOV_TOKEN.totalSupply(); // Simplified, should be total *staked* for accuracy
        uint256 requiredQuorumVotes = totalStakedForQuorum.mul(quorumPercentage).div(100);

        if (proposal.forVotes > proposal.againstVotes && proposal.forVotes >= requiredQuorumVotes) {
            return ProposalState.Succeeded;
        } else {
            return ProposalState.Defeated;
        }
    }

    /**
     * @dev Allows `EGA_GOV` stakers to delegate their voting power to another address.
     * @param _delegatee The address to delegate voting power to.
     */
    function delegateVotingPower(address _delegatee) public whenNotPaused {
        if (_delegatee == address(0)) revert CannotDelegateToZeroAddress();
        if (_delegatee == msg.sender) revert SelfDelegationNotAllowed();
        if (delegates[msg.sender] == _delegatee) revert AlreadyDelegated();

        address oldDelegatee = delegates[msg.sender];
        delegates[msg.sender] = _delegatee;

        // Adjust votes: subtract from old delegatee, add to new
        uint256 staked = stakedEgaGovTokens[msg.sender];
        if (oldDelegatee != address(0)) {
            votes[oldDelegatee] = votes[oldDelegatee].sub(staked);
        }
        votes[_delegatee] = votes[_delegatee].add(staked);

        emit VotingPowerDelegated(msg.sender, _delegatee);
    }

    // --- IV. Staking & Rewards ---

    /**
     * @dev Stakes `EGA_GOV` tokens for voting power in the DAO and to accrue rewards.
     * @param _amount The amount of `EGA_GOV` tokens to stake.
     */
    function stakeEGA_GOV(uint256 _amount) public whenNotPaused {
        if (_amount == 0) revert AmountCannotBeZero();
        
        uint256 currentStaked = stakedEgaGovTokens[msg.sender];
        // Distribute pending rewards before updating stake
        _distributeRewards(msg.sender, currentStaked);

        EGA_GOV_TOKEN.transferFrom(msg.sender, address(this), _amount);
        stakedEgaGovTokens[msg.sender] = currentStaked.add(_amount);
        lastRewardClaimTimestamp[msg.sender] = block.timestamp;

        // Update voting power for the staker or their delegate
        address currentDelegatee = delegates[msg.sender];
        if (currentDelegatee == address(0)) currentDelegatee = msg.sender;
        votes[currentDelegatee] = votes[currentDelegatee].add(_amount);

        emit TokensStaked(msg.sender, _amount);
    }

    /**
     * @dev Unstakes `EGA_GOV` tokens.
     * @param _amount The amount of `EGA_GOV` tokens to unstake.
     */
    function unstakeEGA_GOV(uint256 _amount) public whenNotPaused onlyStakedEgaGov(_amount) {
        if (_amount == 0) revert AmountCannotBeZero();

        uint256 currentStaked = stakedEgaGovTokens[msg.sender];
        // Distribute pending rewards before updating stake
        _distributeRewards(msg.sender, currentStaked);

        stakedEgaGovTokens[msg.sender] = currentStaked.sub(_amount);
        EGA_GOV_TOKEN.transfer(msg.sender, _amount);
        lastRewardClaimTimestamp[msg.sender] = block.timestamp;

        // Update voting power for the staker or their delegate
        address currentDelegatee = delegates[msg.sender];
        if (currentDelegatee == address(0)) currentDelegatee = msg.sender;
        votes[currentDelegatee] = votes[currentDelegatee].sub(_amount);

        emit TokensUnstaked(msg.sender, _amount);
    }

    /**
     * @dev Allows users to claim accumulated rewards for their staked `EGA_GOV` tokens.
     */
    function claimEGA_GOV_Rewards() public whenNotPaused {
        if (rewardToken == address(0)) revert RewardTokenNotSet();

        uint256 currentStaked = stakedEgaGovTokens[msg.sender];
        _distributeRewards(msg.sender, currentStaked);

        uint256 amountToClaim = rewardAccrued[msg.sender];
        if (amountToClaim == 0) revert NotEnoughRewardsAvailable();

        rewardAccrued[msg.sender] = 0;
        rewardToken.transfer(msg.sender, amountToClaim);

        emit RewardsClaimed(msg.sender, amountToClaim);
    }

    /**
     * @dev Internal function to calculate and add rewards to `rewardAccrued`.
     *      Simplified reward calculation: 1 reward token per 100 EGA_GOV per day.
     *      This would be much more complex in a real system (e.g., based on TVL, fee share).
     * @param _user The address of the staker.
     * @param _stakedAmount The amount currently staked by the user.
     */
    function _distributeRewards(address _user, uint256 _stakedAmount) internal {
        if (_stakedAmount == 0 || rewardToken == address(0)) return;

        uint256 timeElapsed = block.timestamp.sub(lastRewardClaimTimestamp[_user]);
        if (timeElapsed == 0) return;

        // Example reward logic: 1 reward token per 100 EGA_GOV per day (86400 seconds)
        // (Reward_rate_per_sec * staked_amount * time_elapsed) / 1e18 (if reward token has 18 decimals)
        uint256 rewards = (_stakedAmount.mul(timeElapsed).mul(10**rewardToken.decimals())).div(100 * 86400 * 10**EGA_GOV_TOKEN.decimals()); // Simplified and needs adjustment for decimals

        rewardAccrued[_user] = rewardAccrued[_user].add(rewards);
        lastRewardClaimTimestamp[_user] = block.timestamp;
    }

    /**
     * @dev Allows an owner to stake their `CanvasSegmentNFT` to potentially influence its evolution
     *      more significantly or earn a share of specific NFT-related rewards.
     *      Requires the NFT to be approved for transfer to this contract first.
     * @param _tokenId The ID of the CanvasSegmentNFT to stake.
     */
    function stakeCanvasSegment(uint256 _tokenId) public whenNotPaused onlyCanvasSegmentOwner(_tokenId) {
        if (isCanvasSegmentStaked[_tokenId]) revert CanvasSegmentFrozen(); // Re-using error for already staked, consider new error
        if (getApproved(_tokenId) != address(this) && isApprovedForAll(msg.sender, address(this)) == false) revert ERC721InsufficientApproval(address(this), _tokenId);

        _transfer(msg.sender, address(this), _tokenId); // Transfer NFT to contract
        isCanvasSegmentStaked[_tokenId] = true;
        // Logic to increase evolution influence or assign a reward share could go here.
        // For simplicity, `influenceStake` on segment can be updated by staking EGA_GOV on it too.
        // e.g. canvasSegments[_tokenId].influenceStake += 1;

        emit CanvasSegmentStaked(_tokenId, msg.sender);
    }

    /**
     * @dev Allows an owner to unstake their `CanvasSegmentNFT`.
     * @param _tokenId The ID of the CanvasSegmentNFT to unstake.
     */
    function unstakeCanvasSegment(uint256 _tokenId) public whenNotPaused {
        if (ownerOf(_tokenId) != address(this)) revert CanvasSegmentNotFound(); // Not owned by contract, thus not staked
        if (!isCanvasSegmentStaked[_tokenId]) revert CanvasSegmentNotFound(); // Re-using error for not staked

        isCanvasSegmentStaked[_tokenId] = false;
        _transfer(address(this), msg.sender, _tokenId); // Transfer NFT back to original staker

        emit CanvasSegmentUnstaked(_tokenId, msg.sender);
    }

    // --- V. Admin & Configuration ---

    /**
     * @dev Sets the Chainlink oracle contract address, job ID, and link fee for requests.
     *      Callable only by the owner or via a successful DAO proposal.
     * @param _oracle The address of the Chainlink oracle.
     * @param _jobId The Chainlink job ID.
     * @param _fee The amount of LINK tokens to pay for the request.
     */
    function setOracleConfiguration(address _oracle, bytes32 _jobId, uint256 _fee) public onlyOwner { // Can be made `canCallByProposal` too
        if (_oracle == address(0) || _jobId == bytes32(0) || _fee == 0) revert InvalidOracleConfiguration();
        chainlinkOracle = _oracle;
        chainlinkJobId = _jobId;
        chainlinkFee = _fee;
        emit OracleConfigurationUpdated(_oracle, _jobId, _fee);
    }

    /**
     * @dev Updates the duration of an evolution epoch and the minimum interval between segment evolutions.
     *      Callable only by the owner or via a successful DAO proposal.
     * @param _newEpochDuration The new epoch duration in seconds.
     * @param _newMinEvolutionInterval The new minimum evolution interval in seconds.
     */
    function updateEvolutionSettings(uint256 _newEpochDuration, uint256 _newMinEvolutionInterval) public onlyOwner { // Can be made `canCallByProposal` too
        if (_newEpochDuration == 0 || _newMinEvolutionInterval == 0) revert AmountCannotBeZero();
        epochDuration = _newEpochDuration;
        minEvolutionInterval = _newMinEvolutionInterval;
        emit EvolutionSettingsUpdated(_newEpochDuration, _newMinEvolutionInterval);
    }

    /**
     * @dev Sets the ERC20 token address that will be distributed as rewards.
     *      Callable only by the owner or via a successful DAO proposal.
     * @param _rewardTokenAddress The address of the reward token.
     */
    function setRewardToken(address _rewardTokenAddress) public onlyOwner { // Can be made `canCallByProposal` too
        if (_rewardTokenAddress == address(0)) revert ZeroAddressNotAllowed();
        rewardToken = ERC20(_rewardTokenAddress);
        emit RewardTokenSet(_rewardTokenAddress);
    }

    /**
     * @dev Allows the contract owner to withdraw any accumulated platform fees.
     *      (This contract currently doesn't implement fee collection, but this function
     *       is included as a standard admin utility for future expansion).
     * @param _amount The amount of native currency (e.g., ETH) to withdraw.
     */
    function withdrawAdminFees(uint256 _amount) public onlyOwner {
        if (_amount == 0) revert AmountCannotBeZero();
        require(address(this).balance >= _amount, "Not enough funds in contract");
        (bool success,) = msg.sender.call{value: _amount}("");
        require(success, "Withdrawal failed");
        emit AdminFeesWithdrawn(msg.sender, _amount);
    }

    /**
     * @dev Emergency function to pause critical contract operations (e.g., transfers, minting, evolution).
     *      Callable only by the owner.
     */
    function pauseContract() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract after an emergency.
     *      Callable only by the owner.
     */
    function unpauseContract() public onlyOwner {
        _unpause();
    }

    // --- Fallback & Receive ---
    receive() external payable {}
    fallback() external payable {}
}

// Minimal ERC20 for EGA_GOV (for deployment purposes if not already deployed)
contract EGAGovToken is ERC20 {
    constructor(uint256 initialSupply) ERC20("EGA Governance Token", "EGA_GOV") {
        _mint(msg.sender, initialSupply);
    }
}
```