// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract BatchExecutor is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint256 public maxRecipients;

    event MaxRecipientsUpdated(uint256 previousValue, uint256 newValue);
    event TokenBatchExecuted(
        address indexed sender,
        address indexed token,
        uint256 recipientCount,
        uint256 totalAmount
    );
    event NativeBatchExecuted(
        address indexed sender,
        uint256 recipientCount,
        uint256 totalAmount
    );

    error InvalidLength();
    error ZeroRecipients();
    error TooManyRecipients(uint256 provided, uint256 maxAllowed);
    error ZeroAddressRecipient();
    error ZeroTokenAddress();
    error InvalidNativeValue(uint256 expected, uint256 received);
    error NativeTransferFailed(address recipient, uint256 amount);

    constructor(uint256 initialMaxRecipients) Ownable(msg.sender) {
        if (initialMaxRecipients == 0) revert ZeroRecipients();
        maxRecipients = initialMaxRecipients;
    }

    function setMaxRecipients(uint256 newMaxRecipients) external onlyOwner {
        if (newMaxRecipients == 0) revert ZeroRecipients();
        uint256 previous = maxRecipients;
        maxRecipients = newMaxRecipients;
        emit MaxRecipientsUpdated(previous, newMaxRecipients);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    // Explorer-friendly aliases requested by UI/business naming.
    function Airdrop(
        address token,
        address[] calldata recipients,
        uint256[] calldata amounts
    ) external nonReentrant whenNotPaused {
        _executeTokenBatch(token, recipients, amounts, msg.sender);
    }

    function MultiSender(
        address token,
        address[] calldata recipients,
        uint256[] calldata amounts
    ) external nonReentrant whenNotPaused {
        _executeTokenBatch(token, recipients, amounts, msg.sender);
    }

    function Disperse(
        address token,
        address[] calldata recipients,
        uint256[] calldata amounts
    ) external nonReentrant whenNotPaused {
        _executeTokenBatch(token, recipients, amounts, msg.sender);
    }

    function Disperse(
        address[] calldata recipients,
        uint256[] calldata amounts
    ) external payable nonReentrant whenNotPaused {
        _executeNativeBatch(recipients, amounts, msg.sender);
    }

    function Transfer(
        address token,
        address[] calldata recipients,
        uint256[] calldata amounts
    ) external nonReentrant whenNotPaused {
        _executeTokenBatch(token, recipients, amounts, msg.sender);
    }

    function Transfer(
        address[] calldata recipients,
        uint256[] calldata amounts
    ) external payable nonReentrant whenNotPaused {
        _executeNativeBatch(recipients, amounts, msg.sender);
    }

    function _executeTokenBatch(
        address token,
        address[] memory recipients,
        uint256[] memory amounts,
        address sender
    ) private {
        if (token == address(0)) revert ZeroTokenAddress();
        _validateBatchInput(recipients, amounts);

        uint256 totalAmount;
        uint256 len = recipients.length;
        for (uint256 i = 0; i < len; ++i) {
            address recipient = recipients[i];
            if (recipient == address(0)) revert ZeroAddressRecipient();

            uint256 amount = amounts[i];
            totalAmount += amount;
            IERC20(token).safeTransferFrom(sender, recipient, amount);
        }

        emit TokenBatchExecuted(sender, token, len, totalAmount);
    }

    function _executeNativeBatch(
        address[] memory recipients,
        uint256[] memory amounts,
        address sender
    ) private {
        _validateBatchInput(recipients, amounts);

        uint256 totalAmount;
        uint256 len = recipients.length;
        for (uint256 i = 0; i < len; ++i) {
            address recipient = recipients[i];
            if (recipient == address(0)) revert ZeroAddressRecipient();
            totalAmount += amounts[i];
        }

        if (msg.value != totalAmount) {
            revert InvalidNativeValue(totalAmount, msg.value);
        }

        for (uint256 i = 0; i < len; ++i) {
            uint256 amount = amounts[i];
            if (amount == 0) continue;

            (bool success, ) = recipients[i].call{value: amount}("");
            if (!success) revert NativeTransferFailed(recipients[i], amount);
        }

        emit NativeBatchExecuted(sender, len, totalAmount);
    }

    function _validateBatchInput(
        address[] memory recipients,
        uint256[] memory amounts
    ) internal view {
        uint256 len = recipients.length;
        if (len != amounts.length) revert InvalidLength();
        if (len == 0) revert ZeroRecipients();
        if (len > maxRecipients) revert TooManyRecipients(len, maxRecipients);
    }
}
