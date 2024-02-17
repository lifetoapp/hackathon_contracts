// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.17;

/*
 *  ██      ██ ███████ ███████ ██████   █████  ██████  ██████
 *  ██      ██ ██      ██           ██ ██   ██ ██   ██ ██   ██
 *  ██      ██ █████   █████    █████  ███████ ██████  ██████
 *  ██      ██ ██      ██      ██      ██   ██ ██      ██
 *  ███████ ██ ██      ███████ ███████ ██   ██ ██      ██
 */

// Import libraries.
import {Initializable} from '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import {UUPSUpgradeable} from '@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol';
import {ContextUpgradeable} from '@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol';
import {OwnableUpgradeable} from '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import {ECDSA} from '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';

/**
 * @title The Data Validator smart contract.
 * @dev The following contract is used to check whether data transmitted to smart contracts
        was signed using the valid private key.
 */
contract EIP712DataValidator is Initializable, UUPSUpgradeable, ContextUpgradeable, OwnableUpgradeable {
  using ECDSA for bytes32;
  /// @notice The signing name that is used in the domain separator.
  string public constant SIGNING_NAME = 'L2A_DATA_VALIDATOR';
  /// @notice The version that is used in the domain separator.
  string public constant VERSION = '1.0.0';
  /// @notice The type hash of the data that was signed.
  bytes32 public constant TYPE_HASH = keccak256('Data(bytes32 data)');
  /// @notice Domain Separator is the EIP-712 defined structure that defines what contract
  //          and chain these signatures can be used for.  This ensures people can't take
  //          a signature used to mint on one contract and use it for another, or a signature
  //          from testnet to replay on mainnet.
  /// @dev It has to be created in the constructor so we can dynamically grab the chainId.
  ///      https://github.com/ethereum/EIPs/blob/master/EIPS/eip-712.md#definition-of-domainseparator
  bytes32 public domainSeparator;

  /**
   * @notice The constructor of the contract.
   * @dev This constructor is used to disable the initializers of the inherited contracts.
   */
  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  /**
   * @notice The constructor that initializes the current smart contract.
   */
  function initializeValidator() public initializer {
    domainSeparator = keccak256(
      abi.encode(
        keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
        keccak256(bytes(SIGNING_NAME)),
        keccak256(bytes(VERSION)),
        block.chainid,
        address(this)
      )
    );
  }

  /**
   * @notice Recovers an address that signed a message.
   * @param data The data that was signed.
   * @param encodedData The encoded version of the data.
   * @param signature The data signing signature.
   * @return The recovered address
   */
  function recoverSigningAddress(bytes calldata data, bytes32 encodedData, bytes calldata signature) public view returns (bool) {
    // Check if the encoded data and data are the same.
    require(keccak256(data) == encodedData, 'INVALID_DATA');
    // Verify EIP-712 signature by recreating the data structure
    // that we signed on the client side, and then using that to recover
    // the address that signed the signature for this data.
    bytes32 digest = keccak256(abi.encodePacked('\x19\x01', domainSeparator, keccak256(abi.encode(TYPE_HASH, encodedData))));
    // Use the recover method to see what address was used to create
    // the signature on this data.
    // Note that if the digest doesn't exactly match what was signed we'll
    // get a random recovered address.
    address recoveredAddress = digest.recover(signature);
    return recoveredAddress;
  }

  /**
   * @notice Handles authorization of the upgrade.
   * @dev Only the contract owner is authorized to upgrade the contract.
   */
  function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
