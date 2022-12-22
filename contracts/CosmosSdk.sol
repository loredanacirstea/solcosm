// SPDX-License-Identifier: GPL-3.0
// @author Loredana Cirstea
// Solidity interfaces and inheritable contracts for Cosmos SDK structs, messages and queries

/*
Rules:
- all methods must use `message` as the name of the instantiated data structure: `function DoSend(MsgSend memory message)`
*/

pragma solidity >=0.7.0 <0.9.0;

struct Float {
    uint256 Amount;
    uint256 CommaPos;
}

struct Coin {
    string Denom;
    uint256 Amount;
}

struct DecCoin {
    string Denom;
    string Amount;
}

contract CosmosSdkCommon {
    address public PrecompileAddress = 0x000000000000000000000000000000000000001D;

    function sendMsgAbiEncoded(string memory moduleVersion, string memory msgName, bytes memory encodedMsg) internal returns (bytes memory) {
        string memory typeUrl = string(abi.encodePacked("/", moduleVersion, ".", msgName));
        bytes memory payload = abi.encodeWithSignature("sendMsgAbiEncoded(string,bytes)", typeUrl, encodedMsg);
        (bool success, bytes memory data) = PrecompileAddress.call(payload);
        require(success, string(abi.encodePacked("Msg failed: ", typeUrl)));
        return data;
    }

    function sendQueryAbiEncoded(string memory moduleVersion, string memory msgName, bytes memory encodedMsg) view internal returns (bytes memory) {
        string memory typeUrl = string(abi.encodePacked("/", moduleVersion, ".Query/", msgName));
        bytes memory payload = abi.encodeWithSignature("sendQueryAbiEncoded(string,bytes)", typeUrl, encodedMsg);

        (bool success, bytes memory data) = PrecompileAddress.staticcall(payload);
        require(success, string(abi.encodePacked("Query failed: ", typeUrl)));
        return data;
    }
}

interface CosmosSdkBankInterface {
    /* MESSAGES */

    struct MsgSend {
        address FromAddress;
        address ToAddress;
        Coin[] Amount;
    }

    struct Input {
        string Address;
        Coin[] Coins;
    }

    struct Output {
        string Address;
        Coin[] Coins;
    }

    struct MsgMultiSend {
        Input[] Inputs;
        Output[] Outputs;
    }

    /* QUERIES */

    struct DenomUnit {
        string Denom;
        uint32 Exponent;
        string[] Aliases;
    }

    struct Metadata {
        string Description;
        DenomUnit[] DenomUnits;
        string Base;
        string Display;
        string Name;
        string Symbol;
        string Uri;
        string UriHash;
    }

    struct QueryBalanceRequest {
        address Address;
        string Denom;
    }

    struct QueryBalanceResponse {
        Coin Balance;
    }

    struct QuerySupplyOfRequest {
        string Denom;
    }

    struct QuerySupplyOfResponse {
        Coin[] Amount;
    }

    struct QueryDenomMetadataRequest {
        string Denom;
    }

    struct QueryDenomMetadataResponse {
        Metadata Metadata;
    }

    function DoSend(MsgSend memory message) external;

    function DoMultiSend(MsgMultiSend memory message) external;

    /* QUERIES */

    function GetBalance(QueryBalanceRequest memory message) view external returns(QueryBalanceResponse memory data);
}

contract CosmosSdkBank is CosmosSdkCommon, CosmosSdkBankInterface {
    string public versionBank = "cosmos.bank.v1beta1";

    function DoSend(MsgSend memory message) override public {
        sendMsgAbiEncoded(versionBank, "MsgSend", abi.encode(message));
    }

    function DoMultiSend(MsgMultiSend memory message) override public {
        sendMsgAbiEncoded(versionBank, "MsgMultiSend", abi.encode(message));
    }

    /* QUERIES */

    function GetBalance(QueryBalanceRequest memory message) override view public returns(QueryBalanceResponse memory data) {
        bytes memory _data = sendQueryAbiEncoded(versionBank, "Balance", abi.encode(message));
        data = abi.decode(_data, (QueryBalanceResponse));
        return data;
    }
}

interface CosmosSdkGovInterface {

    // VoteOption enumerates the valid vote options for a given governance proposal.
    enum VoteOption {
        // VOTE_OPTION_UNSPECIFIED defines a no-op vote option.
        VOTE_OPTION_UNSPECIFIED, // 0
        // VOTE_OPTION_YES defines a yes vote option.
        VOTE_OPTION_YES,  // 1
        // VOTE_OPTION_ABSTAIN defines an abstain vote option.
        VOTE_OPTION_ABSTAIN,  // 2
        // VOTE_OPTION_NO defines a no vote option.
        VOTE_OPTION_NO,  // 3
        // VOTE_OPTION_NO_WITH_VETO defines a no with veto vote option.
        VOTE_OPTION_NO_WITH_VETO  // 4
    }

    /* MESSAGES */

    struct MsgVote {
        uint64 ProposalId;
        address Voter;
        VoteOption Option;
    }

    struct WeightedVoteOption {
        VoteOption Option;
        Float Weight;
    }

    struct MsgVoteWeighted {
        uint64 ProposalId;
        address Voter;
        WeightedVoteOption[] options;
    }

    struct MsgSubmitProposal {
        address Proposer;
        Coin[] InitialDeposit;
        bytes Content;
    }

    struct MsgSubmitProposalResponse {
        uint64 ProposalId;
    }

    struct MsgDeposit {
        uint64 ProposalId;
        address Depositor;
        Coin[] Amount;
    }

    struct MsgProposalText {
        string Title;
        string Description;
    }

    /* QUERIES */

    struct QueryProposalRequest {
        uint64 ProposalId;
    }

    enum ProposalStatus {
        // PROPOSAL_STATUS_UNSPECIFIED defines the default proposal status.
        PROPOSAL_STATUS_UNSPECIFIED, // = 0
        // PROPOSAL_STATUS_DEPOSIT_PERIOD defines a proposal status during the deposit
        // period.
        PROPOSAL_STATUS_DEPOSIT_PERIOD, // = 1
        // PROPOSAL_STATUS_VOTING_PERIOD defines a proposal status during the voting
        // period.
        PROPOSAL_STATUS_VOTING_PERIOD, // = 2
        // PROPOSAL_STATUS_PASSED defines a proposal status of a proposal that has
        // passed.
        PROPOSAL_STATUS_PASSED, // = 3
        // PROPOSAL_STATUS_REJECTED defines a proposal status of a proposal that has
        // been rejected.
        PROPOSAL_STATUS_REJECTED, // = 4
        // PROPOSAL_STATUS_FAILED defines a proposal status of a proposal that has
        // failed.
        PROPOSAL_STATUS_FAILED // = 5
    }

    struct TallyResult {
        string YesCount;
        string AbstainCount;
        string NoCount;
        string NoWithVetoCount;
    }

    struct Proposal {
        uint64 Id;
        ProposalStatus Status;
        TallyResult FinalTallyResult;
        uint256 SubmitTime;
        uint256 DepositEndTime;
        Coin[] TotalDeposit;
        uint256 VotingStartTime;
        uint256 VotingEndTime;
        string Metadata;
    }

    struct QueryProposalResponse {
        Proposal Proposal;
    }

    struct QueryVoteRequest {
        uint64 ProposalId;
        address Voter;
    }

    struct Vote {
        uint64 ProposalId;
        address Voter;
        string Metadata;
    }

    struct QueryVoteResponse {
        Vote Vote;
    }

    struct VotingParams {
        uint256 VotingPeriod;
    }

    struct DepositParams {
        Coin[] MinDeposit;
        uint256 MaxDepositPeriod;
    }

    struct TallyParams {
        string Quorum;
        string Threshold;
        string VetoThreshold;
    }

    struct QueryParamsResponse {
        VotingParams VotingParams;
        DepositParams DepositParams;
        TallyParams TallyParams;
    }

    struct QueryDepositRequest {
        uint64 ProposalId;
        address Depositor;
    }

    struct Deposit {
        uint64 ProposalId;
        address Depositor;
        Coin[] Amount;
    }

    struct QueryDepositResponse {
        Deposit Deposit;
    }

    struct QueryTallyResultRequest {
        uint64 ProposalId;
    }

    struct QueryTallyResultResponse {
        TallyResult Tally;
    }

    function DoSubmitProposal(MsgSubmitProposal memory message) external returns(MsgSubmitProposalResponse memory data);

    function DoVote(MsgVote memory message) external;

    function DoVoteWeighted(MsgVoteWeighted memory message) external;

    function DoDeposit(MsgDeposit memory message) external;
}

contract CosmosSdkGov is CosmosSdkCommon, CosmosSdkGovInterface {
    string public versionGov = "cosmos.gov.v1beta1";

    function DoSubmitProposal(MsgSubmitProposal memory message) override public returns (MsgSubmitProposalResponse memory data) {
        bytes memory _data = sendMsgAbiEncoded(versionGov, "MsgSubmitProposal", abi.encode(message));
        data = abi.decode(_data, (MsgSubmitProposalResponse));
        return data;
    }

    function DoVote(MsgVote memory message) override public {
        sendMsgAbiEncoded(versionGov, "MsgVote", abi.encode(message));
    }

    function DoVoteWeighted(MsgVoteWeighted memory message) override public {
        sendMsgAbiEncoded(versionGov, "MsgVoteWeighted", abi.encode(message));
    }

    function DoDeposit(MsgDeposit memory message) override public {
       sendMsgAbiEncoded(versionGov, "MsgDeposit", abi.encode(message));
    }
}

interface CosmosSdkErc20Interface {
    /* MESSAGES */

    struct MsgConvertCoin {
        Coin Coin;
        address Receiver;
        address Sender;
    }

    struct MsgConvertERC20 {
        address ContractAddress;
        uint256 Amount;
        address Receiver;
        address Sender;
    }

    /* QUERIES */

    struct QueryTokenPairRequest {
        string Token;
    }

    enum Owner {
        // OWNER_UNSPECIFIED defines an invalid/undefined owner.
        OWNER_UNSPECIFIED, // = 0
        // OWNER_MODULE - erc20 is owned by the erc20 module account.
        OWNER_MODULE, // = 1
        // OWNER_EXTERNAL - erc20 is owned by an external account.
        OWNER_EXTERNAL // = 2
    }

    struct TokenPair {
        address Erc20Address;
        string Denom;
        bool Enabled;
        Owner ContractOwner;
    }

    struct QueryTokenPairResponse {
        TokenPair TokenPair;
    }

    function DoConvertCoin(MsgConvertCoin memory message) external;

    function DoConvertERC20(MsgConvertERC20 memory message) external;
}

contract CosmosSdkErc20 is CosmosSdkCommon, CosmosSdkErc20Interface {
    string public versionErc20 = "evmos.erc20.v1";

    function DoConvertCoin(MsgConvertCoin memory message) override public {
        sendMsgAbiEncoded(versionErc20, "MsgConvertCoin", abi.encode(message));
    }

    function DoConvertERC20(MsgConvertERC20 memory message) override public {
        sendMsgAbiEncoded(versionErc20, "MsgConvertERC20", abi.encode(message));
    }
}

interface CosmosSdkAuthInterface {}

contract CosmosSdkAuth is CosmosSdkCommon, CosmosSdkAuthInterface {
    string public versionAuth = "cosmos.auth.v1beta1";
}

interface CosmosSdkAuthzInterface {}

contract CosmosSdkAuthz is CosmosSdkCommon, CosmosSdkAuthzInterface {
    string public versionAuthz = "cosmos.authz.v1beta1";
}

interface CosmosSdkDistributionInterface {
    /* MESSAGES */

    struct MsgSetWithdrawAddress {
        address DelegatorAddress;
        address WithdrawAddress;
    }

    struct MsgWithdrawDelegatorReward {
        address DelegatorAddress;
        address ValidatorAddress;
    }

    struct MsgWithdrawDelegatorRewardResponse {
        Coin[] Amount;
    }

    struct MsgWithdrawValidatorCommission {
        address ValidatorAddress;
    }

    struct MsgWithdrawValidatorCommissionResponse {
        Coin[] Amount;
    }

    struct MsgFundCommunityPool {
        address Depositor;
        Coin[] Amount;
    }

    /* QUERIES */

    struct QueryValidatorDistributionInfoRequest {
        address ValidatorAddress;
    }

    struct QueryValidatorDistributionInfoResponse {
        string OperatorAddress;
        DecCoin[] SelfBondRewards;
        DecCoin[] Commission;
    }

    struct QueryValidatorOutstandingRewardsRequest {
        string ValidatorAddress;
    }

    struct ValidatorOutstandingRewards {
        DecCoin[] Rewards;
    }

    struct QueryValidatorOutstandingRewardsResponse {
        ValidatorOutstandingRewards Rewards;
    }

    struct QueryValidatorCommissionRequest {
        address ValidatorAddress;
    }

    struct ValidatorAccumulatedCommission {
        DecCoin[] Commission;
    }

    struct QueryValidatorCommissionResponse {
        ValidatorAccumulatedCommission Commission;
    }

    struct QueryDelegationRewardsRequest {
        address DelegatorAddress;
        address ValidatorAddress;
    }

    struct QueryDelegationRewardsResponse {
        DecCoin[] Rewards;
    }

    struct QueryDelegatorValidatorsRequest {
        address DelegatorAddress;
    }

    struct QueryDelegatorValidatorsResponse {
        address[] Validators;
    }

    struct QueryDelegatorWithdrawAddressRequest {
        address DelegatorAddress;
    }

    struct QueryDelegatorWithdrawAddressResponse {
        address WithdrawAddress;
    }

    // struct QueryCommunityPoolRequest {}

    struct QueryCommunityPoolResponse {
        DecCoin[] Pool;
    }

    function DoSetWithdrawAddress(MsgSetWithdrawAddress memory message) external;

    function DoWithdrawDelegatorReward(MsgWithdrawDelegatorReward memory message) external returns(MsgWithdrawDelegatorRewardResponse memory data);

    function DoWithdrawValidatorCommission(MsgWithdrawValidatorCommission memory message) external returns(MsgWithdrawValidatorCommissionResponse memory data);

    function DoFundCommunityPool(MsgFundCommunityPool memory message) external;
}

contract CosmosSdkDistribution is CosmosSdkCommon, CosmosSdkDistributionInterface {
    string public versionDistribution = "cosmos.distribution.v1beta1";

    function DoSetWithdrawAddress(MsgSetWithdrawAddress memory message) override public {
        sendMsgAbiEncoded(versionDistribution, "MsgSetWithdrawAddress", abi.encode(message));
    }

    function DoWithdrawDelegatorReward(MsgWithdrawDelegatorReward memory message) override public returns(MsgWithdrawDelegatorRewardResponse memory data) {
        bytes memory _data = sendMsgAbiEncoded(versionDistribution, "MsgWithdrawDelegatorReward", abi.encode(message));
        data = abi.decode(_data, (MsgWithdrawDelegatorRewardResponse));
        return data;
    }

    function DoWithdrawValidatorCommission(MsgWithdrawValidatorCommission memory message) override public returns(MsgWithdrawValidatorCommissionResponse memory data) {
        bytes memory _data = sendMsgAbiEncoded(versionDistribution, "MsgWithdrawValidatorCommission", abi.encode(message));
        data = abi.decode(_data, (MsgWithdrawValidatorCommissionResponse));
        return data;
    }

    function DoFundCommunityPool(MsgFundCommunityPool memory message) override public {
        sendMsgAbiEncoded(versionDistribution, "MsgFundCommunityPool", abi.encode(message));
    }
}

interface CosmosSdkSlashingInterface {
    struct MsgUnjail {
        address ValidatorAddr;
    }

    function DoUnjail(MsgUnjail memory message) external;
}

contract CosmosSdkSlashing is CosmosSdkCommon, CosmosSdkSlashingInterface {
    string public versionSlashing = "cosmos.slashing.v1beta1";

    function DoUnjail(MsgUnjail memory message) override public {
        sendMsgAbiEncoded(versionSlashing, "MsgUnjail", abi.encode(message));
    }
}

interface CosmosSdkStakingInterface {
    /* MESSAGES */

    struct MsgDelegate {
        address DelegatorAddress;
        address ValidatorAddress;
        Coin Amount;
    }

    struct MsgBeginRedelegate {
        address DelegatorAddress;
        address ValidatorSrcAddress;
        address ValidatorDstAddress;
        Coin Amount;
    }

    struct MsgBeginRedelegateResponse {
        uint256 CompletionTime;
    }

    struct MsgUndelegate {
        address DelegatorAddress;
        address ValidatorAddress;
        Coin Amount;
    }

    struct MsgUndelegateResponse {
        uint256 CompletionTime;
    }

    struct MsgCancelUnbondingDelegation {
        address DelegatorAddress;
        address ValidatorAddress;
        Coin Amount;
        int64 CreationHeight;
    }

    /* QUERIES */

    struct QueryValidatorRequest {
        address ValidatorAddr;
    }

    struct Validator {
        address Address;
        bytes PubKey;
        int64 VotingPower;
        int64 ProposerPriority;
    }

    struct QueryValidatorResponse {
        Validator Validator;
    }

    struct QueryDelegationRequest {
        address DelegatorAddr;
        address ValidatorAddr;
    }

    struct Delegation {
        address DelegatorAddress;
        address ValidatorAddress;
        string Shares;
    }

    struct DelegationResponse {
        Delegation Delegation;
        Coin Balance;
    }

    struct QueryDelegationResponse {
        DelegationResponse DelegationResponse;
    }

    struct QueryUnbondingDelegationRequest {
        address DelegatorAddr;
        address ValidatorAddr;
    }

    struct UnbondingDelegationEntry {
        int64 CreationHeight;
        uint256 CompletionTime;
        string InitialBalance;
        string Balance;
        uint64 UnbondingId;
        int64 UnbondingOnHoldRefCount;
    }

    struct UnbondingDelegation {
        address DelegatorAddress;
        address ValidatorAddress;
        UnbondingDelegationEntry[] Entries;
    }

    struct QueryUnbondingDelegationResponse {
        UnbondingDelegation Unbond;
    }

    struct QueryDelegatorValidatorRequest {
        address DelegatorAddr;
        address ValidatorAddr;
    }

    struct QueryDelegatorValidatorResponse {
        Validator Validator;
    }

    function DoDelegate(MsgDelegate memory message) external;

    function DoBeginRedelegate(MsgBeginRedelegate memory message) external returns(MsgBeginRedelegateResponse memory data);

    function DoUndelegate(MsgUndelegate memory message) external returns(MsgUndelegateResponse memory data);

    function DoCancelUnbondingDelegation(MsgCancelUnbondingDelegation memory message) external;

    /* QUERIES */

    function GetDelegation(QueryDelegationRequest memory message) view external returns(QueryDelegationResponse memory data);
}

contract CosmosSdkStaking is CosmosSdkCommon, CosmosSdkStakingInterface {
    string public versionStaking = "cosmos.staking.v1beta1";

    function DoDelegate(MsgDelegate memory message) override public {
        sendMsgAbiEncoded(versionStaking, "MsgDelegate", abi.encode(message));
    }

    function DoBeginRedelegate(MsgBeginRedelegate memory message) override public returns(MsgBeginRedelegateResponse memory data) {
        bytes memory _data = sendMsgAbiEncoded(versionStaking, "MsgBeginRedelegate", abi.encode(message));
        data = abi.decode(_data, (MsgBeginRedelegateResponse));
        return data;
    }

    function DoUndelegate(MsgUndelegate memory message) override public returns(MsgUndelegateResponse memory data) {
        bytes memory _data = sendMsgAbiEncoded(versionStaking, "MsgUndelegate", abi.encode(message));
        data = abi.decode(_data, (MsgUndelegateResponse));
        return data;
    }

    function DoCancelUnbondingDelegation(MsgCancelUnbondingDelegation memory message) override public {
        sendMsgAbiEncoded(versionStaking, "MsgCancelUnbondingDelegation", abi.encode(message));
    }

    /* QUERIES */

    function GetDelegation(QueryDelegationRequest memory message) override view public returns(QueryDelegationResponse memory data) {
        bytes memory _data = sendQueryAbiEncoded(versionStaking, "Delegation", abi.encode(message));
        data = abi.decode(_data, (QueryDelegationResponse));
        return data;
    }
}

