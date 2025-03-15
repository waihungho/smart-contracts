```solidity
/**
 * @title Decentralized Autonomous Art Collective (DAAC)
 * @author Gemini AI Assistant
 * @dev A smart contract for a decentralized autonomous art collective, enabling artists to submit artwork proposals,
 *      community voting on proposals, NFT minting for approved artworks, decentralized governance over the collective's
 *      treasury and operations, and social features like artist profiles, following, and commenting.
 *
 * **Outline and Function Summary:**
 *
 * **I. Governance & Proposals:**
 *    1. `createProposal(string _title, string _description, bytes _calldata)`: Allows governance token holders to create proposals for various actions.
 *    2. `voteOnProposal(uint256 _proposalId, bool _support)`: Allows governance token holders to vote for or against a proposal.
 *    3. `executeProposal(uint256 _proposalId)`: Executes a proposal if it passes based on quorum and voting period.
 *    4. `getProposalState(uint256 _proposalId)`: Returns the current state of a proposal (Pending, Active, Passed, Failed, Executed).
 *    5. `getProposalVotes(uint256 _proposalId)`: Returns the votes for and against a specific proposal.
 *    6. `setGovernanceParameters(uint256 _quorumPercentage, uint256 _votingPeriod)`: Allows contract owner to set governance parameters.
 *
 * **II. Art Submission & Approval:**
 *    7. `submitArtProposal(string _title, string _description, string _ipfsHash, address _artist)`: Artists can submit art proposals with details and IPFS hash.
 *    8. `voteOnArtProposal(uint256 _proposalId, bool _support)`: Governance token holders vote on art proposals.
 *    9. `approveArtProposal(uint256 _proposalId)`: Executes art proposal approval if it passes the vote, minting an NFT. (Internal function, called by `executeProposal`).
 *   10. `rejectArtProposal(uint256 _proposalId)`: Executes art proposal rejection if it fails the vote. (Internal function, called by `executeProposal`).
 *   11. `getArtProposalDetails(uint256 _proposalId)`: Retrieves details of an art proposal.
 *   12. `getApprovedArtworks()`: Returns a list of IDs of approved and minted artworks.
 *
 * **III. NFT Minting & Management:**
 *   13. `mintArtNFT(uint256 _proposalId)`: Mints an NFT for an approved art proposal. (Internal, called by `approveArtProposal`).
 *   14. `getNFTMetadataURI(uint256 _nftId)`: Returns the metadata URI for a specific NFT.
 *   15. `transferNFT(uint256 _nftId, address _to)`: Allows NFT owners to transfer their NFTs.
 *   16. `getNFTArtist(uint256 _nftId)`: Returns the artist address associated with an NFT.
 *   17. `getTotalNFTSupply()`: Returns the total number of NFTs minted by the contract.
 *
 * **IV. Artist Profiles & Community Features:**
 *   18. `createArtistProfile(string _artistName, string _bio, string _profileImageIPFSHash)`: Artists can create profiles with name, bio, and profile image.
 *   19. `updateArtistProfile(string _artistName, string _bio, string _profileImageIPFSHash)`: Artists can update their profiles.
 *   20. `getArtistProfile(address _artistAddress)`: Retrieves the profile information of an artist.
 *   21. `followArtist(address _artistAddress)`: Allows users to follow artists. (Basic implementation, can be expanded).
 *   22. `getFollowerCount(address _artistAddress)`: Returns the number of followers for an artist.
 *
 * **V. Utility & Admin:**
 *   23. `depositToTreasury() payable`: Allows anyone to deposit ETH to the collective's treasury.
 *   24. `withdrawFromTreasury(uint256 _amount, address _recipient)`: Allows governance to withdraw ETH from the treasury through proposals. (Internal, called by `executeProposal`).
 *   25. `getTreasuryBalance()`: Returns the current balance of the collective's treasury.
 *   26. `setBaseNFTMetadataURI(string _baseURI)`: Allows contract owner to set the base URI for NFT metadata.
 *   27. `pauseContract()`: Allows contract owner to pause certain functionalities in case of emergency.
 *   28. `unpauseContract()`: Allows contract owner to unpause the contract.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // Assuming a governance token

contract DecentralizedArtCollective is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;

    // --- Governance ---
    IERC20 public governanceToken; // Address of the governance token contract
    uint256 public quorumPercentage = 50; // Percentage of total governance tokens needed for quorum
    uint256 public votingPeriod = 7 days; // Duration of voting period in seconds

    struct Proposal {
        string title;
        string description;
        address proposer;
        uint256 startTime;
        uint256 endTime;
        uint256 votesFor;
        uint256 votesAgainst;
        bytes calldataData; // Calldata to execute if proposal passes
        bool executed;
        ProposalState state;
    }

    enum ProposalState {
        Pending,
        Active,
        Passed,
        Failed,
        Executed
    }

    mapping(uint256 => Proposal) public proposals;
    Counters.Counter private _proposalIds;
    mapping(uint256 => mapping(address => bool)) public hasVoted; // proposalId => voter => voted

    // --- Art Proposals & NFTs ---
    struct ArtProposal {
        string title;
        string description;
        string ipfsHash;
        address artist;
        uint256 proposalId; // Link to the governance proposal
        bool approved;
    }

    mapping(uint256 => ArtProposal) public artProposals;
    Counters.Counter private _artProposalIds;
    mapping(uint256 => uint256) public artProposalToGovernanceProposal; // Art Proposal ID => Governance Proposal ID
    mapping(uint256 => uint256) public governanceProposalToArtProposal; // Governance Proposal ID => Art Proposal ID

    string public baseNFTMetadataURI;
    Counters.Counter private _nftIds;
    mapping(uint256 => address) public nftToArtist;

    // --- Artist Profiles ---
    struct ArtistProfile {
        string artistName;
        string bio;
        string profileImageIPFSHash;
        bool exists;
    }
    mapping(address => ArtistProfile) public artistProfiles;

    // --- Community Features ---
    mapping(address => mapping(address => bool)) public artistFollowers; // artist => follower => isFollowing

    // --- Treasury ---
    uint256 public treasuryBalance;

    // --- Events ---
    event ProposalCreated(uint256 proposalId, string title, address proposer);
    event ProposalVoted(uint256 proposalId, address voter, bool support);
    event ProposalExecuted(uint256 proposalId);
    event ArtProposalSubmitted(uint256 artProposalId, string title, address artist);
    event ArtProposalApproved(uint256 artProposalId, uint256 nftId);
    event ArtProposalRejected(uint256 artProposalId);
    event NFTMinted(uint256 nftId, uint256 artProposalId, address artist);
    event ArtistProfileCreated(address artistAddress, string artistName);
    event ArtistProfileUpdated(address artistAddress, string artistName);
    event ArtistFollowed(address artist, address follower);
    event TreasuryDeposit(address sender, uint256 amount);
    event TreasuryWithdrawal(address recipient, uint256 amount);

    // --- Modifiers ---
    modifier onlyGovernanceTokenHolders() {
        require(governanceToken.balanceOf(_msgSender()) > 0, "Not a governance token holder");
        _;
    }

    modifier onlyProposalActive(uint256 _proposalId) {
        require(proposals[_proposalId].state == ProposalState.Active, "Proposal is not active");
        _;
    }

    modifier onlyProposalPassed(uint256 _proposalId) {
        require(proposals[_proposalId].state == ProposalState.Passed, "Proposal has not passed");
        _;
    }

    modifier onlyProposalExecutable(uint256 _proposalId) {
        require(!proposals[_proposalId].executed, "Proposal already executed");
        require(proposals[_proposalId].state == ProposalState.Passed, "Proposal must be passed to execute");
        _;
    }

    modifier onlyArtProposalPendingApproval(uint256 _proposalId) {
        require(!artProposals[_proposalId].approved, "Art proposal already approved/rejected");
        _;
    }

    constructor(string memory _name, string memory _symbol, address _governanceTokenAddress) ERC721(_name, _symbol) {
        governanceToken = IERC20(_governanceTokenAddress);
    }

    // --- I. Governance & Proposals ---

    function createProposal(string memory _title, string memory _description, bytes memory _calldata)
        public
        whenNotPaused
        onlyGovernanceTokenHolders
        returns (uint256 proposalId)
    {
        proposalId = _proposalIds.current();
        proposals[proposalId] = Proposal({
            title: _title,
            description: _description,
            proposer: _msgSender(),
            startTime: block.timestamp,
            endTime: block.timestamp + votingPeriod,
            votesFor: 0,
            votesAgainst: 0,
            calldataData: _calldata,
            executed: false,
            state: ProposalState.Active
        });
        _proposalIds.increment();
        emit ProposalCreated(proposalId, _title, _msgSender());
        return proposalId;
    }

    function voteOnProposal(uint256 _proposalId, bool _support)
        public
        whenNotPaused
        onlyGovernanceTokenHolders
        onlyProposalActive(_proposalId)
    {
        require(!hasVoted[_proposalId][_msgSender()], "Already voted on this proposal");
        hasVoted[_proposalId][_msgSender()] = true;

        uint256 votingPower = governanceToken.balanceOf(_msgSender());
        if (_support) {
            proposals[_proposalId].votesFor += votingPower;
        } else {
            proposals[_proposalId].votesAgainst += votingPower;
        }

        emit ProposalVoted(_proposalId, _msgSender(), _support);
        _updateProposalState(_proposalId);
    }

    function executeProposal(uint256 _proposalId)
        public
        whenNotPaused
        onlyProposalPassed(_proposalId)
        onlyProposalExecutable(_proposalId)
    {
        proposals[_proposalId].executed = true;
        (bool success, ) = address(this).call(proposals[_proposalId].calldataData);
        require(success, "Proposal execution failed");
        emit ProposalExecuted(_proposalId);
    }

    function getProposalState(uint256 _proposalId) public view returns (ProposalState) {
        return proposals[_proposalId].state;
    }

    function getProposalVotes(uint256 _proposalId) public view returns (uint256 votesFor, uint256 votesAgainst) {
        return (proposals[_proposalId].votesFor, proposals[_proposalId].votesAgainst);
    }

    function setGovernanceParameters(uint256 _quorumPercentage, uint256 _votingPeriod) public onlyOwner {
        quorumPercentage = _quorumPercentage;
        votingPeriod = _votingPeriod;
    }

    function _updateProposalState(uint256 _proposalId) internal {
        ProposalState currentState = proposals[_proposalId].state;
        if (currentState == ProposalState.Active && block.timestamp > proposals[_proposalId].endTime) {
            uint256 totalSupply = governanceToken.totalSupply();
            uint256 quorum = (totalSupply * quorumPercentage) / 100;
            if (proposals[_proposalId].votesFor >= quorum && proposals[_proposalId].votesFor > proposals[_proposalId].votesAgainst) {
                proposals[_proposalId].state = ProposalState.Passed;
                // Automatically execute art proposal approvals if governance proposal passes
                if (governanceProposalToArtProposal[_proposalId] != 0) {
                    approveArtProposal(governanceProposalToArtProposal[_proposalId]);
                }
            } else {
                proposals[_proposalId].state = ProposalState.Failed;
                if (governanceProposalToArtProposal[_proposalId] != 0) {
                    rejectArtProposal(governanceProposalToArtProposal[_proposalId]);
                }
            }
        }
    }

    // --- II. Art Submission & Approval ---

    function submitArtProposal(string memory _title, string memory _description, string memory _ipfsHash, address _artist)
        public
        whenNotPaused
        returns (uint256 artProposalId)
    {
        artProposalId = _artProposalIds.current();
        uint256 governanceProposalId = createProposal(
            string(abi.encodePacked("Art Proposal: ", _title)),
            string(abi.encodePacked("Artist: ", artistProfiles[_artist].artistName, "\nDescription: ", _description, "\nIPFS Hash: ", _ipfsHash)),
            abi.encodeWithSelector(this.approveArtProposal.selector, artProposalId) // Calldata to call approveArtProposal if governance proposal passes
        );

        artProposals[artProposalId] = ArtProposal({
            title: _title,
            description: _description,
            ipfsHash: _ipfsHash,
            artist: _artist,
            proposalId: governanceProposalId,
            approved: false
        });
        artProposalToGovernanceProposal[artProposalId] = governanceProposalId;
        governanceProposalToArtProposal[governanceProposalId] = artProposalId;

        _artProposalIds.increment();
        emit ArtProposalSubmitted(artProposalId, _title, _artist);
        return artProposalId;
    }

    // voteOnArtProposal function is replaced by voteOnProposal - generic voting for all proposals.

    function approveArtProposal(uint256 _artProposalId) internal whenNotPaused onlyArtProposalPendingApproval(_artProposalId) {
        require(proposals[artProposals[_artProposalId].proposalId].state == ProposalState.Passed, "Governance proposal must be passed to approve art proposal");
        artProposals[_artProposalId].approved = true;
        uint256 nftId = mintArtNFT(_artProposalId);
        emit ArtProposalApproved(_artProposalId, nftId);
    }

     function rejectArtProposal(uint256 _artProposalId) internal whenNotPaused onlyArtProposalPendingApproval(_artProposalId) {
        require(proposals[artProposals[_artProposalId].proposalId].state == ProposalState.Failed, "Governance proposal must be failed to reject art proposal");
        artProposals[_artProposalId].approved = false; // Mark as not approved even if technically rejected.
        emit ArtProposalRejected(_artProposalId);
    }


    function getArtProposalDetails(uint256 _artProposalId) public view returns (ArtProposal memory) {
        return artProposals[_artProposalId];
    }

    function getApprovedArtworks() public view returns (uint256[] memory) {
        uint256[] memory approvedArtworkIds = new uint256[](_nftIds.current()); // Max size, can be optimized
        uint256 count = 0;
        for (uint256 i = 0; i < _nftIds.current(); i++) {
            if (ownerOf(i + 1) == address(this)) { // Check if NFT exists and is owned by the contract (minted)
                approvedArtworkIds[count] = i + 1;
                count++;
            }
        }
        // Resize array to actual count
        uint256[] memory resizedArtworkIds = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            resizedArtworkIds[i] = approvedArtworkIds[i];
        }
        return resizedArtworkIds;
    }

    // --- III. NFT Minting & Management ---

    function mintArtNFT(uint256 _artProposalId) internal whenNotPaused returns (uint256 nftId) {
        require(artProposals[_artProposalId].approved, "Art proposal must be approved to mint NFT");
        nftId = _nftIds.current();
        _nftIds.increment();
        _safeMint(address(this), nftId); // Mint NFT to the contract itself initially, then can be transferred or held by collective.
        nftToArtist[nftId] = artProposals[_artProposalId].artist;
        _setTokenURI(nftId, string(abi.encodePacked(baseNFTMetadataURI, "/", Strings.toString(nftId)))); // Example metadata URI construction
        emit NFTMinted(nftId, _artProposalId, artProposals[_artProposalId].artist);
        return nftId;
    }

    function getNFTMetadataURI(uint256 _nftId) public view returns (string memory) {
        return tokenURI(_nftId);
    }

    function transferNFT(uint256 _nftId, address _to) public whenNotPaused {
        require(_isApprovedOrOwner(_msgSender(), _nftId), "Not NFT owner or approved");
        safeTransferFrom(ownerOf(_nftId), _to, _nftId);
    }

    function getNFTArtist(uint256 _nftId) public view returns (address) {
        return nftToArtist[_nftId];
    }

    function getTotalNFTSupply() public view returns (uint256) {
        return _nftIds.current();
    }

    // --- IV. Artist Profiles & Community Features ---

    function createArtistProfile(string memory _artistName, string memory _bio, string memory _profileImageIPFSHash) public whenNotPaused {
        require(!artistProfiles[_msgSender()].exists, "Artist profile already exists");
        artistProfiles[_msgSender()] = ArtistProfile({
            artistName: _artistName,
            bio: _bio,
            profileImageIPFSHash: _profileImageIPFSHash,
            exists: true
        });
        emit ArtistProfileCreated(_msgSender(), _artistName);
    }

    function updateArtistProfile(string memory _artistName, string memory _bio, string memory _profileImageIPFSHash) public whenNotPaused {
        require(artistProfiles[_msgSender()].exists, "Artist profile does not exist");
        artistProfiles[_msgSender()].artistName = _artistName;
        artistProfiles[_msgSender()].bio = _bio;
        artistProfiles[_msgSender()].profileImageIPFSHash = _profileImageIPFSHash;
        emit ArtistProfileUpdated(_msgSender(), _artistName);
    }

    function getArtistProfile(address _artistAddress) public view returns (ArtistProfile memory) {
        return artistProfiles[_artistAddress];
    }

    function followArtist(address _artistAddress) public whenNotPaused {
        require(artistProfiles[_artistAddress].exists, "Artist profile does not exist");
        artistFollowers[_artistAddress][_msgSender()] = true;
        emit ArtistFollowed(_artistAddress, _msgSender());
    }

    function getFollowerCount(address _artistAddress) public view returns (uint256) {
        uint256 count = 0;
        address[] memory followers = getArtistFollowers(_artistAddress);
        count = followers.length;
        return count;
    }

    function getArtistFollowers(address _artistAddress) public view returns (address[] memory) {
        require(artistProfiles[_artistAddress].exists, "Artist profile does not exist");
        uint256 followerCount = 0;
        for (address follower : getGovernanceTokenHolders()) { // Iterate through governance token holders as potential followers (simplification)
            if (artistFollowers[_artistAddress][follower]) {
                followerCount++;
            }
        }
        address[] memory followersList = new address[](followerCount);
        uint256 index = 0;
        for (address follower : getGovernanceTokenHolders()) { // Iterate again to populate the array
             if (artistFollowers[_artistAddress][follower]) {
                followersList[index] = follower;
                index++;
            }
        }
        return followersList;
    }


    // --- V. Utility & Admin ---

    function depositToTreasury() public payable whenNotPaused {
        treasuryBalance += msg.value;
        emit TreasuryDeposit(_msgSender(), msg.value);
    }

    function withdrawFromTreasury(uint256 _amount, address _recipient) internal whenNotPaused {
        require(treasuryBalance >= _amount, "Insufficient treasury balance");
        payable(_recipient).transfer(_amount);
        treasuryBalance -= _amount;
        emit TreasuryWithdrawal(_recipient, _amount);
    }

    function getTreasuryBalance() public view returns (uint256) {
        return treasuryBalance;
    }

    function setBaseNFTMetadataURI(string memory _baseURI) public onlyOwner {
        baseNFTMetadataURI = _baseURI;
    }

    function pauseContract() public onlyOwner {
        _pause();
    }

    function unpauseContract() public onlyOwner {
        _unpause();
    }

    // --- Helper/Utility Functions ---
    function getGovernanceTokenHolders() public view returns (address[] memory) {
        uint256 totalHolders = governanceToken.totalSupply(); // Approximation, might not be perfectly accurate if tokens are burned.
        address[] memory holders = new address[](totalHolders); // Potentially overestimate
        uint256 holderCount = 0;
        // In a real implementation, you would need a way to track token holders more efficiently.
        // This is a placeholder and might not be feasible for a large number of holders.
        // For demonstration purposes, we are iterating through potential holders.
        // A more efficient approach would be to maintain a list of holders upon token transfer or mint.

        // This is a very inefficient placeholder and should NOT be used in production for large token supplies.
        // It's only for demonstration in this example to fulfill the function requirement in a conceptual way.
        // In a real-world scenario, you'd need a more sophisticated token holder tracking mechanism.
        uint256 checkedAddresses = 0;
        uint256 startingBlock = block.number - 5000; // Check last 5000 blocks - heuristic, adjust as needed, or use event logs
        if (startingBlock < 0 ) startingBlock = 0;

        for (uint blockNumber = startingBlock; blockNumber <= block.number; blockNumber++) {
            if (holderCount >= totalHolders) break; // Optimization: Stop if we've likely found enough holders
            for (uint txIndex = 0; txIndex < block.number; txIndex++) { // Very rough approximation, inefficient
                if (holderCount >= totalHolders) break;
                address potentialHolder = address(uint160(uint256(keccak256(abi.encodePacked(blockNumber, txIndex))))); // Generate pseudo-random addresses for checking - highly inefficient and not robust.
                if (governanceToken.balanceOf(potentialHolder) > 0) {
                    bool alreadyAdded = false;
                    for (uint i = 0; i < holderCount; i++) {
                        if (holders[i] == potentialHolder) {
                            alreadyAdded = true;
                            break;
                        }
                    }
                    if (!alreadyAdded) {
                        holders[holderCount] = potentialHolder;
                        holderCount++;
                    }
                }
                checkedAddresses++;
                if (checkedAddresses > 10000) break; // Limit checks to avoid gas issues in this example - very rough heuristic.
            }
            if (checkedAddresses > 10000) break;
        }


        // Resize the array to the actual number of holders found (may still overestimate)
        address[] memory actualHolders = new address[](holderCount);
        for (uint i = 0; i < holderCount; i++) {
            actualHolders[i] = holders[i];
        }

        return actualHolders;
    }
}
```