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

  /// @notice The max amount of tokens that can be minted.
  uint256 public maxMintableAmount;
  /// @notice The minimum time between minting for each address.
  uint256 public mintingInterval;
  /// @notice The mapping of authorized minters.
  mapping(address => bool) public minters;
  /// @notice The mapping of timestamps of the last minting per address.
  mapping(address => uint256) public lastMinting;
  /// @notice The mapping of used nonces per address.
  mapping(address => mapping(uint256 => bool)) public usedNonces;

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
  function initialize(uint256 maxMintableAmount_, uint256 mintingInterval_) public initializer {
    __ERC20_init('L2APPGEM', 'L2APPGEM');
    __ERC20Burnable_init();
    __Ownable_init(msg.sender);
    __ReentrancyGuard_init();
    EIP712DataValidator.initializeValidator();
    maxMintableAmount = maxMintableAmount_;
    mintingInterval = mintingInterval_;
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
    require(minters[recoverSigningAddress(data, encodedData, signature)], 'NOT_A_MINTER');
    // Unpack the data.
    MintData memory mintData = abi.decode(data, (MintData));
    // Check if the amount is not greater than the max mintable amount.
    require(mintData.amount <= maxMintableAmount, 'MINT_AMOUNT_EXCEEDS_MAX');
    // Check if the nonce is not used.
    require(!usedNonces[mintData.to][mintData.nonce], 'NONCE_ALREADY_USED');
    // Check if the minting interval has passed.
    require(block.timestamp - lastMinting[mintData.to] >= mintingInterval, 'MINTING_INTERVAL_NOT_PASSED');
    // Mint the tokens.
    _mint(mintData.to, mintData.amount);
    // Update the last minting timestamp.
    lastMinting[mintData.to] = block.timestamp;
    // Mark the nonce as used.
    usedNonces[mintData.to][mintData.nonce] = true;
    // Emit the Mint event.
    emit Mint(mintData.to, mintData.amount);
  }

  /**
   * @notice Handles authorization of the upgrade.
   * @dev Only the contract owner is authorized to upgrade the contract.
   */
  function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
