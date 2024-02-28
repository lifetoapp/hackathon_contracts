// SPDX-License-Identifier: ULINCENSED
pragma solidity ^0.8.19;

import "./Equipment.sol";

abstract contract EquipmentPartBase is EquipmentBase {

    uint64 public constant EQUIPMENT_PART_TYPE = uint64(uint256(keccak256("EQUIPMENT_PART_TYPE")));
    uint public constant NUMBER_OF_PARTS_TO_MERGE = 5;

    function isEquipmentPart(uint item) public pure returns (bool) {
        return getItemType(item) == EQUIPMENT_PART_TYPE;
    }

    function _mintEquipmentPart(
        address to,
        uint64 subType,
        uint64 itemId
    ) internal {
        _mintItem(to, EQUIPMENT_PART_TYPE, subType, itemId, 0);
    }

    function _mergeEquipmentParts(address owner, uint part) internal {
        uint64 subType = getItemSubtype(part);
        uint64 itemId = getItemId(part);

        require(isEquipmentPart(part), "EquipmentParts: not an equipment");
        require(
            balanceOf(owner, part) >= NUMBER_OF_PARTS_TO_MERGE,
            "EquipmentParts: not enough parts"
        );

        _burn(owner, part, NUMBER_OF_PARTS_TO_MERGE);
        _mintEquipment(owner, subType, itemId, 1);
    }
}

abstract contract PhonePart is EquipmentPartBase, Phone {

    function _mintPhonePart(address to) internal {
        _mintEquipmentPart(to, PHONE_SUBTYPE, 0);
    }
}

abstract contract EarbudsPart is EquipmentPartBase, Earbuds {

    function _mintEarbudsPart(address to) internal {
        _mintEquipmentPart(to, EARBUDS_SUBTYPE, 0);
    }
}

abstract contract PowerbankPart is EquipmentPartBase, Powerbank {

    function _mintPowerbankPart(address to) internal {
        _mintEquipmentPart(to, POWERBANK_SUBTYPE, 0);
    }
}

abstract contract LaptopPart is EquipmentPartBase, Laptop {

    function _mintLaptopPart(address to) internal {
        _mintEquipmentPart(to, LAPTOP_SUBTYPE, 0);
    }
}

abstract contract EquipmentParts is PhonePart, EarbudsPart, PowerbankPart, LaptopPart {}