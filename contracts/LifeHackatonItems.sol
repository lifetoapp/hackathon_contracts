// SPDX-License-Identifier: ULINCENSED
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./items/Equipment.sol";
import "./items/EquipmentParts.sol";
import "./items/Lootboxes.sol";

contract LifeHackatonItems is
    Initializable,
    OwnableUpgradeable,
    ERC1155Upgradeable,
    Equipment,
    EquipmentParts,
    Lootboxes,
    UUPSUpgradeable
{
    using SafeERC20 for IERC20;

    IERC20 regularToken;
    IERC20 premiumToken;

    uint regularLootboxPrice;
    uint premiumLootboxPrice;

    address paymentReceiver;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(
        string memory uri,
        address regularToken_,
        address premiumToken_,
        uint regularLootboxPrice_,
        uint premiumLootboxPrice_,
        address paymentReceiver_
    ) initializer public {
        __Ownable_init(msg.sender);
        __ERC1155_init(uri);
        __UUPSUpgradeable_init();

        regularToken = IERC20(regularToken_);
        premiumToken = IERC20(premiumToken_);
        regularLootboxPrice = regularLootboxPrice_;
        premiumLootboxPrice = premiumLootboxPrice_;
        paymentReceiver = paymentReceiver_;
    }

    function buyRegularLootbox() external {
      regularToken.safeTransferFrom(_msgSender(), paymentReceiver, regularLootboxPrice);
    }

    function buyPremiumLootbox() external {
      premiumToken.safeTransferFrom(_msgSender(), paymentReceiver, premiumLootboxPrice);
    }

    // TODO: add direct item purchases

    function setURI(string memory newURI) external onlyOwner() {
        _setURI(newURI);
    }

    function setRegularLootboxPrice(uint newPrice) external onlyOwner() {
        regularLootboxPrice = newPrice;
    }

    function setPremiumLootboxPrice(uint newPrice) external onlyOwner() {
        premiumLootboxPrice = newPrice;
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner()
        override
    {}

    // // The following functions are overrides required by Solidity.

    // function supportsInterface(bytes4 interfaceId)
    //     public
    //     view
    //     override(ERC1155Upgradeable, AccessControlUpgradeable)
    //     returns (bool)
    // {
    //     return super.supportsInterface(interfaceId);
    // }
}