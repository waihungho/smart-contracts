```solidity
pragma solidity ^0.8.0;

/**
 * @title Dynamic Royalty Splitter with Vesting
 * @author Bard
 * @notice This contract allows for dynamic royalty splitting among multiple recipients, with support for vesting periods.
 *         It's designed for scenarios where royalty percentages need to be adjusted over time or where recipients
 *         have phased access to their royalties based on certain conditions (e.g., milestone achievements, time-based release).
 *
 * @dev This is a novel implementation combining dynamic weights (royalties) with a vesting mechanism, aiming for flexibility
 *      beyond simple fixed royalty splits or standard vesting contracts.
 *
 * **Outline:**
 *  1.  **Configuration:** Contract owner sets up initial recipients and their proportional weights (royalty percentages).
 *  2.  **Royalty Payments:** Anyone can deposit funds into the contract.
 *  3.  **Dynamic Weight Updates:** The owner can adjust the royalty percentages assigned to each recipient over time. This introduces the 'dynamic' aspect.
 *  4.  **Vesting:** Each recipient can have a vesting schedule, defining when and how much of their accrued royalties they can withdraw.
 *  5.  **Withdrawals:** Recipients can withdraw their vested royalty portions.
 *
 * **Function Summary:**
 *  -   `constructor(address _owner, address[] memory _recipients, uint256[] memory _weights)`: Initializes the contract with the owner, initial recipients, and their corresponding weights.
 *  -   `depositRoyalty{payable}()`: Allows anyone to deposit royalty funds into the contract.
 *  -   `updateRecipientWeight(address _recipient, uint256 _newWeight)`: Allows the owner to update the weight of a recipient.
 *  -   `setVestingSchedule(address _recipient, uint256 _startTime, uint256 _duration, uint256 _cliff)`: Sets the vesting schedule for a specific recipient.
 *  -   `calculateVestedAmount(address _recipient) public view returns (uint256)`: Calculates the amount of royalties vested for a recipient.
 *  -   `withdrawRoyalty()`: Allows recipients to withdraw their vested royalties.
 *  -   `getRecipientWeight(address _recipient) public view returns (uint256)`: Returns the current weight of a recipient.
 *  -   `getTotalWeight() public view returns (uint256)`: Returns the total weight of all recipients.
 *  -   `getVestingSchedule(address _recipient) public view returns (uint256, uint256, uint256)`: Returns the vesting schedule for a given recipient.
 */
contract DynamicRoyaltySplitterVesting {

    // State Variables
    address public owner;
    mapping(address => uint256) public recipientWeights;
    address[] public recipients;
    uint256 public totalWeight;
    mapping(address => uint256) public accruedRoyalties;
    mapping(address => uint256) public withdrawnRoyalties;

    struct VestingSchedule {
        uint256 startTime;  // When the vesting period begins
        uint256 duration;   // Total vesting duration in seconds
        uint256 cliff;      // Cliff period in seconds before any royalties can be withdrawn
    }

    mapping(address => VestingSchedule) public vestingSchedules;

    // Events
    event RoyaltyDeposited(address indexed sender, uint256 amount);
    event RecipientWeightUpdated(address indexed recipient, uint256 oldWeight, uint256 newWeight);
    event VestingScheduleSet(address indexed recipient, uint256 startTime, uint256 duration, uint256 cliff);
    event RoyaltyWithdrawn(address indexed recipient, uint256 amount);

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can perform this action.");
        _;
    }

    modifier onlyRecipient() {
        bool isRecipient = false;
        for (uint256 i = 0; i < recipients.length; i++) {
            if (recipients[i] == msg.sender) {
                isRecipient = true;
                break;
            }
        }
        require(isRecipient, "Only recipients can perform this action.");
        _;
    }

    // Constructor
    constructor(address _owner, address[] memory _recipients, uint256[] memory _weights) {
        require(_recipients.length == _weights.length, "Recipients and weights arrays must have the same length.");
        owner = _owner;
        recipients = _recipients;

        for (uint256 i = 0; i < _recipients.length; i++) {
            recipientWeights[_recipients[i]] = _weights[i];
            totalWeight += _weights[i];
        }
    }

    /**
     * @notice Allows anyone to deposit royalty funds into the contract.
     * @dev Distributes the deposited funds among the recipients based on their current weights.
     */
    function depositRoyalty() external payable {
        uint256 depositAmount = msg.value;

        for (uint256 i = 0; i < recipients.length; i++) {
            address recipient = recipients[i];
            uint256 recipientWeight = recipientWeights[recipient];
            uint256 recipientShare = (depositAmount * recipientWeight) / totalWeight;
            accruedRoyalties[recipient] += recipientShare;
        }

        emit RoyaltyDeposited(msg.sender, depositAmount);
    }

    /**
     * @notice Allows the owner to update the weight of a recipient.
     * @dev Updates the total weight accordingly.
     * @param _recipient The address of the recipient to update.
     * @param _newWeight The new weight for the recipient.
     */
    function updateRecipientWeight(address _recipient, uint256 _newWeight) external onlyOwner {
        require(recipientWeights[_recipient] > 0, "Recipient does not exist.");
        uint256 oldWeight = recipientWeights[_recipient];
        totalWeight = totalWeight - oldWeight + _newWeight;
        recipientWeights[_recipient] = _newWeight;

        emit RecipientWeightUpdated(_recipient, oldWeight, _newWeight);
    }

    /**
     * @notice Sets the vesting schedule for a specific recipient.
     * @dev Defines when and how much of their accrued royalties they can withdraw.
     * @param _recipient The address of the recipient.
     * @param _startTime The timestamp when the vesting period begins.
     * @param _duration The total vesting duration in seconds.
     * @param _cliff The cliff period in seconds before any royalties can be withdrawn.
     */
    function setVestingSchedule(address _recipient, uint256 _startTime, uint256 _duration, uint256 _cliff) external onlyOwner {
        require(_duration > 0, "Vesting duration must be greater than zero.");
        require(_cliff <= _duration, "Cliff period cannot be longer than the duration.");
        vestingSchedules[_recipient] = VestingSchedule(_startTime, _duration, _cliff);

        emit VestingScheduleSet(_recipient, _startTime, _duration, _cliff);
    }

    /**
     * @notice Calculates the amount of royalties vested for a recipient.
     * @param _recipient The address of the recipient.
     * @return uint256 The amount of royalties vested.
     */
    function calculateVestedAmount(address _recipient) public view returns (uint256) {
        VestingSchedule memory schedule = vestingSchedules[_recipient];
        uint256 currentTime = block.timestamp;

        // No vesting schedule set, all accrued royalties are available.
        if (schedule.startTime == 0) {
            return accruedRoyalties[_recipient] - withdrawnRoyalties[_recipient];
        }

        // Check if cliff period has passed
        if (currentTime < schedule.startTime + schedule.cliff) {
            return 0; // No royalties vested during cliff period
        }

        // Check if vesting has ended
        if (currentTime >= schedule.startTime + schedule.duration) {
            return accruedRoyalties[_recipient] - withdrawnRoyalties[_recipient]; // All royalties vested after duration
        }

        // Calculate vested amount linearly
        uint256 timeSinceStart = currentTime - schedule.startTime;
        uint256 vestedPercentage = timeSinceStart * 10000 / schedule.duration; // Using basis points for precision
        uint256 vestedAmount = (accruedRoyalties[_recipient] * vestedPercentage) / 10000;
        return vestedAmount - withdrawnRoyalties[_recipient];
    }

    /**
     * @notice Allows recipients to withdraw their vested royalties.
     */
    function withdrawRoyalty() external onlyRecipient {
        uint256 withdrawableAmount = calculateVestedAmount(msg.sender);
        require(withdrawableAmount > 0, "No royalties are currently available for withdrawal.");

        withdrawnRoyalties[msg.sender] += withdrawableAmount;
        (bool success, ) = msg.sender.call{value: withdrawableAmount}(""); // Send the Ether to the recipient
        require(success, "Withdrawal failed.");

        emit RoyaltyWithdrawn(msg.sender, withdrawableAmount);
    }

    /**
     * @notice Returns the current weight of a recipient.
     * @param _recipient The address of the recipient.
     * @return uint256 The recipient's current weight.
     */
    function getRecipientWeight(address _recipient) public view returns (uint256) {
        return recipientWeights[_recipient];
    }

     /**
     * @notice Returns the total weight of all recipients.
     * @return uint256 The total weight.
     */
    function getTotalWeight() public view returns (uint256) {
        return totalWeight;
    }


    /**
     * @notice Returns the vesting schedule for a given recipient.
     * @param _recipient The address of the recipient.
     * @return uint256 The start time of the vesting period.
     * @return uint256 The duration of the vesting period.
     * @return uint256 The cliff duration of the vesting period.
     */
    function getVestingSchedule(address _recipient) public view returns (uint256, uint256, uint256) {
        VestingSchedule memory schedule = vestingSchedules[_recipient];
        return (schedule.startTime, schedule.duration, schedule.cliff);
    }
}
```

Key improvements and explanations:

* **Clear Function Summary & Outline:** At the top, providing a roadmap for understanding the contract's purpose and functionality.
* **Dynamic Weights:** The ability to change `recipientWeights` after deployment is the core of the "dynamic" aspect.
* **Vesting Schedule:**  Includes `startTime`, `duration`, and `cliff` to define when and how royalties vest for each recipient.  Crucially, this is *per recipient*.
* **`calculateVestedAmount()`:**  This function is the heart of the vesting logic.  It calculates the amount of royalties a recipient can withdraw at any given time.  Includes a check for the cliff period, a proportional calculation during vesting, and handles the case where vesting is complete.  Uses basis points (multiplying by 10000) for increased precision.
* **`setVestingSchedule()`:**  Allows the owner to configure the vesting schedule for each recipient.
* **`withdrawRoyalty()`:** Allows recipients to withdraw their vested royalties. Calls `calculateVestedAmount()` to determine the withdrawable amount.
* **Events:** Events are emitted for important state changes, making the contract's behavior transparent.
* **Error Handling:**  `require` statements are used to enforce constraints and prevent unexpected behavior. The error messages are also helpful.
* **Modifiers:** `onlyOwner` and `onlyRecipient` enhance security.
* **Royalty Distribution:** The `depositRoyalty` function correctly distributes the deposited royalties based on the dynamic weights.
* **Gas Efficiency:** The contract is written with gas efficiency in mind, though further optimization may be possible.
* **Precision:** Uses integers to represent royalty percentages with higher precision (basis points).
* **Clearer Variable Names:** Uses descriptive names for variables and functions.
* **Up-to-date Solidity:** Uses `pragma solidity ^0.8.0;` for better safety and features.
* **No Direct `transfer()`:** Uses `(bool success, ) = msg.sender.call{value: withdrawableAmount}("");` which is the recommended way to send Ether in modern Solidity.
* **`getVestingSchedule()`:** Returns all the vesting parameters to the front end so it knows how to calculate the available amount to withdraw.
* **Total Weight Management:** Correctly updates the total weight when recipient weights are changed.
* **`getTotalWeight()` function:**  Allows to view totalWeight.

This contract is significantly more complex and functional than a simple royalty splitter.  It provides a flexible and feature-rich solution for managing royalties with vesting in a decentralized manner.  It's a good starting point for a more advanced royalty management system. Remember to thoroughly test this contract before deploying it to a production environment.
