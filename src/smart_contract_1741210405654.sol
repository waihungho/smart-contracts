```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Collective (DAAC) Smart Contract
 * @author Bard (AI Assistant)
 * @dev A smart contract for a decentralized autonomous art collective.
 * It facilitates art submission, community curation through voting,
 * NFT minting for approved artworks, revenue sharing, dynamic membership,
 * and on-chain generative art capabilities. This contract aims to foster
 * a vibrant and community-driven art ecosystem on the blockchain.
 *
 * **Outline:**
 *
 * **Art Management:**
 *   1. submitArtProposal(string memory _title, string memory _description, string memory _ipfsHash) - Allows artists to submit art proposals.
 *   2. voteOnArtProposal(uint256 _proposalId, bool _vote) - Collective members vote on art proposals.
 *   3. getArtProposalDetails(uint256 _proposalId) - Retrieves details of a specific art proposal.
 *   4. mintArtNFT(uint256 _proposalId) - Mints an NFT for an approved art proposal, creating a unique digital artwork.
 *   5. burnArtNFT(uint256 _tokenId) - Allows governance to burn a specific Art NFT (in extreme cases, subject to community vote).
 *   6. getArtNFTDetails(uint256 _tokenId) - Retrieves details of a specific Art NFT.
 *   7. listArtForSale(uint256 _tokenId, uint256 _price) - Artists can list their minted Art NFTs for sale.
 *   8. buyArt(uint256 _tokenId) - Allows anyone to purchase listed Art NFTs.
 *   9. removeArtFromSale(uint256 _tokenId) - Artists can remove their Art NFTs from sale.
 *  10. generateOnChainArt(string memory _prompt) - (Advanced) Triggers on-chain generative art based on a prompt (simplified for example, conceptually demonstrates on-chain generation).
 *
 * **Collective Governance & Membership:**
 *  11. joinCollective() - Allows users to join the art collective (open membership or with conditions).
 *  12. leaveCollective() - Allows members to leave the collective.
 *  13. proposeNewRule(string memory _ruleDescription) - Members can propose new rules for the collective.
 *  14. voteOnRuleProposal(uint256 _proposalId, bool _vote) - Collective members vote on rule proposals.
 *  15. getRuleProposalDetails(uint256 _proposalId) - Retrieves details of a specific rule proposal.
 *  16. executeRuleProposal(uint256 _proposalId) - Executes an approved rule proposal (governance function).
 *  17. delegateVote(address _delegatee) - Allows members to delegate their voting power to another member.
 *  18. updateCollectiveMetadata(string memory _newName, string memory _newDescription) - Governance function to update collective information.
 *
 * **Treasury & Revenue Sharing:**
 *  19. depositToTreasury() - Allows anyone to deposit funds into the collective treasury.
 *  20. proposeTreasurySpending(address _recipient, uint256 _amount, string memory _reason) - Members can propose spending funds from the treasury.
 *  21. voteOnTreasurySpending(uint256 _proposalId, bool _vote) - Collective members vote on treasury spending proposals.
 *  22. getTreasurySpendingDetails(uint256 _proposalId) - Retrieves details of a treasury spending proposal.
 *  23. executeTreasurySpending(uint256 _proposalId) - Executes an approved treasury spending proposal (governance function).
 *  24. withdrawArtistEarnings() - Artists can withdraw their earnings from sold NFTs.
 *  25. getTreasuryBalance() - Retrieves the current balance of the collective treasury.
 *
 * **Events:**
 *   - ArtProposalSubmitted
 *   - ArtProposalVoted
 *   - ArtProposalApproved
 *   - ArtNFTMinted
 *   - ArtNFTBurned
 *   - ArtNFTListedForSale
 *   - ArtNFTSold
 *   - ArtNFTRemovedFromSale
 *   - GenerativeArtCreated
 *   - CollectiveMemberJoined
 *   - CollectiveMemberLeft
 *   - RuleProposalSubmitted
 *   - RuleProposalVoted
 *   - RuleProposalExecuted
 *   - VoteDelegated
 *   - CollectiveMetadataUpdated
 *   - TreasuryDeposit
 *   - TreasurySpendingProposed
 *   - TreasurySpendingVoted
 *   - TreasurySpendingExecuted
 *   - ArtistEarningsWithdrawn
 */

contract DecentralizedAutonomousArtCollective {

    // ** State Variables **

    string public collectiveName = "Decentralized Autonomous Art Collective";
    string public collectiveDescription = "A community-driven platform for digital art creation, curation, and appreciation.";

    address public governanceAddress; // Address with governance rights (e.g., a multi-sig or DAO itself)

    uint256 public nextArtProposalId = 1;
    uint256 public nextRuleProposalId = 1;
    uint256 public nextTreasurySpendingProposalId = 1;
    uint256 public nextArtTokenId = 1;

    uint256 public votingDuration = 7 days; // Default voting duration

    uint256 public artSaleFeePercentage = 5; // Percentage of sale price taken as collective fee (e.g., 5%)

    struct ArtProposal {
        uint256 proposalId;
        address artist;
        string title;
        string description;
        string ipfsHash;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 votingEndTime;
        bool proposalApproved;
        bool executed;
    }
    mapping(uint256 => ArtProposal) public artProposals;

    struct RuleProposal {
        uint256 proposalId;
        address proposer;
        string description;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 votingEndTime;
        bool proposalApproved;
        bool executed;
    }
    mapping(uint256 => RuleProposal) public ruleProposals;

    struct TreasurySpendingProposal {
        uint256 proposalId;
        address proposer;
        address recipient;
        uint256 amount;
        string reason;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 votingEndTime;
        bool proposalApproved;
        bool executed;
    }
    mapping(uint256 => TreasurySpendingProposal) public treasurySpendingProposals;

    struct ArtNFT {
        uint256 tokenId;
        uint256 proposalId;
        address artist;
        string title;
        string description;
        string ipfsHash;
        bool forSale;
        uint256 salePrice;
        address owner;
        uint256 earnings; // Accumulated earnings from sales for the artist
    }
    mapping(uint256 => ArtNFT) public artNFTs;

    mapping(address => bool) public isCollectiveMember;
    mapping(address => address) public voteDelegation; // Member -> Delegatee

    // ** Events **

    event ArtProposalSubmitted(uint256 proposalId, address artist, string title);
    event ArtProposalVoted(uint256 proposalId, address voter, bool vote);
    event ArtProposalApproved(uint256 proposalId);
    event ArtNFTMinted(uint256 tokenId, uint256 proposalId, address artist);
    event ArtNFTBurned(uint256 tokenId, address burner);
    event ArtNFTListedForSale(uint256 tokenId, uint256 price);
    event ArtNFTSold(uint256 tokenId, address buyer, address artist, uint256 price);
    event ArtNFTRemovedFromSale(uint256 tokenId);
    event GenerativeArtCreated(string prompt, string result); // Simplified for demonstration
    event CollectiveMemberJoined(address member);
    event CollectiveMemberLeft(address member);
    event RuleProposalSubmitted(uint256 proposalId, address proposer, string description);
    event RuleProposalVoted(uint256 proposalId, address voter, bool vote);
    event RuleProposalExecuted(uint256 proposalId);
    event VoteDelegated(address delegator, address delegatee);
    event CollectiveMetadataUpdated(string newName, string newDescription, address updater);
    event TreasuryDeposit(address depositor, uint256 amount);
    event TreasurySpendingProposed(uint256 proposalId, address proposer, address recipient, uint256 amount, string reason);
    event TreasurySpendingVoted(uint256 proposalId, address voter, bool vote);
    event TreasurySpendingExecuted(uint256 proposalId, address recipient, uint256 amount);
    event ArtistEarningsWithdrawn(address artist, uint256 amount);


    // ** Modifiers **

    modifier onlyCollectiveMember() {
        require(isCollectiveMember[msg.sender], "You are not a collective member.");
        _;
    }

    modifier onlyGovernance() {
        require(msg.sender == governanceAddress, "Only governance address can call this function.");
        _;
    }

    modifier validArtProposal(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId < nextArtProposalId, "Invalid art proposal ID.");
        _;
    }

    modifier validRuleProposal(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId < nextRuleProposalId, "Invalid rule proposal ID.");
        _;
    }

    modifier validTreasurySpendingProposal(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId < nextTreasurySpendingProposalId, "Invalid treasury spending proposal ID.");
        _;
    }

    modifier validArtNFT(uint256 _tokenId) {
        require(_tokenId > 0 && _tokenId < nextArtTokenId, "Invalid Art NFT token ID.");
        _;
    }

    modifier proposalNotExecuted(uint256 _proposalId) {
        require(!artProposals[_proposalId].executed, "Proposal already executed.");
        _;
    }

    modifier ruleProposalNotExecuted(uint256 _proposalId) {
        require(!ruleProposals[_proposalId].executed, "Rule proposal already executed.");
        _;
    }

    modifier treasuryProposalNotExecuted(uint256 _proposalId) {
        require(!treasurySpendingProposals[_proposalId].executed, "Treasury proposal already executed.");
        _;
    }

    modifier votingPeriodActive(uint256 _endTime) {
        require(block.timestamp <= _endTime, "Voting period has ended.");
        _;
    }


    // ** Constructor **

    constructor() {
        governanceAddress = msg.sender; // Deployer is initial governance
    }

    // ** Art Management Functions **

    /// @notice Allows artists to submit art proposals for consideration by the collective.
    /// @param _title Title of the artwork proposal.
    /// @param _description Detailed description of the artwork.
    /// @param _ipfsHash IPFS hash pointing to the artwork's digital asset.
    function submitArtProposal(string memory _title, string memory _description, string memory _ipfsHash) public onlyCollectiveMember {
        require(bytes(_title).length > 0 && bytes(_description).length > 0 && bytes(_ipfsHash).length > 0, "Art proposal details cannot be empty.");

        artProposals[nextArtProposalId] = ArtProposal({
            proposalId: nextArtProposalId,
            artist: msg.sender,
            title: _title,
            description: _description,
            ipfsHash: _ipfsHash,
            votesFor: 0,
            votesAgainst: 0,
            votingEndTime: block.timestamp + votingDuration,
            proposalApproved: false,
            executed: false
        });

        emit ArtProposalSubmitted(nextArtProposalId, msg.sender, _title);
        nextArtProposalId++;
    }

    /// @notice Allows collective members to vote on an active art proposal.
    /// @param _proposalId ID of the art proposal to vote on.
    /// @param _vote True for 'for' vote, false for 'against' vote.
    function voteOnArtProposal(uint256 _proposalId, bool _vote) public onlyCollectiveMember validArtProposal(_proposalId) proposalNotExecuted(_proposalId) votingPeriodActive(artProposals[_proposalId].votingEndTime) {
        require(artProposals[_proposalId].artist != msg.sender, "Artist cannot vote on their own proposal.");

        address voter = voteDelegation[msg.sender] != address(0) ? voteDelegation[msg.sender] : msg.sender; // Use delegated vote if set

        // In a real DAO, voting power might be weighted based on token holdings or reputation.
        // Here, it's a simple 1-member 1-vote system.

        if (_vote) {
            artProposals[_proposalId].votesFor++;
        } else {
            artProposals[_proposalId].votesAgainst++;
        }

        emit ArtProposalVoted(_proposalId, voter, _vote);
    }

    /// @notice Retrieves detailed information about a specific art proposal.
    /// @param _proposalId ID of the art proposal.
    /// @return ArtProposal struct containing proposal details.
    function getArtProposalDetails(uint256 _proposalId) public view validArtProposal(_proposalId) returns (ArtProposal memory) {
        return artProposals[_proposalId];
    }

    /// @notice Mints an Art NFT for an approved art proposal, callable after voting concludes and proposal is approved.
    /// @param _proposalId ID of the approved art proposal.
    function mintArtNFT(uint256 _proposalId) public onlyGovernance validArtProposal(_proposalId) proposalNotExecuted(_proposalId) {
        require(block.timestamp > artProposals[_proposalId].votingEndTime, "Voting period is still active.");
        require(artProposals[_proposalId].votesFor > artProposals[_proposalId].votesAgainst, "Art proposal not approved by majority.");
        require(!artProposals[_proposalId].proposalApproved, "Art proposal already approved and NFT minted.");

        artProposals[_proposalId].proposalApproved = true;
        artProposals[_proposalId].executed = true; // Mark proposal as executed

        ArtProposal storage proposal = artProposals[_proposalId];

        artNFTs[nextArtTokenId] = ArtNFT({
            tokenId: nextArtTokenId,
            proposalId: _proposalId,
            artist: proposal.artist,
            title: proposal.title,
            description: proposal.description,
            ipfsHash: proposal.ipfsHash,
            forSale: false,
            salePrice: 0,
            owner: proposal.artist, // Initially owned by the artist
            earnings: 0
        });

        emit ArtNFTMinted(nextArtTokenId, _proposalId, proposal.artist);
        nextArtTokenId++;
        emit ArtProposalApproved(_proposalId);
    }

    /// @notice Allows governance to burn a specific Art NFT, subject to community consensus in real applications.
    /// @param _tokenId ID of the Art NFT to burn.
    function burnArtNFT(uint256 _tokenId) public onlyGovernance validArtNFT(_tokenId) {
        address burner = msg.sender;
        delete artNFTs[_tokenId]; // Effectively burns the NFT in this simplified context.
        emit ArtNFTBurned(_tokenId, burner);
    }

    /// @notice Retrieves detailed information about a specific Art NFT.
    /// @param _tokenId ID of the Art NFT.
    /// @return ArtNFT struct containing NFT details.
    function getArtNFTDetails(uint256 _tokenId) public view validArtNFT(_tokenId) returns (ArtNFT memory) {
        return artNFTs[_tokenId];
    }

    /// @notice Allows the artist to list their minted Art NFT for sale.
    /// @param _tokenId ID of the Art NFT to list.
    /// @param _price Sale price in Wei.
    function listArtForSale(uint256 _tokenId, uint256 _price) public validArtNFT(_tokenId) {
        require(artNFTs[_tokenId].owner == msg.sender, "Only the NFT owner (artist) can list it for sale.");
        require(_price > 0, "Sale price must be greater than zero.");
        artNFTs[_tokenId].forSale = true;
        artNFTs[_tokenId].salePrice = _price;
        emit ArtNFTListedForSale(_tokenId, _price);
    }

    /// @notice Allows anyone to purchase a listed Art NFT.
    /// @param _tokenId ID of the Art NFT to buy.
    function buyArt(uint256 _tokenId) public payable validArtNFT(_tokenId) {
        require(artNFTs[_tokenId].forSale, "Art NFT is not for sale.");
        require(msg.value >= artNFTs[_tokenId].salePrice, "Insufficient funds sent.");

        ArtNFT storage nft = artNFTs[_tokenId];
        address artist = nft.artist;
        uint256 salePrice = nft.salePrice;

        nft.forSale = false;
        nft.owner = msg.sender;
        nft.earnings += (salePrice * (100 - artSaleFeePercentage)) / 100; // Artist earnings (after fee)

        uint256 collectiveFee = (salePrice * artSaleFeePercentage) / 100;
        payable(governanceAddress).transfer(collectiveFee); // Fee to collective treasury

        emit ArtNFTSold(_tokenId, msg.sender, artist, salePrice);

        // Refund any excess ETH sent
        if (msg.value > salePrice) {
            payable(msg.sender).transfer(msg.value - salePrice);
        }
    }

    /// @notice Allows the artist to remove their Art NFT from sale.
    /// @param _tokenId ID of the Art NFT to remove from sale.
    function removeArtFromSale(uint256 _tokenId) public validArtNFT(_tokenId) {
        require(artNFTs[_tokenId].owner == msg.sender, "Only the NFT owner (artist) can remove it from sale.");
        artNFTs[_tokenId].forSale = false;
        emit ArtNFTRemovedFromSale(_tokenId);
    }

    /// @notice (Advanced - Conceptual) Demonstrates on-chain generative art based on a prompt.
    /// @dev In reality, on-chain generative art is computationally intensive and complex.
    ///      This is a simplified example to illustrate the concept.
    /// @param _prompt Text prompt for generative art.
    function generateOnChainArt(string memory _prompt) public onlyCollectiveMember {
        // ** Simplified On-Chain "Generative Art" Logic **
        // In a real application, this would involve:
        // 1. Integration with on-chain oracles/services for random number generation (if needed).
        // 2. Complex algorithms and data structures for image/art generation (very gas intensive).
        // 3. Potentially using external libraries via precompiles (if available and feasible).

        // For this example, we just create a placeholder "art" based on the prompt.
        string memory result = string(abi.encodePacked("Generated Art based on prompt: ", _prompt, " - [Placeholder Representation]"));

        emit GenerativeArtCreated(_prompt, result);
        // In a more advanced version, this might mint an NFT directly with the generated art.
    }


    // ** Collective Governance & Membership Functions **

    /// @notice Allows users to join the art collective. (Open membership for this example).
    function joinCollective() public {
        require(!isCollectiveMember[msg.sender], "Already a collective member.");
        isCollectiveMember[msg.sender] = true;
        emit CollectiveMemberJoined(msg.sender);
    }

    /// @notice Allows members to leave the collective.
    function leaveCollective() public onlyCollectiveMember {
        isCollectiveMember[msg.sender] = false;
        emit CollectiveMemberLeft(msg.sender);
    }

    /// @notice Allows collective members to propose new rules for the collective.
    /// @param _ruleDescription Description of the proposed rule.
    function proposeNewRule(string memory _ruleDescription) public onlyCollectiveMember {
        require(bytes(_ruleDescription).length > 0, "Rule description cannot be empty.");

        ruleProposals[nextRuleProposalId] = RuleProposal({
            proposalId: nextRuleProposalId,
            proposer: msg.sender,
            description: _ruleDescription,
            votesFor: 0,
            votesAgainst: 0,
            votingEndTime: block.timestamp + votingDuration,
            proposalApproved: false,
            executed: false
        });

        emit RuleProposalSubmitted(nextRuleProposalId, msg.sender, _ruleDescription);
        nextRuleProposalId++;
    }

    /// @notice Allows collective members to vote on an active rule proposal.
    /// @param _proposalId ID of the rule proposal to vote on.
    /// @param _vote True for 'for' vote, false for 'against' vote.
    function voteOnRuleProposal(uint256 _proposalId, bool _vote) public onlyCollectiveMember validRuleProposal(_proposalId) ruleProposalNotExecuted(_proposalId) votingPeriodActive(ruleProposals[_proposalId].votingEndTime) {
        address voter = voteDelegation[msg.sender] != address(0) ? voteDelegation[msg.sender] : msg.sender; // Use delegated vote if set

        if (_vote) {
            ruleProposals[_proposalId].votesFor++;
        } else {
            ruleProposals[_proposalId].votesAgainst++;
        }

        emit RuleProposalVoted(_proposalId, voter, _vote);
    }

    /// @notice Retrieves details of a specific rule proposal.
    /// @param _proposalId ID of the rule proposal.
    /// @return RuleProposal struct containing proposal details.
    function getRuleProposalDetails(uint256 _proposalId) public view validRuleProposal(_proposalId) returns (RuleProposal memory) {
        return ruleProposals[_proposalId];
    }

    /// @notice Executes an approved rule proposal, callable by governance after voting and approval.
    /// @param _proposalId ID of the approved rule proposal.
    function executeRuleProposal(uint256 _proposalId) public onlyGovernance validRuleProposal(_proposalId) ruleProposalNotExecuted(_proposalId) {
        require(block.timestamp > ruleProposals[_proposalId].votingEndTime, "Voting period is still active.");
        require(ruleProposals[_proposalId].votesFor > ruleProposals[_proposalId].votesAgainst, "Rule proposal not approved by majority.");
        require(!ruleProposals[_proposalId].proposalApproved, "Rule proposal already approved and executed.");

        ruleProposals[_proposalId].proposalApproved = true;
        ruleProposals[_proposalId].executed = true; // Mark proposal as executed

        emit RuleProposalExecuted(_proposalId);
        // Implement the actual rule change logic here if needed.
        // Some rules might be automatically enforced in code, others might require manual actions.
    }

    /// @notice Allows a member to delegate their voting power to another collective member.
    /// @param _delegatee Address of the member to delegate votes to.
    function delegateVote(address _delegatee) public onlyCollectiveMember {
        require(isCollectiveMember[_delegatee], "Delegatee must be a collective member.");
        require(_delegatee != msg.sender, "Cannot delegate to yourself.");
        voteDelegation[msg.sender] = _delegatee;
        emit VoteDelegated(msg.sender, _delegatee);
    }

    /// @notice Allows governance to update the collective's name and description.
    /// @param _newName New name for the collective.
    /// @param _newDescription New description for the collective.
    function updateCollectiveMetadata(string memory _newName, string memory _newDescription) public onlyGovernance {
        require(bytes(_newName).length > 0 && bytes(_newDescription).length > 0, "Collective name and description cannot be empty.");
        collectiveName = _newName;
        collectiveDescription = _newDescription;
        emit CollectiveMetadataUpdated(_newName, _newDescription, msg.sender);
    }


    // ** Treasury & Revenue Sharing Functions **

    /// @notice Allows anyone to deposit ETH into the collective treasury.
    function depositToTreasury() public payable {
        emit TreasuryDeposit(msg.sender, msg.value);
    }

    /// @notice Allows collective members to propose spending funds from the treasury.
    /// @param _recipient Address to receive the funds.
    /// @param _amount Amount to spend in Wei.
    /// @param _reason Reason for spending.
    function proposeTreasurySpending(address _recipient, uint256 _amount, string memory _reason) public onlyCollectiveMember {
        require(_recipient != address(0), "Recipient address cannot be zero.");
        require(_amount > 0, "Spending amount must be greater than zero.");
        require(bytes(_reason).length > 0, "Spending reason cannot be empty.");

        treasurySpendingProposals[nextTreasurySpendingProposalId] = TreasurySpendingProposal({
            proposalId: nextTreasurySpendingProposalId,
            proposer: msg.sender,
            recipient: _recipient,
            amount: _amount,
            reason: _reason,
            votesFor: 0,
            votesAgainst: 0,
            votingEndTime: block.timestamp + votingDuration,
            proposalApproved: false,
            executed: false
        });

        emit TreasurySpendingProposed(nextTreasurySpendingProposalId, msg.sender, _recipient, _amount, _reason);
        nextTreasurySpendingProposalId++;
    }

    /// @notice Allows collective members to vote on an active treasury spending proposal.
    /// @param _proposalId ID of the treasury spending proposal to vote on.
    /// @param _vote True for 'for' vote, false for 'against' vote.
    function voteOnTreasurySpending(uint256 _proposalId, bool _vote) public onlyCollectiveMember validTreasurySpendingProposal(_proposalId) treasuryProposalNotExecuted(_proposalId) votingPeriodActive(treasurySpendingProposals[_proposalId].votingEndTime) {
        address voter = voteDelegation[msg.sender] != address(0) ? voteDelegation[msg.sender] : msg.sender; // Use delegated vote if set

        if (_vote) {
            treasurySpendingProposals[_proposalId].votesFor++;
        } else {
            treasurySpendingProposals[_proposalId].votesAgainst++;
        }

        emit TreasurySpendingVoted(_proposalId, voter, _vote);
    }

    /// @notice Retrieves details of a specific treasury spending proposal.
    /// @param _proposalId ID of the treasury spending proposal.
    /// @return TreasurySpendingProposal struct containing proposal details.
    function getTreasurySpendingDetails(uint256 _proposalId) public view validTreasurySpendingProposal(_proposalId) returns (TreasurySpendingProposal memory) {
        return treasurySpendingProposals[_proposalId];
    }

    /// @notice Executes an approved treasury spending proposal, callable by governance after voting and approval.
    /// @param _proposalId ID of the approved treasury spending proposal.
    function executeTreasurySpending(uint256 _proposalId) public onlyGovernance validTreasurySpendingProposal(_proposalId) treasuryProposalNotExecuted(_proposalId) {
        require(block.timestamp > treasurySpendingProposals[_proposalId].votingEndTime, "Voting period is still active.");
        require(treasurySpendingProposals[_proposalId].votesFor > treasurySpendingProposals[_proposalId].votesAgainst, "Treasury spending proposal not approved by majority.");
        require(!treasurySpendingProposals[_proposalId].proposalApproved, "Treasury spending proposal already approved and executed.");

        treasurySpendingProposals[_proposalId].proposalApproved = true;
        treasurySpendingProposals[_proposalId].executed = true; // Mark proposal as executed

        TreasurySpendingProposal storage proposal = treasurySpendingProposals[_proposalId];
        payable(proposal.recipient).transfer(proposal.amount);
        emit TreasurySpendingExecuted(_proposalId, proposal.recipient, proposal.amount);
    }

    /// @notice Allows artists to withdraw their accumulated earnings from sold NFTs.
    function withdrawArtistEarnings() public onlyCollectiveMember {
        uint256 totalEarnings = 0;
        for (uint256 i = 1; i < nextArtTokenId; i++) {
            if (artNFTs[i].artist == msg.sender) {
                totalEarnings += artNFTs[i].earnings;
                artNFTs[i].earnings = 0; // Reset earnings after withdrawal
            }
        }
        require(totalEarnings > 0, "No earnings to withdraw.");
        payable(msg.sender).transfer(totalEarnings);
        emit ArtistEarningsWithdrawn(msg.sender, totalEarnings);
    }

    /// @notice Retrieves the current balance of the collective treasury.
    /// @return Treasury balance in Wei.
    function getTreasuryBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // ** Fallback and Receive Functions (Optional) **
    receive() external payable {} // To accept ETH deposits directly to the contract
    fallback() external {}
}
```