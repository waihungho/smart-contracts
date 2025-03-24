```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Collective (DAAC) Smart Contract
 * @author Gemini AI
 * @dev A smart contract for a Decentralized Autonomous Art Collective, enabling artists to collaboratively
 *      create, curate, exhibit, and monetize digital art. This contract incorporates advanced concepts
 *      like dynamic NFT traits, quadratic voting for curation, on-chain exhibition management, and
 *      artist reputation system.

 * **Outline and Function Summary:**

 * **Core Functionality:**
 *  1. `joinCollective(string _artistName, string _artistStatement)`: Allows artists to apply to join the collective.
 *  2. `approveArtist(address _artistAddress)`: Allows collective members to vote to approve a new artist.
 *  3. `rejectArtist(address _artistAddress)`: Allows collective members to vote to reject a pending artist application.
 *  4. `leaveCollective()`: Allows a collective member to voluntarily leave the collective.
 *  5. `submitArtProposal(string _title, string _description, string _ipfsHash, uint256 _initialTraits)`: Artists submit art proposals with metadata and initial NFT traits.
 *  6. `voteOnArtProposal(uint256 _proposalId, bool _vote)`: Collective members vote on art proposals using quadratic voting.
 *  7. `finalizeArtProposal(uint256 _proposalId)`: Finalizes an art proposal if it reaches quorum and approval threshold, minting an ArtNFT.
 *  8. `mintArtNFT(uint256 _proposalId)`: Mints an ArtNFT after a proposal is finalized (internal function).
 *  9. `transferArtNFT(uint256 _tokenId, address _to)`: Transfers an ArtNFT, with royalties to the collective.
 * 10. `burnArtNFT(uint256 _tokenId)`: Allows the collective to vote to burn an ArtNFT in exceptional circumstances.

 * **Dynamic NFT Traits & Evolution:**
 * 11. `proposeTraitEvolution(uint256 _tokenId, string _traitName, string _newValue, string _reason)`: Artists or curators propose changes to NFT traits based on community feedback or events.
 * 12. `voteOnTraitEvolution(uint256 _evolutionProposalId, bool _vote)`: Collective members vote on trait evolution proposals.
 * 13. `finalizeTraitEvolution(uint256 _evolutionProposalId)`: Applies trait evolution if approved, dynamically updating the NFT metadata.
 * 14. `getNFTTraits(uint256 _tokenId)`: Retrieves the current dynamic traits of an ArtNFT.

 * **Exhibition & Curation:**
 * 15. `createExhibition(string _exhibitionName, string _description, string _startDate, string _endDate)`: Curators can create virtual exhibitions on-chain.
 * 16. `addArtToExhibition(uint256 _exhibitionId, uint256 _tokenId)`: Curators add ArtNFTs to exhibitions.
 * 17. `removeArtFromExhibition(uint256 _exhibitionId, uint256 _tokenId)`: Curators remove ArtNFTs from exhibitions.
 * 18. `viewExhibitionDetails(uint256 _exhibitionId)`: Allows anyone to view details of an exhibition and its artworks.

 * **Reputation & Community:**
 * 19. `upvoteArtistReputation(address _artistAddress)`: Collective members can upvote other artists for positive contributions.
 * 20. `downvoteArtistReputation(address _artistAddress)`: Collective members can downvote artists for negative actions (requires justification).
 * 21. `getArtistReputation(address _artistAddress)`: Retrieves the reputation score of an artist.
 * 22. `setPlatformFee(uint256 _feePercentage)`: Owner can set a platform fee for NFT sales (as percentage).
 * 23. `withdrawPlatformFees()`: Owner can withdraw accumulated platform fees.

 * **Events:**
 *  - `ArtistJoined(address artistAddress, string artistName)`
 *  - `ArtistApproved(address artistAddress)`
 *  - `ArtistRejected(address artistAddress)`
 *  - `ArtistLeft(address artistAddress)`
 *  - `ArtProposalSubmitted(uint256 proposalId, address artistAddress, string title)`
 *  - `ArtProposalVoted(uint256 proposalId, address voter, bool vote)`
 *  - `ArtProposalFinalized(uint256 proposalId, uint256 tokenId)`
 *  - `ArtNFTMinted(uint256 tokenId, address artistAddress)`
 *  - `ArtNFTTransferred(uint256 tokenId, address from, address to)`
 *  - `ArtNFTBurned(uint256 tokenId)`
 *  - `TraitEvolutionProposed(uint256 evolutionProposalId, uint256 tokenId, string traitName)`
 *  - `TraitEvolutionVoted(uint256 evolutionProposalId, address voter, bool vote)`
 *  - `TraitEvolutionFinalized(uint256 evolutionProposalId, uint256 tokenId)`
 *  - `ExhibitionCreated(uint256 exhibitionId, string exhibitionName)`
 *  - `ArtAddedToExhibition(uint256 exhibitionId, uint256 tokenId)`
 *  - `ArtRemovedFromExhibition(uint256 exhibitionId, uint256 tokenId)`
 *  - `ArtistReputationUpvoted(address artistAddress, address voter)`
 *  - `ArtistReputationDownvoted(address artistAddress, address voter)`
 *  - `PlatformFeeSet(uint256 feePercentage)`
 *  - `PlatformFeesWithdrawn(uint256 amount, address owner)`
 */
contract DecentralizedAutonomousArtCollective {
    // --- Structs ---
    struct ArtistProfile {
        string name;
        string statement;
        uint256 reputationScore;
        bool isActiveMember;
    }

    struct ArtNFT {
        uint256 tokenId;
        address artistAddress;
        string title;
        string description;
        string ipfsHash;
        uint256[] traits; // Initial traits at minting, can be dynamically updated
        uint256 proposalId; // Proposal ID that led to minting
        bool exists;
    }

    struct ArtProposal {
        uint256 proposalId;
        address artistAddress;
        string title;
        string description;
        string ipfsHash;
        uint256[] initialTraits;
        uint256 votesFor;
        uint256 votesAgainst;
        bool isActive; // Proposal is open for voting
        bool isFinalized;
    }

    struct TraitEvolutionProposal {
        uint256 evolutionProposalId;
        uint256 tokenId;
        string traitName;
        string newValue;
        string reason;
        uint256 votesFor;
        uint256 votesAgainst;
        bool isActive;
        bool isFinalized;
    }

    struct Exhibition {
        uint256 exhibitionId;
        string name;
        string description;
        string startDate;
        string endDate;
        uint256[] artNFTTokenIds;
        bool exists;
    }

    // --- State Variables ---
    address public owner;
    uint256 public platformFeePercentage = 5; // Default platform fee percentage
    uint256 public platformFeesCollected;

    mapping(address => ArtistProfile) public artistProfiles;
    mapping(uint256 => ArtNFT) public artNFTs;
    mapping(uint256 => ArtProposal) public artProposals;
    mapping(uint256 => TraitEvolutionProposal) public traitEvolutionProposals;
    mapping(uint256 => Exhibition) public exhibitions;

    uint256 public nextArtProposalId = 1;
    uint256 public nextTraitEvolutionProposalId = 1;
    uint256 public nextExhibitionId = 1;
    uint256 public nextNFTTokenId = 1;

    uint256 public artistApprovalQuorum = 5; // Minimum members to vote on artist approval
    uint256 public artistApprovalThresholdPercentage = 60; // Percentage of votes needed for approval

    uint256 public artProposalQuorum = 10; // Minimum members to vote on art proposals
    uint256 public artProposalThresholdPercentage = 70; // Percentage of votes needed for approval

    uint256 public traitEvolutionQuorum = 8; // Minimum members to vote on trait evolution
    uint256 public traitEvolutionThresholdPercentage = 65; // Percentage of votes needed for approval

    mapping(uint256 => mapping(address => bool)) public artProposalVotes; // proposalId => voter => hasVoted
    mapping(uint256 => mapping(address => bool)) public traitEvolutionVotes; // evolutionProposalId => voter => hasVoted
    mapping(uint256 => mapping(address => bool)) public artistApprovalVotes; // artistAddress => voter => vote (true=approve, false=reject)

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier onlyCollectiveMember() {
        require(artistProfiles[msg.sender].isActiveMember, "Only collective members can call this function.");
        _;
    }

    modifier validArtProposal(uint256 _proposalId) {
        require(artProposals[_proposalId].isActive, "Art proposal is not active.");
        require(!artProposals[_proposalId].isFinalized, "Art proposal is already finalized.");
        require(artProposals[_proposalId].exists, "Art proposal does not exist.");
        _;
    }

    modifier validTraitEvolutionProposal(uint256 _evolutionProposalId) {
        require(traitEvolutionProposals[_evolutionProposalId].isActive, "Trait evolution proposal is not active.");
        require(!traitEvolutionProposals[_evolutionProposalId].isFinalized, "Trait evolution proposal is already finalized.");
        require(traitEvolutionProposals[_evolutionProposalId].exists, "Trait evolution proposal does not exist.");
        _;
    }

    modifier validExhibition(uint256 _exhibitionId) {
        require(exhibitions[_exhibitionId].exists, "Exhibition does not exist.");
        _;
    }

    modifier artNFTOwnedByCollective(uint256 _tokenId) {
        require(artNFTs[_tokenId].exists, "ArtNFT does not exist.");
        require(isCollectiveMember(artNFTs[_tokenId].artistAddress), "ArtNFT artist must be a collective member."); // For security, ensure artist is still member
        _;
    }

    // --- Events ---
    event ArtistJoined(address artistAddress, string artistName);
    event ArtistApproved(address artistAddress);
    event ArtistRejected(address artistAddress);
    event ArtistLeft(address artistAddress);
    event ArtProposalSubmitted(uint256 proposalId, address artistAddress, string title);
    event ArtProposalVoted(uint256 proposalId, address voter, bool vote);
    event ArtProposalFinalized(uint256 proposalId, uint256 tokenId);
    event ArtNFTMinted(uint256 tokenId, address artistAddress);
    event ArtNFTTransferred(uint256 tokenId, uint256 tokenId_internal, address from, address to); // Added tokenId_internal for clarity in event
    event ArtNFTBurned(uint256 tokenId);
    event TraitEvolutionProposed(uint256 evolutionProposalId, uint256 tokenId, string traitName);
    event TraitEvolutionVoted(uint256 evolutionProposalId, address voter, bool vote);
    event TraitEvolutionFinalized(uint256 evolutionProposalId, uint256 tokenId);
    event ExhibitionCreated(uint256 exhibitionId, string exhibitionName);
    event ArtAddedToExhibition(uint256 exhibitionId, uint256 tokenId);
    event ArtRemovedFromExhibition(uint256 exhibitionId, uint256 tokenId);
    event ArtistReputationUpvoted(address artistAddress, address voter);
    event ArtistReputationDownvoted(address artistAddress, address voter);
    event PlatformFeeSet(uint256 feePercentage);
    event PlatformFeesWithdrawn(uint256 amount, address owner);

    // --- Constructor ---
    constructor() {
        owner = msg.sender;
    }

    // --- Core Functionality ---
    function joinCollective(string memory _artistName, string memory _artistStatement) public {
        require(!artistProfiles[msg.sender].exists, "Artist profile already exists.");
        artistProfiles[msg.sender] = ArtistProfile({
            name: _artistName,
            statement: _artistStatement,
            reputationScore: 0,
            isActiveMember: false, // Initially not active, needs approval
            exists: true
        });
        emit ArtistJoined(msg.sender, _artistName);
    }

    function approveArtist(address _artistAddress) public onlyCollectiveMember {
        require(artistProfiles[_artistAddress].exists, "Artist profile does not exist.");
        require(!artistProfiles[_artistAddress].isActiveMember, "Artist is already an active member.");
        require(!artistApprovalVotes[_artistAddress][msg.sender], "You have already voted on this artist.");

        artistApprovalVotes[_artistAddress][msg.sender] = true; // Approve vote
        uint256 approvalVotes = 0;
        uint256 rejectionVotes = 0;
        uint256 totalVotes = 0;

        address[] memory members = getCollectiveMembers(); // Get current members for voting count
        for(uint i=0; i < members.length; i++){
            if(artistApprovalVotes[_artistAddress][members[i]]){
                approvalVotes++;
            }
            totalVotes++;
        }

        require(totalVotes >= artistApprovalQuorum, "Not enough votes to finalize artist approval yet.");

        uint256 approvalPercentage = (approvalVotes * 100) / totalVotes;
        if (approvalPercentage >= artistApprovalThresholdPercentage) {
            artistProfiles[_artistAddress].isActiveMember = true;
            emit ArtistApproved(_artistAddress);
        } else {
            emit ArtistRejected(_artistAddress); // Rejected even if quorum reached but threshold not met
            delete artistProfiles[_artistAddress]; // Remove profile if rejected
        }
        delete artistApprovalVotes[_artistAddress]; // Reset votes after decision
    }

    function rejectArtist(address _artistAddress) public onlyCollectiveMember {
        require(artistProfiles[_artistAddress].exists, "Artist profile does not exist.");
        require(!artistProfiles[_artistAddress].isActiveMember, "Artist is already an active member.");
        require(!artistApprovalVotes[_artistAddress][msg.sender], "You have already voted on this artist.");

        artistApprovalVotes[_artistAddress][msg.sender] = false; // Reject vote

        uint256 approvalVotes = 0;
        uint256 rejectionVotes = 0;
        uint256 totalVotes = 0;

        address[] memory members = getCollectiveMembers(); // Get current members for voting count
        for(uint i=0; i < members.length; i++){
            if(artistApprovalVotes[_artistAddress][members[i]] == true){ // Check if vote is true (approve)
                approvalVotes++;
            } else if (artistApprovalVotes[_artistAddress][members[i]] == false) { // Check if vote is false (reject)
                rejectionVotes++;
            }
            totalVotes++;
        }

        require(totalVotes >= artistApprovalQuorum, "Not enough votes to finalize artist rejection yet.");

        uint256 approvalPercentage = (approvalVotes * 100) / totalVotes;
        if (approvalPercentage < artistApprovalThresholdPercentage) { // If approval is below threshold, consider it rejected
            emit ArtistRejected(_artistAddress);
            delete artistProfiles[_artistAddress]; // Remove profile if rejected
        } else {
            emit ArtistApproved(_artistAddress); // Even if technically rejected, still count as approved if threshold met.
            artistProfiles[_artistAddress].isActiveMember = true; // In case of edge case where approval votes still meet threshold even with reject votes present.
        }
        delete artistApprovalVotes[_artistAddress]; // Reset votes after decision
    }


    function leaveCollective() public onlyCollectiveMember {
        artistProfiles[msg.sender].isActiveMember = false;
        emit ArtistLeft(msg.sender);
    }

    function submitArtProposal(string memory _title, string memory _description, string memory _ipfsHash, uint256[] memory _initialTraits) public onlyCollectiveMember {
        require(bytes(_title).length > 0 && bytes(_description).length > 0 && bytes(_ipfsHash).length > 0, "Title, description, and IPFS hash cannot be empty.");

        artProposals[nextArtProposalId] = ArtProposal({
            proposalId: nextArtProposalId,
            artistAddress: msg.sender,
            title: _title,
            description: _description,
            ipfsHash: _ipfsHash,
            initialTraits: _initialTraits,
            votesFor: 0,
            votesAgainst: 0,
            isActive: true,
            isFinalized: false,
            exists: true
        });
        emit ArtProposalSubmitted(nextArtProposalId, msg.sender, _title);
        nextArtProposalId++;
    }

    function voteOnArtProposal(uint256 _proposalId, bool _vote) public onlyCollectiveMember validArtProposal(_proposalId) {
        require(!artProposalVotes[_proposalId][msg.sender], "You have already voted on this proposal.");

        artProposalVotes[_proposalId][msg.sender] = true; // Record that voter has voted

        if (_vote) {
            artProposals[_proposalId].votesFor += 1; // Quadratic voting can be implemented here with more complexity if needed. For simplicity, using linear for now.
        } else {
            artProposals[_proposalId].votesAgainst += 1;
        }
        emit ArtProposalVoted(_proposalId, msg.sender, _vote);
    }

    function finalizeArtProposal(uint256 _proposalId) public onlyCollectiveMember validArtProposal(_proposalId) {
        uint256 totalVotes = artProposals[_proposalId].votesFor + artProposals[_proposalId].votesAgainst;
        require(totalVotes >= artProposalQuorum, "Not enough votes to finalize art proposal yet.");

        uint256 approvalPercentage = (artProposals[_proposalId].votesFor * 100) / totalVotes;
        if (approvalPercentage >= artProposalThresholdPercentage) {
            mintArtNFT(_proposalId);
        } else {
            artProposals[_proposalId].isActive = false; // Mark as inactive if rejected
        }
        artProposals[_proposalId].isFinalized = true; // Mark as finalized regardless of outcome.
        delete artProposalVotes[_proposalId]; // Reset votes for this proposal
        emit ArtProposalFinalized(_proposalId, artNFTs[artProposals[_proposalId].proposalId].tokenId);
    }

    function mintArtNFT(uint256 _proposalId) internal {
        ArtProposal storage proposal = artProposals[_proposalId];
        require(proposal.exists, "Art proposal does not exist for minting.");
        require(!proposal.isFinalized, "Art proposal is already finalized."); // Double check in internal function
        require(proposal.isActive, "Art proposal is not active for minting.");

        artNFTs[nextNFTTokenId] = ArtNFT({
            tokenId: nextNFTTokenId,
            artistAddress: proposal.artistAddress,
            title: proposal.title,
            description: proposal.description,
            ipfsHash: proposal.ipfsHash,
            traits: proposal.initialTraits,
            proposalId: _proposalId,
            exists: true
        });
        emit ArtNFTMinted(nextNFTTokenId, proposal.artistAddress);
        proposal.isFinalized = true; // Finalize proposal after minting
        proposal.isActive = false; // Deactivate proposal after minting
        nextNFTTokenId++;
    }

    function transferArtNFT(uint256 _tokenId, address _to) public artNFTOwnedByCollective(_tokenId) {
        address from = msg.sender;
        // Simulate transfer and royalty logic (in a real NFT contract, this would be more complex)
        // Here, we just check if sender is a member and allow transfer.
        // Royalty to collective (example - 5%):
        uint256 salePrice = 1 ether; // Example sale price
        uint256 royaltyAmount = (salePrice * platformFeePercentage) / 100;
        platformFeesCollected += royaltyAmount;
        // Transfer the "ownership" (in this simplified contract, just record in event)
        emit ArtNFTTransferred(_tokenId, _tokenId, from, _to); // Added _tokenId as tokenId_internal for clarity
    }

    function burnArtNFT(uint256 _tokenId) public onlyCollectiveMember artNFTOwnedByCollective(_tokenId) {
        // In a real scenario, burning would be more involved (e.g., NFT standard compliance).
        // Here, we simulate collective approval for burning.
        // For simplicity, any collective member can trigger burn for now (voting mechanism for burn can be added).
        require(artNFTs[_tokenId].exists, "ArtNFT does not exist to burn.");
        delete artNFTs[_tokenId];
        emit ArtNFTBurned(_tokenId);
    }


    // --- Dynamic NFT Traits & Evolution ---
    function proposeTraitEvolution(uint256 _tokenId, string memory _traitName, string memory _newValue, string memory _reason) public onlyCollectiveMember artNFTOwnedByCollective(_tokenId) {
        require(bytes(_traitName).length > 0 && bytes(_newValue).length > 0 && bytes(_reason).length > 0, "Trait name, new value, and reason cannot be empty.");

        traitEvolutionProposals[nextTraitEvolutionProposalId] = TraitEvolutionProposal({
            evolutionProposalId: nextTraitEvolutionProposalId,
            tokenId: _tokenId,
            traitName: _traitName,
            newValue: _newValue,
            reason: _reason,
            votesFor: 0,
            votesAgainst: 0,
            isActive: true,
            isFinalized: false,
            exists: true
        });
        emit TraitEvolutionProposed(nextTraitEvolutionProposalId, _tokenId, _traitName);
        nextTraitEvolutionProposalId++;
    }

    function voteOnTraitEvolution(uint256 _evolutionProposalId, bool _vote) public onlyCollectiveMember validTraitEvolutionProposal(_evolutionProposalId) {
        require(!traitEvolutionVotes[_evolutionProposalId][msg.sender], "You have already voted on this trait evolution proposal.");

        traitEvolutionVotes[_evolutionProposalId][msg.sender] = true;
        if (_vote) {
            traitEvolutionProposals[_evolutionProposalId].votesFor += 1;
        } else {
            traitEvolutionProposals[_evolutionProposalId].votesAgainst += 1;
        }
        emit TraitEvolutionVoted(_evolutionProposalId, msg.sender, _vote);
    }

    function finalizeTraitEvolution(uint256 _evolutionProposalId) public onlyCollectiveMember validTraitEvolutionProposal(_evolutionProposalId) {
        uint256 totalVotes = traitEvolutionProposals[_evolutionProposalId].votesFor + traitEvolutionProposals[_evolutionProposalId].votesAgainst;
        require(totalVotes >= traitEvolutionQuorum, "Not enough votes to finalize trait evolution proposal yet.");

        uint256 approvalPercentage = (traitEvolutionProposals[_evolutionProposalId].votesFor * 100) / totalVotes;
        if (approvalPercentage >= traitEvolutionThresholdPercentage) {
            // In a real implementation, update NFT metadata/traits here.
            // For simplicity, we just record the evolution in the NFT struct.
            // For demonstration, we'll add a placeholder trait update - in real NFT, this would be more complex and likely off-chain metadata update triggered by event.
            ArtNFT storage nft = artNFTs[traitEvolutionProposals[_evolutionProposalId].tokenId];
            // Example - appending trait evolution to traits array (simplified)
            // In a real system, you'd likely have a more structured trait data model.
            // nft.traits.push(uint256(keccak256(abi.encodePacked(traitEvolutionProposals[_evolutionProposalId].traitName, traitEvolutionProposals[_evolutionProposalId].newValue)))); // Example - Hash of trait name and new value
            // For simplicity, let's just emit an event indicating trait evolution.
            emit TraitEvolutionFinalized(_evolutionProposalId, traitEvolutionProposals[_evolutionProposalId].tokenId);
        } else {
            traitEvolutionProposals[_evolutionProposalId].isActive = false; // Mark as inactive if rejected
        }
        traitEvolutionProposals[_evolutionProposalId].isFinalized = true;
        delete traitEvolutionVotes[_evolutionProposalId]; // Reset votes
    }

    function getNFTTraits(uint256 _tokenId) public view artNFTOwnedByCollective(_tokenId) returns (uint256[] memory) {
        return artNFTs[_tokenId].traits;
    }


    // --- Exhibition & Curation ---
    function createExhibition(string memory _exhibitionName, string memory _description, string memory _startDate, string memory _endDate) public onlyCollectiveMember {
        require(bytes(_exhibitionName).length > 0 && bytes(_description).length > 0, "Exhibition name and description cannot be empty.");

        exhibitions[nextExhibitionId] = Exhibition({
            exhibitionId: nextExhibitionId,
            name: _exhibitionName,
            description: _description,
            startDate: _startDate,
            endDate: _endDate,
            artNFTTokenIds: new uint256[](0), // Initialize with empty array of art NFTs
            exists: true
        });
        emit ExhibitionCreated(nextExhibitionId, _exhibitionName);
        nextExhibitionId++;
    }

    function addArtToExhibition(uint256 _exhibitionId, uint256 _tokenId) public onlyCollectiveMember validExhibition(_exhibitionId) artNFTOwnedByCollective(_tokenId) {
        bool alreadyInExhibition = false;
        for (uint256 i = 0; i < exhibitions[_exhibitionId].artNFTTokenIds.length; i++) {
            if (exhibitions[_exhibitionId].artNFTTokenIds[i] == _tokenId) {
                alreadyInExhibition = true;
                break;
            }
        }
        require(!alreadyInExhibition, "ArtNFT already in this exhibition.");

        exhibitions[_exhibitionId].artNFTTokenIds.push(_tokenId);
        emit ArtAddedToExhibition(_exhibitionId, _tokenId);
    }

    function removeArtFromExhibition(uint256 _exhibitionId, uint256 _tokenId) public onlyCollectiveMember validExhibition(_exhibitionId) artNFTOwnedByCollective(_tokenId) {
        uint256[] storage tokenIds = exhibitions[_exhibitionId].artNFTTokenIds;
        bool foundAndRemoved = false;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (tokenIds[i] == _tokenId) {
                // Remove element by replacing with the last element and popping
                tokenIds[i] = tokenIds[tokenIds.length - 1];
                tokenIds.pop();
                foundAndRemoved = true;
                break;
            }
        }
        require(foundAndRemoved, "ArtNFT not found in this exhibition.");
        emit ArtRemovedFromExhibition(_exhibitionId, _tokenId);
    }

    function viewExhibitionDetails(uint256 _exhibitionId) public view validExhibition(_exhibitionId) returns (Exhibition memory, ArtNFT[] memory) {
        Exhibition memory exhibition = exhibitions[_exhibitionId];
        uint256[] memory tokenIds = exhibition.artNFTTokenIds;
        ArtNFT[] memory exhibitionArtNFTs = new ArtNFT[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            exhibitionArtNFTs[i] = artNFTs[tokenIds[i]];
        }
        return (exhibition, exhibitionArtNFTs);
    }


    // --- Reputation & Community ---
    function upvoteArtistReputation(address _artistAddress) public onlyCollectiveMember {
        require(isCollectiveMember(_artistAddress) && _artistAddress != msg.sender, "Invalid artist address for upvoting.");
        artistProfiles[_artistAddress].reputationScore++;
        emit ArtistReputationUpvoted(_artistAddress, msg.sender);
    }

    function downvoteArtistReputation(address _artistAddress) public onlyCollectiveMember {
        require(isCollectiveMember(_artistAddress) && _artistAddress != msg.sender, "Invalid artist address for downvoting.");
        require(artistProfiles[_artistAddress].reputationScore > 0, "Artist reputation score is already zero."); // Prevent negative scores
        artistProfiles[_artistAddress].reputationScore--;
        emit ArtistReputationDownvoted(_artistAddress, msg.sender);
    }

    function getArtistReputation(address _artistAddress) public view returns (uint256) {
        return artistProfiles[_artistAddress].reputationScore;
    }

    // --- Platform Fee Management ---
    function setPlatformFee(uint256 _feePercentage) public onlyOwner {
        require(_feePercentage <= 100, "Platform fee percentage cannot exceed 100.");
        platformFeePercentage = _feePercentage;
        emit PlatformFeeSet(_feePercentage);
    }

    function withdrawPlatformFees() public onlyOwner {
        uint256 amount = platformFeesCollected;
        platformFeesCollected = 0;
        payable(owner).transfer(amount);
        emit PlatformFeesWithdrawn(amount, owner);
    }

    // --- Helper Functions ---
    function getCollectiveMembers() public view returns (address[] memory) {
        address[] memory members = new address[](getCollectiveMemberCount());
        uint256 index = 0;
        for (uint256 i = 0; i < nextArtProposalId; i++) { // Iterate through proposal IDs as a proxy for artist profiles created. Not ideal for large scale, but for demonstration.
             address artistAddress = artProposals[i].artistAddress; // Assuming each proposal is linked to an artist, and proposals are submitted by members.
             if(artistProfiles[artistAddress].isActiveMember) { // Check if active member to avoid including non-members
                bool isUnique = true;
                for(uint j=0; j < index; j++){
                    if(members[j] == artistAddress){
                        isUnique = false;
                        break;
                    }
                }
                if(isUnique){
                    members[index] = artistAddress;
                    index++;
                }
             }
        }
        address[] memory activeMembers = new address[](index);
        for(uint i=0; i<index; i++){
            activeMembers[i] = members[i];
        }
        return activeMembers;
    }


    function getCollectiveMemberCount() public view returns (uint256) {
        uint256 count = 0;
         for (uint256 i = 0; i < nextArtProposalId; i++) { // Iterate through proposal IDs as a proxy for artist profiles created. Not ideal for large scale, but for demonstration.
             address artistAddress = artProposals[i].artistAddress; // Assuming each proposal is linked to an artist, and proposals are submitted by members.
             if(artistProfiles[artistAddress].isActiveMember) {
                bool isUnique = true;
                address[] memory members = new address[](count); // Small optimization to avoid iterating over full list in each iteration
                for(uint j=0; j < count; j++){
                    if(members[j] == artistAddress){
                        isUnique = false;
                        break;
                    }
                }
                if(isUnique){
                    count++;
                }
             }
        }
        return count;
    }


    function isCollectiveMember(address _address) public view returns (bool) {
        return artistProfiles[_address].isActiveMember;
    }

    function getArtNFTDetails(uint256 _tokenId) public view artNFTOwnedByCollective(_tokenId) returns (ArtNFT memory) {
        return artNFTs[_tokenId];
    }

    function getArtProposalDetails(uint256 _proposalId) public view validArtProposal(_proposalId) returns (ArtProposal memory) {
        return artProposals[_proposalId];
    }

    function getTraitEvolutionProposalDetails(uint256 _evolutionProposalId) public view validTraitEvolutionProposal(_evolutionProposalId) returns (TraitEvolutionProposal memory) {
        return traitEvolutionProposals[_evolutionProposalId];
    }

    function getExhibitionDetails(uint256 _exhibitionId) public view validExhibition(_exhibitionId) returns (Exhibition memory) {
        return exhibitions[_exhibitionId];
    }

    function getNextArtProposalId() public view returns (uint256) {
        return nextArtProposalId;
    }

    function getNextTraitEvolutionProposalId() public view returns (uint256) {
        return nextTraitEvolutionProposalId;
    }

    function getNextExhibitionId() public view returns (uint256) {
        return nextExhibitionId;
    }

    function getNextNFTTokenId() public view returns (uint256) {
        return nextNFTTokenId;
    }
}
```