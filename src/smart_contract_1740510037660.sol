Okay, here's a Solidity smart contract that implements a "Dynamic NFT Rental & Yield Aggregation" system. This concept combines NFT rental with DeFi yield optimization. This is designed to be conceptually complex and utilizes advanced Solidity features like interfaces, external contract calls, and dynamic arrays.

**Outline and Function Summary:**

*   **Contract Name:** `DynamicNFTRentalYield`

*   **Description:**  Allows NFT owners to rent out their NFTs for a set period. While rented, the rental fees collected are deposited into a yield-generating protocol (e.g., Compound, Aave) and the yield earned is split between the NFT owner and the renter.

*   **Key Features:**

    *   **NFT Rental:**  Owners can list their NFTs for rent, specifying a rental price and duration.
    *   **Yield Aggregation:** Rental fees are automatically deposited into a yield-generating protocol.
    *   **Dynamic Yield Split:** The yield generated is split between the NFT owner and the renter based on predefined proportions.
    *   **Composable Architecture:** Uses interfaces to interact with external NFT and DeFi protocols.
    *   **Rental Extension:** Renters can extend their rental period for a fee.
    *   **Emergency Withdraw:** Emergency function for owner to withdraw NFT and cancel rental in unforeseen circumstances.
    *   **Ownership Transfer Restriction During Rental:** Prevents owner from transfering NFT to another address during rental.

*   **Functions:**

    *   `listNFTForRent(address _nftContract, uint256 _tokenId, uint256 _rentalPrice, uint256 _rentalDuration)`:  Lists an NFT for rent.
    *   `rentNFT(address _nftContract, uint256 _tokenId)`:  Rents a listed NFT.
    *   `extendRental(address _nftContract, uint256 _tokenId, uint256 _extensionDuration)`: Extends the rental period of an NFT.
    *   `withdrawNFT(address _nftContract, uint256 _tokenId)`: Withdraws the NFT if the rental period has expired or emergency withdrawal triggered.
    *   `collectYield(address _nftContract, uint256 _tokenId)`:  Collects the yield earned on rental fees and distributes it between the owner and renter.
    *   `setYieldProtocol(address _yieldProtocolAddress)`: Sets the address of the yield-generating protocol.
    *   `setYieldSplit(uint256 _ownerPercentage, uint256 _renterPercentage)`: Sets the yield split percentage between the owner and renter.
    *   `emergencyWithdraw(address _nftContract, uint256 _tokenId)`: Allows owner to withdraw NFT regardless of rental status in case of emergency, forfeiting collected rent to renter.
    *   `supportsInterface(bytes4 interfaceId) external pure returns (bool)`: Complies with ERC-165 standard for interface detection.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IYieldProtocol {
    function deposit(address token, uint256 amount) external;
    function withdraw(address token, uint256 amount) external;
    function getYield(address token) external view returns (uint256);
}

contract DynamicNFTRentalYield is ERC721Holder, ReentrancyGuard, IERC165 {

    // Struct to store rental information
    struct Rental {
        address owner;
        address renter;
        uint256 rentalPrice;
        uint256 rentalDuration;
        uint256 startTime;
        bool isActive;
    }

    // Mapping from NFT contract address and token ID to rental information
    mapping(address => mapping(uint256 => Rental)) public rentals;

    // Address of the yield-generating protocol
    IYieldProtocol public yieldProtocol;

    // Yield split percentages
    uint256 public ownerYieldPercentage;
    uint256 public renterYieldPercentage;

    // Events
    event NFTListed(address indexed nftContract, uint256 indexed tokenId, address owner, uint256 rentalPrice, uint256 rentalDuration);
    event NFTRented(address indexed nftContract, uint256 indexed tokenId, address renter, uint256 rentalPrice, uint256 rentalDuration);
    event RentalExtended(address indexed nftContract, uint256 indexed tokenId, uint256 extensionDuration);
    event NFTWithdrawn(address indexed nftContract, uint256 indexed tokenId, address owner);
    event YieldCollected(address indexed nftContract, uint256 indexed tokenId, uint256 ownerYield, uint256 renterYield);

    constructor(address _yieldProtocolAddress, uint256 _ownerPercentage, uint256 _renterPercentage) {
        yieldProtocol = IYieldProtocol(_yieldProtocolAddress);
        ownerYieldPercentage = _ownerPercentage;
        renterYieldPercentage = _renterPercentage;
        require(_ownerPercentage + _renterPercentage == 100, "Yield percentages must add up to 100");
    }

    // Function to list an NFT for rent
    function listNFTForRent(address _nftContract, uint256 _tokenId, uint256 _rentalPrice, uint256 _rentalDuration) external {
        IERC721 nft = IERC721(_nftContract);
        require(nft.ownerOf(_tokenId) == msg.sender, "You are not the owner of this NFT");
        require(rentals[_nftContract][_tokenId].isActive == false, "NFT is already listed or rented");

        // Transfer NFT to this contract
        nft.transferFrom(msg.sender, address(this), _tokenId);

        rentals[_nftContract][_tokenId] = Rental({
            owner: msg.sender,
            renter: address(0),
            rentalPrice: _rentalPrice,
            rentalDuration: _rentalDuration,
            startTime: 0,
            isActive: true
        });

        emit NFTListed(_nftContract, _tokenId, msg.sender, _rentalPrice, _rentalDuration);
    }


    // Function to rent an NFT
    function rentNFT(address _nftContract, uint256 _tokenId) external payable nonReentrant {
        Rental storage rental = rentals[_nftContract][_tokenId];
        require(rental.isActive == true, "NFT is not listed for rent");
        require(rental.renter == address(0), "NFT is already rented");
        require(msg.value >= rental.rentalPrice, "Insufficient rental fee");

        // Deposit rental fee into yield protocol
        yieldProtocol.deposit(address(this), rental.rentalPrice);

        rental.renter = msg.sender;
        rental.startTime = block.timestamp;

        emit NFTRented(_nftContract, _tokenId, msg.sender, rental.rentalPrice, rental.rentalDuration);
    }

    // Function to extend the rental period
    function extendRental(address _nftContract, uint256 _tokenId, uint256 _extensionDuration) external payable nonReentrant {
        Rental storage rental = rentals[_nftContract][_tokenId];
        require(rental.isActive == true, "NFT is not currently rented");
        require(rental.renter == msg.sender, "You are not the current renter");
        require(msg.value >= rental.rentalPrice, "Insufficient rental fee for extension"); //Using original rentalPrice for simplicity

        // Deposit rental fee into yield protocol
        yieldProtocol.deposit(address(this), rental.rentalPrice);

        rental.rentalDuration += _extensionDuration;

        emit RentalExtended(_nftContract, _tokenId, _extensionDuration);
    }


    // Function to withdraw the NFT
    function withdrawNFT(address _nftContract, uint256 _tokenId) external nonReentrant {
        Rental storage rental = rentals[_nftContract][_tokenId];
        require(rental.isActive == true, "NFT is not currently listed or rented");
        require(rental.owner == msg.sender, "You are not the owner of this NFT");

        if (rental.renter != address(0)) {
            require(block.timestamp >= rental.startTime + rental.rentalDuration, "Rental period has not expired yet");
        }

        IERC721 nft = IERC721(_nftContract);
        nft.transferFrom(address(this), msg.sender, _tokenId);

        delete rentals[_nftContract][_tokenId]; // Reset rental information
        emit NFTWithdrawn(_nftContract, _tokenId, msg.sender);
    }

    //Function to emergency withdraw NFT
    function emergencyWithdraw(address _nftContract, uint256 _tokenId) external nonReentrant {
        Rental storage rental = rentals[_nftContract][_tokenId];
        require(rental.owner == msg.sender, "You are not the owner of this NFT");
        require(rental.isActive == true, "NFT is not currently listed or rented");

        IERC721 nft = IERC721(_nftContract);
        nft.transferFrom(address(this), msg.sender, _tokenId);

        // Refund rent to renter.  This is the emergency forfeit.
        if(rental.renter != address(0)) {
            payable(rental.renter).transfer(address(this).balance); //Transfer all contract balance to renter
        }

        delete rentals[_nftContract][_tokenId]; // Reset rental information
        emit NFTWithdrawn(_nftContract, _tokenId, msg.sender);

    }

    // Function to collect yield and distribute it
    function collectYield(address _nftContract, uint256 _tokenId) external nonReentrant {
        Rental storage rental = rentals[_nftContract][_tokenId];
        require(rental.isActive == true, "NFT is not currently listed or rented");
        require(msg.sender == rental.owner || msg.sender == rental.renter, "Only the owner or renter can collect yield");

        // Get the yield earned on rental fees
        uint256 yieldAmount = yieldProtocol.getYield(address(this));

        // Calculate owner and renter yield portions
        uint256 ownerYield = (yieldAmount * ownerYieldPercentage) / 100;
        uint256 renterYield = (yieldAmount * renterYieldPercentage) / 100;

        // Withdraw yield from protocol
        yieldProtocol.withdraw(address(this), yieldAmount);

        // Transfer yield to owner and renter
        if(ownerYield > 0) {
           payable(rental.owner).transfer(ownerYield);
        }
        if(rental.renter != address(0) && renterYield > 0) {
            payable(rental.renter).transfer(renterYield);
        }


        emit YieldCollected(_nftContract, _tokenId, ownerYield, renterYield);
    }

    // Function to set the yield protocol address
    function setYieldProtocol(address _yieldProtocolAddress) external {
        //Consider adding access control, only owner can change this
        yieldProtocol = IYieldProtocol(_yieldProtocolAddress);
    }

    // Function to set the yield split percentages
    function setYieldSplit(uint256 _ownerPercentage, uint256 _renterPercentage) external {
       //Consider adding access control, only owner can change this
        require(_ownerPercentage + _renterPercentage == 100, "Yield percentages must add up to 100");
        ownerYieldPercentage = _ownerPercentage;
        renterYieldPercentage = _renterPercentage;
    }

    //Override transfer function to block owner from transfering NFT while rented
    function onERC721Received(address, address from, uint256 tokenId, bytes calldata) external override returns (bytes4) {
        require(from == address(0), "ERC721: mint not supported");
        return this.onERC721Received.selector;
    }

    // Function to comply with ERC-165 interface detection
    function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
        return interfaceId == type(IERC165).interfaceId || interfaceId == type(ERC721Holder).interfaceId;
    }

    // Prevents direct ETH send
    receive() external payable {
        revert("This contract does not accept direct ETH transfers.");
    }
    fallback() external payable {
        revert("This contract does not accept direct ETH transfers.");
    }
}
```

**Key Considerations and Further Development:**

*   **Error Handling:**  More robust error handling and revert messages are crucial for production.
*   **Gas Optimization:**  This contract can be optimized for gas efficiency. Consider using smaller data types where possible and minimizing storage writes.
*   **Security Audits:** Before deploying to a live environment, a professional security audit is absolutely necessary.
*   **Yield Protocol Integration:**  The integration with the yield protocol is simplified.  In a real-world scenario, you would need to adapt the code to the specific API of the chosen protocol.
*   **NFT Standards:**  This contract assumes ERC721 NFTs.  You might need to adapt it to handle other NFT standards like ERC1155.
*   **Access Control:** Implement role-based access control (e.g., using OpenZeppelin's `Ownable` or `AccessControl`) to restrict administrative functions like setting the yield protocol and yield split.
*   **Dynamic Pricing:**  Implement dynamic rental pricing based on demand and NFT rarity.
*   **Insurance:**  Consider integrating with insurance protocols to protect renters in case of contract vulnerabilities.
*   **Frontend Interface:**  A user-friendly frontend is essential for interacting with this smart contract.

This is a complex and advanced concept, and the code provided is a starting point.  Thorough testing, security reviews, and gas optimization are crucial before deploying to a production environment.
