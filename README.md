# solcosm

Solidity interfaces and inheritable contracts for Cosmos SDK structs, messages and queries

This project is in-development, as part of the [Quasar module for Cosmos-EVM chains](https://www.youtube.com/playlist?list=PL323JufuD9JB1R28TdzCtiiIwTHy9TX5C).

Test it on the [Mythos chain](https://github.com/cosmos/chain-registry/tree/943428722d7715ecd95cba702bde1be5cc5a06b1/mythos). Ask for the non-tradable gas token in the [Mythos Discord](https://discord.gg/8W5jeBke4f).

## Usage

```sh
npm install loredanacirstea/solcosm
yarn add loredanacirstea/solcosm
```

```shell
cd solcosm
npx hardhat help
npx hardhat test
REPORT_GAS=true npx hardhat test
npx hardhat node
npx hardhat run scripts/deploy.ts
```

This is an example meant only for didactic purposes.

```solidity
import "loredanacirstea/solcosm/contracts/CosmosSdk.sol";

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
```
