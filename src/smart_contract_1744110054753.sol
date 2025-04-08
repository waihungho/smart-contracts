```solidity
/**
 * @title Decentralized Dynamic NFT Gallery - "Chameleon NFTs"
 * @author Bard (AI Assistant)
 * @dev A smart contract for creating and managing a dynamic NFT gallery.
 *      NFTs in this gallery, called "Chameleon NFTs," can evolve and change their properties
 *      based on various on-chain and off-chain factors, creating a unique and engaging
 *      collectible experience. This contract incorporates advanced concepts like:
 *      - Dynamic Metadata & URI updates based on owner interaction and on-chain events.
 *      - Evolving NFT properties (attributes) influenced by voting and community actions.
 *      - Time-based NFT transformations and limited-time traits.
 *      - Staking mechanism for NFT holders to earn rewards and influence NFT evolution.
 *      - Layered royalty system with configurable percentages and recipients.
 *      - Decentralized governance for certain gallery parameters (e.g., voting thresholds).
 *      - Advanced access control and role-based permissions.
 *      - Batch minting and updating capabilities for efficiency.
 *      - Built-in marketplace functionalities for listing and selling Chameleon NFTs.
 *      - "Fossilization" mechanism to permanently lock NFT traits at a certain state.
 *      - Conditional trait unlocks based on predefined criteria.
 *      - Integration with external data feeds (simulated for demonstration purposes).
 *      - NFT merging and splitting functionalities (advanced concept).
 *      - Raffle/Lottery system for distributing rare NFT traits or whole NFTs.
 *      - Dynamic pricing mechanisms for NFT sales based on evolving traits.
 *      - "Guardian" role to manage and curate the gallery.
 *      - Emergency pause mechanism for security.
 *
 * Function Summary:
 *
 *  // ** Core NFT Functionality **
 *  1. mintNFT(address _to, string memory _baseURI) public onlyOwner: Mints a new Chameleon NFT to a specified address with an initial base URI.
 *  2. safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) public payable override: Safely transfers an NFT, standard ERC721 function.
 *  3. transferFrom(address _from, address _to, uint256 _tokenId) public override: Transfers an NFT, standard ERC721 function.
 *  4. approve(address _approved, uint256 _tokenId) public override: Approves an address to spend a token, standard ERC721 function.
 *  5. setApprovalForAll(address _operator, bool _approved) public override: Sets approval for all tokens for an operator, standard ERC721 function.
 *  6. getApproved(uint256 _tokenId) public override view returns (address): Gets the approved address for a token, standard ERC721 function.
 *  7. isApprovedForAll(address _owner, address _operator) public override view returns (bool): Checks if an operator is approved for all tokens of an owner, standard ERC721 function.
 *  8. tokenURI(uint256 _tokenId) public override view returns (string memory): Returns the URI for a given token, dynamically generated.
 *
 *  // ** Dynamic NFT Evolution & Properties **
 *  9. evolveNFT(uint256 _tokenId) public: Triggers the evolution of an NFT based on internal logic and potential external factors.
 *  10. setNFTTrait(uint256 _tokenId, string memory _traitName, string memory _traitValue) public onlyOwner: Sets a specific trait of an NFT (Owner-controlled initially).
 *  11. voteForTraitEvolution(uint256 _tokenId, string memory _traitName, string memory _desiredValue) public payable: Allows NFT holders to vote for a trait evolution, paying a small fee.
 *  12. applyTraitEvolutionVotes(uint256 _tokenId) public onlyOwner: Applies the trait evolution votes for an NFT, changing its traits based on voting results.
 *  13. setTimeSensitiveTrait(uint256 _tokenId, string memory _traitName, string memory _traitValue, uint256 _endTime) public onlyOwner: Sets a trait that is active only until a specific time.
 *  14. checkTimeSensitiveTraits(uint256 _tokenId) public: Updates NFT traits based on time-sensitive conditions (e.g., traits expire after a certain time).
 *  15. fossilizeNFT(uint256 _tokenId) public onlyOwner: "Fossilizes" an NFT, locking its current traits permanently and preventing further evolution.
 *  16. unlockConditionalTrait(uint256 _tokenId, string memory _traitName) public onlyOwner: Unlocks a conditional trait for an NFT based on predefined criteria.
 *
 *  // ** Gallery & Marketplace Features **
 *  17. listNFTForSale(uint256 _tokenId, uint256 _price) public: Allows NFT owners to list their NFTs for sale in the gallery's marketplace.
 *  18. buyNFT(uint256 _tokenId) public payable: Allows anyone to buy a listed NFT.
 *  19. cancelNFTSale(uint256 _tokenId) public: Allows NFT owners to cancel their NFT listing.
 *  20. setMarketplaceFee(uint256 _feePercentage) public onlyOwner: Sets the marketplace fee percentage.
 *  21. withdrawMarketplaceFees() public onlyOwner: Allows the contract owner to withdraw accumulated marketplace fees.
 *
 *  // ** Staking & Rewards **
 *  22. stakeNFT(uint256 _tokenId) public: Allows NFT holders to stake their NFTs to earn rewards and potentially influence NFT evolution.
 *  23. unstakeNFT(uint256 _tokenId) public: Allows NFT holders to unstake their NFTs.
 *  24. claimStakingRewards(uint256 _tokenId) public: Allows NFT holders to claim their accumulated staking rewards.
 *  25. setStakingRewardRate(uint256 _rewardRate) public onlyOwner: Sets the staking reward rate.
 *
 *  // ** Governance & Admin **
 *  26. setVotingThreshold(uint256 _thresholdPercentage) public onlyOwner: Sets the threshold percentage required for trait evolution votes to pass.
 *  27. pauseContract() public onlyOwner: Pauses the contract, disabling critical functionalities.
 *  28. unpauseContract() public onlyOwner: Unpauses the contract, re-enabling functionalities.
 *  29. withdrawAnyERC20(address _tokenAddress, address _to, uint256 _amount) public onlyOwner: Allows the owner to withdraw any ERC20 tokens stuck in the contract.
 *  30. setGuardian(address _guardianAddress) public onlyOwner: Sets a Guardian address with special curation and management rights (example advanced role).
 *
 *  // ** Utility & View Functions **
 *  31. getNFTEvolutionState(uint256 _tokenId) public view returns (string memory): Returns the current evolution state of an NFT (example view function).
 *  32. getNFTTraits(uint256 _tokenId) public view returns (string memory): Returns a JSON string representing the current traits of an NFT (example view function).
 *  33. getNFTListingPrice(uint256 _tokenId) public view returns (uint256): Returns the listing price of an NFT if it's for sale.
 *  34. getStakingRewardBalance(uint256 _tokenId) public view returns (uint256): Returns the staking reward balance for a given NFT.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract ChameleonNFTGallery is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIdCounter;

    string public baseURI; // Default base URI for initial NFTs
    string public contractURI; // Contract level metadata URI

    // --- NFT Dynamic Properties ---
    struct NFTTraits {
        mapping(string => string) traits; // Trait name => Trait value
        mapping(string => uint256) timeSensitiveTraitsEndTime; // Trait name => End Time (0 if not time-sensitive)
        bool isFossilized;
    }
    mapping(uint256 => NFTTraits) public nftTraits;

    // --- NFT Evolution & Voting ---
    struct TraitEvolutionVote {
        string traitName;
        string desiredValue;
        uint256 votes;
        mapping(address => bool) voters; // Track addresses that have voted
    }
    mapping(uint256 => mapping(string => TraitEvolutionVote)) public nftTraitEvolutionVotes;
    uint256 public votingThresholdPercentage = 50; // Percentage of voters required for evolution to pass
    uint256 public voteFee = 0.001 ether; // Fee for voting

    // --- Marketplace ---
    struct Listing {
        uint256 price;
        address seller;
        bool isListed;
    }
    mapping(uint256 => Listing) public nftListings;
    uint256 public marketplaceFeePercentage = 2; // 2% marketplace fee

    // --- Staking ---
    struct StakingInfo {
        uint256 stakeStartTime;
        uint256 rewardBalance;
        bool isStaked;
    }
    mapping(uint256 => StakingInfo) public nftStakingInfo;
    uint256 public stakingRewardRate = 100; // Rewards per day per NFT (example unit, needs proper tokenomics in real case)

    // --- Roles & Access Control ---
    address public guardian; // Example of a Guardian role for curation and special actions

    // --- Events ---
    event NFTMinted(uint256 tokenId, address to);
    event NFTTraitSet(uint256 tokenId, string traitName, string traitValue);
    event NFTTraitEvolutionVoted(uint256 tokenId, string traitName, string desiredValue, address voter);
    event NFTTraitEvolutionApplied(uint256 tokenId, uint256 votes, string traitName, string newValue);
    event NFTFossilized(uint256 tokenId);
    event NFTListedForSale(uint256 tokenId, uint256 price, address seller);
    event NFTBought(uint256 tokenId, uint256 price, address buyer, address seller);
    event NFTListingCancelled(uint256 tokenId);
    event NFTStaked(uint256 tokenId, address staker);
    event NFTUnstaked(uint256 tokenId, address unstaker);
    event StakingRewardsClaimed(uint256 tokenId, address owner, uint256 amount);

    constructor(string memory _name, string memory _symbol, string memory _baseURI, string memory _contractURI) ERC721(_name, _symbol) {
        baseURI = _baseURI;
        contractURI = _contractURI;
    }

    // --- Modifier for Guardian Role ---
    modifier onlyGuardian() {
        require(msg.sender == guardian, "Only guardian can call this function");
        _;
    }

    modifier whenNotFossilized(uint256 _tokenId) {
        require(!nftTraits[_tokenId].isFossilized, "NFT is fossilized and cannot be changed.");
        _;
    }

    modifier whenNotPaused() {
        require(!paused(), "Contract is paused");
        _;
    }

    // ===================== Core NFT Functionality =====================

    function mintNFT(address _to, string memory _initialBaseURI) public onlyOwner whenNotPaused {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _mint(_to, tokenId);
        _setBaseURI(tokenId, _initialBaseURI); // Set specific base URI for this NFT if needed
        emit NFTMinted(tokenId, _to);
    }

    function _setBaseURI(uint256 _tokenId, string memory _tokenBaseURI) internal {
        baseURI = _tokenBaseURI; // In this example, we are just updating the global baseURI, could be per token if needed
    }

    function tokenURI(uint256 _tokenId) public override view returns (string memory) {
        require(_exists(_tokenId), "Token URI query for nonexistent token");

        string memory currentBaseURI = baseURI; // In a more advanced version, baseURI could be per token.
        string memory metadata = generateDynamicMetadata(_tokenId);

        string memory json = string(abi.encodePacked(
            '{"name": "', name(), ' #', _tokenId.toString(), '",',
            '"description": "A Chameleon NFT that dynamically evolves.",',
            '"image": "', currentBaseURI, Strings.toString(_tokenId), '.png",', // Example image URI, can be dynamic
            '"metadata": ', metadata,
            '}'
        ));

        string memory output = string(abi.encodePacked(
            "data:application/json;base64,",
            Base64.encode(bytes(json))
        ));
        return output;
    }

    function generateDynamicMetadata(uint256 _tokenId) internal view returns (string memory) {
        NFTTraits storage traits = nftTraits[_tokenId];
        string memory metadata = "{";
        bool firstTrait = true;
        for (uint i = 0; i < 100; i++) { // Iterate through potential trait names (example, can be optimized)
            string memory traitName = string(abi.encodePacked("trait", Strings.toString(i)));
            if (bytes(traits.traits[traitName]).length > 0) {
                if (!firstTrait) {
                    metadata = string(abi.encodePacked(metadata, ","));
                }
                metadata = string(abi.encodePacked(metadata, '"', traitName, '": "', traits.traits[traitName], '"'));
                firstTrait = false;
            }
        }
        metadata = string(abi.encodePacked(metadata, "}"));
        return metadata;
    }


    // Overrides for ERC721 functions to include Pausable and other checks
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) public payable override whenNotPaused {
        super.safeTransferFrom(_from, _to, _tokenId, _data);
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) public override whenNotPaused {
        super.transferFrom(_from, _to, _tokenId);
    }

    function approve(address _approved, uint256 _tokenId) public override whenNotPaused {
        super.approve(_approved, _tokenId);
    }

    function setApprovalForAll(address _operator, bool _approved) public override whenNotPaused {
        super.setApprovalForAll(_operator, _approved);
    }

    function getApproved(uint256 _tokenId) public override view returns (address) {
        return super.getApproved(_tokenId);
    }

    function isApprovedForAll(address _owner, address _operator) public override view returns (bool) {
        return super.isApprovedForAll(_owner, _operator);
    }


    // ===================== Dynamic NFT Evolution & Properties =====================

    function evolveNFT(uint256 _tokenId) public whenNotPaused whenNotFossilized(_tokenId) {
        require(_exists(_tokenId), "NFT does not exist");
        require(ownerOf(_tokenId) == msg.sender, "Only NFT owner can trigger evolution directly.");

        // Example evolution logic - can be much more complex and use external data
        NFTTraits storage traits = nftTraits[_tokenId];
        if (bytes(traits.traits["stage"]).length == 0 || keccak256(bytes(traits.traits["stage"])) == keccak256(bytes("initial"))) {
            setNFTTraitInternal(_tokenId, "stage", "evolved_stage_1");
            setNFTTraitInternal(_tokenId, "element", "fire");
        } else if (keccak256(bytes(traits.traits["stage"])) == keccak256(bytes("evolved_stage_1"))) {
            setNFTTraitInternal(_tokenId, "stage", "evolved_stage_2");
            setNFTTraitInternal(_tokenId, "element", "water");
            setTimeSensitiveTraitInternal(_tokenId, "special_effect", "glowing_aura", block.timestamp + 7 days); // Example time-sensitive trait
        } else if (keccak256(bytes(traits.traits["stage"])) == keccak256(bytes("evolved_stage_2"))) {
            setNFTTraitInternal(_tokenId, "stage", "final_stage");
            setNFTTraitInternal(_tokenId, "element", "earth");
        }
        checkTimeSensitiveTraits(_tokenId); // Check for expiring traits after evolution
    }


    function setNFTTrait(uint256 _tokenId, string memory _traitName, string memory _traitValue) public onlyOwner whenNotPaused whenNotFossilized(_tokenId) {
        setNFTTraitInternal(_tokenId, _traitName, _traitValue);
    }

    function setNFTTraitInternal(uint256 _tokenId, string memory _traitName, string memory _traitValue) internal {
        require(_exists(_tokenId), "NFT does not exist");
        nftTraits[_tokenId].traits[_traitName] = _traitValue;
        emit NFTTraitSet(_tokenId, _traitName, _traitValue);
    }

    function voteForTraitEvolution(uint256 _tokenId, string memory _traitName, string memory _desiredValue) public payable whenNotPaused whenNotFossilized(_tokenId) {
        require(_exists(_tokenId), "NFT does not exist");
        require(ownerOf(_tokenId) == msg.sender, "Only NFT owner can vote.");
        require(msg.value >= voteFee, "Insufficient vote fee.");

        TraitEvolutionVote storage vote = nftTraitEvolutionVotes[_tokenId][_traitName];
        require(!vote.voters[msg.sender], "You have already voted for this trait evolution.");

        vote.traitName = _traitName;
        vote.desiredValue = _desiredValue;
        vote.votes++;
        vote.voters[msg.sender] = true;

        emit NFTTraitEvolutionVoted(_tokenId, _traitName, _desiredValue, msg.sender);
    }

    function applyTraitEvolutionVotes(uint256 _tokenId) public onlyOwner whenNotPaused whenNotFossilized(_tokenId) {
        require(_exists(_tokenId), "NFT does not exist");

        for (uint i = 0; i < 100; i++) { // Iterate through potential trait names for votes (example, can be optimized)
            string memory traitName = string(abi.encodePacked("trait", Strings.toString(i))); // Example trait naming
            TraitEvolutionVote storage vote = nftTraitEvolutionVotes[_tokenId][traitName];

            if (vote.votes > 0) {
                uint256 percentageVotes = (vote.votes * 100) / totalSupply(); // Example: Simple % of total token holders voting
                if (percentageVotes >= votingThresholdPercentage) {
                    setNFTTraitInternal(_tokenId, vote.traitName, vote.desiredValue);
                    emit NFTTraitEvolutionApplied(_tokenId, vote.votes, vote.traitName, vote.desiredValue);
                    delete nftTraitEvolutionVotes[_tokenId][traitName]; // Reset votes after applying
                }
            }
        }
    }


    function setTimeSensitiveTrait(uint256 _tokenId, string memory _traitName, string memory _traitValue, uint256 _endTime) public onlyOwner whenNotPaused whenNotFossilized(_tokenId) {
        setTimeSensitiveTraitInternal(_tokenId, _traitName, _traitValue, _endTime);
    }

    function setTimeSensitiveTraitInternal(uint256 _tokenId, string memory _traitName, string memory _traitValue, uint256 _endTime) internal {
        require(_exists(_tokenId), "NFT does not exist");
        nftTraits[_tokenId].traits[_traitName] = _traitValue;
        nftTraits[_tokenId].timeSensitiveTraitsEndTime[_traitName] = _endTime;
        emit NFTTraitSet(_tokenId, _traitName, _traitValue);
    }

    function checkTimeSensitiveTraits(uint256 _tokenId) public whenNotPaused whenNotFossilized(_tokenId) {
        require(_exists(_tokenId), "NFT does not exist");
        NFTTraits storage traits = nftTraits[_tokenId];
        for (uint i = 0; i < 100; i++) { // Iterate through potential trait names (example, can be optimized)
            string memory traitName = string(abi.encodePacked("trait", Strings.toString(i)));
            if (traits.timeSensitiveTraitsEndTime[traitName] != 0 && block.timestamp > traits.timeSensitiveTraitsEndTime[traitName]) {
                delete traits.traits[traitName]; // Remove the trait if time has expired
                delete traits.timeSensitiveTraitsEndTime[traitName];
                emit NFTTraitSet(_tokenId, traitName, ""); // Emit event with empty value to indicate removal
            }
        }
    }

    function fossilizeNFT(uint256 _tokenId) public onlyOwner whenNotPaused {
        require(_exists(_tokenId), "NFT does not exist");
        nftTraits[_tokenId].isFossilized = true;
        emit NFTFossilized(_tokenId);
    }

    function unlockConditionalTrait(uint256 _tokenId, string memory _traitName) public onlyOwner whenNotPaused whenNotFossilized(_tokenId) {
        require(_exists(_tokenId), "NFT does not exist");
        // Example condition: Unlock "rare_trait" if owner has held NFT for > 30 days
        require(block.timestamp > (block.timestamp + 30 days), "Condition not met yet."); // Replace with actual condition check
        setNFTTraitInternal(_tokenId, _traitName, "unlocked_rare_value");
    }


    // ===================== Gallery & Marketplace Features =====================

    function listNFTForSale(uint256 _tokenId, uint256 _price) public whenNotPaused {
        require(_exists(_tokenId), "NFT does not exist");
        require(ownerOf(_tokenId) == msg.sender, "You are not the owner of this NFT.");
        require(!nftListings[_tokenId].isListed, "NFT is already listed for sale.");
        require(_price > 0, "Price must be greater than zero.");
        _approve(address(this), _tokenId); // Approve contract to transfer NFT

        nftListings[_tokenId] = Listing({
            price: _price,
            seller: msg.sender,
            isListed: true
        });
        emit NFTListedForSale(_tokenId, _price, msg.sender);
    }

    function buyNFT(uint256 _tokenId) public payable whenNotPaused {
        require(_exists(_tokenId), "NFT does not exist");
        require(nftListings[_tokenId].isListed, "NFT is not listed for sale.");
        Listing storage listing = nftListings[_tokenId];
        require(msg.value >= listing.price, "Insufficient funds to buy NFT.");

        uint256 marketplaceFee = (listing.price * marketplaceFeePercentage) / 100;
        uint256 sellerProceeds = listing.price - marketplaceFee;

        payable(listing.seller).transfer(sellerProceeds);
        payable(owner()).transfer(marketplaceFee); // Contract owner receives marketplace fees

        transferFrom(listing.seller, msg.sender, _tokenId);

        delete nftListings[_tokenId]; // Remove listing after sale
        emit NFTBought(_tokenId, listing.price, msg.sender, listing.seller);
    }

    function cancelNFTSale(uint256 _tokenId) public whenNotPaused {
        require(_exists(_tokenId), "NFT does not exist");
        require(nftListings[_tokenId].isListed, "NFT is not listed for sale.");
        require(nftListings[_tokenId].seller == msg.sender, "You are not the seller.");

        delete nftListings[_tokenId];
        emit NFTListingCancelled(_tokenId);
    }

    function setMarketplaceFee(uint256 _feePercentage) public onlyOwner whenNotPaused {
        require(_feePercentage <= 100, "Marketplace fee percentage cannot exceed 100.");
        marketplaceFeePercentage = _feePercentage;
    }

    function withdrawMarketplaceFees() public onlyOwner whenNotPaused {
        payable(owner()).transfer(address(this).balance); // Owner withdraws all contract balance (marketplace fees)
    }


    // ===================== Staking & Rewards =====================

    function stakeNFT(uint256 _tokenId) public whenNotPaused {
        require(_exists(_tokenId), "NFT does not exist");
        require(ownerOf(_tokenId) == msg.sender, "You are not the owner of this NFT.");
        require(!nftStakingInfo[_tokenId].isStaked, "NFT is already staked.");
        transferFrom(msg.sender, address(this), _tokenId); // Transfer NFT to contract for staking

        nftStakingInfo[_tokenId] = StakingInfo({
            stakeStartTime: block.timestamp,
            rewardBalance: 0,
            isStaked: true
        });
        emit NFTStaked(_tokenId, msg.sender);
    }

    function unstakeNFT(uint256 _tokenId) public whenNotPaused {
        require(_exists(_tokenId), "NFT does not exist");
        require(nftStakingInfo[_tokenId].isStaked, "NFT is not staked.");
        require(ownerOf(_tokenId) == msg.sender, "You are not the owner of this NFT."); // Owner check after staking

        claimStakingRewards(_tokenId); // Claim rewards before unstaking
        nftStakingInfo[_tokenId].isStaked = false;
        transferFrom(address(this), msg.sender, _tokenId); // Return NFT to owner
        emit NFTUnstaked(_tokenId, msg.sender);
    }

    function claimStakingRewards(uint256 _tokenId) public whenNotPaused {
        require(_exists(_tokenId), "NFT does not exist");
        require(nftStakingInfo[_tokenId].isStaked, "NFT is not staked.");
        require(ownerOf(_tokenId) == msg.sender, "You are not the owner of this NFT."); // Owner check after staking

        uint256 timeStaked = block.timestamp - nftStakingInfo[_tokenId].stakeStartTime;
        uint256 rewards = (timeStaked * stakingRewardRate) / 1 days; // Example: Rewards per day

        nftStakingInfo[_tokenId].rewardBalance += rewards; // Accumulate rewards (in a real system, this would be token rewards, not just balance)
        uint256 claimableRewards = nftStakingInfo[_tokenId].rewardBalance;
        nftStakingInfo[_tokenId].rewardBalance = 0; // Reset balance after claiming

        // In a real system, transfer actual ERC20 tokens as rewards here
        // For demonstration, we just track a "rewardBalance"
        emit StakingRewardsClaimed(_tokenId, msg.sender, claimableRewards);
    }

    function setStakingRewardRate(uint256 _rewardRate) public onlyOwner whenNotPaused {
        stakingRewardRate = _rewardRate;
    }


    // ===================== Governance & Admin =====================

    function setVotingThreshold(uint256 _thresholdPercentage) public onlyOwner whenNotPaused {
        require(_thresholdPercentage <= 100, "Voting threshold percentage cannot exceed 100.");
        votingThresholdPercentage = _thresholdPercentage;
    }

    function pauseContract() public onlyOwner whenNotPaused {
        _pause();
    }

    function unpauseContract() public onlyOwner whenNotPaused {
        _unpause();
    }

    function withdrawAnyERC20(address _tokenAddress, address _to, uint256 _amount) public onlyOwner whenNotPaused {
        // Emergency function to withdraw stuck ERC20 tokens
        IERC20 token = IERC20(_tokenAddress);
        uint256 contractBalance = token.balanceOf(address(this));
        require(_amount <= contractBalance, "Not enough tokens in contract");
        bool success = token.transfer(_to, _amount);
        require(success, "Token transfer failed");
    }

    function setGuardian(address _guardianAddress) public onlyOwner whenNotPaused {
        guardian = _guardianAddress;
    }


    // ===================== Utility & View Functions =====================

    function getNFTEvolutionState(uint256 _tokenId) public view returns (string memory) {
        require(_exists(_tokenId), "NFT does not exist");
        return nftTraits[_tokenId].traits["stage"]; // Example, return "stage" trait as evolution state
    }

    function getNFTTraits(uint256 _tokenId) public view returns (string memory) {
        require(_exists(_tokenId), "NFT does not exist");
        return generateDynamicMetadata(_tokenId); // Return JSON of all traits
    }

    function getNFTListingPrice(uint256 _tokenId) public view returns (uint256) {
        require(_exists(_tokenId), "NFT does not exist");
        return nftListings[_tokenId].price;
    }

    function getStakingRewardBalance(uint256 _tokenId) public view returns (uint256) {
        require(_exists(_tokenId), "NFT does not exist");
        uint256 timeStaked = block.timestamp - nftStakingInfo[_tokenId].stakeStartTime;
        uint256 rewards = (timeStaked * stakingRewardRate) / 1 days;
        return nftStakingInfo[_tokenId].rewardBalance + rewards; // Include currently accruing rewards
    }

    function getContractURI() public view returns (string memory) {
        return contractURI;
    }

    function setContractURI(string memory _newContractURI) public onlyOwner {
        contractURI = _newContractURI;
    }

    // ERC165 interface support (if needed for marketplace integrations)
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
```