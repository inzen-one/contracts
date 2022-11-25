// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/introspection/ERC165.sol';

abstract contract EasyGovernor is ERC165 {
    enum EventState {
        Propose,
        Execute
    }

    /**
     * @dev Returns list of proposal topics to listen for
     */
    function proposalTopics() external view virtual returns (bytes32[] memory);

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == (type(ERC165).interfaceId ^ this.proposalTopics.selector) ||
            super.supportsInterface(interfaceId);
    }
}
