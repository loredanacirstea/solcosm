// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "../CosmosSdk.sol";

contract MyContract is CosmosSdkBank, CosmosSdkGov, CosmosSdkDistribution, CosmosSdkAuth, CosmosSdkAuthz, CosmosSdkSlashing, CosmosSdkStaking {
    receive() payable external {}

    function delegateFromMyContract(address validator, uint256 amount) public {
        MsgDelegate memory message = MsgDelegate(address(this), validator, Coin("aMYT", amount));
        DoDelegate(message);
    }

    function getAndIncreaseDelegation(address validator) view public returns(QueryDelegationResponse memory data) {
        QueryDelegationRequest memory query = QueryDelegationRequest(address(this), validator);
        QueryDelegationResponse memory result = GetDelegation(query);
        result.DelegationResponse.Balance.Amount = result.DelegationResponse.Balance.Amount + 10000;
        return result;
    }
}
