```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Collective (DAAC) Smart Contract
 * @author Bard (Example - Conceptual Contract)
 * @dev A smart contract for a decentralized art collective, incorporating advanced concepts like quadratic voting,
 *      dynamic NFT traits, decentralized curation, and community-driven evolution.
 *
 * Outline & Function Summary:
 *
 *  **Core Functionality:**
 *  1.  `submitArt(string memory _title, string memory _ipfsHash, string memory _description)`: Allows artists to submit art pieces to the collective.
 *  2.  `voteOnArtSubmission(uint256 _artId, bool _approve)`: Members vote on submitted art pieces for inclusion in the collective. (Quadratic Voting)
 *  3.  `finalizeArtSubmission(uint256 _artId)`: Finalizes the art submission if it reaches quorum and approval, minting an NFT.
 *  4.  `mintMembershipNFT()`: Allows users to mint a Membership NFT to join the DAAC and participate in governance.
 *  5.  `stakeMembershipNFT(uint256 _tokenId)`: Stakes a Membership NFT to gain voting power and access to exclusive features.
 *  6.  `unstakeMembershipNFT(uint256 _tokenId)`: Unstakes a Membership NFT, reducing voting power.
 *  7.  `proposeTraitEvolution(uint256 _artId, string memory _traitName, string memory _newValue)`: Members can propose evolutions/changes to the traits of an existing NFT.
 *  8.  `voteOnTraitEvolution(uint256 _evolutionProposalId, bool _approve)`: Members vote on proposed trait evolutions. (Quadratic Voting)
 *  9.  `finalizeTraitEvolution(uint256 _evolutionProposalId)`: Executes approved trait evolutions, dynamically updating NFT metadata.
 *  10. `donateToCollective()`: Allows anyone to donate ETH to the collective's treasury.
 *  11. `proposeTreasurySpending(address _recipient, uint256 _amount, string memory _reason)`: Members can propose spending from the collective's treasury.
 *  12. `voteOnTreasurySpending(uint256 _spendingProposalId, bool _approve)`: Members vote on treasury spending proposals. (Quadratic Voting)
 *  13. `executeTreasurySpending(uint256 _spendingProposalId)`: Executes approved treasury spending proposals.
 *
 *  **Advanced/Trendy Features:**
 *  14. `setQuadraticVotingPower(uint256 _baseVotingPower)`:  Admin function to adjust the base voting power for quadratic voting.
 *  15. `getArtPieceDetails(uint256 _artId)`: Retrieves detailed information about a specific art piece.
 *  16. `getMembershipNFTDetails(uint256 _tokenId)`: Retrieves details of a Membership NFT, including staking status.
 *  17. `getVotingPower(address _member)`: Returns the voting power of a member based on staked Membership NFTs (Quadratic Voting).
 *  18. `pauseContract()`: Admin function to pause critical contract functionalities in case of emergency.
 *  19. `unpauseContract()`: Admin function to resume contract functionalities after pausing.
 *  20. `emergencyWithdraw()`: Admin function to withdraw contract balance in case of critical vulnerability (with multisig or timelock in real-world scenarios).
 *  21. `setQuorumPercentage(uint256 _percentage)`: Admin function to set the quorum percentage for voting.
 *  22. `getTraitEvolutionProposalDetails(uint256 _proposalId)`: Retrieves details about a specific trait evolution proposal.
 */

contract DecentralizedAutonomousArtCollective {
    // --- Structs ---
    struct ArtPiece {
        string title;
        string ipfsHash;
        string description;
        address artist;
        uint256 submissionTimestamp;
        bool isApproved;
        bool exists; // To handle deletion/non-existent IDs gracefully
    }

    struct MembershipNFT {
        uint256 tokenId;
        address owner;
        bool isStaked;
        uint256 stakeTimestamp;
        bool exists;
    }

    struct ArtSubmissionProposal {
        uint256 artId;
        uint256 yesVotes;
        uint256 noVotes;
        uint256 proposalTimestamp;
        bool isActive;
        bool exists;
    }

    struct TraitEvolutionProposal {
        uint256 artId;
        string traitName;
        string newValue;
        uint256 yesVotes;
        uint256 noVotes;
        uint256 proposalTimestamp;
        bool isActive;
        bool exists;
    }

    struct TreasurySpendingProposal {
        address recipient;
        uint256 amount;
        string reason;
        uint256 yesVotes;
        uint256 noVotes;
        uint256 proposalTimestamp;
        bool isActive;
        bool exists;
    }

    // --- State Variables ---
    mapping(uint256 => ArtPiece) public artPieces;
    uint256 public artPieceCount;

    mapping(uint256 => MembershipNFT) public membershipNFTs;
    uint256 public membershipNFTCount;

    mapping(uint256 => ArtSubmissionProposal) public artSubmissionProposals;
    uint256 public artSubmissionProposalCount;

    mapping(uint256 => TraitEvolutionProposal) public traitEvolutionProposals;
    uint256 public traitEvolutionProposalCount;

    mapping(uint256 => TreasurySpendingProposal) public treasurySpendingProposals;
    uint256 public treasurySpendingProposalCount;

    mapping(address => uint256) public memberStakedNFTCount; // Count of staked NFTs per member for voting power

    uint256 public quadraticVotingPowerBase = 100; // Base voting power per staked NFT
    uint256 public votingQuorumPercentage = 50; // Percentage of total staked voting power required for quorum

    address public admin;
    bool public paused;

    // --- Events ---
    event ArtSubmitted(uint256 artId, address artist, string title);
    event ArtSubmissionVoted(uint256 proposalId, address voter, bool vote);
    event ArtSubmissionFinalized(uint256 artId, bool approved);
    event MembershipNFTMinted(uint256 tokenId, address minter);
    event MembershipNFTStaked(uint256 tokenId, address staker);
    event MembershipNFTUnstaked(uint256 tokenId, address unstaker);
    event TraitEvolutionProposed(uint256 proposalId, uint256 artId, string traitName, string newValue);
    event TraitEvolutionVoted(uint256 proposalId, address voter, bool vote);
    event TraitEvolutionFinalized(uint256 proposalId, bool approved);
    event TreasuryDonationReceived(address donor, uint256 amount);
    event TreasurySpendingProposed(uint256 proposalId, address recipient, uint256 amount, string reason);
    event TreasurySpendingVoted(uint256 proposalId, address voter, bool vote);
    event TreasurySpendingExecuted(uint256 proposalId, bool approved);
    event ContractPaused(address admin);
    event ContractUnpaused(address admin);
    event EmergencyWithdrawal(address admin, uint256 amount);
    event QuorumPercentageUpdated(uint256 newPercentage, address admin);
    event QuadraticVotingPowerUpdated(uint256 newPower, address admin);

    // --- Modifiers ---
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused");
        _;
    }

    modifier validArtId(uint256 _artId) {
        require(artPieces[_artId].exists, "Invalid Art ID");
        _;
    }

    modifier validMembershipNFTId(uint256 _tokenId) {
        require(membershipNFTs[_tokenId].exists, "Invalid Membership NFT ID");
        _;
    }

    modifier validArtSubmissionProposalId(uint256 _proposalId) {
        require(artSubmissionProposals[_proposalId].exists, "Invalid Art Submission Proposal ID");
        _;
    }

    modifier validTraitEvolutionProposalId(uint256 _proposalId) {
        require(traitEvolutionProposals[_proposalId].exists, "Invalid Trait Evolution Proposal ID");
        _;
    }

    modifier validTreasurySpendingProposalId(uint256 _proposalId) {
        require(treasurySpendingProposals[_proposalId].exists, "Invalid Treasury Spending Proposal ID");
        _;
    }

    modifier onlyStakedMember(uint256 _tokenId) {
        require(membershipNFTs[_tokenId].exists && membershipNFTs[_tokenId].isStaked && membershipNFTs[_tokenId].owner == msg.sender, "Must be a staked member to perform this action");
        _;
    }

    modifier onlyMember(uint256 _tokenId) {
        require(membershipNFTs[_tokenId].exists && membershipNFTs[_tokenId].owner == msg.sender, "Must be a member to perform this action");
        _;
    }

    modifier proposalActive(ArtSubmissionProposal storage _proposal) {
        require(_proposal.isActive, "Proposal is not active");
        _;
    }

    modifier proposalActive(TraitEvolutionProposal storage _proposal) {
        require(_proposal.isActive, "Proposal is not active");
        _;
    }

    modifier proposalActive(TreasurySpendingProposal storage _proposal) {
        require(_proposal.isActive, "Proposal is not active");
        _;
    }

    // --- Constructor ---
    constructor() {
        admin = msg.sender;
        paused = false;
    }

    // --- Core Functions ---

    /// @notice Allows artists to submit their art piece to the collective for consideration.
    /// @param _title The title of the art piece.
    /// @param _ipfsHash IPFS hash pointing to the art piece's metadata.
    /// @param _description A brief description of the art piece.
    function submitArt(string memory _title, string memory _ipfsHash, string memory _description) external whenNotPaused {
        artPieceCount++;
        artPieces[artPieceCount] = ArtPiece({
            title: _title,
            ipfsHash: _ipfsHash,
            description: _description,
            artist: msg.sender,
            submissionTimestamp: block.timestamp,
            isApproved: false,
            exists: true
        });

        artSubmissionProposalCount++;
        artSubmissionProposals[artSubmissionProposalCount] = ArtSubmissionProposal({
            artId: artPieceCount,
            yesVotes: 0,
            noVotes: 0,
            proposalTimestamp: block.timestamp,
            isActive: true,
            exists: true
        });

        emit ArtSubmitted(artPieceCount, msg.sender, _title);
    }

    /// @notice Allows staked members to vote on an art submission proposal. Quadratic voting mechanism is applied.
    /// @param _artId The ID of the art piece being voted on.
    /// @param _approve Boolean indicating approval (true) or rejection (false).
    function voteOnArtSubmission(uint256 _artId, bool _approve) external whenNotPaused {
        uint256 tokenId = _getTokenIdForAddress(msg.sender); // Find a staked NFT owned by the voter
        require(tokenId != 0, "You need to stake a Membership NFT to vote.");
        require(membershipNFTs[tokenId].isStaked, "You need to stake a Membership NFT to vote.");

        uint256 proposalId = _getArtSubmissionProposalIdByArtId(_artId);
        require(proposalId != 0, "No active proposal found for this Art ID.");
        ArtSubmissionProposal storage proposal = artSubmissionProposals[proposalId];
        proposalActive(proposal);

        uint256 votingPower = getVotingPower(msg.sender); // Quadratic voting power
        require(votingPower > 0, "No voting power available.");

        if (_approve) {
            proposal.yesVotes += votingPower;
        } else {
            proposal.noVotes += votingPower;
        }

        emit ArtSubmissionVoted(proposalId, msg.sender, _approve);
    }

    /// @notice Finalizes an art submission proposal if it reaches quorum and is approved. Mints an NFT for the art piece if approved.
    /// @param _artId The ID of the art piece to finalize the submission for.
    function finalizeArtSubmission(uint256 _artId) external whenNotPaused {
        uint256 proposalId = _getArtSubmissionProposalIdByArtId(_artId);
        require(proposalId != 0, "No active proposal found for this Art ID.");
        ArtSubmissionProposal storage proposal = artSubmissionProposals[proposalId];
        proposalActive(proposal);

        uint256 totalStakedVotingPower = _getTotalStakedVotingPower();
        uint256 quorumNeeded = (totalStakedVotingPower * votingQuorumPercentage) / 100;

        require(proposal.yesVotes + proposal.noVotes >= quorumNeeded, "Quorum not reached yet.");

        bool approved = proposal.yesVotes > proposal.noVotes; // Simple majority for now

        if (approved) {
            artPieces[_artId].isApproved = true;
            // In a real-world scenario, mint an NFT here, potentially using ERC721 or ERC1155.
            // For simplicity, this example just marks it as approved.
        }

        proposal.isActive = false; // Deactivate the proposal
        emit ArtSubmissionFinalized(_artId, approved);
    }

    /// @notice Allows users to mint a Membership NFT to join the DAAC and participate in governance.
    function mintMembershipNFT() external whenNotPaused {
        membershipNFTCount++;
        membershipNFTs[membershipNFTCount] = MembershipNFT({
            tokenId: membershipNFTCount,
            owner: msg.sender,
            isStaked: false,
            stakeTimestamp: 0,
            exists: true
        });
        emit MembershipNFTMinted(membershipNFTCount, msg.sender);
    }

    /// @notice Allows members to stake their Membership NFT to gain voting power and access to exclusive features.
    /// @param _tokenId The ID of the Membership NFT to stake.
    function stakeMembershipNFT(uint256 _tokenId) external whenNotPaused validMembershipNFTId(_tokenId) onlyMember(_tokenId) {
        require(!membershipNFTs[_tokenId].isStaked, "NFT already staked");
        membershipNFTs[_tokenId].isStaked = true;
        membershipNFTs[_tokenId].stakeTimestamp = block.timestamp;
        memberStakedNFTCount[msg.sender]++;
        emit MembershipNFTStaked(_tokenId, msg.sender);
    }

    /// @notice Allows members to unstake their Membership NFT, reducing their voting power.
    /// @param _tokenId The ID of the Membership NFT to unstake.
    function unstakeMembershipNFT(uint256 _tokenId) external whenNotPaused validMembershipNFTId(_tokenId) onlyMember(_tokenId) {
        require(membershipNFTs[_tokenId].isStaked, "NFT not staked");
        membershipNFTs[_tokenId].isStaked = false;
        membershipNFTs[_tokenId].stakeTimestamp = 0;
        memberStakedNFTCount[msg.sender]--;
        emit MembershipNFTUnstaked(_tokenId, msg.sender);
    }

    /// @notice Allows staked members to propose an evolution or change to a trait of an existing NFT art piece.
    /// @param _artId The ID of the art piece to propose a trait evolution for.
    /// @param _traitName The name of the trait to be evolved.
    /// @param _newValue The new value for the trait.
    function proposeTraitEvolution(uint256 _artId, string memory _traitName, string memory _newValue) external whenNotPaused validArtId(_artId) {
        uint256 tokenId = _getTokenIdForAddress(msg.sender); // Find a staked NFT owned by the proposer
        require(tokenId != 0, "You need to stake a Membership NFT to propose trait evolution.");
        require(membershipNFTs[tokenId].isStaked, "You need to stake a Membership NFT to propose trait evolution.");

        traitEvolutionProposalCount++;
        traitEvolutionProposals[traitEvolutionProposalCount] = TraitEvolutionProposal({
            artId: _artId,
            traitName: _traitName,
            newValue: _newValue,
            yesVotes: 0,
            noVotes: 0,
            proposalTimestamp: block.timestamp,
            isActive: true,
            exists: true
        });

        emit TraitEvolutionProposed(traitEvolutionProposalCount, _artId, _traitName, _newValue);
    }

    /// @notice Allows staked members to vote on a trait evolution proposal. Quadratic voting mechanism is applied.
    /// @param _evolutionProposalId The ID of the trait evolution proposal.
    /// @param _approve Boolean indicating approval (true) or rejection (false).
    function voteOnTraitEvolution(uint256 _evolutionProposalId, bool _approve) external whenNotPaused validTraitEvolutionProposalId(_evolutionProposalId) {
        uint256 tokenId = _getTokenIdForAddress(msg.sender); // Find a staked NFT owned by the voter
        require(tokenId != 0, "You need to stake a Membership NFT to vote.");
        require(membershipNFTs[tokenId].isStaked, "You need to stake a Membership NFT to vote.");

        TraitEvolutionProposal storage proposal = traitEvolutionProposals[_evolutionProposalId];
        proposalActive(proposal);

        uint256 votingPower = getVotingPower(msg.sender); // Quadratic voting power
        require(votingPower > 0, "No voting power available.");

        if (_approve) {
            proposal.yesVotes += votingPower;
        } else {
            proposal.noVotes += votingPower;
        }

        emit TraitEvolutionVoted(_evolutionProposalId, msg.sender, _approve);
    }

    /// @notice Finalizes a trait evolution proposal if it reaches quorum and is approved. Dynamically updates the NFT metadata (conceptually).
    /// @param _evolutionProposalId The ID of the trait evolution proposal to finalize.
    function finalizeTraitEvolution(uint256 _evolutionProposalId) external whenNotPaused validTraitEvolutionProposalId(_evolutionProposalId) {
        TraitEvolutionProposal storage proposal = traitEvolutionProposals[_evolutionProposalId];
        proposalActive(proposal);

        uint256 totalStakedVotingPower = _getTotalStakedVotingPower();
        uint256 quorumNeeded = (totalStakedVotingPower * votingQuorumPercentage) / 100;
        require(proposal.yesVotes + proposal.noVotes >= quorumNeeded, "Quorum not reached yet.");

        bool approved = proposal.yesVotes > proposal.noVotes; // Simple majority for now

        if (approved) {
            // In a real-world scenario, update the NFT metadata here, likely off-chain with a service that listens to this event.
            // For simplicity, this example just emits an event.
        }

        proposal.isActive = false; // Deactivate the proposal
        emit TraitEvolutionFinalized(_evolutionProposalId, approved);
    }

    /// @notice Allows anyone to donate ETH to the collective's treasury.
    function donateToCollective() external payable whenNotPaused {
        emit TreasuryDonationReceived(msg.sender, msg.value);
    }

    /// @notice Allows staked members to propose spending funds from the collective's treasury.
    /// @param _recipient The address to receive the funds.
    /// @param _amount The amount of ETH to spend.
    /// @param _reason A brief reason for the spending proposal.
    function proposeTreasurySpending(address _recipient, uint256 _amount, string memory _reason) external whenNotPaused {
        uint256 tokenId = _getTokenIdForAddress(msg.sender); // Find a staked NFT owned by the proposer
        require(tokenId != 0, "You need to stake a Membership NFT to propose treasury spending.");
        require(membershipNFTs[tokenId].isStaked, "You need to stake a Membership NFT to propose treasury spending.");
        require(address(this).balance >= _amount, "Insufficient funds in treasury.");

        treasurySpendingProposalCount++;
        treasurySpendingProposals[treasurySpendingProposalCount] = TreasurySpendingProposal({
            recipient: _recipient,
            amount: _amount,
            reason: _reason,
            yesVotes: 0,
            noVotes: 0,
            proposalTimestamp: block.timestamp,
            isActive: true,
            exists: true
        });

        emit TreasurySpendingProposed(treasurySpendingProposalCount, _recipient, _amount, _reason);
    }

    /// @notice Allows staked members to vote on a treasury spending proposal. Quadratic voting mechanism is applied.
    /// @param _spendingProposalId The ID of the treasury spending proposal.
    /// @param _approve Boolean indicating approval (true) or rejection (false).
    function voteOnTreasurySpending(uint256 _spendingProposalId, bool _approve) external whenNotPaused validTreasurySpendingProposalId(_spendingProposalId) {
        uint256 tokenId = _getTokenIdForAddress(msg.sender); // Find a staked NFT owned by the voter
        require(tokenId != 0, "You need to stake a Membership NFT to vote.");
        require(membershipNFTs[tokenId].isStaked, "You need to stake a Membership NFT to vote.");

        TreasurySpendingProposal storage proposal = treasurySpendingProposals[_spendingProposalId];
        proposalActive(proposal);

        uint256 votingPower = getVotingPower(msg.sender); // Quadratic voting power
        require(votingPower > 0, "No voting power available.");

        if (_approve) {
            proposal.yesVotes += votingPower;
        } else {
            proposal.noVotes += votingPower;
        }

        emit TreasurySpendingVoted(_spendingProposalId, msg.sender, _approve);
    }

    /// @notice Executes a treasury spending proposal if it reaches quorum and is approved. Transfers ETH to the recipient.
    /// @param _spendingProposalId The ID of the treasury spending proposal to execute.
    function executeTreasurySpending(uint256 _spendingProposalId) external whenNotPaused validTreasurySpendingProposalId(_spendingProposalId) {
        TreasurySpendingProposal storage proposal = treasurySpendingProposals[_spendingProposalId];
        proposalActive(proposal);

        uint256 totalStakedVotingPower = _getTotalStakedVotingPower();
        uint256 quorumNeeded = (totalStakedVotingPower * votingQuorumPercentage) / 100;
        require(proposal.yesVotes + proposal.noVotes >= quorumNeeded, "Quorum not reached yet.");

        bool approved = proposal.yesVotes > proposal.noVotes; // Simple majority for now

        if (approved) {
            (bool success, ) = proposal.recipient.call{value: proposal.amount}("");
            require(success, "Treasury spending transfer failed.");
        }

        proposal.isActive = false; // Deactivate the proposal
        emit TreasurySpendingExecuted(_spendingProposalId, approved);
    }

    // --- Advanced/Trendy Functions ---

    /// @notice Admin function to set the base voting power for quadratic voting.
    /// @param _baseVotingPower The new base voting power value.
    function setQuadraticVotingPower(uint256 _baseVotingPower) external onlyAdmin {
        quadraticVotingPowerBase = _baseVotingPower;
        emit QuadraticVotingPowerUpdated(_baseVotingPower, admin);
    }

    /// @notice Retrieves detailed information about a specific art piece.
    /// @param _artId The ID of the art piece.
    /// @return ArtPiece struct containing art piece details.
    function getArtPieceDetails(uint256 _artId) external view validArtId(_artId) returns (ArtPiece memory) {
        return artPieces[_artId];
    }

    /// @notice Retrieves details of a Membership NFT, including staking status.
    /// @param _tokenId The ID of the Membership NFT.
    /// @return MembershipNFT struct containing Membership NFT details.
    function getMembershipNFTDetails(uint256 _tokenId) external view validMembershipNFTId(_tokenId) returns (MembershipNFT memory) {
        return membershipNFTs[_tokenId];
    }

    /// @notice Calculates and returns the voting power of a member based on staked Membership NFTs using quadratic voting.
    ///         Voting power is the square root of the number of staked NFTs multiplied by the base voting power.
    /// @param _member The address of the member.
    /// @return The voting power of the member.
    function getVotingPower(address _member) public view returns (uint256) {
        uint256 stakedCount = memberStakedNFTCount[_member];
        // Quadratic voting: voting power = sqrt(stakedCount) * baseVotingPower
        // Solidity doesn't have native sqrt, so we can approximate or use a library for more precise sqrt.
        // For simplicity, a linear approach is used here as a placeholder for demonstration.
        // In a real-world scenario, implement a proper square root approximation or library.
        return stakedCount * quadraticVotingPowerBase; // Linear approximation for demonstration. Replace with sqrt for quadratic voting.
    }

    /// @notice Admin function to pause critical contract functionalities in case of emergency.
    function pauseContract() external onlyAdmin whenNotPaused {
        paused = true;
        emit ContractPaused(admin);
    }

    /// @notice Admin function to resume contract functionalities after pausing.
    function unpauseContract() external onlyAdmin whenPaused {
        paused = false;
        emit ContractUnpaused(admin);
    }

    /// @notice Admin function to withdraw contract balance in case of critical vulnerability (use with caution and multisig/timelock in real-world).
    function emergencyWithdraw() external onlyAdmin {
        uint256 balance = address(this).balance;
        (bool success, ) = admin.call{value: balance}("");
        require(success, "Emergency withdrawal failed");
        emit EmergencyWithdrawal(admin, balance);
    }

    /// @notice Admin function to set the quorum percentage required for voting to pass.
    /// @param _percentage The new quorum percentage (e.g., 50 for 50%).
    function setQuorumPercentage(uint256 _percentage) external onlyAdmin {
        require(_percentage <= 100, "Quorum percentage must be less than or equal to 100");
        votingQuorumPercentage = _percentage;
        emit QuorumPercentageUpdated(_percentage, admin);
    }

     /// @notice Retrieves detailed information about a specific trait evolution proposal.
    /// @param _proposalId The ID of the trait evolution proposal.
    /// @return TraitEvolutionProposal struct containing trait evolution proposal details.
    function getTraitEvolutionProposalDetails(uint256 _proposalId) external view validTraitEvolutionProposalId(_proposalId) returns (TraitEvolutionProposal memory) {
        return traitEvolutionProposals[_proposalId];
    }

    // --- Internal Helper Functions ---

    /// @dev Internal function to get the total staked voting power in the collective.
    function _getTotalStakedVotingPower() internal view returns (uint256) {
        uint256 totalPower = 0;
        for (uint256 i = 1; i <= membershipNFTCount; i++) {
            if (membershipNFTs[i].exists && membershipNFTs[i].isStaked) {
                totalPower += getVotingPower(membershipNFTs[i].owner);
            }
        }
        return totalPower;
    }

    /// @dev Internal function to get the first staked Membership NFT token ID for a given address.
    ///      This is a simplified approach and assumes a member stakes only one NFT for voting.
    ///      In a more complex system, you might track staked NFTs in a mapping per address.
    function _getTokenIdForAddress(address _address) internal view returns (uint256) {
        for (uint256 i = 1; i <= membershipNFTCount; i++) {
            if (membershipNFTs[i].exists && membershipNFTs[i].owner == _address && membershipNFTs[i].isStaked) {
                return membershipNFTs[i].tokenId;
            }
        }
        return 0; // Returns 0 if no staked NFT is found for the address.
    }

    /// @dev Internal function to get the Art Submission Proposal ID by Art ID.
    function _getArtSubmissionProposalIdByArtId(uint256 _artId) internal view returns (uint256) {
        for (uint256 i = 1; i <= artSubmissionProposalCount; i++) {
            if (artSubmissionProposals[i].exists && artSubmissionProposals[i].artId == _artId && artSubmissionProposals[i].isActive) {
                return i;
            }
        }
        return 0; // Returns 0 if no active proposal found for the Art ID.
    }

    // --- Fallback and Receive ---
    receive() external payable {
        emit TreasuryDonationReceived(msg.sender, msg.value);
    }

    fallback() external {}
}
```