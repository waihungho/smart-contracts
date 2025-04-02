```solidity
/**
 * @title Decentralized Autonomous Art Collective (DAAC) Smart Contract
 * @author Bard (AI Assistant)
 * @dev A smart contract for a Decentralized Autonomous Art Collective (DAAC).
 * It allows artists to submit art, community members to vote on art, fractionalize NFTs,
 * propose exhibitions, manage grants, and participate in a decentralized art ecosystem.
 *
 * Function Summary:
 *
 * **Core Art Management:**
 * 1. `submitArtProposal(string memory _title, string memory _description, string memory _ipfsHash)`: Allows members to submit new art proposals.
 * 2. `voteOnArtProposal(uint256 _proposalId, bool _support)`: Allows members to vote on pending art proposals.
 * 3. `executeArtProposal(uint256 _proposalId)`: Executes an approved art proposal, minting an NFT for the artwork.
 * 4. `burnArtNFT(uint256 _tokenId)`: Allows authorized roles to burn (destroy) an NFT.
 * 5. `setBaseURI(string memory _baseURI)`: Allows admin to set the base URI for NFT metadata.
 * 6. `getArtNFTByIndex(uint256 _index)`: Retrieves the token ID of an art NFT by its index.
 * 7. `getArtProposalDetails(uint256 _proposalId)`: Retrieves detailed information about an art proposal.
 * 8. `getNFTDetails(uint256 _tokenId)`: Retrieves details about a minted art NFT.
 *
 * **Fractionalization & Shared Ownership:**
 * 9. `fractionalizeNFT(uint256 _tokenId, uint256 _fractionCount)`: Fractionalizes an art NFT into ERC20 tokens.
 * 10. `redeemFractionalizedNFT(uint256 _tokenId)`: Allows fractional token holders to redeem the original NFT (requires majority).
 * 11. `getFractionTokenAddress(uint256 _tokenId)`: Retrieves the ERC20 token address for a fractionalized NFT.
 *
 * **DAO Governance & Membership:**
 * 12. `applyForMembership(string memory _reason)`: Allows anyone to apply for membership in the DAAC.
 * 13. `approveMembership(address _applicant, bool _approve)`: Allows admin to approve or reject membership applications.
 * 14. `revokeMembership(address _member)`: Allows admin to revoke membership from a member.
 * 15. `isMember(address _account)`: Checks if an address is a member of the DAAC.
 * 16. `submitGrantProposal(address _artist, string memory _grantDescription, uint256 _grantAmount)`: Allows members to propose grants for artists.
 * 17. `voteOnGrantProposal(uint256 _proposalId, bool _support)`: Allows members to vote on pending grant proposals.
 * 18. `executeGrantProposal(uint256 _proposalId)`: Executes an approved grant proposal, transferring funds to the artist.
 * 19. `setMessage(string memory _newMessage)`: Allows admin to set a global message for the DAAC.
 * 20. `getMessage()`: Retrieves the current global message of the DAAC.
 * 21. `emergencyShutdown()`: Allows admin to pause critical functionalities in case of emergency.
 * 22. `resumeContract()`: Allows admin to resume contract functionalities after emergency shutdown.
 * 23. `setVotingDuration(uint256 _durationInBlocks)`: Allows admin to set the voting duration for proposals.
 * 24. `setQuorum(uint256 _newQuorum)`: Allows admin to set the quorum for proposal approval (percentage).
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract DecentralizedArtCollective is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _artNFTCounter;
    Counters.Counter private _proposalCounter;

    string private _baseURI;
    string public message;
    uint256 public votingDurationBlocks = 100; // Default voting duration in blocks
    uint256 public quorumPercentage = 50; // Default quorum percentage for proposal approval
    bool public contractPaused = false;

    // Membership Management
    mapping(address => bool) public members;
    mapping(address => string) public membershipApplicationReasons;
    address[] public pendingMembershipApplications;

    // Art Proposals
    struct ArtProposal {
        string title;
        string description;
        string ipfsHash;
        address proposer;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        uint256 votingEndTime;
    }
    mapping(uint256 => ArtProposal) public artProposals;
    mapping(uint256 => mapping(address => bool)) public proposalVotes; // proposalId => voter => votedSupport

    // Artist Grant Proposals
    struct GrantProposal {
        address artist;
        string description;
        uint256 grantAmount;
        address proposer;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        uint256 votingEndTime;
    }
    mapping(uint256 => GrantProposal) public grantProposals;
    mapping(uint256 => mapping(address => bool)) public grantProposalVotes; // proposalId => voter => votedSupport

    // Fractionalized NFTs
    mapping(uint256 => address) public fractionalizedNFTContracts; // tokenId => fractionTokenContractAddress

    // Events
    event ArtProposalSubmitted(uint256 proposalId, string title, address proposer);
    event ArtProposalVoted(uint256 proposalId, address voter, bool support);
    event ArtProposalExecuted(uint256 proposalId, uint256 tokenId);
    event ArtNFTRemoved(uint256 tokenId);
    event MembershipApplied(address applicant, string reason);
    event MembershipApproved(address member, bool approved);
    event MembershipRevoked(address member);
    event GrantProposalSubmitted(uint256 proposalId, address artist, uint256 amount, address proposer);
    event GrantProposalVoted(uint256 proposalId, address voter, bool support);
    event GrantProposalExecuted(uint256 proposalId, uint256 grantAmount, address artist);
    event ContractMessageUpdated(string newMessage);
    event ContractPaused();
    event ContractResumed();
    event VotingDurationChanged(uint256 newDuration);
    event QuorumPercentageChanged(uint256 newQuorum);
    event NFTFractionalized(uint256 tokenId, address fractionTokenAddress, uint256 fractionCount);
    event NFTFractionRedeemed(uint256 tokenId);

    modifier onlyMember() {
        require(members[msg.sender], "You are not a member of the DAAC.");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == owner(), "Only admin can perform this action.");
        _;
    }

    modifier whenNotPaused() {
        require(!contractPaused, "Contract is currently paused.");
        _;
    }

    constructor(string memory _name, string memory _symbol, string memory _uri) ERC721(_name, _symbol) {
        _baseURI = _uri;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender); // Admin role is the contract deployer initially
    }

    // --- Core Art Management ---

    /**
     * @dev Allows members to submit a new art proposal.
     * @param _title The title of the artwork proposal.
     * @param _description A brief description of the artwork.
     * @param _ipfsHash IPFS hash pointing to the artwork's metadata or file.
     */
    function submitArtProposal(string memory _title, string memory _description, string memory _ipfsHash) external onlyMember whenNotPaused {
        _proposalCounter.increment();
        uint256 proposalId = _proposalCounter.current();
        artProposals[proposalId] = ArtProposal({
            title: _title,
            description: _description,
            ipfsHash: _ipfsHash,
            proposer: msg.sender,
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            votingEndTime: block.number + votingDurationBlocks
        });
        emit ArtProposalSubmitted(proposalId, _title, msg.sender);
    }

    /**
     * @dev Allows members to vote on a pending art proposal.
     * @param _proposalId The ID of the art proposal to vote on.
     * @param _support True to vote in favor, false to vote against.
     */
    function voteOnArtProposal(uint256 _proposalId, bool _support) external onlyMember whenNotPaused {
        require(artProposals[_proposalId].votingEndTime > block.number, "Voting for this proposal has ended.");
        require(!proposalVotes[_proposalId][msg.sender], "You have already voted on this proposal.");

        proposalVotes[_proposalId][msg.sender] = true;
        if (_support) {
            artProposals[_proposalId].votesFor++;
        } else {
            artProposals[_proposalId].votesAgainst++;
        }
        emit ArtProposalVoted(_proposalId, msg.sender, _support);
    }

    /**
     * @dev Executes an approved art proposal if it reaches quorum and voting time is over.
     * Mints an NFT for the approved artwork.
     * @param _proposalId The ID of the art proposal to execute.
     */
    function executeArtProposal(uint256 _proposalId) external whenNotPaused {
        require(artProposals[_proposalId].votingEndTime <= block.number, "Voting is still ongoing.");
        require(!artProposals[_proposalId].executed, "Proposal already executed.");

        uint256 totalVotes = artProposals[_proposalId].votesFor + artProposals[_proposalId].votesAgainst;
        require(totalVotes > 0, "No votes cast for this proposal, cannot execute."); // Prevent division by zero
        uint256 approvalPercentage = (artProposals[_proposalId].votesFor * 100) / totalVotes;
        require(approvalPercentage >= quorumPercentage, "Proposal did not reach quorum.");

        _artNFTCounter.increment();
        uint256 tokenId = _artNFTCounter.current();
        _mint(address(this), tokenId); // Mint to contract, can be transferred later or fractionalized.
        _setTokenURI(tokenId, string(abi.encodePacked(_baseURI, _proposalId.toString()))); // Using proposal ID for unique URI for now, can be improved.

        artProposals[_proposalId].executed = true;
        emit ArtProposalExecuted(_proposalId, tokenId);
    }

    /**
     * @dev Allows authorized roles (admin) to burn (destroy) an NFT.
     * @param _tokenId The ID of the NFT to burn.
     */
    function burnArtNFT(uint256 _tokenId) external onlyAdmin whenNotPaused {
        _burn(_tokenId);
        emit ArtNFTRemoved(_tokenId);
    }

    /**
     * @dev Sets the base URI for NFT metadata. Only admin can call this.
     * @param _baseURI The new base URI.
     */
    function setBaseURI(string memory _baseURI) external onlyAdmin whenNotPaused {
        _baseURI = _baseURI;
    }

    /**
     * @dev Retrieves the token ID of an art NFT by its index.
     * @param _index The index of the NFT in the collection.
     * @return The token ID of the NFT at the given index.
     */
    function getArtNFTByIndex(uint256 _index) external view returns (uint256) {
        require(_index < _artNFTCounter.current(), "Index out of bounds.");
        return _index + 1; // Assuming token IDs start from 1 and are sequential.  In a real implementation you might need to track token IDs more robustly if burns are common.
    }

    /**
     * @dev Retrieves detailed information about an art proposal.
     * @param _proposalId The ID of the art proposal.
     * @return ArtProposal struct containing proposal details.
     */
    function getArtProposalDetails(uint256 _proposalId) external view returns (ArtProposal memory) {
        return artProposals[_proposalId];
    }

    /**
     * @dev Retrieves details about a minted art NFT.
     * @param _tokenId The ID of the NFT.
     * @return A string containing the token URI.
     */
    function getNFTDetails(uint256 _tokenId) external view returns (string memory) {
        return tokenURI(_tokenId);
    }


    // --- Fractionalization & Shared Ownership ---

    /**
     * @dev Fractionalizes an art NFT into ERC20 tokens.
     * Creates a new ERC20 contract representing fractions of the NFT.
     * @param _tokenId The ID of the NFT to fractionalize.
     * @param _fractionCount The number of fractions to create.
     */
    function fractionalizeNFT(uint256 _tokenId, uint256 _fractionCount) external onlyAdmin whenNotPaused {
        require(_exists(_tokenId), "NFT does not exist.");
        require(fractionalizedNFTContracts[_tokenId] == address(0), "NFT is already fractionalized.");
        require(_fractionCount > 0, "Fraction count must be greater than zero.");

        string memory fractionTokenName = string(abi.encodePacked(name(), " Fraction - ", _tokenId.toString()));
        string memory fractionTokenSymbol = string(abi.encodePacked(symbol(), "FRAC", _tokenId.toString()));

        FractionToken fractionToken = new FractionToken(fractionTokenName, fractionTokenSymbol, _fractionCount);
        fractionalizedNFTContracts[_tokenId] = address(fractionToken);

        // Transfer the NFT to the fraction token contract (for safekeeping until redemption)
        safeTransferFrom(owner(), address(fractionToken), _tokenId); // Assuming contract owner initiates fractionalization

        emit NFTFractionalized(_tokenId, address(fractionToken), _fractionCount);
    }

    /**
     * @dev Allows fractional token holders to redeem the original NFT.
     * Requires a majority of fractional tokens to initiate redemption.
     * In a real-world scenario, you would need a more robust redemption mechanism
     * potentially involving voting by fractional token holders in the ERC20 contract itself.
     * This is a simplified example for demonstration.
     * @param _tokenId The ID of the fractionalized NFT to redeem.
     */
    function redeemFractionalizedNFT(uint256 _tokenId) external whenNotPaused {
        require(fractionalizedNFTContracts[_tokenId] != address(0), "NFT is not fractionalized.");
        FractionToken fractionToken = FractionToken(fractionalizedNFTContracts[_tokenId]);

        // Simplified redemption logic: Anyone can call redeem if they hold enough fraction tokens.
        // In a real scenario, you might need to track votes from fraction holders within the FractionToken contract.
        // Here we just check if the caller owns more than half of the fraction tokens (simplified majority).
        uint256 totalSupply = fractionToken.totalSupply();
        uint256 holderBalance = fractionToken.balanceOf(msg.sender);
        require(holderBalance * 2 > totalSupply, "Not enough fractional tokens to redeem."); // Simplified majority check

        // Transfer the original NFT back to the redeemer (again, simplified, needs better logic in production)
        FractionToken(fractionalizedNFTContracts[_tokenId]).transferNFT(msg.sender, _tokenId); // Assuming a function in FractionToken to do this.

        // Clean up fractionalization data (optional, depending on desired behavior)
        delete fractionalizedNFTContracts[_tokenId];

        emit NFTFractionRedeemed(_tokenId);
    }

    /**
     * @dev Retrieves the ERC20 token address for a fractionalized NFT.
     * @param _tokenId The ID of the NFT.
     * @return The address of the ERC20 fraction token contract, or address(0) if not fractionalized.
     */
    function getFractionTokenAddress(uint256 _tokenId) external view returns (address) {
        return fractionalizedNFTContracts[_tokenId];
    }


    // --- DAO Governance & Membership ---

    /**
     * @dev Allows anyone to apply for membership in the DAAC.
     * @param _reason A short reason for wanting to join the DAAC.
     */
    function applyForMembership(string memory _reason) external whenNotPaused {
        require(!members[msg.sender], "You are already a member.");
        membershipApplicationReasons[msg.sender] = _reason;
        pendingMembershipApplications.push(msg.sender);
        emit MembershipApplied(msg.sender, _reason);
    }

    /**
     * @dev Allows admin to approve or reject membership applications.
     * @param _applicant The address of the applicant.
     * @param _approve True to approve, false to reject.
     */
    function approveMembership(address _applicant, bool _approve) external onlyAdmin whenNotPaused {
        bool found = false;
        for (uint i = 0; i < pendingMembershipApplications.length; i++) {
            if (pendingMembershipApplications[i] == _applicant) {
                found = true;
                // Remove from pending list (shift elements down)
                for (uint j = i; j < pendingMembershipApplications.length - 1; j++) {
                    pendingMembershipApplications[j] = pendingMembershipApplications[j + 1];
                }
                pendingMembershipApplications.pop();
                break;
            }
        }
        require(found, "Applicant not found in pending list.");

        if (_approve) {
            members[_applicant] = true;
        } else {
            delete membershipApplicationReasons[_applicant]; // Clean up reason if rejected
        }
        emit MembershipApproved(_applicant, _approve);
    }

    /**
     * @dev Allows admin to revoke membership from a member.
     * @param _member The address of the member to revoke membership from.
     */
    function revokeMembership(address _member) external onlyAdmin whenNotPaused {
        require(members[_member], "Address is not a member.");
        delete members[_member];
        emit MembershipRevoked(_member);
    }

    /**
     * @dev Checks if an address is a member of the DAAC.
     * @param _account The address to check.
     * @return True if the address is a member, false otherwise.
     */
    function isMember(address _account) external view returns (bool) {
        return members[_account];
    }

    /**
     * @dev Allows members to propose grants for artists.
     * @param _artist The address of the artist to receive the grant.
     * @param _grantDescription Description of why the grant is being proposed.
     * @param _grantAmount The amount of Ether to grant.
     */
    function submitGrantProposal(address _artist, string memory _grantDescription, uint256 _grantAmount) external onlyMember whenNotPaused {
        require(_grantAmount > 0, "Grant amount must be positive.");
        _proposalCounter.increment(); // Reuse proposal counter for simplicity, could have separate counters
        uint256 proposalId = _proposalCounter.current();
        grantProposals[proposalId] = GrantProposal({
            artist: _artist,
            description: _grantDescription,
            grantAmount: _grantAmount,
            proposer: msg.sender,
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            votingEndTime: block.number + votingDurationBlocks
        });
        emit GrantProposalSubmitted(proposalId, _artist, _grantAmount, msg.sender);
    }

    /**
     * @dev Allows members to vote on a pending grant proposal.
     * @param _proposalId The ID of the grant proposal to vote on.
     * @param _support True to vote in favor, false to vote against.
     */
    function voteOnGrantProposal(uint256 _proposalId, bool _support) external onlyMember whenNotPaused {
        require(grantProposals[_proposalId].votingEndTime > block.number, "Voting for this grant proposal has ended.");
        require(!grantProposalVotes[_proposalId][msg.sender], "You have already voted on this grant proposal.");

        grantProposalVotes[_proposalId][msg.sender] = true;
        if (_support) {
            grantProposals[_proposalId].votesFor++;
        } else {
            grantProposals[_proposalId].votesAgainst++;
        }
        emit GrantProposalVoted(_proposalId, msg.sender, _support);
    }

    /**
     * @dev Executes an approved grant proposal if it reaches quorum and voting time is over.
     * Transfers the grant amount to the artist.
     * @param _proposalId The ID of the grant proposal to execute.
     */
    function executeGrantProposal(uint256 _proposalId) external onlyAdmin whenNotPaused { // Admin executes grant proposals for fund management
        require(grantProposals[_proposalId].votingEndTime <= block.number, "Voting is still ongoing.");
        require(!grantProposals[_proposalId].executed, "Grant proposal already executed.");

        uint256 totalVotes = grantProposals[_proposalId].votesFor + grantProposals[_proposalId].votesAgainst;
        require(totalVotes > 0, "No votes cast for this grant proposal, cannot execute."); // Prevent division by zero
        uint256 approvalPercentage = (grantProposals[_proposalId].votesFor * 100) / totalVotes;
        require(approvalPercentage >= quorumPercentage, "Grant proposal did not reach quorum.");
        require(address(this).balance >= grantProposals[_proposalId].grantAmount, "Contract balance is insufficient for grant.");

        payable(grantProposals[_proposalId].artist).transfer(grantProposals[_proposalId].grantAmount);
        grantProposals[_proposalId].executed = true;
        emit GrantProposalExecuted(_proposalId, grantProposals[_proposalId].grantAmount, grantProposals[_proposalId].artist);
    }

    // --- Community & Admin Functions ---

    /**
     * @dev Allows admin to set a global message for the DAAC.
     * @param _newMessage The new message to set.
     */
    function setMessage(string memory _newMessage) external onlyAdmin whenNotPaused {
        message = _newMessage;
        emit ContractMessageUpdated(_newMessage);
    }

    /**
     * @dev Retrieves the current global message of the DAAC.
     * @return The current global message.
     */
    function getMessage() external view returns (string memory) {
        return message;
    }

    /**
     * @dev Allows admin to pause critical functionalities in case of emergency.
     */
    function emergencyShutdown() external onlyAdmin {
        contractPaused = true;
        emit ContractPaused();
    }

    /**
     * @dev Allows admin to resume contract functionalities after emergency shutdown.
     */
    function resumeContract() external onlyAdmin {
        contractPaused = false;
        emit ContractResumed();
    }

    /**
     * @dev Allows admin to set the voting duration for proposals in blocks.
     * @param _durationInBlocks The new voting duration in blocks.
     */
    function setVotingDuration(uint256 _durationInBlocks) external onlyAdmin {
        votingDurationBlocks = _durationInBlocks;
        emit VotingDurationChanged(_durationInBlocks);
    }

    /**
     * @dev Allows admin to set the quorum percentage for proposal approval.
     * @param _newQuorum The new quorum percentage (0-100).
     */
    function setQuorum(uint256 _newQuorum) external onlyAdmin {
        require(_newQuorum <= 100, "Quorum percentage cannot exceed 100.");
        quorumPercentage = _newQuorum;
        emit QuorumPercentageChanged(_newQuorum);
    }

    // --- Fallback and Receive Functions ---
    receive() external payable {} // To receive Ether for grant proposals
    fallback() external payable {}

}

// --- Helper Contract for Fractionalized Tokens ---
contract FractionToken is ERC20, Ownable {
    ERC721 public originalNFTContract;
    uint256 public originalNFTTokenId;

    constructor(string memory _name, string memory _symbol, uint256 _initialSupply) ERC20(_name, _symbol) {
        _mint(msg.sender, _initialSupply); // Admin (fractionalizer) initially gets all fraction tokens.
        originalNFTContract = ERC721(msg.sender); // Assuming the contract that deploys this is the NFT contract, adjust if needed.
        // originalNFTTokenId will be set when fractionalization is called in the main contract.
    }

    function setOriginalNFTTokenId(uint256 _tokenId) external onlyOwner {
        originalNFTTokenId = _tokenId;
    }

    function transferNFT(address _recipient, uint256 _tokenId) external onlyOwner { // Simple function for NFT transfer back, needs more robust logic in real-world
        require(msg.sender == address(originalNFTContract), "Only original NFT contract can call this.");
        require(_tokenId == originalNFTTokenId, "Incorrect token ID.");
        originalNFTContract.safeTransferFrom(address(this), _recipient, _tokenId); // Transfer NFT from FractionToken contract to recipient.
    }
}
```