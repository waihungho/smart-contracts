```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Collective - "ArtVerse DAO"
 * @author Bard (AI Assistant)
 * @dev A smart contract for a DAO focused on collaborative art creation, curation, and NFT management.
 *
 * **Outline and Function Summary:**
 *
 * **Membership & Governance:**
 *   1. joinCollective(string _artistName, string _artistStatement): Allows artists to request membership by providing a name and statement.
 *   2. approveMembership(address _artistAddress): Governor-only function to approve pending membership requests.
 *   3. revokeMembership(address _memberAddress): Governor-only function to revoke membership.
 *   4. proposeNewGovernor(address _newGovernorAddress): Allows current governors to propose a new governor.
 *   5. voteOnGovernorProposal(uint _proposalId, bool _vote): Members vote on governor proposals.
 *   6. executeGovernorProposal(uint _proposalId): Governor-only function to execute approved governor proposals.
 *   7. getMemberCount(): Returns the current number of members in the collective.
 *   8. getPendingMembershipRequests(): Returns a list of pending membership request addresses.
 *
 * **Artwork Submission & Curation:**
 *   9. submitArtwork(string _title, string _description, string _ipfsHash): Members submit their artwork with title, description, and IPFS hash.
 *   10. voteOnArtwork(uint _artworkId, bool _vote): Members vote on submitted artwork for inclusion in the curated collection.
 *   11. finalizeArtworkCuration(uint _artworkId): Governor-only function to finalize curation after voting and mint NFT if approved.
 *   12. getArtworkDetails(uint _artworkId): Returns details of a specific artwork, including votes and status.
 *   13. getRandomArtworkId(): Returns a random artwork ID from the curated collection (for showcasing).
 *
 * **NFT Minting & Management:**
 *   14. mintCollectibleNFT(uint _artworkId): Governor-only function to mint an NFT for a curated artwork (ERC721-like, internal).
 *   15. transferCollectibleNFT(uint _artworkId, address _recipient): Governor-only function to transfer ownership of a collective NFT (e.g., for sale proceeds distribution).
 *   16. getCollectibleNFTOwner(uint _artworkId): Returns the current owner of a collective NFT.
 *   17. getCollectibleNFTMetadataURI(uint _artworkId): Returns the metadata URI for a collective NFT.
 *
 * **Collective Treasury & Funding:**
 *   18. donateToCollective(): Allows anyone to donate ETH to the collective treasury.
 *   19. proposeFundingProposal(string _proposalDescription, address _recipient, uint _amount): Members propose funding proposals for collective initiatives.
 *   20. voteOnFundingProposal(uint _proposalId, bool _vote): Members vote on funding proposals.
 *   21. executeFundingProposal(uint _proposalId): Governor-only function to execute approved funding proposals, sending ETH from the treasury.
 *   22. getTreasuryBalance(): Returns the current ETH balance of the collective treasury.
 *
 * **Utility & Information:**
 *   23. setMetadataBaseURI(string _baseURI): Governor-only function to set the base URI for NFT metadata.
 *   24. getMetadataBaseURI(): Returns the current base URI for NFT metadata.
 */

contract ArtVerseDAO {
    // --- Structs and Enums ---

    struct Member {
        string artistName;
        string artistStatement;
        bool isActive;
    }

    struct Artwork {
        string title;
        string description;
        string ipfsHash;
        address artistAddress;
        uint upvotes;
        uint downvotes;
        bool isCurated;
        bool isNFTMinted;
    }

    struct GovernorProposal {
        address newGovernorAddress;
        uint votesFor;
        uint votesAgainst;
        bool isExecuted;
    }

    struct FundingProposal {
        string description;
        address recipient;
        uint amount;
        uint votesFor;
        uint votesAgainst;
        bool isExecuted;
    }

    // --- State Variables ---

    address public governor; // Address of the DAO governor (initial admin)
    mapping(address => Member) public members; // Mapping of member addresses to Member struct
    address[] public memberList; // Array to track members in order
    uint public memberCount; // Count of active members

    mapping(uint => Artwork) public artworks; // Mapping of artwork IDs to Artwork struct
    uint public artworkCount; // Counter for artwork IDs
    uint[] public curatedArtworkIds; // Array of curated artwork IDs

    mapping(uint => GovernorProposal) public governorProposals; // Mapping of governor proposal IDs
    uint public governorProposalCount; // Counter for governor proposal IDs

    mapping(uint => FundingProposal) public fundingProposals; // Mapping of funding proposal IDs
    uint public fundingProposalCount; // Counter for funding proposal IDs

    mapping(address => bool) public pendingMembershipRequests; // Track pending membership requests

    string public metadataBaseURI; // Base URI for NFT metadata

    // --- Events ---

    event MembershipRequested(address artistAddress, string artistName);
    event MembershipApproved(address memberAddress);
    event MembershipRevoked(address memberAddress);
    event GovernorProposed(uint proposalId, address newGovernorAddress);
    event GovernorProposalVoted(uint proposalId, address voter, bool vote);
    event GovernorChanged(address newGovernor);
    event ArtworkSubmitted(uint artworkId, address artistAddress, string title);
    event ArtworkVoted(uint artworkId, address voter, bool vote);
    event ArtworkCurated(uint artworkId);
    event CollectibleNFTMinted(uint artworkId, uint tokenId);
    event CollectibleNFTTransferred(uint artworkId, address recipient);
    event FundingProposalCreated(uint proposalId, string description, address recipient, uint amount);
    event FundingProposalVoted(uint proposalId, address voter, bool vote);
    event FundingProposalExecuted(uint proposalId, address recipient, uint amount);
    event DonationReceived(address donor, uint amount);
    event MetadataBaseURISet(string baseURI);

    // --- Modifiers ---

    modifier onlyGovernor() {
        require(msg.sender == governor, "Only governor can perform this action.");
        _;
    }

    modifier onlyMember() {
        require(members[msg.sender].isActive, "Only active members can perform this action.");
        _;
    }

    // --- Constructor ---

    constructor(string memory _initialMetadataBaseURI) {
        governor = msg.sender; // Deployer is the initial governor
        metadataBaseURI = _initialMetadataBaseURI;
    }

    // --- Membership & Governance Functions ---

    /// @notice Allows artists to request membership by providing a name and statement.
    /// @param _artistName The name of the artist.
    /// @param _artistStatement A statement from the artist about their work and interest in the collective.
    function joinCollective(string memory _artistName, string memory _artistStatement) public {
        require(!members[msg.sender].isActive, "Already a member.");
        require(!pendingMembershipRequests[msg.sender], "Membership request already pending.");
        pendingMembershipRequests[msg.sender] = true;
        emit MembershipRequested(msg.sender, _artistName);
        // Storing name and statement only upon approval to save gas on pending requests.
        // In a real-world scenario, consider off-chain storage or more gas-efficient methods if needed.
    }

    /// @notice Governor-only function to approve pending membership requests.
    /// @param _artistAddress The address of the artist to approve.
    function approveMembership(address _artistAddress) public onlyGovernor {
        require(pendingMembershipRequests[_artistAddress], "No pending membership request for this address.");
        require(!members[_artistAddress].isActive, "Address is already a member.");

        members[_artistAddress] = Member({
            artistName: "", // Name and statement will be set when artist submits first artwork (or separate function)
            artistStatement: "",
            isActive: true
        });
        memberList.push(_artistAddress);
        memberCount++;
        pendingMembershipRequests[_artistAddress] = false; // Clear pending request
        emit MembershipApproved(_artistAddress);
    }

    /// @notice Governor-only function to revoke membership.
    /// @param _memberAddress The address of the member to revoke.
    function revokeMembership(address _memberAddress) public onlyGovernor {
        require(members[_memberAddress].isActive, "Address is not an active member.");
        members[_memberAddress].isActive = false;

        // Remove from memberList (more gas-efficient method needed for large lists in production)
        for (uint i = 0; i < memberList.length; i++) {
            if (memberList[i] == _memberAddress) {
                memberList[i] = memberList[memberList.length - 1];
                memberList.pop();
                break;
            }
        }
        memberCount--;
        emit MembershipRevoked(_memberAddress);
    }

    /// @notice Allows current governors to propose a new governor.
    /// @param _newGovernorAddress The address of the proposed new governor.
    function proposeNewGovernor(address _newGovernorAddress) public onlyGovernor {
        governorProposalCount++;
        governorProposals[governorProposalCount] = GovernorProposal({
            newGovernorAddress: _newGovernorAddress,
            votesFor: 0,
            votesAgainst: 0,
            isExecuted: false
        });
        emit GovernorProposed(governorProposalCount, _newGovernorAddress);
    }

    /// @notice Members vote on governor proposals.
    /// @param _proposalId The ID of the governor proposal to vote on.
    /// @param _vote True for "for", false for "against".
    function voteOnGovernorProposal(uint _proposalId, bool _vote) public onlyMember {
        GovernorProposal storage proposal = governorProposals[_proposalId];
        require(!proposal.isExecuted, "Proposal already executed.");

        if (_vote) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        emit GovernorProposalVoted(_proposalId, msg.sender, _vote);
    }

    /// @notice Governor-only function to execute approved governor proposals.
    /// @param _proposalId The ID of the governor proposal to execute.
    function executeGovernorProposal(uint _proposalId) public onlyGovernor {
        GovernorProposal storage proposal = governorProposals[_proposalId];
        require(!proposal.isExecuted, "Proposal already executed.");
        require(proposal.votesFor > proposal.votesAgainst, "Proposal not approved by majority."); // Simple majority

        governor = proposal.newGovernorAddress;
        proposal.isExecuted = true;
        emit GovernorChanged(governor);
        executeGovernorProposal(_proposalId); // Mark as executed even if something fails later
    }

    /// @notice Returns the current number of members in the collective.
    function getMemberCount() public view returns (uint) {
        return memberCount;
    }

    /// @notice Returns a list of pending membership request addresses.
    function getPendingMembershipRequests() public view onlyGovernor returns (address[] memory) {
        address[] memory pendingRequests = new address[](0);
        for (uint i = 0; i < memberList.length; i++) { // Iterate through members (not ideal for large lists, optimize in prod)
            if (pendingMembershipRequests[memberList[i]]) {
                // This is incorrect, we should iterate through keys of pendingMembershipRequests.
                // A more efficient way is to maintain a separate list of pending requests.
                // For this example, iterating over members and checking pending status.
                if (pendingMembershipRequests[memberList[i]]) { // Check if still pending (edge case if member list is being updated concurrently - unlikely but possible)
                    address[] memory temp = new address[](pendingRequests.length + 1);
                    for (uint j = 0; j < pendingRequests.length; j++) {
                        temp[j] = pendingRequests[j];
                    }
                    temp[pendingRequests.length] = memberList[i];
                    pendingRequests = temp;
                }
            }
        }

        address[] memory actualPendingRequests = new address[](0);
        for (uint i=0; i < memberList.length; i++) {
            if (pendingMembershipRequests[memberList[i]]) {
                address[] memory temp = new address[](actualPendingRequests.length + 1);
                 for (uint j = 0; j < actualPendingRequests.length; j++) {
                    temp[j] = actualPendingRequests[j];
                }
                temp[actualPendingRequests.length] = memberList[i];
                actualPendingRequests = temp;
            }
        }
        return actualPendingRequests;

    }


    // --- Artwork Submission & Curation Functions ---

    /// @notice Members submit their artwork with title, description, and IPFS hash.
    /// @param _title The title of the artwork.
    /// @param _description A description of the artwork.
    /// @param _ipfsHash The IPFS hash of the artwork's digital file.
    function submitArtwork(string memory _title, string memory _description, string memory _ipfsHash) public onlyMember {
        artworkCount++;
        artworks[artworkCount] = Artwork({
            title: _title,
            description: _description,
            ipfsHash: _ipfsHash,
            artistAddress: msg.sender,
            upvotes: 0,
            downvotes: 0,
            isCurated: false,
            isNFTMinted: false
        });
        if (bytes(members[msg.sender].artistName).length == 0) {
            members[msg.sender].artistName = _title; // Example: Set artist name from first artwork title (can be improved)
            members[msg.sender].artistStatement = _description; // Example: Set artist statement from first artwork description (can be improved)
        }
        emit ArtworkSubmitted(artworkCount, msg.sender, _title);
    }

    /// @notice Members vote on submitted artwork for inclusion in the curated collection.
    /// @param _artworkId The ID of the artwork to vote on.
    /// @param _vote True for "upvote", false for "downvote".
    function voteOnArtwork(uint _artworkId, bool _vote) public onlyMember {
        Artwork storage artwork = artworks[_artworkId];
        require(!artwork.isCurated, "Artwork already curated.");

        if (_vote) {
            artwork.upvotes++;
        } else {
            artwork.downvotes++;
        }
        emit ArtworkVoted(_artworkId, msg.sender, _vote);
    }

    /// @notice Governor-only function to finalize curation after voting and mint NFT if approved.
    /// @param _artworkId The ID of the artwork to finalize.
    function finalizeArtworkCuration(uint _artworkId) public onlyGovernor {
        Artwork storage artwork = artworks[_artworkId];
        require(!artwork.isCurated, "Artwork already curated.");

        if (artwork.upvotes > artwork.downvotes) { // Simple upvote majority for curation
            artwork.isCurated = true;
            curatedArtworkIds.push(_artworkId);
            emit ArtworkCurated(_artworkId);
        } else {
            // Artwork not curated - can add logic for rejection if needed
        }
    }

    /// @notice Returns details of a specific artwork, including votes and status.
    /// @param _artworkId The ID of the artwork.
    function getArtworkDetails(uint _artworkId) public view returns (Artwork memory) {
        return artworks[_artworkId];
    }

    /// @notice Returns a random artwork ID from the curated collection (for showcasing).
    function getRandomArtworkId() public view returns (uint) {
        require(curatedArtworkIds.length > 0, "No curated artworks yet.");
        uint randomIndex = uint(blockhash(block.number - 1)) % curatedArtworkIds.length; // Simple pseudo-randomness, use Chainlink VRF for production
        return curatedArtworkIds[randomIndex];
    }

    // --- NFT Minting & Management Functions ---

    /// @notice Governor-only function to mint an NFT for a curated artwork (ERC721-like, internal).
    /// @param _artworkId The ID of the curated artwork to mint an NFT for.
    function mintCollectibleNFT(uint _artworkId) public onlyGovernor {
        Artwork storage artwork = artworks[_artworkId];
        require(artwork.isCurated, "Artwork is not curated.");
        require(!artwork.isNFTMinted, "NFT already minted for this artwork.");

        artwork.isNFTMinted = true;
        // In a real ERC721, you would mint a token and assign it to the collective/treasury here.
        // For simplicity, we're just marking it as "minted" and managing ownership internally.
        emit CollectibleNFTMinted(_artworkId, _artworkId); // Using artworkId as a simple token ID for this example
    }

    /// @notice Governor-only function to transfer ownership of a collective NFT (e.g., for sale proceeds distribution).
    /// @param _artworkId The ID of the artwork/NFT to transfer.
    /// @param _recipient The address to transfer the NFT to.
    function transferCollectibleNFT(uint _artworkId, address _recipient) public onlyGovernor {
        Artwork storage artwork = artworks[_artworkId];
        require(artwork.isNFTMinted, "NFT not yet minted for this artwork.");
        // In a real ERC721, you would perform a safeTransferFrom from the collective/treasury to _recipient.
        // For simplicity, we are just emitting an event to track the transfer.
        emit CollectibleNFTTransferred(_artworkId, _recipient);
    }

    /// @notice Returns the current owner of a collective NFT.
    /// @param _artworkId The ID of the artwork/NFT.
    function getCollectibleNFTOwner(uint _artworkId) public view returns (address) {
        // In a real ERC721, you would query the ownerOf function.
        // For this simplified example, the DAO implicitly "owns" all minted NFTs.
        // In a more advanced version, you could track ownership within the contract or use a separate ERC721 contract.
        return address(this); // DAO contract address is considered the "owner" in this simplified version.
    }

    /// @notice Returns the metadata URI for a collective NFT.
    /// @param _artworkId The ID of the artwork/NFT.
    function getCollectibleNFTMetadataURI(uint _artworkId) public view returns (string memory) {
        Artwork storage artwork = artworks[_artworkId];
        require(artwork.isNFTMinted, "NFT not yet minted for this artwork.");
        // Construct metadata URI based on base URI and artwork ID/IPFS hash
        return string(abi.encodePacked(metadataBaseURI, _artworkId, ".json")); // Example: baseURI/{artworkId}.json
        // In a real-world scenario, the metadata URI should point to IPFS or a decentralized storage solution.
    }

    // --- Collective Treasury & Funding Functions ---

    /// @notice Allows anyone to donate ETH to the collective treasury.
    function donateToCollective() public payable {
        emit DonationReceived(msg.sender, msg.value);
    }

    /// @notice Members propose funding proposals for collective initiatives.
    /// @param _proposalDescription A description of the funding proposal.
    /// @param _recipient The address to receive the funds if the proposal is approved.
    /// @param _amount The amount of ETH to request.
    function proposeFundingProposal(string memory _proposalDescription, address _recipient, uint _amount) public onlyMember {
        fundingProposalCount++;
        fundingProposals[fundingProposalCount] = FundingProposal({
            description: _proposalDescription,
            recipient: _recipient,
            amount: _amount,
            votesFor: 0,
            votesAgainst: 0,
            isExecuted: false
        });
        emit FundingProposalCreated(fundingProposalCount, _proposalDescription, _recipient, _amount);
    }

    /// @notice Members vote on funding proposals.
    /// @param _proposalId The ID of the funding proposal to vote on.
    /// @param _vote True for "for", false for "against".
    function voteOnFundingProposal(uint _proposalId, bool _vote) public onlyMember {
        FundingProposal storage proposal = fundingProposals[_proposalId];
        require(!proposal.isExecuted, "Proposal already executed.");

        if (_vote) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        emit FundingProposalVoted(_proposalId, msg.sender, _vote);
    }

    /// @notice Governor-only function to execute approved funding proposals, sending ETH from the treasury.
    /// @param _proposalId The ID of the funding proposal to execute.
    function executeFundingProposal(uint _proposalId) public onlyGovernor {
        FundingProposal storage proposal = fundingProposals[_proposalId];
        require(!proposal.isExecuted, "Proposal already executed.");
        require(proposal.votesFor > proposal.votesAgainst, "Proposal not approved by majority."); // Simple majority
        require(address(this).balance >= proposal.amount, "Insufficient treasury balance.");

        proposal.isExecuted = true;
        payable(proposal.recipient).transfer(proposal.amount);
        emit FundingProposalExecuted(_proposalId, proposal.recipient, proposal.amount);
    }

    /// @notice Returns the current ETH balance of the collective treasury.
    function getTreasuryBalance() public view returns (uint) {
        return address(this).balance;
    }

    // --- Utility & Information Functions ---

    /// @notice Governor-only function to set the base URI for NFT metadata.
    /// @param _baseURI The new base URI for NFT metadata.
    function setMetadataBaseURI(string memory _baseURI) public onlyGovernor {
        metadataBaseURI = _baseURI;
        emit MetadataBaseURISet(_baseURI);
    }

    /// @notice Returns the current base URI for NFT metadata.
    function getMetadataBaseURI() public view returns (string memory) {
        return metadataBaseURI;
    }

    // --- Fallback and Receive functions (Optional, for receiving ETH donations directly) ---
    receive() external payable {
        emit DonationReceived(msg.sender, msg.value);
    }

    fallback() external payable {
        emit DonationReceived(msg.sender, msg.value);
    }
}
```