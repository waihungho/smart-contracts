Okay, let's design a smart contract that combines concepts from generative art, dynamic NFTs, on-chain parameters, and community influence (via a simple staking/voting mechanism).

We'll call it `GenerativeAssetStudio`. The idea is that the contract manages a set of on-chain parameters that influence the "generation" or "evolution" of unique digital assets (represented as NFTs). Users can mint assets based on the *current* parameters, and potentially stake their NFTs or tokens to propose and vote on changes to these parameters, affecting future generations or even the state of existing assets.

**Advanced Concepts Used:**

1.  **On-Chain Parameter Management:** Storing and managing a structured set of parameters directly in contract storage.
2.  **Parametric Generation/Evolution:** The *potential* visual/metadata representation of the NFT is derived from on-chain parameters stored within the contract or specifically for that token. (While rendering is off-chain, the *inputs* are on-chain).
3.  **Dynamic NFT State:** NFTs can "evolve" or change state based on parameters, time, or owner actions.
4.  **Staking for Utility:** Staking NFTs (or a hypothetical native token) grants voting power or access to features.
5.  **Simple On-Chain Governance/Influence:** A mechanism for staked users to propose and vote on changes to the global parameters.
6.  **Feature Locking:** Owners can lock specific aspects of their dynamic NFT's state to prevent further changes.
7.  **Access Control:** Utilizing roles for managing administrative and governance functions.

**Disclaimer:** This contract is a complex example demonstrating concepts. A production system would require more robust randomness (e.g., Chainlink VRF), a more sophisticated governance model, gas optimizations, and thorough security audits. The generative/evolution logic here is simplified placeholders (e.g., based on block data and parameters). The actual art/metadata rendering based on these parameters would happen off-chain, but the contract provides the canonical, verifiable parameters.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Base64.sol"; // Optional: For generating simple on-chain SVG/JSON in tokenURI

/**
 * @title GenerativeAssetStudio
 * @notice A contract for minting and managing dynamic generative NFTs influenced by on-chain parameters and community governance.
 *
 * Outline:
 * 1.  Inherits ERC721, AccessControl, ReentrancyGuard.
 * 2.  Defines roles for access control (DEFAULT_ADMIN_ROLE, GOVERNOR_ROLE).
 * 3.  Manages global generative parameters.
 * 4.  Stores specific parameters and evolutionary state for each NFT.
 * 5.  Implements a staking mechanism for NFTs.
 * 6.  Provides a simple proposal/voting system for governors/stakers to influence global parameters.
 * 7.  Allows NFT owners to trigger evolution or lock features of their assets.
 * 8.  Handles minting process with price and availability checks.
 * 9.  Overrides tokenURI to reflect dynamic state (potentially via off-chain service using on-chain data).
 *
 * Function Summary:
 *
 * ERC721 & Basic:
 * - constructor: Initializes contract, roles, and initial parameters.
 * - tokenURI: Overrides ERC721 standard to provide dynamic metadata URI.
 * - supportsInterface: ERC165 standard.
 * - totalSupply: Returns total number of minted tokens.
 * - ... (standard ERC721 functions like ownerOf, balanceOf, getApproved, isApprovedForAll, transferFrom, safeTransferFrom, approve, setApprovalForAll are inherited)
 *
 * Access Control (via AccessControl.sol):
 * - grantRole: Grants a role to an account (DEFAULT_ADMIN_ROLE only).
 * - revokeRole: Revokes a role from an account (DEFAULT_ADMIN_ROLE only).
 * - renounceRole: Renounces a role (callable by role holder).
 * - hasRole: Checks if an account has a role.
 *
 * Minting:
 * - mint: Mints a new NFT using current global parameters, payable.
 * - setMintPrice: Sets the price for minting (GOVERNOR_ROLE).
 * - setMintAvailability: Sets whether minting is enabled (GOVERNOR_ROLE).
 * - getMintPrice: Returns the current mint price.
 * - isMintAvailable: Returns minting availability status.
 * - setMintFeeDestination: Sets the address where minting fees are sent (DEFAULT_ADMIN_ROLE).
 * - getMintFeeDestination: Returns the fee destination address.
 * - withdrawFunds: Withdraws collected ETH fees (DEFAULT_ADMIN_ROLE).
 *
 * Global Parameters:
 * - setGlobalParameter: Sets a specific global generative parameter (GOVERNOR_ROLE).
 * - getGlobalParameter: Retrieves a specific global parameter.
 * - getAllGlobalParameters: Retrieves all global parameters.
 *
 * NFT Specific Data:
 * - getNftParameters: Retrieves the parameters recorded at the time an NFT was minted.
 * - getNftEvolutionState: Retrieves the current evolution state variables for an NFT.
 *
 * NFT Dynamics & Evolution:
 * - evolveNft: Triggers an evolution step for an NFT, potentially changing its state based on parameters (callable by owner).
 * - lockNftFeature: Locks a specific evolutionary feature of an NFT (callable by owner).
 * - isFeatureLocked: Checks if a specific feature on an NFT is locked.
 *
 * Staking:
 * - stakeNft: Stakes an NFT, associating it with the staker for utility like voting (callable by owner).
 * - unstakeNft: Unstakes an NFT (callable by owner).
 * - isNftStaked: Checks if an NFT is currently staked.
 * - getStakedNftsByOwner: Lists token IDs of NFTs staked by a specific owner.
 *
 * Governance (Parameter Proposals):
 * - proposeParameterChange: Allows a staked user to propose a change to a global parameter (requires stake).
 * - voteOnProposal: Allows a staked user to vote on an active proposal (requires stake).
 * - executeProposal: Executes a successful proposal to change a global parameter (GOVERNOR_ROLE or sufficient votes/time).
 * - getCurrentProposalState: Gets the state (active, pending, passed, failed, executed) of a proposal.
 * - getProposalDetails: Gets the details of a proposal.
 * - getRequiredStakeForProposal: Gets the minimum number of staked NFTs required to create a proposal.
 * - setRequiredStakeForProposal: Sets the minimum staked NFTs required for proposals (GOVERNOR_ROLE).
 * - getRequiredVotesForProposal: Gets the percentage of votes required for a proposal to pass.
 * - setRequiredVotesForProposal: Sets the required vote percentage (GOVERNOR_ROLE).
 * - getProposalVotingPeriod: Gets the duration of the voting period in seconds.
 * - setProposalVotingPeriod: Sets the duration of the voting period (GOVERNOR_ROLE).
 *
 * Internal/Helper:
 * - _generateNftParameters: Internal logic to generate parameters for a new NFT based on global state and block data.
 * - _calculateEvolution: Internal logic to calculate the next evolution state for an NFT.
 * - _beforeTokenTransfer: Internal hook to prevent transferring staked tokens.
 */
contract GenerativeAssetStudio is ERC721, AccessControl, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _nextTokenId;

    bytes32 public constant GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE");

    // --- State Variables ---

    // Minting configuration
    uint256 public _mintPrice;
    bool public _mintAvailable = false;
    address payable public _mintFeeDestination;

    // Generative parameters (simplified example: just an array of uint256)
    uint256[] private _globalParameters;
    uint256 constant public MAX_GLOBAL_PARAMETERS = 16; // Cap the number of parameters

    // Per-NFT parameters (copied from global at mint time)
    mapping(uint256 => uint256[]) private _nftParameters;

    // Per-NFT dynamic state (simplified example: just an array of uint256)
    mapping(uint256 => uint256[]) private _nftEvolutionState;
    uint256 constant public MAX_EVOLUTION_STATE_VARS = 8; // Cap the number of state variables

    // Per-NFT feature locks (prevent specific state variables from evolving)
    mapping(uint256 => mapping(uint256 => bool)) private _featureLocks; // tokenId => stateVarIndex => locked

    // Staking
    mapping(uint256 => address) private _stakedNfts; // tokenId => staker address (0x0 if not staked)
    mapping(address => uint256[]) private _ownerStakedNfts; // staker address => list of staked tokenIds

    // Governance Proposals
    struct ParameterProposal {
        uint256 proposalId;
        uint256 parameterIndex; // Index in _globalParameters to change
        uint256 newValue;       // The value to change it to
        address proposer;       // Address that created the proposal
        uint256 stakeRequired;  // Stake required at time of proposal
        uint256 voteStartTime;  // Block timestamp when voting starts
        uint256 voteEndTime;    // Block timestamp when voting ends
        uint256 votesFor;       // Cumulative votes for
        uint256 votesAgainst;   // Cumulative votes against
        bool executed;          // Whether the proposal has been executed
        mapping(address => bool) voted; // Address => whether they have voted
        ProposalState state;    // Current state of the proposal
    }

    enum ProposalState { Pending, Active, Passed, Failed, Executed, Canceled }

    mapping(uint256 => ParameterProposal) private _proposals;
    uint256 private _proposalCount = 0;

    uint256 public requiredStakeForProposal = 1; // Number of staked NFTs required to create/vote on a proposal
    uint256 public requiredVotesPercentage = 51; // Percentage (out of 100) of total staked NFTs required for 'For' votes to pass
    uint40 public proposalVotingPeriod = 3 days; // Duration for voting in seconds

    // --- Events ---
    event Minted(address indexed to, uint256 indexed tokenId, uint256[] initialParameters);
    event GlobalParameterSet(uint256 indexed parameterIndex, uint256 value, address indexed by);
    event NftEvolved(uint256 indexed tokenId, uint256[] newState);
    event NftFeatureLocked(uint256 indexed tokenId, uint256 indexed featureIndex, address indexed by);
    event NftStaked(uint256 indexed tokenId, address indexed staker);
    event NftUnstaked(uint256 indexed tokenId, address indexed staker);
    event ParameterProposalCreated(uint256 indexed proposalId, address indexed proposer, uint256 parameterIndex, uint256 newValue);
    event ProposalVoted(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId);
    event MintPriceSet(uint256 price, address indexed by);
    event MintAvailabilitySet(bool available, address indexed by);
    event MintFeeDestinationSet(address indexed destination, address indexed by);
    event FundsWithdrawn(uint256 amount, address indexed to, address indexed by);
    event RequiredStakeForProposalSet(uint256 amount, address indexed by);
    event RequiredVotesPercentageSet(uint256 percentage, address indexed by);
    event ProposalVotingPeriodSet(uint40 duration, address indexed by);
    event BaseURISet(string baseURI, address indexed by);

    // --- Constructor ---
    constructor(
        string memory name,
        string memory symbol,
        address defaultAdmin,
        address[] memory initialGovernors,
        uint256 initialMintPrice,
        address payable initialFeeDestination,
        uint256[] memory initialGlobalParameters,
        uint40 _initialVotingPeriod
    ) ERC721(name, symbol) ReentrancyGuard() {
        _setupRole(DEFAULT_ADMIN_ROLE, defaultAdmin);

        for (uint i = 0; i < initialGovernors.length; i++) {
            _setupRole(GOVERNOR_ROLE, initialGovernors[i]);
        }

        require(initialGlobalParameters.length <= MAX_GLOBAL_PARAMETERS, "Too many initial parameters");
        _globalParameters = initialGlobalParameters;

        _mintPrice = initialMintPrice;
        _mintFeeDestination = initialFeeDestination;
        proposalVotingPeriod = _initialVotingPeriod;

        // Initialize evolution state structure (placeholder)
        // Ensure there are enough initial parameters if generation logic relies on them
         for(uint i = _globalParameters.length; i < MAX_GLOBAL_PARAMETERS; i++){
            _globalParameters.push(0); // Pad with zeros if needed
        }
    }

    // --- Access Control Overrides ---
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, AccessControl) returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    // --- Minting Functions ---

    /**
     * @notice Mints a new generative NFT.
     * @param to The address to mint the NFT to.
     */
    function mint(address to) public payable nonReentrant {
        require(_mintAvailable, "Minting is not currently available");
        require(msg.value >= _mintPrice, "Insufficient funds sent");

        uint256 tokenId = _nextTokenId.current();
        _nextTokenId.increment();

        // Generate initial parameters for this specific NFT based on current global state and randomness
        uint256[] memory initialNftParams = _generateNftParameters(tokenId);
        _nftParameters[tokenId] = initialNftParams;

        // Initialize evolution state (e.g., copy initial params or set defaults)
        _nftEvolutionState[tokenId] = new uint256[](MAX_EVOLUTION_STATE_VARS);
         for(uint i = 0; i < MAX_EVOLUTION_STATE_VARS; i++){
             if (i < initialNftParams.length) {
                 _nftEvolutionState[tokenId][i] = initialNftParams[i];
             } else {
                 _nftEvolutionState[tokenId][i] = 0; // Default state
             }
         }


        _safeMint(to, tokenId);

        // Send minting fee
        if (msg.value > 0) {
            (bool success, ) = _mintFeeDestination.call{value: msg.value}("");
            require(success, "Fee transfer failed");
        }

        emit Minted(to, tokenId, initialNftParams);
    }

    /**
     * @notice Sets the mint price.
     * @param price The new mint price in wei.
     */
    function setMintPrice(uint256 price) public onlyRole(GOVERNOR_ROLE) {
        _mintPrice = price;
        emit MintPriceSet(price, msg.sender);
    }

     /**
     * @notice Sets whether minting is available.
     * @param available True to enable, false to disable.
     */
    function setMintAvailability(bool available) public onlyRole(GOVERNOR_ROLE) {
        _mintAvailable = available;
        emit MintAvailabilitySet(available, msg.sender);
    }

     /**
     * @notice Gets the current mint price.
     * @return The current mint price in wei.
     */
    function getMintPrice() public view returns (uint256) {
        return _mintPrice;
    }

     /**
     * @notice Checks if minting is available.
     * @return True if minting is enabled, false otherwise.
     */
    function isMintAvailable() public view returns (bool) {
        return _mintAvailable;
    }

     /**
     * @notice Sets the destination address for minting fees.
     * @param destination The address to send fees to.
     */
    function setMintFeeDestination(address payable destination) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _mintFeeDestination = destination;
        emit MintFeeDestinationSet(destination, msg.sender);
    }

    /**
     * @notice Gets the destination address for minting fees.
     * @return The fee destination address.
     */
     function getMintFeeDestination() public view returns (address payable) {
         return _mintFeeDestination;
     }

    /**
     * @notice Withdraws accumulated ETH fees from the contract.
     */
    function withdrawFunds() public onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");

        (bool success, ) = _mintFeeDestination.call{value: balance}("");
        require(success, "Withdrawal failed");

        emit FundsWithdrawn(balance, _mintFeeDestination, msg.sender);
    }

    /**
     * @notice Returns the total number of tokens in existence.
     * @dev Simply returns the next token ID counter, which represents the total minted.
     * @return The total supply of tokens.
     */
    function totalSupply() public view returns (uint256) {
        return _nextTokenId.current();
    }

    // --- Global Parameter Functions ---

    /**
     * @notice Sets a specific global generative parameter.
     * @param parameterIndex The index of the parameter to set.
     * @param value The new value for the parameter.
     */
    function setGlobalParameter(uint256 parameterIndex, uint256 value) public onlyRole(GOVERNOR_ROLE) {
        require(parameterIndex < _globalParameters.length, "Parameter index out of bounds");
        _globalParameters[parameterIndex] = value;
        emit GlobalParameterSet(parameterIndex, value, msg.sender);
    }

    /**
     * @notice Retrieves a specific global generative parameter.
     * @param parameterIndex The index of the parameter to retrieve.
     * @return The value of the parameter.
     */
    function getGlobalParameter(uint256 parameterIndex) public view returns (uint256) {
        require(parameterIndex < _globalParameters.length, "Parameter index out of bounds");
        return _globalParameters[parameterIndex];
    }

     /**
     * @notice Retrieves all global generative parameters.
     * @return An array containing all global parameters.
     */
    function getAllGlobalParameters() public view returns (uint256[] memory) {
        return _globalParameters;
    }

    // --- NFT Specific Data Functions ---

    /**
     * @notice Retrieves the generative parameters specifically recorded for a given NFT at mint time.
     * @param tokenId The ID of the NFT.
     * @return An array of parameters specific to the NFT.
     */
    function getNftParameters(uint256 tokenId) public view returns (uint256[] memory) {
        _requireMinted(tokenId); // Inherited check from ERC721
        return _nftParameters[tokenId];
    }

    /**
     * @notice Retrieves the current evolution state variables for a given NFT.
     * @param tokenId The ID of the NFT.
     * @return An array representing the current state variables.
     */
    function getNftEvolutionState(uint256 tokenId) public view returns (uint256[] memory) {
        _requireMinted(tokenId); // Inherited check
        return _nftEvolutionState[tokenId];
    }

    // --- NFT Dynamics & Evolution ---

    /**
     * @notice Triggers an evolution step for an NFT.
     * @dev The evolution logic is simplified here; in a real app, it would be more complex.
     * @param tokenId The ID of the NFT to evolve.
     */
    function evolveNft(uint256 tokenId) public nonReentrant {
        require(_exists(tokenId), "NFT does not exist");
        require(_isApprovedOrOwner(msg.sender, tokenId), "Caller is not owner nor approved");
        require(!isNftStaked(tokenId), "Cannot evolve a staked NFT");

        // Calculate the next state based on current state, global parameters, and block data
        uint256[] memory currentEvolutionState = _nftEvolutionState[tokenId];
        uint256[] memory nextEvolutionState = _calculateEvolution(tokenId, currentEvolutionState);

        // Apply the new state, respecting feature locks
        require(nextEvolutionState.length == currentEvolutionState.length, "Evolution calculation returned incorrect state length");

        for(uint i = 0; i < currentEvolutionState.length; i++){
            if (!_featureLocks[tokenId][i]) {
                _nftEvolutionState[tokenId][i] = nextEvolutionState[i];
            }
        }

        emit NftEvolved(tokenId, _nftEvolutionState[tokenId]);
    }

    /**
     * @notice Locks a specific evolutionary feature (state variable) of an NFT.
     * @dev Locked features will not change during subsequent `evolveNft` calls.
     * @param tokenId The ID of the NFT.
     * @param featureIndex The index of the feature/state variable to lock.
     */
    function lockNftFeature(uint256 tokenId, uint256 featureIndex) public {
        require(_exists(tokenId), "NFT does not exist");
        require(_isApprovedOrOwner(msg.sender, tokenId), "Caller is not owner nor approved");
        require(featureIndex < MAX_EVOLUTION_STATE_VARS, "Feature index out of bounds");

        _featureLocks[tokenId][featureIndex] = true;

        emit NftFeatureLocked(tokenId, featureIndex, msg.sender);
    }

    /**
     * @notice Checks if a specific feature (state variable) on an NFT is locked.
     * @param tokenId The ID of the NFT.
     * @param featureIndex The index of the feature/state variable.
     * @return True if the feature is locked, false otherwise.
     */
    function isFeatureLocked(uint256 tokenId, uint256 featureIndex) public view returns (bool) {
         require(_exists(tokenId), "NFT does not exist");
         require(featureIndex < MAX_EVOLUTION_STATE_VARS, "Feature index out of bounds");
         return _featureLocks[tokenId][featureIndex];
    }

    // --- Staking Functions ---

    /**
     * @notice Stakes an NFT, associating it with the staker's address.
     * @dev Staked NFTs cannot be transferred or evolved.
     * @param tokenId The ID of the NFT to stake.
     */
    function stakeNft(uint256 tokenId) public {
        require(_exists(tokenId), "NFT does not exist");
        require(_isApprovedOrOwner(msg.sender, tokenId), "Caller is not owner nor approved");
        require(_stakedNfts[tokenId] == address(0), "NFT is already staked");

        _stakedNfts[tokenId] = msg.sender;
        _ownerStakedNfts[msg.sender].push(tokenId); // Add to owner's list

        // Remove approval status when staking, as only staker/owner can unstake
        _approve(address(0), tokenId);

        emit NftStaked(tokenId, msg.sender);
    }

    /**
     * @notice Unstakes an NFT.
     * @param tokenId The ID of the NFT to unstake.
     */
    function unstakeNft(uint256 tokenId) public {
        require(_exists(tokenId), "NFT does not exist");
        require(_stakedNfts[tokenId] == msg.sender, "Caller is not the staker of this NFT");

        _stakedNfts[tokenId] = address(0);

        // Remove from owner's list (simple swap-and-pop)
        uint256[] storage stakedList = _ownerStakedNfts[msg.sender];
        for (uint i = 0; i < stakedList.length; i++) {
            if (stakedList[i] == tokenId) {
                stakedList[i] = stakedList[stakedList.length - 1];
                stakedList.pop();
                break;
            }
        }

        emit NftUnstaked(tokenId, msg.sender);
    }

     /**
     * @notice Checks if an NFT is currently staked.
     * @param tokenId The ID of the NFT.
     * @return True if staked, false otherwise.
     */
    function isNftStaked(uint256 tokenId) public view returns (bool) {
        return _stakedNfts[tokenId] != address(0);
    }

    /**
     * @notice Gets the list of NFTs staked by a specific owner.
     * @param owner The address of the staker.
     * @return An array of token IDs staked by the owner.
     */
    function getStakedNftsByOwner(address owner) public view returns (uint256[] memory) {
        return _ownerStakedNfts[owner];
    }


    // --- Governance (Parameter Proposal) Functions ---

    /**
     * @notice Allows a staked user to propose a change to a global parameter.
     * @dev Requires the proposer to have the minimum required number of staked NFTs.
     * @param parameterIndex The index of the global parameter to propose changing.
     * @param newValue The proposed new value for the parameter.
     */
    function proposeParameterChange(uint256 parameterIndex, uint256 newValue) public {
        require(parameterIndex < _globalParameters.length, "Parameter index out of bounds");
        require(_ownerStakedNfts[msg.sender].length >= requiredStakeForProposal, "Insufficient staked NFTs to propose");

        uint256 proposalId = _proposalCount;
        _proposals[proposalId] = ParameterProposal({
            proposalId: proposalId,
            parameterIndex: parameterIndex,
            newValue: newValue,
            proposer: msg.sender,
            stakeRequired: requiredStakeForProposal, // Record stake required at proposal time
            voteStartTime: block.timestamp,
            voteEndTime: block.timestamp + proposalVotingPeriod,
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            voted: new mapping(address => bool)(), // Initialize mapping
            state: ProposalState.Active
        });

        _proposalCount++;
        emit ParameterProposalCreated(proposalId, msg.sender, parameterIndex, newValue);
    }

    /**
     * @notice Allows a staked user to vote on an active proposal.
     * @dev Requires the voter to have the minimum required number of staked NFTs. Each address votes once per proposal.
     * @param proposalId The ID of the proposal to vote on.
     * @param support True for a 'yes' vote, false for a 'no' vote.
     */
    function voteOnProposal(uint256 proposalId, bool support) public {
        ParameterProposal storage proposal = _proposals[proposalId];
        require(proposal.proposalId == proposalId, "Proposal does not exist"); // Check proposal existence
        require(proposal.state == ProposalState.Active, "Proposal is not active");
        require(block.timestamp < proposal.voteEndTime, "Voting period has ended");
        require(_ownerStakedNfts[msg.sender].length >= requiredStakeForProposal, "Insufficient staked NFTs to vote");
        require(!proposal.voted[msg.sender], "Already voted on this proposal");

        proposal.voted[msg.sender] = true;

        // Voting weight could be based on number of staked NFTs, or just 1 vote per address as here
        if (support) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }

        emit ProposalVoted(proposalId, msg.sender, support);
    }

    /**
     * @notice Attempts to execute a proposal if it has passed and the voting period is over.
     * @dev Can be called by any account, but checks if conditions are met. A governor can execute anytime after voting ends if passed.
     * @param proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 proposalId) public {
        ParameterProposal storage proposal = _proposals[proposalId];
        require(proposal.proposalId == proposalId, "Proposal does not exist"); // Check proposal existence
        require(proposal.state != ProposalState.Executed, "Proposal already executed");
        require(proposal.state != ProposalState.Canceled, "Proposal canceled");
        require(block.timestamp >= proposal.voteEndTime || hasRole(GOVERNOR_ROLE, msg.sender), "Voting not ended or not governor");

        // Update state based on results (only if voting period is over)
        if (block.timestamp >= proposal.voteEndTime && (proposal.state == ProposalState.Pending || proposal.state == ProposalState.Active)) {
            uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
            uint256 requiredTotalVotes = totalStakedNFTs(); // Or some other metric representing potential voters

            // Simple pass condition: votesFor >= required percentage of *total* staked NFTs AND votesFor > votesAgainst
             if (totalVotes > 0 && proposal.votesFor * 100 >= requiredVotesPercentage * requiredTotalVotes && proposal.votesFor > proposal.votesAgainst) {
                 proposal.state = ProposalState.Passed;
             } else {
                 proposal.state = ProposalState.Failed;
             }
        }

        // Execute only if state is Passed
        require(proposal.state == ProposalState.Passed, "Proposal has not passed or voting not ended");
        require(!proposal.executed, "Proposal already executed");

        // Apply the parameter change
        require(proposal.parameterIndex < _globalParameters.length, "Execution failed: Parameter index out of bounds"); // Re-check index
        _globalParameters[proposal.parameterIndex] = proposal.newValue;
        proposal.executed = true;
        proposal.state = ProposalState.Executed;

        emit ProposalExecuted(proposalId);
        emit GlobalParameterSet(proposal.parameterIndex, proposal.newValue, msg.sender); // Also emit global param change event
    }

    /**
     * @notice Gets the current state of a proposal.
     * @param proposalId The ID of the proposal.
     * @return The state of the proposal (Pending, Active, Passed, Failed, Executed, Canceled).
     */
    function getCurrentProposalState(uint256 proposalId) public view returns (ProposalState) {
         ParameterProposal storage proposal = _proposals[proposalId];
         require(proposal.proposalId == proposalId, "Proposal does not exist"); // Check proposal existence

         // Update state if voting period is over but state hasn't been finalized
         if (proposal.state == ProposalState.Active && block.timestamp >= proposal.voteEndTime) {
             uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
             uint256 requiredTotalVotes = totalStakedNFTs(); // Or total token supply if voting is based on a different token

             // Simple pass condition: votesFor >= required percentage of total staked NFTs AND votesFor > votesAgainst
              if (totalVotes > 0 && proposal.votesFor * 100 >= requiredVotesPercentage * requiredTotalVotes && proposal.votesFor > proposal.votesAgainst) {
                 return ProposalState.Passed;
             } else {
                 return ProposalState.Failed;
             }
         }

         return proposal.state;
    }

    /**
     * @notice Gets the details of a proposal.
     * @param proposalId The ID of the proposal.
     * @return A tuple containing proposal details.
     */
    function getProposalDetails(uint256 proposalId) public view returns (
        uint256, // proposalId
        uint256, // parameterIndex
        uint256, // newValue
        address, // proposer
        uint256, // stakeRequired
        uint256, // voteStartTime
        uint256, // voteEndTime
        uint256, // votesFor
        uint256, // votesAgainst
        bool,    // executed
        ProposalState // state
    ) {
         ParameterProposal storage proposal = _proposals[proposalId];
         require(proposal.proposalId == proposalId, "Proposal does not exist"); // Check proposal existence

         return (
             proposal.proposalId,
             proposal.parameterIndex,
             proposal.newValue,
             proposal.proposer,
             proposal.stakeRequired,
             proposal.voteStartTime,
             proposal.voteEndTime,
             proposal.votesFor,
             proposal.votesAgainst,
             proposal.executed,
             getCurrentProposalState(proposalId) // Return calculated state
         );
    }

    /**
     * @notice Gets the minimum number of staked NFTs required to create/vote on a proposal.
     * @return The required number of staked NFTs.
     */
    function getRequiredStakeForProposal() public view returns (uint256) {
        return requiredStakeForProposal;
    }

    /**
     * @notice Sets the minimum number of staked NFTs required for proposals and voting.
     * @param amount The new required number of staked NFTs.
     */
    function setRequiredStakeForProposal(uint256 amount) public onlyRole(GOVERNOR_ROLE) {
        requiredStakeForProposal = amount;
        emit RequiredStakeForProposalSet(amount, msg.sender);
    }

    /**
     * @notice Gets the percentage of total staked NFTs required for 'For' votes for a proposal to pass.
     * @return The required vote percentage (0-100).
     */
     function getRequiredVotesPercentage() public view returns (uint256) {
         return requiredVotesPercentage;
     }

    /**
     * @notice Sets the percentage of total staked NFTs required for 'For' votes for a proposal to pass.
     * @param percentage The new required vote percentage (0-100).
     */
     function setRequiredVotesPercentage(uint256 percentage) public onlyRole(GOVERNOR_ROLE) {
         require(percentage <= 100, "Percentage cannot exceed 100");
         requiredVotesPercentage = percentage;
         emit RequiredVotesPercentageSet(percentage, msg.sender);
     }

    /**
     * @notice Gets the duration of the voting period for proposals in seconds.
     * @return The voting period duration in seconds.
     */
    function getProposalVotingPeriod() public view returns (uint40) {
        return proposalVotingPeriod;
    }

    /**
     * @notice Sets the duration of the voting period for proposals in seconds.
     * @param duration The new voting period duration in seconds.
     */
    function setProposalVotingPeriod(uint40 duration) public onlyRole(GOVERNOR_ROLE) {
        proposalVotingPeriod = duration;
        emit ProposalVotingPeriodSet(duration, msg.sender);
    }

    /**
     * @notice Helper function to get the total number of currently staked NFTs.
     * @dev This iterates over all token IDs up to the total minted. Could be gas expensive with large supply.
     * @return The total count of staked NFTs.
     */
    function totalStakedNFTs() public view returns (uint256) {
        uint256 count = 0;
        for(uint i = 0; i < _nextTokenId.current(); i++){
            if (_stakedNfts[i] != address(0)) {
                count++;
            }
        }
        return count;
    }

    // --- ERC721 Standard Overrides ---

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     * @dev This implementation returns a base URI concatenated with the token ID and potentially parameters/state as query strings.
     *      The actual JSON metadata and image generation would happen off-chain, reading this contract's data.
     */
    string private _baseURI;

    function _baseURI() internal view override returns (string memory) {
        return _baseURI;
    }

    function setBaseURI(string memory baseURI_) public onlyRole(GOVERNOR_ROLE) {
        _baseURI = baseURI_;
        emit BaseURISet(baseURI_, msg.sender);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId); // Ensure token exists and caller has permission if enforcing strict access
        // In a real dapp, this would likely return something like
        // "ipfs://<cid>/<tokenId> or http://api.example.com/metadata/<tokenId>"
        // The metadata server at that URI would then query this contract's
        // getNftParameters(tokenId) and getNftEvolutionState(tokenId)
        // to generate the dynamic metadata JSON.

        // For demonstration, return baseURI + tokenId
        // Or, if feeling fancy and params are simple enough, construct a simple on-chain data URI:
        // This Base64 example is for *very* simple data. Real metadata is complex.
         string memory base = _baseURI();
         if(bytes(base).length == 0) return ""; // Return empty if no base URI is set

         // Example: Append tokenId and a simple representation of state (for testing/demo)
         // This is NOT how you'd typically put complex metadata on-chain.
         string memory stateString = "";
         uint256[] memory state = _nftEvolutionState[tokenId];
         for(uint i = 0; i < state.length; i++){
             stateString = string(abi.encodePacked(stateString, i > 0 ? "," : "", Strings.toString(state[i])));
         }

         // Simple URI example: baseURI/tokenId?params=...&state=...
         return string(abi.encodePacked(
             base,
             Strings.toString(tokenId),
             "?state=", stateString,
             "&staked=", isNftStaked(tokenId) ? "true" : "false"
         ));
    }


    /**
     * @dev Internal function called before any token transfer.
     * @dev Used here to prevent transfer of staked NFTs.
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        if (from != address(0) && to != address(0)) { // Standard transfer, not minting/burning
             require(!isNftStaked(tokenId), "Cannot transfer a staked NFT");
        }
    }


    // --- Internal/Helper Functions ---

    /**
     * @notice Generates initial parameters for a new NFT based on global state and a source of entropy.
     * @dev Simplified example using block number and global params. In a real app, use VRF.
     * @param tokenId The ID of the token being generated.
     * @return An array of parameters for the new NFT.
     */
    function _generateNftParameters(uint256 tokenId) internal view returns (uint256[] memory) {
        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, block.number, msg.sender, tokenId)));

        uint256[] memory params = new uint256[](MAX_GLOBAL_PARAMETERS);
        for(uint i = 0; i < MAX_GLOBAL_PARAMETERS; i++){
             // Simple generation logic: Combine global parameter with seed and index
            uint256 globalVal = i < _globalParameters.length ? _globalParameters[i] : 0;
            params[i] = (seed + globalVal + i) % 1000; // Example: value between 0-999
        }
        return params;
    }

    /**
     * @notice Calculates the next evolution state for an NFT.
     * @dev Simplified example using current state, global params, and block data.
     * @param tokenId The ID of the token.
     * @param currentState The current evolution state.
     * @return The calculated next evolution state.
     */
    function _calculateEvolution(uint256 tokenId, uint256[] memory currentState) internal view returns (uint256[] memory) {
        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, block.number, tokenId)));

        uint256[] memory nextState = new uint256[](currentState.length);
        uint256[] memory nftParams = _nftParameters[tokenId]; // Parameters fixed at mint

        for(uint i = 0; i < currentState.length; i++){
            uint256 currentVal = currentState[i];
            uint256 globalVal = i < _globalParameters.length ? _globalParameters[i] : 0;
            uint256 nftParamVal = i < nftParams.length ? nftParams[i] : 0;

            // Example evolution logic: combine current state, global param, NFT param, and seed
            // Ensure result stays within a reasonable range, e.g., modulo
            nextState[i] = (currentVal + globalVal + nftParamVal + (seed % 100)) % 1000; // Example: new value between 0-999
        }
        return nextState;
    }

     /**
     * @dev Checks if a token exists by requiring it to be minted.
     * @param tokenId The token ID to check.
     */
    function _requireMinted(uint256 tokenId) internal view {
        require(_exists(tokenId), "ERC721: owner query for nonexistent token");
    }
}
```

---

**Explanation of the 20+ Functions and Concepts:**

Here's a breakdown focusing on the distinct functionalities, including inherited and custom ones:

**Inherited & Standard (Essential for ERC721/AccessControl):**

1.  `constructor`: Initializes the contract, sets up ERC721, AccessControl, and initial parameters/config. (Standard, but with custom initializations).
2.  `supportsInterface`: Standard ERC165 function. (Standard)
3.  `ownerOf(uint256 tokenId)`: Returns the owner of an NFT. (Standard ERC721)
4.  `balanceOf(address owner)`: Returns the number of NFTs owned by an address. (Standard ERC721)
5.  `getApproved(uint256 tokenId)`: Returns the approved address for a token. (Standard ERC721)
6.  `isApprovedForAll(address owner, address operator)`: Checks if an operator is approved for all tokens of an owner. (Standard ERC721)
7.  `transferFrom(address from, address to, uint256 tokenId)`: Transfers token (checks approval/ownership). (Standard ERC721)
8.  `safeTransferFrom(address from, address to, uint256 tokenId)`: Transfers token safely. (Standard ERC721)
9.  `approve(address to, uint256 tokenId)`: Approves an address to manage a token. (Standard ERC721)
10. `setApprovalForAll(address operator, bool approved)`: Sets operator approval. (Standard ERC721)
11. `grantRole(bytes32 role, address account)`: Grants an access control role. (Standard AccessControl)
12. `revokeRole(bytes32 role, address account)`: Revokes an access control role. (Standard AccessControl)
13. `renounceRole(bytes32 role, address account)`: Renounces an access control role. (Standard AccessControl)
14. `hasRole(bytes32 role, address account)`: Checks if an account has a role. (Standard AccessControl)

**Custom & Advanced/Creative Functions:**

15. `tokenURI(uint256 tokenId)`: **Override.** Provides a URI for the NFT's metadata. Critically, this contract intends the off-chain metadata service reading this URI to query the *on-chain* state (`getNftParameters`, `getNftEvolutionState`, `isNftStaked`) to generate *dynamic* metadata, making the NFT's appearance or properties change based on its on-chain state.
16. `totalSupply()`: **Override/Custom Getter.** Returns the total number of NFTs minted using the internal counter `_nextTokenId`.
17. `mint(address to)`: **Custom.** Core minting function. Requires payment (`_mintPrice`), checks availability, calls the internal `_generateNftParameters`, initializes evolution state, and handles fee transfer. This is where the *initial* generative state is set based on current global parameters and on-chain entropy.
18. `setMintPrice(uint256 price)`: **Custom.** Allows a GOVERNOR_ROLE to change the mint cost.
19. `setMintAvailability(bool available)`: **Custom.** Allows a GOVERNOR_ROLE to enable or disable minting.
20. `getMintPrice()`: **Custom.** Getter for the current mint price.
21. `isMintAvailable()`: **Custom.** Getter for minting availability status.
22. `setMintFeeDestination(address payable destination)`: **Custom.** Allows the DEFAULT_ADMIN_ROLE to set where minting fees go.
23. `getMintFeeDestination()`: **Custom.** Getter for the fee destination.
24. `withdrawFunds()`: **Custom.** Allows the DEFAULT_ADMIN_ROLE to withdraw collected ETH.
25. `setGlobalParameter(uint256 parameterIndex, uint256 value)`: **Custom.** Allows a GOVERNOR_ROLE to directly set a global generative parameter.
26. `getGlobalParameter(uint256 parameterIndex)`: **Custom.** Getter for a single global parameter.
27. `getAllGlobalParameters()`: **Custom.** Getter for all global parameters.
28. `getNftParameters(uint256 tokenId)`: **Custom.** Retrieves the immutable parameters specifically assigned to an NFT at mint time.
29. `getNftEvolutionState(uint256 tokenId)`: **Custom.** Retrieves the *current*, dynamic evolution state variables for an NFT.
30. `evolveNft(uint256 tokenId)`: **Custom.** Triggers the dynamic state change for an NFT. Calls the internal `_calculateEvolution` and updates the state, respecting feature locks. This is a core dynamic NFT function.
31. `lockNftFeature(uint256 tokenId, uint256 featureIndex)`: **Custom.** Allows the owner to lock a specific state variable on their NFT, preventing it from changing during evolution.
32. `isFeatureLocked(uint256 tokenId, uint256 featureIndex)`: **Custom.** Checks if an NFT's feature/state variable is locked.
33. `stakeNft(uint256 tokenId)`: **Custom.** Allows an owner to stake their NFT in the contract. Prevents transfer and evolution while staked. Grants utility (voting).
34. `unstakeNft(uint256 tokenId)`: **Custom.** Allows the staker to unstake their NFT.
35. `isNftStaked(uint256 tokenId)`: **Custom.** Checks the staking status of an NFT.
36. `getStakedNftsByOwner(address owner)`: **Custom.** Lists the token IDs of NFTs staked by a given address.
37. `proposeParameterChange(uint256 parameterIndex, uint256 newValue)`: **Custom.** Allows a user with sufficient staked NFTs to propose a change to a global parameter, starting a voting period. (Simple Governance)
38. `voteOnProposal(uint256 proposalId, bool support)`: **Custom.** Allows a user with sufficient staked NFTs to vote on an active proposal. (Simple Governance)
39. `executeProposal(uint256 proposalId)`: **Custom.** Executes a proposal if the voting period is over and it passed. A governor can bypass the time lock for execution if passed. (Simple Governance)
40. `getCurrentProposalState(uint256 proposalId)`: **Custom.** Returns the state of a proposal, calculating Passed/Failed if the voting period is over. (Simple Governance)
41. `getProposalDetails(uint256 proposalId)`: **Custom.** Returns all details of a proposal. (Simple Governance)
42. `getRequiredStakeForProposal()`: **Custom.** Getter for the minimum staked NFTs needed for proposal/voting.
43. `setRequiredStakeForProposal(uint256 amount)`: **Custom.** Allows GOVERNOR_ROLE to set the required stake.
44. `getRequiredVotesPercentage()`: **Custom.** Getter for the percentage of total staked NFTs needed for a proposal to pass.
45. `setRequiredVotesPercentage(uint256 percentage)`: **Custom.** Allows GOVERNOR_ROLE to set the required vote percentage.
46. `getProposalVotingPeriod()`: **Custom.** Getter for the proposal voting duration.
47. `setProposalVotingPeriod(uint40 duration)`: **Custom.** Allows GOVERNOR_ROLE to set the proposal voting duration.
48. `totalStakedNFTs()`: **Custom.** Calculates and returns the total count of NFTs currently staked.
49. `setBaseURI(string memory baseURI_)`: **Custom.** Allows GOVERNOR_ROLE to set the base URI for metadata.

This contract provides a framework where generative traits (derived from `_nftParameters` and potentially `_globalParameters`) are set at mint, but the NFT's state (`_nftEvolutionState`) can change over time via the `evolveNft` function, influenced by the current `_globalParameters`. These global parameters themselves can be influenced by staked NFT holders through a basic proposal and voting system. Locking features provides an owner the ability to preserve certain aspects of their NFT's evolved state. The metadata link ensures that off-chain viewers can see the current, dynamic state. This design goes beyond standard ERC721 minting/transfer by incorporating on-chain data interaction, dynamics, staking, and a rudimentary form of decentralized influence over the asset characteristics.