```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Collective (DAAC) - Smart Contract
 * @author Bard (AI Assistant)
 * @dev A smart contract for a Decentralized Autonomous Art Collective (DAAC).
 *      This contract enables artists to submit artwork proposals, community members to vote on them,
 *      and, upon approval, the artworks can be minted as NFTs and sold through a decentralized marketplace.
 *      The contract incorporates advanced concepts like decentralized governance, dynamic revenue splitting,
 *      and a layered voting system for art curation and DAO proposals.
 *
 * Function Summary:
 *
 * --- Artist Functions ---
 * 1. submitArtProposal(string memory _title, string memory _description, string memory _ipfsHash, uint256 _proposalCost): Allows artists to submit art proposals.
 * 2. getArtistProposals(address _artist) view returns (uint256[]): Retrieves the IDs of proposals submitted by a specific artist.
 * 3. withdrawArtistRevenue(): Allows artists to withdraw their earned revenue from art sales.
 * 4. setArtistProfile(string memory _artistName, string memory _artistBio): Allows artists to set or update their public profile.
 * 5. getArtistProfile(address _artist) view returns (string memory, string memory): Retrieves the profile information of an artist.
 *
 * --- Community/DAO Member Functions ---
 * 6. voteOnArtProposal(uint256 _proposalId, bool _vote): Allows DAO members to vote on art proposals.
 * 7. delegateVote(address _delegatee): Allows members to delegate their voting power to another address.
 * 8. proposeDAOAmendment(string memory _proposalTitle, string memory _proposalDescription, bytes memory _calldata): Allows members to propose changes to the DAO itself.
 * 9. voteOnDAOAmendment(uint256 _amendmentId, bool _vote): Allows DAO members to vote on DAO amendment proposals.
 * 10. stakeTokens(uint256 _amount): Allows members to stake tokens to increase their voting power and potentially earn rewards (future feature).
 * 11. unstakeTokens(uint256 _amount): Allows members to unstake tokens.
 * 12. getVotingPower(address _voter) view returns (uint256): Retrieves the voting power of a member.
 *
 * --- Marketplace Functions ---
 * 13. mintArtNFT(uint256 _proposalId): Mints an NFT for an approved art proposal (internal function, triggered after approval).
 * 14. listArtForSale(uint256 _nftId, uint256 _price): Allows NFT owners to list their art for sale on the DAAC marketplace.
 * 15. buyArt(uint256 _listingId): Allows users to buy art listed on the marketplace.
 * 16. cancelListing(uint256 _listingId): Allows NFT owners to cancel their art listing.
 * 17. getAllListings() view returns (uint256[]): Retrieves IDs of all active art listings.
 * 18. getListingDetails(uint256 _listingId) view returns (tuple): Retrieves detailed information about a specific art listing.
 *
 * --- Utility/Admin Functions ---
 * 19. getArtProposalDetails(uint256 _proposalId) view returns (tuple): Retrieves detailed information about an art proposal.
 * 20. getDAOAmendmentDetails(uint256 _amendmentId) view returns (tuple): Retrieves details of a DAO amendment proposal.
 * 21. setDAOFee(uint256 _newFeePercentage): Admin function to set the DAO fee percentage on art sales.
 * 22. withdrawDAOFees(): Admin function to withdraw accumulated DAO fees.
 * 23. setVotingDuration(uint256 _newDurationBlocks): Admin function to set the voting duration for proposals.
 * 24. emergencyPause(): Admin function to pause critical functionalities in case of emergency.
 * 25. emergencyUnpause(): Admin function to resume functionalities after emergency pause.
 */
contract DecentralizedAutonomousArtCollective {

    // -------- State Variables --------

    // --- Core DAO Parameters ---
    address public daoAdmin;
    uint256 public daoFeePercentage = 5; // Percentage of sale price taken as DAO fee
    uint256 public votingDurationBlocks = 100; // Default voting duration in blocks
    bool public paused = false;

    // --- Art Proposals ---
    uint256 public proposalCounter = 0;
    mapping(uint256 => ArtProposal) public artProposals;
    mapping(uint256 => uint256) public proposalVotesCount; // Proposal ID => Vote Count
    mapping(uint256 => mapping(address => bool)) public hasVotedOnProposal; // Proposal ID => Voter Address => Voted?

    struct ArtProposal {
        uint256 id;
        address artist;
        string title;
        string description;
        string ipfsHash;
        uint256 proposalCost;
        uint256 submissionTimestamp;
        uint256 votingDeadline;
        uint256 yesVotes;
        uint256 noVotes;
        bool approved;
        bool minted;
    }

    // --- DAO Amendments ---
    uint256 public amendmentCounter = 0;
    mapping(uint256 => DAOAmendmentProposal) public daoAmendments;
    mapping(uint256 => uint256) public amendmentVotesCount; // Amendment ID => Vote Count
    mapping(uint256 => mapping(address => bool)) public hasVotedOnAmendment; // Amendment ID => Voter Address => Voted?

    struct DAOAmendmentProposal {
        uint256 id;
        address proposer;
        string title;
        string description;
        bytes calldata; // Calldata for DAO changes
        uint256 submissionTimestamp;
        uint256 votingDeadline;
        uint256 yesVotes;
        uint256 noVotes;
        bool approved;
        bool executed;
    }

    // --- Artist Profiles ---
    mapping(address => ArtistProfile) public artistProfiles;
    struct ArtistProfile {
        string artistName;
        string artistBio;
    }

    // --- Marketplace & NFTs ---
    mapping(uint256 => ArtNFT) public artNFTs; // NFT ID => ArtNFT struct
    uint256 public nftCounter = 0;
    mapping(uint256 => ArtListing) public artListings; // Listing ID => ArtListing struct
    uint256 public listingCounter = 0;

    struct ArtNFT {
        uint256 id;
        uint256 proposalId;
        address artist;
        string title;
        string ipfsHash;
        bool listedForSale;
        address currentOwner;
    }

    struct ArtListing {
        uint256 id;
        uint256 nftId;
        uint256 price;
        address seller;
        bool active;
    }

    // --- Revenue & Treasury ---
    mapping(address => uint256) public artistRevenueBalances;
    uint256 public daoTreasuryBalance;

    // --- Voting & Staking (Simplified - can be expanded) ---
    mapping(address => uint256) public stakedTokens; // Address => Staked Token Amount (for voting power)
    uint256 public totalStakedTokens;


    // -------- Events --------
    event ArtProposalSubmitted(uint256 proposalId, address artist, string title);
    event ArtProposalVoted(uint256 proposalId, address voter, bool vote);
    event ArtProposalApproved(uint256 proposalId);
    event ArtNFTMinted(uint256 nftId, uint256 proposalId, address artist, address owner);
    event ArtListedForSale(uint256 listingId, uint256 nftId, uint256 price, address seller);
    event ArtSold(uint256 listingId, uint256 nftId, address buyer, uint256 price);
    event ListingCancelled(uint256 listingId, uint256 nftId);
    event DAOAmendmentProposed(uint256 amendmentId, address proposer, string title);
    event DAOAmendmentVoted(uint256 amendmentId, address voter, bool vote);
    event DAOAmendmentApproved(uint256 amendmentId);
    event DAOAmendmentExecuted(uint256 amendmentId);
    event ArtistProfileUpdated(address artist, string artistName, string artistBio);
    event ArtistRevenueWithdrawn(address artist, uint256 amount);
    event DAOFeesWithdrawn(uint256 amount);
    event TokensStaked(address staker, uint256 amount);
    event TokensUnstaked(address unstaker, uint256 amount);
    event VotingDurationChanged(uint256 newDuration);
    event DAOFeePercentageChanged(uint256 newFee);
    event ContractPaused();
    event ContractUnpaused();


    // -------- Modifiers --------
    modifier onlyDAOAdmin() {
        require(msg.sender == daoAdmin, "Only DAO Admin allowed");
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


    // -------- Constructor --------
    constructor() {
        daoAdmin = msg.sender;
    }


    // ------------------------ Artist Functions ------------------------

    /**
     * @dev Allows artists to submit an art proposal.
     * @param _title Title of the artwork.
     * @param _description Description of the artwork.
     * @param _ipfsHash IPFS hash pointing to the artwork's digital file.
     * @param _proposalCost Cost associated with the proposal (e.g., for materials, minting fees).
     */
    function submitArtProposal(
        string memory _title,
        string memory _description,
        string memory _ipfsHash,
        uint256 _proposalCost
    ) external whenNotPaused {
        proposalCounter++;
        artProposals[proposalCounter] = ArtProposal({
            id: proposalCounter,
            artist: msg.sender,
            title: _title,
            description: _description,
            ipfsHash: _ipfsHash,
            proposalCost: _proposalCost,
            submissionTimestamp: block.timestamp,
            votingDeadline: block.number + votingDurationBlocks,
            yesVotes: 0,
            noVotes: 0,
            approved: false,
            minted: false
        });
        emit ArtProposalSubmitted(proposalCounter, msg.sender, _title);
    }

    /**
     * @dev Retrieves the IDs of proposals submitted by a specific artist.
     * @param _artist Address of the artist.
     * @return Array of proposal IDs.
     */
    function getArtistProposals(address _artist) external view returns (uint256[] memory) {
        uint256[] memory proposalIds = new uint256[](proposalCounter); // Max possible size
        uint256 count = 0;
        for (uint256 i = 1; i <= proposalCounter; i++) {
            if (artProposals[i].artist == _artist) {
                proposalIds[count] = i;
                count++;
            }
        }
        // Resize array to actual number of proposals
        assembly {
            mstore(proposalIds, count) // Update the length of the array
        }
        return proposalIds;
    }

    /**
     * @dev Allows artists to withdraw their earned revenue from art sales.
     */
    function withdrawArtistRevenue() external whenNotPaused {
        uint256 amount = artistRevenueBalances[msg.sender];
        require(amount > 0, "No revenue to withdraw");
        artistRevenueBalances[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
        emit ArtistRevenueWithdrawn(msg.sender, amount);
    }

    /**
     * @dev Allows artists to set or update their public profile.
     * @param _artistName Artist's display name.
     * @param _artistBio Short biography of the artist.
     */
    function setArtistProfile(string memory _artistName, string memory _artistBio) external whenNotPaused {
        artistProfiles[msg.sender] = ArtistProfile({
            artistName: _artistName,
            artistBio: _artistBio
        });
        emit ArtistProfileUpdated(msg.sender, _artistName, _artistBio);
    }

    /**
     * @dev Retrieves the profile information of an artist.
     * @param _artist Address of the artist.
     * @return Artist's name and bio.
     */
    function getArtistProfile(address _artist) external view returns (string memory, string memory) {
        return (artistProfiles[_artist].artistName, artistProfiles[_artist].artistBio);
    }


    // ------------------------ Community/DAO Member Functions ------------------------

    /**
     * @dev Allows DAO members to vote on an art proposal.
     * @param _proposalId ID of the art proposal to vote on.
     * @param _vote True for yes, false for no.
     */
    function voteOnArtProposal(uint256 _proposalId, bool _vote) external whenNotPaused {
        require(artProposals[_proposalId].votingDeadline > block.number, "Voting deadline passed");
        require(!hasVotedOnProposal[_proposalId][msg.sender], "Already voted on this proposal");

        hasVotedOnProposal[_proposalId][msg.sender] = true;
        uint256 votingPower = getVotingPower(msg.sender); // Get voting power (based on staked tokens)

        if (_vote) {
            artProposals[_proposalId].yesVotes += votingPower;
        } else {
            artProposals[_proposalId].noVotes += votingPower;
        }
        emit ArtProposalVoted(_proposalId, msg.sender, _vote);

        // Check if proposal is approved after vote
        if (!artProposals[_proposalId].approved && artProposals[_proposalId].yesVotes > artProposals[_proposalId].noVotes) {
            artProposals[_proposalId].approved = true;
            emit ArtProposalApproved(_proposalId);
            _mintArtNFT(_proposalId); // Mint NFT if approved
        }
    }

    /**
     * @dev Allows members to delegate their voting power to another address.
     * @param _delegatee Address to delegate voting power to.
     * @dev This is a simplified delegation for demonstration. In a real DAO, more robust delegation mechanisms are used.
     */
    mapping(address => address) public voteDelegations;
    function delegateVote(address _delegatee) external whenNotPaused {
        voteDelegations[msg.sender] = _delegatee;
    }

    /**
     * @dev Allows members to propose changes to the DAO itself.
     * @param _proposalTitle Title of the DAO amendment proposal.
     * @param _proposalDescription Description of the amendment.
     * @param _calldata Calldata to execute if the amendment is approved.
     */
    function proposeDAOAmendment(
        string memory _proposalTitle,
        string memory _proposalDescription,
        bytes memory _calldata
    ) external whenNotPaused {
        amendmentCounter++;
        daoAmendments[amendmentCounter] = DAOAmendmentProposal({
            id: amendmentCounter,
            proposer: msg.sender,
            title: _proposalTitle,
            description: _proposalDescription,
            calldata: _calldata,
            submissionTimestamp: block.timestamp,
            votingDeadline: block.number + votingDurationBlocks,
            yesVotes: 0,
            noVotes: 0,
            approved: false,
            executed: false
        });
        emit DAOAmendmentProposed(amendmentCounter, msg.sender, _proposalTitle);
    }

    /**
     * @dev Allows DAO members to vote on DAO amendment proposals.
     * @param _amendmentId ID of the DAO amendment proposal.
     * @param _vote True for yes, false for no.
     */
    function voteOnDAOAmendment(uint256 _amendmentId, bool _vote) external whenNotPaused {
        require(daoAmendments[_amendmentId].votingDeadline > block.number, "Voting deadline passed");
        require(!hasVotedOnAmendment[_amendmentId][msg.sender], "Already voted on this amendment");

        hasVotedOnAmendment[_amendmentId][msg.sender] = true;
        uint256 votingPower = getVotingPower(msg.sender); // Get voting power

        if (_vote) {
            daoAmendments[_amendmentId].yesVotes += votingPower;
        } else {
            daoAmendments[_amendmentId].noVotes += votingPower;
        }
        emit DAOAmendmentVoted(_amendmentId, msg.sender, _vote);

        // Check if amendment is approved
        if (!daoAmendments[_amendmentId].approved && daoAmendments[_amendmentId].yesVotes > daoAmendments[_amendmentId].noVotes) {
            daoAmendments[_amendmentId].approved = true;
            emit DAOAmendmentApproved(_amendmentId);
            _executeDAOAmendment(_amendmentId); // Execute amendment if approved
        }
    }

    /**
     * @dev Allows members to stake tokens to increase their voting power.
     * @param _amount Amount of tokens to stake.
     * @dev In a real application, you would integrate with an actual token contract (e.g., ERC20).
     *      For simplicity, this example uses Ether as "tokens".
     */
    function stakeTokens(uint256 _amount) external payable whenNotPaused {
        require(msg.value == _amount, "Amount sent does not match stake amount"); // Using msg.value as "tokens"
        stakedTokens[msg.sender] += _amount;
        totalStakedTokens += _amount;
        emit TokensStaked(msg.sender, _amount);
    }

    /**
     * @dev Allows members to unstake tokens.
     * @param _amount Amount of tokens to unstake.
     */
    function unstakeTokens(uint256 _amount) external whenNotPaused {
        require(stakedTokens[msg.sender] >= _amount, "Insufficient staked tokens");
        stakedTokens[msg.sender] -= _amount;
        totalStakedTokens -= _amount;
        payable(msg.sender).transfer(_amount); // Return "tokens" (Ether)
        emit TokensUnstaked(msg.sender, _amount);
    }

    /**
     * @dev Retrieves the voting power of a member.
     * @param _voter Address of the voter.
     * @return Voting power.
     * @dev Voting power is currently directly proportional to staked tokens. Can be adjusted for more complex models.
     */
    function getVotingPower(address _voter) public view returns (uint256) {
        address delegate = voteDelegations[_voter];
        if (delegate != address(0)) {
            return stakedTokens[delegate]; // Delegated vote goes to delegatee's staked amount
        } else {
            return stakedTokens[_voter];
        }
    }


    // ------------------------ Marketplace Functions ------------------------

    /**
     * @dev Internal function to mint an NFT for an approved art proposal.
     * @param _proposalId ID of the approved art proposal.
     */
    function _mintArtNFT(uint256 _proposalId) internal whenNotPaused {
        require(artProposals[_proposalId].approved, "Proposal not approved");
        require(!artProposals[_proposalId].minted, "NFT already minted");

        nftCounter++;
        artNFTs[nftCounter] = ArtNFT({
            id: nftCounter,
            proposalId: _proposalId,
            artist: artProposals[_proposalId].artist,
            title: artProposals[_proposalId].title,
            ipfsHash: artProposals[_proposalId].ipfsHash,
            listedForSale: false,
            currentOwner: artProposals[_proposalId].artist // Initially owned by the artist
        });
        artProposals[_proposalId].minted = true;
        emit ArtNFTMinted(nftCounter, _proposalId, artProposals[_proposalId].artist, artProposals[_proposalId].artist);
    }

    /**
     * @dev Allows NFT owners to list their art for sale on the DAAC marketplace.
     * @param _nftId ID of the ArtNFT to list.
     * @param _price Price in wei for the NFT.
     */
    function listArtForSale(uint256 _nftId, uint256 _price) external whenNotPaused {
        require(artNFTs[_nftId].currentOwner == msg.sender, "Not the NFT owner");
        require(!artNFTs[_nftId].listedForSale, "Art already listed for sale");

        listingCounter++;
        artListings[listingCounter] = ArtListing({
            id: listingCounter,
            nftId: _nftId,
            price: _price,
            seller: msg.sender,
            active: true
        });
        artNFTs[_nftId].listedForSale = true;
        emit ArtListedForSale(listingCounter, _nftId, _price, msg.sender);
    }

    /**
     * @dev Allows users to buy art listed on the marketplace.
     * @param _listingId ID of the art listing.
     */
    function buyArt(uint256 _listingId) external payable whenNotPaused {
        require(artListings[_listingId].active, "Listing is not active");
        ArtListing storage listing = artListings[_listingId];
        ArtNFT storage nft = artNFTs[listing.nftId];
        require(msg.value >= listing.price, "Insufficient funds sent");

        // Transfer funds and NFT
        uint256 daoFee = (listing.price * daoFeePercentage) / 100;
        uint256 artistRevenue = listing.price - daoFee;

        daoTreasuryBalance += daoFee;
        artistRevenueBalances[nft.artist] += artistRevenue;
        nft.currentOwner = msg.sender;
        nft.listedForSale = false;
        listing.active = false;

        payable(listing.seller).transfer(listing.price - daoFee); // Seller receives price - DAO fee
        emit ArtSold(_listingId, listing.nftId, msg.sender, listing.price);
    }

    /**
     * @dev Allows NFT owners to cancel their art listing.
     * @param _listingId ID of the art listing to cancel.
     */
    function cancelListing(uint256 _listingId) external whenNotPaused {
        require(artListings[_listingId].seller == msg.sender, "Not the listing seller");
        require(artListings[_listingId].active, "Listing is not active");

        artNFTs[artListings[_listingId].nftId].listedForSale = false;
        artListings[_listingId].active = false;
        emit ListingCancelled(_listingId, artListings[_listingId].nftId);
    }

    /**
     * @dev Retrieves IDs of all active art listings.
     * @return Array of listing IDs.
     */
    function getAllListings() external view returns (uint256[] memory) {
        uint256[] memory listingIds = new uint256[](listingCounter); // Max possible size
        uint256 count = 0;
        for (uint256 i = 1; i <= listingCounter; i++) {
            if (artListings[i].active) {
                listingIds[count] = i;
                count++;
            }
        }
        // Resize array to actual number of listings
        assembly {
            mstore(listingIds, count) // Update the length of the array
        }
        return listingIds;
    }

    /**
     * @dev Retrieves detailed information about a specific art listing.
     * @param _listingId ID of the art listing.
     * @return Listing details.
     */
    function getListingDetails(uint256 _listingId) external view returns (
        uint256 id,
        uint256 nftId,
        uint256 price,
        address seller,
        bool active
    ) {
        ArtListing storage listing = artListings[_listingId];
        return (
            listing.id,
            listing.nftId,
            listing.price,
            listing.seller,
            listing.active
        );
    }


    // ------------------------ Utility/Admin Functions ------------------------

    /**
     * @dev Retrieves detailed information about an art proposal.
     * @param _proposalId ID of the art proposal.
     * @return Art proposal details.
     */
    function getArtProposalDetails(uint256 _proposalId) external view returns (
        uint256 id,
        address artist,
        string memory title,
        string memory description,
        string memory ipfsHash,
        uint256 proposalCost,
        uint256 submissionTimestamp,
        uint256 votingDeadline,
        uint256 yesVotes,
        uint256 noVotes,
        bool approved,
        bool minted
    ) {
        ArtProposal storage proposal = artProposals[_proposalId];
        return (
            proposal.id,
            proposal.artist,
            proposal.title,
            proposal.description,
            proposal.ipfsHash,
            proposal.proposalCost,
            proposal.submissionTimestamp,
            proposal.votingDeadline,
            proposal.yesVotes,
            proposal.noVotes,
            proposal.approved,
            proposal.minted
        );
    }

    /**
     * @dev Retrieves details of a DAO amendment proposal.
     * @param _amendmentId ID of the DAO amendment proposal.
     * @return DAO amendment details.
     */
    function getDAOAmendmentDetails(uint256 _amendmentId) external view returns (
        uint256 id,
        address proposer,
        string memory title,
        string memory description,
        bytes memory calldataData,
        uint256 submissionTimestamp,
        uint256 votingDeadline,
        uint256 yesVotes,
        uint256 noVotes,
        bool approved,
        bool executed
    ) {
        DAOAmendmentProposal storage amendment = daoAmendments[_amendmentId];
        return (
            amendment.id,
            amendment.proposer,
            amendment.title,
            amendment.description,
            amendment.calldata,
            amendment.submissionTimestamp,
            amendment.votingDeadline,
            amendment.yesVotes,
            amendment.noVotes,
            amendment.approved,
            amendment.executed
        );
    }

    /**
     * @dev Admin function to set the DAO fee percentage on art sales.
     * @param _newFeePercentage New DAO fee percentage (0-100).
     */
    function setDAOFee(uint256 _newFeePercentage) external onlyDAOAdmin whenNotPaused {
        require(_newFeePercentage <= 100, "Fee percentage cannot exceed 100");
        daoFeePercentage = _newFeePercentage;
        emit DAOFeePercentageChanged(_newFeePercentage);
    }

    /**
     * @dev Admin function to withdraw accumulated DAO fees from the treasury.
     */
    function withdrawDAOFees() external onlyDAOAdmin whenNotPaused {
        uint256 amount = daoTreasuryBalance;
        require(amount > 0, "No DAO fees to withdraw");
        daoTreasuryBalance = 0;
        payable(daoAdmin).transfer(amount);
        emit DAOFeesWithdrawn(amount);
    }

    /**
     * @dev Admin function to set the voting duration for proposals.
     * @param _newDurationBlocks New voting duration in blocks.
     */
    function setVotingDuration(uint256 _newDurationBlocks) external onlyDAOAdmin whenNotPaused {
        votingDurationBlocks = _newDurationBlocks;
        emit VotingDurationChanged(_newDurationBlocks);
    }

    /**
     * @dev Admin function to pause critical functionalities in case of emergency.
     */
    function emergencyPause() external onlyDAOAdmin whenNotPaused {
        paused = true;
        emit ContractPaused();
    }

    /**
     * @dev Admin function to resume functionalities after emergency pause.
     */
    function emergencyUnpause() external onlyDAOAdmin whenPaused {
        paused = false;
        emit ContractUnpaused();
    }

    /**
     * @dev Internal function to execute an approved DAO amendment.
     * @param _amendmentId ID of the approved amendment.
     */
    function _executeDAOAmendment(uint256 _amendmentId) internal whenNotPaused {
        require(daoAmendments[_amendmentId].approved, "Amendment not approved");
        require(!daoAmendments[_amendmentId].executed, "Amendment already executed");

        DAOAmendmentProposal storage amendment = daoAmendments[_amendmentId];
        (bool success, ) = address(this).delegatecall(amendment.calldata); // Execute the calldata
        require(success, "DAO Amendment execution failed");
        amendment.executed = true;
        emit DAOAmendmentExecuted(_amendmentId);
    }

    // --- Fallback and Receive (Optional, for receiving Ether directly to the contract) ---
    receive() external payable {}
    fallback() external payable {}
}
```