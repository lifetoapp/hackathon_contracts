// SPDX-License-Identifier: ULINCENSED
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
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
    using EnumerableSet for EnumerableSet.UintSet;

    IERC20 public regularToken;
    IERC20 public premiumToken;

    uint public regularLootboxPrice;
    uint public premiumLootboxPrice;
    // uint public premiumItemPrice;
    // uint public premiumItemLevel;

    address public paymentReceiver;
    address public playersContract;

    // TODO: leave indexing for backend?
    // owner => owned items set
    mapping(address => EnumerableSet.UintSet) private ownedItems;

    modifier onlyPlayersContract() {
        require(msg.sender == playersContract, "LifeHackatonItems: only Players contract can call this function");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(
        string memory uri,
        address regularToken_,
        address premiumToken_,
        uint regularLootboxPrice_,
        uint premiumLootboxPrice_,
        // uint premiumItemPrice_,
        // uint premiumItemLevel_,
        address paymentReceiver_
    ) initializer public {
        __Ownable_init(msg.sender);
        __ERC1155_init(uri);
        __UUPSUpgradeable_init();

        regularToken = IERC20(regularToken_);
        premiumToken = IERC20(premiumToken_);
        regularLootboxPrice = regularLootboxPrice_;
        premiumLootboxPrice = premiumLootboxPrice_;
        // premiumItemPrice = premiumItemPrice_;
        // premiumItemLevel = premiumItemLevel_;
        paymentReceiver = paymentReceiver_;
    }

    function buyRegularLootbox() external {
        address msgSender = _msgSender();

        regularToken.safeTransferFrom(msgSender, paymentReceiver, regularLootboxPrice);
        _mintRegularLootbox(msgSender);
    }

    function buyPremiumLootbox() external {
        address msgSender = _msgSender();
      
        premiumToken.safeTransferFrom(_msgSender(), paymentReceiver, premiumLootboxPrice);
        _mintPremiumLootbox(msgSender);
    }

    function openLootbox(uint lootbox) external {
        _openLootbox(_msgSender(), lootbox);
    }

    function claimLootboxReward(uint lootbox) external {
        _claimLootboxReward(_msgSender(), lootbox);
    }

    function mergeEquipmentParts(uint part) external {
        _mergeEquipmentParts(_msgSender(), part);
    }

    function mergeEquipment(uint equipment) external {
        _mergeEquipment(_msgSender(), equipment);
    }

    function giveRegularLootboxes(address to, uint amount) external onlyPlayersContract() {
        _mintRegularLootboxes(to, amount);
    }

    // TODO: for testing only, remove
    function freeMintSelfItems(uint64 type_, uint64 subType, uint64 level, uint amount) external {
        _mintItems(
            _msgSender(),
            amount,
            type_,
            subType,
            0,
            level
        );
    }

    // TODO: stub
    function buyPremiumItem(uint64 subType) external {
        address msgSender = _msgSender();
      
        premiumToken.safeTransferFrom(msgSender, paymentReceiver, premiumLootboxPrice * 10);
        _mintItem(
            msgSender,
            EQUIPMENT_TYPE,
            subType,
            0,
            4
        );
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

    function setPlayersContract(address playersContract_) external onlyOwner() {
        playersContract = playersContract_;
    }

    function getPlayerOwnedItems(address player) external view returns (uint[] memory) {
        return ownedItems[player].values();
    }

    function _update(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values
    ) internal virtual override {
        super._update(from, to, ids, values);

        for (uint i = 0; i < ids.length; i++) {
            uint id = ids[i];

            if (from != address(0) && balanceOf(from, id) == 0) {
                ownedItems[from].remove(id);
            }

            if (to != address(0)) {
                ownedItems[to].add(id);
            }
        }
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner()
        override
    {}
}