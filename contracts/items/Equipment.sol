// SPDX-License-Identifier: ULINCENSED
pragma solidity ^0.8.19;

import "./ItemBase.sol";

abstract contract EquipmentBase is ItemBase {

    uint64 public constant EQUIPMENT_TYPE = uint64(uint256(keccak256("EQUIPMENT_TYPE")));
    uint public constant NUMBER_OF_ITEMS_TO_MERGE = 2;
    uint public constant MAX_EQUIPMENT_LEVEL = 15;

    // TODO: add coolness and reward multiplier viewers

    function isEquipment(uint item) public pure returns (bool) {
        return getItemType(item) == EQUIPMENT_TYPE;
    }

    function getEquipmentLevel(uint256 item) public pure returns (uint64) {
        return getItemExtra(item);
    }

    function getEquipmentCoolness(uint256 item) public pure virtual returns (uint256) {
        // Calculates the coolness of the equipment.
        // Used formula: CP(n)=10*2^(n-1)
        uint256 level = getEquipmentLevel(item);

        if (level == 0) {
          return 0;
        }

        return 10 * (2 ** (getEquipmentLevel(item) - 1));
    }

    function getRewardMultiplier(uint256 item) public pure virtual returns (uint256) {
        // Calculates the reward multiplier of the equipment.
        // Used formula: RM(n)=5*n
        return 5 * getEquipmentLevel(item);
    }

    function _mintEquipment(
        address to,
        uint64 subType,
        uint64 itemId,
        uint64 level
    ) internal {
        require(level > 0 && level <= MAX_EQUIPMENT_LEVEL, "Equipment: invalid level");

        _mintItem(to, EQUIPMENT_TYPE, subType, itemId, level);
    }

    function _mergeEquipment(address owner, uint item) internal {
        uint64 subType = getItemSubtype(item);
        uint64 itemId = getItemId(item);
        uint64 level = getEquipmentLevel(item);

        require(isEquipment(item), "Equipment: not an equipment");
        require(level < MAX_EQUIPMENT_LEVEL, "Equipment: max level reached");
        require(
            balanceOf(owner, item) >= NUMBER_OF_ITEMS_TO_MERGE,
            "Equipment: not enough items"
        );

        _burn(owner, item, NUMBER_OF_ITEMS_TO_MERGE);
        _mintEquipment(owner, subType, itemId, level + 1);
    }
}

abstract contract Phone is EquipmentBase {

    uint64 public constant PHONE_SUBTYPE = uint64(uint256(keccak256("PHONE_SUBTYPE")));

    function isPhone(uint item) public pure returns (bool) {
        return isEquipment(item) && getItemSubtype(item) == PHONE_SUBTYPE;
    }

    function _mintPhone(
        address to,
        uint64 level
    ) internal {
        _mintEquipment(to, PHONE_SUBTYPE, 0, level);
    }
}

abstract contract Earbuds is EquipmentBase {

    uint64 public constant EARBUDS_SUBTYPE = uint64(uint256(keccak256("EARBUDS_SUBTYPE")));

    function isEarbuds(uint item) public pure returns (bool) {
        return isEquipment(item) && getItemSubtype(item) == EARBUDS_SUBTYPE;
    }

    function _mintEarbuds(
        address to,
        uint64 level
    ) internal {
        _mintEquipment(to, EARBUDS_SUBTYPE, 0, level);
    }
}

abstract contract Powerbank is EquipmentBase {

    uint64 public constant POWERBANK_SUBTYPE = uint64(uint256(keccak256("POWERBANK_SUBTYPE")));

    function isPowerbank(uint item) public pure returns (bool) {
        return isEquipment(item) && getItemSubtype(item) == POWERBANK_SUBTYPE;
    }

    function getPowerbankCapacity(uint256 item) public pure returns (uint256) {
        // Calculates the number of additional battles the powerbank can provide.
        // Used formula: C(n)=2*n+1
        return 2 * getEquipmentLevel(item) + 1;
    }

    function _mintPowerbank(
        address to,
        uint64 level
    ) internal {
        _mintEquipment(to, POWERBANK_SUBTYPE, 0, level);
    }
}

abstract contract Laptop is EquipmentBase {

    uint64 public constant LAPTOP_SUBTYPE = uint64(uint256(keccak256("LAPTOP_SUBTYPE")));

    function isLaptop(uint item) public pure returns (bool) {
        return isEquipment(item) && getItemSubtype(item) == LAPTOP_SUBTYPE;
    }

    function _mintLaptop(
        address to,
        uint64 level
    ) internal {
        _mintEquipment(to, LAPTOP_SUBTYPE, 0, level);
    }
}

abstract contract Equipment is Phone, Earbuds, Powerbank, Laptop {}