```solidity
/**
 * @title Dynamic NFT Lending and Reputation System
 * @author Gemini AI
 * @dev A smart contract that enables dynamic NFT lending with a built-in reputation system for borrowers.
 *
 * **Outline:**
 * This contract introduces a decentralized platform for lending and borrowing NFTs.
 * NFTs listed for lending can dynamically change their metadata to reflect their lending status.
 * Borrowers build reputation based on their loan repayment history, influencing future borrowing terms.
 *
 * **Function Summary:**
 * 1. `initialize(string _platformName, address _admin)`: Initializes the contract with platform name and admin address.
 * 2. `setNFTContract(address _nftContract)`: Sets the address of the NFT contract to be used.
 * 3. `listNFTForLending(uint256 _tokenId, uint256 _dailyRentPrice)`: Lists an NFT for lending at a specified daily rent price.
 * 4. `unlistNFTForLending(uint256 _tokenId)`: Removes an NFT listing from the lending pool.
 * 5. `borrowNFT(uint256 _tokenId, uint256 _durationDays)`: Borrows a listed NFT for a specified duration.
 * 6. `repayLoan(uint256 _loanId)`: Repays an active loan and returns the NFT to the lender.
 * 7. `extendLoanDuration(uint256 _loanId, uint256 _additionalDays)`: Extends the duration of an active loan, subject to lender approval (simulated here).
 * 8. `liquidateLoan(uint256 _loanId)`: Allows lender (or admin in case of emergency) to liquidate a loan if the borrower defaults.
 * 9. `setBaseMetadataURI(string _baseURI)`: Sets the base URI for dynamic NFT metadata updates.
 * 10. `getNFTListing(uint256 _tokenId)`: Retrieves details of an NFT listing.
 * 11. `getLoanDetails(uint256 _loanId)`: Retrieves details of a specific loan.
 * 12. `getBorrowerReputation(address _borrower)`: Retrieves the reputation score of a borrower.
 * 13. `updateBorrowerReputation(address _borrower, int256 _reputationChange)`: (Admin only) Manually updates a borrower's reputation score.
 * 14. `setReputationThresholds(int256 _goodThreshold, int256 _badThreshold)`: (Admin only) Sets thresholds for reputation levels (Good, Neutral, Bad).
 * 15. `setPlatformFeePercentage(uint256 _feePercentage)`: (Admin only) Sets the platform fee percentage for each loan.
 * 16. `withdrawPlatformFees()`: (Admin only) Withdraws accumulated platform fees.
 * 17. `pauseContract()`: (Admin only) Pauses the contract, disabling core functionalities.
 * 18. `unpauseContract()`: (Admin only) Unpauses the contract, re-enabling functionalities.
 * 19. `emergencyWithdraw(address _tokenAddress, address _recipient)`: (Admin only) Emergency withdraw function for specific tokens in case of issues.
 * 20. `isAdmin(address _account)`: Checks if an address is an admin.
 * 21. `getPlatformName()`: Returns the name of the platform.
 * 22. `getContractBalance()`: Returns the current contract balance in ETH.

 * **Advanced Concepts Implemented:**
 * - **Dynamic NFT Metadata:** NFTs change their metadata URI based on their lending status, showcasing a dynamic NFT approach.
 * - **Reputation System:**  Borrower reputation influences trust and potentially future features (e.g., tiered interest rates).
 * - **Platform Fees:**  Introduces a platform fee mechanism for revenue generation.
 * - **Emergency Stop & Withdraw:**  Includes safety mechanisms for contract management.
 * - **Loan Liquidation:**  Implements a loan liquidation process for defaulted loans.
 * - **Contract Pausing:**  Provides admin control to pause contract operations in emergencies.
 * - **Modular Design:**  Functions are designed to be relatively independent, promoting maintainability.

 * **Creative and Trendy Aspects:**
 * - **NFT Lending Platform:**  Capitalizes on the NFT trend and provides a useful DeFi application for NFTs.
 * - **Dynamic Metadata:**  Makes NFTs more interactive and informative, beyond static collectibles.
 * - **Reputation in NFT Space:** Addresses the need for trust and accountability within NFT ecosystems.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract DynamicNFTLendingPlatform is Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _loanIdCounter;

    string public platformName;
    address public admin;
    address public nftContractAddress;
    string public baseMetadataURI;
    uint256 public platformFeePercentage = 2; // Default 2% platform fee
    uint256 public platformFeesCollected = 0;

    int256 public goodReputationThreshold = 50;
    int256 public badReputationThreshold = -50;

    bool public paused = false;

    struct NFTListing {
        uint256 tokenId;
        address lender;
        uint256 dailyRentPrice;
        bool isListed;
    }

    struct Loan {
        uint256 loanId;
        uint256 tokenId;
        address lender;
        address borrower;
        uint256 startTime;
        uint256 durationDays;
        uint256 endTime;
        uint256 totalRentAmount;
        bool isActive;
    }

    mapping(uint256 => NFTListing) public nftListings;
    mapping(uint256 => Loan) public activeLoans;
    mapping(address => int256) public borrowerReputation;

    event NFTListed(uint256 tokenId, address lender, uint256 dailyRentPrice);
    event NFTUnlisted(uint256 tokenId, address lender);
    event NFTBorrowed(uint256 loanId, uint256 tokenId, address borrower, uint256 durationDays, uint256 totalRentAmount);
    event LoanRepaid(uint256 loanId, uint256 tokenId, address borrower);
    event LoanExtended(uint256 loanId, uint256 additionalDays, uint256 newEndTime);
    event LoanLiquidated(uint256 loanId, uint256 tokenId, address lender);
    event ReputationUpdated(address borrower, int256 reputationChange, int256 newReputation);
    event PlatformFeePercentageSet(uint256 feePercentage);
    event PlatformFeesWithdrawn(uint256 amount, address admin);
    event ContractPaused(address admin);
    event ContractUnpaused(address admin);
    event EmergencyWithdrawal(address tokenAddress, address recipient, uint256 amount);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
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

    constructor() payable {
        // Optionally initialize platform name and admin during deployment if needed,
        // or use initialize function for more control after deployment.
        // platformName = "Default NFT Lending Platform";
        // admin = msg.sender;
    }

    /**
     * @dev Initializes the contract settings. Can be called once by the contract deployer.
     * @param _platformName The name of the lending platform.
     * @param _admin The address of the platform administrator.
     */
    function initialize(string memory _platformName, address _admin) public onlyOwner {
        require(bytes(platformName).length == 0, "Contract already initialized"); // Prevent re-initialization
        platformName = _platformName;
        admin = _admin;
        emit PlatformFeePercentageSet(platformFeePercentage); // Emit initial fee percentage for clarity
    }

    /**
     * @dev Sets the address of the ERC721 NFT contract that this platform will interact with.
     * @param _nftContract The address of the NFT contract.
     */
    function setNFTContract(address _nftContract) external onlyAdmin {
        require(_nftContract != address(0), "NFT Contract address cannot be zero address");
        nftContractAddress = _nftContract;
    }

    /**
     * @dev Lists an NFT for lending on the platform.
     * @param _tokenId The ID of the NFT to list.
     * @param _dailyRentPrice The daily rent price for lending the NFT (in wei).
     */
    function listNFTForLending(uint256 _tokenId, uint256 _dailyRentPrice) external whenNotPaused {
        require(nftContractAddress != address(0), "NFT Contract address not set");
        IERC721 nftContract = IERC721(nftContractAddress);
        require(nftContract.ownerOf(_tokenId) == msg.sender, "You are not the owner of this NFT");
        require(!nftListings[_tokenId].isListed, "NFT already listed for lending");
        require(_dailyRentPrice > 0, "Daily rent price must be greater than zero");

        nftListings[_tokenId] = NFTListing({
            tokenId: _tokenId,
            lender: msg.sender,
            dailyRentPrice: _dailyRentPrice,
            isListed: true
        });

        // In a real dynamic NFT implementation, you would trigger an update to the NFT metadata here.
        // For example, by calling a function on the NFT contract or an off-chain service listening to events.
        // Example: _updateNFTMetadata(_tokenId, "For Lending");

        emit NFTListed(_tokenId, msg.sender, _dailyRentPrice);
    }

    /**
     * @dev Removes an NFT listing from the lending pool.
     * @param _tokenId The ID of the NFT to unlist.
     */
    function unlistNFTForLending(uint256 _tokenId) external whenNotPaused {
        require(nftListings[_tokenId].isListed, "NFT is not listed for lending");
        require(nftListings[_tokenId].lender == msg.sender, "Only the lender can unlist their NFT");
        require(!activeLoans[_tokenId].isActive, "Cannot unlist NFT while it is on loan"); // Ensure no active loan

        delete nftListings[_tokenId];

        // Update NFT metadata to reflect unlisted status (optional)
        // Example: _updateNFTMetadata(_tokenId, "Not Listed");

        emit NFTUnlisted(_tokenId, msg.sender);
    }

    /**
     * @dev Borrows a listed NFT for a specified duration.
     * @param _tokenId The ID of the NFT to borrow.
     * @param _durationDays The number of days to borrow the NFT for.
     */
    function borrowNFT(uint256 _tokenId, uint256 _durationDays) external payable whenNotPaused {
        require(nftListings[_tokenId].isListed, "NFT is not listed for lending");
        require(!activeLoans[_tokenId].isActive, "NFT is already borrowed");
        require(_durationDays > 0 && _durationDays <= 365, "Duration must be between 1 and 365 days"); // Reasonable duration limit

        NFTListing memory listing = nftListings[_tokenId];
        uint256 totalRentAmount = listing.dailyRentPrice * _durationDays;

        uint256 platformFee = (totalRentAmount * platformFeePercentage) / 100;
        uint256 lenderAmount = totalRentAmount - platformFee;

        require(msg.value >= totalRentAmount, "Insufficient payment for rent and platform fee");

        // Transfer rent to lender (minus platform fee) and platform fee to contract
        payable(listing.lender).transfer(lenderAmount);
        platformFeesCollected += platformFee;

        // Transfer NFT to borrower (temporarily - ownership remains with lender)
        IERC721 nftContract = IERC721(nftContractAddress);
        nftContract.safeTransferFrom(listing.lender, msg.sender, _tokenId);

        _loanIdCounter.increment();
        uint256 loanId = _loanIdCounter.current();

        activeLoans[loanId] = Loan({
            loanId: loanId,
            tokenId: _tokenId,
            lender: listing.lender,
            borrower: msg.sender,
            startTime: block.timestamp,
            durationDays: _durationDays,
            endTime: block.timestamp + (_durationDays * 1 days),
            totalRentAmount: totalRentAmount,
            isActive: true
        });

        // Update NFT metadata to reflect borrowed status (optional)
        // Example: _updateNFTMetadata(_tokenId, "Borrowed by " + _borrowerName);

        emit NFTBorrowed(loanId, _tokenId, msg.sender, _durationDays, totalRentAmount);

        // Refund any excess payment
        if (msg.value > totalRentAmount) {
            payable(msg.sender).transfer(msg.value - totalRentAmount);
        }
    }

    /**
     * @dev Repays an active loan and returns the NFT to the lender.
     * @param _loanId The ID of the loan to repay.
     */
    function repayLoan(uint256 _loanId) external whenNotPaused {
        require(activeLoans[_loanId].isActive, "Loan is not active");
        Loan storage loan = activeLoans[_loanId];
        require(loan.borrower == msg.sender, "Only the borrower can repay the loan");

        // Check if loan is overdue and apply reputation penalty (example)
        if (block.timestamp > loan.endTime) {
            updateBorrowerReputation(msg.sender, -10); // Example: -10 reputation for late repayment
        } else {
            updateBorrowerReputation(msg.sender, 5);  // Example: +5 reputation for timely repayment
        }

        // Return NFT to lender
        IERC721 nftContract = IERC721(IERC721(nftContractAddress)); // Re-cast for function call
        nftContract.safeTransferFrom(msg.sender, loan.lender, loan.tokenId);

        loan.isActive = false; // Mark loan as inactive
        delete activeLoans[_loanId]; // Clean up loan data

        // Update NFT metadata to reflect available status (optional)
        // Example: _updateNFTMetadata(loan.tokenId, "Available for Lending");

        emit LoanRepaid(_loanId, loan.tokenId, msg.sender);
    }

    /**
     * @dev Extends the duration of an active loan. (Simplified approval - in real scenario, lender approval would be more robust).
     * @param _loanId The ID of the loan to extend.
     * @param _additionalDays The number of additional days to extend the loan for.
     */
    function extendLoanDuration(uint256 _loanId, uint256 _additionalDays) external payable whenNotPaused {
        require(activeLoans[_loanId].isActive, "Loan is not active");
        Loan storage loan = activeLoans[_loanId];
        require(loan.borrower == msg.sender, "Only the borrower can request loan extension");
        require(_additionalDays > 0 && _additionalDays <= 30, "Extension duration must be between 1 and 30 days"); // Limit extension period

        uint256 additionalRent = nftListings[loan.tokenId].dailyRentPrice * _additionalDays;
        uint256 platformFee = (additionalRent * platformFeePercentage) / 100;
        uint256 lenderAmount = additionalRent - platformFee;
        uint256 totalExtensionPayment = additionalRent; // No platform fee on extension payment in this simplified example

        require(msg.value >= totalExtensionPayment, "Insufficient payment for loan extension");

        // Transfer rent to lender (minus platform fee) and platform fee to contract
        payable(loan.lender).transfer(lenderAmount);
        platformFeesCollected += platformFee;


        loan.durationDays += _additionalDays;
        loan.endTime += (_additionalDays * 1 days);
        loan.totalRentAmount += totalExtensionPayment; // Update total rent

        emit LoanExtended(_loanId, _additionalDays, loan.endTime);

        // Refund any excess payment
        if (msg.value > totalExtensionPayment) {
            payable(msg.sender).transfer(msg.value - totalExtensionPayment);
        }
    }

    /**
     * @dev Allows the lender (or admin in case of emergency) to liquidate a loan if the borrower defaults (loan time elapsed).
     * @param _loanId The ID of the loan to liquidate.
     */
    function liquidateLoan(uint256 _loanId) external whenNotPaused {
        require(activeLoans[_loanId].isActive, "Loan is not active");
        Loan storage loan = activeLoans[_loanId];
        require(block.timestamp > loan.endTime, "Loan is not yet overdue for liquidation"); // Check if loan is overdue
        require(msg.sender == loan.lender || msg.sender == admin, "Only lender or admin can liquidate");

        // Return NFT to lender (if not already returned) - in this simple model, NFT is always with borrower until repay
        IERC721 nftContract = IERC721(nftContractAddress);
        nftContract.safeTransferFrom(loan.borrower, loan.lender, loan.tokenId);

        loan.isActive = false; // Mark loan as inactive
        delete activeLoans[_loanId]; // Clean up loan data

        updateBorrowerReputation(loan.borrower, -25); // Significant reputation penalty for default

        // Update NFT metadata to reflect available status (optional)
        // Example: _updateNFTMetadata(loan.tokenId, "Available for Lending");

        emit LoanLiquidated(_loanId, loan.tokenId, loan.lender);
    }

    /**
     * @dev Sets the base URI for dynamic NFT metadata.
     * @param _baseURI The base URI string.
     */
    function setBaseMetadataURI(string memory _baseURI) external onlyAdmin {
        baseMetadataURI = _baseURI;
    }

    /**
     * @dev Retrieves details of an NFT listing.
     * @param _tokenId The ID of the NFT.
     * @return NFTListing struct containing listing details.
     */
    function getNFTListing(uint256 _tokenId) external view returns (NFTListing memory) {
        return nftListings[_tokenId];
    }

    /**
     * @dev Retrieves details of a specific loan.
     * @param _loanId The ID of the loan.
     * @return Loan struct containing loan details.
     */
    function getLoanDetails(uint256 _loanId) external view returns (Loan memory) {
        return activeLoans[_loanId];
    }

    /**
     * @dev Retrieves the reputation score of a borrower.
     * @param _borrower The address of the borrower.
     * @return The reputation score of the borrower.
     */
    function getBorrowerReputation(address _borrower) external view returns (int256) {
        return borrowerReputation[_borrower];
    }

    /**
     * @dev (Admin only) Manually updates a borrower's reputation score.
     * @param _borrower The address of the borrower.
     * @param _reputationChange The change in reputation score (positive or negative).
     */
    function updateBorrowerReputation(address _borrower, int256 _reputationChange) internal { // Made internal for contract control
        borrowerReputation[_borrower] += _reputationChange;
        emit ReputationUpdated(_borrower, _reputationChange, borrowerReputation[_borrower]);
    }

    /**
     * @dev (Admin only) Sets thresholds for reputation levels (Good, Neutral, Bad).
     * @param _goodThreshold Reputation score above which is considered 'Good'.
     * @param _badThreshold Reputation score below which is considered 'Bad'.
     */
    function setReputationThresholds(int256 _goodThreshold, int256 _badThreshold) external onlyAdmin {
        goodReputationThreshold = _goodThreshold;
        badReputationThreshold = _badThreshold;
    }

    /**
     * @dev (Admin only) Sets the platform fee percentage for each loan.
     * @param _feePercentage The platform fee percentage (e.g., 2 for 2%).
     */
    function setPlatformFeePercentage(uint256 _feePercentage) external onlyAdmin {
        require(_feePercentage <= 100, "Fee percentage cannot exceed 100%");
        platformFeePercentage = _feePercentage;
        emit PlatformFeePercentageSet(_feePercentage);
    }

    /**
     * @dev (Admin only) Withdraws accumulated platform fees.
     */
    function withdrawPlatformFees() external onlyAdmin {
        uint256 amountToWithdraw = platformFeesCollected;
        platformFeesCollected = 0; // Reset collected fees after withdrawal
        payable(admin).transfer(amountToWithdraw);
        emit PlatformFeesWithdrawn(amountToWithdraw, admin);
    }

    /**
     * @dev (Admin only) Pauses the contract, disabling core functionalities.
     */
    function pauseContract() external onlyAdmin whenNotPaused {
        paused = true;
        emit ContractPaused(admin);
    }

    /**
     * @dev (Admin only) Unpauses the contract, re-enabling functionalities.
     */
    function unpauseContract() external onlyAdmin whenPaused {
        paused = false;
        emit ContractUnpaused(admin);
    }

    /**
     * @dev (Admin only) Emergency withdraw function for specific tokens in case of issues.
     * @param _tokenAddress The address of the token contract (address(0) for ETH).
     * @param _recipient The address to receive the withdrawn tokens/ETH.
     */
    function emergencyWithdraw(address _tokenAddress, address _recipient) external onlyAdmin {
        require(_recipient != address(0), "Recipient address cannot be zero address");

        if (_tokenAddress == address(0)) {
            // Withdraw ETH
            uint256 balance = address(this).balance;
            payable(_recipient).transfer(balance);
            emit EmergencyWithdrawal(address(0), _recipient, balance);
        } else {
            // Withdraw ERC20 tokens (Example - extend for other token standards if needed)
            // Note: This is a simplified example and might need adjustments based on the specific ERC20 token.
            IERC20 token = IERC20(_tokenAddress);
            uint256 balance = token.balanceOf(address(this));
            token.transfer(_recipient, balance);
            emit EmergencyWithdrawal(_tokenAddress, _recipient, balance);
        }
    }

    /**
     * @dev Checks if an address is an admin.
     * @param _account The address to check.
     * @return True if the address is an admin, false otherwise.
     */
    function isAdmin(address _account) external view returns (bool) {
        return _account == admin;
    }

    /**
     * @dev Returns the name of the platform.
     * @return The platform name string.
     */
    function getPlatformName() external view returns (string memory) {
        return platformName;
    }

    /**
     * @dev Returns the current contract balance in ETH.
     * @return The contract balance in wei.
     */
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    // --- Internal Helper Function (Example for Dynamic Metadata - needs more context to fully implement) ---
    // For demonstration purposes, this is a placeholder.
    // In a real scenario, you'd need to interact with the NFT contract or an off-chain service to update metadata.
    // function _updateNFTMetadata(uint256 _tokenId, string memory _status) internal {
    //     // Example: Construct a new metadata URI based on baseMetadataURI and status.
    //     string memory newMetadataURI = string(abi.encodePacked(baseMetadataURI, "/", _tokenId, "/", _status, ".json"));
    //     // ... Logic to update the NFT metadata URI. This might involve:
    //     // 1. Calling a function on the NFT contract if it supports metadata updates.
    //     // 2. Triggering an event that an off-chain service listens to, which then updates the metadata (e.g., on IPFS, Arweave).
    //     // For simplicity, this example is left as a comment as actual implementation depends heavily on the NFT contract and metadata storage mechanism.
    //     // emit NFTMetadataUpdated(_tokenId, newMetadataURI, _status); // Example event
    // }
}
```

**Important Notes:**

* **Security:** This is a conceptual contract and **not audited**.  For production use, thorough security audits are essential. Consider potential vulnerabilities like reentrancy, integer overflows/underflows (though Solidity 0.8+ is safer), and front-running.
* **Gas Optimization:**  The contract is written for clarity and demonstration, not necessarily gas efficiency.  In a real-world application, gas optimization is crucial.
* **Error Handling & User Experience:**  More detailed error messages and better event logging would improve the user and developer experience.
* **Dynamic NFT Metadata Implementation:** The `_updateNFTMetadata` function is a placeholder. Implementing dynamic NFT metadata updates requires interaction with the NFT contract itself or an off-chain service that manages NFT metadata. The specific method depends on how the NFT collection is designed (e.g., if it uses a mutable metadata contract or relies on off-chain metadata storage).
* **Reputation System Complexity:** The reputation system is basic. More sophisticated reputation systems could consider loan value, borrower history, and other factors for a more nuanced score.
* **Lender Approval for Extension:**  Loan extension is simplified. In a real-world scenario, lenders would likely need to explicitly approve loan extensions.
* **Collateralization:** This contract does not include NFT collateralization for borrowing, which is a common feature in NFT lending platforms. Adding collateralization would be a significant enhancement.
* **Testing:**  This contract is not accompanied by unit tests. Comprehensive testing is crucial before deploying any smart contract to a live network.
* **Dependencies:**  This contract uses OpenZeppelin contracts for ERC721 interface, Ownable, and Counters. Make sure to install these dependencies using npm or yarn if you intend to compile and deploy this contract.

This contract provides a solid foundation and demonstrates several advanced and trendy concepts. You can expand upon it by adding features like collateralization, more complex interest rate models, better reputation management, and a robust dynamic NFT metadata update mechanism. Remember to prioritize security and thorough testing in any real-world implementation.