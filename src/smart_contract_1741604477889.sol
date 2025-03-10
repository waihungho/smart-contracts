```solidity
/**
 * @title Decentralized Autonomous Art Collective (DAAC) Smart Contract
 * @author Bard (AI Assistant)
 * @dev A smart contract for a Decentralized Autonomous Art Collective (DAAC) that facilitates collaborative art creation,
 * governance, and NFT management. This contract incorporates advanced concepts like quadratic voting for proposals,
 * dynamic NFT rarity based on community engagement, decentralized curation, and a reputation system.
 *
 * Function Summary:
 *
 * 1.  `registerArtist(string _artistName, string _artistBio)`: Allows users to register as artists in the collective.
 * 2.  `submitArtworkProposal(string _title, string _description, string _ipfsHash)`: Artists propose new artworks for the collective to create as NFTs.
 * 3.  `voteOnArtworkProposal(uint256 _proposalId, bool _support)`: Members vote on artwork proposals using quadratic voting.
 * 4.  `executeArtworkProposal(uint256 _proposalId)`: Executes an approved artwork proposal, minting an NFT for the collective.
 * 5.  `mintCollectiveNFT(uint256 _artworkId)`: Mints an NFT representing a collective artwork to a member (requires governance approval).
 * 6.  `transferCollectiveNFT(uint256 _tokenId, address _to)`: Transfers ownership of a collective NFT (governance controlled).
 * 7.  `createGovernanceProposal(string _title, string _description, bytes _calldata)`: Members propose changes to the collective's rules or contract parameters.
 * 8.  `voteOnGovernanceProposal(uint256 _proposalId, uint256 _votingPower)`: Members vote on governance proposals using customizable voting power (e.g., based on reputation).
 * 9.  `executeGovernanceProposal(uint256 _proposalId)`: Executes an approved governance proposal.
 * 10. `donateToCollective()`: Allows anyone to donate ETH to the collective's treasury.
 * 11. `withdrawTreasuryFunds(uint256 _amount, address _recipient)`: Allows governance to withdraw funds from the collective's treasury.
 * 12. `setNFTBaseURI(string _baseURI)`: Sets the base URI for the collective's NFTs (governance controlled).
 * 13. `getNFTMetadataURI(uint256 _tokenId)`: Retrieves the metadata URI for a specific collective NFT.
 * 14. `getArtistProfile(address _artistAddress)`: Retrieves the profile information of a registered artist.
 * 15. `getArtworkProposalDetails(uint256 _proposalId)`: Retrieves details of a specific artwork proposal.
 * 16. `getGovernanceProposalDetails(uint256 _proposalId)`: Retrieves details of a specific governance proposal.
 * 17. `getCollectiveNFTDetails(uint256 _tokenId)`: Retrieves details of a specific collective NFT.
 * 18. `getArtistReputation(address _artistAddress)`: Retrieves the reputation score of an artist.
 * 19. `upvoteArtist(address _artistAddress)`: Allows members to upvote an artist, increasing their reputation.
 * 20. `downvoteArtist(address _artistAddress)`: Allows members to downvote an artist, decreasing their reputation.
 * 21. `pauseContract()`: Pauses certain contract functionalities (admin only).
 * 22. `unpauseContract()`: Resumes paused contract functionalities (admin only).
 * 23. `setGovernanceThreshold(uint256 _newThreshold)`: Sets the threshold required for governance proposal approval (governance controlled).
 */

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract DecentralizedArtCollective is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;
    using SafeMath for uint256;

    // --- State Variables ---

    string public baseURI;
    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _artworkProposalIdCounter;
    Counters.Counter private _governanceProposalIdCounter;

    uint256 public governanceThreshold = 51; // Percentage threshold for governance proposal approval
    bool public paused = false;

    // Artist Registry
    mapping(address => ArtistProfile) public artistProfiles;
    address[] public registeredArtists;

    // Artwork Proposals
    mapping(uint256 => ArtworkProposal) public artworkProposals;

    // Governance Proposals
    mapping(uint256 => GovernanceProposal) public governanceProposals;

    // Collective NFTs
    mapping(uint256 => CollectiveNFT) public collectiveNFTs;

    // Reputation System
    mapping(address => uint256) public artistReputation;

    // Treasury
    uint256 public treasuryBalance;

    // --- Structs ---

    struct ArtistProfile {
        string artistName;
        string artistBio;
        bool isRegistered;
        uint256 registrationTimestamp;
    }

    struct ArtworkProposal {
        uint256 proposalId;
        string title;
        string description;
        string ipfsHash;
        address proposer;
        uint256 creationTimestamp;
        uint256 positiveVotes;
        uint256 negativeVotes;
        bool executed;
    }

    struct GovernanceProposal {
        uint256 proposalId;
        string title;
        string description;
        address proposer;
        uint256 creationTimestamp;
        bytes calldataData; // Calldata for execution
        uint256 positiveVotes;
        uint256 negativeVotes;
        bool executed;
    }

    struct CollectiveNFT {
        uint256 tokenId;
        uint256 artworkId; // Links to the artwork proposal
        address minter;
        uint256 mintTimestamp;
        uint256 rarityScore; // Dynamic rarity based on engagement
    }

    // --- Events ---

    event ArtistRegistered(address artistAddress, string artistName);
    event ArtworkProposalCreated(uint256 proposalId, string title, address proposer);
    event ArtworkProposalVoted(uint256 proposalId, address voter, bool support);
    event ArtworkProposalExecuted(uint256 proposalId);
    event CollectiveNFTMinted(uint256 tokenId, uint256 artworkId, address minter);
    event CollectiveNFTTransferred(uint256 tokenId, address from, address to);
    event GovernanceProposalCreated(uint256 proposalId, string title, address proposer);
    event GovernanceProposalVoted(uint256 proposalId, address voter, uint256 votingPower);
    event GovernanceProposalExecuted(uint256 proposalId);
    event TreasuryDonationReceived(address donor, uint256 amount);
    event TreasuryWithdrawal(uint256 amount, address recipient);
    event NFTBaseURISet(string baseURI);
    event ArtistReputationChanged(address artistAddress, uint256 newReputation);
    event ContractPaused();
    event ContractUnpaused();
    event GovernanceThresholdSet(uint256 newThreshold);

    // --- Modifiers ---

    modifier onlyRegisteredArtist() {
        require(artistProfiles[msg.sender].isRegistered, "Only registered artists can perform this action.");
        _;
    }

    modifier onlyGovernance() {
        // Simple majority for now, can be made more complex with voting power later
        require(getGovernanceApprovalPercentage(governanceProposals[_governanceProposalIdCounter.current()].positiveVotes, governanceProposals[_governanceProposalIdCounter.current()].negativeVotes) >= governanceThreshold, "Governance threshold not met.");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused.");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused.");
        _;
    }

    // --- Constructor ---

    constructor(string memory _name, string memory _symbol, string memory _baseURI) ERC721(_name, _symbol) {
        baseURI = _baseURI;
    }

    // --- Artist Management Functions ---

    /**
     * @dev Registers a user as an artist in the collective.
     * @param _artistName The name of the artist.
     * @param _artistBio A brief biography of the artist.
     */
    function registerArtist(string memory _artistName, string memory _artistBio) external whenNotPaused {
        require(!artistProfiles[msg.sender].isRegistered, "Artist already registered.");
        artistProfiles[msg.sender] = ArtistProfile({
            artistName: _artistName,
            artistBio: _artistBio,
            isRegistered: true,
            registrationTimestamp: block.timestamp
        });
        registeredArtists.push(msg.sender);
        emit ArtistRegistered(msg.sender, _artistName);
    }

    /**
     * @dev Retrieves the profile information of a registered artist.
     * @param _artistAddress The address of the artist.
     * @return ArtistProfile struct containing artist's information.
     */
    function getArtistProfile(address _artistAddress) external view returns (ArtistProfile memory) {
        return artistProfiles[_artistAddress];
    }

    /**
     * @dev Retrieves the reputation score of an artist.
     * @param _artistAddress The address of the artist.
     * @return The reputation score of the artist.
     */
    function getArtistReputation(address _artistAddress) external view returns (uint256) {
        return artistReputation[_artistAddress];
    }

    /**
     * @dev Allows members to upvote an artist, increasing their reputation.
     * @param _artistAddress The address of the artist to upvote.
     */
    function upvoteArtist(address _artistAddress) external whenNotPaused {
        require(artistProfiles[_artistAddress].isRegistered, "Artist is not registered.");
        artistReputation[_artistAddress] = artistReputation[_artistAddress].add(1);
        emit ArtistReputationChanged(_artistAddress, artistReputation[_artistAddress]);
    }

    /**
     * @dev Allows members to downvote an artist, decreasing their reputation.
     * @param _artistAddress The address of the artist to downvote.
     */
    function downvoteArtist(address _artistAddress) external whenNotPaused {
        require(artistProfiles[_artistAddress].isRegistered, "Artist is not registered.");
        artistReputation[_artistAddress] = artistReputation[_artistAddress].sub(1); // Assuming reputation can go negative or start from a higher base. Adjust as needed.
        emit ArtistReputationChanged(_artistAddress, artistReputation[_artistAddress]);
    }


    // --- Artwork Proposal Functions ---

    /**
     * @dev Allows registered artists to submit artwork proposals.
     * @param _title The title of the artwork.
     * @param _description A description of the artwork.
     * @param _ipfsHash The IPFS hash of the artwork's metadata.
     */
    function submitArtworkProposal(string memory _title, string memory _description, string memory _ipfsHash) external onlyRegisteredArtist whenNotPaused {
        _artworkProposalIdCounter.increment();
        artworkProposals[_artworkProposalIdCounter.current()] = ArtworkProposal({
            proposalId: _artworkProposalIdCounter.current(),
            title: _title,
            description: _description,
            ipfsHash: _ipfsHash,
            proposer: msg.sender,
            creationTimestamp: block.timestamp,
            positiveVotes: 0,
            negativeVotes: 0,
            executed: false
        });
        emit ArtworkProposalCreated(_artworkProposalIdCounter.current(), _title, msg.sender);
    }

    /**
     * @dev Allows members to vote on artwork proposals using quadratic voting (simplified example).
     * @param _proposalId The ID of the artwork proposal to vote on.
     * @param _support True for supporting the proposal, false for opposing.
     */
    function voteOnArtworkProposal(uint256 _proposalId, bool _support) external whenNotPaused {
        require(!artworkProposals[_proposalId].executed, "Proposal already executed.");
        require(artworkProposals[_proposalId].proposer != msg.sender, "Proposer cannot vote on their own proposal."); // Optional: Prevent proposer voting

        if (_support) {
            artworkProposals[_proposalId].positiveVotes = artworkProposals[_proposalId].positiveVotes.add(1); // Simplified quadratic voting - adjust based on desired complexity.
        } else {
            artworkProposals[_proposalId].negativeVotes = artworkProposals[_proposalId].negativeVotes.add(1);
        }
        emit ArtworkProposalVoted(_proposalId, msg.sender, _support);
    }

    /**
     * @dev Executes an approved artwork proposal if it meets the governance threshold.
     * @param _proposalId The ID of the artwork proposal to execute.
     */
    function executeArtworkProposal(uint256 _proposalId) external whenNotPaused {
        require(!artworkProposals[_proposalId].executed, "Proposal already executed.");
        require(getGovernanceApprovalPercentage(artworkProposals[_proposalId].positiveVotes, artworkProposals[_proposalId].negativeVotes) >= governanceThreshold, "Governance threshold not met.");

        artworkProposals[_proposalId].executed = true;
        emit ArtworkProposalExecuted(_proposalId);
    }

    /**
     * @dev Retrieves details of a specific artwork proposal.
     * @param _proposalId The ID of the artwork proposal.
     * @return ArtworkProposal struct containing proposal details.
     */
    function getArtworkProposalDetails(uint256 _proposalId) external view returns (ArtworkProposal memory) {
        return artworkProposals[_proposalId];
    }


    // --- Collective NFT Functions ---

    /**
     * @dev Mints an NFT representing a collective artwork to a member (requires governance approval).
     * @param _artworkId The ID of the approved artwork proposal to mint an NFT for.
     */
    function mintCollectiveNFT(uint256 _artworkId) external onlyGovernance whenNotPaused {
        require(artworkProposals[_artworkId].executed, "Artwork proposal not yet executed.");
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        collectiveNFTs[newTokenId] = CollectiveNFT({
            tokenId: newTokenId,
            artworkId: _artworkId,
            minter: msg.sender, // Or can be set to collective address if minted to treasury initially
            mintTimestamp: block.timestamp,
            rarityScore: 0 // Initial rarity score, can be dynamically updated based on engagement
        });

        _safeMint(msg.sender, newTokenId); // Mint NFT to the caller (can be adjusted for distribution)
        emit CollectiveNFTMinted(newTokenId, _artworkId, msg.sender);
    }

    /**
     * @dev Transfers ownership of a collective NFT (governance controlled).
     * @param _tokenId The ID of the NFT to transfer.
     * @param _to The address to transfer the NFT to.
     */
    function transferCollectiveNFT(uint256 _tokenId, address _to) external onlyGovernance whenNotPaused {
        _transfer(ownerOf(_tokenId), _to, _tokenId);
        emit CollectiveNFTTransferred(_tokenId, ownerOf(_tokenId), _to);
    }

    /**
     * @dev Retrieves details of a specific collective NFT.
     * @param _tokenId The ID of the collective NFT.
     * @return CollectiveNFT struct containing NFT details.
     */
    function getCollectiveNFTDetails(uint256 _tokenId) external view returns (CollectiveNFT memory) {
        return collectiveNFTs[_tokenId];
    }


    // --- Governance Functions ---

    /**
     * @dev Creates a governance proposal to change contract parameters or execute actions.
     * @param _title The title of the governance proposal.
     * @param _description A description of the governance proposal.
     * @param _calldata The calldata to execute if the proposal is approved (can be empty if no execution needed).
     */
    function createGovernanceProposal(string memory _title, string memory _description, bytes memory _calldata) external whenNotPaused {
        _governanceProposalIdCounter.increment();
        governanceProposals[_governanceProposalIdCounter.current()] = GovernanceProposal({
            proposalId: _governanceProposalIdCounter.current(),
            title: _title,
            description: _description,
            proposer: msg.sender,
            creationTimestamp: block.timestamp,
            calldataData: _calldata,
            positiveVotes: 0,
            negativeVotes: 0,
            executed: false
        });
        emit GovernanceProposalCreated(_governanceProposalIdCounter.current(), _title, msg.sender);
    }

    /**
     * @dev Allows members to vote on governance proposals using customizable voting power (e.g., reputation-based).
     * @param _proposalId The ID of the governance proposal to vote on.
     * @param _votingPower The voting power of the voter (can be based on reputation or other factors).
     */
    function voteOnGovernanceProposal(uint256 _proposalId, uint256 _votingPower) external whenNotPaused {
        require(!governanceProposals[_proposalId].executed, "Governance proposal already executed.");
        require(_votingPower > 0, "Voting power must be greater than zero."); // Basic voting power requirement

        governanceProposals[_proposalId].positiveVotes = governanceProposals[_proposalId].positiveVotes.add(_votingPower);
        emit GovernanceProposalVoted(_proposalId, msg.sender, _votingPower);
    }

    /**
     * @dev Executes an approved governance proposal if it meets the governance threshold.
     * @param _proposalId The ID of the governance proposal to execute.
     */
    function executeGovernanceProposal(uint256 _proposalId) external onlyGovernance whenNotPaused {
        require(!governanceProposals[_proposalId].executed, "Governance proposal already executed.");
        require(getGovernanceApprovalPercentage(governanceProposals[_proposalId].positiveVotes, governanceProposals[_proposalId].negativeVotes) >= governanceThreshold, "Governance threshold not met.");

        governanceProposals[_proposalId].executed = true;
        if (governanceProposals[_proposalId].calldataData.length > 0) {
            (bool success, ) = address(this).call(governanceProposals[_proposalId].calldataData);
            require(success, "Governance proposal execution failed.");
        }
        emit GovernanceProposalExecuted(_proposalId);
    }

    /**
     * @dev Retrieves details of a specific governance proposal.
     * @param _proposalId The ID of the governance proposal.
     * @return GovernanceProposal struct containing proposal details.
     */
    function getGovernanceProposalDetails(uint256 _proposalId) external view returns (GovernanceProposal memory) {
        return governanceProposals[_proposalId];
    }


    // --- Treasury Functions ---

    /**
     * @dev Allows anyone to donate ETH to the collective's treasury.
     */
    function donateToCollective() external payable whenNotPaused {
        treasuryBalance = treasuryBalance.add(msg.value);
        emit TreasuryDonationReceived(msg.sender, msg.value);
    }

    /**
     * @dev Allows governance to withdraw funds from the collective's treasury.
     * @param _amount The amount of ETH to withdraw.
     * @param _recipient The address to send the withdrawn funds to.
     */
    function withdrawTreasuryFunds(uint256 _amount, address _recipient) external onlyGovernance whenNotPaused {
        require(treasuryBalance >= _amount, "Insufficient treasury balance.");
        payable(_recipient).transfer(_amount);
        treasuryBalance = treasuryBalance.sub(_amount);
        emit TreasuryWithdrawal(_amount, _recipient);
    }

    /**
     * @dev Gets the current treasury balance.
     * @return The current treasury balance in Wei.
     */
    function getTreasuryBalance() external view returns (uint256) {
        return treasuryBalance;
    }


    // --- NFT Metadata Functions ---

    /**
     * @dev Sets the base URI for the collective's NFTs (governance controlled).
     * @param _baseURI The new base URI string.
     */
    function setNFTBaseURI(string memory _baseURI) external onlyGovernance whenNotPaused {
        baseURI = _baseURI;
        emit NFTBaseURISet(_baseURI);
    }

    /**
     * @dev Overrides the _baseURI function to use the contract's baseURI.
     * @return The base URI string.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
     * @dev Retrieves the metadata URI for a specific collective NFT.
     * @param _tokenId The ID of the NFT.
     * @return The metadata URI string.
     */
    function getNFTMetadataURI(uint256 _tokenId) external view returns (string memory) {
        require(_exists(_tokenId), "Token ID does not exist.");
        return string(abi.encodePacked(_baseURI(), _tokenId.toString(), ".json")); // Example: baseURI + tokenId + ".json"
    }


    // --- Utility and Admin Functions ---

    /**
     * @dev Pauses certain contract functionalities. Only callable by the contract owner.
     */
    function pauseContract() external onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused();
    }

    /**
     * @dev Resumes paused contract functionalities. Only callable by the contract owner.
     */
    function unpauseContract() external onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused();
    }

    /**
     * @dev Sets the governance threshold percentage. Only callable by governance once implemented.
     * @param _newThreshold The new governance threshold percentage (e.g., 51 for 51%).
     */
    function setGovernanceThreshold(uint256 _newThreshold) external onlyGovernance whenNotPaused {
        require(_newThreshold <= 100, "Governance threshold cannot exceed 100%.");
        governanceThreshold = _newThreshold;
        emit GovernanceThresholdSet(_newThreshold);
    }

    /**
     * @dev Helper function to calculate the governance approval percentage.
     * @param _positiveVotes Number of positive votes.
     * @param _negativeVotes Number of negative votes.
     * @return The approval percentage (0-100).
     */
    function getGovernanceApprovalPercentage(uint256 _positiveVotes, uint256 _negativeVotes) internal pure returns (uint256) {
        if (_positiveVotes.add(_negativeVotes) == 0) {
            return 0; // Avoid division by zero if no votes yet
        }
        return (_positiveVotes.mul(100)).div(_positiveVotes.add(_negativeVotes));
    }

    /**
     * @dev Withdraws any accidentally sent tokens to this contract. Owner only function for emergency recovery.
     * @param _tokenAddress ERC20 token address to withdraw.
     * @param _recipient Address to receive the withdrawn tokens.
     * @param _amount Amount of tokens to withdraw.
     */
    function emergencyERC20Withdraw(address _tokenAddress, address _recipient, uint256 _amount) external onlyOwner {
        IERC20 token = IERC20(_tokenAddress);
        uint256 contractBalance = token.balanceOf(address(this));
        uint256 withdrawAmount = Math.min(_amount, contractBalance); // Prevent withdrawing more than contract balance.
        require(withdrawAmount > 0, "No tokens to withdraw or amount is zero.");
        bool success = token.transfer(_recipient, withdrawAmount);
        require(success, "ERC20 token withdrawal failed.");
    }

    /**
     * @dev Withdraws any accidentally sent ETH to this contract. Owner only function for emergency recovery.
     * @param _recipient Address to receive the withdrawn ETH.
     */
    function emergencyETHWithdraw(address payable _recipient) external onlyOwner {
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "No ETH to withdraw.");
        (bool success, ) = _recipient.call{value: contractBalance}("");
        require(success, "ETH withdrawal failed.");
    }

    // --- ERC721 Override (Optional - for demonstration) ---
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return getNFTMetadataURI(tokenId);
    }
}

// --- Interface for ERC20 for emergency withdraw ---
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address from, address to, uint256 value);
    event Approval(address owner, address spender, uint256 value);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
}

library Math {
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}
```