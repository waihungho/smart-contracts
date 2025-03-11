```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Collective (DAAC) - Smart Contract Outline & Summary
 * @author Bard (AI Assistant)
 * @dev A smart contract for a decentralized art collective, enabling artists to submit, curate, exhibit, and monetize digital art pieces through community governance and innovative features.
 *
 * Function Summary:
 *
 * 1.  initializeContract(string _collectiveName, address _initialAdmin): Initializes the contract with a collective name and sets the initial admin.
 * 2.  setCollectiveName(string _newName): Allows the admin to change the collective's name.
 * 3.  submitArt(string _title, string _description, string _ipfsHash, uint256 _royaltyPercentage): Artists can submit their artwork proposals.
 * 4.  voteOnArtSubmission(uint256 _submissionId, bool _approve): Members can vote to approve or reject submitted artwork.
 * 5.  mintArtNFT(uint256 _submissionId): Mints an NFT for approved artwork after successful voting.
 * 6.  setBaseURI(string _baseURI): Sets the base URI for NFT metadata.
 * 7.  purchaseArtNFT(uint256 _tokenId): Allows anyone to purchase an art NFT from the collective.
 * 8.  setArtPrice(uint256 _tokenId, uint256 _newPrice): Admin/Curators can set or update the price of an art NFT.
 * 9.  transferArtOwnership(uint256 _tokenId, address _newOwner): Allows NFT owners to transfer ownership (standard ERC721 function).
 * 10. createExhibition(string _exhibitionName, uint256 _startTime, uint256 _endTime): Admin/Curators can create virtual art exhibitions.
 * 11. addArtToExhibition(uint256 _exhibitionId, uint256 _tokenId): Admin/Curators can add approved artworks to an exhibition.
 * 12. removeArtFromExhibition(uint256 _exhibitionId, uint256 _tokenId): Admin/Curators can remove artworks from an exhibition.
 * 13. proposeCollectiveRuleChange(string _proposalDescription, string _ruleDetails): Members can propose changes to collective rules.
 * 14. voteOnRuleChange(uint256 _proposalId, bool _approve): Members can vote on proposed rule changes.
 * 15. executeRuleChange(uint256 _proposalId): Admin executes approved rule changes after successful voting.
 * 16. donateToCollective(): Allows anyone to donate ETH to the collective treasury.
 * 17. withdrawFromTreasury(address _recipient, uint256 _amount): Admin can withdraw funds from the treasury (potentially for collective initiatives, artist grants, etc.).
 * 18. setMembershipFee(uint256 _newFee): Admin can set or update the membership fee to join the collective.
 * 19. joinCollective(): Allows users to become members by paying the membership fee.
 * 20. leaveCollective(): Allows members to leave the collective (potentially with refund logic based on rules).
 * 21. getArtDetails(uint256 _tokenId): Returns details of a specific art NFT.
 * 22. getSubmissionDetails(uint256 _submissionId): Returns details of an art submission.
 * 23. getExhibitionDetails(uint256 _exhibitionId): Returns details of an art exhibition.
 * 24. getCollectiveBalance(): Returns the current balance of the collective treasury.
 * 25. getMemberCount(): Returns the number of members in the collective.
 * 26. isMember(address _account): Checks if an address is a member of the collective.
 * 27. renounceAdminRole(): Allows the current admin to renounce their admin role.
 * 28. transferAdminRole(address _newAdmin): Allows the current admin to transfer the admin role to a new address.
 */

contract DecentralizedArtCollective {
    string public collectiveName;
    address public admin;
    uint256 public membershipFee;
    mapping(address => bool) public members;
    uint256 public memberCount;

    uint256 public submissionCounter;
    mapping(uint256 => ArtSubmission) public artSubmissions;
    struct ArtSubmission {
        address artist;
        string title;
        string description;
        string ipfsHash;
        uint256 royaltyPercentage;
        uint256 upvotes;
        uint256 downvotes;
        bool approved;
        bool minted;
    }

    uint256 public proposalCounter;
    mapping(uint256 => RuleChangeProposal) public ruleChangeProposals;
    struct RuleChangeProposal {
        address proposer;
        string description;
        string ruleDetails;
        uint256 upvotes;
        uint256 downvotes;
        bool approved;
        bool executed;
    }

    uint256 public exhibitionCounter;
    mapping(uint256 => ArtExhibition) public artExhibitions;
    struct ArtExhibition {
        string name;
        uint256 startTime;
        uint256 endTime;
        uint256[] artTokenIds;
        bool isActive;
    }

    string public baseURI;

    // NFT related mappings and counters (Simplified ERC721-like structure)
    uint256 public tokenCounter;
    mapping(uint256 => address) public tokenOwners;
    mapping(uint256 => uint256) public tokenPrices; // Price in wei
    mapping(uint256 => uint256) public tokenRoyaltyPercentage; // Royalty percentage for artists

    event CollectiveInitialized(string collectiveName, address admin);
    event CollectiveNameChanged(string newName);
    event ArtSubmitted(uint256 submissionId, address artist, string title);
    event ArtVoteCast(uint256 submissionId, address voter, bool approve);
    event ArtMinted(uint256 tokenId, uint256 submissionId, address artist);
    event BaseURISet(string baseURI);
    event ArtPurchased(uint256 tokenId, address buyer, uint256 price);
    event ArtPriceSet(uint256 tokenId, uint256 newPrice);
    event ArtOwnershipTransferred(uint256 tokenId, address from, address to);
    event ExhibitionCreated(uint256 exhibitionId, string exhibitionName);
    event ArtAddedToExhibition(uint256 exhibitionId, uint256 tokenId);
    event ArtRemovedFromExhibition(uint256 exhibitionId, uint256 tokenId);
    event RuleChangeProposed(uint256 proposalId, address proposer, string description);
    event RuleChangeVoteCast(uint256 proposalId, address voter, bool approve);
    event RuleChangeExecuted(uint256 proposalId);
    event DonationReceived(address donor, uint256 amount);
    event TreasuryWithdrawal(address recipient, uint256 amount);
    event MembershipFeeSet(uint256 newFee);
    event MemberJoined(address member);
    event MemberLeft(address member);
    event AdminRoleRenounced(address oldAdmin);
    event AdminRoleTransferred(address oldAdmin, address newAdmin);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action.");
        _;
    }

    modifier onlyMembers() {
        require(members[msg.sender], "Only members can perform this action.");
        _;
    }

    modifier validSubmissionId(uint256 _submissionId) {
        require(_submissionId > 0 && _submissionId <= submissionCounter, "Invalid submission ID.");
        _;
    }

    modifier validProposalId(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= proposalCounter, "Invalid proposal ID.");
        _;
    }

    modifier validExhibitionId(uint256 _exhibitionId) {
        require(_exhibitionId > 0 && _exhibitionId <= exhibitionCounter, "Invalid exhibition ID.");
        _;
    }

    modifier validTokenId(uint256 _tokenId) {
        require(_tokenId > 0 && tokenOwners[_tokenId] != address(0), "Invalid token ID.");
        _;
    }

    modifier submissionNotMinted(uint256 _submissionId) {
        require(!artSubmissions[_submissionId].minted, "Art for this submission already minted.");
        _;
    }

    modifier submissionApproved(uint256 _submissionId) {
        require(artSubmissions[_submissionId].approved, "Art submission not yet approved.");
        _;
    }


    constructor() {
        // Constructor is intentionally left empty. Use initializeContract for setup.
    }

    /**
     * @dev Initializes the contract with a collective name and sets the initial admin.
     * Can only be called once.
     * @param _collectiveName The name of the art collective.
     * @param _initialAdmin The address of the initial admin.
     */
    function initializeContract(string memory _collectiveName, address _initialAdmin) public {
        require(admin == address(0), "Contract already initialized."); // Prevent re-initialization
        collectiveName = _collectiveName;
        admin = _initialAdmin;
        emit CollectiveInitialized(_collectiveName, _initialAdmin);
    }

    /**
     * @dev Allows the admin to change the collective's name.
     * @param _newName The new name for the collective.
     */
    function setCollectiveName(string memory _newName) public onlyAdmin {
        collectiveName = _newName;
        emit CollectiveNameChanged(_newName);
    }

    /**
     * @dev Artists can submit their artwork proposals.
     * @param _title The title of the artwork.
     * @param _description A description of the artwork.
     * @param _ipfsHash The IPFS hash of the artwork's digital file.
     * @param _royaltyPercentage The royalty percentage for the artist on secondary sales (0-100).
     */
    function submitArt(
        string memory _title,
        string memory _description,
        string memory _ipfsHash,
        uint256 _royaltyPercentage
    ) public onlyMembers {
        require(_royaltyPercentage <= 100, "Royalty percentage must be between 0 and 100.");
        submissionCounter++;
        artSubmissions[submissionCounter] = ArtSubmission({
            artist: msg.sender,
            title: _title,
            description: _description,
            ipfsHash: _ipfsHash,
            royaltyPercentage: _royaltyPercentage,
            upvotes: 0,
            downvotes: 0,
            approved: false,
            minted: false
        });
        emit ArtSubmitted(submissionCounter, msg.sender, _title);
    }

    /**
     * @dev Members can vote to approve or reject submitted artwork.
     * @param _submissionId The ID of the art submission to vote on.
     * @param _approve True to approve, false to reject.
     */
    function voteOnArtSubmission(uint256 _submissionId, bool _approve) public onlyMembers validSubmissionId(_submissionId) {
        require(!artSubmissions[_submissionId].approved && !artSubmissions[_submissionId].minted, "Submission already finalized."); // Prevent voting after approval/minting
        if (_approve) {
            artSubmissions[_submissionId].upvotes++;
        } else {
            artSubmissions[_submissionId].downvotes++;
        }
        // Simple majority for approval (can be made more complex with quorum, etc.)
        if (artSubmissions[_submissionId].upvotes > artSubmissions[_submissionId].downvotes) {
            artSubmissions[_submissionId].approved = true;
        }
        emit ArtVoteCast(_submissionId, msg.sender, _approve);
    }

    /**
     * @dev Mints an NFT for approved artwork after successful voting.
     * Only admin or designated curator role can mint. (Simplified to admin for this example)
     * @param _submissionId The ID of the approved art submission.
     */
    function mintArtNFT(uint256 _submissionId) public onlyAdmin validSubmissionId(_submissionId) submissionApproved(_submissionId) submissionNotMinted(_submissionId) {
        tokenCounter++;
        tokenOwners[tokenCounter] = artSubmissions[_submissionId].artist; // Artist becomes initial owner
        tokenPrices[tokenCounter] = 0; // Set initial price to 0, admin can set later
        tokenRoyaltyPercentage[tokenCounter] = artSubmissions[_submissionId].royaltyPercentage;
        artSubmissions[_submissionId].minted = true;
        emit ArtMinted(tokenCounter, _submissionId, artSubmissions[_submissionId].artist);
    }

    /**
     * @dev Sets the base URI for NFT metadata.
     * @param _baseURI The base URI string (e.g., "ipfs://your-metadata-folder/").
     */
    function setBaseURI(string memory _baseURI) public onlyAdmin {
        baseURI = _baseURI;
        emit BaseURISet(_baseURI);
    }

    /**
     * @dev Allows anyone to purchase an art NFT from the collective.
     * @param _tokenId The ID of the NFT to purchase.
     */
    function purchaseArtNFT(uint256 _tokenId) payable public validTokenId(_tokenId) {
        require(tokenPrices[_tokenId] > 0, "Art is not for sale or price not set.");
        require(msg.value >= tokenPrices[_tokenId], "Insufficient funds sent.");

        address previousOwner = tokenOwners[_tokenId];
        uint256 price = tokenPrices[_tokenId];
        uint256 royaltyAmount = (price * tokenRoyaltyPercentage[_tokenId]) / 100;
        uint256 collectiveShare = price - royaltyAmount;

        tokenOwners[_tokenId] = msg.sender;
        tokenPrices[_tokenId] = 0; // Reset price after purchase

        // Transfer funds: Royalty to artist, remainder to collective treasury
        payable(getArtOriginalArtist(_tokenId)).transfer(royaltyAmount); // Pay royalty to original artist
        payable(address(this)).transfer(collectiveShare); // Send collective share to contract

        emit ArtPurchased(_tokenId, msg.sender, price);
        emit ArtOwnershipTransferred(_tokenId, previousOwner, msg.sender);
    }

    /**
     * @dev Admin/Curators can set or update the price of an art NFT.
     * @param _tokenId The ID of the NFT to set the price for.
     * @param _newPrice The new price in wei.
     */
    function setArtPrice(uint256 _tokenId, uint256 _newPrice) public onlyAdmin validTokenId(_tokenId) {
        tokenPrices[_tokenId] = _newPrice;
        emit ArtPriceSet(_tokenId, _newPrice);
    }

    /**
     * @dev Allows NFT owners to transfer ownership (standard ERC721 function).
     * @param _tokenId The ID of the NFT to transfer.
     * @param _newOwner The address of the new owner.
     */
    function transferArtOwnership(uint256 _tokenId, address _newOwner) public validTokenId(_tokenId) {
        require(tokenOwners[_tokenId] == msg.sender, "Only current owner can transfer.");
        address previousOwner = tokenOwners[_tokenId];
        tokenOwners[_tokenId] = _newOwner;
        emit ArtOwnershipTransferred(_tokenId, previousOwner, _newOwner);
    }

    /**
     * @dev Admin/Curators can create virtual art exhibitions.
     * @param _exhibitionName The name of the exhibition.
     * @param _startTime Unix timestamp for the exhibition start time.
     * @param _endTime Unix timestamp for the exhibition end time.
     */
    function createExhibition(string memory _exhibitionName, uint256 _startTime, uint256 _endTime) public onlyAdmin {
        exhibitionCounter++;
        artExhibitions[exhibitionCounter] = ArtExhibition({
            name: _exhibitionName,
            startTime: _startTime,
            endTime: _endTime,
            artTokenIds: new uint256[](0),
            isActive: true // Assume active upon creation
        });
        emit ExhibitionCreated(exhibitionCounter, _exhibitionName);
    }

    /**
     * @dev Admin/Curators can add approved artworks to an exhibition.
     * @param _exhibitionId The ID of the exhibition.
     * @param _tokenId The ID of the art NFT to add.
     */
    function addArtToExhibition(uint256 _exhibitionId, uint256 _tokenId) public onlyAdmin validExhibitionId(_exhibitionId) validTokenId(_tokenId) {
        artExhibitions[_exhibitionId].artTokenIds.push(_tokenId);
        emit ArtAddedToExhibition(_exhibitionId, _tokenId);
    }

    /**
     * @dev Admin/Curators can remove artworks from an exhibition.
     * @param _exhibitionId The ID of the exhibition.
     * @param _tokenId The ID of the art NFT to remove.
     */
    function removeArtFromExhibition(uint256 _exhibitionId, uint256 _tokenId) public onlyAdmin validExhibitionId(_exhibitionId) validTokenId(_tokenId) {
        uint256[] storage artTokenIds = artExhibitions[_exhibitionId].artTokenIds;
        for (uint256 i = 0; i < artTokenIds.length; i++) {
            if (artTokenIds[i] == _tokenId) {
                // Remove the element by shifting elements to the left (preserving order not guaranteed, but efficient for removal)
                for (uint256 j = i; j < artTokenIds.length - 1; j++) {
                    artTokenIds[j] = artTokenIds[j + 1];
                }
                artTokenIds.pop(); // Remove the last element (which is now a duplicate or zero)
                emit ArtRemovedFromExhibition(_exhibitionId, _tokenId);
                return;
            }
        }
        revert("Art not found in exhibition.");
    }

    /**
     * @dev Members can propose changes to collective rules.
     * @param _proposalDescription A brief description of the proposed rule change.
     * @param _ruleDetails Detailed explanation of the rule change.
     */
    function proposeCollectiveRuleChange(string memory _proposalDescription, string memory _ruleDetails) public onlyMembers {
        proposalCounter++;
        ruleChangeProposals[proposalCounter] = RuleChangeProposal({
            proposer: msg.sender,
            description: _proposalDescription,
            ruleDetails: _ruleDetails,
            upvotes: 0,
            downvotes: 0,
            approved: false,
            executed: false
        });
        emit RuleChangeProposed(proposalCounter, msg.sender, _proposalDescription);
    }

    /**
     * @dev Members can vote on proposed rule changes.
     * @param _proposalId The ID of the rule change proposal.
     * @param _approve True to approve, false to reject.
     */
    function voteOnRuleChange(uint256 _proposalId, bool _approve) public onlyMembers validProposalId(_proposalId) {
        require(!ruleChangeProposals[_proposalId].approved && !ruleChangeProposals[_proposalId].executed, "Proposal already finalized."); // Prevent voting after approval/execution
        if (_approve) {
            ruleChangeProposals[_proposalId].upvotes++;
        } else {
            ruleChangeProposals[_proposalId].downvotes++;
        }
        // Simple majority for approval (can be made more complex with quorum, etc.)
        if (ruleChangeProposals[_proposalId].upvotes > ruleChangeProposals[_proposalId].downvotes) {
            ruleChangeProposals[_proposalId].approved = true;
        }
        emit RuleChangeVoteCast(_proposalId, msg.sender, _approve);
    }

    /**
     * @dev Admin executes approved rule changes after successful voting.
     * @param _proposalId The ID of the approved rule change proposal.
     */
    function executeRuleChange(uint256 _proposalId) public onlyAdmin validProposalId(_proposalId) {
        require(ruleChangeProposals[_proposalId].approved && !ruleChangeProposals[_proposalId].executed, "Proposal not approved or already executed.");
        ruleChangeProposals[_proposalId].executed = true;
        // In a real implementation, this function would contain logic to actually apply the rule change.
        // For this example, we are just marking it as executed.
        emit RuleChangeExecuted(_proposalId);
    }

    /**
     * @dev Allows anyone to donate ETH to the collective treasury.
     */
    function donateToCollective() payable public {
        emit DonationReceived(msg.sender, msg.value);
    }

    /**
     * @dev Admin can withdraw funds from the treasury (potentially for collective initiatives, artist grants, etc.).
     * @param _recipient The address to receive the withdrawn funds.
     * @param _amount The amount to withdraw in wei.
     */
    function withdrawFromTreasury(address _recipient, uint256 _amount) public onlyAdmin {
        payable(_recipient).transfer(_amount);
        emit TreasuryWithdrawal(_recipient, _amount);
    }

    /**
     * @dev Admin can set or update the membership fee to join the collective.
     * @param _newFee The new membership fee in wei.
     */
    function setMembershipFee(uint256 _newFee) public onlyAdmin {
        membershipFee = _newFee;
        emit MembershipFeeSet(_newFee);
    }

    /**
     * @dev Allows users to become members by paying the membership fee.
     */
    function joinCollective() payable public {
        require(!members[msg.sender], "Already a member.");
        require(msg.value >= membershipFee, "Membership fee not paid.");
        members[msg.sender] = true;
        memberCount++;
        emit MemberJoined(msg.sender);
    }

    /**
     * @dev Allows members to leave the collective (potentially with refund logic based on rules).
     * Refund logic is simplified here - no refund in this example.
     */
    function leaveCollective() public onlyMembers {
        require(members[msg.sender], "Not a member.");
        members[msg.sender] = false;
        memberCount--;
        emit MemberLeft(msg.sender);
    }

    /**
     * @dev Returns details of a specific art NFT.
     * @param _tokenId The ID of the art NFT.
     * @return title, description, ipfsHash, royaltyPercentage, artist, price, owner
     */
    function getArtDetails(uint256 _tokenId) public view validTokenId(_tokenId) returns (string memory title, string memory description, string memory ipfsHash, uint256 royaltyPercentage, address artist, uint256 price, address owner) {
        uint256 submissionId = getTokenSubmissionId(_tokenId); // Assuming you have a way to link token to submission
        require(submissionId > 0 && submissionId <= submissionCounter, "Invalid token or submission link."); // Basic check
        ArtSubmission storage submission = artSubmissions[submissionId];
        return (submission.title, submission.description, submission.ipfsHash, submission.royaltyPercentage, submission.artist, tokenPrices[_tokenId], tokenOwners[_tokenId]);
    }

    /**
     * @dev Returns details of an art submission.
     * @param _submissionId The ID of the art submission.
     * @return artist, title, description, ipfsHash, royaltyPercentage, upvotes, downvotes, approved, minted
     */
    function getSubmissionDetails(uint256 _submissionId) public view validSubmissionId(_submissionId) returns (address artist, string memory title, string memory description, string memory ipfsHash, uint256 royaltyPercentage, uint256 upvotes, uint256 downvotes, bool approved, bool minted) {
        ArtSubmission storage submission = artSubmissions[_submissionId];
        return (submission.artist, submission.title, submission.description, submission.ipfsHash, submission.royaltyPercentage, submission.upvotes, submission.downvotes, submission.approved, submission.minted);
    }

    /**
     * @dev Returns details of an art exhibition.
     * @param _exhibitionId The ID of the art exhibition.
     * @return name, startTime, endTime, artTokenIds, isActive
     */
    function getExhibitionDetails(uint256 _exhibitionId) public view validExhibitionId(_exhibitionId) returns (string memory name, uint256 startTime, uint256 endTime, uint256[] memory artTokenIds, bool isActive) {
        ArtExhibition storage exhibition = artExhibitions[_exhibitionId];
        return (exhibition.name, exhibition.startTime, exhibition.endTime, exhibition.artTokenIds, exhibition.isActive);
    }

    /**
     * @dev Returns the current balance of the collective treasury.
     * @return The balance of the contract in wei.
     */
    function getCollectiveBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Returns the number of members in the collective.
     * @return The number of members.
     */
    function getMemberCount() public view returns (uint256) {
        return memberCount;
    }

    /**
     * @dev Checks if an address is a member of the collective.
     * @param _account The address to check.
     * @return True if the address is a member, false otherwise.
     */
    function isMember(address _account) public view returns (bool) {
        return members[_account];
    }

    /**
     * @dev Allows the current admin to renounce their admin role.
     * Can only be called by the current admin. Admin role becomes address(0) after renouncing.
     */
    function renounceAdminRole() public onlyAdmin {
        address oldAdmin = admin;
        admin = address(0);
        emit AdminRoleRenounced(oldAdmin);
    }

    /**
     * @dev Allows the current admin to transfer the admin role to a new address.
     * Can only be called by the current admin.
     * @param _newAdmin The address of the new admin.
     */
    function transferAdminRole(address _newAdmin) public onlyAdmin {
        require(_newAdmin != address(0), "New admin address cannot be the zero address.");
        address oldAdmin = admin;
        admin = _newAdmin;
        emit AdminRoleTransferred(oldAdmin, _newAdmin);
    }

    // -------------------- Internal/Helper Functions (Not part of 20+ function count, but useful) --------------------

    /**
     * @dev Internal function to get the original artist of an art NFT.
     * @param _tokenId The ID of the art NFT.
     * @return The address of the original artist.
     */
    function getArtOriginalArtist(uint256 _tokenId) internal view validTokenId(_tokenId) returns (address) {
        uint256 submissionId = getTokenSubmissionId(_tokenId); // Assuming you have a way to link token to submission
        require(submissionId > 0 && submissionId <= submissionCounter, "Invalid token or submission link."); // Basic check
        return artSubmissions[submissionId].artist;
    }

    /**
     * @dev  **Placeholder**:  Internal function to link a tokenId to its original submissionId.
     * In a real implementation, you might store this mapping or derive it differently.
     * This is a simplified example.
     * @param _tokenId The ID of the art NFT.
     * @return The submission ID associated with the token.
     */
    function getTokenSubmissionId(uint256 _tokenId) internal pure returns (uint256) {
        // In a real implementation, you would need to store this link.
        // For this example, we are just assuming a simple 1:1 mapping for demonstration purposes.
        return _tokenId; //  **IMPORTANT: In a real contract, this would NOT be simply _tokenId. You'd need a mapping or other logic.**
    }

    /**
     * @dev  **Placeholder**:  Function to get the metadata URI for an NFT.
     * In a real implementation, this would construct the URI based on baseURI and tokenId.
     * This is a simplified example.
     * @param _tokenId The ID of the art NFT.
     * @return The metadata URI string.
     */
    function tokenURI(uint256 _tokenId) public view validTokenId(_tokenId) returns (string memory) {
        // In a real implementation, you would construct the URI based on baseURI and tokenId.
        // For example: return string(abi.encodePacked(baseURI, Strings.toString(_tokenId), ".json"));
        // For this simplified example, just return a placeholder.
        return string(abi.encodePacked(baseURI, "metadata/", Strings.toString(_tokenId), ".json"));
    }
}

// --- Helper Library (Import or include if not already in your project) ---
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    function toString(uint256 value) internal pure returns (string memory) {
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
}
```