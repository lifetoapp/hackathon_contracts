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
import {OwnableUpgradeable} from '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import {ReentrancyGuardUpgradeable} from '@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol';
import {IERC1155} from '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';
import {ERC1155} from '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';
import {EnumerableSet} from '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';

/**
 * @title The Players smart contract.
 * @author Life2App
 * @notice The Players smart contract is used to manage the players of the game.
 * @dev The Players smart contract is used to manage the players of the game.
 */
contract Players is Initializable, UUPSUpgradeable, OwnableUpgradeable {
  /**
   * @notice The struct of the player info.
   * @param selectedObjects The array of selected objects.
   * @param currentLeague The current league of the player.
   * @param currentCoolness The current coolness of the player.
   * @param currentExperience The current experience of the player.
   * @param currentRating The current rating of the player.
   */
  struct PlayerInfo {
    mapping(uint64 => uint256) selectedObjects;
    uint256 currentLeague;
    uint256 currentCoolness;
    uint256 currentExperience;
    uint256 currentRating;
  }

  /// @notice The ID of the phone subtype.
  uint64 public constant PHONE_SUBTYPE = uint64(uint256(keccak256('PHONE_SUBTYPE')));
  /// @notice The ID of the earbuds subtype.
  uint64 public constant EARBUDS_SUBTYPE = uint64(uint256(keccak256('EARBUDS_SUBTYPE')));
  /// @notice The ID of the power bank subtype.
  uint64 public constant POWERBANK_SUBTYPE = uint64(uint256(keccak256('POWERBANK_SUBTYPE')));
  /// @notice The ID of the laptop subtype.
  uint64 public constant LAPTOP_SUBTYPE = uint64(uint256(keccak256('LAPTOP_SUBTYPE')));

  /// @notice The mapping of player info per address.
  mapping(address => PlayerInfo) public playerInfo;
  /// @notice The mapping of authorized operators.
  mapping(address => bool) public authorizedOperators;
  /// @notice The mapping of the current league per address.
  mapping(address => uint256) public currentLeague;
  /// @notice The mapping of the league to the players.
  mapping(uint256 => EnumerableSet.AddressSet) public leaguePlayers;

  /**
   * @notice The modifier to check if the sender is an authorized operator.
   */
  modifier onlyAuthorizedOperator() {
    require(authorizedOperators[msg.sender], 'Players: Not an authorized operator');
    _;
  }

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
  function initialize() public initializer {
    __Ownable_init(msg.sender);
    __ReentrancyGuard_init();
  }

  /**
   * @notice The function to update the user's selected objects.
   * @param phoneTokenId The ID of the phone token.
   * @param earbudsTokenId The ID of the earbuds token.
   * @param powerbankTokenId The ID of the power bank token.
   * @param laptopTokenId The ID of the laptop token.
   */
  function updateUserSelectedObjects(uint256 phoneTokenId, uint256 earbudsTokenId, uint256 powerbankTokenId, uint256 laptopTokenId) external {
    // Verifying ownership of each token.
    require(phoneTokenId == 0 || IERC1155(msg.sender).balanceOf(msg.sender, phoneTokenId) > 0, 'Players: Not the owner of the phone token');
    require(earbudsTokenId == 0 || IERC1155(msg.sender).balanceOf(msg.sender, earbudsTokenId) > 0, 'Players: Not the owner of the earbuds token');
    require(
      powerbankTokenId == 0 || IERC1155(msg.sender).balanceOf(msg.sender, powerbankTokenId) > 0,
      'Players: Not the owner of the power bank token'
    );
    require(laptopTokenId == 0 || IERC1155(msg.sender).balanceOf(msg.sender, laptopTokenId) > 0, 'Players: Not the owner of the laptop token');
    // Set the selected objects.
    playerInfo[msg.sender].selectedObjects[PHONE_SUBTYPE] = phoneTokenId;
    playerInfo[msg.sender].selectedObjects[EARBUDS_SUBTYPE] = earbudsTokenId;
    playerInfo[msg.sender].selectedObjects[POWERBANK_SUBTYPE] = powerbankTokenId;
    playerInfo[msg.sender].selectedObjects[LAPTOP_SUBTYPE] = laptopTokenId;
    // Set coolness based on the selected objects.
    // TODO: Set the coolness based on the selected objects.
  }

  /**
   * @notice The function updates the user's current league.
   * @param user The address of the user.
   * @param league The league number.
   */
  function updateUserCurrentLeague(address user, uint256 league) external onlyAuthorizedOperator {
    // Remove the user from the current league.
    leaguePlayers[currentLeague[user]].remove(user);
    // Add the user to the new league.
    leaguePlayers[league].add(user);
    // Update the user's current league.
    currentLeague[user] = league;
  }

  /**
   * @notice The function updates the user's rating and experience.
   * @param user The address of the user.
   * @param rating The rating of the user.
   * @param experience The experience of the user.
   */
  function updateUserRatingAndExperience(address user, uint256 rating, uint256 experience) external onlyAuthorizedOperator {
    // Update the user's rating and experience.
    playerInfo[user].currentRating = rating;
    playerInfo[user].currentExperience = experience;
  }

  /**
   * @notice The function to set the authorized operator.
   * @param authorizedOperator_ The address of the authorized operator.
   * @param authorize The authorization status.
   */
  function setAuthorizedOperator(address authorizedOperator_, bool authorize) external onlyOwner {
    authorizedOperators[authorizedOperator_] = authorize;
  }

  /**
   * @notice The function returns the user-selected objects.
   * @param user The address of the user.
   * @return The user-selected objects.
   */
  function getUserSelectedObjects(address user) external view returns (uint256[4] memory) {
    return [
      playerInfo[user].selectedObjects[PHONE_SUBTYPE],
      playerInfo[user].selectedObjects[EARBUDS_SUBTYPE],
      playerInfo[user].selectedObjects[POWERBANK_SUBTYPE],
      playerInfo[user].selectedObjects[LAPTOP_SUBTYPE]
    ];
  }

  /**
   * @notice Gets all the players of the league.
   * @param league The league number.
   * @return The players of the league.
   */
  function getLeaguePlayers(uint256 league) external view returns (address[] memory) {
    return leaguePlayers[league].values();
  }

  /**
   * @notice The version of the smart contract.
   * @return The version of the smart contract.
   */
  function version() external pure returns (string memory) {
    return '1.0.0';
  }

  /**
   * @notice Handles authorization of the upgrade.
   * @dev Only the contract owner is authorized to upgrade the contract.
   */
  function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
