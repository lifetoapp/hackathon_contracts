// SPDX-License-Identifier: UNLICENSED

/*
 *  ██      ██ ███████ ███████ ██████   █████  ██████  ██████
 *  ██      ██ ██      ██           ██ ██   ██ ██   ██ ██   ██
 *  ██      ██ █████   █████    █████  ███████ ██████  ██████
 *  ██      ██ ██      ██      ██      ██   ██ ██      ██
 *  ███████ ██ ██      ███████ ███████ ██   ██ ██      ██
 */

pragma solidity 0.8.23;

// Imports.
import {Initializable} from '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import {UUPSUpgradeable} from '@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol';
import {ERC20Upgradeable} from '@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol';
import {ERC20BurnableUpgradeable} from '@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol';
import {OwnableUpgradeable} from '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import {ReentrancyGuardUpgradeable} from '@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol';
import {EIP712DataValidator} from './libs/EIP712DataValidator.sol';

// Errors.
error UnauthorizedMinter();
error NonceAlreadyUsed();
error MaxMintableAmountPerDayExceeded();

/**
 * @title The Life2App GEM Token.
 * @author Life2App
 * @notice The Life2App GEM Token is an ERC20 token that is used to reward users for their activity.
 * @dev The Life2App GEM Token is an ERC20 token that is used to reward users for their activity.
 */
contract L2AppGem is
  Initializable,
  UUPSUpgradeable,
  ERC20Upgradeable,
  ERC20BurnableUpgradeable,
  OwnableUpgradeable,
  ReentrancyGuardUpgradeable,
  EIP712DataValidator
{
  /**
   * @notice The struct of the mint data.
   * @param to The address to which the tokens will be transferred.
   * @param amount The amount of tokens to be minted.
   * @param nonce The nonce of the minting transaction.
   */
  struct MintData {
    address to;
    uint256 amount;
    uint256 nonce;
  }

  /// @notice The max amount of tokens that can be minted per day.
  uint256 public maxMintableAmountPerDay;
  /// @notice The mapping of authorized minters.
  mapping(address => bool) public minters;
  /// @notice The mapping of used nonces per address.
  mapping(address => mapping(uint256 => bool)) public usedNonces;
  /// @notice The mapping contains the number of minted tokens per day per address.
  mapping(address => mapping(uint256 => uint256)) public mintedPerDay;

  // Events.
  /// @notice The event is emitted when a new minter is added.
  event MinterAdded(address indexed minter);
  /// @notice The event is emitted when a minter is removed.
  event MinterRemoved(address indexed minter);
  /// @notice The event is emitted when tokens are minted.
  event Mint(address indexed to, uint256 amount);
  /// @notice The event is emitted when tokens are burned.
  event Burn(address indexed from, uint256 amount);

  /**
   * @notice The constructor of the contract.
   * @dev This constructor is used to disable the initializers of the inherited contracts.
   */
  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  /**
   * @notice The smart contract initializer.
   */
  function initialize(uint256 maxMintableAmountPerDay_) public initializer {
    __ERC20_init('L2APPGEM', 'L2APPGEM');
    __ERC20Burnable_init();
    __Ownable_init(msg.sender);
    __ReentrancyGuard_init();
    EIP712DataValidator.initializeValidator();
    maxMintableAmountPerDay = maxMintableAmountPerDay_;
  }

  /**
   * @notice The version of the smart contract.
   * @return The version of the smart contract.
   */
  function version() external pure returns (string memory) {
    return '1.0.0';
  }

  /**
   * @notice The function is used to add a new minter.
   * @dev This function adds a new minter to the mapping of authorized minters.
   * @param minter The address of the minter to be added.
   */
  function addMinter(address minter) external onlyOwner {
    minters[minter] = true;
    emit MinterAdded(minter);
  }

  /**
   * @notice The function is used to remove a minter.
   * @dev This function removes a minter from the mapping of authorized minters.
   * @param minter The address of the minter to be removed.
   */
  function removeMinter(address minter) external onlyOwner {
    minters[minter] = false;
    emit MinterRemoved(minter);
  }

  /**
   * @notice The mint function is used to mint new tokens.
   * @dev This function mints new tokens and transfers them to the specified address.
   */
  function mint(bytes calldata data, bytes32 encodedData, bytes calldata signature) public nonReentrant {
    // Verify the signature.
    if (!minters[recoverSigningAddress(data, encodedData, signature)]) {
      revert UnauthorizedMinter();
    }

    // Unpack the data.
    MintData memory mintData = abi.decode(data, (MintData));
    // Check if max mint amount per day is not exceeded.
    uint256 currentDay = block.timestamp / 1 days;
    uint256 dailyMinted = mintedPerDay[mintData.to][currentDay];
    uint256 mintAmountAfter = dailyMinted + mintData.amount;

    if (mintAmountAfter > maxMintableAmountPerDay) {
      revert MaxMintableAmountPerDayExceeded();
    }

    // Check if the nonce is not used.
    if (usedNonces[mintData.to][mintData.nonce]) {
      revert NonceAlreadyUsed();
    }

    // Mint the tokens.
    _mint(mintData.to, mintData.amount);
    usedNonces[mintData.to][mintData.nonce] = true;
    mintedPerDay[mintData.to][currentDay] = mintAmountAfter;
    // Emit the Mint event.
    emit Mint(mintData.to, mintData.amount);
  }

  /**
   * @notice Handles authorization of the upgrade.
   * @dev Only the contract owner is authorized to upgrade the contract.
   */
  function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
