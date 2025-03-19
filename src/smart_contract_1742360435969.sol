```solidity
/**
 * @title Decentralized Autonomous Art Gallery - Smart Contract
 * @author Bard (AI Assistant)
 * @dev A sophisticated smart contract implementing a Decentralized Autonomous Art Gallery.
 *      It features advanced concepts like dynamic NFT metadata, decentralized curation,
 *      artist royalty management, community governance through proposals and voting,
 *      and a staking mechanism for gallery membership and enhanced features.
 *
 * **Outline and Function Summary:**
 *
 * **1. Core NFT Functionality (ArtNFT):**
 *    - `mintArtNFT(string memory _metadataURI)`: Allows artists to mint unique Art NFTs with dynamic metadata.
 *    - `transferArtNFT(address _to, uint256 _tokenId)`: Standard NFT transfer function.
 *    - `getArtNFTOwner(uint256 _tokenId)`: Returns the owner of a specific Art NFT.
 *    - `getArtNFTMetadataURI(uint256 _tokenId)`: Retrieves the current metadata URI of an Art NFT.
 *    - `setArtNFTMetadataURI(uint256 _tokenId, string memory _newMetadataURI)`: Allows the NFT owner to update metadata (with potential restrictions).
 *
 * **2. Gallery Curation and Listing:**
 *    - `proposeArtListing(uint256 _tokenId)`: Allows community members to propose an Art NFT for gallery listing.
 *    - `voteOnArtListing(uint256 _proposalId, bool _vote)`: Registered gallery members vote on art listing proposals.
 *    - `listArtInGallery(uint256 _tokenId)`: Admin function to officially list an approved Art NFT in the gallery.
 *    - `removeArtFromGallery(uint256 _tokenId)`: Admin function to remove an Art NFT from the gallery.
 *    - `isArtListed(uint256 _tokenId)`: Checks if an Art NFT is currently listed in the gallery.
 *    - `getGalleryListings()`: Returns a list of currently listed Art NFT token IDs.
 *
 * **3. Artist Royalty Management:**
 *    - `setArtistRoyalty(uint256 _tokenId, uint256 _royaltyPercentage)`: Allows the original artist to set a royalty percentage for secondary sales.
 *    - `getArtistRoyalty(uint256 _tokenId)`: Retrieves the royalty percentage for a specific Art NFT.
 *    - `withdrawArtistRoyalties()`: Allows artists to withdraw accumulated royalties.
 *
 * **4. Community Governance and Proposals:**
 *    - `createProposal(string memory _title, string memory _description, bytes memory _calldata)`: Registered members can create proposals for gallery changes.
 *    - `voteOnProposal(uint256 _proposalId, bool _vote)`: Registered members vote on governance proposals.
 *    - `executeProposal(uint256 _proposalId)`: Admin function to execute approved governance proposals after voting period.
 *    - `getProposalDetails(uint256 _proposalId)`: Retrieves details of a specific governance proposal.
 *    - `getProposalVotingStatus(uint256 _proposalId)`: Gets the current voting status (open/closed, votes for/against) of a proposal.
 *
 * **5. Gallery Membership and Staking (Advanced):**
 *    - `stakeForMembership()`: Users stake ETH to become registered gallery members and gain voting rights.
 *    - `unstakeMembership()`: Allows members to unstake ETH and lose membership.
 *    - `getMemberStake(address _member)`: Retrieves the stake amount for a member.
 *    - `isGalleryMember(address _user)`: Checks if an address is a registered gallery member.
 *
 * **6. Utility and Admin Functions:**
 *    - `pauseContract()`: Admin function to pause core functionalities in case of emergency.
 *    - `unpauseContract()`: Admin function to unpause the contract.
 *    - `setAdmin(address _newAdmin)`: Admin function to change the contract administrator.
 *    - `getContractBalance()`: Returns the ETH balance of the contract.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract DecentralizedArtGallery is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _artNFTIds;
    Counters.Counter private _proposalIds;

    string public baseMetadataURI; // Base URI for dynamic metadata

    mapping(uint256 => string) private _artMetadataURIs; // Token ID to Metadata URI
    mapping(uint256 => address) private _artistOfNFT; // Token ID to Original Artist
    mapping(uint256 => uint256) private _artistRoyalties; // Token ID to Royalty Percentage (in basis points - 100 = 1%)
    mapping(uint256 => bool) public isListedInGallery; // Token ID to Gallery Listing Status
    mapping(uint256 => bool) public isArtProposalActive; // Token ID to Art Listing Proposal Status
    mapping(uint256 => uint256) public artListingProposalId; // Token ID to Art Listing Proposal ID

    mapping(uint256 => Proposal) public proposals; // Proposal ID to Proposal details
    mapping(uint256 => mapping(address => bool)) public proposalVotes; // Proposal ID to Voter to Vote Status
    mapping(address => uint256) public memberStakes; // Member Address to Stake Amount
    mapping(address => bool) public isGalleryMemberMap; // Address to Gallery Membership Status

    uint256 public membershipStakeAmount = 1 ether; // Required stake for membership
    uint256 public proposalVoteDuration = 7 days; // Duration for proposals to be active
    uint256 public artListingVoteThreshold = 50; // Percentage of votes needed for art listing approval
    uint256 public governanceVoteThreshold = 60; // Percentage of votes needed for governance proposal approval
    uint256 public royaltyBasisPointsDenominator = 10000; // Denominator for royalty percentage calculations (10000 = 100%)

    struct Proposal {
        string title;
        string description;
        address proposer;
        uint256 startTime;
        uint256 endTime;
        bytes calldataPayload; // Calldata to execute if proposal passes
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        bool active;
    }

    event ArtNFTMinted(uint256 tokenId, address artist, string metadataURI);
    event ArtNFTMetadataUpdated(uint256 tokenId, string newMetadataURI);
    event ArtNFTListedInGallery(uint256 tokenId);
    event ArtNFTRemovedFromGallery(uint256 tokenId);
    event ArtListingProposed(uint256 proposalId, uint256 tokenId, address proposer);
    event GovernanceProposalCreated(uint256 proposalId, string title, address proposer);
    event ProposalVoted(uint256 proposalId, address voter, bool vote);
    event ProposalExecuted(uint256 proposalId);
    event MembershipStaked(address member, uint256 amount);
    event MembershipUnstaked(address member, uint256 amount);
    event ArtistRoyaltySet(uint256 tokenId, uint256 royaltyPercentage);
    event ArtistRoyaltyWithdrawn(address artist, uint256 amount);
    event ContractPaused();
    event ContractUnpaused();
    event AdminChanged(address newAdmin);

    modifier onlyGalleryMember() {
        require(isGalleryMember(msg.sender), "Not a gallery member");
        _;
    }

    modifier onlyAdmin() {
        require(owner() == msg.sender, "Only admin can call this function");
        _;
    }

    modifier whenNotPaused() {
        require(!paused(), "Contract is paused");
        _;
    }

    constructor(string memory _name, string memory _symbol, string memory _baseMetadataURI) ERC721(_name, _symbol) {
        baseMetadataURI = _baseMetadataURI;
    }

    // ------------------------- 1. Core NFT Functionality (ArtNFT) -------------------------

    /**
     * @dev Mints a new Art NFT for the artist, setting initial metadata.
     * @param _metadataURI The URI for the initial metadata of the Art NFT.
     */
    function mintArtNFT(string memory _metadataURI) external whenNotPaused {
        _artNFTIds.increment();
        uint256 tokenId = _artNFTIds.current();
        _safeMint(msg.sender, tokenId);
        _artMetadataURIs[tokenId] = _metadataURI;
        _artistOfNFT[tokenId] = msg.sender;
        emit ArtNFTMinted(tokenId, msg.sender, _metadataURI);
    }

    /**
     * @dev Overrides the base URI for token metadata. Can be used for dynamic metadata.
     * @return string The constructed metadata URI for the given token ID.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory metadataURI = _artMetadataURIs[tokenId];
        if (bytes(metadataURI).length > 0) {
            return metadataURI;
        }
        return string(abi.encodePacked(baseMetadataURI, tokenId.toString()));
    }

    /**
     * @dev Transfers ownership of an Art NFT. Standard ERC721 transfer.
     * @param _to The address to transfer the NFT to.
     * @param _tokenId The ID of the NFT to transfer.
     */
    function transferArtNFT(address _to, uint256 _tokenId) external whenNotPaused {
        safeTransferFrom(msg.sender, _to, _tokenId);
    }

    /**
     * @dev Gets the owner of a specific Art NFT.
     * @param _tokenId The ID of the Art NFT.
     * @return address The owner of the NFT.
     */
    function getArtNFTOwner(uint256 _tokenId) external view returns (address) {
        return ownerOf(_tokenId);
    }

    /**
     * @dev Retrieves the current metadata URI of an Art NFT.
     * @param _tokenId The ID of the Art NFT.
     * @return string The metadata URI of the NFT.
     */
    function getArtNFTMetadataURI(uint256 _tokenId) external view returns (string memory) {
        require(_exists(_tokenId), "Invalid token ID");
        return _artMetadataURIs[_tokenId];
    }

    /**
     * @dev Allows the NFT owner to update the metadata URI of their Art NFT.
     * @param _tokenId The ID of the Art NFT to update.
     * @param _newMetadataURI The new metadata URI.
     */
    function setArtNFTMetadataURI(uint256 _tokenId, string memory _newMetadataURI) external whenNotPaused {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Not approved or owner");
        _artMetadataURIs[_tokenId] = _newMetadataURI;
        emit ArtNFTMetadataUpdated(_tokenId, _newMetadataURI);
    }

    // ------------------------- 2. Gallery Curation and Listing -------------------------

    /**
     * @dev Allows a gallery member to propose an Art NFT for listing in the gallery.
     * @param _tokenId The ID of the Art NFT to propose for listing.
     */
    function proposeArtListing(uint256 _tokenId) external onlyGalleryMember whenNotPaused {
        require(_exists(_tokenId), "Invalid token ID");
        require(!isListedInGallery[_tokenId], "Art already listed in gallery");
        require(!isArtProposalActive[_tokenId], "Art already has an active proposal");

        _proposalIds.increment();
        uint256 proposalId = _proposalIds.current();

        proposals[proposalId] = Proposal({
            title: string(abi.encodePacked("List Art NFT #", _tokenId.toString(), " in Gallery")),
            description: string(abi.encodePacked("Proposal to list Art NFT #", _tokenId.toString(), " in the gallery.")),
            proposer: msg.sender,
            startTime: block.timestamp,
            endTime: block.timestamp + proposalVoteDuration,
            calldataPayload: abi.encodeWithSignature("listArtInGallery(uint256)", _tokenId), // Call to listArtInGallery if proposal passes
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            active: true
        });

        isArtProposalActive[_tokenId] = true;
        artListingProposalId[_tokenId] = proposalId;
        emit ArtListingProposed(proposalId, _tokenId, msg.sender);
    }

    /**
     * @dev Registered gallery members can vote on an active art listing proposal.
     * @param _proposalId The ID of the art listing proposal.
     * @param _vote True for voting in favor, false for voting against.
     */
    function voteOnArtListing(uint256 _proposalId, bool _vote) external onlyGalleryMember whenNotPaused {
        require(proposals[_proposalId].active, "Proposal is not active");
        require(block.timestamp <= proposals[_proposalId].endTime, "Voting period ended");
        require(!proposalVotes[_proposalId][msg.sender], "Already voted on this proposal");

        proposalVotes[_proposalId][msg.sender] = true;
        if (_vote) {
            proposals[_proposalId].votesFor++;
        } else {
            proposals[_proposalId].votesAgainst++;
        }
        emit ProposalVoted(_proposalId, msg.sender, _vote);
    }

    /**
     * @dev Admin function to officially list an approved Art NFT in the gallery after proposal passes.
     * @param _tokenId The ID of the Art NFT to list.
     */
    function listArtInGallery(uint256 _tokenId) external onlyAdmin whenNotPaused {
        require(_exists(_tokenId), "Invalid token ID");
        require(!isListedInGallery[_tokenId], "Art already listed in gallery");

        uint256 proposalId = artListingProposalId[_tokenId];
        require(proposals[proposalId].active == false || block.timestamp > proposals[proposalId].endTime, "Proposal voting still active"); // Ensure proposal period ended
        require(calculateVotePercentage(proposals[proposalId].votesFor, proposals[proposalId].votesFor + proposals[proposalId].votesAgainst) >= artListingVoteThreshold, "Proposal did not pass voting threshold");
        require(!proposals[proposalId].executed, "Proposal already executed");

        isListedInGallery[_tokenId] = true;
        isArtProposalActive[_tokenId] = false;
        proposals[proposalId].executed = true;
        emit ArtNFTListedInGallery(_tokenId);
        emit ProposalExecuted(proposalId);
    }

    /**
     * @dev Admin function to remove an Art NFT from the gallery.
     * @param _tokenId The ID of the Art NFT to remove.
     */
    function removeArtFromGallery(uint256 _tokenId) external onlyAdmin whenNotPaused {
        require(_exists(_tokenId), "Invalid token ID");
        require(isListedInGallery[_tokenId], "Art not listed in gallery");
        isListedInGallery[_tokenId] = false;
        emit ArtNFTRemovedFromGallery(_tokenId);
    }

    /**
     * @dev Checks if an Art NFT is currently listed in the gallery.
     * @param _tokenId The ID of the Art NFT to check.
     * @return bool True if listed, false otherwise.
     */
    function isArtListed(uint256 _tokenId) external view returns (bool) {
        return isListedInGallery[_tokenId];
    }

    /**
     * @dev Gets a list of token IDs of Art NFTs currently listed in the gallery.
     * @return uint256[] An array of token IDs.
     */
    function getGalleryListings() external view returns (uint256[] memory) {
        uint256 listingCount = 0;
        for (uint256 i = 1; i <= _artNFTIds.current(); i++) {
            if (isListedInGallery[i]) {
                listingCount++;
            }
        }
        uint256[] memory listings = new uint256[](listingCount);
        uint256 index = 0;
        for (uint256 i = 1; i <= _artNFTIds.current(); i++) {
            if (isListedInGallery[i]) {
                listings[index] = i;
                index++;
            }
        }
        return listings;
    }

    // ------------------------- 3. Artist Royalty Management -------------------------

    /**
     * @dev Allows the original artist of an Art NFT to set a royalty percentage for secondary sales.
     * @param _tokenId The ID of the Art NFT.
     * @param _royaltyPercentage The royalty percentage in basis points (e.g., 500 for 5%).
     */
    function setArtistRoyalty(uint256 _tokenId, uint256 _royaltyPercentage) external whenNotPaused {
        require(_artistOfNFT[_tokenId] == msg.sender, "Only original artist can set royalty");
        require(_royaltyPercentage <= royaltyBasisPointsDenominator, "Royalty percentage too high"); // Max 100%
        _artistRoyalties[_tokenId] = _royaltyPercentage;
        emit ArtistRoyaltySet(_tokenId, _royaltyPercentage);
    }

    /**
     * @dev Retrieves the royalty percentage for a specific Art NFT.
     * @param _tokenId The ID of the Art NFT.
     * @return uint256 The royalty percentage in basis points.
     */
    function getArtistRoyalty(uint256 _tokenId) external view returns (uint256) {
        return _artistRoyalties[_tokenId];
    }

    /**
     * @dev Allows artists to withdraw their accumulated royalties from secondary sales.
     *      (Note: In a real-world scenario, royalty distribution would be handled during sales.
     *       This function is a simplified example for demonstration purposes).
     */
    function withdrawArtistRoyalties() external payable whenNotPaused {
        // In a real implementation, track royalties owed to each artist.
        // This is a placeholder for demonstrating function existence.
        // For simplicity, this example just allows withdrawing the contract's balance.
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
        emit ArtistRoyaltyWithdrawn(msg.sender, balance);
    }


    // ------------------------- 4. Community Governance and Proposals -------------------------

    /**
     * @dev Registered gallery members can create governance proposals for contract changes.
     * @param _title Title of the proposal.
     * @param _description Detailed description of the proposal.
     * @param _calldata Calldata to execute if the proposal passes (e.g., function call).
     */
    function createProposal(string memory _title, string memory _description, bytes memory _calldata) external onlyGalleryMember whenNotPaused {
        _proposalIds.increment();
        uint256 proposalId = _proposalIds.current();

        proposals[proposalId] = Proposal({
            title: _title,
            description: _description,
            proposer: msg.sender,
            startTime: block.timestamp,
            endTime: block.timestamp + proposalVoteDuration,
            calldataPayload: _calldata,
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            active: true
        });

        emit GovernanceProposalCreated(proposalId, _title, msg.sender);
    }

    /**
     * @dev Registered gallery members can vote on active governance proposals.
     * @param _proposalId The ID of the governance proposal.
     * @param _vote True for voting in favor, false for voting against.
     */
    function voteOnProposal(uint256 _proposalId, bool _vote) external onlyGalleryMember whenNotPaused {
        require(proposals[_proposalId].active, "Proposal is not active");
        require(block.timestamp <= proposals[_proposalId].endTime, "Voting period ended");
        require(!proposalVotes[_proposalId][msg.sender], "Already voted on this proposal");

        proposalVotes[_proposalId][msg.sender] = true;
        if (_vote) {
            proposals[_proposalId].votesFor++;
        } else {
            proposals[_proposalId].votesAgainst++;
        }
        emit ProposalVoted(_proposalId, msg.sender, _vote);
    }

    /**
     * @dev Admin function to execute an approved governance proposal after the voting period.
     * @param _proposalId The ID of the governance proposal to execute.
     */
    function executeProposal(uint256 _proposalId) external onlyAdmin whenNotPaused {
        require(proposals[_proposalId].active == false || block.timestamp > proposals[_proposalId].endTime, "Proposal voting still active"); // Ensure proposal period ended
        require(calculateVotePercentage(proposals[_proposalId].votesFor, proposals[_proposalId].votesFor + proposals[_proposalId].votesAgainst) >= governanceVoteThreshold, "Proposal did not pass voting threshold");
        require(!proposals[_proposalId].executed, "Proposal already executed");

        (bool success, ) = address(this).call(proposals[_proposalId].calldataPayload);
        require(success, "Proposal execution failed"); // Revert if execution fails

        proposals[_proposalId].executed = true;
        proposals[_proposalId].active = false;
        emit ProposalExecuted(_proposalId);
    }

    /**
     * @dev Retrieves details of a specific governance proposal.
     * @param _proposalId The ID of the proposal.
     * @return Proposal The proposal struct containing details.
     */
    function getProposalDetails(uint256 _proposalId) external view returns (Proposal memory) {
        return proposals[_proposalId];
    }

    /**
     * @dev Gets the current voting status of a proposal (open/closed, votes for/against).
     * @param _proposalId The ID of the proposal.
     * @return bool isActive, uint256 votesFor, uint256 votesAgainst, uint256 endTime
     */
    function getProposalVotingStatus(uint256 _proposalId) external view returns (bool isActive, uint256 votesFor, uint256 votesAgainst, uint256 endTime) {
        return (proposals[_proposalId].active, proposals[_proposalId].votesFor, proposals[_proposalId].votesAgainst, proposals[_proposalId].endTime);
    }


    // ------------------------- 5. Gallery Membership and Staking (Advanced) -------------------------

    /**
     * @dev Allows users to stake ETH to become registered gallery members.
     *      Members gain voting rights and potentially other benefits.
     */
    function stakeForMembership() external payable whenNotPaused {
        require(!isGalleryMemberMap[msg.sender], "Already a gallery member");
        require(msg.value >= membershipStakeAmount, "Stake amount less than required");
        memberStakes[msg.sender] += msg.value;
        isGalleryMemberMap[msg.sender] = true;
        emit MembershipStaked(msg.sender, msg.value);
    }

    /**
     * @dev Allows members to unstake their ETH and lose gallery membership.
     */
    function unstakeMembership() external whenNotPaused {
        require(isGalleryMemberMap[msg.sender], "Not a gallery member");
        uint256 stakedAmount = memberStakes[msg.sender];
        require(stakedAmount > 0, "No stake to unstake");
        memberStakes[msg.sender] = 0;
        isGalleryMemberMap[msg.sender] = false;
        payable(msg.sender).transfer(stakedAmount);
        emit MembershipUnstaked(msg.sender, stakedAmount);
    }

    /**
     * @dev Retrieves the staked amount for a gallery member.
     * @param _member The address of the member.
     * @return uint256 The staked amount in Wei.
     */
    function getMemberStake(address _member) external view returns (uint256) {
        return memberStakes[_member];
    }

    /**
     * @dev Checks if an address is a registered gallery member.
     * @param _user The address to check.
     * @return bool True if member, false otherwise.
     */
    function isGalleryMember(address _user) public view returns (bool) {
        return isGalleryMemberMap[_user];
    }

    // ------------------------- 6. Utility and Admin Functions -------------------------

    /**
     * @dev Admin function to pause core functionalities of the contract.
     */
    function pauseContract() external onlyAdmin {
        _pause();
        emit ContractPaused();
    }

    /**
     * @dev Admin function to unpause the contract, restoring functionalities.
     */
    function unpauseContract() external onlyAdmin {
        _unpause();
        emit ContractUnpaused();
    }

    /**
     * @dev Admin function to change the contract administrator.
     * @param _newAdmin The address of the new administrator.
     */
    function setAdmin(address _newAdmin) external onlyAdmin {
        transferOwnership(_newAdmin);
        emit AdminChanged(_newAdmin);
    }

    /**
     * @dev Gets the ETH balance of the contract.
     * @return uint256 The contract's ETH balance in Wei.
     */
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Helper function to calculate percentage.
     * @param _numerator The numerator.
     * @param _denominator The denominator.
     * @return uint256 The percentage.
     */
    function calculateVotePercentage(uint256 _numerator, uint256 _denominator) internal pure returns (uint256) {
        if (_denominator == 0) return 0; // Avoid division by zero
        return (_numerator * 100) / _denominator;
    }

    // **Optional: Fallback function to receive ETH (for potential future features)**
    receive() external payable {}
}
```