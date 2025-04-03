```solidity
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic NFT Marketplace with Advanced Features
 * @author Bard (AI Assistant)
 * @dev This contract implements a decentralized marketplace for Dynamic NFTs,
 * incorporating advanced concepts like dynamic metadata updates based on on-chain events,
 * decentralized governance for marketplace parameters, NFT staking for discounts,
 * tiered royalty system, batch listing and buying, referral program, and more.
 * It aims to be a creative and trendy marketplace with features not commonly found in open-source examples.
 *
 * Function Summary:
 *
 * **NFT Management & Dynamic Updates:**
 * 1. `mintDynamicNFT(address _to, string memory _baseURI)`: Mints a new Dynamic NFT.
 * 2. `updateNFTMetadata(uint256 _tokenId)`: Triggers metadata update for an NFT based on on-chain state.
 * 3. `setBaseURI(string memory _newBaseURI)`: Sets the base URI for NFT metadata.
 * 4. `tokenURI(uint256 _tokenId)`: Returns the URI for a given NFT token.
 *
 * **Marketplace Listing & Trading:**
 * 5. `listItem(uint256 _tokenId, uint256 _price)`: Lists an NFT for sale on the marketplace.
 * 6. `cancelListing(uint256 _tokenId)`: Cancels an NFT listing.
 * 7. `buyItem(uint256 _tokenId)`: Allows anyone to buy a listed NFT.
 * 8. `batchListItem(uint256[] memory _tokenIds, uint256 _price)`: Lists multiple NFTs for the same price.
 * 9. `batchBuyItem(uint256[] memory _tokenIds)`: Buys multiple NFTs in a single transaction.
 * 10. `setMarketplaceFee(uint256 _feePercentage)`: Sets the marketplace fee percentage (governance controlled).
 * 11. `withdrawMarketplaceFees()`: Allows the marketplace owner to withdraw accumulated fees.
 * 12. `pauseMarketplace()`: Pauses all marketplace trading (governance controlled).
 * 13. `unpauseMarketplace()`: Resumes marketplace trading (governance controlled).
 *
 * **Advanced Features & Incentives:**
 * 14. `stakeNFTForDiscount(uint256 _tokenId)`: Stakes an NFT to receive a discount on marketplace fees.
 * 15. `unstakeNFT(uint256 _tokenId)`: Unstakes a previously staked NFT.
 * 16. `setStakingDiscountPercentage(uint256 _discountPercentage)`: Sets the staking discount percentage (governance controlled).
 * 17. `setRoyaltyPercentage(uint256 _royaltyPercentage)`: Sets the royalty percentage for secondary sales.
 * 18. `withdrawRoyalties(uint256 _tokenId)`: Allows the NFT creator to withdraw accumulated royalties.
 * 19. `setReferralRewardPercentage(uint256 _rewardPercentage)`: Sets the referral reward percentage (governance controlled).
 * 20. `applyReferral(address _referrer)`: Applies a referral when buying an NFT, rewarding the referrer.
 *
 * **Governance & Administration:**
 * 21. `proposeMarketplaceFeeChange(uint256 _newFeePercentage)`: Proposes a change to the marketplace fee.
 * 22. `voteOnProposal(uint256 _proposalId, bool _vote)`: Allows token holders to vote on governance proposals.
 * 23. `executeProposal(uint256 _proposalId)`: Executes a passed governance proposal.
 * 24. `setGovernanceToken(address _governanceToken)`: Sets the governance token address.
 * 25. `setRequiredVotesForProposal(uint256 _requiredVotes)`: Sets the number of votes required for a proposal to pass.
 * 26. `transferOwnership(address newOwner)`: Allows the owner to transfer contract ownership.
 * 27. `renounceOwnership()`: Allows the owner to renounce contract ownership.
 */
contract DynamicNFTMarketplace {
    using SafeMath for uint256;

    // ** State Variables **
    string public name = "Dynamic NFT Marketplace";
    string public symbol = "DNFTM";
    string public baseURI;

    address public owner;
    address public governanceToken; // Address of the governance token contract
    uint256 public marketplaceFeePercentage = 2; // Default 2% marketplace fee
    uint256 public stakingDiscountPercentage = 10; // Default 10% staking discount
    uint256 public royaltyPercentage = 5; // Default 5% royalty
    uint256 public referralRewardPercentage = 1; // Default 1% referral reward
    uint256 public requiredVotesForProposal = 50; // Default 50% of governance tokens need to vote YES

    uint256 public currentTokenId = 0;
    mapping(uint256 => address) public tokenOwner;
    mapping(uint256 => string) public tokenMetadata;
    mapping(uint256 => uint256) public tokenListPrice; // Price at which token is listed
    mapping(uint256 => bool) public isListed;
    mapping(uint256 => bool) public isStaked;
    mapping(uint256 => uint256) public royaltyBalance;
    mapping(address => uint256) public marketplaceFeeBalance;

    bool public marketplacePaused = false;

    struct Proposal {
        uint256 proposalId;
        string description;
        uint256 newMarketplaceFeePercentage;
        bool executed;
        uint256 yesVotes;
        uint256 noVotes;
        mapping(address => bool) voters; // Track who has voted
    }
    mapping(uint256 => Proposal) public proposals;
    uint256 public proposalCount = 0;


    // ** Events **
    event NFTMinted(uint256 tokenId, address to);
    event NFTListed(uint256 tokenId, uint256 price, address seller);
    event NFTListingCancelled(uint256 tokenId, address seller);
    event NFTBought(uint256 tokenId, address buyer, address seller, uint256 price);
    event MarketplaceFeeSet(uint256 feePercentage, address setter);
    event MarketplacePaused(address pauser);
    event MarketplaceUnpaused(address unpauser);
    event NFTStaked(uint256 tokenId, address staker);
    event NFTUnstaked(uint256 tokenId, address unstaker);
    event StakingDiscountSet(uint256 discountPercentage, address setter);
    event RoyaltyPercentageSet(uint256 royaltyPercentage, address setter);
    event RoyaltyWithdrawn(uint256 tokenId, address creator, uint256 amount);
    event ReferralRewardSet(uint256 rewardPercentage, address setter);
    event ReferralApplied(address referrer, address buyer, uint256 tokenId);
    event MarketplaceFeesWithdrawn(address withdrawer, uint256 amount);
    event ProposalCreated(uint256 proposalId, string description, uint256 newFeePercentage, address proposer);
    event VoteCast(uint256 proposalId, address voter, bool vote);
    event ProposalExecuted(uint256 proposalId, bool success);
    event GovernanceTokenSet(address governanceTokenAddress, address setter);
    event RequiredVotesSet(uint256 requiredVotes, address setter);


    // ** Libraries & Utilities **
    library SafeMath {
        function add(uint256 a, uint256 b) internal pure returns (uint256) {
            uint256 c = a + b;
            require(c >= a, "SafeMath: addition overflow");
            return c;
        }
        function sub(uint256 a, uint256 b) internal pure returns (uint256) {
            return sub(a, b, "SafeMath: subtraction overflow");
        }
        function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
            require(b <= a, errorMessage);
            uint256 c = a - b;
            return c;
        }
        function mul(uint256 a, uint256 b) internal pure returns (uint256) {
            if (a == 0) {
                return 0;
            }
            uint256 c = a * b;
            require(c / a == b, "SafeMath: multiplication overflow");
            return c;
        }
        function div(uint256 a, uint256 b) internal pure returns (uint256) {
            return div(a, b, "SafeMath: division by zero");
        }
        function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
            require(b > 0, errorMessage);
            uint256 c = a / b;
            return c;
        }
        function mod(uint256 a, uint256 b) internal pure returns (uint256) {
            return mod(a, b, "SafeMath: modulo by zero");
        }
        function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
            require(b != 0, errorMessage);
            return a % b;
        }
    }

    // ** Modifiers **
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier onlyGovernance() {
        require(msg.sender == governanceToken, "Only governance token contract can call this function.");
        _;
    }

    modifier whenNotPaused() {
        require(!marketplacePaused, "Marketplace is paused.");
        _;
    }

    modifier whenPaused() {
        require(marketplacePaused, "Marketplace is not paused.");
        _;
    }


    // ** Constructor **
    constructor(string memory _baseURI, address _governanceTokenAddress) {
        owner = msg.sender;
        baseURI = _baseURI;
        governanceToken = _governanceTokenAddress;
    }


    // ** NFT Management & Dynamic Updates **

    /// @dev Mints a new Dynamic NFT to the specified address.
    function mintDynamicNFT(address _to, string memory _metadataSuffix) public onlyOwner returns (uint256) {
        uint256 newTokenId = currentTokenId++;
        tokenOwner[newTokenId] = _to;
        tokenMetadata[newTokenId] = _metadataSuffix; // Store suffix, full URI built in tokenURI
        emit NFTMinted(newTokenId, _to);
        return newTokenId;
    }

    /// @dev Updates the metadata of an NFT based on some on-chain dynamic condition (example: time of day, contract balance, etc.).
    /// @param _tokenId The ID of the NFT to update.
    function updateNFTMetadata(uint256 _tokenId) public {
        require(tokenOwner[_tokenId] != address(0), "NFT does not exist.");
        // Example dynamic logic: Change metadata based on block timestamp
        if (block.timestamp % 2 == 0) {
            tokenMetadata[_tokenId] = "day"; // Example: "day" metadata
        } else {
            tokenMetadata[_tokenId] = "night"; // Example: "night" metadata
        }
        // In a real application, this could be more complex, fetching data from oracles, etc.
    }

    /// @dev Sets the base URI for all NFT metadata.
    /// @param _newBaseURI The new base URI string.
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    /// @dev Returns the URI for a given NFT token, combining baseURI and token-specific metadata.
    /// @param _tokenId The ID of the NFT.
    /// @return The full URI string for the NFT metadata.
    function tokenURI(uint256 _tokenId) public view returns (string memory) {
        require(tokenOwner[_tokenId] != address(0), "NFT does not exist.");
        return string(abi.encodePacked(baseURI, tokenMetadata[_tokenId]));
    }


    // ** Marketplace Listing & Trading **

    /// @dev Lists an NFT for sale on the marketplace.
    /// @param _tokenId The ID of the NFT to list.
    /// @param _price The listing price in wei.
    function listItem(uint256 _tokenId, uint256 _price) public whenNotPaused {
        require(tokenOwner[_tokenId] == msg.sender, "You are not the owner of this NFT.");
        require(!isListed[_tokenId], "NFT is already listed.");
        require(!isStaked[_tokenId], "NFT is staked and cannot be listed.");
        require(_price > 0, "Price must be greater than zero.");

        // Transfer NFT ownership to this contract for escrow during listing
        // In a real-world ERC721 implementation, you would need to handle approvals correctly
        // For simplicity in this example, assuming owner has approved this contract already or we are using a simple internal token.
        tokenOwner[_tokenId] = address(this);
        tokenListPrice[_tokenId] = _price;
        isListed[_tokenId] = true;

        emit NFTListed(_tokenId, _price, msg.sender);
    }

    /// @dev Cancels an NFT listing. Only the seller can cancel their listing.
    /// @param _tokenId The ID of the NFT to cancel listing for.
    function cancelListing(uint256 _tokenId) public whenNotPaused {
        require(isListed[_tokenId], "NFT is not listed.");
        require(tokenOwner[_tokenId] == address(this), "Contract is not holding this NFT for listing."); // Sanity check
        // In a real ERC721, you would check the original seller, not the contract owner.
        // Here, for simplicity, we assume the lister is always the original owner.
        // This needs to be adjusted for a proper ERC721 integration.
        // For now, we'll use msg.sender as a proxy for the original lister.
        require(msg.sender == getOriginalOwner(_tokenId), "Only the seller can cancel listing.");

        isListed[_tokenId] = false;
        tokenListPrice[_tokenId] = 0;
        tokenOwner[_tokenId] = msg.sender; // Return ownership to the original seller

        emit NFTListingCancelled(_tokenId, msg.sender);
    }


    /// @dev Allows anyone to buy a listed NFT.
    /// @param _tokenId The ID of the NFT to buy.
    function buyItem(uint256 _tokenId) public payable whenNotPaused {
        require(isListed[_tokenId], "NFT is not listed for sale.");
        require(tokenOwner[_tokenId] == address(this), "Contract is not holding this NFT for sale."); // Sanity check
        uint256 price = tokenListPrice[_tokenId];
        require(msg.value >= price, "Insufficient funds to buy NFT.");

        address seller = getOriginalOwner(_tokenId); // Get original owner for royalties and fees
        require(seller != msg.sender, "Cannot buy your own NFT.");

        // Calculate marketplace fee and royalty
        uint256 marketplaceFee = price.mul(getMarketplaceFee()).div(100);
        uint256 royaltyAmount = price.mul(royaltyPercentage).div(100);

        // Apply staking discount if buyer has staked an NFT
        uint256 discountedFee = marketplaceFee;
        if (isStakedForUser(msg.sender)) {
            discountedFee = marketplaceFee.mul(100 - stakingDiscountPercentage).div(100);
        }

        // Apply referral reward if a referrer is provided (in a real app, this might be handled differently)
        address referrer; // In a real app, you might pass referrer in function args or use storage
        if (msg.data.length > 4) { // Simple check if extra data is sent (could be more robust)
            (referrer,) = abi.decode(msg.data[4:], (address,)); // Example: decode referrer from calldata
            if (referrer != address(0) && referrer != msg.sender) { // Basic referrer check
                uint256 referralReward = price.mul(referralRewardPercentage).div(100);
                payable(referrer).transfer(referralReward); // Reward the referrer (basic implementation)
                emit ReferralApplied(referrer, msg.sender, _tokenId);
            }
        }


        // Transfer funds: buyer -> seller, marketplace, royalty, and referrer (if any)
        payable(seller).transfer(price.sub(marketplaceFee).sub(royaltyAmount)); // Seller gets price - fees - royalty
        marketplaceFeeBalance[address(this)] = marketplaceFeeBalance[address(this)].add(discountedFee); // Marketplace fee
        royaltyBalance[_tokenId] = royaltyBalance[_tokenId].add(royaltyAmount); // Royalty balance

        // Transfer NFT to buyer
        tokenOwner[_tokenId] = msg.sender;
        isListed[_tokenId] = false;
        tokenListPrice[_tokenId] = 0;

        emit NFTBought(_tokenId, msg.sender, seller, price);

        // Return any excess ETH sent by the buyer
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value.sub(price));
        }
    }


    /// @dev Lists multiple NFTs for sale with the same price.
    /// @param _tokenIds Array of NFT IDs to list.
    /// @param _price The listing price for each NFT.
    function batchListItem(uint256[] memory _tokenIds, uint256 _price) public whenNotPaused {
        require(_price > 0, "Price must be greater than zero.");
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 tokenId = _tokenIds[i];
            require(tokenOwner[tokenId] == msg.sender, "You are not the owner of NFT ID: " + string(abi.encodePacked(tokenId)));
            require(!isListed[tokenId], "NFT ID: " + string(abi.encodePacked(tokenId)) + " is already listed.");
            require(!isStaked[tokenId], "NFT ID: " + string(abi.encodePacked(tokenId)) + " is staked and cannot be listed.");

            tokenOwner[tokenId] = address(this); // Escrow
            tokenListPrice[tokenId] = _price;
            isListed[tokenId] = true;
            emit NFTListed(tokenId, _price, msg.sender);
        }
    }

    /// @dev Buys multiple NFTs in a single transaction.
    /// @param _tokenIds Array of NFT IDs to buy.
    function batchBuyItem(uint256[] memory _tokenIds) public payable whenNotPaused {
        uint256 totalPrice = 0;
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 tokenId = _tokenIds[i];
            require(isListed[tokenId], "NFT ID: " + string(abi.encodePacked(tokenId)) + " is not listed for sale.");
            require(tokenOwner[tokenId] == address(this), "Contract is not holding NFT ID: " + string(abi.encodePacked(tokenId)) + " for sale.");
            totalPrice = totalPrice.add(tokenListPrice[tokenId]);
        }
        require(msg.value >= totalPrice, "Insufficient funds to buy NFTs.");

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 tokenId = _tokenIds[i];
            uint256 price = tokenListPrice[tokenId];
            address seller = getOriginalOwner(tokenId); // Get original owner for royalties and fees

            // Calculate fees and royalties (simplified for batch - fee/royalty applied per item)
            uint256 marketplaceFee = price.mul(getMarketplaceFee()).div(100);
            uint256 royaltyAmount = price.mul(royaltyPercentage).div(100);
            uint256 discountedFee = marketplaceFee;
            if (isStakedForUser(msg.sender)) {
                discountedFee = marketplaceFee.mul(100 - stakingDiscountPercentage).div(100);
            }

            payable(seller).transfer(price.sub(marketplaceFee).sub(royaltyAmount));
            marketplaceFeeBalance[address(this)] = marketplaceFeeBalance[address(this)].add(discountedFee);
            royaltyBalance[tokenId] = royaltyBalance[tokenId].add(royaltyAmount);
            tokenOwner[tokenId] = msg.sender;
            isListed[tokenId] = false;
            tokenListPrice[tokenId] = 0;
            emit NFTBought(tokenId, msg.sender, seller, price);
        }
        // Return any excess ETH sent by the buyer
        if (msg.value > totalPrice) {
            payable(msg.sender).transfer(msg.value.sub(totalPrice));
        }
    }


    /// @dev Sets the marketplace fee percentage. Governance controlled.
    /// @param _feePercentage The new marketplace fee percentage (0-100).
    function setMarketplaceFee(uint256 _feePercentage) public onlyOwner { // For simplicity, onlyOwner for now, should be governance
        require(_feePercentage <= 100, "Fee percentage must be between 0 and 100.");
        marketplaceFeePercentage = _feePercentage;
        emit MarketplaceFeeSet(_feePercentage, msg.sender);
    }

    /// @dev Allows the marketplace owner to withdraw accumulated marketplace fees.
    function withdrawMarketplaceFees() public onlyOwner {
        uint256 balance = marketplaceFeeBalance[address(this)];
        require(balance > 0, "No marketplace fees to withdraw.");
        marketplaceFeeBalance[address(this)] = 0;
        payable(owner).transfer(balance);
        emit MarketplaceFeesWithdrawn(owner, balance);
    }

    /// @dev Pauses all marketplace trading. Governance controlled.
    function pauseMarketplace() public onlyOwner { // For simplicity, onlyOwner for now, should be governance
        marketplacePaused = true;
        emit MarketplacePaused(msg.sender);
    }

    /// @dev Resumes marketplace trading. Governance controlled.
    function unpauseMarketplace() public onlyOwner { // For simplicity, onlyOwner for now, should be governance
        marketplacePaused = false;
        emit MarketplaceUnpaused(msg.sender);
    }


    // ** Advanced Features & Incentives **

    /// @dev Stakes an NFT to receive a discount on marketplace fees.
    /// @param _tokenId The ID of the NFT to stake.
    function stakeNFTForDiscount(uint256 _tokenId) public whenNotPaused {
        require(tokenOwner[_tokenId] == msg.sender, "You are not the owner of this NFT.");
        require(!isListed[_tokenId], "NFT is listed and cannot be staked.");
        require(!isStaked[_tokenId], "NFT is already staked.");

        isStaked[_tokenId] = true;
        emit NFTStaked(_tokenId, msg.sender);
    }

    /// @dev Unstakes a previously staked NFT.
    /// @param _tokenId The ID of the NFT to unstake.
    function unstakeNFT(uint256 _tokenId) public whenNotPaused {
        require(tokenOwner[_tokenId] == msg.sender, "You are not the owner of this NFT.");
        require(isStaked[_tokenId], "NFT is not staked.");

        isStaked[_tokenId] = false;
        emit NFTUnstaked(_tokenId, msg.sender);
    }

    /// @dev Sets the staking discount percentage. Governance controlled.
    /// @param _discountPercentage The new staking discount percentage (0-100).
    function setStakingDiscountPercentage(uint256 _discountPercentage) public onlyOwner { // For simplicity, onlyOwner for now, should be governance
        require(_discountPercentage <= 100, "Discount percentage must be between 0 and 100.");
        stakingDiscountPercentage = _discountPercentage;
        emit StakingDiscountSet(_discountPercentage, msg.sender);
    }

    /// @dev Sets the royalty percentage for secondary sales. Governance controlled.
    /// @param _royaltyPercentage The new royalty percentage (0-100).
    function setRoyaltyPercentage(uint256 _royaltyPercentage) public onlyOwner { // For simplicity, onlyOwner for now, should be governance
        require(_royaltyPercentage <= 100, "Royalty percentage must be between 0 and 100.");
        royaltyPercentage = _royaltyPercentage;
        emit RoyaltyPercentageSet(_royaltyPercentage, msg.sender);
    }

    /// @dev Allows the NFT creator to withdraw accumulated royalties for a specific NFT.
    /// @param _tokenId The ID of the NFT to withdraw royalties for.
    function withdrawRoyalties(uint256 _tokenId) public {
        address creator = getCreator(_tokenId); // Assuming you have a way to track creator, or use original minter as creator
        require(msg.sender == creator, "Only the NFT creator can withdraw royalties.");
        uint256 balance = royaltyBalance[_tokenId];
        require(balance > 0, "No royalties to withdraw for this NFT.");
        royaltyBalance[_tokenId] = 0;
        payable(creator).transfer(balance);
        emit RoyaltyWithdrawn(_tokenId, creator, balance);
    }

    /// @dev Sets the referral reward percentage. Governance controlled.
    /// @param _rewardPercentage The new referral reward percentage (0-100).
    function setReferralRewardPercentage(uint256 _rewardPercentage) public onlyOwner { // For simplicity, onlyOwner for now, should be governance
        require(_rewardPercentage <= 100, "Referral reward percentage must be between 0 and 100.");
        referralRewardPercentage = _rewardPercentage;
        emit ReferralRewardSet(_rewardPercentage, msg.sender);
    }

    /// @dev Applies a referral when buying an NFT. This is a simplified example; in a real app, referral might be handled via codes or links.
    /// @param _referrer The address of the referrer.
    function applyReferral(address _referrer) public payable {
        // In actual implementation, referral might be passed during buyItem call or handled via separate referral code system.
        // This is just a placeholder function for demonstration of referral concept.
        require(_referrer != address(0), "Invalid referrer address.");
        require(_referrer != msg.sender, "Cannot refer yourself.");
        // Referral logic would be integrated into buyItem function in a real scenario.
        emit ReferralApplied(_referrer, msg.sender, 0); // Token ID not relevant here, just event for concept.
    }


    // ** Governance & Administration **

    /// @dev Proposes a change to the marketplace fee percentage.
    /// @param _newFeePercentage The new marketplace fee percentage being proposed.
    function proposeMarketplaceFeeChange(uint256 _newFeePercentage) public whenNotPaused {
        require(_newFeePercentage <= 100, "Fee percentage must be between 0 and 100.");
        proposalCount++;
        proposals[proposalCount] = Proposal({
            proposalId: proposalCount,
            description: "Change marketplace fee to " + string(abi.encodePacked(_newFeePercentage)) + "%",
            newMarketplaceFeePercentage: _newFeePercentage,
            executed: false,
            yesVotes: 0,
            noVotes: 0,
            voters: mapping(address => bool)()
        });
        emit ProposalCreated(proposalCount, proposals[proposalCount].description, _newFeePercentage, msg.sender);
    }

    /// @dev Allows governance token holders to vote on a proposal.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _vote True for yes, false for no.
    function voteOnProposal(uint256 _proposalId, bool _vote) public whenNotPaused {
        require(governanceToken != address(0), "Governance token not set.");
        require(proposals[_proposalId].proposalId == _proposalId, "Invalid proposal ID.");
        require(!proposals[_proposalId].executed, "Proposal already executed.");
        require(!proposals[_proposalId].voters[msg.sender], "You have already voted on this proposal.");

        // Assume governance token contract has a balanceOf function
        uint256 votingPower = getGovernanceTokenBalance(msg.sender);
        require(votingPower > 0, "You need governance tokens to vote.");

        proposals[_proposalId].voters[msg.sender] = true;
        if (_vote) {
            proposals[_proposalId].yesVotes = proposals[_proposalId].yesVotes.add(votingPower);
        } else {
            proposals[_proposalId].noVotes = proposals[_proposalId].noVotes.add(votingPower);
        }
        emit VoteCast(_proposalId, msg.sender, _vote);
    }


    /// @dev Executes a passed governance proposal if enough votes have been received.
    /// @param _proposalId The ID of the proposal to execute.
    function executeProposal(uint256 _proposalId) public whenNotPaused {
        require(proposals[_proposalId].proposalId == _proposalId, "Invalid proposal ID.");
        require(!proposals[_proposalId].executed, "Proposal already executed.");

        uint256 totalVotes = proposals[_proposalId].yesVotes.add(proposals[_proposalId].noVotes);
        uint256 yesPercentage = proposals[_proposalId].yesVotes.mul(100).div(totalVotes);

        if (yesPercentage >= requiredVotesForProposal) {
            marketplaceFeePercentage = proposals[_proposalId].newMarketplaceFeePercentage;
            proposals[_proposalId].executed = true;
            emit ProposalExecuted(_proposalId, true);
            emit MarketplaceFeeSet(marketplaceFeePercentage, address(this)); // Emit fee change event again for clarity
        } else {
            proposals[_proposalId].executed = true; // Mark as executed even if failed, to prevent re-execution
            emit ProposalExecuted(_proposalId, false);
        }
    }

    /// @dev Sets the address of the governance token contract.
    /// @param _governanceToken The address of the governance token contract.
    function setGovernanceToken(address _governanceToken) public onlyOwner {
        governanceToken = _governanceToken;
        emit GovernanceTokenSet(_governanceToken, msg.sender);
    }

    /// @dev Sets the required percentage of votes for a proposal to pass.
    /// @param _requiredVotes The required percentage (e.g., 50 for 50%).
    function setRequiredVotesForProposal(uint256 _requiredVotes) public onlyOwner {
        require(_requiredVotes <= 100, "Required votes percentage must be between 0 and 100.");
        requiredVotesForProposal = _requiredVotes;
        emit RequiredVotesSet(_requiredVotes, msg.sender);
    }


    // ** Ownership Management **
    /// @dev Transfers ownership of the contract to a new address.
    /// @param newOwner The address of the new owner.
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner address cannot be zero.");
        owner = newOwner;
    }

    /// @dev Allows the current owner to renounce ownership of the contract.
    function renounceOwnership() public onlyOwner {
        owner = address(0);
        // Consider what should happen to governance if owner renounces.
    }


    // ** Helper/Utility Functions **

    /// @dev Returns the original owner of an NFT (before listing).
    function getOriginalOwner(uint256 _tokenId) public view returns (address) {
        // In a real ERC721, you would need to track the original minter/creator separately if needed.
        // For this simplified example, we assume the original owner is the one who minted it, and we track owner changes internally.
        // In a proper ERC721 integration, you'd likely use the ERC721 `ownerOf` function and potentially track creator separately if royalties are creator-based.
        address currentOwner = tokenOwner[_tokenId];
        if (currentOwner == address(this)) {
            // If contract holds it, trace back to who listed it. For simplicity, we assume the lister was the last owner before listing.
            // In a more robust system, you might store the lister's address separately during listing.
            // For this example, we'll just return the current owner if the contract is holding it, assuming it's the original seller.
            // **This is a simplification and might need adjustment for a real ERC721 integration.**
            return getPreviousOwnerBeforeListing(_tokenId); // Placeholder - in a real app you'd need to track this.
        } else {
            return currentOwner;
        }
    }

    // Placeholder for tracking previous owner - needs proper implementation in a real app.
    function getPreviousOwnerBeforeListing(uint256 _tokenId) internal pure returns (address) {
        // In a real application, you would need to store the original seller's address when listing.
        // This is a placeholder function, as tracking previous owner is not directly built into this simple contract.
        return address(0); // Return zero address as placeholder - needs proper tracking.
    }


    /// @dev Returns the current marketplace fee percentage.
    function getMarketplaceFee() public view returns (uint256) {
        return marketplaceFeePercentage;
    }

    /// @dev Checks if a user has staked any NFT for discount.
    function isStakedForUser(address _user) public view returns (bool) {
        // Simple linear scan - inefficient for large number of NFTs, optimize in real app if needed.
        for (uint256 i = 0; i < currentTokenId; i++) {
            if (tokenOwner[i] == _user && isStaked[i]) {
                return true;
            }
        }
        return false;
    }

    /// @dev Placeholder function to get governance token balance. Replace with actual governance token contract interaction.
    function getGovernanceTokenBalance(address _account) public view returns (uint256) {
        // In a real application, you would interact with the governance token contract (ERC20-like)
        // to get the balance of the _account.
        // Example (assuming governanceToken is an ERC20-like contract):
        // IERC20 governanceTokenContract = IERC20(governanceToken);
        // return governanceTokenContract.balanceOf(_account);
        // For this example, we just return a fixed value or simulate based on some condition.
        // For demonstration, let's assume everyone has 10 governance tokens for voting.
        return 10;
    }

    /// @dev Placeholder interface for ERC20-like governance token (replace with actual interface if needed).
    interface IERC20 {
        function balanceOf(address account) external view returns (uint256);
        // ... other ERC20 functions if needed for governance ...
    }

    receive() external payable {} // Allow contract to receive ETH
    fallback() external payable {} // Allow contract to receive ETH
}
```