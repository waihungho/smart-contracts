Okay, let's create a smart contract for a Decentralized Self-Governing Art DAO. This DAO will manage a collection of digital art (represented by NFTs), potentially fund new art creation, and govern its treasury and parameters through liquid democracy voting.

Here's an outline and summary followed by the Solidity code.

**Outline:**

1.  **Contract Definition:** `DecentralizedSelfGoverningArtDAO`
2.  **Interfaces:** ERC20 (minimal for internal token), ERC721, ERC1155 (for interacting with external NFTs).
3.  **Events:** Signify key actions (ProposalCreation, VoteCast, DelegationChanged, ArtRegistered, TreasuryDeposit, ProposalExecuted, ParameterChanged, etc.)
4.  **Enums & Structs:** Define proposal types, states, vote types, proposal structure, voter info, art piece info, governance parameters.
5.  **State Variables:** Store proposal details, voter info, art registry, treasury balance, governance parameters, token data.
6.  **Internal Token Logic:** Minimal implementation for governance tokens.
7.  **Delegation Logic:** Manage liquid democracy delegation.
8.  **Voting Power Calculation:** Determine effective voting power considering delegation.
9.  **Proposal Lifecycle:** Creation, voting, ending, execution.
10. **Execution Logic:** Handle different proposal types (Art Acquisition/Sale, Treasury Spend, Parameter Change, Custom Calls).
11. **Art Registry Logic:** Record and manage metadata/parameters for art pieces owned or curated by the DAO.
12. **Treasury Management:** Receive funds, allow spending via proposals.
13. **Query Functions:** View state, proposal details, voter info, art info, parameters.

**Function Summary (> 20 Functions):**

1.  `constructor()`: Initializes the contract, sets initial parameters.
2.  `mintInitialTokens(address[] recipients, uint256[] amounts)`: Distributes initial governance tokens (callable once by deployer).
3.  `balanceOf(address account)`: (View) Returns the token balance of an account.
4.  `getTotalSupply()`: (View) Returns the total supply of governance tokens.
5.  `delegate(address delegatee)`: Delegates voting power to another address.
6.  `undelegate()`: Revokes current delegation.
7.  `getDelegatedTo(address delegator)`: (View) Returns the address the delegator is delegating to.
8.  `getVotingPower(address account)`: (View) Calculates and returns the effective voting power of an address, considering delegation.
9.  `createProposal(string description, ProposalType proposalType, address targetContract, bytes callData, uint256[] artIds, string[] paramKeys, string[] paramValues, uint256 amount)`: Creates a new proposal of a specific type. Requires minimum stake.
10. `castVote(uint256 proposalId, VoteType voteType)`: Casts a vote on an active proposal.
11. `castDelegatedVote(uint256 proposalId, VoteType voteType, address delegator)`: Allows a delegate to cast a vote on behalf of a specific delegator.
12. `endVotingPeriod(uint256 proposalId)`: Callable by anyone to mark a proposal's voting period as ended and determine outcome.
13. `executeProposal(uint256 proposalId)`: Executes the action for a passed proposal.
14. `depositTreasury()`: Allows anyone to deposit Ether into the DAO treasury.
15. `registerOwnedArt(address nftContract, uint256 nftId, string metadataURI)`: Registers an NFT the DAO owns or has acquired. Callable via `executeProposal`.
16. `getProposalState(uint256 proposalId)`: (View) Returns the current state of a proposal (Pending, Active, Passed, Failed, Executed).
17. `getVoterInfo(address account)`: (View) Returns detailed information about a voter's tokens, delegation, and delegated power.
18. `getArtInfo(uint256 artId)`: (View) Returns basic information about a registered art piece.
19. `getArtParameters(uint256 artId)`: (View) Returns custom parameters for a registered art piece.
20. `getTreasuryBalance()`: (View) Returns the current Ether balance of the DAO treasury.
21. `getProposalVotes(uint256 proposalId)`: (View) Returns the current vote counts for a proposal.
22. `getGovernanceParameters()`: (View) Returns the current governance settings.
23. `getProposals()`: (View) Returns a list of all proposal IDs. (Note: Can be gas-intensive for many proposals)
24. `getActiveProposals()`: (View) Returns a list of currently active proposal IDs.
25. `getPastProposals()`: (View) Returns a list of past proposal IDs (Ended, Executed).
26. `getVote(uint256 proposalId, address voter)`: (View) Checks if a voter has voted on a proposal and their vote type.
27. `distributeRoyalties(address token, address[] recipients, uint256[] amounts)`: (Callable via proposal execution) Distributes a specific token from the treasury as royalties.
28. `setArtRoyaltyRecipient(address nftContract, uint256 nftId, address newRecipient)`: (Callable via proposal execution) Calls an external NFT contract to set the royalty recipient (requires NFT contract support).
29. `transferGovernanceToken(address recipient, uint256 amount)`: (Callable via proposal execution) Transfers governance tokens from the treasury (if DAO holds tokens).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Basic interfaces for interaction
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    // Minimal interface needed for this contract
}

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function transferFrom(address from, address to, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    // Optional: Royalties interface like EIP-2981 if needed for `setArtRoyaltyRecipient`
    // function setRoyaltyRecipient(address newRecipient) external; // Example, not standard
}

interface IERC1155 {
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;
     // Optional: Royalties interface
}


contract DecentralizedSelfGoverningArtDAO {

    // --- Events ---
    event ProposalCreated(uint256 proposalId, address indexed creator, string description, ProposalType proposalType, uint256 endBlock);
    event VoteCast(uint256 indexed proposalId, address indexed voter, VoteType voteType, uint256 weight);
    event DelegationChanged(address indexed delegator, address indexed fromDelegatee, address indexed toDelegatee);
    event ArtRegistered(uint256 artId, address indexed nftContract, uint256 indexed nftId, string metadataURI);
    event ArtParametersUpdated(uint256 indexed artId, string key, string value);
    event TreasuryDeposit(address indexed depositor, uint256 amount);
    event ProposalExecuted(uint256 indexed proposalId);
    event GovernanceParameterChanged(string parameterName, uint256 oldValue, uint256 newValue);
    event TreasuryWithdrawal(address indexed recipient, uint256 amount);
    event GovernanceTokenTransferred(address indexed from, address indexed to, uint256 amount);
    event RoyaltiesDistributed(address indexed token, address[] recipients, uint256[] amounts);

    // --- Enums ---
    enum ProposalType {
        ArtAcquisition,       // Acquire new art (requires DAO to receive NFT)
        ArtSale,              // Sell owned art (requires DAO to send NFT)
        TreasurySpend,        // Spend funds from the treasury (Ether or tokens)
        ParameterChange,      // Change governance parameters
        UpdateArtParams,      // Update custom parameters for registered art
        CustomCall            // Call arbitrary function on a target contract
    }

    enum ProposalState {
        Pending, // Not yet active (could add a queue/delay) - simplicity: starts Active
        Active,
        Passed,
        Failed,
        Executed
    }

    enum VoteType {
        Nay,
        Yay,
        Abstain
    }

    // --- Structs ---
    struct Proposal {
        string description;
        ProposalType proposalType;
        // For CustomCall/TreasurySpend (token transfer)/ArtAcquisition (receive from) / ArtSale (send to) / ParameterChange
        address targetContract; // Contract to interact with or address to send funds to
        bytes callData;         // Data for CustomCall or function signature + params
        uint256 value;          // Ether value for CustomCall or TreasurySpend (Ether)
        // For specific proposal types
        uint256[] artIds;       // Art IDs involved (e.g., for sale, update params)
        string[] paramKeys;     // Parameter keys for UpdateArtParams
        string[] paramValues;   // Parameter values for UpdateArtParams
        address tokenAddress;   // Token address for TreasurySpend (token) or RoyaltiesDistribution
        address[] recipients;   // Recipients for TreasurySpend (tokens/royalties)
        uint256[] amounts;      // Amounts for TreasurySpend (tokens/royalties)
        string parameterName;   // Parameter name for ParameterChange
        uint256 newValue;       // New value for ParameterChange

        bool executed;
        ProposalState state; // Added state tracking
        uint256 startBlock; // When voting starts
        uint256 endBlock;   // When voting ends

        uint256 yayVotes;
        uint256 nayVotes;
        uint256 abstainVotes;

        mapping(address => bool) hasVoted; // Track if an address (not delegate) has voted
        mapping(address => uint256) voteWeights; // Track vote weight per address
    }

    struct VoterInfo {
        uint256 tokenBalance;       // Current balance
        address delegatedTo;        // Address this user delegates to (0x0 if none)
        uint256 delegatedPower;     // Total power delegated *to* this user (sum of delegators' balances)
        // Note: We don't store who delegates *from* here, use delegatedFrom map for that.
    }

     struct ArtPieceInfo {
        address nftContract;    // Address of the NFT contract
        uint256 nftId;          // Token ID of the NFT
        string metadataURI;     // Link to external metadata
        mapping(string => string) parameters; // Custom DAO-governed parameters (e.g., generative seed, display settings)
        bool isRegistered;      // To check if an ID is valid
    }

    struct GovernanceParameters {
        uint256 minStakeToCreateProposal;
        uint256 votingPeriodBlocks; // Duration in blocks
        uint256 quorumPercentage;   // Percentage of total voting power required for a proposal to pass
        // Add more parameters as needed (e.g., proposal execution delay, min/max amounts)
    }

    // --- State Variables ---
    uint256 public totalTokenSupply;
    mapping(address => uint256) private _balances; // Internal token balance tracking
    mapping(address => VoterInfo) public voters; // Voter information (includes delegation)
    mapping(address => address[]) private delegatedFrom; // delegatee => list of delegators (Simplified: direct map, potential gas issue with large lists)

    uint256 public proposalCount;
    mapping(uint256 => Proposal) public proposals;

    uint256 public artCount;
    mapping(uint256 => ArtPieceInfo) public artRegistry; // ID assigned by DAO => ArtPieceInfo

    GovernanceParameters public governanceParameters;

    // Initial minter can mint tokens once to seed the DAO
    address public initialMinter;
    bool public initialTokensMinted = false;


    // --- Modifiers ---
    modifier onlyInitialMinter() {
        require(msg.sender == initialMinter, "Not initial minter");
        _;
    }

    modifier onlyActiveProposal(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= proposalCount, "Invalid proposal ID");
        require(proposals[_proposalId].state == ProposalState.Active, "Proposal not active");
        _;
    }

     modifier onlyEndedProposal(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= proposalCount, "Invalid proposal ID");
        require(proposals[_proposalId].state != ProposalState.Active && proposals[_proposalId].state != ProposalState.Pending, "Proposal still active or pending");
        _;
    }

     modifier onlyPassedProposal(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= proposalCount, "Invalid proposal ID");
        require(proposals[_proposalId].state == ProposalState.Passed, "Proposal has not passed");
        _;
    }

     modifier onlyNotExecuted(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= proposalCount, "Invalid proposal ID");
        require(!proposals[_proposalId].executed, "Proposal already executed");
        _;
    }

    // --- Constructor ---
    constructor(uint256 _minStakeToCreateProposal, uint256 _votingPeriodBlocks, uint256 _quorumPercentage) payable {
        initialMinter = msg.sender;

        governanceParameters = GovernanceParameters({
            minStakeToCreateProposal: _minStakeToCreateProposal,
            votingPeriodBlocks: _votingPeriodBlocks,
            quorumPercentage: _quorumPercentage
        });

         // Deposit initial ether if sent during deployment
        if (msg.value > 0) {
            emit TreasuryDeposit(msg.sender, msg.value);
        }
    }

    // --- Internal Token & Balance Logic ---

    // Minting is restricted for initial distribution
    function mintInitialTokens(address[] calldata recipients, uint256[] calldata amounts) external onlyInitialMinter {
        require(!initialTokensMinted, "Initial tokens already minted");
        require(recipients.length == amounts.length, "Recipients and amounts mismatch");

        uint256 totalMinted = 0;
        for (uint i = 0; i < recipients.length; i++) {
            address recipient = recipients[i];
            uint256 amount = amounts[i];
            _mint(recipient, amount);
            totalMinted += amount;
        }
        totalTokenSupply = totalMinted; // Set total supply based on initial mint
        initialTokensMinted = true; // Prevent further initial minting
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "Mint to the zero address");
        _balances[account] += amount;
        voters[account].tokenBalance += amount;
        // Note: Total supply is set by initial mint, subsequent minting would require governance
        // If adding governance minting, update totalTokenSupply here.
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function getTotalSupply() external view returns (uint256) {
        return totalTokenSupply;
    }


    // --- Delegation Logic ---

    // Calculate effective voting power recursively following delegation chain
    function _getEffectiveVotingPower(address account) internal view returns (uint256) {
        address current = account;
        // Prevent delegation cycles or excessive depth (basic protection)
        for(uint i = 0; i < 10; i++) { // Limit depth to 10
            address delegatee = voters[current].delegatedTo;
             if (delegatee == address(0) || delegatee == account) { // Found end or cycle
                 return voters[current].tokenBalance + voters[current].delegatedPower;
             }
            current = delegatee;
        }
        // If loop exits, potential deep chain or cycle - return just own power
        return voters[account].tokenBalance + voters[account].delegatedPower;
    }


    function delegate(address delegatee) external {
        address delegator = msg.sender;
        require(delegator != delegatee, "Cannot delegate to yourself");

        address currentDelegatee = voters[delegator].delegatedTo;

        if (currentDelegatee != address(0)) {
             // Remove from previous delegatee's delegatedFrom list (simple array modification)
            address[] storage delegatorsList = delegatedFrom[currentDelegatee];
            for (uint i = 0; i < delegatorsList.length; i++) {
                if (delegatorsList[i] == delegator) {
                    delegatorsList[i] = delegatorsList[delegatorsList.length - 1];
                    delegatorsList.pop();
                    break;
                }
            }
             // Decrease previous delegatee's delegated power
            voters[currentDelegatee].delegatedPower -= voters[delegator].tokenBalance; // Delegator's balance was delegated power
        }

        voters[delegator].delegatedTo = delegatee;
        delegatedFrom[delegatee].push(delegator); // Add to new delegatee's delegatedFrom list
        voters[delegatee].delegatedPower += voters[delegator].tokenBalance; // Increase new delegatee's delegated power

        emit DelegationChanged(delegator, currentDelegatee, delegatee);
    }

    function undelegate() external {
        address delegator = msg.sender;
        address currentDelegatee = voters[delegator].delegatedTo;
        require(currentDelegatee != address(0), "Not currently delegating");

         // Remove from delegatee's delegatedFrom list
        address[] storage delegatorsList = delegatedFrom[currentDelegatee];
        for (uint i = 0; i < delegatorsList.length; i++) {
            if (delegatorsList[i] == delegator) {
                delegatorsList[i] = delegatorsList[delegatorsList.length - 1];
                delegatorsList.pop();
                break;
            }
        }
         // Decrease delegatee's delegated power
        voters[currentDelegatee].delegatedPower -= voters[delegator].tokenBalance; // Delegator's balance was delegated power

        voters[delegator].delegatedTo = address(0); // Clear delegation
        emit DelegationChanged(delegator, currentDelegatee, address(0));
    }

     // Get the address the user is delegating their voting power to
    function getDelegatedTo(address delegator) external view returns (address) {
        return voters[delegator].delegatedTo;
    }

    // Get the effective voting power of an account (including delegated power)
    function getVotingPower(address account) external view returns (uint256) {
         // Return effective voting power including nested delegation up to a limit
         return _getEffectiveVotingPower(account);
    }

     // Get the list of addresses delegating their power *to* this address
     // NOTE: This can be gas intensive if an address has many delegators.
     function getDelegators(address delegatee) external view returns (address[] memory) {
         return delegatedFrom[delegatee];
     }


    // --- Proposal Logic ---

    function createProposal(
        string calldata description,
        ProposalType proposalType,
        address targetContract, // For CustomCall, TreasurySpend recipient, ArtAcquisition (source), ArtSale (destination), RoyaltyRecipient (new recipient)
        bytes calldata callData, // For CustomCall
        uint256 value,           // For CustomCall (Ether) or TreasurySpend (Ether)
        uint256[] calldata artIds, // For ArtSale, UpdateArtParams
        string[] calldata paramKeys, // For UpdateArtParams
        string[] calldata paramValues, // For UpdateArtParams
        address tokenAddress,    // For TreasurySpend (token), RoyaltiesDistribution
        address[] calldata recipients, // For TreasurySpend (tokens/royalties)
        uint256[] calldata amounts,  // For TreasurySpend (tokens/royalties)
        string calldata parameterName, // For ParameterChange
        uint256 newValue         // For ParameterChange
    ) external {
        require(_getVotingPower(msg.sender) >= governanceParameters.minStakeToCreateProposal, "Creator does not have enough voting power");
        require(bytes(description).length > 0, "Description cannot be empty");
         require(governanceParameters.votingPeriodBlocks > 0, "Voting period must be greater than 0");

        proposalCount++;
        uint256 currentProposalId = proposalCount;

        Proposal storage newProposal = proposals[currentProposalId];
        newProposal.description = description;
        newProposal.proposalType = proposalType;
        newProposal.targetContract = targetContract;
        newProposal.callData = callData;
        newProposal.value = value;
        newProposal.artIds = artIds;
        newProposal.paramKeys = paramKeys;
        newProposal.paramValues = paramValues;
        newProposal.tokenAddress = tokenAddress;
        newProposal.recipients = recipients;
        newProposal.amounts = amounts;
        newProposal.parameterName = parameterName;
        newProposal.newValue = newValue;

        newProposal.state = ProposalState.Active; // Starts active immediately
        newProposal.startBlock = block.number;
        newProposal.endBlock = block.number + governanceParameters.votingPeriodBlocks;
        newProposal.executed = false;

        // Basic validation based on type
        if (proposalType == ProposalType.TreasurySpend && value == 0 && (recipients.length == 0 || recipients.length != amounts.length)) {
             require(tokenAddress != address(0), "Token address required for token spend");
             require(recipients.length > 0 && recipients.length == amounts.length, "Recipients and amounts required for token spend");
        } else if (proposalType == ProposalType.UpdateArtParams) {
             require(artIds.length > 0, "Art IDs required for UpdateArtParams");
             require(paramKeys.length > 0 && paramKeys.length == paramValues.length, "Parameter keys and values required for UpdateArtParams");
             // Check if art IDs are registered (optional, can also check during execution)
        } else if (proposalType == ProposalType.ParameterChange) {
             require(bytes(parameterName).length > 0, "Parameter name required for ParameterChange");
        } else if (proposalType == ProposalType.CustomCall) {
             require(targetContract != address(0), "Target contract required for CustomCall");
             require(callData.length > 0, "Call data required for CustomCall");
        } else if (proposalType == ProposalType.ArtSale) {
             require(artIds.length > 0, "Art IDs required for ArtSale");
             require(targetContract != address(0), "Recipient address required for ArtSale"); // Target is the buyer/recipient
        } else if (proposalType == ProposalType.ArtAcquisition) {
            // Requires the DAO to receive the NFT later, execution doesn't *send* here
            // The `targetContract` might be the source address the NFT is expected from, or the NFT contract address itself for context.
            // This proposal type is more about approving the *act* of acquisition and potentially spending treasury funds (if also included via `value` or `tokenAddress`/`recipients`/`amounts`).
        }


        emit ProposalCreated(currentProposalId, msg.sender, description, proposalType, newProposal.endBlock);
    }

    function castVote(uint256 proposalId, VoteType voteType) external onlyActiveProposal(proposalId) {
        address voterAddress = msg.sender;
        // If the sender is delegating, their vote power is 0 here. They must vote via delegate.
        require(voters[voterAddress].delegatedTo == address(0), "Cannot vote directly while delegating");
        require(!proposals[proposalId].hasVoted[voterAddress], "Already voted on this proposal");

        uint256 weight = _getVotingPower(voterAddress); // Get total power including delegated-to power
        require(weight > 0, "Voter has no voting power");

        proposals[proposalId].hasVoted[voterAddress] = true;
        proposals[proposalId].voteWeights[voterAddress] = weight; // Store individual weight contribution

        if (voteType == VoteType.Yay) {
            proposals[proposalId].yayVotes += weight;
        } else if (voteType == VoteType.Nay) {
            proposals[proposalId].nayVotes += weight;
        } else { // Abstain
            proposals[proposalId].abstainVotes += weight;
        }

        emit VoteCast(proposalId, voterAddress, voteType, weight);
    }

    // Allows a delegate to cast a vote on behalf of a specific delegator.
    // The delegate's *own* vote is separate. This is for liquid democracy mechanics.
    // The delegator must have explicitly delegated to msg.sender.
    function castDelegatedVote(uint256 proposalId, VoteType voteType, address delegator) external onlyActiveProposal(proposalId) {
         require(voters[delegator].delegatedTo == msg.sender, "Sender is not the delegate for this address");
         require(!proposals[proposalId].hasVoted[delegator], "Delegator has already voted on this proposal (directly or via another delegation path)"); // Check if the original delegator address has voted
         require(voters[delegator].tokenBalance > 0, "Delegator has no token balance to delegate");

        uint256 weight = voters[delegator].tokenBalance; // The power comes from the delegator's balance
        // Note: This does NOT include the delegated power the delegator themselves received.
        // That power can only be voted by the original source or their delegate chain end.
        // This prevents double counting power via delegation paths.
        // Alternative: Include delegatedPower here too, requires careful cycle prevention and state tracking. Sticking to simpler "token holder delegates their balance" model for casting.

        require(weight > 0, "Delegator has no token balance to vote with");


        proposals[proposalId].hasVoted[delegator] = true; // Mark the original delegator as having voted
        // We don't store voteWeights per delegator, the weight is added to the total counts.
        // We could store a mapping(address => VoteType) to allow fetching individual delegated votes if needed.

        if (voteType == VoteType.Yay) {
            proposals[proposalId].yayVotes += weight;
        } else if (voteType == VoteType.Nay) {
            proposals[proposalId].nayVotes += weight;
        } else { // Abstain
            proposals[proposalId].abstainVotes += weight;
        }

         // Emit event with msg.sender as voter, but perhaps indicate it's on behalf of delegator
        emit VoteCast(proposalId, msg.sender, voteType, weight); // Event shows *who* cast the transaction
        // A more detailed event could include the 'on behalf of' address.
    }


    function endVotingPeriod(uint256 proposalId) external {
        require(proposalId > 0 && proposalId <= proposalCount, "Invalid proposal ID");
        Proposal storage proposal = proposals[proposalId];
        require(proposal.state == ProposalState.Active, "Proposal not active");
        require(block.number > proposal.endBlock, "Voting period not ended yet");

        // Calculate total potential voting power based on total token supply at proposal start/end
        // This is simplified - a real DAO might track voting power snapshots per block.
        // Using current total supply for simplicity here.
        uint256 currentTotalSupply = totalTokenSupply;
        if (currentTotalSupply == 0) { // Avoid division by zero if no tokens exist
             proposal.state = ProposalState.Failed; // Cannot pass if no voting power
             return;
        }

        uint256 totalVotes = proposal.yayVotes + proposal.nayVotes + proposal.abstainVotes;

        // Check Quorum: Total votes cast must meet quorum percentage of total supply
        // This uses a simple quorum check on total tokens. A more advanced DAO might check quorum on *active* voters or staked tokens.
        uint256 requiredQuorumVotes = (currentTotalSupply * governanceParameters.quorumPercentage) / 100;

        if (totalVotes >= requiredQuorumVotes && proposal.yayVotes > proposal.nayVotes) {
            proposal.state = ProposalState.Passed;
        } else {
            proposal.state = ProposalState.Failed;
        }
    }

    function executeProposal(uint256 proposalId) external onlyEndedProposal(proposalId) onlyPassedProposal(proposalId) onlyNotExecuted(proposalId) {
        Proposal storage proposal = proposals[proposalId];
        proposal.executed = true; // Mark as executed first

        // Execute based on proposal type
        if (proposal.proposalType == ProposalType.ArtAcquisition) {
            // This type usually signifies the DAO *approves* receiving an NFT
            // The actual transfer of the NFT to the DAO address happens externally.
            // This execution step could optionally trigger recording the acquisition or receiving Ether/tokens if the proposal included payment terms.
             // Example: If the proposal included a `targetContract` (the expected NFT contract) and `artIds` (expected token IDs), we could register them here.
            for(uint i=0; i < proposal.artIds.length; i++) {
                _registerOwnedArt(proposal.targetContract, proposal.artIds[i], ""); // Metadata might be set later
            }
             // If the proposal included payment by the DAO, execute that here
             if (proposal.value > 0 && address(this).balance >= proposal.value) {
                 // Payment for acquisition. Requires targetContract to be the seller.
                 (bool success, ) = payable(proposal.targetContract).call{value: proposal.value}("");
                 require(success, "Ether payment failed");
                 emit TreasuryWithdrawal(proposal.targetContract, proposal.value);
             }
             if (proposal.tokenAddress != address(0) && proposal.recipients.length > 0 && proposal.recipients.length == proposal.amounts.length) {
                 // Payment in tokens. Requires targetContract to be the seller. Only transfers to ONE recipient (the seller).
                 require(proposal.recipients.length == 1, "Token payment for acquisition must have exactly one recipient (the seller)");
                 _transferToken(proposal.tokenAddress, proposal.recipients[0], proposal.amounts[0]);
                  emit TreasuryWithdrawal(proposal.recipients[0], proposal.amounts[0]); // Emitting withdrawal for tokens too
             }


        } else if (proposal.proposalType == ProposalType.ArtSale) {
             // Requires the DAO to send an NFT. targetContract is the buyer address. artIds are the NFTs to send.
             require(proposal.targetContract != address(0), "Recipient required for ArtSale execution");
             for(uint i=0; i < proposal.artIds.length; i++) {
                 uint256 artId = proposal.artIds[i];
                 require(artRegistry[artId].isRegistered, "Art piece not registered by DAO");
                 address nftContract = artRegistry[artId].nftContract;
                 uint256 nftTokenId = artRegistry[artId].nftId;

                // Assuming the DAO contract is approved or owner of the NFT
                 bytes memory data = ""; // No data needed for standard ERC721/1155 transfer
                 if (IERC721(nftContract).ownerOf(nftTokenId) == address(this)) {
                     IERC721(nftContract).safeTransferFrom(address(this), proposal.targetContract, nftTokenId);
                 } else if (IERC1155(nftContract).balanceOf(address(this), nftTokenId) > 0) {
                      // Assuming amount is 1 for sale of a single edition
                     IERC1155(nftContract).safeTransferFrom(address(this), proposal.targetContract, nftTokenId, 1, data);
                 } else {
                     revert("DAO does not own the NFT specified for sale");
                 }
                 // Optionally, remove from registry after sale, or mark as 'sold'
             }
             // If the proposal included receiving payment, that happens externally to the DAO.
             // This execution step only covers the sending of the art.

        } else if (proposal.proposalType == ProposalType.TreasurySpend) {
             // targetContract is the recipient for Ether, recipients[] for tokens/Ether.
             // value is Ether amount, tokenAddress/recipients/amounts for tokens.
            if (proposal.value > 0) { // Spending Ether
                require(address(this).balance >= proposal.value, "Insufficient Ether balance for TreasurySpend");
                // Assuming targetContract is the single recipient for Ether spend
                (bool success, ) = payable(proposal.targetContract).call{value: proposal.value}("");
                require(success, "Ether spend failed");
                emit TreasuryWithdrawal(proposal.targetContract, proposal.value);
            } else if (proposal.tokenAddress != address(0) && proposal.recipients.length > 0 && proposal.recipients.length == proposal.amounts.length) { // Spending tokens
                 require(IERC20(proposal.tokenAddress).balanceOf(address(this)) >= _sumArray(proposal.amounts), "Insufficient token balance for TreasurySpend");
                 for(uint i=0; i < proposal.recipients.length; i++) {
                     _transferToken(proposal.tokenAddress, proposal.recipients[i], proposal.amounts[i]);
                      emit TreasuryWithdrawal(proposal.recipients[i], proposal.amounts[i]); // Emitting withdrawal for tokens
                 }
             } else {
                 revert("Invalid TreasurySpend parameters");
             }

        } else if (proposal.proposalType == ProposalType.ParameterChange) {
             // Update a governance parameter. Requires specific parameterName and newValue.
             bytes memory parameterNameBytes = bytes(proposal.parameterName);
             if (compareBytes(parameterNameBytes, bytes("minStakeToCreateProposal"))) {
                 uint256 oldValue = governanceParameters.minStakeToCreateProposal;
                 governanceParameters.minStakeToCreateProposal = proposal.newValue;
                 emit GovernanceParameterChanged("minStakeToCreateProposal", oldValue, governanceParameters.minStakeToCreateProposal);
             } else if (compareBytes(parameterNameBytes, bytes("votingPeriodBlocks"))) {
                 uint256 oldValue = governanceParameters.votingPeriodBlocks;
                 governanceParameters.votingPeriodBlocks = proposal.newValue;
                 emit GovernanceParameterChanged("votingPeriodBlocks", oldValue, governanceParameters.votingPeriodBlocks);
             } else if (compareBytes(parameterNameBytes, bytes("quorumPercentage"))) {
                  require(proposal.newValue <= 100, "Quorum percentage cannot exceed 100");
                 uint256 oldValue = governanceParameters.quorumPercentage;
                 governanceParameters.quorumPercentage = proposal.newValue;
                 emit GovernanceParameterChanged("quorumPercentage", oldValue, governanceParameters.quorumPercentage);
             } else {
                 revert("Unknown parameter name for change");
             }

        } else if (proposal.proposalType == ProposalType.UpdateArtParams) {
             // Update custom parameters for a registered art piece.
             require(proposal.artIds.length == 1, "UpdateArtParams requires exactly one art ID");
             uint256 artId = proposal.artIds[0];
             require(artRegistry[artId].isRegistered, "Art piece not registered by DAO");
             require(proposal.paramKeys.length == proposal.paramValues.length, "Param keys and values mismatch");
             for(uint i=0; i < proposal.paramKeys.length; i++) {
                  artRegistry[artId].parameters[proposal.paramKeys[i]] = proposal.paramValues[i];
                  emit ArtParametersUpdated(artId, proposal.paramKeys[i], proposal.paramValues[i]);
             }

        } else if (proposal.proposalType == ProposalType.CustomCall) {
             // Execute arbitrary call data on a target contract. Powerful, use with caution.
             require(proposal.targetContract != address(0), "Target contract required for CustomCall");
             require(proposal.callData.length > 0, "Call data required for CustomCall");
             // Reentrancy check is important here if interacting with untrusted contracts
             (bool success, ) = proposal.targetContract.call{value: proposal.value}(proposal.callData);
             require(success, "Custom call execution failed");

        } else {
             revert("Unknown proposal type");
        }

        emit ProposalExecuted(proposalId);
    }

    // Allows anyone to deposit Ether into the DAO treasury
    receive() external payable {
        emit TreasuryDeposit(msg.sender, msg.value);
    }

    function depositTreasury() external payable {
         emit TreasuryDeposit(msg.sender, msg.value);
    }


    // --- Art Registry Logic ---

    // This function should only be callable via proposal execution
    function _registerOwnedArt(address nftContract, uint256 nftId, string memory metadataURI) internal {
        // Add checks: Does the DAO contract actually own this NFT? (Requires calling external contract)
        // For ERC721: IERC721(nftContract).ownerOf(nftId) == address(this)
        // For ERC1155: IERC1155(nftContract).balanceOf(address(this), nftId) > 0
        // Or trust the proposal process validated ownership off-chain.
        // Adding basic check for demo:
        bytes4 ownerOfSelector = bytes4(keccak256("ownerOf(uint256)"));
        bytes memory callData = abi.encodePacked(ownerOfSelector, nftId);
        (bool success721, bytes memory returnData721) = nftContract.staticcall(callData);

        bytes4 balanceOfSelector = bytes4(keccak256("balanceOf(address,uint256)"));
        bytes memory callData1155 = abi.encodePacked(balanceOfSelector, address(this), nftId);
        (bool success1155, bytes memory returnData1155) = nftContract.staticcall(callData1155);


        bool owned = false;
        if (success721 && returnData721.length >= 32) {
            address owner = abi.decode(returnData721, (address));
            if (owner == address(this)) owned = true;
        } else if (success1155 && returnData1155.length >= 32) {
             uint256 balance = abi.decode(returnData1155, (uint256));
             if (balance > 0) owned = true;
        }

        require(owned, "DAO does not own the NFT to register");


        // Check if already registered (optional, depends on desired behavior)
        // Could iterate through artRegistry or add a reverse mapping

        artCount++;
        uint256 currentArtId = artCount;
        ArtPieceInfo storage newArt = artRegistry[currentArtId];
        newArt.nftContract = nftContract;
        newArt.nftId = nftId;
        newArt.metadataURI = metadataURI;
        newArt.isRegistered = true; // Mark as valid entry

        emit ArtRegistered(currentArtId, nftContract, nftId, metadataURI);
    }


    // Function callable via proposal execution to distribute specific tokens (e.g., royalties)
    // Requires the DAO to hold the token balance.
    function distributeRoyalties(address token, address[] calldata recipients, uint256[] calldata amounts) external {
        // This function should only be callable via a specific proposal type execution
        // Add an internal flag or check msg.sender == address(this)
        // For simplicity in this example, assuming it's called correctly via executeProposal.
        require(msg.sender == address(this), "Only DAO can call this function");
        require(token != address(0), "Invalid token address");
        require(recipients.length > 0 && recipients.length == amounts.length, "Recipients and amounts mismatch");

        uint256 totalAmount = 0;
        for(uint i=0; i < amounts.length; i++) {
            totalAmount += amounts[i];
        }
        require(IERC20(token).balanceOf(address(this)) >= totalAmount, "Insufficient token balance for distribution");

        for(uint i=0; i < recipients.length; i++) {
             require(recipients[i] != address(0), "Invalid recipient address");
            IERC20(token).transfer(recipients[i], amounts[i]);
        }

        emit RoyaltiesDistributed(token, recipients, amounts);
    }


     // Function callable via proposal execution to call setRoyaltyRecipient on an external NFT
     // Assumes the NFT contract implements a function like `setRoyaltyRecipient(address newRecipient)`
     function setArtRoyaltyRecipient(address nftContract, uint256 nftId, address newRecipient) external {
         require(msg.sender == address(this), "Only DAO can call this function");
         require(nftContract != address(0), "Invalid NFT contract address");
         require(newRecipient != address(0), "Invalid recipient address");

         bytes4 selector = bytes4(keccak256("setRoyaltyRecipient(address)"));
         bytes memory callData = abi.encodePacked(selector, newRecipient);

          // Check if the DAO owns the art first
         bytes4 ownerOfSelector = bytes4(keccak256("ownerOf(uint256)"));
         bytes memory ownerCallData = abi.encodePacked(ownerOfSelector, nftId);
         (bool successOwner, bytes memory returnDataOwner) = nftContract.staticcall(ownerCallData);
         bool owned = false;
         if (successOwner && returnDataOwner.length >= 32) {
             address owner = abi.decode(returnDataOwner, (address));
             if (owner == address(this)) owned = true;
         }
         require(owned, "DAO does not own this NFT or it is not ERC721 with ownerOf"); // Simplified check

         (bool success, ) = nftContract.call(callData);
         require(success, "Failed to call setRoyaltyRecipient on NFT contract");

         // Optionally, record this action within the DAO state
     }


    // Function callable via proposal execution to transfer governance tokens held by the DAO
    // The DAO could receive tokens (e.g., from a sale), and distribute them.
    function transferGovernanceToken(address recipient, uint256 amount) external {
        require(msg.sender == address(this), "Only DAO can call this function");
        require(recipient != address(0), "Transfer to the zero address");
        // Use internal _balances check
        require(_balances[address(this)] >= amount, "Insufficient DAO governance token balance");

        _balances[address(this)] -= amount;
        _balances[recipient] += amount;
        // Voter info is for user stakes, not DAO balance, so no update to voters mapping here.

        emit GovernanceTokenTransferred(address(this), recipient, amount);
    }


    // --- Query Functions ---

    function getProposalState(uint256 proposalId) external view returns (ProposalState) {
         require(proposalId > 0 && proposalId <= proposalCount, "Invalid proposal ID");
         Proposal storage proposal = proposals[proposalId];
         if (proposal.state == ProposalState.Active && block.number > proposal.endBlock) {
             // Voting period ended, but state hasn't been updated yet by endVotingPeriod
             // We can calculate the potential outcome here, but the official state is updated by the function call.
             // For this view function, just return the stored state.
             return ProposalState.Active; // Or add a 'ReadyToEnd' state check
         }
         return proposal.state;
    }

    function getVoterInfo(address account) external view returns (uint256 tokenBalance, address delegatedTo, uint256 delegatedPower, uint256 effectiveVotingPower) {
        VoterInfo storage info = voters[account];
        return (info.tokenBalance, info.delegatedTo, info.delegatedPower, _getEffectiveVotingPower(account));
    }

    function getArtInfo(uint256 artId) external view returns (address nftContract, uint256 nftId, string memory metadataURI) {
         require(artRegistry[artId].isRegistered, "Art piece not registered");
         ArtPieceInfo storage art = artRegistry[artId];
         return (art.nftContract, art.nftId, art.metadataURI);
    }

    function getArtParameters(uint256 artId) external view returns (string[] memory keys, string[] memory values) {
         require(artRegistry[artId].isRegistered, "Art piece not registered");
         // Reading from a mapping directly like this is not possible in Solidity
         // You would need to store keys in an array when adding parameters or provide a way to get parameters by key
         // For this example, returning empty arrays. A real implementation would need a different storage pattern.
         // Example: Store keys in an array: string[] public artParameterKeys[uint256 artId];
         // And map key => value: mapping(uint256 => mapping(string => string)) public artParameters;

         // Simplified for demo: you would query specific parameters using artRegistry[artId].parameters[key]
         // This function signature is misleading as implemented due to mapping limitations.
         // A practical version would require querying per key or returning a list of keys.
          return (new string[](0), new string[](0));
    }


    function getTreasuryBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function getProposalVotes(uint256 proposalId) external view returns (uint256 yay, uint256 nay, uint256 abstain) {
        require(proposalId > 0 && proposalId <= proposalCount, "Invalid proposal ID");
        Proposal storage proposal = proposals[proposalId];
        return (proposal.yayVotes, proposal.nayVotes, proposal.abstainVotes);
    }

    function getGovernanceParameters() external view returns (uint256 minStakeToCreateProposal, uint256 votingPeriodBlocks, uint256 quorumPercentage) {
        return (governanceParameters.minStakeToCreateProposal, governanceParameters.votingPeriodBlocks, governanceParameters.quorumPercentage);
    }

    // Get list of all proposal IDs
    // NOTE: Gas intensive for many proposals
    function getProposals() external view returns (uint256[] memory) {
        uint256[] memory proposalIds = new uint256[proposalCount];
        for (uint i = 0; i < proposalCount; i++) {
            proposalIds[i] = i + 1;
        }
        return proposalIds;
    }

     // Get list of currently active proposal IDs
    function getActiveProposals() external view returns (uint256[] memory) {
        uint256[] memory activeIds = new uint256[proposalCount]; // Max size
        uint256 count = 0;
        for (uint i = 1; i <= proposalCount; i++) {
            if (proposals[i].state == ProposalState.Active) {
                activeIds[count] = i;
                count++;
            }
        }
        bytes memory packed = abi.encodePacked(activeIds); // Pack to size
        return abi.decode(packed[0:count * 32], (uint256[]));
    }

     // Get list of past proposal IDs (Failed, Passed, Executed)
    function getPastProposals() external view returns (uint256[] memory) {
         uint256[] memory pastIds = new uint256[proposalCount]; // Max size
        uint256 count = 0;
        for (uint i = 1; i <= proposalCount; i++) {
            if (proposals[i].state != ProposalState.Pending && proposals[i].state != ProposalState.Active) {
                pastIds[count] = i;
                count++;
            }
        }
        bytes memory packed = abi.encodePacked(pastIds); // Pack to size
        return abi.decode(packed[0:count * 32], (uint256[]));
    }

    // Check how a specific address voted on a proposal
    function getVote(uint256 proposalId, address voter) external view returns (VoteType, uint256 weight, bool voted) {
        require(proposalId > 0 && proposalId <= proposalCount, "Invalid proposal ID");
        Proposal storage proposal = proposals[proposalId];
        // Note: This only returns direct votes or votes explicitly cast by a delegate *on behalf of* the delegator if hasVoted is tracked per delegator.
        // As implemented, hasVoted is per original voter address.
        return (VoteType.Abstain, proposal.voteWeights[voter], proposal.hasVoted[voter]); // VoteType returned here is not stored per voter, needs refinement.
        // To return vote type per voter, mapping(address => VoteType) would be needed in the Proposal struct.
        // Returning Abstain as a placeholder if not explicitly tracked per voter.
    }


    // --- Internal Helper Functions ---

    // Helper to transfer tokens (internal or external)
    function _transferToken(address tokenAddress, address recipient, uint256 amount) internal {
         require(recipient != address(0), "Transfer to the zero address");
         if (tokenAddress == address(0)) { // Assuming address(0) is a way to signify the internal DAO token
             // Transfer internal token
             require(_balances[address(this)] >= amount, "Insufficient internal token balance");
             _balances[address(this)] -= amount;
             _balances[recipient] += amount;
             // No voter info update here, this is for DAO holding internal tokens, not user stakes.
         } else {
             // Transfer external ERC20 token
             require(IERC20(tokenAddress).transfer(recipient, amount), "External token transfer failed");
         }
    }

    // Helper to compare bytes (for string comparison)
    function compareBytes(bytes memory a, bytes memory b) internal pure returns (bool) {
        return keccak256(a) == keccak256(b);
    }

    // Helper to sum an array
     function _sumArray(uint256[] memory arr) internal pure returns (uint256) {
         uint256 sum = 0;
         for(uint i=0; i < arr.length; i++) {
             sum += arr[i];
         }
         return sum;
     }

    // Fallback function to receive Ether
    fallback() external payable {
        emit TreasuryDeposit(msg.sender, msg.value);
    }
}
```