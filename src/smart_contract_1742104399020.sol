```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Collective (DAAC) Smart Contract
 * @author Bard (Example - Not for Production Use)
 * @notice A smart contract for a decentralized art collective, enabling collaborative art creation,
 *         community curation, dynamic NFT evolution, and on-chain governance.
 *
 * @dev **Outline and Function Summary:**
 *
 * **1. Core Functionality:**
 *    - `submitArtProposal(string memory _title, string memory _description, string memory _ipfsHash)`: Allows artists to submit art proposals with metadata and IPFS hash.
 *    - `voteOnArtProposal(uint256 _proposalId, bool _support)`: Members can vote on submitted art proposals.
 *    - `mintArtNFT(uint256 _proposalId)`: Mints an NFT for a successfully approved art proposal, transferring it to the artist.
 *    - `evolveArtNFT(uint256 _tokenId, string memory _evolutionData)`: Allows for dynamic evolution of an NFT's metadata or visual representation based on community actions or external events.
 *    - `burnArtNFT(uint256 _tokenId)`: Allows the community to vote to "burn" an NFT under certain conditions (e.g., violation of community guidelines, consensus on quality).
 *
 * **2. Collaborative Art Creation & Features:**
 *    - `createCollaborativeCanvas(string memory _canvasName, string memory _description)`: Initiates a collaborative art canvas project.
 *    - `contributeToCanvas(uint256 _canvasId, string memory _contributionData)`: Members can contribute data or elements to an active collaborative canvas.
 *    - `finalizeCanvas(uint256 _canvasId)`:  Ends a collaborative canvas project, potentially minting a collective NFT representing the final artwork.
 *    - `setCanvasContributionCost(uint256 _canvasId, uint256 _cost)`: Sets a fee to contribute to a specific collaborative canvas, funding the collective treasury.
 *
 * **3. Community Governance & DAO Features:**
 *    - `proposeNewRule(string memory _ruleProposal, string memory _description)`: Allows members to propose new rules or guidelines for the collective.
 *    - `voteOnRuleProposal(uint256 _ruleId, bool _support)`: Members can vote on proposed rule changes.
 *    - `executeRuleProposal(uint256 _ruleId)`: Executes an approved rule proposal, potentially modifying contract parameters or behavior.
 *    - `depositToTreasury() payable`: Allows members to deposit funds into the collective treasury.
 *    - `proposeTreasurySpending(address _recipient, uint256 _amount, string memory _reason)`: Allows members to propose spending funds from the treasury.
 *    - `voteOnTreasurySpending(uint256 _spendingId, bool _support)`: Members can vote on treasury spending proposals.
 *    - `executeTreasurySpending(uint256 _spendingId)`: Executes approved treasury spending proposals.
 *
 * **4. Membership and Access Control:**
 *    - `requestMembership()`: Allows users to request membership in the DAAC.
 *    - `approveMembership(address _member)`: Only admin can approve pending membership requests.
 *    - `revokeMembership(address _member)`: Only admin can revoke membership under specific conditions.
 *    - `setAdmin(address _newAdmin)`: Allows the current admin to transfer admin rights to a new address.
 *
 * **5. Utility & Information Functions:**
 *    - `getArtProposalDetails(uint256 _proposalId)`: Returns details of a specific art proposal.
 *    - `getRuleProposalDetails(uint256 _ruleId)`: Returns details of a specific rule proposal.
 *    - `getTreasurySpendingDetails(uint256 _spendingId)`: Returns details of a specific treasury spending proposal.
 *    - `getCanvasDetails(uint256 _canvasId)`: Returns details of a specific collaborative canvas.
 *    - `getMemberStatus(address _member)`: Checks if an address is a member of the DAAC.
 *    - `getContractBalance()`: Returns the current balance of the contract treasury.
 */

contract DecentralizedAutonomousArtCollective {
    // -------- State Variables --------

    address public admin; // Admin address with privileged functions
    uint256 public membershipFee = 0.1 ether; // Fee to request membership (optional, can be 0)

    // Art Proposals
    uint256 public artProposalCount;
    mapping(uint256 => ArtProposal) public artProposals;
    enum ProposalStatus { Pending, Approved, Rejected }
    struct ArtProposal {
        uint256 id;
        address artist;
        string title;
        string description;
        string ipfsHash;
        ProposalStatus status;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted; // Track who voted on this proposal
    }
    uint256 public artProposalVotingDuration = 7 days; // Default voting duration for art proposals

    // Art NFTs (Simple example, could integrate with ERC721Enumerable for more features)
    uint256 public nextTokenId = 1;
    mapping(uint256 => ArtNFT) public artNFTs;
    struct ArtNFT {
        uint256 tokenId;
        address artist;
        string initialMetadata;
        string currentMetadata; // For dynamic evolution
        bool burned;
    }

    // Collaborative Canvases
    uint256 public canvasCount;
    mapping(uint256 => CollaborativeCanvas) public canvases;
    enum CanvasStatus { Active, Finalized }
    struct CollaborativeCanvas {
        uint256 id;
        string name;
        string description;
        CanvasStatus status;
        address creator;
        string collectiveArtworkData; // Could be IPFS hash or on-chain data, simplified for example
        uint256 contributionCost;
    }

    // Rule Proposals (Governance)
    uint256 public ruleProposalCount;
    mapping(uint256 => RuleProposal) public ruleProposals;
    struct RuleProposal {
        uint256 id;
        address proposer;
        string ruleProposal;
        string description;
        bool executed;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted; // Track who voted on this rule proposal
    }
    uint256 public ruleProposalVotingDuration = 14 days; // Default voting duration for rule proposals
    uint256 public quorumPercentage = 50; // Percentage of members required to vote for a proposal to pass

    // Treasury Spending Proposals
    uint256 public treasurySpendingProposalCount;
    mapping(uint256 => TreasurySpendingProposal) public treasurySpendingProposals;
    enum SpendingStatus { Pending, Approved, Rejected, Executed }
    struct TreasurySpendingProposal {
        uint256 id;
        address proposer;
        address recipient;
        uint256 amount;
        string reason;
        SpendingStatus status;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted; // Track who voted on this spending proposal
    }
    uint256 public treasurySpendingVotingDuration = 7 days;

    // Membership
    mapping(address => bool) public members; // Track members
    mapping(address => bool) public pendingMembershipRequests; // Track pending requests


    // -------- Events --------
    event ArtProposalSubmitted(uint256 proposalId, address artist, string title);
    event ArtProposalVoted(uint256 proposalId, address voter, bool support);
    event ArtNFTMinted(uint256 tokenId, address artist, uint256 proposalId);
    event ArtNFTEvolved(uint256 tokenId, string evolutionData);
    event ArtNFTBurned(uint256 tokenId);
    event CollaborativeCanvasCreated(uint256 canvasId, string canvasName, address creator);
    event CanvasContributionMade(uint256 canvasId, address contributor, string contributionData);
    event CanvasFinalized(uint256 canvasId);
    event RuleProposalCreated(uint256 ruleId, address proposer, string ruleProposal);
    event RuleProposalVoted(uint256 ruleId, address voter, bool support);
    event RuleProposalExecuted(uint256 ruleId);
    event TreasurySpendingProposed(uint256 spendingId, address proposer, address recipient, uint256 amount);
    event TreasurySpendingVoted(uint256 spendingId, address voter, bool support);
    event TreasurySpendingExecuted(uint256 spendingId, uint256 amount, address recipient);
    event MembershipRequested(address requester);
    event MembershipApproved(address member, address approvedBy);
    event MembershipRevoked(address member, address revokedBy);
    event AdminChanged(address oldAdmin, address newAdmin);

    // -------- Modifiers --------
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    modifier onlyMembers() {
        require(members[msg.sender], "Only members can perform this action");
        _;
    }

    modifier validArtProposal(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= artProposalCount, "Invalid art proposal ID");
        require(artProposals[_proposalId].status == ProposalStatus.Pending, "Art proposal is not pending");
        _;
    }

    modifier validRuleProposal(uint256 _ruleId) {
        require(_ruleId > 0 && _ruleId <= ruleProposalCount, "Invalid rule proposal ID");
        require(!ruleProposals[_ruleId].executed, "Rule proposal already executed");
        _;
    }

    modifier validTreasurySpendingProposal(uint256 _spendingId) {
        require(_spendingId > 0 && _spendingId <= treasurySpendingProposalCount, "Invalid spending proposal ID");
        require(treasurySpendingProposals[_spendingId].status == SpendingStatus.Pending, "Spending proposal is not pending");
        _;
    }

    modifier validCanvas(uint256 _canvasId) {
        require(_canvasId > 0 && _canvasId <= canvasCount, "Invalid canvas ID");
        require(canvases[_canvasId].status == CanvasStatus.Active, "Canvas is not active");
        _;
    }

    modifier nonMember(address _member) {
        require(!members(_member), "Address is already a member");
        _;
    }

    // -------- Constructor --------
    constructor() {
        admin = msg.sender; // Deployer becomes initial admin
    }

    // -------- 1. Core Functionality --------

    /// @notice Allows members to submit art proposals.
    /// @param _title Title of the art proposal.
    /// @param _description Description of the art proposal.
    /// @param _ipfsHash IPFS hash of the art proposal's metadata or artwork.
    function submitArtProposal(
        string memory _title,
        string memory _description,
        string memory _ipfsHash
    ) external onlyMembers {
        artProposalCount++;
        artProposals[artProposalCount] = ArtProposal({
            id: artProposalCount,
            artist: msg.sender,
            title: _title,
            description: _description,
            ipfsHash: _ipfsHash,
            status: ProposalStatus.Pending,
            votesFor: 0,
            votesAgainst: 0,
            hasVoted: mapping(address => bool)()
        });
        emit ArtProposalSubmitted(artProposalCount, msg.sender, _title);
    }

    /// @notice Allows members to vote on pending art proposals.
    /// @param _proposalId ID of the art proposal to vote on.
    /// @param _support True to vote in favor, false to vote against.
    function voteOnArtProposal(uint256 _proposalId, bool _support) external onlyMembers validArtProposal(_proposalId) {
        require(!artProposals[_proposalId].hasVoted[msg.sender], "Already voted on this proposal");
        artProposals[_proposalId].hasVoted[msg.sender] = true;

        if (_support) {
            artProposals[_proposalId].votesFor++;
        } else {
            artProposals[_proposalId].votesAgainst++;
        }
        emit ArtProposalVoted(_proposalId, msg.sender, _support);

        // Check if voting period ended and determine outcome (simplified logic)
        if (block.timestamp >= block.timestamp + artProposalVotingDuration) { // Example: Check if voting duration passed (simplified)
            if (artProposals[_proposalId].votesFor > artProposals[_proposalId].votesAgainst) {
                artProposals[_proposalId].status = ProposalStatus.Approved;
            } else {
                artProposals[_proposalId].status = ProposalStatus.Rejected;
            }
        }
    }

    /// @notice Mints an NFT for an approved art proposal and transfers it to the artist.
    /// @param _proposalId ID of the approved art proposal.
    function mintArtNFT(uint256 _proposalId) external onlyAdmin { // Admin mints after approval
        require(artProposals[_proposalId].status == ProposalStatus.Approved, "Proposal not approved");

        artNFTs[nextTokenId] = ArtNFT({
            tokenId: nextTokenId,
            artist: artProposals[_proposalId].artist,
            initialMetadata: artProposals[_proposalId].ipfsHash,
            currentMetadata: artProposals[_proposalId].ipfsHash, // Initially same as initial metadata
            burned: false
        });

        // In a real application, you would likely integrate with an ERC721 contract here
        // For simplicity, we just manage basic NFT data in this contract.

        emit ArtNFTMinted(nextTokenId, artProposals[_proposalId].artist, _proposalId);
        nextTokenId++;
    }

    /// @notice Allows for dynamic evolution of an NFT's metadata (or visual representation - conceptually).
    /// @param _tokenId ID of the NFT to evolve.
    /// @param _evolutionData Data representing the evolution (e.g., new metadata, traits, etc.).
    function evolveArtNFT(uint256 _tokenId, string memory _evolutionData) external onlyMembers {
        require(_tokenId > 0 && _tokenId < nextTokenId, "Invalid NFT token ID");
        require(!artNFTs[_tokenId].burned, "NFT is burned and cannot be evolved");

        // Implement logic for evolution based on _evolutionData.
        // This could involve updating metadata, triggering on-chain generative art processes, etc.
        // For this example, we simply update the `currentMetadata`.
        artNFTs[_tokenId].currentMetadata = _evolutionData;
        emit ArtNFTEvolved(_tokenId, _evolutionData);
    }

    /// @notice Allows the community to vote to "burn" an NFT under certain conditions.
    /// @param _tokenId ID of the NFT to burn.
    function burnArtNFT(uint256 _tokenId) external onlyAdmin { // Admin executes burn after community vote (not implemented voting here for burn - can be added)
        require(_tokenId > 0 && _tokenId < nextTokenId, "Invalid NFT token ID");
        require(!artNFTs[_tokenId].burned, "NFT is already burned");

        artNFTs[_tokenId].burned = true;
        // In a real application, you might want to trigger events or actions related to burning on an ERC721 contract.
        emit ArtNFTBurned(_tokenId);
    }


    // -------- 2. Collaborative Art Creation & Features --------

    /// @notice Initiates a collaborative art canvas project.
    /// @param _canvasName Name of the collaborative canvas.
    /// @param _description Description of the canvas project.
    function createCollaborativeCanvas(string memory _canvasName, string memory _description) external onlyMembers {
        canvasCount++;
        canvases[canvasCount] = CollaborativeCanvas({
            id: canvasCount,
            name: _canvasName,
            description: _description,
            status: CanvasStatus.Active,
            creator: msg.sender,
            collectiveArtworkData: "", // Initialize empty, contributions will build it
            contributionCost: 0 // Default contribution cost is 0
        });
        emit CollaborativeCanvasCreated(canvasCount, _canvasName, msg.sender);
    }

    /// @notice Allows members to contribute data or elements to an active collaborative canvas.
    /// @param _canvasId ID of the collaborative canvas to contribute to.
    /// @param _contributionData Data representing the contribution (e.g., drawing instructions, text, etc.).
    function contributeToCanvas(uint256 _canvasId, string memory _contributionData) external payable onlyMembers validCanvas(_canvasId) {
        if (canvases[_canvasId].contributionCost > 0) {
            require(msg.value >= canvases[_canvasId].contributionCost, "Insufficient contribution fee");
        }

        // Append contribution data to the collective artwork data (simplified - in real use, might be more complex)
        canvases[_canvasId].collectiveArtworkData = string(abi.encodePacked(canvases[_canvasId].collectiveArtworkData, _contributionData, ",")); // Simple comma separation

        if (canvases[_canvasId].contributionCost > 0) {
            // Transfer contribution fee to the treasury
            (bool success, ) = address(this).call{value: canvases[_canvasId].contributionCost}("");
            require(success, "Failed to transfer contribution fee to treasury");
        }

        emit CanvasContributionMade(_canvasId, msg.sender, _contributionData);
    }

    /// @notice Sets a fee to contribute to a specific collaborative canvas.
    /// @param _canvasId ID of the canvas.
    /// @param _cost Fee in wei required to contribute.
    function setCanvasContributionCost(uint256 _canvasId, uint256 _cost) external onlyAdmin validCanvas(_canvasId) {
        canvases[_canvasId].contributionCost = _cost;
    }


    /// @notice Ends a collaborative canvas project, potentially minting a collective NFT (not implemented in this simplified example).
    /// @param _canvasId ID of the collaborative canvas to finalize.
    function finalizeCanvas(uint256 _canvasId) external onlyAdmin validCanvas(_canvasId) {
        canvases[_canvasId].status = CanvasStatus.Finalized;
        emit CanvasFinalized(_canvasId);
        // In a more advanced version, you could implement logic to mint an NFT representing the final `collectiveArtworkData`.
    }


    // -------- 3. Community Governance & DAO Features --------

    /// @notice Allows members to propose new rules or guidelines for the collective.
    /// @param _ruleProposal Short description of the proposed rule.
    /// @param _description Detailed description of the rule proposal.
    function proposeNewRule(string memory _ruleProposal, string memory _description) external onlyMembers {
        ruleProposalCount++;
        ruleProposals[ruleProposalCount] = RuleProposal({
            id: ruleProposalCount,
            proposer: msg.sender,
            ruleProposal: _ruleProposal,
            description: _description,
            executed: false,
            votesFor: 0,
            votesAgainst: 0,
            hasVoted: mapping(address => bool)()
        });
        emit RuleProposalCreated(ruleProposalCount, msg.sender, _ruleProposal);
    }

    /// @notice Allows members to vote on pending rule proposals.
    /// @param _ruleId ID of the rule proposal to vote on.
    /// @param _support True to vote in favor, false to vote against.
    function voteOnRuleProposal(uint256 _ruleId, bool _support) external onlyMembers validRuleProposal(_ruleId) {
        require(!ruleProposals[_ruleId].hasVoted[msg.sender], "Already voted on this rule proposal");
        ruleProposals[_ruleId].hasVoted[msg.sender] = true;

        if (_support) {
            ruleProposals[_ruleId].votesFor++;
        } else {
            ruleProposals[_ruleId].votesAgainst++;
        }
        emit RuleProposalVoted(_ruleId, msg.sender, _support);

        // Check if voting period ended and determine outcome (simplified logic)
        if (block.timestamp >= block.timestamp + ruleProposalVotingDuration) { // Example: Check if voting duration passed (simplified)
            uint256 totalMembers = 0; // In real app, track members count
            for (uint256 i = 1; i <= ruleProposalCount; i++) { // Inefficient, use better member tracking in real app
                if (members[address(uint160(i))]){ // Placeholder logic, replace with proper member count
                    totalMembers++;
                }
            }
            uint256 quorumVotesNeeded = (totalMembers * quorumPercentage) / 100; // Quorum based on total members

            if (ruleProposals[_ruleId].votesFor >= quorumVotesNeeded && ruleProposals[_ruleId].votesFor > ruleProposals[_ruleId].votesAgainst) {
                ruleProposals[_ruleId].executed = true;
                emit RuleProposalExecuted(_ruleId);
                // Execute the rule change if needed (logic depends on what rules are being changed)
            }
        }
    }

    /// @notice Executes an approved rule proposal. (In this example, execution is mostly conceptual, rules are not dynamically applied to contract logic)
    /// @param _ruleId ID of the rule proposal to execute.
    function executeRuleProposal(uint256 _ruleId) external onlyAdmin validRuleProposal(_ruleId) { // Admin executes after approval
        require(ruleProposals[_ruleId].votesFor > ruleProposals[_ruleId].votesAgainst, "Rule proposal not approved by community majority");
        ruleProposals[_ruleId].executed = true;
        emit RuleProposalExecuted(_ruleId);
        // Rule execution logic would go here if rules were dynamically modifying contract behavior.
        // For this example, rule execution is mostly about marking it as executed and potentially communicating the rule off-chain.
    }

    /// @notice Allows members to deposit funds into the collective treasury.
    function depositToTreasury() external payable onlyMembers {
        // Funds are automatically deposited to the contract address when payable functions are called with value.
        // No explicit transfer needed here.
    }

    /// @notice Allows members to propose spending funds from the treasury.
    /// @param _recipient Address to receive the funds.
    /// @param _amount Amount to spend in wei.
    /// @param _reason Reason for the spending proposal.
    function proposeTreasurySpending(address _recipient, uint256 _amount, string memory _reason) external onlyMembers {
        require(_recipient != address(0), "Invalid recipient address");
        require(_amount > 0, "Spending amount must be greater than zero");
        require(address(this).balance >= _amount, "Insufficient contract balance for spending"); // Check treasury balance

        treasurySpendingProposalCount++;
        treasurySpendingProposals[treasurySpendingProposalCount] = TreasurySpendingProposal({
            id: treasurySpendingProposalCount,
            proposer: msg.sender,
            recipient: _recipient,
            amount: _amount,
            reason: _reason,
            status: SpendingStatus.Pending,
            votesFor: 0,
            votesAgainst: 0,
            hasVoted: mapping(address => bool)()
        });
        emit TreasurySpendingProposed(treasurySpendingProposalCount, msg.sender, _recipient, _amount);
    }

    /// @notice Allows members to vote on pending treasury spending proposals.
    /// @param _spendingId ID of the treasury spending proposal to vote on.
    /// @param _support True to vote in favor, false to vote against.
    function voteOnTreasurySpending(uint256 _spendingId, bool _support) external onlyMembers validTreasurySpendingProposal(_spendingId) {
        require(!treasurySpendingProposals[_spendingId].hasVoted[msg.sender], "Already voted on this spending proposal");
        treasurySpendingProposals[_spendingId].hasVoted[msg.sender] = true;

        if (_support) {
            treasurySpendingProposals[_spendingId].votesFor++;
        } else {
            treasurySpendingProposals[_spendingId].votesAgainst++;
        }
        emit TreasurySpendingVoted(_spendingId, msg.sender, _support);

        // Check if voting period ended and determine outcome (simplified logic)
        if (block.timestamp >= block.timestamp + treasurySpendingVotingDuration) { // Example: Check if voting duration passed (simplified)
            if (treasurySpendingProposals[_spendingId].votesFor > treasurySpendingProposals[_spendingId].votesAgainst) {
                treasurySpendingProposals[_spendingId].status = SpendingStatus.Approved;
            } else {
                treasurySpendingProposals[_spendingId].status = SpendingStatus.Rejected;
            }
        }
    }

    /// @notice Executes an approved treasury spending proposal.
    /// @param _spendingId ID of the treasury spending proposal to execute.
    function executeTreasurySpending(uint256 _spendingId) external onlyAdmin validTreasurySpendingProposal(_spendingId) { // Admin executes after approval
        require(treasurySpendingProposals[_spendingId].status == SpendingStatus.Approved, "Spending proposal not approved");
        treasurySpendingProposals[_spendingId].status = SpendingStatus.Executed;

        uint256 amount = treasurySpendingProposals[_spendingId].amount;
        address recipient = treasurySpendingProposals[_spendingId].recipient;

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Treasury spending transfer failed");

        emit TreasurySpendingExecuted(_spendingId, amount, recipient);
    }


    // -------- 4. Membership and Access Control --------

    /// @notice Allows users to request membership in the DAAC.
    function requestMembership() external payable nonMember(msg.sender) {
        if (membershipFee > 0) {
            require(msg.value >= membershipFee, "Insufficient membership fee");
        }
        pendingMembershipRequests[msg.sender] = true;
        emit MembershipRequested(msg.sender);
    }

    /// @notice Approves a pending membership request (only admin).
    /// @param _member Address of the user to approve for membership.
    function approveMembership(address _member) external onlyAdmin {
        require(pendingMembershipRequests[_member], "No pending membership request for this address");
        members[_member] = true;
        pendingMembershipRequests[_member] = false;
        emit MembershipApproved(_member, msg.sender);
    }

    /// @notice Revokes membership from a member (only admin).
    /// @param _member Address of the member to revoke membership from.
    function revokeMembership(address _member) external onlyAdmin {
        require(members[_member], "Address is not a member");
        delete members[_member]; // Or set to false: members[_member] = false;
        emit MembershipRevoked(_member, msg.sender);
    }

    /// @notice Sets a new admin address (only current admin).
    /// @param _newAdmin Address of the new admin.
    function setAdmin(address _newAdmin) external onlyAdmin {
        require(_newAdmin != address(0), "Invalid new admin address");
        emit AdminChanged(admin, _newAdmin);
        admin = _newAdmin;
    }


    // -------- 5. Utility & Information Functions --------

    /// @notice Returns details of a specific art proposal.
    /// @param _proposalId ID of the art proposal.
    /// @return Details of the art proposal.
    function getArtProposalDetails(uint256 _proposalId) external view returns (ArtProposal memory) {
        require(_proposalId > 0 && _proposalId <= artProposalCount, "Invalid art proposal ID");
        return artProposals[_proposalId];
    }

    /// @notice Returns details of a specific rule proposal.
    /// @param _ruleId ID of the rule proposal.
    /// @return Details of the rule proposal.
    function getRuleProposalDetails(uint256 _ruleId) external view returns (RuleProposal memory) {
        require(_ruleId > 0 && _ruleId <= ruleProposalCount, "Invalid rule proposal ID");
        return ruleProposals[_ruleId];
    }

    /// @notice Returns details of a specific treasury spending proposal.
    /// @param _spendingId ID of the treasury spending proposal.
    /// @return Details of the treasury spending proposal.
    function getTreasurySpendingDetails(uint256 _spendingId) external view returns (TreasurySpendingProposal memory) {
        require(_spendingId > 0 && _spendingId <= treasurySpendingProposalCount, "Invalid spending proposal ID");
        return treasurySpendingProposals[_spendingId];
    }

    /// @notice Returns details of a specific collaborative canvas.
    /// @param _canvasId ID of the collaborative canvas.
    /// @return Details of the collaborative canvas.
    function getCanvasDetails(uint256 _canvasId) external view returns (CollaborativeCanvas memory) {
        require(_canvasId > 0 && _canvasId <= canvasCount, "Invalid canvas ID");
        return canvases[_canvasId];
    }

    /// @notice Checks if an address is a member of the DAAC.
    /// @param _member Address to check.
    /// @return True if the address is a member, false otherwise.
    function getMemberStatus(address _member) external view returns (bool) {
        return members[_member];
    }

    /// @notice Returns the current balance of the contract treasury.
    /// @return The contract's balance in wei.
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
```