//SPDX-License-Identifier: LICENSED
pragma solidity ^0.7.0;
import "./MultiSigOwner.sol";

contract OwnerConstants is MultiSigOwner {
    uint256 public constant HR48 = 10 minutes; //for testing
    // address public owner;

    // daily limit contants
    uint256 public constant MAX_LEVEL = 5;
    // uint256[] public OkseStakeAmounts;
    // uint256[] public DailyLimits;
    uint256[] public CashBackPercents;
    // // this is validation period after user change his okse balance for this contract, normally is 30 days. we set 10 mnutes for testing.
    // uint256 public levelValidationPeriod;

    // this is reward address for user's withdraw and payment for goods.
    address public treasuryAddress;
    // this address should be deposit okse in his balance and users can get cashback from this address.
    address public financialAddress;
    // master address is used to send USDC tokens when user buy goods.
    address public masterAddress;
    // monthly fee rewarded address
    address public monthlyFeeAddress;

    address public pendingTreasuryAddress;
    address public pendingFinancialAddress;
    address public pendingMasterAddress;
    address public pendingMonthlyFeeAddress;
    uint256 public requestTimeOfManagerAddressUpdate;

    // staking contract address, which is used to receive 20% of monthly fee, so staked users can be rewarded from this contract
    address public stakeContractAddress;
    // statking amount of monthly fee
    uint256 public stakePercent; // 15 %

    // withdraw fee and payment fee should not exeed this amount, 1% is coresponding to 100.
    uint256 public constant MAX_FEE_AMOUNT = 500; // 5%
    // buy fee setting.
    uint256 public buyFeePercent; // 1%

    // withdraw fee setting.
    uint256 public withdrawFeePercent; // 0.1 %
    // // unit is usd amount , so decimal is 18
    // mapping(address => uint256) public userDailyLimits;
    // Set whether user can use okse as payment asset. normally it is false.
    // bool public oksePaymentEnable;
    // Setting for cashback enable or disable
    // bool public cashBackEnable;
    // // enable or disable for each market
    // mapping(address => bool) public marketEnabled;
    // set monthly fee of user to use card payment, unit is usd amount ( 1e18)
    uint256 public monthlyFeeAmount; // 6.99 USD
    // if user pay monthly fee using okse, then he will pay less amount fro this percent. 0% => 0, 100% => 10000
    uint256 public okseMonthlyProfit; // 10%

    bool public emergencyStop;

    // // events
    // event OwnershipTransferred(
    //     address indexed previousOwner,
    //     address indexed newOwner
    // );
    event ManagerAddressChanged(
        address owner,
        address treasuryAddress,
        address financialAddress,
        address masterAddress,
        address monthlyFeeAddress
    );
    // /// modifier functions
    // modifier onlyOwner() {
    //     require(msg.sender == owner, "oo");
    //     _;
    // }
    modifier noEmergency() {
        require(!emergencyStop, "stopped");
        _;
    }

    constructor() {
        // owner = msg.sender;
    }

    // /**
    //  * @notice Get user level from his okse balance
    //  * @param _okseAmount okse token amount
    //  * @return user's level, 0~5 , 0 => no level
    //  */
    // // verified
    // function getLevel(uint256 _okseAmount) public view returns (uint256) {
    //     if (_okseAmount < OkseStakeAmounts[0]) return 0;
    //     if (_okseAmount < OkseStakeAmounts[1]) return 1;
    //     if (_okseAmount < OkseStakeAmounts[2]) return 2;
    //     if (_okseAmount < OkseStakeAmounts[3]) return 3;
    //     if (_okseAmount < OkseStakeAmounts[4]) return 4;
    //     return 5;
    // }

    // // verified
    // function getDailyLimit(uint256 level) public view returns (uint256) {
    //     require(level <= 5, "level > 5");
    //     return DailyLimits[level];
    // }

    // //verified
    // function getCashBackPercent(uint256 level) public view returns (uint256) {
    //     require(level <= 5, "level > 5");
    //     return CashBackPercents[level];
    // }

    function getMonthlyFeeAmount(bool payFromOkse)
        public
        view
        returns (uint256)
    {
        uint256 result;
        if (payFromOkse) {
            result =
                monthlyFeeAmount -
                (monthlyFeeAmount * okseMonthlyProfit) /
                10000;
        } else {
            result = monthlyFeeAmount;
        }
        return result;
    }

    // Set functions
    // verified
    // function transaferOwnership(address newOwner) public onlyOwner {
    //     address oldOwner = owner;
    //     owner = newOwner;
    //     emit OwnershipTransferred(oldOwner, newOwner);
    // }

    // I have to add 48 hours delay in this function
    function setManagerAddresses(bytes calldata signData, bytes calldata keys)
        public
        onlyOwner
        validSignOfOwner(signData, keys, "setManagerAddresses")
    {
        require(
            block.timestamp > requestTimeOfManagerAddressUpdate + HR48 &&
                requestTimeOfManagerAddressUpdate > 0,
            "need to wait 48hr"
        );
        treasuryAddress = pendingTreasuryAddress;
        financialAddress = pendingFinancialAddress;
        masterAddress = pendingMasterAddress;
        monthlyFeeAddress = pendingMonthlyFeeAddress;
        requestTimeOfManagerAddressUpdate = 0;
    }

    function requestManagerAddressUpdate(
        bytes calldata signData,
        bytes calldata keys
    )
        public
        onlyOwner
        validSignOfOwner(signData, keys, "requestManagerAddressUpdate")
    {
        (, , bytes memory params) = abi.decode(
            signData,
            (bytes4, uint256, bytes)
        );
        (
            address _newTreasuryAddress,
            address _newFinancialAddress,
            address _newMasterAddress,
            address _mothlyFeeAddress
        ) = abi.decode(params, (address, address, address, address));

        pendingTreasuryAddress = _newTreasuryAddress;
        pendingFinancialAddress = _newFinancialAddress;
        pendingMasterAddress = _newMasterAddress;
        pendingMonthlyFeeAddress = _mothlyFeeAddress;
        requestTimeOfManagerAddressUpdate = block.timestamp;
    }

    // verified
    function setWithdrawFeePercent(bytes calldata signData, bytes calldata keys)
        public
        onlyOwner
        validSignOfOwner(signData, keys, "setWithdrawFeePercent")
    {
        (, , bytes memory params) = abi.decode(
            signData,
            (bytes4, uint256, bytes)
        );
        uint256 newPercent = abi.decode(params, (uint256));
        require(newPercent <= MAX_FEE_AMOUNT, "mfo");
        // uint256 beforePercent = withdrawFeePercent;
        withdrawFeePercent = newPercent;
        // emit WithdrawFeePercentChanged(owner, newPercent, beforePercent);
    }

    // verified
    // function setUserDailyLimits(address userAddr, uint256 usdAmount)
    //     public
    //     onlyOwner
    // {
    //     userDailyLimits[userAddr] = usdAmount;
    //     // emit UserDailyLimitChanged(userAddr, usdAmount);
    // }

    // // verified
    // function setOkseStakeAmount(uint256 index, uint256 _amount)
    //     public
    //     onlyOwner
    // {
    //     require(index < MAX_LEVEL, "level<5");
    //     OkseStakeAmounts[index] = _amount;
    // }

    // // verified
    // function setDailyLimit(uint256 index, uint256 _amount) public onlyOwner {
    //     require(index <= MAX_LEVEL, "level<=5");
    //     DailyLimits[index] = _amount;
    // }

    // verified
    // function setCashBackPercent(bytes calldata signData, bytes calldata keys)
    //     public
    //     onlyOwner
    //     validSignOfOwner(signData, keys, "setCashBackPercent")
    // {
    //     (, , bytes memory params) = abi.decode(
    //         signData,
    //         (bytes4, uint256, bytes)
    //     );
    //     (uint256 index, uint256 _amount) = abi.decode(
    //         params,
    //         (uint256, uint256)
    //     );
    //     require(index <= MAX_LEVEL, "level<=5");
    //     CashBackPercents[index] = _amount;
    // }

    // verified
    // function setCashBackEnable(bytes calldata signData, bytes calldata keys)
    //     public
    //     onlyOwner
    //     validSignOfOwner(signData, keys, "setCashBackEnable")
    // {
    //     (, , bytes memory params) = abi.decode(
    //         signData,
    //         (bytes4, uint256, bytes)
    //     );
    //     bool newEnabled = abi.decode(params, (bool));
    //     cashBackEnable = newEnabled;
    // }

    // verified
    // function enableMarket(bytes calldata signData, bytes calldata keys)
    //     public
    //     onlyOwner
    //     validSignOfOwner(signData, keys, "enableMarket")
    // {
    //     (, , bytes memory params) = abi.decode(
    //         signData,
    //         (bytes4, uint256, bytes)
    //     );
    //     (address market, bool bEnable) = abi.decode(params, (address, bool));
    //     marketEnabled[market] = bEnable;
    // }

    // // verified
    // function setOkseAsPayment(bytes calldata signData, bytes calldata keys)
    //     public
    //     onlyOwner
    //     validSignOfOwner(signData, keys, "setOkseAsPayment")
    // {
    //     (, , bytes memory params) = abi.decode(
    //         signData,
    //         (bytes4, uint256, bytes)
    //     );
    //     bool bEnable = abi.decode(params, (bool));
    //     oksePaymentEnable = bEnable;
    // }

    // verified
    function setMonthlyFee(bytes calldata signData, bytes calldata keys)
        public
        onlyOwner
        validSignOfOwner(signData, keys, "setMonthlyFee")
    {
        (, , bytes memory params) = abi.decode(
            signData,
            (bytes4, uint256, bytes)
        );
        (uint256 usdFeeAmount, uint256 okseProfitPercent) = abi.decode(
            params,
            (uint256, uint256)
        );
        require(okseProfitPercent <= 10000, "over percent");
        monthlyFeeAmount = usdFeeAmount;
        okseMonthlyProfit = okseProfitPercent;
    }

    // // verified
    // function setLevelValidationPeriod(uint256 _newValue) public onlyOwner {
    //     levelValidationPeriod = _newValue;
    // }

    function setStakeContractParams(
        bytes calldata signData,
        bytes calldata keys
    )
        public
        onlyOwner
        validSignOfOwner(signData, keys, "setStakeContractParams")
    {
        (, , bytes memory params) = abi.decode(
            signData,
            (bytes4, uint256, bytes)
        );
        (address _stakeContractAddress, uint256 _stakePercent) = abi.decode(
            params,
            (address, uint256)
        );
        stakeContractAddress = _stakeContractAddress;
        stakePercent = _stakePercent;
    }

    function setEmergencyStop(bytes calldata signData, bytes calldata keys)
        public
        onlyOwner
        validSignOfOwner(signData, keys, "setParams")
    {
        (, , bytes memory params) = abi.decode(
            signData,
            (bytes4, uint256, bytes)
        );
        bool _value = abi.decode(params, (bool));
        emergencyStop = _value;
    }
}
