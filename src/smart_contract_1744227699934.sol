```solidity
/**
 * @title Dynamic Reputation & Skill-Based NFT Marketplace with DAO Governance
 * @author Bard (Example Smart Contract - Conceptual and Not for Production)
 * @dev This smart contract implements a dynamic NFT marketplace where NFTs represent user skills and reputation,
 *      evolving based on platform activity and community validation. It incorporates DAO governance for platform
 *      upgrades, fee structures, and feature proposals. This is a conceptual example showcasing advanced
 *      Solidity concepts and creative functionalities, distinct from typical open-source contracts.
 *
 * **Outline and Function Summary:**
 *
 * **1. NFT Core Functions (Skill/Reputation NFTs):**
 *    - `mintSkillNFT(address _to, string memory _skillName, string memory _initialDescription)`: Mints a new Skill NFT to an address.
 *    - `transferSkillNFT(address _from, address _to, uint256 _tokenId)`: Transfers a Skill NFT.
 *    - `getSkillNFTMetadata(uint256 _tokenId)`: Retrieves metadata (skill name, description, reputation score) for a Skill NFT.
 *    - `updateSkillDescription(uint256 _tokenId, string memory _newDescription)`: Allows NFT owner to update the skill description.
 *    - `burnSkillNFT(uint256 _tokenId)`: Allows NFT owner to burn their Skill NFT.
 *    - `totalSupplySkillNFT()`: Returns the total supply of Skill NFTs.
 *    - `ownerOfSkillNFT(uint256 _tokenId)`: Returns the owner of a Skill NFT.
 *
 * **2. Reputation System Functions:**
 *    - `endorseSkill(uint256 _tokenId)`: Allows users to endorse (upvote) a Skill NFT, increasing its reputation.
 *    - `reportSkill(uint256 _tokenId)`: Allows users to report (downvote) a Skill NFT, potentially decreasing its reputation.
 *    - `getReputationScore(uint256 _tokenId)`: Retrieves the current reputation score of a Skill NFT.
 *    - `setReputationThresholds(uint256 _endorsementWeight, uint256 _reportWeight)`: Admin function to adjust endorsement and report weights.
 *
 * **3. Skill-Based Marketplace Functions:**
 *    - `listNFTForSale(uint256 _tokenId, uint256 _price)`: NFT owner lists their Skill NFT for sale on the marketplace.
 *    - `buyNFT(uint256 _tokenId)`: Allows users to buy a listed Skill NFT.
 *    - `cancelNFTSale(uint256 _tokenId)`: NFT owner cancels the sale listing of their NFT.
 *    - `getNFTListingDetails(uint256 _tokenId)`: Retrieves listing details (price, seller) for a Skill NFT.
 *    - `setMarketplaceFee(uint256 _feePercentage)`: Admin function to set the marketplace fee percentage.
 *    - `withdrawMarketplaceFees()`: Admin function to withdraw accumulated marketplace fees.
 *
 * **4. DAO Governance Functions (Proposal & Voting):**
 *    - `proposePlatformUpgrade(string memory _proposalDescription, bytes memory _upgradeCalldata)`: Allows DAO members to propose platform upgrades.
 *    - `voteOnProposal(uint256 _proposalId, bool _vote)`: DAO members vote on active proposals.
 *    - `executeProposal(uint256 _proposalId)`: Executes a passed proposal (after voting period).
 *    - `getProposalDetails(uint256 _proposalId)`: Retrieves details of a specific proposal.
 *    - `getProposalVotingStatus(uint256 _proposalId)`: Retrieves the voting status (active, passed, failed) of a proposal.
 *    - `setVotingPeriod(uint256 _votingPeriodInBlocks)`: Admin function to set the proposal voting period.
 *    - `setQuorumThreshold(uint256 _quorumPercentage)`: Admin function to set the quorum percentage for proposals.
 *
 * **5. Utility & Admin Functions:**
 *    - `pauseContract()`: Admin function to pause the contract (emergency stop).
 *    - `unpauseContract()`: Admin function to unpause the contract.
 *    - `setAdmin(address _newAdmin)`: Admin function to change the contract administrator.
 *    - `withdrawAnyERC20(address _tokenAddress, address _to, uint256 _amount)`: Admin function to withdraw accidentally sent ERC20 tokens.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract SkillReputationMarketplace is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIdCounter;

    // Struct to hold NFT metadata
    struct SkillNFTMetadata {
        string skillName;
        string description;
        uint256 reputationScore;
    }

    // Mapping from token ID to SkillNFTMetadata
    mapping(uint256 => SkillNFTMetadata) public skillNFTMetadata;

    // Mapping from token ID to sale listing details
    struct SaleListing {
        uint256 price;
        address seller;
        bool isListed;
    }
    mapping(uint256 => SaleListing) public nftListings;

    // Marketplace fee percentage (e.g., 2% fee = 2)
    uint256 public marketplaceFeePercentage = 2; // Default 2%

    // Reputation system weights
    uint256 public endorsementWeight = 1;
    uint256 public reportWeight = 1;

    // DAO Governance variables
    struct Proposal {
        string description;
        bytes upgradeCalldata;
        uint256 votingStartTime;
        uint256 votingEndTime;
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
        bool isActive;
    }
    mapping(uint256 => Proposal) public proposals;
    Counters.Counter private _proposalIdCounter;
    uint256 public votingPeriodInBlocks = 100; // Default voting period of 100 blocks
    uint256 public quorumThresholdPercentage = 50; // Default quorum of 50%

    event SkillNFTMinted(uint256 tokenId, address indexed to, string skillName);
    event SkillNFTTransferred(uint256 indexed tokenId, address indexed from, address indexed to);
    event SkillNFTDescriptionUpdated(uint256 indexed tokenId, string newDescription);
    event SkillNFTBurned(uint256 indexed tokenId);
    event SkillEndorsed(uint256 indexed tokenId, address endorser);
    event SkillReported(uint256 indexed tokenId, address reporter);
    event NFTListedForSale(uint256 indexed tokenId, uint256 price, address seller);
    event NFTBought(uint256 indexed tokenId, address buyer, uint256 price);
    event NFTSaleCancelled(uint256 indexed tokenId);
    event MarketplaceFeeSet(uint256 feePercentage);
    event MarketplaceFeesWithdrawn(address indexed admin, uint256 amount);
    event PlatformUpgradeProposed(uint256 proposalId, string description);
    event ProposalVoted(uint256 proposalId, address voter, bool vote);
    event ProposalExecuted(uint256 proposalId);
    event VotingPeriodSet(uint256 votingPeriodInBlocks);
    event QuorumThresholdSet(uint256 quorumPercentage);
    event ContractPaused();
    event ContractUnpaused();
    event AdminChanged(address indexed oldAdmin, address indexed newAdmin);
    event ERC20TokensWithdrawn(address tokenAddress, address indexed to, uint256 amount);


    constructor() ERC721("SkillNFT", "SKNFT") {}

    modifier onlyNFTOwner(uint256 _tokenId) {
        require(_exists(_tokenId), "Token does not exist");
        require(ownerOf(_tokenId) == _msgSender(), "You are not the NFT owner");
        _;
    }

    modifier onlyListedNFT(uint256 _tokenId) {
        require(nftListings[_tokenId].isListed, "NFT is not listed for sale");
        _;
    }

    modifier validProposal(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= _proposalIdCounter.current(), "Invalid proposal ID");
        require(proposals[_proposalId].isActive, "Proposal is not active");
        require(block.number <= proposals[_proposalId].votingEndTime, "Voting period has ended");
        _;
    }

    modifier onlyAdmin() {
        require(owner() == _msgSender(), "Only admin can call this function");
        _;
    }

    modifier whenNotPaused() {
        require(!paused(), "Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(paused(), "Contract is not paused");
        _;
    }


    // ------------------------------------------------------------------------
    // 1. NFT Core Functions (Skill/Reputation NFTs)
    // ------------------------------------------------------------------------

    /**
     * @dev Mints a new Skill NFT to an address.
     * @param _to The address to receive the NFT.
     * @param _skillName The name of the skill.
     * @param _initialDescription Initial description of the skill.
     */
    function mintSkillNFT(address _to, string memory _skillName, string memory _initialDescription)
        external
        whenNotPaused
        returns (uint256)
    {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _mint(_to, tokenId);

        skillNFTMetadata[tokenId] = SkillNFTMetadata({
            skillName: _skillName,
            description: _initialDescription,
            reputationScore: 0
        });

        emit SkillNFTMinted(tokenId, _to, _skillName);
        return tokenId;
    }

    /**
     * @dev Transfers a Skill NFT.
     * @param _from The current owner of the NFT.
     * @param _to The address to receive the NFT.
     * @param _tokenId The ID of the NFT to transfer.
     */
    function transferSkillNFT(address _from, address _to, uint256 _tokenId)
        external
        whenNotPaused
    {
        require(ownerOf(_tokenId) == _from, "Sender is not the owner");
        transferFrom(_from, _to, _tokenId);
        emit SkillNFTTransferred(_tokenId, _from, _to);
    }

    /**
     * @dev Retrieves metadata (skill name, description, reputation score) for a Skill NFT.
     * @param _tokenId The ID of the NFT.
     * @return skillName, description, reputationScore
     */
    function getSkillNFTMetadata(uint256 _tokenId)
        external
        view
        returns (string memory skillName, string memory description, uint256 reputationScore)
    {
        require(_exists(_tokenId), "Token does not exist");
        SkillNFTMetadata memory metadata = skillNFTMetadata[_tokenId];
        return (metadata.skillName, metadata.description, metadata.reputationScore);
    }

    /**
     * @dev Allows NFT owner to update the skill description.
     * @param _tokenId The ID of the NFT.
     * @param _newDescription The new description for the skill.
     */
    function updateSkillDescription(uint256 _tokenId, string memory _newDescription)
        external
        onlyNFTOwner(_tokenId)
        whenNotPaused
    {
        skillNFTMetadata[_tokenId].description = _newDescription;
        emit SkillNFTDescriptionUpdated(_tokenId, _newDescription);
    }

    /**
     * @dev Allows NFT owner to burn their Skill NFT.
     * @param _tokenId The ID of the NFT to burn.
     */
    function burnSkillNFT(uint256 _tokenId)
        external
        onlyNFTOwner(_tokenId)
        whenNotPaused
    {
        _burn(_tokenId);
        emit SkillNFTBurned(_tokenId);
    }

    /**
     * @dev Returns the total supply of Skill NFTs.
     * @return The total supply.
     */
    function totalSupplySkillNFT()
        external
        view
        returns (uint256)
    {
        return _tokenIdCounter.current();
    }

    /**
     * @dev Returns the owner of a Skill NFT.
     * @param _tokenId The ID of the NFT.
     * @return The owner address.
     */
    function ownerOfSkillNFT(uint256 _tokenId)
        external
        view
        returns (address)
    {
        return ownerOf(_tokenId);
    }


    // ------------------------------------------------------------------------
    // 2. Reputation System Functions
    // ------------------------------------------------------------------------

    /**
     * @dev Allows users to endorse (upvote) a Skill NFT, increasing its reputation.
     * @param _tokenId The ID of the NFT to endorse.
     */
    function endorseSkill(uint256 _tokenId)
        external
        whenNotPaused
    {
        require(_exists(_tokenId), "Token does not exist");
        // Prevent self-endorsement (optional) - can remove if self-endorsement is allowed
        require(ownerOf(_tokenId) != _msgSender(), "Cannot endorse your own skill");

        skillNFTMetadata[_tokenId].reputationScore += endorsementWeight;
        emit SkillEndorsed(_tokenId, _msgSender());
    }

    /**
     * @dev Allows users to report (downvote) a Skill NFT, potentially decreasing its reputation.
     * @param _tokenId The ID of the NFT to report.
     */
    function reportSkill(uint256 _tokenId)
        external
        whenNotPaused
    {
        require(_exists(_tokenId), "Token does not exist");
        // Prevent self-reporting (optional) - usually makes sense
        require(ownerOf(_tokenId) != _msgSender(), "Cannot report your own skill");

        if (skillNFTMetadata[_tokenId].reputationScore >= reportWeight) {
            skillNFTMetadata[_tokenId].reputationScore -= reportWeight;
        } else {
            skillNFTMetadata[_tokenId].reputationScore = 0; // Prevent negative score
        }
        emit SkillReported(_tokenId, _msgSender());
    }

    /**
     * @dev Retrieves the current reputation score of a Skill NFT.
     * @param _tokenId The ID of the NFT.
     * @return The reputation score.
     */
    function getReputationScore(uint256 _tokenId)
        external
        view
        returns (uint256)
    {
        require(_exists(_tokenId), "Token does not exist");
        return skillNFTMetadata[_tokenId].reputationScore;
    }

    /**
     * @dev Admin function to adjust endorsement and report weights for reputation system.
     * @param _endorsementWeight The new weight for endorsements.
     * @param _reportWeight The new weight for reports.
     */
    function setReputationThresholds(uint256 _endorsementWeight, uint256 _reportWeight)
        external
        onlyAdmin
        whenNotPaused
    {
        endorsementWeight = _endorsementWeight;
        reportWeight = _reportWeight;
    }


    // ------------------------------------------------------------------------
    // 3. Skill-Based Marketplace Functions
    // ------------------------------------------------------------------------

    /**
     * @dev NFT owner lists their Skill NFT for sale on the marketplace.
     * @param _tokenId The ID of the NFT to list.
     * @param _price The price in wei to list the NFT for.
     */
    function listNFTForSale(uint256 _tokenId, uint256 _price)
        external
        onlyNFTOwner(_tokenId)
        whenNotPaused
    {
        require(_price > 0, "Price must be greater than zero");
        nftListings[_tokenId] = SaleListing({
            price: _price,
            seller: _msgSender(),
            isListed: true
        });
        emit NFTListedForSale(_tokenId, _price, _msgSender());
    }

    /**
     * @dev Allows users to buy a listed Skill NFT.
     * @param _tokenId The ID of the NFT to buy.
     */
    function buyNFT(uint256 _tokenId)
        external
        payable
        onlyListedNFT(_tokenId)
        whenNotPaused
    {
        SaleListing memory listing = nftListings[_tokenId];
        require(_msgSender() != listing.seller, "Seller cannot buy their own NFT");
        require(msg.value >= listing.price, "Insufficient funds sent");

        uint256 marketplaceFee = (listing.price * marketplaceFeePercentage) / 100;
        uint256 sellerPayout = listing.price - marketplaceFee;

        // Transfer funds
        payable(listing.seller).transfer(sellerPayout);
        payable(owner()).transfer(marketplaceFee); // Admin/Contract owner receives marketplace fees

        // Transfer NFT
        transferFrom(listing.seller, _msgSender(), _tokenId);

        // Update listing status
        nftListings[_tokenId].isListed = false;
        delete nftListings[_tokenId]; // Clean up listing data

        emit NFTBought(_tokenId, _msgSender(), listing.price);
    }

    /**
     * @dev NFT owner cancels the sale listing of their NFT.
     * @param _tokenId The ID of the NFT to cancel listing for.
     */
    function cancelNFTSale(uint256 _tokenId)
        external
        onlyNFTOwner(_tokenId)
        whenNotPaused
    {
        require(nftListings[_tokenId].isListed, "NFT is not currently listed for sale");
        nftListings[_tokenId].isListed = false;
        delete nftListings[_tokenId]; // Clean up listing data
        emit NFTSaleCancelled(_tokenId);
    }

    /**
     * @dev Retrieves listing details (price, seller) for a Skill NFT.
     * @param _tokenId The ID of the NFT.
     * @return price, seller, isListed
     */
    function getNFTListingDetails(uint256 _tokenId)
        external
        view
        returns (uint256 price, address seller, bool isListed)
    {
        require(_exists(_tokenId), "Token does not exist");
        return (nftListings[_tokenId].price, nftListings[_tokenId].seller, nftListings[_tokenId].isListed);
    }

    /**
     * @dev Admin function to set the marketplace fee percentage.
     * @param _feePercentage The new marketplace fee percentage (e.g., 2 for 2%).
     */
    function setMarketplaceFee(uint256 _feePercentage)
        external
        onlyAdmin
        whenNotPaused
    {
        require(_feePercentage <= 100, "Fee percentage cannot exceed 100%");
        marketplaceFeePercentage = _feePercentage;
        emit MarketplaceFeeSet(_feePercentage);
    }

    /**
     * @dev Admin function to withdraw accumulated marketplace fees.
     */
    function withdrawMarketplaceFees()
        external
        onlyAdmin
        whenNotPaused
    {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
        emit MarketplaceFeesWithdrawn(owner(), balance);
    }


    // ------------------------------------------------------------------------
    // 4. DAO Governance Functions (Proposal & Voting)
    // ------------------------------------------------------------------------

    /**
     * @dev Allows DAO members to propose platform upgrades.
     * @param _proposalDescription Description of the proposed upgrade.
     * @param _upgradeCalldata Calldata for the upgrade function (if applicable).
     */
    function proposePlatformUpgrade(string memory _proposalDescription, bytes memory _upgradeCalldata)
        external
        whenNotPaused
    {
        _proposalIdCounter.increment();
        uint256 proposalId = _proposalIdCounter.current();
        proposals[proposalId] = Proposal({
            description: _proposalDescription,
            upgradeCalldata: _upgradeCalldata,
            votingStartTime: block.number,
            votingEndTime: block.number + votingPeriodInBlocks,
            yesVotes: 0,
            noVotes: 0,
            executed: false,
            isActive: true
        });
        emit PlatformUpgradeProposed(proposalId, _proposalDescription);
    }

    /**
     * @dev DAO members vote on active proposals.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _vote True for yes, false for no.
     */
    function voteOnProposal(uint256 _proposalId, bool _vote)
        external
        validProposal(_proposalId)
        whenNotPaused
    {
        // In a real DAO, you would check if the voter is a DAO member (e.g., based on token holdings)
        // For this example, assume all users are DAO members.
        Proposal storage proposal = proposals[_proposalId];
        if (_vote) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }
        emit ProposalVoted(_proposalId, _msgSender(), _vote);
    }

    /**
     * @dev Executes a passed proposal (after voting period).
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId)
        external
        whenNotPaused
    {
        require(_proposalId > 0 && _proposalId <= _proposalIdCounter.current(), "Invalid proposal ID");
        Proposal storage proposal = proposals[_proposalId];
        require(!proposal.executed, "Proposal already executed");
        require(block.number > proposal.votingEndTime, "Voting period has not ended");
        require(proposal.isActive, "Proposal is not active");

        uint256 totalVotes = proposal.yesVotes + proposal.noVotes;
        uint256 quorum = (totalVotes * 100) / totalSupplySkillNFT(); // Example: Quorum based on total NFT supply
        require(quorum >= quorumThresholdPercentage, "Quorum not reached");
        require(proposal.yesVotes > proposal.noVotes, "Proposal failed to pass");

        proposal.executed = true;
        proposal.isActive = false; // Mark as inactive after execution

        // Execute the upgrade logic (example - can be customized based on proposal type)
        if (proposal.upgradeCalldata.length > 0) {
            // Example: Delegatecall to another contract or perform some logic.
            // In a real system, this would be carefully designed and potentially use a proxy pattern.
            // For this example, we are just emitting an event.
            // (delegatecall is complex and security-sensitive, for demonstration only in a conceptual contract)
            // (bool success, bytes memory returnData) = address(this).delegatecall(proposal.upgradeCalldata);
            // require(success, "Proposal execution failed");
        }

        emit ProposalExecuted(_proposalId);
    }

    /**
     * @dev Retrieves details of a specific proposal.
     * @param _proposalId The ID of the proposal.
     * @return proposal details (description, votingStartTime, votingEndTime, yesVotes, noVotes, executed, isActive).
     */
    function getProposalDetails(uint256 _proposalId)
        external
        view
        returns (string memory description, uint256 votingStartTime, uint256 votingEndTime, uint256 yesVotes, uint256 noVotes, bool executed, bool isActive)
    {
        require(_proposalId > 0 && _proposalId <= _proposalIdCounter.current(), "Invalid proposal ID");
        Proposal memory proposal = proposals[_proposalId];
        return (proposal.description, proposal.votingStartTime, proposal.votingEndTime, proposal.yesVotes, proposal.noVotes, proposal.executed, proposal.isActive);
    }

    /**
     * @dev Retrieves the voting status (active, passed, failed) of a proposal.
     * @param _proposalId The ID of the proposal.
     * @return status string (e.g., "Active", "Passed", "Failed").
     */
    function getProposalVotingStatus(uint256 _proposalId)
        external
        view
        returns (string memory status)
    {
        require(_proposalId > 0 && _proposalId <= _proposalIdCounter.current(), "Invalid proposal ID");
        Proposal memory proposal = proposals[_proposalId];

        if (!proposal.isActive) {
            if (proposal.executed) {
                return "Passed and Executed";
            } else {
                return "Failed (No Quorum or Votes)";
            }
        } else if (block.number > proposal.votingEndTime) {
            uint256 totalVotes = proposal.yesVotes + proposal.noVotes;
            uint256 quorum = (totalVotes * 100) / totalSupplySkillNFT();
            if (quorum >= quorumThresholdPercentage && proposal.yesVotes > proposal.noVotes) {
                return "Passed - Ready for Execution";
            } else {
                proposal.isActive = false; // Mark as inactive if voting ended and failed
                return "Failed (No Quorum or Votes)";
            }
        } else {
            return "Active - Voting in Progress";
        }
    }

    /**
     * @dev Admin function to set the proposal voting period in blocks.
     * @param _votingPeriodInBlocks The new voting period in blocks.
     */
    function setVotingPeriod(uint256 _votingPeriodInBlocks)
        external
        onlyAdmin
        whenNotPaused
    {
        votingPeriodInBlocks = _votingPeriodInBlocks;
        emit VotingPeriodSet(_votingPeriodInBlocks);
    }

    /**
     * @dev Admin function to set the quorum percentage for proposals.
     * @param _quorumPercentage The new quorum percentage (e.g., 50 for 50%).
     */
    function setQuorumThreshold(uint256 _quorumPercentage)
        external
        onlyAdmin
        whenNotPaused
    {
        require(_quorumPercentage <= 100, "Quorum percentage cannot exceed 100%");
        quorumThresholdPercentage = _quorumPercentage;
        emit QuorumThresholdSet(_quorumPercentage);
    }


    // ------------------------------------------------------------------------
    // 5. Utility & Admin Functions
    // ------------------------------------------------------------------------

    /**
     * @dev Pauses the contract, preventing most state-changing functions from being called.
     */
    function pauseContract() external onlyOwner whenNotPaused {
        _pause();
        emit ContractPaused();
    }

    /**
     * @dev Unpauses the contract, allowing functions to be called again.
     */
    function unpauseContract() external onlyOwner whenPaused {
        _unpause();
        emit ContractUnpaused();
    }

    /**
     * @dev Admin function to set a new contract administrator (owner).
     * @param _newAdmin The address of the new admin.
     */
    function setAdmin(address _newAdmin) external onlyOwner {
        address oldAdmin = owner();
        transferOwnership(_newAdmin);
        emit AdminChanged(oldAdmin, _newAdmin);
    }

    /**
     * @dev Admin function to withdraw any accidentally sent ERC20 tokens from the contract.
     * @param _tokenAddress The address of the ERC20 token contract.
     * @param _to The address to send the tokens to.
     * @param _amount The amount of tokens to withdraw.
     */
    function withdrawAnyERC20(address _tokenAddress, address _to, uint256 _amount) external onlyOwner {
        IERC20 token = IERC20(_tokenAddress);
        uint256 contractBalance = token.balanceOf(address(this));
        require(_amount <= contractBalance, "Withdraw amount exceeds contract balance");
        token.transfer(_to, _amount);
        emit ERC20TokensWithdrawn(_tokenAddress, _to, _amount);
    }

    /**
     * @dev @inheritdoc ERC721
     * The URI for token metadata. This example returns an empty string,
     * in a real application, this would point to off-chain metadata, potentially dynamic.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        // In a real-world scenario, this would generate a dynamic URI based on skillNFTMetadata[tokenId]
        // For example, pointing to IPFS or a centralized metadata server.
        // For simplicity in this example, we return an empty string.
        return ""; // Example: return string(abi.encodePacked("ipfs://your_ipfs_cid/", tokenId.toString(), ".json"));
    }

    // **Optional - Example function to get list of active proposals (for UI)**
    function getActiveProposalIds() external view returns (uint256[] memory) {
        uint256 proposalCount = _proposalIdCounter.current();
        uint256 activeProposalCount = 0;
        for (uint256 i = 1; i <= proposalCount; i++) {
            if (proposals[i].isActive) {
                activeProposalCount++;
            }
        }
        uint256[] memory activeProposalIds = new uint256[](activeProposalCount);
        uint256 index = 0;
        for (uint256 i = 1; i <= proposalCount; i++) {
            if (proposals[i].isActive) {
                activeProposalIds[index] = i;
                index++;
            }
        }
        return activeProposalIds;
    }
}

// Minimal ERC20 interface for withdrawAnyERC20 function
interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}
```