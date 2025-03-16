```solidity
/**
 * @title Decentralized Autonomous Art Collective (DAAC)
 * @author Bard (AI Assistant)
 * @dev A smart contract for a Decentralized Autonomous Art Collective (DAAC).
 *      This contract allows artists to submit art proposals, community members to vote on them,
 *      mint NFTs for approved art, manage a treasury from art sales, and implement
 *      various creative functions related to art curation, contests, and community engagement.
 *
 * **Outline & Function Summary:**
 *
 * **Core Art Management:**
 * 1. `submitArtProposal(string _title, string _description, string _ipfsHash)`: Allows artists to submit art proposals.
 * 2. `voteOnArtProposal(uint256 _proposalId, bool _vote)`: Collective members vote on art proposals.
 * 3. `mintArtNFT(uint256 _proposalId)`: Mints an NFT for an approved art proposal.
 * 4. `purchaseArtNFT(uint256 _tokenId)`: Allows users to purchase art NFTs.
 * 5. `transferArtNFT(address _to, uint256 _tokenId)`: Standard NFT transfer function.
 * 6. `setArtPrice(uint256 _tokenId, uint256 _newPrice)`: Allows governance to set or change the price of an art NFT.
 * 7. `burnArtNFT(uint256 _tokenId)`: Allows governance to burn an art NFT (e.g., for inappropriate content - with governance vote).
 * 8. `curateFeaturedArt(uint256 _tokenId)`: Allows governance to feature a specific art NFT.
 * 9. `removeFeaturedArt(uint256 _tokenId)`: Allows governance to remove a featured art NFT.
 * 10. `getArtProposalDetails(uint256 _proposalId)`: View details of an art proposal.
 * 11. `getArtNFTDetails(uint256 _tokenId)`: View details of an art NFT.
 * 12. `getTotalArtPieces()`: Returns the total number of art NFTs minted.
 *
 * **Community & Governance:**
 * 13. `joinCollective()`: Allows users to join the art collective.
 * 14. `leaveCollective()`: Allows members to leave the collective.
 * 15. `proposeGovernanceChange(string _description, bytes _calldata)`: Allows members to propose governance changes.
 * 16. `voteOnGovernanceChange(uint256 _proposalId, bool _vote)`: Collective members vote on governance proposals.
 * 17. `executeGovernanceChange(uint256 _proposalId)`: Executes a governance change proposal after successful voting.
 * 18. `rewardActiveMembers()`:  A mechanism to reward active collective members (e.g., based on voting participation - needs further logic implementation).
 * 19. `createArtContest(string _contestName, string _contestDescription, uint256 _startTime, uint256 _endTime)`:  Create an art contest within the collective.
 * 20. `submitArtToContest(uint256 _contestId, uint256 _proposalId)`: Submit an already proposed art to an active contest.
 * 21. `voteForContestArt(uint256 _contestId, uint256 _proposalId)`: Collective members vote for art in a contest.
 * 22. `finalizeArtContest(uint256 _contestId)`: Finalize an art contest, select winners (needs winner selection logic).
 *
 * **Treasury & Revenue:**
 * 23. `getCollectiveBalance()`: Returns the current balance of the collective treasury.
 * 24. `withdrawFunds(address _recipient, uint256 _amount)`: Allows governance to withdraw funds from the treasury.
 * 25. `splitRevenueWithArtist(uint256 _tokenId)`: Distributes a percentage of the sale revenue to the original artist (upon initial NFT sale).
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract DecentralizedAutonomousArtCollective is ERC721, Ownable {
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.AddressSet;

    Counters.Counter private _artProposalIds;
    Counters.Counter private _artTokenIds;
    Counters.Counter private _governanceProposalIds;
    Counters.Counter private _contestIds;

    // Structs
    struct ArtProposal {
        uint256 id;
        address artist;
        string title;
        string description;
        string ipfsHash;
        uint256 votesFor;
        uint256 votesAgainst;
        bool isActive;
        bool isApproved;
    }

    struct ArtNFT {
        uint256 tokenId;
        uint256 proposalId;
        address artist;
        uint256 price;
        bool isFeatured;
    }

    struct GovernanceProposal {
        uint256 id;
        address proposer;
        string description;
        bytes calldataToExecute;
        uint256 votesFor;
        uint256 votesAgainst;
        bool isActive;
        bool isExecuted;
    }

    struct ArtContest {
        uint256 id;
        string name;
        string description;
        uint256 startTime;
        uint256 endTime;
        bool isActive;
        uint256 winningProposalId; // To store the winning proposal ID after contest ends
    }


    // Mappings
    mapping(uint256 => ArtProposal) public artProposals;
    mapping(uint256 => ArtNFT) public artNFTs;
    mapping(uint256 => GovernanceProposal) public governanceProposals;
    mapping(uint256 => ArtContest) public artContests;
    mapping(uint256 => mapping(address => bool)) public artProposalVotes; // proposalId => voter => vote
    mapping(uint256 => mapping(address => bool)) public governanceProposalVotes; // proposalId => voter => vote
    mapping(uint256 => mapping(address => bool)) public contestArtVotes; // contestId => proposalId => voter => vote

    EnumerableSet.AddressSet private collectiveMembers;

    uint256 public votingDuration = 7 days; // Default voting duration
    uint256 public governanceQuorum = 50; // Percentage quorum for governance proposals (e.g., 50%)
    uint256 public artApprovalThreshold = 60; // Percentage approval threshold for art proposals (e.g., 60%)
    uint256 public artistRevenueSharePercentage = 10; // Percentage of initial sale revenue for artist

    // Events
    event ArtProposalSubmitted(uint256 proposalId, address artist, string title);
    event ArtProposalVoted(uint256 proposalId, address voter, bool vote);
    event ArtProposalApproved(uint256 proposalId);
    event ArtNFTMinted(uint256 tokenId, uint256 proposalId, address artist);
    event ArtNFTPurchased(uint256 tokenId, address buyer, uint256 price);
    event ArtNFTPriceSet(uint256 tokenId, uint256 newPrice);
    event ArtNFTBurned(uint256 tokenId);
    event ArtNFTFeatured(uint256 tokenId);
    event ArtNFTUnfeatured(uint256 tokenId);
    event GovernanceProposalCreated(uint256 proposalId, address proposer, string description);
    event GovernanceProposalVoted(uint256 proposalId, address voter, bool vote);
    event GovernanceProposalExecuted(uint256 proposalId);
    event CollectiveMemberJoined(address member);
    event CollectiveMemberLeft(address member);
    event ArtContestCreated(uint256 contestId, string name);
    event ArtSubmittedToContest(uint256 contestId, uint256 proposalId);
    event ContestArtVoted(uint256 contestId, uint256 proposalId, address voter, bool vote);
    event ArtContestFinalized(uint256 contestId, uint256 winningProposalId);
    event FundsWithdrawn(address recipient, uint256 amount);
    event RevenueSplitWithArtist(uint256 tokenId, address artist, uint256 amount);


    // Modifiers
    modifier onlyCollectiveMember() {
        require(isCollectiveMember(msg.sender), "Not a collective member");
        _;
    }

    modifier onlyGovernance() {
        require(msg.sender == owner(), "Only governance (contract owner) can call this function"); // Simple owner-based governance for example. Can be expanded.
        _;
    }

    modifier onlyActiveProposal(uint256 _proposalId) {
        require(artProposals[_proposalId].isActive, "Proposal is not active");
        _;
    }

    modifier onlyActiveContest(uint256 _contestId) {
        require(artContests[_contestId].isActive, "Contest is not active");
        _;
    }

    constructor() ERC721("Decentralized Art Collective", "DAC") {}

    // ----------------------- Core Art Management -----------------------

    /**
     * @dev Allows artists to submit art proposals.
     * @param _title Title of the artwork.
     * @param _description Description of the artwork.
     * @param _ipfsHash IPFS hash of the artwork's media.
     */
    function submitArtProposal(string memory _title, string memory _description, string memory _ipfsHash) public onlyCollectiveMember {
        _artProposalIds.increment();
        uint256 proposalId = _artProposalIds.current();
        artProposals[proposalId] = ArtProposal({
            id: proposalId,
            artist: msg.sender,
            title: _title,
            description: _description,
            ipfsHash: _ipfsHash,
            votesFor: 0,
            votesAgainst: 0,
            isActive: true,
            isApproved: false
        });
        emit ArtProposalSubmitted(proposalId, msg.sender, _title);
    }

    /**
     * @dev Collective members vote on art proposals.
     * @param _proposalId ID of the art proposal.
     * @param _vote True for 'for', false for 'against'.
     */
    function voteOnArtProposal(uint256 _proposalId, bool _vote) public onlyCollectiveMember onlyActiveProposal(_proposalId) {
        require(!artProposalVotes[_proposalId][msg.sender], "Already voted on this proposal");
        artProposalVotes[_proposalId][msg.sender] = true; // Record the vote

        if (_vote) {
            artProposals[_proposalId].votesFor++;
        } else {
            artProposals[_proposalId].votesAgainst++;
        }
        emit ArtProposalVoted(_proposalId, msg.sender, _vote);

        // Check if voting period is over (simplified - could use block.timestamp for more precise timing)
        if (block.number % 10 == 0) { // Example: Check every 10 blocks to simulate voting period end. Replace with actual time-based mechanism in real implementation.
            _finalizeArtProposalVoting(_proposalId);
        }
    }

    /**
     * @dev Internal function to finalize art proposal voting and approve if threshold is met.
     * @param _proposalId ID of the art proposal.
     */
    function _finalizeArtProposalVoting(uint256 _proposalId) internal onlyActiveProposal(_proposalId) {
        artProposals[_proposalId].isActive = false; // Deactivate the proposal

        uint256 totalVotes = artProposals[_proposalId].votesFor + artProposals[_proposalId].votesAgainst;
        if (totalVotes > 0) {
            uint256 approvalPercentage = (artProposals[_proposalId].votesFor * 100) / totalVotes;
            if (approvalPercentage >= artApprovalThreshold) {
                artProposals[_proposalId].isApproved = true;
                emit ArtProposalApproved(_proposalId);
            }
        }
    }

    /**
     * @dev Mints an NFT for an approved art proposal.
     * @param _proposalId ID of the approved art proposal.
     */
    function mintArtNFT(uint256 _proposalId) public onlyGovernance { // Governance controlled minting for now, could be automated after approval
        require(artProposals[_proposalId].isApproved, "Art proposal not approved");
        require(!artProposals[_proposalId].isActive, "Art proposal is still active"); // Ensure proposal is finalized
        require(artNFTs[_proposalId].tokenId == 0, "NFT already minted for this proposal"); // Prevent duplicate minting

        _artTokenIds.increment();
        uint256 tokenId = _artTokenIds.current();

        _safeMint(address(this), tokenId); // Mint to the contract initially, can be transferred to artist later or sold directly.
        artNFTs[tokenId] = ArtNFT({
            tokenId: tokenId,
            proposalId: _proposalId,
            artist: artProposals[_proposalId].artist,
            price: 0.1 ether, // Default initial price
            isFeatured: false
        });
        emit ArtNFTMinted(tokenId, _proposalId, artProposals[_proposalId].artist);
    }

    /**
     * @dev Allows users to purchase art NFTs.
     * @param _tokenId ID of the art NFT to purchase.
     */
    function purchaseArtNFT(uint256 _tokenId) public payable {
        require(artNFTs[_tokenId].tokenId != 0, "Art NFT does not exist");
        require(msg.value >= artNFTs[_tokenId].price, "Insufficient funds sent");

        address artist = artNFTs[_tokenId].artist;
        uint256 salePrice = artNFTs[_tokenId].price;

        // Transfer revenue to collective treasury (owner of contract)
        payable(owner()).transfer(salePrice);

        // Split revenue with artist (example - 10% to artist)
        uint256 artistShare = (salePrice * artistRevenueSharePercentage) / 100;
        payable(artist).transfer(artistShare);
        emit RevenueSplitWithArtist(_tokenId, artist, artistShare);

        // Transfer NFT to buyer
        _transfer(address(this), msg.sender, _tokenId);
        emit ArtNFTPurchased(_tokenId, msg.sender, salePrice);
    }

    /**
     * @dev Standard NFT transfer function.
     * @param _to Address to transfer the NFT to.
     * @param _tokenId ID of the art NFT to transfer.
     */
    function transferArtNFT(address _to, uint256 _tokenId) public payable {
        safeTransferFrom(msg.sender, _to, _tokenId);
    }

    /**
     * @dev Allows governance to set or change the price of an art NFT.
     * @param _tokenId ID of the art NFT.
     * @param _newPrice New price for the art NFT.
     */
    function setArtPrice(uint256 _tokenId, uint256 _newPrice) public onlyGovernance {
        require(artNFTs[_tokenId].tokenId != 0, "Art NFT does not exist");
        artNFTs[_tokenId].price = _newPrice;
        emit ArtNFTPriceSet(_tokenId, _tokenId, _newPrice);
    }

    /**
     * @dev Allows governance to burn an art NFT (e.g., for inappropriate content - with governance vote - implementation not included here).
     * @param _tokenId ID of the art NFT to burn.
     */
    function burnArtNFT(uint256 _tokenId) public onlyGovernance { // In real scenario, add governance vote before burning.
        require(artNFTs[_tokenId].tokenId != 0, "Art NFT does not exist");
        _burn(_tokenId);
        emit ArtNFTBurned(_tokenId);
    }

    /**
     * @dev Allows governance to feature a specific art NFT.
     * @param _tokenId ID of the art NFT to feature.
     */
    function curateFeaturedArt(uint256 _tokenId) public onlyGovernance {
        require(artNFTs[_tokenId].tokenId != 0, "Art NFT does not exist");
        artNFTs[_tokenId].isFeatured = true;
        emit ArtNFTFeatured(_tokenId);
    }

    /**
     * @dev Allows governance to remove a featured art NFT.
     * @param _tokenId ID of the art NFT to unfeature.
     */
    function removeFeaturedArt(uint256 _tokenId) public onlyGovernance {
        require(artNFTs[_tokenId].tokenId != 0, "Art NFT does not exist");
        artNFTs[_tokenId].isFeatured = false;
        emit ArtNFTUnfeatured(_tokenId);
    }

    /**
     * @dev View details of an art proposal.
     * @param _proposalId ID of the art proposal.
     * @return ArtProposal struct containing proposal details.
     */
    function getArtProposalDetails(uint256 _proposalId) public view returns (ArtProposal memory) {
        return artProposals[_proposalId];
    }

    /**
     * @dev View details of an art NFT.
     * @param _tokenId ID of the art NFT.
     * @return ArtNFT struct containing NFT details.
     */
    function getArtNFTDetails(uint256 _tokenId) public view returns (ArtNFT memory) {
        return artNFTs[_tokenId];
    }

    /**
     * @dev Returns the total number of art NFTs minted.
     * @return uint256 Total art NFT count.
     */
    function getTotalArtPieces() public view returns (uint256) {
        return _artTokenIds.current();
    }


    // ----------------------- Community & Governance -----------------------

    /**
     * @dev Allows users to join the art collective.
     */
    function joinCollective() public {
        require(!isCollectiveMember(msg.sender), "Already a collective member");
        collectiveMembers.add(msg.sender);
        emit CollectiveMemberJoined(msg.sender);
    }

    /**
     * @dev Allows members to leave the collective.
     */
    function leaveCollective() public onlyCollectiveMember {
        collectiveMembers.remove(msg.sender);
        emit CollectiveMemberLeft(msg.sender);
    }

    /**
     * @dev Checks if an address is a collective member.
     * @param _address Address to check.
     * @return bool True if member, false otherwise.
     */
    function isCollectiveMember(address _address) public view returns (bool) {
        return collectiveMembers.contains(_address);
    }

    /**
     * @dev Allows members to propose governance changes.
     * @param _description Description of the governance change proposal.
     * @param _calldata Calldata to execute if proposal passes.
     */
    function proposeGovernanceChange(string memory _description, bytes memory _calldata) public onlyCollectiveMember {
        _governanceProposalIds.increment();
        uint256 proposalId = _governanceProposalIds.current();
        governanceProposals[proposalId] = GovernanceProposal({
            id: proposalId,
            proposer: msg.sender,
            description: _description,
            calldataToExecute: _calldata,
            votesFor: 0,
            votesAgainst: 0,
            isActive: true,
            isExecuted: false
        });
        emit GovernanceProposalCreated(proposalId, msg.sender, _description);
    }

    /**
     * @dev Collective members vote on governance proposals.
     * @param _proposalId ID of the governance proposal.
     * @param _vote True for 'for', false for 'against'.
     */
    function voteOnGovernanceChange(uint256 _proposalId, bool _vote) public onlyCollectiveMember {
        require(governanceProposals[_proposalId].isActive, "Governance proposal is not active");
        require(!governanceProposalVotes[_proposalId][msg.sender], "Already voted on this governance proposal");
        governanceProposalVotes[_proposalId][msg.sender] = true;

        if (_vote) {
            governanceProposals[_proposalId].votesFor++;
        } else {
            governanceProposals[_proposalId].votesAgainst++;
        }
        emit GovernanceProposalVoted(_proposalId, msg.sender, _vote);

        // Check for governance proposal finalization (simplified - same as art proposal for example)
        if (block.number % 10 == 0) {
            _finalizeGovernanceProposalVoting(_proposalId);
        }
    }

    /**
     * @dev Internal function to finalize governance proposal voting and execute if quorum and approval are met.
     * @param _proposalId ID of the governance proposal.
     */
    function _finalizeGovernanceProposalVoting(uint256 _proposalId) internal {
        governanceProposals[_proposalId].isActive = false; // Deactivate the proposal

        uint256 totalMembers = collectiveMembers.length();
        uint256 totalVotes = governanceProposals[_proposalId].votesFor + governanceProposals[_proposalId].votesAgainst;

        if (totalMembers > 0 && totalVotes > 0) {
            uint256 quorumReachedPercentage = (totalVotes * 100) / totalMembers;
            uint256 approvalPercentage = (governanceProposals[_proposalId].votesFor * 100) / totalVotes;

            if (quorumReachedPercentage >= governanceQuorum && approvalPercentage > 50) { // Simple majority for governance execution
                executeGovernanceChange(_proposalId); // Execute automatically if passed
            }
        }
    }

    /**
     * @dev Executes a governance change proposal after successful voting.
     * @param _proposalId ID of the governance proposal to execute.
     */
    function executeGovernanceChange(uint256 _proposalId) public onlyGovernance { // Governance can execute (or could be timelock for more security)
        require(governanceProposals[_proposalId].isActive == false, "Governance proposal is still active");
        require(governanceProposals[_proposalId].isExecuted == false, "Governance proposal already executed");
        governanceProposals[_proposalId].isExecuted = true;

        (bool success, ) = address(this).call(governanceProposals[_proposalId].calldataToExecute); // Execute the calldata
        require(success, "Governance proposal execution failed");
        emit GovernanceProposalExecuted(_proposalId);
    }

    /**
     * @dev Placeholder function to reward active members (logic needs to be implemented based on criteria).
     *      Example: Could reward members based on voting participation, art submissions, etc.
     */
    function rewardActiveMembers() public onlyGovernance {
        // TODO: Implement logic to reward active members based on participation criteria.
        // Example: Distribute a small amount of ETH to members who voted in the most recent governance proposals.
        // This is a complex function and requires careful design to prevent abuse and ensure fairness.
        // For now, leaving as a placeholder to demonstrate an advanced function concept.
        // Example approach: Track voting participation, calculate rewards proportionally, and distribute.
        // ... (Implementation needed based on specific rewarding strategy) ...
        // For now, just emitting an event as a placeholder
        emit FundsWithdrawn(address(0), 0); // Placeholder event to indicate function called. Replace with actual reward distribution logic.
        // require(false, "Reward active members logic not implemented yet."); // Placeholder - remove in actual implementation.
    }


    /**
     * @dev Creates an art contest within the collective.
     * @param _contestName Name of the contest.
     * @param _contestDescription Description of the contest.
     * @param _startTime Start time of the contest (timestamp).
     * @param _endTime End time of the contest (timestamp).
     */
    function createArtContest(string memory _contestName, string memory _contestDescription, uint256 _startTime, uint256 _endTime) public onlyGovernance {
        _contestIds.increment();
        uint256 contestId = _contestIds.current();
        artContests[contestId] = ArtContest({
            id: contestId,
            name: _contestName,
            description: _contestDescription,
            startTime: _startTime,
            endTime: _endTime,
            isActive: true,
            winningProposalId: 0 // No winner initially
        });
        emit ArtContestCreated(contestId, _contestName);
    }

    /**
     * @dev Submit an already proposed art to an active contest.
     * @param _contestId ID of the art contest.
     * @param _proposalId ID of the art proposal to submit.
     */
    function submitArtToContest(uint256 _contestId, uint256 _proposalId) public onlyCollectiveMember onlyActiveContest(_contestId) {
        require(artProposals[_proposalId].artist == msg.sender, "Only artist can submit their proposal to contest");
        require(block.timestamp >= artContests[_contestId].startTime && block.timestamp <= artContests[_contestId].endTime, "Contest is not currently active for submissions");
        // In a real scenario, you might want to store submitted proposals in a mapping within the contest struct.
        emit ArtSubmittedToContest(_contestId, _proposalId);
    }

    /**
     * @dev Collective members vote for art in a contest.
     * @param _contestId ID of the art contest.
     * @param _proposalId ID of the art proposal being voted on in the contest.
     */
    function voteForContestArt(uint256 _contestId, uint256 _proposalId) public onlyCollectiveMember onlyActiveContest(_contestId) {
        require(block.timestamp >= artContests[_contestId].startTime && block.timestamp <= artContests[_contestId].endTime, "Contest voting period is not active");
        require(!contestArtVotes[_contestId][_proposalId][msg.sender], "Already voted for this art in this contest");
        contestArtVotes[_contestId][_proposalId][msg.sender] = true;

        artProposals[_proposalId].votesFor++; // Reusing votesFor for simplicity, could have separate contest vote count.
        emit ContestArtVoted(_contestId, _proposalId, msg.sender, true); // Assuming 'true' vote for contest.
    }

    /**
     * @dev Finalize an art contest, select winners (needs winner selection logic - simplest is most votes).
     * @param _contestId ID of the art contest to finalize.
     */
    function finalizeArtContest(uint256 _contestId) public onlyGovernance onlyActiveContest(_contestId) {
        require(block.timestamp > artContests[_contestId].endTime, "Contest end time not reached yet");
        artContests[_contestId].isActive = false; // Mark contest as inactive

        uint256 winningProposalId = 0;
        uint256 maxVotes = 0;

        // Find the proposal with the most votes (simplest winner selection logic).
        // In a real scenario, you might have more complex winner selection criteria.
        for (uint256 i = 1; i <= _artProposalIds.current(); i++) { // Iterate through all proposals - inefficient for large number of proposals, optimize if needed
            if (artProposals[i].votesFor > maxVotes) {
                maxVotes = artProposals[i].votesFor;
                winningProposalId = artProposals[i].id;
            }
        }

        artContests[_contestId].winningProposalId = winningProposalId;
        emit ArtContestFinalized(_contestId, winningProposalId);

        // Optionally reward the winner (e.g., transfer NFT, prize money - implementation needed)
    }


    // ----------------------- Treasury & Revenue -----------------------

    /**
     * @dev Returns the current balance of the collective treasury.
     * @return uint256 Treasury balance in wei.
     */
    function getCollectiveBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Allows governance to withdraw funds from the treasury.
     * @param _recipient Address to send the funds to.
     * @param _amount Amount to withdraw in wei.
     */
    function withdrawFunds(address payable _recipient, uint256 _amount) public onlyGovernance {
        require(address(this).balance >= _amount, "Insufficient contract balance");
        (bool success, ) = _recipient.call{value: _amount}("");
        require(success, "Withdrawal failed");
        emit FundsWithdrawn(_recipient, _amount);
    }

    /**
     * @dev Distributes a percentage of the sale revenue to the original artist (upon initial NFT sale).
     *      This function is called internally in `purchaseArtNFT` for initial sale.
     * @param _tokenId ID of the art NFT.
     */
    function splitRevenueWithArtist(uint256 _tokenId) public payable onlyGovernance { // Example - governance can trigger manual split if needed (redundant as it's in purchaseArtNFT)
        require(artNFTs[_tokenId].tokenId != 0, "Art NFT does not exist");
        address artist = artNFTs[_tokenId].artist;
        uint256 salePrice = artNFTs[_tokenId].price;
        uint256 artistShare = (salePrice * artistRevenueSharePercentage) / 100;
        payable(artist).transfer(artistShare);
        emit RevenueSplitWithArtist(_tokenId, artist, artistShare);
    }

    // Fallback function to receive ETH into the contract
    receive() external payable {}
}
```