Okay, here is a Solidity smart contract embodying an interesting, advanced, and creative concept: a Decentralized Autonomous Art Foundry (DAAF).

This contract allows a community (governance token holders) to propose, vote on, and collectively decide on the creation and management of digital art pieces, represented as NFTs. The NFTs can have dynamic parameters controlled by the community through further governance actions.

We will avoid direct inheritance of standard libraries like OpenZeppelin to adhere to the "don't duplicate open source" constraint strictly, implementing necessary token logic ourselves in a simplified manner sufficient for this contract's purpose. Standard interfaces (like ERC20, ERC721) are referenced in principle but not directly inherited or imported as full libraries.

---

**Decentralized Autonomous Art Foundry (DAAF)**

**Outline:**

1.  **State Variables:** Define core contract state, including mappings for governance tokens, NFTs, proposals, art parameters, and configuration.
2.  **Events:** Declare events for transparency and off-chain monitoring.
3.  **Enums:** Define states and types for proposals.
4.  **Structs:** Define data structures for Art Parameters and Proposals.
5.  **Simplified Governance Token (DAAFGov):** Basic internal functions for minting, transfer, balance tracking. Not a full ERC20, but sufficient for internal governance.
6.  **Simplified Art NFT (DAAFArt):** Basic internal functions for minting, transfer, ownership, and tracking metadata/dynamic parameters. Not a full ERC721, but sufficient for internal management. Includes dynamic metadata logic.
7.  **Art Parameters Management:** Functions for submitting and retrieving potential art parameter sets.
8.  **Proposal & Voting System:** Functions for creating proposals (creation, sale, burn, parameter update, fund distribution), voting, checking state, and retrieving details. Token balance dictates voting power.
9.  **Proposal Execution:** Functions callable by anyone (once a proposal succeeds and is in the executable state) to trigger the contract's action based on the proposal type. This is the core autonomous part.
10. **Art Management (Post-Minting):** Logic within execution functions to handle NFT transfers (to/from vault), burning, and updating dynamic parameters.
11. **Vault Management:** Logic within execution functions to handle Ether received from sales or distributions.
12. **Configuration & Admin:** Constructor and functions to update governance parameters (voting period, thresholds) via governance itself.
13. **Helpers:** Internal helper functions for state checks, vote counting, etc.

**Function Summary:**

*   **Governance Token (Simplified):**
    1.  `constructor`: Initializes contract, mints initial governance tokens.
    2.  `mintGovTokens`: Mints DAAFGov tokens (restricted access).
    3.  `transferGovTokens`: Transfers DAAFGov tokens (basic internal logic).
    4.  `balanceOfGovTokens`: Gets DAAFGov balance for an address.
    5.  `totalSupplyGovTokens`: Gets total DAAFGov supply.
    6.  `approveGovTokens`: Sets allowance for DAAFGov tokens.
    7.  `transferFromGovTokens`: Transfers DAAFGov tokens using allowance.
*   **Art NFT (Simplified & Dynamic):**
    8.  `mintArtNFT`: Mints a new DAAFArt NFT (internal, called by execution).
    9.  `transferArtNFT`: Transfers DAAFArt NFT (basic internal logic, respects approvals).
    10. `ownerOfArtNFT`: Gets owner of a DAAFArt NFT.
    11. `balanceOfArtNFTs`: Gets count of DAAFArt NFTs owned by an address.
    12. `tokenURI`: Generates dynamic metadata URI based on stored parameters.
    13. `approveArtNFT`: Sets approval for a single DAAFArt NFT.
    14. `getApprovedArtNFT`: Gets approved address for a DAAFArt NFT.
    15. `setApprovalForAllArtNFT`: Sets operator approval for all DAAFArt NFTs.
    16. `isApprovedForAllArtNFT`: Checks operator approval status.
    17. `updateDynamicArtParameter`: Updates a specific dynamic parameter for an NFT (only via executed proposal).
    18. `getDynamicArtParameter`: Retrieves a dynamic parameter for an NFT.
*   **Art Parameters:**
    19. `submitArtParameters`: Allows anyone to submit a potential set of parameters for future art.
    20. `getArtParameters`: Retrieves details of submitted art parameters.
*   **Proposals & Voting:**
    21. `propose`: Creates a new proposal (Creation, Sale, Burn, Parameter Update, Fund Distribution).
    22. `getProposalDetails`: Retrieves details of a proposal.
    23. `voteOnProposal`: Allows DAAFGov holders to vote on a proposal.
    24. `getVoteCount`: Gets current vote counts for a proposal.
    25. `checkProposalState`: Gets the current state (Pending, Active, Succeeded, Failed, Executed, Canceled) of a proposal.
    26. `cancelProposal`: Allows proposer or admin to cancel a proposal before active state.
*   **Proposal Execution:**
    27. `executeProposal`: Triggers the action of a succeeded proposal based on its type. This function contains the core logic for minting, transferring (sale/distribution), burning, or updating parameters.
*   **Vault Management:**
    28. `getVaultBalance`: Checks the amount of Ether held by the contract vault.
    29. `withdrawETH`: Allows withdrawal *only* via an executed FundDistribution proposal.
*   **Configuration (via Governance):**
    30. `proposeParameterUpdate`: Creates a proposal specifically to change a governance parameter.
    31. `updateVotingPeriod`: Internal, called by execution to change voting period.
    32. `updateProposalThreshold`: Internal, called by execution to change proposal token threshold.
    33. `updateQuorumThreshold`: Internal, called by execution to change quorum requirement.
    34. `updateExecutionDelay`: Internal, called by execution to change execution delay.
    35. `updateExecutionWindow`: Internal, called by execution to change execution window.
    36. `updateBaseTokenURI`: Internal, called by execution to change the base metadata URI.
*   **Helpers (Internal):**
    37. `_updateProposalState`: Internal helper to check and update proposal state based on time and votes.
    38. `_calculateVotingPower`: Internal helper to get voting power (balance) at a specific point (simplified to current balance for this example).
    39. `_mintGovTokensInternal`: Internal minting logic.
    40. `_transferGovTokensInternal`: Internal token transfer logic.
    41. `_transferArtNFTInternal`: Internal NFT transfer logic.
    42. `_safeMintArtNFTInternal`: Internal NFT minting logic ensuring safety checks (simplified).
    43. `_burnArtNFTInternal`: Internal NFT burning logic.

*(Note: This summary lists 43 functions, exceeding the requirement of 20, covering various aspects of the concept.)*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Decentralized Autonomous Art Foundry (DAAF)
 * @dev A smart contract enabling a community (via governance tokens) to propose, vote on,
 *      and manage the creation and lifecycle of unique digital art pieces (NFTs).
 *      Features include parameterized art generation proposals, dynamic NFT metadata,
 *      a governance vault for communal funds/assets, and a decentralized decision-making process.
 *      Avoids duplicating open-source libraries by implementing necessary logic internally.
 */

/**
 * @notice DAAF Outline:
 * 1. State Variables: Core contract state (tokens, NFTs, proposals, parameters, config).
 * 2. Events: Logs for transparency.
 * 3. Enums: Proposal states and types.
 * 4. Structs: Data structures for Art Parameters and Proposals.
 * 5. Simplified Governance Token (DAAFGov): Basic internal token logic.
 * 6. Simplified Art NFT (DAAFArt): Basic internal NFT logic with dynamic metadata.
 * 7. Art Parameters Management: Submit and retrieve potential art inputs.
 * 8. Proposal & Voting System: Create proposals, vote, check state, get details.
 * 9. Proposal Execution: Anyone can trigger execution of successful proposals.
 * 10. Art Management (Post-Minting): NFT transfers (vault), burning, dynamic updates via execution.
 * 11. Vault Management: Handling ETH from sales/distributions.
 * 12. Configuration & Admin: Constructor and governance-controlled parameter updates.
 * 13. Helpers: Internal utility functions.
 */

/**
 * @notice DAAF Function Summary:
 * Governance Token (Simplified):
 * 1. constructor(): Initializes contract, mints initial DAAFGov.
 * 2. mintGovTokens(address to, uint256 amount): Restricted minting.
 * 3. transferGovTokens(address to, uint256 amount): Internal DAAFGov transfer.
 * 4. balanceOfGovTokens(address account): Get DAAFGov balance.
 * 5. totalSupplyGovTokens(): Get total DAAFGov supply.
 * 6. approveGovTokens(address spender, uint256 amount): Set DAAFGov allowance.
 * 7. transferFromGovTokens(address from, address to, uint256 amount): Transfer DAAFGov using allowance.
 *
 * Art NFT (Simplified & Dynamic):
 * 8. mintArtNFT(address to, uint256 artParametersId): Internal NFT minting for executed proposals.
 * 9. transferArtNFT(address from, address to, uint256 tokenId): Internal NFT transfer.
 * 10. ownerOfArtNFT(uint256 tokenId): Get NFT owner.
 * 11. balanceOfArtNFTs(address owner): Get NFT count for owner.
 * 12. tokenURI(uint256 tokenId): Generates dynamic metadata URI.
 * 13. approveArtNFT(address to, uint256 tokenId): Set NFT approval.
 * 14. getApprovedArtNFT(uint256 tokenId): Get NFT approved address.
 * 15. setApprovalForAllArtNFT(address operator, bool approved): Set NFT operator approval.
 * 16. isApprovedForAllArtNFT(address owner, address operator): Check NFT operator approval.
 * 17. updateDynamicArtParameter(uint256 tokenId, string memory key, string memory value): Update NFT dynamic data (via execution).
 * 18. getDynamicArtParameter(uint256 tokenId, string memory key): Get NFT dynamic data point.
 *
 * Art Parameters:
 * 19. submitArtParameters(string memory name, string memory description, string memory parameterData): Submit potential art parameters.
 * 20. getArtParameters(uint256 parametersId): Retrieve submitted parameters.
 *
 * Proposals & Voting:
 * 21. propose(ProposalType proposalType, uint256 relatedId, uint256 amount, address targetAddress, string memory description, string memory key, string memory value): Create a proposal.
 * 22. getProposalDetails(uint256 proposalId): Get proposal details.
 * 23. voteOnProposal(uint256 proposalId, bool support): Cast vote (weighted by DAAFGov).
 * 24. getVoteCount(uint256 proposalId): Get current vote results.
 * 25. checkProposalState(uint256 proposalId): Get proposal state.
 * 26. cancelProposal(uint256 proposalId): Cancel a proposal.
 *
 * Proposal Execution:
 * 27. executeProposal(uint256 proposalId): Execute a succeeded proposal.
 *
 * Vault Management:
 * 28. getVaultBalance(): Check contract ETH balance.
 * 29. withdrawETH(): Withdrawal *only* via executed FundDistribution proposal.
 *
 * Configuration (via Governance):
 * 30. proposeParameterUpdate(ParameterType paramType, uint256 newValue): Create proposal to change governance param.
 * 31. updateVotingPeriod(uint256 newVotingPeriod): Internal, via execution.
 * 32. updateProposalThreshold(uint256 newThreshold): Internal, via execution.
 * 33. updateQuorumThreshold(uint256 newQuorum): Internal, via execution.
 * 34. updateExecutionDelay(uint256 newDelay): Internal, via execution.
 * 35. updateExecutionWindow(uint256 newWindow): Internal, via execution.
 * 36. updateBaseTokenURI(string memory newBaseURI): Internal, via execution.
 *
 * Helpers (Internal):
 * 37. _updateProposalState(uint256 proposalId): Update proposal state based on time/votes.
 * 38. _calculateVotingPower(address account): Get current DAAFGov balance for voting.
 * 39. _mintGovTokensInternal(address to, uint256 amount): Internal DAAFGov mint logic.
 * 40. _transferGovTokensInternal(address from, address to, uint256 amount): Internal DAAFGov transfer logic.
 * 41. _transferArtNFTInternal(address from, address to, uint256 tokenId): Internal NFT transfer logic.
 * 42. _safeMintArtNFTInternal(address to, uint256 tokenId): Internal NFT mint logic.
 * 43. _burnArtNFTInternal(uint256 tokenId): Internal NFT burn logic.
 */

contract DecentralizedAutonomousArtFoundry {

    // --- State Variables ---

    // Governance Token (Simplified DAAFGov)
    string public govTokenName;
    string public govTokenSymbol;
    uint256 private _govTokenSupply;
    mapping(address => uint256) private _govTokenBalances;
    mapping(address => mapping(address => uint256)) private _govTokenAllowances;

    // Art NFT (Simplified DAAFArt)
    string public artTokenName;
    string public artTokenSymbol;
    uint256 private _nextTokenId;
    mapping(uint256 => address) private _artTokenOwners;
    mapping(address => uint256) private _artTokenBalances;
    mapping(uint256 => address) private _artTokenApprovals;
    mapping(address => mapping(address => bool)) private _artOperatorApprovals;
    mapping(uint256 => mapping(string => string)) private _artDynamicParameters; // For dynamic metadata
    string private _baseTokenURI;

    // Art Parameters Storage
    uint256 private _nextParametersId;
    struct ArtParameters {
        string name;
        string description;
        string parameterData; // e.g., JSON string describing generative rules, colors, inputs
        address submitter;
        bool exists; // To check if an ID is valid
    }
    mapping(uint256 => ArtParameters) private _artParameters;

    // Proposal System
    uint256 private _nextProposalId;
    struct Proposal {
        ProposalType proposalType;
        address proposer;
        string description;
        uint256 creationTime;
        uint256 votingEndTime;
        uint256 executionStartTime; // Time after voting ends, before execution window closes
        uint256 executionEndTime;
        uint256 votesFor; // Weighted by governance token balance
        uint256 votesAgainst; // Weighted by governance token balance
        uint256 totalVotingPower; // Total power that voted
        ProposalState state;

        // Proposal Data (related to ProposalType)
        uint256 relatedId;     // Used for parametersId (Creation), tokenId (Sale, Burn, Dynamic)
        uint224 amount;        // Used for price (Sale), amount (FundDistribution) - uint224 to save space
        address targetAddress; // Used for recipient (FundDistribution, potential transfer)
        string key;            // Used for dynamic parameter key
        string value;          // Used for dynamic parameter value
        uint256 newValue;      // Used for parameter update proposals
        ParameterType paramType; // Used for parameter update proposals
    }
    mapping(uint256 => Proposal) private _proposals;
    mapping(uint256 => mapping(address => bool)) private _hasVoted; // Prevent double voting

    // Governance Parameters
    uint256 public votingPeriod = 3 days;        // Duration of voting phase
    uint256 public proposalThreshold = 100;      // Minimum DAAFGov tokens to create a proposal (simplified, could be percentage)
    uint256 public quorumThreshold = 1000;       // Minimum total voting power required for a proposal to pass
    uint256 public executionDelay = 1 day;       // Time between voting end and execution window start
    uint256 public executionWindow = 2 days;     // Time window during which a successful proposal can be executed

    // Admin/Owner (Could be DAO-governed eventually, but start with a simple owner)
    address private _owner;

    // --- Enums ---

    enum ProposalState {
        Pending,    // Created, waiting for active period or start trigger
        Active,     // Open for voting
        Succeeded,  // Voting ended, threshold and quorum met
        Failed,     // Voting ended, did not meet threshold or quorum
        Executed,   // Succeeded and executeProposal called
        Canceled    // Cancelled before voting ended
    }

    enum ProposalType {
        CreateArtNFT,
        SellArtNFT,
        BurnArtNFT,
        UpdateDynamicArtParameter,
        FundDistribution,
        UpdateGovernanceParameter // Special type for changing governance params
    }

    enum ParameterType {
        VotingPeriod,
        ProposalThreshold,
        QuorumThreshold,
        ExecutionDelay,
        ExecutionWindow,
        BaseTokenURI // Changing the base metadata URI
    }

    // --- Events ---

    event GovTokensMinted(address indexed to, uint256 amount);
    event GovTokensTransfer(address indexed from, address indexed to, uint256 amount);
    event GovTokensApproval(address indexed owner, address indexed spender, uint256 amount);

    event ArtNFTMinted(address indexed to, uint256 indexed tokenId, uint256 artParametersId);
    event ArtNFTTransfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event ArtNFTApproval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAllArtNFT(address indexed owner, address indexed operator, bool approved);
    event DynamicArtParameterUpdated(uint256 indexed tokenId, string key, string value);

    event ArtParametersSubmitted(uint256 indexed parametersId, address indexed submitter, string name);

    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, ProposalType proposalType, string description, uint256 creationTime);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 votes);
    event ProposalStateChanged(uint256 indexed proposalId, ProposalState newState);
    event ProposalExecuted(uint256 indexed proposalId, ProposalType proposalType);
    event ProposalCanceled(uint256 indexed proposalId);

    event VaultFundsDistributed(uint256 indexed proposalId, address indexed recipient, uint256 amount);
    event GovernanceParameterUpdated(uint256 indexed proposalId, ParameterType paramType, uint256 newValue);
     event BaseTokenURIUpdated(uint256 indexed proposalId, string newBaseURI);


    // --- Constructor ---

    constructor(address initialOwner, uint256 initialGovSupply, string memory _govName, string memory _govSymbol, string memory _artName, string memory _artSymbol) {
        require(initialOwner != address(0), "Initial owner cannot be zero address");
        _owner = initialOwner;

        govTokenName = _govName;
        govTokenSymbol = _govSymbol;
        _mintGovTokensInternal(initialOwner, initialGovSupply); // Mint initial supply to owner

        artTokenName = _artName;
        artTokenSymbol = _artSymbol;
        _nextTokenId = 1; // Token IDs start from 1

        _nextParametersId = 1; // Parameters IDs start from 1
        _nextProposalId = 1; // Proposal IDs start from 1

        // Receive ETH into the contract - makes it payable
        // No specific receive() or fallback() needed if only expecting ETH on calls like executeProposal (for sale).
    }

    // Function to receive Ether - Explicitly needed if users send ETH directly
    receive() external payable {}
    fallback() external payable {}


    // --- Simplified Governance Token (DAAFGov) Functions ---

    /**
     * @notice Internal function to mint governance tokens. Restricted.
     * @param to The address to mint tokens to.
     * @param amount The amount of tokens to mint.
     */
    function mintGovTokens(address to, uint256 amount) public onlyOwner {
        _mintGovTokensInternal(to, amount);
    }

    /**
     * @notice Transfers DAAFGov tokens. Basic internal transfer logic.
     * @param to The recipient address.
     * @param amount The amount to transfer.
     * @return bool Success status.
     */
    function transferGovTokens(address from, address to, uint256 amount) external returns (bool) {
         // Basic check - typically called from external caller or approved address
         require(from == msg.sender || _govTokenAllowances[from][msg.sender] >= amount, "DAAFGov: Transfer caller is not owner or approved");
         _transferGovTokensInternal(from, to, amount);
         if(from != msg.sender) { // If using allowance, reduce it
             _govTokenAllowances[from][msg.sender] -= amount;
         }
         return true;
    }

    /**
     * @notice Gets the DAAFGov token balance of an account.
     * @param account The address to query.
     * @return uint256 The balance.
     */
    function balanceOfGovTokens(address account) public view returns (uint256) {
        return _govTokenBalances[account];
    }

    /**
     * @notice Gets the total supply of DAAFGov tokens.
     * @return uint256 The total supply.
     */
    function totalSupplyGovTokens() public view returns (uint256) {
        return _govTokenSupply;
    }

     /**
      * @notice Sets the allowance for spending DAAFGov tokens.
      * @param spender The address allowed to spend.
      * @param amount The maximum amount allowed.
      * @return bool Success status.
      */
     function approveGovTokens(address spender, uint256 amount) public returns (bool) {
         _govTokenAllowances[msg.sender][spender] = amount;
         emit GovTokensApproval(msg.sender, spender, amount);
         return true;
     }

     /**
      * @notice Transfers DAAFGov tokens from one address to another using allowance.
      * @param from The address to transfer from.
      * @param to The address to transfer to.
      * @param amount The amount to transfer.
      * @return bool Success status.
      */
     function transferFromGovTokens(address from, address to, uint256 amount) public returns (bool) {
         require(_govTokenAllowances[from][msg.sender] >= amount, "DAAFGov: Transfer amount exceeds allowance");
         _transferGovTokensInternal(from, to, amount);
         _govTokenAllowances[from][msg.sender] -= amount;
         return true;
     }


    // --- Simplified Art NFT (DAAFArt) Functions ---

    /**
     * @notice Internal function to mint a new DAAFArt NFT. Restricted to proposal execution.
     * @param to The address to mint the NFT to.
     * @param artParametersId The ID of the art parameters used for creation.
     */
    function mintArtNFT(address to, uint256 artParametersId) internal returns (uint256) {
        uint256 newTokenId = _nextTokenId++;
        _safeMintArtNFTInternal(to, newTokenId);
        // Associate parametersId with the newly minted token
        _artDynamicParameters[newTokenId]["parametersId"] = uint256ToString(artParametersId);
        emit ArtNFTMinted(to, newTokenId, artParametersId);
        return newTokenId;
    }

    /**
     * @notice Transfers a DAAFArt NFT. Basic internal transfer logic, respects approvals.
     * @param from The current owner address.
     * @param to The recipient address.
     * @param tokenId The ID of the token to transfer.
     */
    function transferArtNFT(address from, address to, uint256 tokenId) public {
         require(ownerOfArtNFT(tokenId) == from, "DAAFArt: Caller is not owner");
         require(to != address(0), "DAAFArt: transfer to the zero address");

         // Check approval: msg.sender is owner OR msg.sender is approved for token OR msg.sender is operator for owner
         require(from == msg.sender ||
                 getApprovedArtNFT(tokenId) == msg.sender ||
                 isApprovedForAllArtNFT(from, msg.sender),
                 "DAAFArt: Transfer caller is not owner nor approved nor operator");

         _transferArtNFTInternal(from, to, tokenId);
    }

    /**
     * @notice Gets the owner of a specific DAAFArt NFT.
     * @param tokenId The ID of the token.
     * @return address The owner address.
     */
    function ownerOfArtNFT(uint256 tokenId) public view returns (address) {
        address owner = _artTokenOwners[tokenId];
        require(owner != address(0), "DAAFArt: owner query for nonexistent token");
        return owner;
    }

    /**
     * @notice Gets the number of DAAFArt NFTs owned by an address.
     * @param owner The address to query.
     * @return uint256 The count of owned NFTs.
     */
    function balanceOfArtNFTs(address owner) public view returns (uint256) {
        require(owner != address(0), "DAAFArt: balance query for zero address");
        return _artTokenBalances[owner];
    }

    /**
     * @notice Generates the dynamic metadata URI for a DAAFArt NFT.
     * @dev This function is crucial for dynamic NFTs. It builds a URI often pointing to an off-chain renderer
     *      that takes the token ID and potentially dynamic parameters to generate metadata/image.
     * @param tokenId The ID of the token.
     * @return string The metadata URI.
     */
    function tokenURI(uint256 tokenId) public view returns (string memory) {
         require(_artTokenOwners[tokenId] != address(0), "DAAFArt: URI query for nonexistent token");
         // Example: Build a URI like "baseURI/metadata/tokenId?param1=value1&param2=value2..."
         // This requires an off-chain service at baseURI that can read the dynamic parameters for the token ID.
         string memory dynamicParams = "";
         // Iterating through a mapping is not directly possible in Solidity.
         // A common pattern is to store keys in an array or use a library for iteration.
         // For simplicity here, we'll just include the token ID and maybe the original parametersId.
         // A more complex implementation would require tracking parameter keys.

         string memory idString = uint256ToString(tokenId);
         string memory paramsIdString = _artDynamicParameters[tokenId]["parametersId"];

         // A simple example constructing the URI: baseURI/tokenId?paramsId=...
         // In a real dynamic NFT, you'd encode all dynamic parameters here or have the renderer fetch them.
         string memory uri;
         if (bytes(_baseTokenURI).length > 0) {
             uri = string(abi.encodePacked(_baseTokenURI, idString));
             if (bytes(paramsIdString).length > 0) {
                 uri = string(abi.encodePacked(uri, "?parametersId=", paramsIdString));
             }
             // Add other dynamic parameters if tracked keys were available
         } else {
             uri = string(abi.encodePacked("ipfs://", idString)); // Fallback or default
         }
         return uri;
    }

     /**
      * @notice Sets the approved address for a single DAAFArt NFT.
      * @param to The address to be approved, or address(0) to clear approval.
      * @param tokenId The token ID.
      */
     function approveArtNFT(address to, uint256 tokenId) public {
         address owner = ownerOfArtNFT(tokenId); // Checks existence
         require(msg.sender == owner || isApprovedForAllArtNFT(owner, msg.sender), "DAAFArt: Approve caller is not owner nor approved for all");
         _artTokenApprovals[tokenId] = to;
         emit ArtNFTApproval(owner, to, tokenId);
     }

     /**
      * @notice Gets the approved address for a single DAAFArt NFT.
      * @param tokenId The token ID.
      * @return address The approved address.
      */
     function getApprovedArtNFT(uint256 tokenId) public view returns (address) {
         require(_artTokenOwners[tokenId] != address(0), "DAAFArt: approved query for nonexistent token");
         return _artTokenApprovals[tokenId];
     }

     /**
      * @notice Sets the operator status for an address, allowing it to manage all of msg.sender's NFTs.
      * @param operator The address to set as operator.
      * @param approved Whether to enable or disable operator status.
      */
     function setApprovalForAllArtNFT(address operator, bool approved) public {
         require(operator != msg.sender, "DAAFArt: Approve for all to caller");
         _artOperatorApprovals[msg.sender][operator] = approved;
         emit ApprovalForAllArtNFT(msg.sender, operator, approved);
     }

     /**
      * @notice Checks if an address is an operator for another address.
      * @param owner The owner of the NFTs.
      * @param operator The potential operator.
      * @return bool True if the operator is approved for all of the owner's NFTs.
      */
     function isApprovedForAllArtNFT(address owner, address operator) public view returns (bool) {
         return _artOperatorApprovals[owner][operator];
     }

     /**
      * @notice Updates a specific dynamic parameter for a DAAFArt NFT.
      * @dev This function should ONLY be called via a successful proposal execution.
      * @param tokenId The ID of the NFT to update.
      * @param key The key of the parameter (e.g., "color", "shape", "status").
      * @param value The new value for the parameter.
      */
     function updateDynamicArtParameter(uint256 tokenId, string memory key, string memory value) external onlyExecuteProposal {
         require(_artTokenOwners[tokenId] != address(0), "DAAFArt: Cannot update nonexistent token");
         _artDynamicParameters[tokenId][key] = value;
         emit DynamicArtParameterUpdated(tokenId, key, value);
     }

     /**
      * @notice Retrieves a specific dynamic parameter for a DAAFArt NFT.
      * @param tokenId The ID of the NFT.
      * @param key The key of the parameter.
      * @return string The value of the parameter.
      */
     function getDynamicArtParameter(uint256 tokenId, string memory key) public view returns (string memory) {
         require(_artTokenOwners[tokenId] != address(0), "DAAFArt: Cannot get parameter for nonexistent token");
         return _artDynamicParameters[tokenId][key];
     }


    // --- Art Parameters Management Functions ---

    /**
     * @notice Allows anyone to submit a set of parameters for a potential future art piece.
     * @param name Name of the art concept.
     * @param description Description of the concept.
     * @param parameterData String (e.g., JSON) containing specific data for the art generation.
     * @return uint256 The ID of the newly submitted art parameters.
     */
    function submitArtParameters(string memory name, string memory description, string memory parameterData) public returns (uint256) {
        uint256 newParametersId = _nextParametersId++;
        _artParameters[newParametersId] = ArtParameters(name, description, parameterData, msg.sender, true);
        emit ArtParametersSubmitted(newParametersId, msg.sender, name);
        return newParametersId;
    }

    /**
     * @notice Retrieves details of a submitted art parameters set.
     * @param parametersId The ID of the parameters to retrieve.
     * @return ArtParameters The struct containing the parameter details.
     */
    function getArtParameters(uint256 parametersId) public view returns (ArtParameters memory) {
        require(_artParameters[parametersId].exists, "DAAF: Art parameters not found");
        return _artParameters[parametersId];
    }

     /**
      * @notice Gets the total count of submitted art parameter sets.
      * @return uint256 The total count.
      */
     function getArtParameterCount() public view returns (uint256) {
         return _nextParametersId - 1; // Subtract 1 because ID starts at 1
     }


    // --- Proposal & Voting System Functions ---

    /**
     * @notice Creates a new proposal. Requires proposer to hold minimum governance tokens.
     * @param proposalType The type of the proposal (Creation, Sale, Burn, etc.).
     * @param relatedId Used for parametersId (Creation), tokenId (Sale, Burn, Dynamic).
     * @param amount Used for price (Sale), amount (FundDistribution).
     * @param targetAddress Used for recipient (FundDistribution, potential transfer target).
     * @param description Description of the proposal.
     * @param key Used for dynamic parameter key.
     * @param value Used for dynamic parameter value.
     * @param newValue Used for governance parameter update.
     * @param paramType Used for governance parameter update type.
     * @return uint256 The ID of the newly created proposal.
     */
    function propose(
        ProposalType proposalType,
        uint256 relatedId,
        uint224 amount,
        address targetAddress,
        string memory description,
        string memory key, // For UpdateDynamicArtParameter
        string memory value, // For UpdateDynamicArtParameter
        uint256 newValue, // For UpdateGovernanceParameter
        ParameterType paramType // For UpdateGovernanceParameter
    ) public returns (uint256) {
        require(_govTokenBalances[msg.sender] >= proposalThreshold, "DAAF: Proposer balance below threshold");

        // Basic validation based on proposal type
        if (proposalType == ProposalType.CreateArtNFT) {
            require(_artParameters[relatedId].exists, "DAAF: Art parameters ID not found for creation proposal");
             require(amount == 0 && targetAddress == address(0) && bytes(key).length == 0 && bytes(value).length == 0 && newValue == 0, "DAAF: Invalid fields for CreateArtNFT proposal");
        } else if (proposalType == ProposalType.SellArtNFT) {
            require(ownerOfArtNFT(relatedId) == address(this), "DAAF: Contract does not own NFT for sale proposal");
            require(amount > 0, "DAAF: Sale proposal requires amount (price)");
            require(targetAddress == address(0) && bytes(key).length == 0 && bytes(value).length == 0 && newValue == 0, "DAAF: Invalid fields for SellArtNFT proposal");
        } else if (proposalType == ProposalType.BurnArtNFT) {
             require(ownerOfArtNFT(relatedId) == address(this), "DAAF: Contract does not own NFT for burn proposal");
             require(amount == 0 && targetAddress == address(0) && bytes(key).length == 0 && bytes(value).length == 0 && newValue == 0, "DAAF: Invalid fields for BurnArtNFT proposal");
        } else if (proposalType == ProposalType.UpdateDynamicArtParameter) {
             require(_artTokenOwners[relatedId] != address(0), "DAAF: NFT ID not found for dynamic update proposal");
             require(bytes(key).length > 0, "DAAF: Dynamic update proposal requires key");
             // Value can be empty string to clear a parameter
             require(amount == 0 && targetAddress == address(0) && newValue == 0, "DAAF: Invalid fields for UpdateDynamicArtParameter proposal");
        } else if (proposalType == ProposalType.FundDistribution) {
             require(targetAddress != address(0), "DAAF: Fund distribution requires recipient");
             require(amount > 0, "DAAF: Fund distribution requires amount"); // Amount is ETH in wei
             require(relatedId == 0 && bytes(key).length == 0 && bytes(value).length == 0 && newValue == 0, "DAAF: Invalid fields for FundDistribution proposal");
        } else if (proposalType == ProposalType.UpdateGovernanceParameter) {
             require(newValue > 0 || paramType == ParameterType.BaseTokenURI, "DAAF: Governance parameter update requires newValue (or BaseTokenURI type)");
             require(relatedId == 0 && amount == 0 && targetAddress == address(0) && bytes(key).length == 0 && bytes(value).length == 0, "DAAF: Invalid fields for UpdateGovernanceParameter proposal");
        } else {
            revert("DAAF: Invalid proposal type");
        }

        uint256 newProposalId = _nextProposalId++;
        uint256 currentTime = block.timestamp;

        _proposals[newProposalId] = Proposal({
            proposalType: proposalType,
            proposer: msg.sender,
            description: description,
            creationTime: currentTime,
            votingEndTime: currentTime + votingPeriod,
            executionStartTime: currentTime + votingPeriod + executionDelay,
            executionEndTime: currentTime + votingPeriod + executionDelay + executionWindow,
            votesFor: 0,
            votesAgainst: 0,
            totalVotingPower: 0,
            state: ProposalState.Active, // Proposals start directly in Active state
            relatedId: relatedId,
            amount: amount,
            targetAddress: targetAddress,
            key: key,
            value: value,
            newValue: newValue,
            paramType: paramType
        });

        emit ProposalCreated(newProposalId, msg.sender, proposalType, description, currentTime);
        // Immediately emit state change as it starts Active
        emit ProposalStateChanged(newProposalId, ProposalState.Active);

        return newProposalId;
    }

     /**
      * @notice Retrieves details of a proposal.
      * @param proposalId The ID of the proposal.
      * @return Proposal The struct containing proposal details.
      */
    function getProposalDetails(uint256 proposalId) public view returns (Proposal memory) {
        require(_proposals[proposalId].creationTime > 0, "DAAF: Proposal not found"); // Use creationTime > 0 as existence check
        return _proposals[proposalId];
    }

    /**
     * @notice Allows a DAAFGov token holder to cast a vote on a proposal.
     * @param proposalId The ID of the proposal to vote on.
     * @param support True for supporting the proposal, false for opposing.
     */
    function voteOnProposal(uint256 proposalId, bool support) public {
        Proposal storage proposal = _proposals[proposalId];
        require(proposal.creationTime > 0, "DAAF: Proposal not found"); // Existence check
        _updateProposalState(proposalId); // Update state based on time
        require(proposal.state == ProposalState.Active, "DAAF: Proposal not in Active state");
        require(!_hasVoted[proposalId][msg.sender], "DAAF: Already voted on this proposal");

        uint256 votingPower = _calculateVotingPower(msg.sender);
        require(votingPower > 0, "DAAF: Voter has no voting power (0 DAAFGov balance)");

        _hasVoted[proposalId][msg.sender] = true;
        proposal.totalVotingPower += votingPower;

        if (support) {
            proposal.votesFor += votingPower;
        } else {
            proposal.votesAgainst += votingPower;
        }

        emit VoteCast(proposalId, msg.sender, support, votingPower);
    }

     /**
      * @notice Gets the current vote counts for a proposal.
      * @param proposalId The ID of the proposal.
      * @return votesFor The total votes in support.
      * @return votesAgainst The total votes against.
      * @return totalVotingPower The total voting power that participated.
      */
     function getVoteCount(uint256 proposalId) public view returns (uint256 votesFor, uint256 votesAgainst, uint256 totalVotingPower) {
         require(_proposals[proposalId].creationTime > 0, "DAAF: Proposal not found");
         return (_proposals[proposalId].votesFor, _proposals[proposalId].votesAgainst, _proposals[proposalId].totalVotingPower);
     }


    /**
     * @notice Checks the current state of a proposal, updating it if necessary based on time.
     * @param proposalId The ID of the proposal.
     * @return ProposalState The current state.
     */
    function checkProposalState(uint256 proposalId) public returns (ProposalState) {
        require(_proposals[proposalId].creationTime > 0, "DAAF: Proposal not found");
        _updateProposalState(proposalId); // Ensure state is up-to-date
        return _proposals[proposalId].state;
    }

     /**
      * @notice Allows the proposer or owner to cancel a proposal before it becomes non-Pending/Active.
      * @param proposalId The ID of the proposal.
      */
     function cancelProposal(uint256 proposalId) public {
         Proposal storage proposal = _proposals[proposalId];
         require(proposal.creationTime > 0, "DAAF: Proposal not found");
         require(proposal.proposer == msg.sender || _owner == msg.sender, "DAAF: Only proposer or owner can cancel");
         // Can only cancel if not already decided (Succeeded/Failed/Executed)
         require(proposal.state == ProposalState.Pending || proposal.state == ProposalState.Active, "DAAF: Proposal cannot be canceled in current state");

         proposal.state = ProposalState.Canceled;
         emit ProposalStateChanged(proposalId, ProposalState.Canceled);
         emit ProposalCanceled(proposalId);
     }


    // --- Proposal Execution Functions ---

    /**
     * @notice Executes a proposal that has succeeded and is within the execution window.
     * @dev Anyone can call this function to trigger the action once conditions are met.
     * @param proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 proposalId) public payable {
        Proposal storage proposal = _proposals[proposalId];
        require(proposal.creationTime > 0, "DAAF: Proposal not found"); // Existence check

        _updateProposalState(proposalId); // Ensure state is up-to-date

        require(proposal.state == ProposalState.Succeeded, "DAAF: Proposal not in Succeeded state");
        require(block.timestamp >= proposal.executionStartTime, "DAAF: Execution window not yet open");
        require(block.timestamp <= proposal.executionEndTime, "DAAF: Execution window has closed");

        proposal.state = ProposalState.Executed; // Mark as executed *before* potential reentrant calls (unlikely here, but good practice)

        // --- Execute based on Proposal Type ---
        if (proposal.proposalType == ProposalType.CreateArtNFT) {
            // Mint a new NFT based on the approved parameters
            uint256 newTokenId = mintArtNFT(address(this), proposal.relatedId); // Mint to the contract vault initially
            // Potentially set initial dynamic parameters here based on the artParameters data
            // Or the tokenURI service reads the original parametersId to generate initial metadata
             // Link the new token ID back to the proposal in dynamic parameters
             updateDynamicArtParameter(newTokenId, "creationProposalId", uint256ToString(proposalId));

        } else if (proposal.proposalType == ProposalType.SellArtNFT) {
            // Sell the NFT owned by the contract
            uint256 tokenId = proposal.relatedId;
            address payable buyer = payable(msg.sender); // Assume the caller is the buyer sending ETH
            uint256 price = proposal.amount; // Price is in Wei

            require(ownerOfArtNFT(tokenId) == address(this), "DAAF: Contract does not own NFT for execution");
            require(msg.value >= price, "DAAF: Not enough ETH sent for NFT sale");

            // Transfer NFT from contract vault to the buyer
            _transferArtNFTInternal(address(this), buyer, tokenId); // Internal transfer logic handles clearing approvals etc.

            // Transfer excess ETH back to buyer
            if (msg.value > price) {
                (bool success, ) = payable(msg.sender).call{value: msg.value - price}("");
                require(success, "DAAF: Failed to return excess ETH");
            }

            // The 'price' amount stays in the contract vault
            // Distribution of sale funds happens via a separate FundDistribution proposal

        } else if (proposal.proposalType == ProposalType.BurnArtNFT) {
            // Burn an NFT owned by the contract
            uint256 tokenId = proposal.relatedId;
            require(ownerOfArtNFT(tokenId) == address(this), "DAAF: Contract does not own NFT for burn execution");
            _burnArtNFTInternal(tokenId); // Internal burn logic

        } else if (proposal.proposalType == ProposalType.UpdateDynamicArtParameter) {
            // Update a dynamic parameter for an NFT
            uint256 tokenId = proposal.relatedId;
             // Check ownership implicitly handled by updateDynamicArtParameter's internal check
             updateDynamicArtParameter(tokenId, proposal.key, proposal.value);

        } else if (proposal.proposalType == ProposalType.FundDistribution) {
            // Distribute ETH from the contract vault
            address payable recipient = payable(proposal.targetAddress);
            uint256 amountToDistribute = proposal.amount; // Amount is in Wei

            require(address(this).balance >= amountToDistribute, "DAAF: Insufficient vault balance for distribution");

            (bool success, ) = recipient.call{value: amountToDistribute}("");
            require(success, "DAAF: Failed to send ETH distribution");

            emit VaultFundsDistributed(proposalId, recipient, amountToDistribute);

        } else if (proposal.proposalType == ProposalType.UpdateGovernanceParameter) {
             // Update a governance configuration parameter
             if (proposal.paramType == ParameterType.VotingPeriod) {
                 updateVotingPeriod(proposal.newValue);
             } else if (proposal.paramType == ParameterType.ProposalThreshold) {
                 updateProposalThreshold(proposal.newValue);
             } else if (proposal.paramType == ParameterType.QuorumThreshold) {
                 updateQuorumThreshold(proposal.newValue);
             } else if (proposal.paramType == ParameterType.ExecutionDelay) {
                 updateExecutionDelay(proposal.newValue);
             } else if (proposal.paramType == ParameterType.ExecutionWindow) {
                 updateExecutionWindow(proposal.newValue);
             } else if (proposal.paramType == ParameterType.BaseTokenURI) {
                  // BaseTokenURI update uses 'value' field from proposal struct, not 'newValue'
                 updateBaseTokenURI(proposal.value);
             } else {
                 revert("DAAF: Unknown parameter type for update");
             }
             emit GovernanceParameterUpdated(proposalId, proposal.paramType, proposal.newValue);
             if (proposal.paramType == ParameterType.BaseTokenURI) {
                  // Specific event for base URI as newValue is 0
                 emit BaseTokenURIUpdated(proposalId, proposal.value);
             }
        } else {
            revert("DAAF: Unknown proposal type for execution");
        }

        emit ProposalExecuted(proposalId, proposal.proposalType);
    }

    // --- Vault Management Functions ---

     /**
      * @notice Gets the current Ether balance held by the contract (the vault).
      * @return uint256 The balance in Wei.
      */
     function getVaultBalance() public view returns (uint256) {
         return address(this).balance;
     }

     /**
      * @notice Placeholder function for withdrawing ETH. It should ONLY be callable internally by `executeProposal`
      *         when handling a `FundDistribution` proposal type. This prevents unauthorized withdrawals.
      *         The actual transfer logic is within `executeProposal`.
      * @dev This function exists mainly for clarity in the function summary. It should not be callable externally.
      */
     function withdrawETH() external {
         revert("DAAF: ETH withdrawal is only possible via a successful FundDistribution proposal execution.");
     }


    // --- Configuration (via Governance) Functions ---

     /**
      * @notice Creates a proposal to update a governance parameter.
      * @param paramType The type of parameter to update.
      * @param newValue The new value for the parameter. For BaseTokenURI, use propose with value field instead.
      * @dev This is a specific proposal type handled by the `propose` function. This wrapper simplifies calling.
      */
     function proposeParameterUpdate(ParameterType paramType, uint256 newValue) public returns (uint256) {
          string memory description = string(abi.encodePacked("Update Governance Parameter: ", uint256(paramType), " to ", newValue));
          // Call the generic propose function
          return propose(
              ProposalType.UpdateGovernanceParameter,
              0,       // relatedId not used
              0,       // amount not used
              address(0), // targetAddress not used
              description,
              "",      // key not used
              "",      // value not used (unless paramType is BaseTokenURI - needs separate handling or overload/union)
              newValue,
              paramType
          );
     }

      /**
       * @notice Internal function to update the voting period. Callable only by proposal execution.
       * @param newVotingPeriod The new duration in seconds.
       */
      function updateVotingPeriod(uint256 newVotingPeriod) internal onlyExecuteProposal {
          votingPeriod = newVotingPeriod;
      }

      /**
       * @notice Internal function to update the proposal threshold. Callable only by proposal execution.
       * @param newThreshold The new minimum token balance to propose.
       */
      function updateProposalThreshold(uint256 newThreshold) internal onlyExecuteProposal {
          proposalThreshold = newThreshold;
      }

       /**
        * @notice Internal function to update the quorum threshold. Callable only by proposal execution.
        * @param newQuorum The new minimum total voting power required to pass.
        */
       function updateQuorumThreshold(uint256 newQuorum) internal onlyExecuteProposal {
           quorumThreshold = newQuorum;
       }

        /**
         * @notice Internal function to update the execution delay. Callable only by proposal execution.
         * @param newDelay The new delay in seconds after voting ends.
         */
        function updateExecutionDelay(uint256 newDelay) internal onlyExecuteProposal {
            executionDelay = newDelay;
        }

         /**
          * @notice Internal function to update the execution window duration. Callable only by proposal execution.
          * @param newWindow The new duration of the execution window in seconds.
          */
         function updateExecutionWindow(uint256 newWindow) internal onlyExecuteProposal {
             executionWindow = newWindow;
         }

         /**
          * @notice Internal function to update the base token URI. Callable only by proposal execution.
          * @param newBaseURI The new base URI string.
          */
         function updateBaseTokenURI(string memory newBaseURI) internal onlyExecuteProposal {
             _baseTokenURI = newBaseURI;
         }


    // --- Internal Helper Functions ---

    /**
     * @dev Internal function to update a proposal's state based on time and vote results.
     * @param proposalId The ID of the proposal.
     */
    function _updateProposalState(uint256 proposalId) internal {
        Proposal storage proposal = _proposals[proposalId];
        if (proposal.state != ProposalState.Active || block.timestamp < proposal.votingEndTime) {
            // State is not Active or voting period is not over
            return;
        }

        // Voting period has ended, determine outcome
        uint256 votesFor = proposal.votesFor;
        uint256 votesAgainst = proposal.votesAgainst;
        uint256 totalVoted = proposal.totalVotingPower;

        ProposalState oldState = proposal.state;

        if (totalVoted < quorumThreshold || votesFor <= votesAgainst) {
            proposal.state = ProposalState.Failed;
        } else {
            proposal.state = ProposalState.Succeeded;
        }

        if (oldState != proposal.state) {
            emit ProposalStateChanged(proposalId, proposal.state);
        }
    }

    /**
     * @dev Internal function to calculate voting power for an account.
     *      Simplified: current balance of DAAFGov tokens.
     *      Could be extended to use checkpoints for balance at proposal creation.
     * @param account The address to calculate power for.
     * @return uint256 The voting power (DAAFGov balance).
     */
    function _calculateVotingPower(address account) internal view returns (uint256) {
        // Simplistic model: power is current balance.
        // More robust DAOs use snapshotting (checkpoints) at proposal creation time.
        return _govTokenBalances[account];
    }

     /**
      * @dev Internal DAAFGov minting logic.
      */
     function _mintGovTokensInternal(address to, uint256 amount) internal {
         require(to != address(0), "DAAFGov: mint to the zero address");
         _govTokenSupply += amount;
         _govTokenBalances[to] += amount;
         emit GovTokensMinted(to, amount);
     }

     /**
      * @dev Internal DAAFGov transfer logic.
      */
     function _transferGovTokensInternal(address from, address to, uint256 amount) internal {
         require(from != address(0), "DAAFGov: transfer from the zero address");
         require(to != address(0), "DAAFGov: transfer to the zero address");
         require(_govTokenBalances[from] >= amount, "DAAFGov: transfer amount exceeds balance");

         _govTokenBalances[from] -= amount;
         _govTokenBalances[to] += amount;
         emit GovTokensTransfer(from, to, amount);
     }


    /**
     * @dev Internal DAAFArt NFT transfer logic. Handles ownership changes and clearing approvals.
     */
    function _transferArtNFTInternal(address from, address to, uint256 tokenId) internal {
        require(ownerOfArtNFT(tokenId) == from, "DAAFArt: transfer from incorrect owner"); // Redundant with external checks, but good internal safety
        require(to != address(0), "DAAFArt: transfer to the zero address");

        // Clear approvals from the previous owner
        _clearApproval(tokenId);

        _artTokenBalances[from] -= 1;
        _artTokenBalances[to] += 1;
        _artTokenOwners[tokenId] = to;

        emit ArtNFTTransfer(from, to, tokenId);
    }

    /**
     * @dev Internal DAAFArt NFT minting logic.
     */
    function _safeMintArtNFTInternal(address to, uint256 tokenId) internal {
        require(to != address(0), "DAAFArt: mint to the zero address");
        // Check if the token ID already exists (shouldn't happen with _nextTokenId)
        require(_artTokenOwners[tokenId] == address(0), "DAAFArt: token already minted");

        _artTokenBalances[to] += 1;
        _artTokenOwners[tokenId] = to;

        // No ERC721Recipient check here to keep it simplified and avoid external calls potentially.
        // In a real ERC721, this would call onERC721Received on the 'to' address if it's a contract.
    }

     /**
      * @dev Internal DAAFArt NFT burning logic.
      */
     function _burnArtNFTInternal(uint256 tokenId) internal {
         address owner = ownerOfArtNFT(tokenId); // Checks existence

         // Clear approvals
         _clearApproval(tokenId);

         _artTokenBalances[owner] -= 1;
         delete _artTokenOwners[tokenId];
         // Note: Dynamic parameters remain in storage unless explicitly cleared.
         // Depending on needs, you might want to clear _artDynamicParameters[tokenId] here.

         emit ArtNFTTransfer(owner, address(0), tokenId); // Transfer to zero address signifies burn
     }

     /**
      * @dev Internal helper to clear approval for a token.
      */
     function _clearApproval(uint256 tokenId) internal {
         if (_artTokenApprovals[tokenId] != address(0)) {
             delete _artTokenApprovals[tokenId];
             emit ArtNFTApproval(ownerOfArtNFT(tokenId), address(0), tokenId);
         }
     }

     /**
      * @dev Converts a uint256 to its string representation.
      *      (Simplified implementation, can be optimized)
      */
     function uint256ToString(uint256 value) internal pure returns (string memory) {
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


    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == _owner, "DAAF: Only owner can call this function");
        _;
    }

     // Modifier to restrict calls ONLY to the contract itself during proposal execution
     // This prevents external calls to update config params or mint NFTs directly.
     modifier onlyExecuteProposal() {
         // This modifier is a simplified check. A robust DAO might pass a flag or context.
         // We assume here that an internal call *from* executeProposal is the only path.
         // This is not a foolproof security measure against complex re-entrancy or internal calls not from executeProposal,
         // but serves the purpose for this example. A better way would involve context variables set by executeProposal.
         // For demonstration, we'll allow msg.sender to be *this* contract address, which is true for internal calls
         // initiated from an external tx to *this* contract.
         require(msg.sender == address(this), "DAAF: This function can only be called during proposal execution");
         _;
     }

}
```