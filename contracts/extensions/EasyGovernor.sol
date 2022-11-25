// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/introspection/ERC165.sol';

abstract contract EasyGovernor is ERC165 {
    enum EventState {Propose, Execute}

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function proposalTopics() external virtual view returns (bytes32[] memory);

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public virtual override view returns (bool) {
        return
            interfaceId == (type(ERC165).interfaceId ^ this.proposalTopics.selector) ||
            super.supportsInterface(interfaceId);
    }
}
